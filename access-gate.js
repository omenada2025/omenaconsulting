/**
 * Share gate for team-only docs on GitHub Pages / Cloudflare Pages.
 * Stops casual public browsing. For real SSO/password protection, use Cloudflare Access
 * (see CLOUDFLARE_PAGES.md).
 *
 * Default password: OmenaTeam2026!
 * To change: set EXPECTED_HASH to sha256 hex of the new password, then tell the team.
 */
(function () {
  const EXPECTED_HASH = "02c2db95811d3d568073e20b105763692667dfa9858c8bbc8df21847ec8d989a";
  const STORAGE_KEY = "omena-doc-access-v1";
  const PAGE_TITLE = document.title || "Protected page";

  async function sha256Hex(text) {
    const data = new TextEncoder().encode(text);
    const buf = await crypto.subtle.digest("SHA-256", data);
    return [...new Uint8Array(buf)].map((b) => b.toString(16).padStart(2, "0")).join("");
  }

  function unlocked() {
    try {
      return sessionStorage.getItem(STORAGE_KEY) === "1";
    } catch {
      return false;
    }
  }

  function setUnlocked() {
    try {
      sessionStorage.setItem(STORAGE_KEY, "1");
    } catch {
      /* ignore */
    }
  }

  function escapeHtml(value) {
    return String(value)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");
  }

  function showGate() {
    const style = document.createElement("style");
    style.textContent = `
      #omena-access-gate{position:fixed;inset:0;z-index:99999;display:grid;place-items:center;
        background:#0f1b2a;font-family:"Segoe UI",Arial,sans-serif;padding:20px}
      #omena-access-gate .card{width:min(420px,100%);background:#fff;border-radius:16px;padding:24px;
        box-shadow:0 18px 45px rgba(0,0,0,.35)}
      #omena-access-gate h1{font-size:18px;margin:0 0 8px;color:#13202e}
      #omena-access-gate p{font-size:13px;color:#657386;margin:0 0 14px;line-height:1.45}
      #omena-access-gate label{display:block;font-size:11px;font-weight:800;letter-spacing:.04em;
        text-transform:uppercase;color:#657386;margin-bottom:6px}
      #omena-access-gate input{width:100%;box-sizing:border-box;padding:10px 12px;border-radius:10px;
        border:1px solid #d8e0e8;font-size:14px;margin-bottom:10px}
      #omena-access-gate button{width:100%;padding:11px 14px;border:0;border-radius:10px;
        background:#1f5874;color:#fff;font-weight:700;font-size:14px;cursor:pointer}
      #omena-access-gate .err{color:#a21b3f;font-size:12px;font-weight:700;min-height:16px;margin:0 0 8px}
      #omena-access-gate .hint{font-size:11px;color:#94a3b8;margin-top:10px}
      body.omena-access-locked > *:not(#omena-access-gate){visibility:hidden !important}
    `;
    document.head.appendChild(style);
    document.body.classList.add("omena-access-locked");

    const gate = document.createElement("div");
    gate.id = "omena-access-gate";
    gate.innerHTML = `
      <div class="card" role="dialog" aria-modal="true" aria-labelledby="omena-access-title">
        <h1 id="omena-access-title">Team access required</h1>
        <p>${escapeHtml(PAGE_TITLE)}<br>Enter the team share password to continue.</p>
        <p class="err" id="omena-access-err" aria-live="polite"></p>
        <label for="omena-access-pw">Password</label>
        <input id="omena-access-pw" type="password" autocomplete="current-password" />
        <button type="button" id="omena-access-btn">Unlock</button>
        <p class="hint">Ask Daniela / Ops for the password. For SSO-grade protection, enable Cloudflare Access.</p>
      </div>
    `;
    document.body.appendChild(gate);

    const input = gate.querySelector("#omena-access-pw");
    const err = gate.querySelector("#omena-access-err");
    const btn = gate.querySelector("#omena-access-btn");

    async function tryUnlock() {
      err.textContent = "";
      const hash = await sha256Hex(input.value || "");
      if (hash !== EXPECTED_HASH) {
        err.textContent = "Incorrect password.";
        input.focus();
        return;
      }
      setUnlocked();
      gate.remove();
      document.body.classList.remove("omena-access-locked");
    }

    btn.addEventListener("click", tryUnlock);
    input.addEventListener("keydown", (event) => {
      if (event.key === "Enter") tryUnlock();
    });
    input.focus();
  }

  function boot() {
    if (unlocked()) return;
    showGate();
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", boot);
  } else {
    boot();
  }
})();
