// Yig'ish paytida kutubxona va shriftlarni ilova ichiga ko'chiradi (ilova internetsiz ishlashi uchun).
const fs = require("fs"), path = require("path");
const out = path.join(__dirname, "..", "app", "src", "main", "assets");
const nm = path.join(__dirname, "..", "node_modules");
fs.mkdirSync(path.join(out, "lib"), { recursive: true });
fs.mkdirSync(path.join(out, "fonts"), { recursive: true });

// Kutubxonalar majburiy: topilmasa yig'ish to'xtaydi.
for (const [from, to] of [
  ["html2canvas/dist/html2canvas.min.js", "html2canvas.min.js"],
  ["jspdf/dist/jspdf.umd.min.js", "jspdf.umd.min.js"],
]) fs.copyFileSync(path.join(nm, from), path.join(out, "lib", to));

const families = [
  ["ibm-plex-sans", "IBM Plex Sans", [400, 500, 600]],
  ["ibm-plex-mono", "IBM Plex Mono", [400, 500]],
  ["oswald", "Oswald", [500, 600]],
  ["pt-serif", "PT Serif", [400, 700]],
];
// Lotin oxirida turadi: bir xil oilada keyingi qoida birinchi tekshiriladi.
const subsets = ["cyrillic-ext", "cyrillic", "latin-ext", "latin"];
let css = "", count = 0;
for (const [pkg, name, weights] of families) {
  const dir = path.join(nm, "@fontsource", pkg, "files");
  for (const w of weights) for (const sub of subsets) {
    const file = `${pkg}-${sub}-${w}-normal.woff2`;
    if (!fs.existsSync(path.join(dir, file))) continue;
    fs.copyFileSync(path.join(dir, file), path.join(out, "fonts", file));
    css += `@font-face{font-family:"${name}";font-style:normal;font-weight:${w};font-display:swap;src:url(fonts/${file}) format("woff2")}\n`;
    count++;
  }
}
fs.writeFileSync(path.join(out, "fonts.css"), css);
console.log("Shrift fayllari:", count);
if (!count) console.warn("OGOHLANTIRISH: shriftlar topilmadi, ilova tizim shriftlari bilan ishlaydi.");
