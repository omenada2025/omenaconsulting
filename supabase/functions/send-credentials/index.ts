const corsHeaders = {
  "Access-Control-Allow-Origin": Deno.env.get("SENDGRID_ALLOWED_ORIGIN") || "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

type InvitePayload = {
  to?: string;
  displayName?: string;
  username?: string;
  password?: string;
  role?: string;
  loginUrl?: string;
};

function jsonResponse(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}

function requiredEnv(name: string) {
  const value = Deno.env.get(name);
  if (!value) throw new Error(`Missing ${name}`);
  return value;
}

function escapeHtml(value: string) {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

function textEmail(payload: Required<InvitePayload>) {
  return [
    `Hello ${payload.displayName},`,
    "",
    "Your Omena Consulting dashboard access has been created.",
    "",
    `Login: ${payload.loginUrl}`,
    `Username/email: ${payload.username}`,
    `Access code: ${payload.password}`,
    `Role: ${payload.role}`,
    "",
    "Please sign in and keep these credentials secure.",
  ].join("\n");
}

function htmlEmail(payload: Required<InvitePayload>) {
  const displayName = escapeHtml(payload.displayName);
  const loginUrl = escapeHtml(payload.loginUrl);
  const username = escapeHtml(payload.username);
  const password = escapeHtml(payload.password);
  const role = escapeHtml(payload.role);
  return `
    <div style="font-family:Arial,sans-serif;line-height:1.5;color:#17212b">
      <h2>Omena Consulting access</h2>
      <p>Hello ${displayName},</p>
      <p>Your dashboard access has been created.</p>
      <table style="border-collapse:collapse">
        <tr><td style="padding:6px 10px;font-weight:bold">Login</td><td style="padding:6px 10px"><a href="${loginUrl}">${loginUrl}</a></td></tr>
        <tr><td style="padding:6px 10px;font-weight:bold">Username/email</td><td style="padding:6px 10px">${username}</td></tr>
        <tr><td style="padding:6px 10px;font-weight:bold">Access code</td><td style="padding:6px 10px">${password}</td></tr>
        <tr><td style="padding:6px 10px;font-weight:bold">Role</td><td style="padding:6px 10px">${role}</td></tr>
      </table>
      <p>Please sign in and keep these credentials secure.</p>
    </div>
  `;
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (request.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  try {
    const sendgridApiKey = requiredEnv("SENDGRID_API_KEY");
    const fromEmail = requiredEnv("SENDGRID_FROM_EMAIL");
    const fromName = Deno.env.get("SENDGRID_FROM_NAME") || "Omena Consulting";
    const payload = await request.json() as InvitePayload;

    const requiredPayload: Required<InvitePayload> = {
      to: payload.to || payload.username || "",
      displayName: payload.displayName || payload.username || "User",
      username: payload.username || payload.to || "",
      password: payload.password || "",
      role: payload.role || "Admin",
      loginUrl: payload.loginUrl || "",
    };

    if (!requiredPayload.to || !requiredPayload.username || !requiredPayload.password || !requiredPayload.loginUrl) {
      return jsonResponse({ error: "Missing required invite fields" }, 400);
    }

    const response = await fetch("https://api.sendgrid.com/v3/mail/send", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${sendgridApiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        personalizations: [
          {
            to: [{ email: requiredPayload.to, name: requiredPayload.displayName }],
            subject: "Omena Consulting access",
          },
        ],
        from: { email: fromEmail, name: fromName },
        content: [
          { type: "text/plain", value: textEmail(requiredPayload) },
          { type: "text/html", value: htmlEmail(requiredPayload) },
        ],
      }),
    });

    if (!response.ok) {
      const detail = await response.text();
      return jsonResponse({ error: "SendGrid rejected the email request", detail }, response.status);
    }

    return jsonResponse({
      ok: true,
      to: requiredPayload.to,
      status: response.status,
      sent_at: new Date().toISOString(),
    });
  } catch (error) {
    return jsonResponse({ error: error instanceof Error ? error.message : "Unknown error" }, 500);
  }
});

