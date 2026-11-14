package uz.chaqmoq.app;

import android.util.Base64;
import android.util.Xml;

import org.json.JSONArray;
import org.json.JSONObject;
import org.xmlpull.v1.XmlPullParser;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.InputStream;
import java.math.BigDecimal;
import java.math.MathContext;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.GregorianCalendar;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.zip.ZipEntry;
import java.util.zip.ZipFile;

/** Word (.docx) va Excel (.xlsx) fayllarni ko'rish uchun HTML ga aylantiradi (tashqi kutubxonasiz). */
final class Office {
    private Office() { }

    private static final int MAX_HTML = 3000000;
    private static final int MAX_ROWS = 3000;
    private static final int MAX_COLS = 60;

    static String esc(String s) {
        StringBuilder b = new StringBuilder(s.length() + 16);
        for (int i = 0; i < s.length(); i++) {
            char c = s.charAt(i);
            if (c == '&') b.append("&amp;");
            else if (c == '<') b.append("&lt;");
            else if (c == '>') b.append("&gt;");
            else if (c == '"') b.append("&quot;");
            else b.append(c);
        }
        return b.toString();
    }

    private static XmlPullParser open(ZipFile z, String name) throws Exception {
        ZipEntry e = z.getEntry(name);
        if (e == null) return null;
        XmlPullParser p = Xml.newPullParser();
        p.setFeature(XmlPullParser.FEATURE_PROCESS_NAMESPACES, false);
        p.setInput(z.getInputStream(e), null);
        return p;
    }

    private static Map<String, String> rels(ZipFile z, String name) {
        Map<String, String> m = new HashMap<>();
        try {
            XmlPullParser p = open(z, name);
            if (p == null) return m;
            int ev;
            while ((ev = p.next()) != XmlPullParser.END_DOCUMENT) {
                if (ev == XmlPullParser.START_TAG && "Relationship".equals(p.getName())) {
                    String id = p.getAttributeValue(null, "Id");
                    String t = p.getAttributeValue(null, "Target");
                    if (id != null && t != null) m.put(id, t);
                }
            }
        } catch (Exception ignored) { }
        return m;
    }

    private static boolean on(XmlPullParser p) {
        String v = p.getAttributeValue(null, "w:val");
        return v == null || !(v.equals("0") || v.equals("false") || v.equals("none"));
    }

    private static int toInt(String s, int def) {
        try { return Integer.parseInt(s.trim()); } catch (Exception e) { return def; }
    }

    private static String image(ZipFile z, String target) {
        try {
            String name = target.startsWith("/") ? target.substring(1) : "word/" + target;
            String low = name.toLowerCase(Locale.ROOT);
            String mime;
            if (low.endsWith(".png")) mime = "image/png";
            else if (low.endsWith(".jpg") || low.endsWith(".jpeg")) mime = "image/jpeg";
            else if (low.endsWith(".gif")) mime = "image/gif";
            else return "";
            ZipEntry e = z.getEntry(name);
            if (e == null || e.getSize() > 1500000) return "";
            ByteArrayOutputStream bo = new ByteArrayOutputStream();
            try (InputStream in = z.getInputStream(e)) {
                byte[] buf = new byte[1 << 15];
                int n;
                while ((n = in.read(buf)) > 0) bo.write(buf, 0, n);
            }
            return "data:" + mime + ";base64," + Base64.encodeToString(bo.toByteArray(), Base64.NO_WRAP);
        } catch (Exception e) {
            return "";
        }
    }

