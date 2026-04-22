// Returns { lang: "fr" | "en", country: "XX" } based on Vercel's edge IP header.
// Frontend calls this once on load and sets the initial language.
export default function handler(req, res) {
  const country = (req.headers["x-vercel-ip-country"] || "").toString().toUpperCase();
  // Francophone-majority countries (+ Quebec handled via CA heuristic: we keep FR for CA
  // since Vercel doesn't expose region reliably; EN speakers can toggle).
  const FR_COUNTRIES = new Set(["FR", "BE", "LU", "MC", "CH"]);
  const lang = FR_COUNTRIES.has(country) ? "fr" : "en";
  res.setHeader("Cache-Control", "public, max-age=0, s-maxage=60");
  res.status(200).json({ lang, country: country || null });
}
