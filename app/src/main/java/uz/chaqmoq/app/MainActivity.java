package uz.chaqmoq.app;

import android.Manifest;
import android.app.Activity;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Matrix;
import android.graphics.Paint;
import android.graphics.RectF;
import android.graphics.pdf.PdfDocument;
import android.media.ExifInterface;
import android.media.MediaScannerConnection;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.os.StatFs;
import android.provider.MediaStore;
import android.provider.Settings;
import android.util.Base64;
import android.view.View;
import android.webkit.JavascriptInterface;
import android.webkit.PermissionRequest;
import android.webkit.WebChromeClient;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.Toast;

import com.google.zxing.BarcodeFormat;
import com.google.zxing.BinaryBitmap;
import com.google.zxing.DecodeHintType;
import com.google.zxing.EncodeHintType;
import com.google.zxing.LuminanceSource;
import com.google.zxing.MultiFormatReader;
import com.google.zxing.RGBLuminanceSource;
import com.google.zxing.common.BitMatrix;
import com.google.zxing.common.HybridBinarizer;
import com.google.zxing.qrcode.QRCodeWriter;
import com.google.zxing.qrcode.decoder.ErrorCorrectionLevel;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.charset.StandardCharsets;
import java.util.EnumMap;
import java.util.Map;

public class MainActivity extends Activity {
    private WebView web;
    private static final int REQ_PERM = 7;
    private static final int REQ_CAMPERM = 8;
    private static final int REQ_CAM = 21;
    private static final int REQ_PICK = 22;
    private String camTag = "";
    private File camFile;
    private PdfDocument pdf;
    private int pdfPages;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        getWindow().setStatusBarColor(Color.parseColor("#14161A"));
        getWindow().setNavigationBarColor(Color.parseColor("#14161A"));

        web = new WebView(this);
        web.setBackgroundColor(Color.parseColor("#14161A"));
        web.setOverScrollMode(View.OVER_SCROLL_NEVER);
        web.setVerticalScrollBarEnabled(false);
        WebSettings s = web.getSettings();
        s.setJavaScriptEnabled(true);
        s.setDomStorageEnabled(true);
        s.setAllowFileAccess(true);
        s.setTextZoom(100);
        s.setSupportZoom(false);
        s.setBuiltInZoomControls(false);
        s.setMediaPlaybackRequiresUserGesture(false);

        try {
            File[] old = FileShare.camDir(this).listFiles();
            if (old != null) for (File f : old) f.delete();
        } catch (Exception ignored) { }