    static String docx(File f) throws Exception {
        try (ZipFile z = new ZipFile(f)) {
            Map<String, String> rel = rels(z, "word/_rels/document.xml.rels");
            XmlPullParser p = open(z, "word/document.xml");
            if (p == null) throw new Exception("hujjat matni topilmadi");
            StringBuilder out = new StringBuilder();
            StringBuilder para = null;
            String pStyle = null, jc = null, color = null;
            boolean list = false, inRPr = false, inPPr = false, inT = false;
            boolean b = false, i = false, u = false, st = false;
            boolean tcPending = false;
            int sz = 0, span = 1;
            long imgTotal = 0;
            int ev;
            while ((ev = p.next()) != XmlPullParser.END_DOCUMENT) {
                if (out.length() > MAX_HTML) {
                    out.append("<p class=\"cut\">Hujjat juda katta, davomi ko'rsatilmadi.</p>");
                    break;
                }
                if (ev == XmlPullParser.START_TAG) {
                    String n = p.getName();
                    if (n.equals("w:p")) {
                        if (tcPending) { out.append(span > 1 ? "<td colspan=\"" + span + "\">" : "<td>"); tcPending = false; }
                        if (para != null) flushPara(out, para, pStyle, jc, list);
                        para = new StringBuilder();
                        pStyle = null; jc = null; list = false;
                    } else if (n.equals("w:pPr")) {
                        inPPr = true;
                    } else if (n.equals("w:pStyle")) {
                        pStyle = p.getAttributeValue(null, "w:val");
                    } else if (n.equals("w:jc")) {
                        if (inPPr) jc = p.getAttributeValue(null, "w:val");
                    } else if (n.equals("w:numPr")) {
                        list = true;
                    } else if (n.equals("w:r")) {
                        b = false; i = false; u = false; st = false; color = null; sz = 0;
                    } else if (n.equals("w:rPr")) {
                        inRPr = true;
                    } else if (inRPr && !inPPr && n.equals("w:b")) {
                        b = on(p);
                    } else if (inRPr && !inPPr && n.equals("w:i")) {
                        i = on(p);
                    } else if (inRPr && !inPPr && n.equals("w:u")) {
                        u = on(p);
                    } else if (inRPr && !inPPr && n.equals("w:strike")) {
                        st = on(p);
                    } else if (inRPr && !inPPr && n.equals("w:color")) {
                        String v = p.getAttributeValue(null, "w:val");
                        color = (v != null && v.matches("[0-9A-Fa-f]{6}")) ? v : null;
                    } else if (inRPr && !inPPr && n.equals("w:sz")) {
                        sz = toInt(p.getAttributeValue(null, "w:val"), 0);
                    } else if (n.equals("w:t")) {
                        inT = true;
                    } else if (n.equals("w:tab")) {
                        if (para != null && !inPPr) para.append("&emsp;");
                    } else if (n.equals("w:br")) {
                        if (para != null) para.append("page".equals(p.getAttributeValue(null, "w:type")) ? "<span class=\"pb\"></span>" : "<br>");
                    } else if (n.equals("w:tbl")) {
                        if (tcPending) { out.append(span > 1 ? "<td colspan=\"" + span + "\">" : "<td>"); tcPending = false; }
                        if (para != null) { flushPara(out, para, pStyle, jc, list); para = null; }
                        out.append("<div class=\"tw\"><table>");
                    } else if (n.equals("w:tr")) {
                        out.append("<tr>");
                    } else if (n.equals("w:tc")) {
                        tcPending = true;
                        span = 1;
                    } else if (n.equals("w:gridSpan")) {
                        span = Math.max(1, Math.min(60, toInt(p.getAttributeValue(null, "w:val"), 1)));
                    } else if (n.equals("a:blip")) {
                        String id = p.getAttributeValue(null, "r:embed");
                        String target = id == null ? null : rel.get(id);
                        if (target != null && imgTotal < 12000000) {
                            String data = image(z, target);
                            if (!data.isEmpty()) {
                                imgTotal += data.length();
                                String tag = "<img alt=\"\" src=\"" + data + "\">";
                                if (para != null) para.append(tag); else out.append(tag);
                            }
                        }
                    }
                } else if (ev == XmlPullParser.TEXT) {
                    if (inT) {
                        String t = esc(p.getText());
                        StringBuilder r = new StringBuilder();
                        String style = "";
                        if (color != null && !color.equalsIgnoreCase("000000") && !color.equalsIgnoreCase("FFFFFF")) style += "color:#" + color + ";";
                        if (sz >= 28 || (sz > 0 && sz <= 18)) {
                            double em = Math.max(0.75, Math.min(2.2, sz / 22.0));
                            style += "font-size:" + String.format(Locale.US, "%.2f", em) + "em;";
                        }
                        if (!style.isEmpty()) r.append("<span style=\"").append(style).append("\">");
                        if (b) r.append("<b>");
                        if (i) r.append("<i>");
                        if (u) r.append("<u>");
                        if (st) r.append("<s>");
                        r.append(t);
                        if (st) r.append("</s>");
                        if (u) r.append("</u>");
                        if (i) r.append("</i>");
                        if (b) r.append("</b>");
                        if (!style.isEmpty()) r.append("</span>");
                        if (para != null) para.append(r); else out.append(r);
                    }
                } else if (ev == XmlPullParser.END_TAG) {
                    String n = p.getName();
                    if (n.equals("w:t")) {
                        inT = false;
                    } else if (n.equals("w:rPr")) {
                        inRPr = false;
                    } else if (n.equals("w:pPr")) {
                        inPPr = false;
                    } else if (n.equals("w:p")) {
                        if (para != null) { flushPara(out, para, pStyle, jc, list); para = null; }
                    } else if (n.equals("w:tc")) {
                        if (tcPending) { out.append(span > 1 ? "<td colspan=\"" + span + "\">" : "<td>"); tcPending = false; }
                        out.append("</td>");
                    } else if (n.equals("w:tr")) {
                        out.append("</tr>");
                    } else if (n.equals("w:tbl")) {
                        out.append("</table></div>");
                    }
                }
            }
            if (para != null) flushPara(out, para, pStyle, jc, list);
            return out.toString();
        }
    }

