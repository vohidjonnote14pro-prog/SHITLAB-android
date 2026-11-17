package uz.jarvis.app;

import android.content.Context;
import android.media.AudioAttributes;
import android.media.MediaPlayer;
import android.util.Base64;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;
import java.util.Random;
import java.util.TimeZone;
import java.util.UUID;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;

import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;
import okhttp3.WebSocket;
import okhttp3.WebSocketListener;
import okio.ByteString;

/** Bulutli neyron ovozlar: Microsoft (Sardor/Madina) va Gemini TTS. */
public class CloudVoice {
    public interface Events {
        void onStart();
        void onDone();
        void onFail(String engine, String msg);
    }

    private static final String TRUSTED = "6A5AA1D4EAFF4E9FB37E23D68491D6F4";
    private static final String[] CHROME_VERSIONS = {"143.0.3650.75", "140.0.3485.14", "130.0.2849.68"};

    private final Context ctx;
    private final Events ev;
    private final AtomicInteger seq = new AtomicInteger();
    private MediaPlayer player;
    private final OkHttpClient client = new OkHttpClient.Builder()
            .connectTimeout(12, TimeUnit.SECONDS)
            .readTimeout(30, TimeUnit.SECONDS)
            .build();

    public CloudVoice(Context ctx, Events ev) {
        this.ctx = ctx;
        this.ev = ev;
    }

    public void stop() {
        seq.incrementAndGet();
        try { if (player != null) { player.stop(); player.release(); } } catch (Exception ignored) { }
        player = null;
    }

    public void speak(final String engine, final String text, final String optsJson) {
        final int my = seq.incrementAndGet();
        try { if (player != null) { player.stop(); player.release(); } } catch (Exception ignored) { }
        player = null;
        new Thread(() -> {
            try {
                JSONObject o = new JSONObject(optsJson == null || optsJson.isEmpty() ? "{}" : optsJson);
                File f;
                if (engine.startsWith("ms:")) f = edge(text, engine.substring(3), o.optString("rate", "+0%"), o.optString("pitch", "+0Hz"));
                else if (engine.equals("gemini")) f = gemini(text, o.optString("key"), o.optString("models"), o.optString("voice", "Charon"), o.optString("style", ""));
                else throw new Exception("engine");
                if (my != seq.get()) return;
                play(f, my);
            } catch (Exception e) {
                if (my == seq.get()) ev.onFail(engine, String.valueOf(e.getMessage()));
            }
        }).start();
    }

