package uz.jarvis.app;

import android.Manifest;
import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import android.database.Cursor;
import android.graphics.Color;
import android.hardware.camera2.CameraCharacteristics;
import android.hardware.camera2.CameraManager;
import android.media.AudioManager;
import android.net.Uri;
import android.os.BatteryManager;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.os.VibrationEffect;
import android.os.Vibrator;
import android.provider.AlarmClock;
import android.provider.ContactsContract;
import android.provider.Settings;
import android.speech.RecognitionListener;
import android.speech.RecognizerIntent;
import android.speech.SpeechRecognizer;
import android.speech.tts.TextToSpeech;
import android.speech.tts.UtteranceProgressListener;
import android.speech.tts.Voice;
import android.telephony.SmsManager;
import android.view.View;
import android.view.WindowManager;
import android.webkit.JavascriptInterface;
import android.webkit.WebChromeClient;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.Toast;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;

public class MainActivity extends Activity {
    private WebView web;
    private TextToSpeech tts;
    private boolean ttsReady = false;
    private SpeechRecognizer recognizer;
    private SharedPreferences prefs;
    private CloudVoice cloud;
    private final Handler ui = new Handler(Looper.getMainLooper());
    private long lastLevel = 0;
    private static final int REQ_PERMS = 11;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        prefs = getSharedPreferences("jarvis", MODE_PRIVATE);
        getWindow().setStatusBarColor(Color.parseColor("#02050C"));
        getWindow().setNavigationBarColor(Color.parseColor("#02050C"));
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);

        web = new WebView(this);
        web.setBackgroundColor(Color.parseColor("#02050C"));
        web.setOverScrollMode(View.OVER_SCROLL_NEVER);
        web.setVerticalScrollBarEnabled(false);
        WebSettings s = web.getSettings();
        s.setJavaScriptEnabled(true);
        s.setDomStorageEnabled(true);
        s.setAllowFileAccess(true);
        s.setMediaPlaybackRequiresUserGesture(false);
        s.setTextZoom(100);
        s.setSupportZoom(false);
        web.addJavascriptInterface(new Bridge(), "Native");
        web.setWebViewClient(new WebViewClient());
        web.setWebChromeClient(new WebChromeClient());
        setContentView(web);
        web.loadUrl("file:///android_asset/index.html");

        cloud = new CloudVoice(this, new CloudVoice.Events() {
            @Override public void onStart() { js("window.onTtsStart&&window.onTtsStart()"); }
            @Override public void onDone() { js("window.onTtsDone&&window.onTtsDone()"); }
            @Override public void onFail(String engine, String msg) {
                js("window.onCloudFail&&window.onCloudFail(" + JSONObject.quote(engine) + "," + JSONObject.quote(msg) + ")");
            }
        });

        tts = new TextToSpeech(this, status -> {
            ttsReady = status == TextToSpeech.SUCCESS;
            if (ttsReady) {
                tts.setOnUtteranceProgressListener(new UtteranceProgressListener() {
                    @Override public void onStart(String id) { js("window.onTtsStart&&window.onTtsStart()"); }
                    @Override public void onDone(String id) { js("window.onTtsDone&&window.onTtsDone()"); }
                    @Override public void onError(String id) { js("window.onTtsDone&&window.onTtsDone()"); }
                });
            }
            js("window.onTtsReady&&window.onTtsReady(" + ttsReady + ")");
        });
    }

    private void js(final String code) {
        ui.post(() -> { if (web != null) web.evaluateJavascript(code, null); });
    }

    private boolean has(String perm) {
        return checkSelfPermission(perm) == PackageManager.PERMISSION_GRANTED;
    }

    @Override
    public void onRequestPermissionsResult(int code, String[] perms, int[] res) {
        super.onRequestPermissionsResult(code, perms, res);
        js("window.onPerms&&window.onPerms()");
    }

    @Override
    public void onBackPressed() {
        web.evaluateJavascript("window.onBack?window.onBack():false", v -> {
            if (!"true".equals(v)) MainActivity.super.onBackPressed();
        });
    }

    private boolean muted = false;
    private void setQuiet(boolean on) {
        ui.post(() -> {
            if (on == muted) return;
            try {
                AudioManager am = (AudioManager) getSystemService(Context.AUDIO_SERVICE);
                int dir = on ? AudioManager.ADJUST_MUTE : AudioManager.ADJUST_UNMUTE;
                am.adjustStreamVolume(AudioManager.STREAM_MUSIC, dir, 0);
                am.adjustStreamVolume(AudioManager.STREAM_NOTIFICATION, dir, 0);
                am.adjustStreamVolume(AudioManager.STREAM_SYSTEM, dir, 0);
                muted = on;
            } catch (Exception ignored) { }
        });
    }

    @Override
    protected void onPause() {
        super.onPause();
        setQuiet(false);
        if (web != null) web.evaluateJavascript("window.onAppPause&&window.onAppPause()", null);
    }

    @Override
    protected void onResume() {
        super.onResume();
        if (web != null) web.evaluateJavascript("window.onAppResume&&window.onAppResume()", null);
    }

    @Override
    protected void onDestroy() {
        setQuiet(false);
        try { if (tts != null) { tts.stop(); tts.shutdown(); } } catch (Exception ignored) { }
        try { if (recognizer != null) recognizer.destroy(); } catch (Exception ignored) { }
        try { if (cloud != null) cloud.stop(); } catch (Exception ignored) { }
        super.onDestroy();
    }

    private Locale localeOf(String tag) {
        if (tag == null || tag.isEmpty()) return Locale.getDefault();
        return Locale.forLanguageTag(tag);
    }

    private class Bridge {

        // ---------- ruxsatlar ----------
        @JavascriptInterface
        public boolean hasPerm(String name) {
            return has(permOf(name));
        }

        @JavascriptInterface
        public void askPerms(String csv) {
            List<String> need = new ArrayList<>();
            for (String n : csv.split(",")) {
                String p = permOf(n.trim());
                if (p != null && !has(p)) need.add(p);
            }
            if (need.isEmpty()) { js("window.onPerms&&window.onPerms()"); return; }
            ui.post(() -> requestPermissions(need.toArray(new String[0]), REQ_PERMS));
        }

        private String permOf(String n) {
            switch (n) {
                case "mic": return Manifest.permission.RECORD_AUDIO;
                case "contacts": return Manifest.permission.READ_CONTACTS;
                case "sms": return Manifest.permission.SEND_SMS;
                case "call": return Manifest.permission.CALL_PHONE;
                case "camera": return Manifest.permission.CAMERA;
                default: return Manifest.permission.RECORD_AUDIO;
            }
        }

        // ---------- ovozni tanish ----------
        @JavascriptInterface
        public boolean canListen() {
            return SpeechRecognizer.isRecognitionAvailable(MainActivity.this);
        }

        @JavascriptInterface
        public void listen(final String lang) { listenS(lang, 0, false); }

        @JavascriptInterface
        public void listenS(final String lang, final int sid, final boolean passive) {
            ui.post(() -> {
                if (!has(Manifest.permission.RECORD_AUDIO)) {
                    requestPermissions(new String[]{Manifest.permission.RECORD_AUDIO}, REQ_PERMS);
                    js("window.onListenError&&window.onListenError(-1," + sid + ")");
                    return;
                }
                try {
                    if (recognizer != null) { recognizer.destroy(); recognizer = null; }
                    recognizer = SpeechRecognizer.createSpeechRecognizer(MainActivity.this);
                    recognizer.setRecognitionListener(new RecognitionListener() {
                        @Override public void onReadyForSpeech(Bundle b) { js("window.onListenStart&&window.onListenStart(" + sid + ")"); }
                        @Override public void onBeginningOfSpeech() { }
                        @Override public void onRmsChanged(float r) {
                            long now = System.currentTimeMillis();
                            if (!passive && now - lastLevel > 80) { lastLevel = now; js("window.onLevel&&window.onLevel(" + r + "," + sid + ")"); }
                        }
                        @Override public void onBufferReceived(byte[] b) { }
                        @Override public void onEndOfSpeech() { js("window.onListenEnd&&window.onListenEnd(" + sid + ")"); }
                        @Override public void onError(int e) { js("window.onListenError&&window.onListenError(" + e + "," + sid + ")"); }
                        @Override public void onResults(Bundle b) {
                            ArrayList<String> r = b.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION);
                            String t = (r != null && !r.isEmpty()) ? r.get(0) : "";
                            js("window.onHeard&&window.onHeard(" + JSONObject.quote(t) + "," + sid + ")");
                        }
                        @Override public void onPartialResults(Bundle b) {
                            ArrayList<String> r = b.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION);
                            if (r != null && !r.isEmpty()) js("window.onPartial&&window.onPartial(" + JSONObject.quote(r.get(0)) + "," + sid + ")");
                        }
                        @Override public void onEvent(int t, Bundle b) { }
                    });
                    Intent it = new Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH);
                    it.putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM);
                    it.putExtra(RecognizerIntent.EXTRA_LANGUAGE, lang);
                    it.putExtra(RecognizerIntent.EXTRA_LANGUAGE_PREFERENCE, lang);
                    it.putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true);
                    it.putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1);
                    if (passive) {
                        it.putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_COMPLETE_SILENCE_LENGTH_MILLIS, 900);
                        it.putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_POSSIBLY_COMPLETE_SILENCE_LENGTH_MILLIS, 900);
                    }
                    recognizer.startListening(it);
                } catch (Exception e) {
                    js("window.onListenError&&window.onListenError(-2," + sid + ")");
                }
            });
        }

        @JavascriptInterface
        public void quiet(boolean on) { setQuiet(on); }

        @JavascriptInterface
        public void stopListen() {
            ui.post(() -> { try { if (recognizer != null) recognizer.stopListening(); } catch (Exception ignored) { } });
        }

        // ---------- ovozli javob ----------
        @JavascriptInterface
        public String ttsLangs() {
            JSONArray a = new JSONArray();
            if (!ttsReady) return a.toString();
            for (String tag : new String[]{"uz-UZ", "tr-TR", "ru-RU", "en-US"}) {
                try {
                    int r = tts.isLanguageAvailable(localeOf(tag));
                    if (r >= TextToSpeech.LANG_AVAILABLE) a.put(tag);
                } catch (Exception ignored) { }
            }
            return a.toString();
        }

        @JavascriptInterface
        public boolean speak(String text, String lang, float rate, float pitch) {
            if (!ttsReady) return false;
            try { cloud.stop(); } catch (Exception ignored) { }
            try {
                int r = tts.setLanguage(localeOf(lang));
                if (r < TextToSpeech.LANG_AVAILABLE) tts.setLanguage(Locale.getDefault());
                tts.setSpeechRate(rate <= 0 ? 1f : rate);
                tts.setPitch(pitch <= 0 ? 1f : pitch);
                Bundle p = new Bundle();
                return tts.speak(text, TextToSpeech.QUEUE_FLUSH, p, "j" + System.currentTimeMillis()) == TextToSpeech.SUCCESS;
            } catch (Exception e) { return false; }
        }

        @JavascriptInterface
        public void speakCloud(String engine, String text, String opts) {
            try { if (tts != null) tts.stop(); } catch (Exception ignored) { }
            cloud.speak(engine, text, opts);
        }

        @JavascriptInterface
        public void stopSpeak() {
            try { if (tts != null) tts.stop(); } catch (Exception ignored) { }
            try { cloud.stop(); } catch (Exception ignored) { }
            js("window.onTtsDone&&window.onTtsDone()");
        }

        @JavascriptInterface
        public void openTtsSettings() {
            ui.post(() -> {
                try { startActivity(new Intent("com.android.settings.TTS_SETTINGS")); }
                catch (Exception e) { try { startActivity(new Intent(Settings.ACTION_SETTINGS)); } catch (Exception ignored) { } }
            });
        }

        // ---------- internet ----------
        @JavascriptInterface
        public void http(final String id, final String url, final String body) {
            httpH(id, url, body, "{}");
        }

        @JavascriptInterface
        public void httpH(final String id, final String url, final String body, final String headers) {
            new Thread(() -> {
                int code = 0;
                String out;
                try {
                    HttpURLConnection c = (HttpURLConnection) new URL(url).openConnection();
                    c.setConnectTimeout(20000);
                    c.setReadTimeout(60000);
                    c.setRequestProperty("Content-Type", "application/json; charset=utf-8");
                    try {
                        JSONObject h = new JSONObject(headers == null || headers.isEmpty() ? "{}" : headers);
                        java.util.Iterator<String> it = h.keys();
                        while (it.hasNext()) { String k = it.next(); c.setRequestProperty(k, h.getString(k)); }
                    } catch (Exception ignored) { }
                    if (body != null && !body.isEmpty()) {
                        c.setRequestMethod("POST");
                        c.setDoOutput(true);
                        try (OutputStream o = c.getOutputStream()) { o.write(body.getBytes(StandardCharsets.UTF_8)); }
                    }
                    code = c.getResponseCode();
                    InputStream in = code >= 400 ? c.getErrorStream() : c.getInputStream();
                    ByteArrayOutputStream bo = new ByteArrayOutputStream();
                    if (in != null) {
                        byte[] buf = new byte[8192];
                        int n;
                        while ((n = in.read(buf)) > 0) bo.write(buf, 0, n);
                        in.close();
                    }
                    out = new String(bo.toByteArray(), StandardCharsets.UTF_8);
                } catch (Exception e) {
                    out = "{\"error\":{\"message\":" + JSONObject.quote(String.valueOf(e.getMessage())) + "}}";
                }
                js("window.onHttp&&window.onHttp(" + JSONObject.quote(id) + "," + code + "," + JSONObject.quote(out) + ")");
            }).start();
        }

        // ---------- xotira ----------
        @JavascriptInterface
        public String get(String k) { return prefs.getString(k, ""); }

        @JavascriptInterface
        public void set(String k, String v) { prefs.edit().putString(k, v).apply(); }

        // ---------- telefon funksiyalari ----------
        @JavascriptInterface
        public boolean torch(boolean on) {
            try {
                CameraManager cm = (CameraManager) getSystemService(Context.CAMERA_SERVICE);
                for (String id : cm.getCameraIdList()) {
                    Boolean f = cm.getCameraCharacteristics(id).get(CameraCharacteristics.FLASH_INFO_AVAILABLE);
                    if (f != null && f) { cm.setTorchMode(id, on); return true; }
                }
            } catch (Exception ignored) { }
            return false;
        }

        @JavascriptInterface
        public boolean setAlarm(int h, int m, String label) {
            try {
                Intent i = new Intent(AlarmClock.ACTION_SET_ALARM);
                i.putExtra(AlarmClock.EXTRA_HOUR, h);
                i.putExtra(AlarmClock.EXTRA_MINUTES, m);
                if (label != null && !label.isEmpty()) i.putExtra(AlarmClock.EXTRA_MESSAGE, label);
                i.putExtra(AlarmClock.EXTRA_SKIP_UI, true);
                i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                startActivity(i);
                return true;
            } catch (Exception e) { return false; }
        }

        @JavascriptInterface
        public boolean setTimer(int seconds, String label) {
            try {
                Intent i = new Intent(AlarmClock.ACTION_SET_TIMER);
                i.putExtra(AlarmClock.EXTRA_LENGTH, seconds);
                if (label != null && !label.isEmpty()) i.putExtra(AlarmClock.EXTRA_MESSAGE, label);
                i.putExtra(AlarmClock.EXTRA_SKIP_UI, true);
                i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                startActivity(i);
                return true;
            } catch (Exception e) { return false; }
        }

        @JavascriptInterface
        public String contacts() {
            JSONArray a = new JSONArray();
            if (!has(Manifest.permission.READ_CONTACTS)) return "null";
            Set<String> seen = new HashSet<>();
            try (Cursor c = getContentResolver().query(
                    ContactsContract.CommonDataKinds.Phone.CONTENT_URI,
                    new String[]{ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME, ContactsContract.CommonDataKinds.Phone.NUMBER},
                    null, null, ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME + " ASC")) {
                if (c != null) {
                    while (c.moveToNext()) {
                        String name = c.getString(0), num = c.getString(1);
                        if (name == null || num == null) continue;
                        String key = name + "|" + num.replaceAll("[^0-9+]", "");
                        if (!seen.add(key)) continue;
                        JSONObject o = new JSONObject();
                        o.put("n", name);
                        o.put("p", num);
                        a.put(o);
                    }
                }
            } catch (Exception ignored) { }
            return a.toString();
        }

        @JavascriptInterface
        public boolean call(String phone) {
            try {
                boolean direct = has(Manifest.permission.CALL_PHONE);
                Intent i = new Intent(direct ? Intent.ACTION_CALL : Intent.ACTION_DIAL, Uri.parse("tel:" + Uri.encode(phone)));
                i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                startActivity(i);
                return true;
            } catch (Exception e) { return false; }
        }

        @JavascriptInterface
        public String sendSms(String phone, String text) {
            if (!has(Manifest.permission.SEND_SMS)) return "perm";
            try {
                SmsManager sm = Build.VERSION.SDK_INT >= 31 ? getSystemService(SmsManager.class) : SmsManager.getDefault();
                ArrayList<String> parts = sm.divideMessage(text);
                sm.sendMultipartTextMessage(phone, null, parts, null, null);
                return "ok";
            } catch (Exception e) { return "err:" + e.getMessage(); }
        }

        @JavascriptInterface
        public String telegram(String text) {
            String[] pk = {"org.telegram.messenger", "org.telegram.messenger.web", "org.thunderdog.challegram"};
            for (String p : pk) {
                try {
                    getPackageManager().getPackageInfo(p, 0);
                    Intent i = new Intent(Intent.ACTION_SEND);
                    i.setType("text/plain");
                    i.putExtra(Intent.EXTRA_TEXT, text);
                    i.setPackage(p);
                    i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                    startActivity(i);
                    return p;
                } catch (Exception ignored) { }
            }
            return "";
        }

        @JavascriptInterface
        public String openApp(String name) {
            try {
                String q = name.toLowerCase(Locale.ROOT).trim();
                PackageManager pm = getPackageManager();
                Intent main = new Intent(Intent.ACTION_MAIN);
                main.addCategory(Intent.CATEGORY_LAUNCHER);
                List<ResolveInfo> list = pm.queryIntentActivities(main, 0);
                ResolveInfo best = null;
                int bestScore = 0;
                for (ResolveInfo r : list) {
                    String label = String.valueOf(r.loadLabel(pm)).toLowerCase(Locale.ROOT);
                    String pkg = r.activityInfo.packageName.toLowerCase(Locale.ROOT);
                    int sc = 0;
                    if (label.equals(q)) sc = 100;
                    else if (label.startsWith(q)) sc = 80;
                    else if (label.contains(q)) sc = 60;
                    else if (q.contains(label) && label.length() > 2) sc = 50;
                    else if (pkg.contains(q.replace(" ", ""))) sc = 40;
                    if (sc > bestScore) { bestScore = sc; best = r; }
                }
                if (best == null) return "";
                Intent i = pm.getLaunchIntentForPackage(best.activityInfo.packageName);
                if (i == null) return "";
                i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                startActivity(i);
                return String.valueOf(best.loadLabel(pm));
            } catch (Exception e) { return ""; }
        }

        @JavascriptInterface
        public boolean openUrl(String url) {
            try {
                Intent i = new Intent(Intent.ACTION_VIEW, Uri.parse(url));
                i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                startActivity(i);
                return true;
            } catch (Exception e) { return false; }
        }

        @JavascriptInterface
        public boolean openSettings(String which) {
            String a;
            switch (which) {
                case "wifi": a = Settings.ACTION_WIFI_SETTINGS; break;
                case "bluetooth": a = Settings.ACTION_BLUETOOTH_SETTINGS; break;
                case "display": a = Settings.ACTION_DISPLAY_SETTINGS; break;
                case "sound": a = Settings.ACTION_SOUND_SETTINGS; break;
                case "location": a = Settings.ACTION_LOCATION_SOURCE_SETTINGS; break;
                default: a = Settings.ACTION_SETTINGS;
            }
            try {
                Intent i = new Intent(a);
                i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                startActivity(i);
                return true;
            } catch (Exception e) { return false; }
        }

        @JavascriptInterface
        public boolean openCamera() {
            try {
                Intent i = new Intent("android.media.action.STILL_IMAGE_CAMERA");
                i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                startActivity(i);
                return true;
            } catch (Exception e) { return false; }
        }

        @JavascriptInterface
        public String battery() {
            try {
                BatteryManager bm = (BatteryManager) getSystemService(Context.BATTERY_SERVICE);
                int lvl = bm.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY);
                Intent b = registerReceiver(null, new IntentFilter(Intent.ACTION_BATTERY_CHANGED));
                int st = b != null ? b.getIntExtra(BatteryManager.EXTRA_STATUS, -1) : -1;
                boolean ch = st == BatteryManager.BATTERY_STATUS_CHARGING || st == BatteryManager.BATTERY_STATUS_FULL;
                return "{\"level\":" + lvl + ",\"charging\":" + ch + "}";
            } catch (Exception e) { return "{\"level\":-1,\"charging\":false}"; }
        }

        @JavascriptInterface
        public int volume(int percent) {
            try {
                AudioManager am = (AudioManager) getSystemService(Context.AUDIO_SERVICE);
                int max = am.getStreamMaxVolume(AudioManager.STREAM_MUSIC);
                if (percent >= 0) am.setStreamVolume(AudioManager.STREAM_MUSIC, Math.round(max * Math.min(100, percent) / 100f), 0);
                return Math.round(am.getStreamVolume(AudioManager.STREAM_MUSIC) * 100f / max);
            } catch (Exception e) { return -1; }
        }

        @JavascriptInterface
        public void vibrate(int ms) {
            try {
                Vibrator v = (Vibrator) getSystemService(Context.VIBRATOR_SERVICE);
                if (v != null) v.vibrate(VibrationEffect.createOneShot(ms, VibrationEffect.DEFAULT_AMPLITUDE));
            } catch (Exception ignored) { }
        }

        @JavascriptInterface
        public void toast(String msg) {
            ui.post(() -> Toast.makeText(MainActivity.this, msg, Toast.LENGTH_SHORT).show());
        }
    }
}