    private static void flushPara(StringBuilder out, StringBuilder para, String pStyle, String jc, boolean list) {
        String tag = "p";
        if (pStyle != null) {
            String s = pStyle.toLowerCase(Locale.ROOT);
            if (s.equals("title") || s.endsWith("heading1") || s.equals("1")) tag = "h1";
            else if (s.endsWith("heading2") || s.equals("2")) tag = "h2";
            else if (s.contains("heading") || s.equals("3") || s.equals("subtitle")) tag = "h3";
        }
        String al = "";
        if ("center".equals(jc)) al = " style=\"text-align:center\"";
        else if ("right".equals(jc) || "end".equals(jc)) al = " style=\"text-align:right\"";
        else if ("both".equals(jc)) al = " style=\"text-align:justify\"";
        if (!list && pStyle != null && tag.equals("p") && pStyle.toLowerCase(Locale.ROOT).contains("list")) list = true;
        out.append('<').append(tag).append(al).append('>');
        if (list) out.append("&bull;&nbsp;");
        if (para.length() == 0) out.append("&nbsp;"); else out.append(para);
        out.append("</").append(tag).append('>');
    }

    /* ---------------- Excel ---------------- */

    private static boolean isDateFmt(int id, String code) {
        if ((id >= 14 && id <= 22) || (id >= 27 && id <= 36) || (id >= 45 && id <= 47) || (id >= 50 && id <= 58)) return true;
        if (code == null) return false;
        String c = code.replaceAll("\"[^\"]*\"", "").replaceAll("\\[[^\\]]*\\]", "").toLowerCase(Locale.ROOT);
        if (c.contains("general") || c.indexOf('0') >= 0 || c.indexOf('#') >= 0) return false;
        return c.indexOf('d') >= 0 || c.indexOf('m') >= 0 || c.indexOf('y') >= 0 || c.indexOf('h') >= 0 || c.indexOf('s') >= 0;
    }

    private static String num(String v) {
        try {
            double d = Double.parseDouble(v);
            if (d == Math.rint(d) && Math.abs(d) < 1e15) return Long.toString((long) d);
            return new BigDecimal(d).round(new MathContext(10)).stripTrailingZeros().toPlainString();
        } catch (Exception e) {
            return v;
        }
    }

    private static String date(String v) {
        try {
            double d = Double.parseDouble(v);
            long days = (long) Math.floor(d);
            int secs = (int) Math.round((d - days) * 86400);
            String s = "";
            if (days > 0) {
                Calendar c = new GregorianCalendar(1899, Calendar.DECEMBER, 30);
                c.add(Calendar.DAY_OF_MONTH, (int) days);
                s = String.format(Locale.US, "%02d.%02d.%04d", c.get(Calendar.DAY_OF_MONTH), c.get(Calendar.MONTH) + 1, c.get(Calendar.YEAR));
            }
            if (secs > 0) s += (s.isEmpty() ? "" : " ") + String.format(Locale.US, "%02d:%02d", (secs / 3600) % 24, (secs / 60) % 60);
            return s.isEmpty() ? num(v) : s;
        } catch (Exception e) {
            return v;
        }
    }

