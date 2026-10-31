# Account requests and invitations

This function uses the built-in Supabase service role only on the server. Never put its value or SMTP credentials in Vite variables or source files.

The public `request` action validates and records a request, rate limits submissions and emails the administrator. It creates no Auth user. Every other action verifies the caller with Auth `getUser` and checks membership of `business_admins`. Only approval generates an invitation. Plain-text messages prevent applicant-controlled HTML or headers.

## Deployment prerequisites

- Apply the account migrations and verify the administrator was found. They preserve existing users as approved and add a restrictive approval policy alongside the existing ownership policies.
- Disable **Allow new users to sign up** in Supabase Authentication. Keep **Confirm email** enabled.
- Set the Auth site URL to `https://bum-bum-costos.bumbumpasteleria.workers.dev` and allow that same redirect destination.
- Deploy `account-access` with gateway JWT verification disabled, as declared in `supabase/config.toml`. The function implements verified JWT and admin-role checks for administrative actions; the request form is intentionally public.
- Configure Edge Function secrets: `SMTP_USERNAME` is the sending Gmail address and `SMTP_PASSWORD` is its Google app password. Set these directly in Supabase Secrets; do not paste them into chat, files, or the browser app. `SITE_URL` and optional comma-separated `ALLOWED_ORIGINS` default to the production app URL. Built-in `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` stay server-side.
- Google app-password creation is a user handoff and requires two-step verification. Use a dedicated app password that can later be revoked. This flow uses SMTP only for transactional request notices and invitations, not marketing.

## Release checklist

1. Run `supabase/tests/aprobacion_cuentas.sql`; it rolls back its synthetic fixtures.
2. Verify the existing administrator can still sign in and access business records.
3. From an admin session, test the email action and confirm delivery to `bumbumpasteleria@gmail.com`.
4. Submit a request with a controlled test email. Confirm it creates a request but no Auth user and that the admin notice is delivered.
5. Approve it, follow the invitation in a separate browser, set a password and verify a private business profile and empty business data.
6. Verify a normal or unauthenticated caller cannot list, approve, reject or resend requests.
7. Publish the front end only after the real email/invitation test passes. This feature is not release-ready until SMTP and the deployed function are checked.

Failed invitation emails leave an approved account with a retry action. Failed approvals can be retried after five minutes and recover an already-created approved user instead of duplicating the account. Rejected and approved requests remain in the administrator's audit list.
