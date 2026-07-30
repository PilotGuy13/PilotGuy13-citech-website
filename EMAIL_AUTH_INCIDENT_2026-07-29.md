# Email Authentication Incident & Fix — citechnologies.io (and account-wide)

**Incident date:** 2026-07-29
**Status:** Resolved. All four domains in the Cloudflare account now pass SPF + DKIM + DMARC.
**Related:** [`AZURE_MIGRATION_PLAN.md`](./AZURE_MIGRATION_PLAN.md) — the migration that caused this.

---

## TL;DR

During the migration of **citechnologies.io** from GitHub Pages to **Azure Static Web Apps**,
the apex DNS records in Cloudflare were replaced in a way that **silently dropped the email
authentication TXT records** (SPF, DKIM, DMARC). Outbound mail from `hello@citechnologies.io`
then started hard-bouncing at Gmail with `550-5.7.26` ("unauthenticated").

All three records were re-created in Cloudflare and verified live. An account-wide sweep found
`talenthunterapp.io` was also missing DKIM + DMARC; those were added too. The website itself was
never down — it correctly serves HTTP 200 from Azure the whole time.

---

## Root cause

- The Azure Static Web Apps migration swapped the apex records (A/CNAME) in Cloudflare.
- The operation did not preserve the pre-existing email-auth TXT records, so
  `SPF`, `DKIM`, and `DMARC` for `citechnologies.io` were removed.
- Gmail's 2024 sender rules require **SPF _or_ DKIM to pass**. With neither present, mail was rejected.

## Impact

- **Affected:** outbound email from `hello@citechnologies.io` (bounced at Gmail and any provider
  enforcing sender authentication).
- **Not affected:** the website — `https://citechnologies.io` served HTTP 200 from Azure SWA
  (`mango-cliff-092baf300.7.azurestaticapps.net`) throughout.

## The bounce (evidence)

```
Remote server returned '554 5.0.0 <gmail-smtp-in.l.google.com #5.0.0 smtp;
550-5.7.26 Your email has been blocked because the sender is unauthenticated.
Gmail requires all senders to authenticate with either SPF or DKIM.
Authentication results: DKIM = did not pass  SPF [citechnologies.io] with ip:[104.207.68.42] = did not pass'
```

Diagnosis confirmed via public DNS resolvers: no SPF, no DKIM at `privateemail._domainkey`,
no DMARC. The mail server *was* signing with DKIM (`s=privateemail`), but the matching public
key was not published.

---

## The fix

Environment (for context):
- **DNS:** Cloudflare (account `Hello@citechnologies.io`, zone id `ca4e4df0d93cb963bdda736cee0fb729`)
- **Website:** Azure Static Web Apps
- **Mail:** Namecheap Private Email (`mx1/mx2.privateemail.com`), DKIM selector `privateemail`

Records added to Cloudflare for **citechnologies.io** (all TXT, DNS-only):

| Name | Content |
|------|---------|
| `@` (root) | `v=spf1 include:spf.privateemail.com ~all` |
| `privateemail._domainkey` | `v=DKIM1;k=rsa;p=…` (2048-bit key from the Namecheap Private Email panel) |
| `_dmarc` | `v=DMARC1; p=none; rua=mailto:hello@citechnologies.io` |

SPF coverage was verified: the bounce's sending IP `104.207.68.42` falls in `104.207.68.0/24`,
which is inside `spf-pe.jellyfish.systems` → included by `spf.privateemail.com`. So SPF now **passes**.

---

## Account-wide sweep

All four domains share the same Cloudflare account and Namecheap Private Email. Final state:

| Domain | SPF | DKIM | DMARC | Notes |
|--------|-----|------|-------|-------|
| citechnologies.io | ✅ | ✅ | ✅ | Fixed this incident |
| jobhunterapp.io | ✅ | ✅ | ✅ | Was already healthy |
| orgcheck.io | ✅ | ✅ | ✅ | Was already healthy (`p=quarantine`) |
| talenthunterapp.io | ✅ | ✅ | ✅ | DKIM + DMARC were missing; added this incident |

`talenthunterapp.io` DMARC added: `v=DMARC1; p=none; rua=mailto:talent@talenthunterapp.io`.

---

## Runbook — retrieve a Namecheap Private Email DKIM key

The DKIM public key is unique per domain and lives in the Namecheap dashboard, **not** in webmail:

1. Namecheap → **Private Email** → the subscription → **MANAGE**.
2. **Email Security → DKIM → SHOW DKIM**.
3. Host is always `privateemail._domainkey`. Click **COPY** on the **"DNS Record"** field
   (the full `v=DKIM1;k=rsa;p=…` value).
4. In Cloudflare, add a **TXT** record: Name `privateemail._domainkey`, paste the value, save.

Transfer the value by **clipboard copy/paste** (Namecheap → Cloudflare). DKIM public keys are
public by design, but browser tooling may refuse to echo long key strings, so copy/paste is the
reliable path.

---

## Verification

- SPF, DKIM, DMARC for all four domains confirmed resolving on both Cloudflare (`1.1.1.1`) and
  Google (`8.8.8.8`) public resolvers.
- CIT DKIM published as a full 2048-bit key (413 chars) at `privateemail._domainkey`.
- Cloudflare Security Center → **Scan now → Full scan** was run for CIT; the "SPF Record Error"
  insight cleared. (The Security Center's cached findings lag the live DNS by one scan cycle, so
  a stale "DMARC Record Error" may briefly persist before its own re-evaluation — the live DMARC
  record is valid and verified.)

---

## Open / optional follow-ups (not blocking)

1. **CIT is "DNS-only" (grey cloud) in Cloudflare** after the Azure move. Consequences:
   - Cloudflare **"unique visitors" reads 0** (Cloudflare isn't in the traffic path to count it).
   - The **"Unproxied CNAME Record detected"** security insight appears.
   - No Cloudflare CDN/WAF/analytics for this site (Azure handles delivery/SSL directly).
   - *If* Cloudflare proxying is wanted back, re-enable the orange cloud deliberately and
     verify Azure SWA SSL/custom-domain validation still works — do not flip it casually.
2. **DMARC policy is `p=none`** (monitor-only) on CIT and talenthunter — a safe starting point.
   Consider tightening to `p=quarantine` (as orgcheck already uses) after reviewing DMARC reports.
3. Cloudflare Security Center will also keep suggesting optional features (Bot Fight Mode,
   AI Labyrinth) — these are nudges, not problems.

---

## Lessons learned

- **Host migrations that swap apex records can silently drop email-auth TXT records.**
  After any DNS migration, immediately re-verify SPF / DKIM / DMARC on the affected domain
  (and on sibling domains sharing the same DNS/mail setup).
- Keep a record of the expected email-auth records per domain so they can be restored quickly.
