package uz.jarvis.app;

import android.content.ContentProvider;
import android.content.ContentValues;
import android.database.Cursor;
import android.database.MatrixCursor;
import android.net.Uri;
import android.os.ParcelFileDescriptor;
import android.provider.OpenableColumns;

import java.io.File;
import java.io.FileNotFoundException;

/** Ovozli xabar faylini Telegram/WhatsApp'ga berish uchun. */
public class FileShare extends ContentProvider {
    public static final String AUTH = "uz.jarvis.app.files";

    public static Uri uriFor(File f) { return Uri.parse("content://" + AUTH + "/" + f.getName()); }

    private File fileOf(Uri uri) {
        String name = uri.getLastPathSegment();
        if (name == null || name.contains("/") || name.contains("..")) return null;
        return new File(getContext().getCacheDir(), name);
    }

    @Override public boolean onCreate() { return true; }

    @Override public ParcelFileDescriptor openFile(Uri uri, String mode) throws FileNotFoundException {
        File f = fileOf(uri);
        if (f == null || !f.exists()) throw new FileNotFoundException();
        return ParcelFileDescriptor.open(f, ParcelFileDescriptor.MODE_READ_ONLY);
    }

    @Override public Cursor query(Uri uri, String[] proj, String sel, String[] args, String sort) {
        File f = fileOf(uri);
        MatrixCursor c = new MatrixCursor(new String[]{OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE});
        if (f != null && f.exists()) c.addRow(new Object[]{f.getName(), f.length()});
        return c;
    }

    @Override public String getType(Uri uri) {
        String n = uri.getLastPathSegment();
        if (n != null && n.endsWith(".ogg")) return "audio/ogg";
        return "audio/mp4";
    }

    @Override public Uri insert(Uri uri, ContentValues v) { return null; }
    @Override public int delete(Uri uri, String s, String[] a) { return 0; }
    @Override public int update(Uri uri, ContentValues v, String s, String[] a) { return 0; }
}
