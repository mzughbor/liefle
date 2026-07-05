// Liefle landing — domain check demo
(function () {
  const form = document.getElementById("domainForm");
  const input = document.getElementById("domain");
  const result = document.getElementById("domainResult");
  const noDomainBtn = document.getElementById("noDomainBtn");

  const domainRe = /^([a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,}$/i;

  function showOwnedFlow(domain) {
    result.hidden = false;
    result.className = "domain-result ok";
    result.innerHTML = `
      <div style="margin-bottom:8px;color:#fff;font-weight:600">
        Nice — let's verify <span style="color:var(--accent)">${domain}</span>
      </div>
      Add this record at your domain registrar, then click verify:
      <div style="margin-top:10px;display:grid;gap:6px;font-family:ui-monospace,monospace;font-size:12.5px">
        <div>TYPE  <code>NS</code></div>
        <div>HOST  <code>_liefle</code></div>
        <div>VALUE <code>verify.liefle.com</code></div>
      </div>
      <div style="margin-top:14px;display:flex;gap:8px;flex-wrap:wrap">
        <button type="button" class="btn btn-primary" onclick="this.innerText='Verified ✓';this.disabled=true;this.style.opacity=0.7">Verify domain</button>
        <button type="button" class="btn btn-outline" onclick="document.getElementById('domainResult').hidden=true">Cancel</button>
      </div>
    `;
  }

  function showInvalid() {
    result.hidden = false;
    result.className = "domain-result";
    result.innerHTML = `That doesn't look like a valid domain. Try <code>yourbrand.com</code>.`;
  }

  function showFreeFlow() {
    result.hidden = false;
    result.className = "domain-result ok";
    result.innerHTML = `
      <div style="margin-bottom:8px;color:#fff;font-weight:600">No domain? No stress.</div>
      Pick a free subdomain — yours for 24 hours to try the editor.
      <div style="margin-top:12px;display:flex;align-items:center;gap:6px;background:var(--bg);border:1px solid var(--border);border-radius:999px;padding:6px 6px 6px 14px">
        <input id="subInput" placeholder="mybrand" style="flex:1;background:transparent;border:0;outline:none;color:var(--text);font:500 15px var(--font);padding:8px 0" />
        <span style="color:var(--muted);font-size:14px">.falcon.codes</span>
        <button type="button" class="btn btn-primary" onclick="this.innerText='Reserved ✓';this.disabled=true;this.style.opacity=0.7">Claim</button>
      </div>
      <div style="margin-top:10px;font-size:12.5px;color:var(--muted)">
        Free trial sites are removed after 24h unless upgraded ($1/mo and up).
      </div>
    `;
    setTimeout(() => document.getElementById("subInput")?.focus(), 30);
  }

  form.addEventListener("submit", (e) => {
    e.preventDefault();
    const val = input.value.trim().toLowerCase().replace(/^https?:\/\//, "").replace(/\/.*$/, "");
    if (!val) { input.focus(); return; }
    if (!domainRe.test(val)) { showInvalid(); return; }
    showOwnedFlow(val);
  });

  noDomainBtn.addEventListener("click", showFreeFlow);

  // Smooth scroll for anchor links in nav
  document.querySelectorAll('a[href^="#"]').forEach((a) => {
    a.addEventListener("click", (e) => {
      const id = a.getAttribute("href").slice(1);
      if (!id) return;
      const el = document.getElementById(id);
      if (el) { e.preventDefault(); el.scrollIntoView({ behavior: "smooth", block: "start" }); }
    });
  });
})();
