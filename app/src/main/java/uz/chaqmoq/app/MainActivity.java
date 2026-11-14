package uz.chaqmoq.app;

import android.Manifest;
import android.app.Activity;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.graphics.Color;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.os.StatFs;
import android.provider.Settings;
import android.view.View;
import android.webkit.JavascriptInterface;
import android.webkit.WebChromeClient;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.Toast;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.charset.StandardCharsets;

public class MainActivity extends Activity {
    private WebView web;
    private static final int REQ_PERM = 7;

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

        web.addJavascriptInterface(new Bridge(), "Native");
        web.setWebViewClient(new WebViewClient());
        web.setWebChromeClient(new WebChromeClient());
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