    private void play(File f, int my) throws Exception {
        MediaPlayer mp = new MediaPlayer();
        mp.setAudioAttributes(new AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_ASSISTANT)
                .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH).build());
        mp.setDataSource(f.getAbsolutePath());
        mp.setOnCompletionListener(m -> { if (my == seq.get()) ev.onDone(); try { m.release(); } catch (Exception ignored) { } if (player == m) player = null; });
        mp.setOnErrorListener((m, a, b) -> { if (my == seq.get()) ev.onFail("play", a + "/" + b); return true; });
        mp.prepare();
        if (my != seq.get()) { mp.release(); return; }
        player = mp;
        mp.start();
        ev.onStart();
    }

    // ---------------- Microsoft Edge neyron ovozi ----------------
    private static String secGec() throws Exception {
        long sec = System.currentTimeMillis() / 1000L + 11644473600L;
        sec -= sec % 300;
        String ticks = String.valueOf(sec) + "0000000";
        MessageDigest md = MessageDigest.getInstance("SHA-256");
        byte[] h = md.digest((ticks + TRUSTED).getBytes(StandardCharsets.US_ASCII));
        StringBuilder sb = new StringBuilder();
        for (byte b : h) sb.append(String.format(Locale.ROOT, "%02X", b));
        return sb.toString();
    }

    private static String stamp() {
        SimpleDateFormat f = new SimpleDateFormat("EEE MMM dd yyyy HH:mm:ss 'GMT+0000 (Coordinated Universal Time)'", Locale.US);
        f.setTimeZone(TimeZone.getTimeZone("UTC"));
        return f.format(new Date());
    }

    private static String esc(String s) {
        return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&apos;");
    }

    private File edge(String text, String voice, String rate, String pitch) throws Exception {
        String last = "edge";
        for (String ver : CHROME_VERSIONS) {
            try { return edgeOnce(text, voice, rate, pitch, ver); }
            catch (Exception e) { last = e.getMessage(); }
        }
        throw new Exception(last);
    }

    private File edgeOnce(String text, String voice, String rate, String pitch, String ver) throws Exception {
        String conn = UUID.randomUUID().toString().replace("-", "");
        String url = "wss://speech.platform.bing.com/consumer/speech/synthesize/readaloud/edge/v1?TrustedClientToken=" + TRUSTED
                + "&ConnectionId=" + conn + "&Sec-MS-GEC=" + secGec() + "&Sec-MS-GEC-Version=1-" + ver;
        String major = ver.split("\\.")[0];
        StringBuilder muid = new StringBuilder();
        Random r = new Random();
        for (int i = 0; i < 32; i++) muid.append("0123456789ABCDEF".charAt(r.nextInt(16)));
        Request req = new Request.Builder().url(url)
                .header("Pragma", "no-cache")
                .header("Cache-Control", "no-cache")
                .header("Origin", "chrome-extension://jdiccldimpdaibmpdkjnbmckianbfold")
                .header("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/" + major + ".0.0.0 Safari/537.36 Edg/" + major + ".0.0.0")
                .header("Accept-Language", "en-US,en;q=0.9")
                .header("Cookie", "muid=" + muid + ";")
                .build();
        final ByteArrayOutputStream audio = new ByteArrayOutputStream();
        final CountDownLatch done = new CountDownLatch(1);
        final String[] err = {null};
        final String reqId = UUID.randomUUID().toString().replace("-", "");
        final String ssml = "<speak version='1.0' xmlns='http://www.w3.org/2001/10/synthesis' xml:lang='uz-UZ'><voice name='" + voice + "'>"
                + "<prosody pitch='" + pitch + "' rate='" + rate + "' volume='+0%'>" + esc(text) + "</prosody></voice></speak>";
        WebSocket ws = client.newWebSocket(req, new WebSocketListener() {
            @Override public void onOpen(WebSocket w, Response resp) {
                String ts = stamp();
                w.send("X-Timestamp:" + ts + "\r\nContent-Type:application/json; charset=utf-8\r\nPath:speech.config\r\n\r\n"
                        + "{\"context\":{\"synthesis\":{\"audio\":{\"metadataoptions\":{\"sentenceBoundaryEnabled\":\"false\",\"wordBoundaryEnabled\":\"false\"},\"outputFormat\":\"audio-24khz-48kbitrate-mono-mp3\"}}}}");
                w.send("X-RequestId:" + reqId + "\r\nContent-Type:application/ssml+xml\r\nX-Timestamp:" + ts + "Z\r\nPath:ssml\r\n\r\n" + ssml);
            }
            @Override public void onMessage(WebSocket w, String t) {
                if (t.contains("Path:turn.end")) { done.countDown(); w.close(1000, null); }
            }
            @Override public void onMessage(WebSocket w, ByteString b) {
                byte[] d = b.toByteArray();
                if (d.length < 2) return;
                int hl = ((d[0] & 0xff) << 8) | (d[1] & 0xff);
                if (2 + hl > d.length) return;
                String head = new String(d, 2, hl, StandardCharsets.US_ASCII);
                if (head.contains("Path:audio")) audio.write(d, 2 + hl, d.length - 2 - hl);
            }
            @Override public void onFailure(WebSocket w, Throwable t, Response resp) {
                err[0] = (resp != null ? "HTTP " + resp.code() + " " : "") + t.getMessage();
                done.countDown();
            }
            @Override public void onClosed(WebSocket w, int code, String reason) { done.countDown(); }
        });
        if (!done.await(25, TimeUnit.SECONDS)) { ws.cancel(); throw new Exception("timeout"); }
        if (audio.size() < 500) throw new Exception(err[0] != null ? err[0] : "bo'sh audio");
        File f = new File(ctx.getCacheDir(), "jv_" + System.nanoTime() + ".mp3");
        try (FileOutputStream o = new FileOutputStream(f)) { audio.writeTo(o); }
        cleanup(f);
        return f;
    }

    // ---------------- Gemini TTS ----------------
    private File gemini(String text, String key, String models, String voice, String style) throws Exception {
        if (key == null || key.isEmpty()) throw new Exception("kalit yo'q");
        String last = "gemini";
        for (String m : models.split(",")) {
            m = m.trim();
            if (m.isEmpty()) continue;
            try { return geminiOnce(text, key, m, voice, style); }
            catch (Exception e) { last = m + ": " + e.getMessage(); }
        }
        throw new Exception(last);
    }

    private File geminiOnce(String text, String key, String model, String voice, String style) throws Exception {
        JSONObject body = new JSONObject();
        JSONArray contents = new JSONArray();
        JSONObject part = new JSONObject().put("text", (style.isEmpty() ? "" : style + ": ") + text);
        contents.put(new JSONObject().put("role", "user").put("parts", new JSONArray().put(part)));
        body.put("contents", contents);
        body.put("generationConfig", new JSONObject()
                .put("responseModalities", new JSONArray().put("AUDIO"))
                .put("speechConfig", new JSONObject().put("voiceConfig",
                        new JSONObject().put("prebuiltVoiceConfig", new JSONObject().put("voiceName", voice)))));
        HttpURLConnection c = (HttpURLConnection) new URL("https://generativelanguage.googleapis.com/v1beta/models/" + model + ":generateContent?key=" + key).openConnection();
        c.setConnectTimeout(15000);
        c.setReadTimeout(60000);
        c.setRequestMethod("POST");
        c.setDoOutput(true);
        c.setRequestProperty("Content-Type", "application/json; charset=utf-8");
        try (OutputStream o = c.getOutputStream()) { o.write(body.toString().getBytes(StandardCharsets.UTF_8)); }
        int code = c.getResponseCode();
        InputStream in = code >= 400 ? c.getErrorStream() : c.getInputStream();
        ByteArrayOutputStream bo = new ByteArrayOutputStream();
        byte[] buf = new byte[16384];
        int n;
        while (in != null && (n = in.read(buf)) > 0) bo.write(buf, 0, n);
        if (in != null) in.close();
        String resp = new String(bo.toByteArray(), StandardCharsets.UTF_8);
        if (code != 200) {
            String msg = "HTTP " + code;
            try { msg = new JSONObject(resp).getJSONObject("error").getString("message"); } catch (Exception ignored) { }
            throw new Exception(msg);
        }
        JSONArray parts = new JSONObject(resp).getJSONArray("candidates").getJSONObject(0).getJSONObject("content").getJSONArray("parts");
        String data = null, mime = "";
        for (int i = 0; i < parts.length(); i++) {
            JSONObject p = parts.getJSONObject(i);
            JSONObject inl = p.optJSONObject("inlineData");
            if (inl == null) inl = p.optJSONObject("inline_data");
            if (inl != null) { data = inl.optString("data"); mime = inl.optString("mimeType", inl.optString("mime_type", "")); break; }
        }
        if (data == null || data.isEmpty()) throw new Exception("audio yo'q");
        byte[] pcm = Base64.decode(data, Base64.DEFAULT);
        File f;
        if (mime.contains("mp3") || mime.contains("mpeg")) {
            f = new File(ctx.getCacheDir(), "jv_" + System.nanoTime() + ".mp3");
            try (FileOutputStream o = new FileOutputStream(f)) { o.write(pcm); }
        } else if (mime.contains("wav")) {
            f = new File(ctx.getCacheDir(), "jv_" + System.nanoTime() + ".wav");
            try (FileOutputStream o = new FileOutputStream(f)) { o.write(pcm); }
        } else {
            int rate = 24000;
            java.util.regex.Matcher mt = java.util.regex.Pattern.compile("rate=(\\d+)").matcher(mime);
            if (mt.find()) rate = Integer.parseInt(mt.group(1));
            f = new File(ctx.getCacheDir(), "jv_" + System.nanoTime() + ".wav");
            try (FileOutputStream o = new FileOutputStream(f)) { o.write(wavHeader(pcm.length, rate)); o.write(pcm); }
        }
        cleanup(f);
        return f;
    }

    private static byte[] wavHeader(int len, int rate) {
        int ch = 1, bits = 16, byteRate = rate * ch * bits / 8;
        java.nio.ByteBuffer b = java.nio.ByteBuffer.allocate(44).order(java.nio.ByteOrder.LITTLE_ENDIAN);
        b.put("RIFF".getBytes(StandardCharsets.US_ASCII)).putInt(36 + len).put("WAVE".getBytes(StandardCharsets.US_ASCII));
        b.put("fmt ".getBytes(StandardCharsets.US_ASCII)).putInt(16).putShort((short) 1).putShort((short) ch).putInt(rate).putInt(byteRate)
                .putShort((short) (ch * bits / 8)).putShort((short) bits);
        b.put("data".getBytes(StandardCharsets.US_ASCII)).putInt(len);
        return b.array();
    }

    private void cleanup(File keep) {
        File[] fs = ctx.getCacheDir().listFiles();
        if (fs == null) return;
        for (File x : fs) if (x.getName().startsWith("jv_") && !x.equals(keep) && System.currentTimeMillis() - x.lastModified() > 60000) x.delete();
    }
}