    private static String colName(int i) {
        StringBuilder b = new StringBuilder();
        i++;
        while (i > 0) {
            int r = (i - 1) % 26;
            b.insert(0, (char) ('A' + r));
            i = (i - 1) / 26;
        }
        return b.toString();
    }

    private static int colOf(String ref) {
        int c = 0, k = 0;
        while (k < ref.length()) {
            char ch = ref.charAt(k);
            if (ch < 'A' || ch > 'Z') break;
            c = c * 26 + (ch - 'A' + 1);
            k++;
        }
        return c - 1;
    }

    static String xlsx(File f) throws Exception {
        try (ZipFile z = new ZipFile(f)) {
            // Umumiy satrlar
            List<String> shared = new ArrayList<>();
            XmlPullParser p = open(z, "xl/sharedStrings.xml");
            if (p != null) {
                StringBuilder cur = null;
                boolean inT = false, inPh = false;
                int ev;
                while ((ev = p.next()) != XmlPullParser.END_DOCUMENT) {
                    if (ev == XmlPullParser.START_TAG) {
                        String n = p.getName();
                        if (n.equals("si")) cur = new StringBuilder();
                        else if (n.equals("rPh")) inPh = true;
                        else if (n.equals("t")) inT = true;
                    } else if (ev == XmlPullParser.TEXT) {
                        if (inT && !inPh && cur != null) cur.append(p.getText());
                    } else if (ev == XmlPullParser.END_TAG) {
                        String n = p.getName();
                        if (n.equals("t")) inT = false;
                        else if (n.equals("rPh")) inPh = false;
                        else if (n.equals("si")) { shared.add(cur == null ? "" : cur.toString()); cur = null; }
                    }
                }
            }
            // Sana formatlari
            List<Boolean> dateXf = new ArrayList<>();
            p = open(z, "xl/styles.xml");
            if (p != null) {
                Map<Integer, String> custom = new HashMap<>();
                boolean inXfs = false;
                int ev;
                while ((ev = p.next()) != XmlPullParser.END_DOCUMENT) {
                    if (ev == XmlPullParser.START_TAG) {
                        String n = p.getName();
                        if (n.equals("numFmt")) {
                            custom.put(toInt(p.getAttributeValue(null, "numFmtId"), -1), p.getAttributeValue(null, "formatCode"));
                        } else if (n.equals("cellXfs")) {
                            inXfs = true;
                        } else if (inXfs && n.equals("xf")) {
                            int id = toInt(p.getAttributeValue(null, "numFmtId"), 0);
                            dateXf.add(isDateFmt(id, custom.get(id)));
                        }
                    } else if (ev == XmlPullParser.END_TAG && p.getName().equals("cellXfs")) {
                        inXfs = false;
                    }
                }
            }
            // Varaqlar ro'yxati
            Map<String, String> rel = rels(z, "xl/_rels/workbook.xml.rels");
            List<String[]> sheets = new ArrayList<>();
            p = open(z, "xl/workbook.xml");
            if (p == null) throw new Exception("kitob topilmadi");
            int ev;
            while ((ev = p.next()) != XmlPullParser.END_DOCUMENT) {
                if (ev == XmlPullParser.START_TAG && p.getName().equals("sheet")) {
                    String name = p.getAttributeValue(null, "name");
                    String target = rel.get(p.getAttributeValue(null, "r:id"));
                    if (target != null) {
                        String path = target.startsWith("/") ? target.substring(1) : "xl/" + target;
                        sheets.add(new String[]{name == null ? "Varaq" : name, path});
                    }
                }
            }
            JSONArray arr = new JSONArray();
            int total = 0;
            for (String[] sh : sheets) {
                if (arr.length() >= 30) break;
                JSONObject o = new JSONObject();
                o.put("name", sh[0]);
                boolean[] cut = new boolean[1];
                String html = total > MAX_HTML ? "" : sheet(z, sh[1], shared, dateXf, cut);
                total += html.length();
                o.put("html", html);
                o.put("cut", cut[0]);
                arr.put(o);
            }
            JSONObject res = new JSONObject();
            res.put("ok", true);
            res.put("sheets", arr);
            return res.toString();
        }
    }

