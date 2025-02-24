/**
 * Simple Cloudflare Worker for a Maintenance Page.
 * Security headers, responsive design, minimal inline CSS.
 * In a real setup, replace these constants with environment variables
 * or Terraform-injected placeholders.
 */
const MAINTENANCE_TITLE   = "We'll be back soon!";
const MAINTENANCE_MESSAGE = "Our site is under maintenance. Please check back later!";
const MAINTENANCE_IMAGE   = ""; // e.g. "https://example.com/maintenance.png"

addEventListener("fetch", (event: FetchEvent) => {
  event.respondWith(handleRequest(event.request));
});

async function handleRequest(_request: Request): Promise<Response> {
  const html = \`<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1"/>
  <title>\${MAINTENANCE_TITLE}</title>
  <style>
    body {
      margin: 0; padding: 0; font-family: system-ui, sans-serif;
      background: #f2f2f2; color: #333; display: flex;
      align-items: center; justify-content: center; flex-direction: column;
      min-height: 100vh; text-align: center;
    }
    .container { max-width: 600px; padding: 1rem; }
    h1 { font-size: 2rem; margin-bottom: 1rem; }
    p { font-size: 1rem; line-height: 1.5; }
    img.hero-image { max-width: 100%; height: auto; margin: 1rem 0; }
    @media (prefers-color-scheme: dark) {
      body { background: #121212; color: #ffffff; }
    }
  </style>
</head>
<body>
  <div class="container" role="main" aria-labelledby="maintenance-title">
    <h1 id="maintenance-title">\${MAINTENANCE_TITLE}</h1>
    \${MAINTENANCE_IMAGE ? \`<img src="\${MAINTENANCE_IMAGE}" alt="Maintenance" class="hero-image" />\` : ""}
    <p>\${MAINTENANCE_MESSAGE}</p>
  </div>
</body>
</html>\`;

  const headers = new Headers({
    "Content-Type": "text/html; charset=utf-8",
    // Security headers
    "Content-Security-Policy": "default-src 'self'; img-src 'self' data:; style-src 'self' 'unsafe-inline';",
    "X-Frame-Options": "DENY",
    "X-Content-Type-Options": "nosniff",
    "Referrer-Policy": "strict-origin-when-cross-origin"
  });

  return new Response(html, { status: 503, headers });
}