        web.addJavascriptInterface(new Bridge(), "Native");
        web.setWebViewClient(new WebViewClient());
        web.setWebChromeClient(new WebChromeClient() {
            @Override
            public void onPermissionRequest(final PermissionRequest request) {
                runOnUiThread(() -> {
                    try {
                        if (hasCam()) request.grant(request.getResources());
                        else request.deny();
                    } catch (Exception ignored) { }
                });
            }
        });
        setContentView(web);
        web.loadUrl("file:///android_asset/index.html");
    }

    @Override
    protected void onResume() {
        super.onResume();
        if (web != null) web.evaluateJavascript("window.onAppResume && window.onAppResume()", null);
    }

    @Override
    public void onRequestPermissionsResult(int code, String[] perms, int[] res) {
        super.onRequestPermissionsResult(code, perms, res);
        if (web != null) web.evaluateJavascript("window.onAppResume && window.onAppResume()", null);
    }

    @Override
    protected void onActivityResult(int req, int res, Intent data) {
        super.onActivityResult(req, res, data);
        if (req == REQ_CAM) {
            final File f = camFile;
            final String tag = camTag;
            boolean ok = res == RESULT_OK && f != null && f.length() > 0;
            js("window.onPhoto && window.onPhoto(" + JSONObject.quote(tag) + "," + JSONObject.quote(ok ? f.getAbsolutePath() : "") + ")");
        } else if (req == REQ_PICK) {
            final String tag = camTag;
            final Uri uri = (res == RESULT_OK && data != null) ? data.getData() : null;
            if (uri == null) {
                js("window.onPhoto && window.onPhoto(" + JSONObject.quote(tag) + ",\"\")");
                return;
            }
            new Thread(() -> {
                String path = "";
                try {
                    File f = new File(FileShare.camDir(MainActivity.this), "g_" + System.currentTimeMillis() + ".jpg");
                    try (InputStream in = getContentResolver().openInputStream(uri); OutputStream out = new FileOutputStream(f)) {
                        byte[] buf = new byte[1 << 16];
                        int n;
                        while ((n = in.read(buf)) > 0) out.write(buf, 0, n);
                    }
                    path = f.getAbsolutePath();
                } catch (Exception ignored) { }
                js("window.onPhoto && window.onPhoto(" + JSONObject.quote(tag) + "," + JSONObject.quote(path) + ")");
            }).start();
        }
    }

    private boolean hasCam() {
        return checkSelfPermission(Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED;
    }

    /** Suratni xotiraga sig'adigan o'lchamda o'qiydi va EXIF bo'yicha to'g'ri buradi. */
    private static Bitmap loadPhoto(String path, int max) throws Exception {
        BitmapFactory.Options o = new BitmapFactory.Options();
        o.inJustDecodeBounds = true;
        BitmapFactory.decodeFile(path, o);
        int big = Math.max(o.outWidth, o.outHeight);
        if (big <= 0) throw new Exception("rasm emas");
        int sample = 1;
        while (big / (sample * 2) >= max) sample *= 2;
        BitmapFactory.Options o2 = new BitmapFactory.Options();
        o2.inSampleSize = sample;
        Bitmap bm = BitmapFactory.decodeFile(path, o2);
        if (bm == null) throw new Exception("rasm ochilmadi");
        int deg = 0;
        try {
            int or = new ExifInterface(path).getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL);
            if (or == ExifInterface.ORIENTATION_ROTATE_90) deg = 90;
            else if (or == ExifInterface.ORIENTATION_ROTATE_180) deg = 180;
            else if (or == ExifInterface.ORIENTATION_ROTATE_270) deg = 270;
        } catch (Exception ignored) { }
        float sc = Math.min(1f, (float) max / Math.max(bm.getWidth(), bm.getHeight()));
        if (deg != 0 || sc < 1f) {
            Matrix m = new Matrix();
            if (sc < 1f) m.postScale(sc, sc);
            if (deg != 0) m.postRotate(deg);
            bm = Bitmap.createBitmap(bm, 0, 0, bm.getWidth(), bm.getHeight(), m, true);
        }
        return bm;
    }

    private static Bitmap fromB64(String b64) {
        int c = b64.indexOf(',');
        if (b64.startsWith("data:") && c > 0) b64 = b64.substring(c + 1);
        byte[] raw = Base64.decode(b64, Base64.DEFAULT);
        return BitmapFactory.decodeByteArray(raw, 0, raw.length);
    }

    /** QR va shtrix-kodni o'qiydi; topilmasa bo'sh satr. */
    private static String readCode(Bitmap bm, boolean hard) {
        if (bm == null) return "";
        try {
            int w = bm.getWidth(), h = bm.getHeight();
            int[] px = new int[w * h];
            bm.getPixels(px, 0, w, 0, 0, w, h);
            LuminanceSource src = new RGBLuminanceSource(w, h, px);
            Map<DecodeHintType, Object> hints = new EnumMap<>(DecodeHintType.class);
            if (hard) hints.put(DecodeHintType.TRY_HARDER, Boolean.TRUE);
            try {
                return new MultiFormatReader().decode(new BinaryBitmap(new HybridBinarizer(src)), hints).getText();
            } catch (Exception e) {
                return new MultiFormatReader().decode(new BinaryBitmap(new HybridBinarizer(src.invert())), hints).getText();
            }
        } catch (Throwable t) {
            return "";
        }
    }

    private File outDir(String type, String sub) {
        File d = new File(Environment.getExternalStoragePublicDirectory(type), sub);
        if (!d.exists()) d.mkdirs();
        return d;
    }

    private static String cleanName(String n, String def) {
        if (n == null) return def;
        n = n.replaceAll("[\\\\/:*?\"<>|]", "_").trim();
        return n.isEmpty() ? def : n;
    }

    @Override
    public void onBackPressed() {
        web.evaluateJavascript("window.goBack ? window.goBack() : false", v -> {
            if (!"true".equals(v)) finish();
        });
    }

    private void js(final String code) {
        runOnUiThread(() -> { if (web != null) web.evaluateJavascript(code, null); });
    }

    private void toastUi(final String text) {
        runOnUiThread(() -> Toast.makeText(MainActivity.this, text, Toast.LENGTH_SHORT).show());
    }

    private boolean hasPerm() {
        if (Build.VERSION.SDK_INT >= 30) return Environment.isExternalStorageManager();
        return checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE) == PackageManager.PERMISSION_GRANTED;
    }

    private static int childCount(File d) {
        String[] names = d.list();
        if (names == null) return 0;
        int n = 0;
        for (String x : names) if (!x.startsWith(".")) n++;
        return n;
    }

    private static boolean deleteRec(File f) {
        if (f.isDirectory()) {
            File[] kids = f.listFiles();
            if (kids != null) for (File k : kids) if (!deleteRec(k)) return false;
        }
        return f.delete();
    }

    private static void copyRec(File src, File dst) throws Exception {
        if (src.isDirectory()) {
            if (!dst.exists() && !dst.mkdirs()) throw new Exception("papka yaratilmadi");
            File[] kids = src.listFiles();
            if (kids != null) for (File k : kids) copyRec(k, new File(dst, k.getName()));
        } else {
            try (InputStream in = new FileInputStream(src); OutputStream out = new FileOutputStream(dst)) {
                byte[] buf = new byte[1 << 16];
                int n;
                while ((n = in.read(buf)) > 0) out.write(buf, 0, n);
            }
            dst.setLastModified(src.lastModified());
        }
    }

    /** Nom band bo'lsa "nom (2).ext" kabi bo'sh nom topadi. */
    private static File freeName(File dir, String name) {
        File f = new File(dir, name);
        if (!f.exists()) return f;
        String base = name, ext = "";
        int dot = name.lastIndexOf('.');
        if (dot > 0) { base = name.substring(0, dot); ext = name.substring(dot); }
        for (int i = 2; i < 1000; i++) {
            f = new File(dir, base + " (" + i + ")" + ext);
            if (!f.exists()) return f;
        }
        return f;
    }

    private static boolean badName(String n) {
        return n == null || n.trim().isEmpty() || n.contains("/") || n.equals(".") || n.equals("..");
    }

    private class Bridge {
        @JavascriptInterface
        public String info() {
            JSONObject o = new JSONObject();
            try {
                File root = Environment.getExternalStorageDirectory();
                o.put("root", root.getAbsolutePath());
                o.put("perm", hasPerm());
                o.put("sdk", Build.VERSION.SDK_INT);
                try {
                    StatFs st = new StatFs(root.getAbsolutePath());
                    o.put("total", st.getTotalBytes());
                    o.put("free", st.getAvailableBytes());
                } catch (Exception e) {
                    o.put("total", 0);
                    o.put("free", 0);
                }
                o.put("ver", getPackageManager().getPackageInfo(getPackageName(), 0).versionName);
            } catch (Exception ignored) { }
            return o.toString();
        }

        @JavascriptInterface
        public void askPerm() {
            runOnUiThread(() -> {
                try {
                    if (Build.VERSION.SDK_INT >= 30) {
                        try {
                            Intent i = new Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION,
                                    Uri.parse("package:" + getPackageName()));
                            startActivity(i);
                        } catch (Exception e) {
                            startActivity(new Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION));
                        }
                    } else {
                        requestPermissions(new String[]{
                                Manifest.permission.READ_EXTERNAL_STORAGE,
                                Manifest.permission.WRITE_EXTERNAL_STORAGE}, REQ_PERM);
                    }
                } catch (Exception e) {
                    Toast.makeText(MainActivity.this, "Ruxsat oynasi ochilmadi", Toast.LENGTH_LONG).show();
                }
            });
        }

        @JavascriptInterface
        public int count(String path) {
            File d = new File(path);
            if (!d.isDirectory()) return -1;
            return childCount(d);
        }

        @JavascriptInterface
        public String list(String path) {
            JSONObject o = new JSONObject();
            try {
                File d = new File(path);
                File[] kids = d.listFiles();
                if (kids == null) {
                    o.put("ok", false);
                    return o.toString();
                }
                JSONArray arr = new JSONArray();
                for (File k : kids) {
                    String n = k.getName();
                    if (n.startsWith(".")) continue;
                    JSONObject it = new JSONObject();
                    boolean dir = k.isDirectory();
                    it.put("n", n);
                    it.put("d", dir);
                    it.put("s", dir ? 0 : k.length());
                    it.put("m", k.lastModified());
                    if (dir) it.put("c", childCount(k));
                    arr.put(it);
                }
                o.put("ok", true);
                o.put("items", arr);
            } catch (Exception e) {
                try { o.put("ok", false); } catch (Exception ignored) { }
            }
            return o.toString();
        }

        @JavascriptInterface
        public boolean mkdir(String dir, String name) {
            if (badName(name)) return false;
            File f = new File(dir, name.trim());
            if (f.exists()) return false;
            return f.mkdirs();
        }

        @JavascriptInterface
        public boolean rename(String path, String newName) {
            if (badName(newName)) return false;
            File f = new File(path);
            File t = new File(f.getParentFile(), newName.trim());
            if (t.exists()) return false;
            return f.renameTo(t);
        }

        /** Og'ir amallar alohida oqimda: tugagach window.onOp(id, ok) chaqiriladi. */
        @JavascriptInterface
        public void remove(final int id, final String path) {
            new Thread(() -> {
                boolean ok;
                try { ok = deleteRec(new File(path)); } catch (Exception e) { ok = false; }
                js("window.onOp && window.onOp(" + id + "," + ok + ")");
            }).start();
        }

        @JavascriptInterface
        public void paste(final int id, final String src, final String dstDir, final boolean move) {
            new Thread(() -> {
                boolean ok = false;
                try {
                    File s = new File(src);
                    File dir = new File(dstDir);
                    String dp = dir.getCanonicalPath() + "/";
                    String sp = s.getCanonicalPath() + "/";
                    if (s.exists() && dir.isDirectory() && !(s.isDirectory() && dp.startsWith(sp))) {
                        if (move && s.getParentFile() != null
                                && s.getParentFile().getCanonicalPath().equals(dir.getCanonicalPath())) {
                            ok = true;
                        } else {
                            File t = freeName(dir, s.getName());
                            if (move && s.renameTo(t)) {
                                ok = true;
                            } else {
                                copyRec(s, t);
                                ok = true;
                                if (move) ok = deleteRec(s);
                            }
                        }
                    }
                } catch (Exception e) {
                    ok = false;
                }
                js("window.onOp && window.onOp(" + id + "," + ok + ")");
            }).start();
        }

        @JavascriptInterface
        public void open(final String path) {
            runOnUiThread(() -> {
                try {
                    File f = new File(path);
                    Intent i = new Intent(Intent.ACTION_VIEW);
                    i.setDataAndType(FileShare.uriFor(f), FileShare.mimeOf(f.getName()));
                    i.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
                    startActivity(Intent.createChooser(i, f.getName()));
                } catch (Exception e) {
                    Toast.makeText(MainActivity.this, "Bu faylni ochadigan dastur topilmadi", Toast.LENGTH_LONG).show();
                }
            });
        }

        @JavascriptInterface
        public void share(final String path) {
            runOnUiThread(() -> {
                try {
                    File f = new File(path);
                    Intent i = new Intent(Intent.ACTION_SEND);
                    i.setType(FileShare.mimeOf(f.getName()));
                    i.putExtra(Intent.EXTRA_STREAM, FileShare.uriFor(f));
                    i.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
                    startActivity(Intent.createChooser(i, f.getName()));
                } catch (Exception e) {
                    Toast.makeText(MainActivity.this, "Ulashib bo'lmadi", Toast.LENGTH_LONG).show();
                }
            });
        }

        @JavascriptInterface
        public void shareText(final String title, final String text) {
            runOnUiThread(() -> {
                try {
                    Intent i = new Intent(Intent.ACTION_SEND);
                    i.setType("text/plain");
                    i.putExtra(Intent.EXTRA_SUBJECT, title);
                    i.putExtra(Intent.EXTRA_TEXT, text);
                    startActivity(Intent.createChooser(i, title));
                } catch (Exception e) {
                    Toast.makeText(MainActivity.this, "Ulashib bo'lmadi", Toast.LENGTH_LONG).show();
                }
            });
        }

        /** Zametka va sozlamalar dasturning o'z xotirasida saqlanadi. */
        @JavascriptInterface
        public boolean save(String key, String value) {
            if (key == null || !key.matches("[a-z0-9_]{1,40}")) return false;
            File tmp = new File(getFilesDir(), key + ".tmp");
            File dst = new File(getFilesDir(), key + ".json");
            try (FileOutputStream os = new FileOutputStream(tmp)) {
                os.write(value.getBytes(StandardCharsets.UTF_8));
            } catch (Exception e) {
                return false;
            }
            return tmp.renameTo(dst);
        }

        @JavascriptInterface
        public String load(String key) {
            if (key == null || !key.matches("[a-z0-9_]{1,40}")) return "";
            File f = new File(getFilesDir(), key + ".json");
            if (!f.isFile()) return "";
            try (FileInputStream in = new FileInputStream(f)) {
                byte[] buf = new byte[(int) f.length()];
                int off = 0;
                while (off < buf.length) {
                    int n = in.read(buf, off, buf.length - off);
                    if (n < 0) break;
                    off += n;
                }
                return new String(buf, 0, off, StandardCharsets.UTF_8);
            } catch (Exception e) {
                return "";
            }
        }

        @JavascriptInterface
        public boolean camPerm() {
            if (hasCam()) return true;
            runOnUiThread(() -> requestPermissions(new String[]{Manifest.permission.CAMERA}, REQ_CAMPERM));
            return false;
        }

        @JavascriptInterface
        public void cam(final String tag) {
            runOnUiThread(() -> {
                try {
                    if (!hasCam()) {
                        requestPermissions(new String[]{Manifest.permission.CAMERA}, REQ_CAMPERM);
                        return;
                    }
                    File f = new File(FileShare.camDir(MainActivity.this), "p_" + System.currentTimeMillis() + ".jpg");
                    f.createNewFile();
                    camFile = f;
                    camTag = tag;
                    Uri uri = FileShare.camUri(f);
                    Intent i = new Intent(MediaStore.ACTION_IMAGE_CAPTURE);
                    i.putExtra(MediaStore.EXTRA_OUTPUT, uri);
                    i.setClipData(ClipData.newRawUri("", uri));
                    i.addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION | Intent.FLAG_GRANT_READ_URI_PERMISSION);
                    startActivityForResult(i, REQ_CAM);
                } catch (Exception e) {
                    Toast.makeText(MainActivity.this, "Kamera ochilmadi", Toast.LENGTH_LONG).show();
                }
            });
        }

        @JavascriptInterface
        public void pick(final String tag) {
            runOnUiThread(() -> {
                try {
                    camTag = tag;
                    Intent i = new Intent(Intent.ACTION_GET_CONTENT);
                    i.setType("image/*");
                    i.addCategory(Intent.CATEGORY_OPENABLE);
                    startActivityForResult(Intent.createChooser(i, "Rasm tanlang"), REQ_PICK);
                } catch (Exception e) {
                    Toast.makeText(MainActivity.this, "Galereya ochilmadi", Toast.LENGTH_LONG).show();
                }
            });
        }

        /** Vaqtinchalik suratni data: URL qilib qaytaradi (faqat dasturning cam papkasidan). */
        @JavascriptInterface
        public String photoData(String path, int max) {
            try {
                File f = new File(path);
                if (!f.getCanonicalPath().startsWith(FileShare.camDir(MainActivity.this).getCanonicalPath())) return "";
                Bitmap bm = loadPhoto(path, Math.max(400, Math.min(max, 2400)));
                ByteArrayOutputStream bo = new ByteArrayOutputStream();
                bm.compress(Bitmap.CompressFormat.JPEG, 88, bo);
                bm.recycle();
                return "data:image/jpeg;base64," + Base64.encodeToString(bo.toByteArray(), Base64.NO_WRAP);
            } catch (Throwable t) {
                return "";
            }
        }

        @JavascriptInterface
        public String decodeImg(String b64) {
            try {
                return readCode(fromB64(b64), false);
            } catch (Throwable t) {
                return "";
            }
        }

        @JavascriptInterface
        public String decodeFile(String path) {
            try {
                String r = readCode(loadPhoto(path, 1600), true);
                if (r.isEmpty()) r = readCode(loadPhoto(path, 800), true);
                return r;
            } catch (Throwable t) {
                return "";
            }
        }

        /** QR matritsasi: {n: o'lcham, d: "0101..."} */
        @JavascriptInterface
        public String qr(String text) {
            try {
                Map<EncodeHintType, Object> hints = new EnumMap<>(EncodeHintType.class);
                hints.put(EncodeHintType.CHARACTER_SET, "UTF-8");
                hints.put(EncodeHintType.MARGIN, 0);
                hints.put(EncodeHintType.ERROR_CORRECTION, ErrorCorrectionLevel.M);
                BitMatrix m = new QRCodeWriter().encode(text, BarcodeFormat.QR_CODE, 0, 0, hints);
                int n = m.getWidth();
                StringBuilder sb = new StringBuilder(n * n);
                for (int y = 0; y < n; y++) for (int x = 0; x < n; x++) sb.append(m.get(x, y) ? '1' : '0');
                JSONObject o = new JSONObject();
                o.put("n", n);
                o.put("d", sb.toString());
                return o.toString();
            } catch (Throwable t) {
                return "";
            }
        }

        @JavascriptInterface
        public String savePng(String name, String b64) {
            try {
                Bitmap bm = fromB64(b64);
                if (bm == null) return "";
                File f = freeName(outDir(Environment.DIRECTORY_PICTURES, "Chaqmoq"), cleanName(name, "QR") + ".png");
                try (FileOutputStream os = new FileOutputStream(f)) {
                    bm.compress(Bitmap.CompressFormat.PNG, 100, os);
                }
                MediaScannerConnection.scanFile(MainActivity.this, new String[]{f.getAbsolutePath()}, null, null);
                return f.getAbsolutePath();
            } catch (Throwable t) {
                return "";
            }
        }

        @JavascriptInterface
        public void pdfBegin() {
            try { if (pdf != null) pdf.close(); } catch (Exception ignored) { }
            pdf = new PdfDocument();
            pdfPages = 0;
        }

        @JavascriptInterface
        public boolean pdfPage(String b64) {
            try {
                Bitmap bm = fromB64(b64);
                if (bm == null || pdf == null) return false;
                boolean land = bm.getWidth() > bm.getHeight();
                int pw = land ? 842 : 595, ph = land ? 595 : 842;
                PdfDocument.Page page = pdf.startPage(new PdfDocument.PageInfo.Builder(pw, ph, ++pdfPages).create());
                Canvas c = page.getCanvas();
                c.drawColor(Color.WHITE);
                float sc = Math.min((float) pw / bm.getWidth(), (float) ph / bm.getHeight());
                float w = bm.getWidth() * sc, h = bm.getHeight() * sc;
                float l = (pw - w) / 2f, t = (ph - h) / 2f;
                c.drawBitmap(bm, null, new RectF(l, t, l + w, t + h), new Paint(Paint.FILTER_BITMAP_FLAG));
                pdf.finishPage(page);
                bm.recycle();
                return true;
            } catch (Throwable t) {
                return false;
            }
        }

        @JavascriptInterface
        public String pdfEnd(String name) {
            if (pdf == null) return "";
            try {
                if (pdfPages == 0) return "";
                File f = freeName(outDir(Environment.DIRECTORY_DOCUMENTS, "Chaqmoq"), cleanName(name, "Skan") + ".pdf");
                try (FileOutputStream os = new FileOutputStream(f)) {
                    pdf.writeTo(os);
                }
                MediaScannerConnection.scanFile(MainActivity.this, new String[]{f.getAbsolutePath()}, null, null);
                return f.getAbsolutePath();
            } catch (Throwable t) {
                return "";
            } finally {
                try { pdf.close(); } catch (Exception ignored) { }
                pdf = null;
            }
        }

        @JavascriptInterface
        public void copy(final String text) {
            runOnUiThread(() -> {
                ClipboardManager cm = (ClipboardManager) getSystemService(CLIPBOARD_SERVICE);
                if (cm != null) cm.setPrimaryClip(ClipData.newPlainText("Chaqmoq", text));
            });
        }

        @JavascriptInterface
        public void openUrl(final String url) {
            runOnUiThread(() -> {
                try {
                    startActivity(new Intent(Intent.ACTION_VIEW, Uri.parse(url)));
                } catch (Exception e) {
                    Toast.makeText(MainActivity.this, "Ochadigan dastur topilmadi", Toast.LENGTH_LONG).show();
                }
            });
        }

        @JavascriptInterface
        public void bars(final String color, final boolean darkIcons) {
            runOnUiThread(() -> {
                try {
                    int c = Color.parseColor(color);
                    getWindow().setStatusBarColor(c);
                    getWindow().setNavigationBarColor(c);
                    View v = getWindow().getDecorView();
                    int flags = v.getSystemUiVisibility();
                    int light = View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR | View.SYSTEM_UI_FLAG_LIGHT_NAVIGATION_BAR;
                    v.setSystemUiVisibility(darkIcons ? (flags | light) : (flags & ~light));
                    web.setBackgroundColor(c);
                } catch (Exception ignored) { }
            });
        }

        @JavascriptInterface
        public void toast(String text) {
            toastUi(text);
        }
    }
}
