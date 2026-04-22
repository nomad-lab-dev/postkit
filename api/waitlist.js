// Vercel Serverless Function — POST /api/waitlist
// Adds email to Resend Audience + sends notification to hello@nomad-lab.io

// Env vars (set in Vercel → Settings → Environment Variables):
//   RESEND_API_KEY       — your Resend secret key
//   RESEND_AUDIENCE_ID   — id of the audience (create one in Resend → Audiences)
//   NOTIFY_EMAIL         — where to send notifications (default: hello@nomad-lab.io)
//   NOTIFY_FROM          — verified sender, e.g. "PostKit <waitlist@nomad-lab.io>"

const BASE = "https://api.resend.com";

// Very simple in-memory rate limit (per serverless instance, best-effort)
const hits = new Map();
const RATE = { max: 5, windowMs: 60_000 };

function rateLimited(ip) {
  const now = Date.now();
  const arr = (hits.get(ip) || []).filter(t => now - t < RATE.windowMs);
  arr.push(now);
  hits.set(ip, arr);
  return arr.length > RATE.max;
}

function isValidEmail(e) {
  return typeof e === "string"
    && e.length < 254
    && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(e);
}

export default async function handler(req, res) {
  // CORS (same-origin deploy doesn't need it, but preview/dev might)
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type");
  if (req.method === "OPTIONS") return res.status(204).end();
  if (req.method !== "POST") return res.status(405).json({ error: "Method not allowed" });

  const ip = (req.headers["x-forwarded-for"] || "").toString().split(",")[0].trim() || "unknown";
  if (rateLimited(ip)) return res.status(429).json({ error: "Too many requests" });

  let body = req.body;
  if (typeof body === "string") { try { body = JSON.parse(body); } catch { body = {}; } }
  const email = (body?.email || "").toString().trim().toLowerCase();
  const lang = (body?.lang || "en").toString().slice(0, 5);

  if (!isValidEmail(email)) return res.status(400).json({ error: "Invalid email" });

  const API_KEY = process.env.RESEND_API_KEY;
  const AUDIENCE_ID = process.env.RESEND_AUDIENCE_ID;
  const NOTIFY_EMAIL = process.env.NOTIFY_EMAIL || "hello@nomad-lab.io";
  const NOTIFY_FROM = process.env.NOTIFY_FROM || "PostKit Waitlist <onboarding@resend.dev>";

  if (!API_KEY) {
    console.error("[waitlist] RESEND_API_KEY missing");
    return res.status(500).json({ error: "Server misconfigured" });
  }

  const authHeaders = {
    "Authorization": `Bearer ${API_KEY}`,
    "Content-Type": "application/json",
  };

  // 1) Add to audience (if configured) — ignore "already exists" as success
  let addedToAudience = false;
  let alreadyExisted = false;
  if (AUDIENCE_ID) {
    try {
      const r = await fetch(`${BASE}/audiences/${AUDIENCE_ID}/contacts`, {
        method: "POST",
        headers: authHeaders,
        body: JSON.stringify({ email, unsubscribed: false }),
      });
      const data = await r.json().catch(() => ({}));
      if (r.ok) addedToAudience = true;
      else if (r.status === 409 || /exist/i.test(data?.message || data?.name || "")) {
        alreadyExisted = true;
      } else {
        console.error("[waitlist] audience add failed", r.status, data);
      }
    } catch (e) {
      console.error("[waitlist] audience add error", e);
    }
  }

  // 2) Notification email to you
  try {
    await fetch(`${BASE}/emails`, {
      method: "POST",
      headers: authHeaders,
      body: JSON.stringify({
        from: NOTIFY_FROM,
        to: [NOTIFY_EMAIL],
        subject: `🟢 PostKit waitlist — ${email}`,
        html: `
          <div style="font-family:ui-sans-serif,system-ui;font-size:14px;color:#0a0a0c">
            <h2 style="margin:0 0 12px">New PostKit waitlist signup</h2>
            <p style="margin:0 0 6px"><b>Email:</b> ${email}</p>
            <p style="margin:0 0 6px"><b>Lang:</b> ${lang}</p>
            <p style="margin:0 0 6px"><b>IP:</b> ${ip}</p>
            <p style="margin:0 0 6px"><b>UA:</b> ${(req.headers["user-agent"] || "").toString().slice(0, 200)}</p>
            <p style="margin:0 0 6px"><b>Audience:</b> ${addedToAudience ? "added" : alreadyExisted ? "already existed" : AUDIENCE_ID ? "failed" : "(not configured)"}</p>
            <p style="margin:0;color:#71717a;font-size:12px">${new Date().toISOString()}</p>
          </div>`,
        reply_to: email,
      }),
    });
  } catch (e) {
    console.error("[waitlist] notify email error", e);
    // Don't fail the whole request if only the notif fails
  }

  return res.status(200).json({
    ok: true,
    alreadyExisted,
  });
}
