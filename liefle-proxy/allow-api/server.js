const http = require("node:http");
const fs = require("node:fs");
const path = require("node:path");
const { URL } = require("node:url");

const PORT = Number(process.env.PORT || 8080);
const HOST = process.env.HOST || "0.0.0.0";
const API_SECRET = process.env.ALLOW_API_SECRET || "";
const DOMAINS_FILE = process.env.DOMAINS_FILE || path.join(__dirname, "domains.json");

let allowedDomains = new Set();
let domainsLoadedAt = 0;

function normalizeDomain(value) {
  return String(value || "")
    .trim()
    .toLowerCase()
    .replace(/\.$/, "");
}

function loadDomains() {
  try {
    const raw = fs.readFileSync(DOMAINS_FILE, "utf8");
    const parsed = JSON.parse(raw);
    const list = Array.isArray(parsed.domains) ? parsed.domains : [];
    allowedDomains = new Set(list.map(normalizeDomain).filter(Boolean));
    domainsLoadedAt = Date.now();
  } catch (error) {
    console.error("[allow-api] failed to load domains file:", error.message);
    allowedDomains = new Set(["connect.liefle.com", "connect.falcon.codes"]);
  }
}

function saveDomains() {
  const payload = {
    domains: [...allowedDomains].sort(),
    updatedAt: new Date().toISOString(),
  };
  fs.writeFileSync(DOMAINS_FILE, `${JSON.stringify(payload, null, 2)}\n`, "utf8");
  domainsLoadedAt = Date.now();
}

function sendJson(res, statusCode, body) {
  const data = JSON.stringify(body);
  res.writeHead(statusCode, {
    "Content-Type": "application/json",
    "Content-Length": Buffer.byteLength(data),
  });
  res.end(data);
}

function readJsonBody(req) {
  return new Promise((resolve, reject) => {
    let body = "";
    req.on("data", (chunk) => {
      body += chunk;
      if (body.length > 1_000_000) {
        reject(new Error("Payload too large"));
        req.destroy();
      }
    });
    req.on("end", () => {
      if (!body) {
        resolve({});
        return;
      }
      try {
        resolve(JSON.parse(body));
      } catch {
        reject(new Error("Invalid JSON"));
      }
    });
    req.on("error", reject);
  });
}

function isAuthorized(req) {
  if (!API_SECRET) {
    return true;
  }
  const header = req.headers.authorization || "";
  return header === `Bearer ${API_SECRET}`;
}

function handleAllowDomain(req, res, url) {
  const domain = normalizeDomain(url.searchParams.get("domain"));
  if (!domain) {
    res.writeHead(400);
    res.end();
    return;
  }

  if (allowedDomains.has(domain)) {
    res.writeHead(200);
    res.end();
    return;
  }

  res.writeHead(403);
  res.end();
}

async function handleApi(req, res, url) {
  if (!isAuthorized(req)) {
    sendJson(res, 401, { error: "Unauthorized" });
    return;
  }

  if (req.method === "GET" && url.pathname === "/api/domains") {
    sendJson(res, 200, {
      count: allowedDomains.size,
      domains: [...allowedDomains].sort(),
      loadedAt: domainsLoadedAt,
    });
    return;
  }

  if (req.method === "POST" && url.pathname === "/api/domains") {
    let body;
    try {
      body = await readJsonBody(req);
    } catch (error) {
      sendJson(res, 400, { error: error.message });
      return;
    }

    const domain = normalizeDomain(body.domain);
    if (!domain || !/^[a-z0-9.-]+$/.test(domain) || domain.length > 253) {
      sendJson(res, 400, { error: "Invalid domain" });
      return;
    }

    allowedDomains.add(domain);
    saveDomains();
    sendJson(res, 201, { domain, status: "allowed" });
    return;
  }

  if (req.method === "DELETE" && url.pathname.startsWith("/api/domains/")) {
    const domain = normalizeDomain(decodeURIComponent(url.pathname.slice("/api/domains/".length)));
    if (!domain) {
      sendJson(res, 400, { error: "Invalid domain" });
      return;
    }

    const existed = allowedDomains.delete(domain);
    if (existed) {
      saveDomains();
    }
    sendJson(res, 200, { domain, removed: existed });
    return;
  }

  sendJson(res, 404, { error: "Not found" });
}

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, `http://${req.headers.host || "localhost"}`);

  if (req.method === "GET" && url.pathname === "/health") {
    sendJson(res, 200, {
      ok: true,
      service: "liefle-allow-api",
      domains: allowedDomains.size,
    });
    return;
  }

  if (req.method === "GET" && url.pathname === "/allow-domain") {
    handleAllowDomain(req, res, url);
    return;
  }

  if (url.pathname.startsWith("/api/domains")) {
    await handleApi(req, res, url);
    return;
  }

  sendJson(res, 404, { error: "Not found" });
});

loadDomains();

fs.watchFile(DOMAINS_FILE, { interval: 2000 }, () => {
  loadDomains();
});

server.listen(PORT, HOST, () => {
  console.log(`[allow-api] listening on http://${HOST}:${PORT}`);
  console.log(`[allow-api] domains file: ${DOMAINS_FILE}`);
  console.log(`[allow-api] loaded ${allowedDomains.size} domain(s)`);
});
