package uz.chaqmoq.app;

import android.content.ContentProvider;
import android.content.ContentValues;
import android.database.Cursor;
import android.database.MatrixCursor;
import android.net.Uri;
import android.os.ParcelFileDescriptor;
import android.provider.OpenableColumns;
import android.webkit.MimeTypeMap;

import java.io.File;
import java.io.FileNotFoundException;
import java.util.Collections;
import java.util.HashSet;
import java.util.Locale;
import java.util.Set;

/** Faylni boshqa dasturda ochish yoki ulashish uchun kichik provayder (androidx'siz). */
public class FileShare extends ContentProvider {
    public static final String AUTH = "uz.chaqmoq.app.files";

    /** Faqat foydalanuvchi o'zi ochgan yoki ulashgan fayllar beriladi. */
    private static final Set<String> ALLOWED = Collections.synchronizedSet(new HashSet<String>());

    /** Kamera dasturi yozishi mumkin bo'lgan vaqtinchalik fayllar. */
    private static final Set<String> WRITABLE = Collections.synchronizedSet(new HashSet<String>());

    public static File camDir(android.content.Context c) {
        File d = new File(c.getCacheDir(), "cam");
        if (!d.exists()) d.mkdirs();
        return d;
    }

    public static Uri camUri(File f) {
        String p = f.getAbsolutePath();
        ALLOWED.add(p);
        WRITABLE.add(p);
        return new Uri.Builder().scheme("content").authority(AUTH).path(p).build();
    }

    public static Uri uriFor(File f) {
        String p = f.getAbsolutePath();
        ALLOWED.add(p);
        return new Uri.Builder().scheme("content").authority(AUTH).path(p).build();
    }

    public static String mimeOf(String name) {
        int dot = name.lastIndexOf('.');
        if (dot < 0 || dot == name.length() - 1) return "*/*";
        String ext = name.substring(dot + 1).toLowerCase(Locale.ROOT);
        String m = MimeTypeMap.getSingleton().getMimeTypeFromExtension(ext);
        return m == null ? "*/*" : m;
    }

    @Override public boolean onCreate() { return true; }

    private File fileFor(Uri uri) throws FileNotFoundException {
        String p = uri.getPath();
        if (p == null || !ALLOWED.contains(p)) throw new FileNotFoundException();
        File f = new File(p);
        if (!f.isFile()) throw new FileNotFoundException();
        return f;
    }

    @Override
    public ParcelFileDescriptor openFile(Uri uri, String mode) throws FileNotFoundException {
        String p = uri.getPath();
        if (p != null && WRITABLE.contains(p)) {
            return ParcelFileDescriptor.open(new File(p), ParcelFileDescriptor.parseMode(mode));
        }
        return ParcelFileDescriptor.open(fileFor(uri), ParcelFileDescriptor.MODE_READ_ONLY);
    }

    @Override
    public Cursor query(Uri uri, String[] p, String s, String[] a, String o) {
        MatrixCursor c = new MatrixCursor(new String[]{OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE});
        try {
            File f = fileFor(uri);
            c.addRow(new Object[]{f.getName(), f.length()});
        } catch (Exception ignored) { }
        return c;
    }

    @Override
    public String getType(Uri uri) {
        String p = uri.getPath();
        return p == null ? "*/*" : mimeOf(new File(p).getName());
    }

    @Override public Uri insert(Uri uri, ContentValues v) { return null; }
    @Override public int delete(Uri uri, String s, String[] a) { return 0; }
    @Override public int update(Uri uri, ContentValues v, String s, String[] a) { return 0; }
}
