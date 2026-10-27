package uz.shitlab.app;

import android.app.Activity;
import android.content.ContentValues;
import android.content.Intent;
import android.graphics.Color;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.CancellationSignal;
import android.os.ParcelFileDescriptor;
import android.print.PageRange;
import android.print.PrintAttributes;
import android.print.PrintDocumentAdapter;
import android.print.PrintDocumentInfo;
import android.print.PrintManager;
import android.os.Environment;
import android.provider.MediaStore;
import android.util.Base64;
import android.webkit.JavascriptInterface;
import android.webkit.ValueCallback;
import android.webkit.WebChromeClient;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.Toast;

import java.io.File;
import java.io.FileOutputStream;
import java.io.OutputStream;

public class MainActivity extends Activity {
    private WebView web;
    private ValueCallback<Uri[]> fileCb;
    private static final int PICK = 41;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        getWindow().setStatusBarColor(Color.parseColor("#1C2226"));
        getWindow().setNavigationBarColor(Color.parseColor("#1C2226"));

        web = new WebView(this);
        web.setBackgroundColor(Color.parseColor("#ECEFF1"));
        WebSettings s = web.getSettings();
        s.setJavaScriptEnabled(true);
        s.setDomStorageEnabled(true);
        s.setDatabaseEnabled(true);
        s.setAllowFileAccess(true);
        s.setMediaPlaybackRequiresUserGesture(false);
        s.setBuiltInZoomControls(true);
        s.setDisplayZoomControls(false);
        s.setUseWideViewPort(true);
        s.setLoadWithOverviewMode(true);
        s.setUserAgentString(s.getUserAgentString() + " ShitLabApp/4.3");

        web.addJavascriptInterface(new Bridge(), "ShitLabNative");
        web.setWebViewClient(new WebViewClient());
        web.setWebChromeClient(new WebChromeClient() {
            @Override
            public boolean onShowFileChooser(WebView v, ValueCallback<Uri[]> cb, FileChooserParams p) {
                if (fileCb != null) fileCb.onReceiveValue(null);
                fileCb = cb;
                try {
                    startActivityForResult(p.createIntent(), PICK);
                } catch (Exception e) {
                    fileCb = null;
                    return false;
                }
                return true;
            }
        });
        setContentView(web);

        if (savedInstanceState != null) {
            web.restoreState(savedInstanceState);
        } else {
            web.loadUrl("file:///android_asset/index.html");
        }
    }

    @Override
    protected void onActivityResult(int req, int res, Intent data) {
        if (req == PICK && fileCb != null) {
            fileCb.onReceiveValue(WebChromeClient.FileChooserParams.parseResult(res, data));
            fileCb = null;
            return;
        }
        super.onActivityResult(req, res, data);
    }

    /** JavaScript ko'prigi: fayl saqlash va ulashish */
    private class Bridge {
        @JavascriptInterface
        public void saveFile(final String name, final String b64, final String mime) {
            runOnUiThread(() -> {
                try {
                    byte[] bytes = Base64.decode(b64, Base64.DEFAULT);
                    Uri uri = null;
                    String where;
                    if (Build.VERSION.SDK_INT >= 29) {
                        ContentValues cv = new ContentValues();
                        cv.put(MediaStore.Downloads.DISPLAY_NAME, name);
                        cv.put(MediaStore.Downloads.MIME_TYPE, mime);
                        cv.put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS + "/ShitLab");
                        uri = getContentResolver().insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, cv);
                        try (OutputStream os = getContentResolver().openOutputStream(uri)) { os.write(bytes); }
                        where = "Download/ShitLab/" + name;
                    } else {
                        File dir = getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS);
                        File f = new File(dir, name);
                        try (FileOutputStream os = new FileOutputStream(f)) { os.write(bytes); }
                        where = f.getAbsolutePath();
                    }
                    Toast.makeText(MainActivity.this, "Saqlandi: " + where, Toast.LENGTH_LONG).show();
                    if (uri != null) {
                        Intent send = new Intent(Intent.ACTION_SEND);
                        send.setType(mime);
                        send.putExtra(Intent.EXTRA_STREAM, uri);
                        send.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
                        startActivity(Intent.createChooser(send, "Ulashish yoki ochish: " + name));
                    }
                } catch (Exception e) {
                    Toast.makeText(MainActivity.this, "Saqlab bo'lmadi: " + e.getMessage(), Toast.LENGTH_LONG).show();
                }
            });
        }

        @JavascriptInterface
        public void printPdf(final String name, final String b64) {
            runOnUiThread(() -> {
                try {
                    final byte[] bytes = Base64.decode(b64, Base64.DEFAULT);
                    PrintManager pm = (PrintManager) getSystemService(PRINT_SERVICE);
                    pm.print(name, new PrintDocumentAdapter() {
                        @Override
                        public void onLayout(PrintAttributes o, PrintAttributes n, CancellationSignal c, LayoutResultCallback cb, Bundle e) {
                            if (c.isCanceled()) { cb.onLayoutCancelled(); return; }
                            cb.onLayoutFinished(new PrintDocumentInfo.Builder(name)
                                .setContentType(PrintDocumentInfo.CONTENT_TYPE_DOCUMENT).build(), true);
                        }
                        @Override
                        public void onWrite(PageRange[] pages, ParcelFileDescriptor d, CancellationSignal c, WriteResultCallback cb) {
                            try (FileOutputStream os = new FileOutputStream(d.getFileDescriptor())) {
                                os.write(bytes);
                                cb.onWriteFinished(new PageRange[]{PageRange.ALL_PAGES});
                            } catch (Exception ex) {
                                cb.onWriteFailed(ex.getMessage());
                            }
                        }
                    }, new PrintAttributes.Builder().setMediaSize(PrintAttributes.MediaSize.ISO_A4).build());
                } catch (Exception e) {
                    Toast.makeText(MainActivity.this, "Chop etib bo'lmadi: " + e.getMessage(), Toast.LENGTH_LONG).show();
                }
            });
        }

        @JavascriptInterface
        public void openUrl(final String url) {
            runOnUiThread(() -> {
                try {
                    startActivity(new Intent(Intent.ACTION_VIEW, Uri.parse(url)));
                } catch (Exception e) {
                    Toast.makeText(MainActivity.this, "Brauzer topilmadi", Toast.LENGTH_LONG).show();
                }
            });
        }

        @JavascriptInterface
        public void copyText(final String text) {
            runOnUiThread(() -> {
                android.content.ClipboardManager cm = (android.content.ClipboardManager) getSystemService(CLIPBOARD_SERVICE);
                if (cm != null) cm.setPrimaryClip(android.content.ClipData.newPlainText("ShitLab", text));
            });
        }


        @JavascriptInterface
        public void share(final String title, final String text) {
            runOnUiThread(() -> {
                Intent send = new Intent(Intent.ACTION_SEND);
                send.setType("text/plain");
                send.putExtra(Intent.EXTRA_SUBJECT, title);
                send.putExtra(Intent.EXTRA_TEXT, text);
                startActivity(Intent.createChooser(send, title));
            });
        }
    }

    @Override
    protected void onSaveInstanceState(Bundle outState) {
        super.onSaveInstanceState(outState);
        web.saveState(outState);
    }

    @Override
    public void onBackPressed() {
        if (web.canGoBack()) {
            web.goBack();
        } else {
            super.onBackPressed();
        }
    }
}