    private static String sheet(ZipFile z, String path, List<String> shared, List<Boolean> dateXf, boolean[] cut) throws Exception {
        XmlPullParser p = open(z, path);
        if (p == null) return "";
        StringBuilder body = new StringBuilder();
        int maxCol = 0, rows = 0, col = 0, next = 0, rowNo = 0;
        String type = null, val = null;
        StringBuilder inl = null;
        boolean inV = false, inIs = false, inT = false, isDate = false, rowOpen = false;
        int ev;
        while ((ev = p.next()) != XmlPullParser.END_DOCUMENT) {
            if (ev == XmlPullParser.START_TAG) {
                String n = p.getName();
                if (n.equals("row")) {
                    if (rows >= MAX_ROWS || body.length() > MAX_HTML) { cut[0] = true; break; }
                    rowNo = toInt(p.getAttributeValue(null, "r"), rowNo + 1);
                    body.append("<tr><th>").append(rowNo).append("</th>");
                    rowOpen = true;
                    next = 0;
                    rows++;
                } else if (n.equals("c")) {
                    String ref = p.getAttributeValue(null, "r");
                    col = ref == null ? next : colOf(ref);
                    type = p.getAttributeValue(null, "t");
                    int xf = toInt(p.getAttributeValue(null, "s"), -1);
                    isDate = xf >= 0 && xf < dateXf.size() && dateXf.get(xf);
                    val = null;
                    inl = null;
                } else if (n.equals("v")) {
                    inV = true;
                } else if (n.equals("is")) {
                    inIs = true;
                    inl = new StringBuilder();
                } else if (n.equals("t")) {
                    inT = true;
                }
            } else if (ev == XmlPullParser.TEXT) {
                if (inV) val = (val == null ? "" : val) + p.getText();
                else if (inIs && inT && inl != null) inl.append(p.getText());
            } else if (ev == XmlPullParser.END_TAG) {
                String n = p.getName();
                if (n.equals("v")) {
                    inV = false;
                } else if (n.equals("t")) {
                    inT = false;
                } else if (n.equals("is")) {
                    inIs = false;
                } else if (n.equals("c")) {
                    if (rowOpen && col >= 0 && col < MAX_COLS) {
                        String text = "";
                        boolean numeric = false;
                        if (inl != null) {
                            text = inl.toString();
                        } else if (val != null) {
                            if ("s".equals(type)) {
                                int k = toInt(val, -1);
                                text = k >= 0 && k < shared.size() ? shared.get(k) : "";
                            } else if ("str".equals(type) || "e".equals(type) || "inlineStr".equals(type)) {
                                text = val;
                            } else if ("b".equals(type)) {
                                text = "1".equals(val.trim()) ? "TRUE" : "FALSE";
                            } else {
                                numeric = true;
                                text = isDate ? date(val) : num(val);
                            }
                        }
                        if (!text.isEmpty() || col >= next) {
                            while (next < col) { body.append("<td></td>"); next++; }
                            body.append(numeric ? "<td class=\"n\">" : "<td>").append(esc(text)).append("</td>");
                            next = col + 1;
                            if (next > maxCol) maxCol = next;
                        }
                    } else if (col >= MAX_COLS) {
                        cut[0] = true;
                    }
                } else if (n.equals("row")) {
                    if (rowOpen) { body.append("</tr>"); rowOpen = false; }
                }
            }
        }
        if (rowOpen) body.append("</tr>");
        if (rows == 0 || maxCol == 0) return "";
        StringBuilder out = new StringBuilder("<table class=\"xl\"><thead><tr><th></th>");
        for (int c = 0; c < maxCol; c++) out.append("<th>").append(colName(c)).append("</th>");
        out.append("</tr></thead><tbody>").append(body).append("</tbody></table>");
        return out.toString();
    }
}
