# Infrastructure & Repository Change Log

A running log of infrastructure, hosting, and repository-level changes for the
CI Technologies website. Newest entries first. For the email-authentication
incident, see [`EMAIL_AUTH_INCIDENT_2026-07-29.md`](./EMAIL_AUTH_INCIDENT_2026-07-29.md).

---

## 2026-07-30 — Repository made private + GitHub Pages retired

**Summary:** The GitHub repo `PilotGuy13/PilotGuy13-citech-website` was switched
from **public → private**. GitHub Pages (already dormant) was disabled as a
direct result. The live website was unaffected.

### Context
The site was migrated from GitHub Pages to **Azure Static Web Apps** (see
`AZURE_MIGRATION_PLAN.md`). By this date the DNS cutover was already complete:

- `citechnologies.io` and `www` resolve to Azure (`*.azurestaticapps.net`).
- The site serves **HTTP 200 from Azure** (verified during and after the change).
- GitHub Pages was still *enabled* on the repo (status "built", custom domain
  `citechnologies.io`, HTTPS cert approved) but **no longer in the serving path** —
  DNS pointed at Azure, not at Pages.

Because Pages was dead weight and the public repo exposed internal identifiers
(see "Related exposure" below), the repo was made private.

### What changed
| Item | Before | After |
|------|--------|-------|
| Repo visibility | Public | **Private** |
| GitHub Pages | Enabled ("built", cname `citechnologies.io`) | **Disabled** (auto-removed on going private; API now returns 404) |
| Live site (Azure SWA) | HTTP 200 | HTTP 200 (unchanged) |
| Azure deploy (GitHub Actions + `AZURE_SWA_TOKEN`) | Working | Working (Actions run on private repos) |

### Why this is safe
- **Deployment is Azure, not Pages.** The `azure-swa.yml` workflow deploys via the
  `AZURE_SWA_TOKEN` secret; GitHub Actions and repo secrets work identically on
  private repos.
- **Live domain is on Azure via DNS**, independent of GitHub repo visibility.
- **GitHub Pages on the Free plan is not available for private repos**, so going
  private auto-disabled it. Since Pages was already dormant, nothing broke.
  (This confirmed the account is on the GitHub **Free** plan — on Pro/Team, Pages
  would have remained enabled.)

### Trade-offs / things to know
- **Actions minutes:** public repos get unlimited free Actions; private repos draw
  from the free **2,000 minutes/month**. The no-build static deploy uses ~1 min per
  push — negligible.
- **`CNAME` file** still contains `citechnologies.io` (a GitHub Pages marker). It is
  now inert since Pages is disabled; left in place, harmless. Remove it only if you
  want to fully purge Pages remnants.
- **`AGENTS.md`** notes "the repo is public" — now stale; worth a one-line update.

### Related exposure (resolved by this change)
The committed `EMAIL_AUTH_INCIDENT_2026-07-29.md` contains the Cloudflare zone ID
and the `Hello@citechnologies.io` account name (no secrets, no keys). Making the
repo private removes that public exposure.

### Verification
- `gh repo view` → `visibility: PRIVATE`, `isPrivate: true`.
- `gh api repos/.../pages` → `404 Not Found` (Pages disabled).
- `curl -I https://citechnologies.io` → `HTTP 200` from Azure, before and after.

### Rollback (if ever needed)
- Re-public: `gh repo edit PilotGuy13/PilotGuy13-citech-website --visibility public --accept-visibility-change-consequences`
- Re-enable Pages: repo **Settings → Pages**, source `main` / root (only needed if
  reverting off Azure — not recommended, since DNS is on Azure).

---

## 2026-07-29 — Email authentication restored (all account domains)

Azure migration had dropped `citechnologies.io`'s SPF/DKIM/DMARC records, causing
Gmail to hard-bounce outbound mail. All three were restored; an account-wide sweep
also fixed missing DKIM/DMARC on `talenthunterapp.io`. All four domains
(citechnologies.io, jobhunterapp.io, orgcheck.io, talenthunterapp.io) now pass
SPF + DKIM + DMARC.

**Full detail:** [`EMAIL_AUTH_INCIDENT_2026-07-29.md`](./EMAIL_AUTH_INCIDENT_2026-07-29.md)
