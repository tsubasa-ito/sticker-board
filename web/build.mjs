// 利用規約・プライバシーポリシーの Markdown を静的 HTML に変換して dist/ に出力する
// Cloudflare Pages のビルドコマンド（npm run build）から実行される
import { readFile, writeFile, mkdir, rm, copyFile } from "node:fs/promises";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { marked } from "marked";

const root = dirname(fileURLToPath(import.meta.url));
const contentDir = join(root, "content");
const distDir = join(root, "dist");

const documents = ["privacy", "terms"];

const languages = {
  ja: {
    htmlLang: "ja",
    pathPrefix: "",
    switchLabel: "English",
    appName: "シールボード",
    indexTitle: "シールボード",
    indexLinks: { privacy: "プライバシーポリシー", terms: "利用規約" },
  },
  en: {
    htmlLang: "en",
    pathPrefix: "/en",
    switchLabel: "日本語",
    appName: "StickerBoard",
    indexTitle: "StickerBoard",
    indexLinks: { privacy: "Privacy Policy", terms: "Terms of Service" },
  },
};

// 既存 URL（/privacy と /privacy/en）との互換性を保つためのパス
function documentPath(doc, lang) {
  return lang === "ja" ? `/${doc}/` : `/${doc}/en/`;
}

function escapeHtml(text) {
  return text
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
}

function page({ lang, title, body, alternatePath }) {
  const config = languages[lang];
  const otherLang = lang === "ja" ? "en" : "ja";
  return `<!doctype html>
<html lang="${config.htmlLang}">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${escapeHtml(title)}</title>
<link rel="alternate" hreflang="${otherLang}" href="${alternatePath}">
<link rel="stylesheet" href="/style.css">
</head>
<body>
<header class="site-header">
  <a class="app-name" href="${config.pathPrefix || "/"}">${escapeHtml(config.appName)}</a>
  <a class="lang-switch" href="${alternatePath}" hreflang="${otherLang}" lang="${otherLang}">${config.switchLabel}</a>
</header>
<main>
${body}
</main>
</body>
</html>
`;
}

async function writePage(path, html) {
  const filePath = join(distDir, path, "index.html");
  await mkdir(dirname(filePath), { recursive: true });
  await writeFile(filePath, html);
}

async function build() {
  await rm(distDir, { recursive: true, force: true });
  await mkdir(distDir, { recursive: true });

  for (const lang of Object.keys(languages)) {
    const otherLang = lang === "ja" ? "en" : "ja";

    for (const doc of documents) {
      const markdown = await readFile(join(contentDir, lang, `${doc}.md`), "utf8");
      const title = markdown.match(/^# (.+)$/m)?.[1] ?? languages[lang].appName;
      const body = marked.parse(markdown);
      await writePage(
        documentPath(doc, lang),
        page({ lang, title, body, alternatePath: documentPath(doc, otherLang) })
      );
    }

    const config = languages[lang];
    const links = documents
      .map((doc) => `<li><a href="${documentPath(doc, lang)}">${config.indexLinks[doc]}</a></li>`)
      .join("\n");
    await writePage(
      config.pathPrefix,
      page({
        lang,
        title: config.indexTitle,
        body: `<h1>${escapeHtml(config.indexTitle)}</h1>\n<ul class="index-links">\n${links}\n</ul>`,
        alternatePath: languages[otherLang].pathPrefix || "/",
      })
    );
  }

  await copyFile(join(root, "style.css"), join(distDir, "style.css"));
}

await build();
