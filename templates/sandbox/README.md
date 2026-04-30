# Sandbox Reference Architecture

Two ready-to-deploy sandbox environments for stage 3 of the AI-Built App
Promotion Runbook. Pick the one that fits your regulatory posture.

## A. Cloudflare-native (low-friction)

**Best for**: SaaS, mid-market, cloud-first orgs without strict residency rules.

**Stack**: Cloudflare Pages preview build (or Workers for arbitrary apps) +
Cloudflare Access for SSO + R2 for artefacts + D1 for sandbox-only data + a
scheduled Worker for auto-expiry.

**Files**:
- `wrangler.toml` — drop-in deployment template
- (the Worker code itself lives in your AI-built app's repo)

**Setup** (15 min):
1. Edit `wrangler.toml` — replace `[YOUR_CLOUDFLARE_ACCOUNT_ID]`,
   `[Organization Name]`, `[REPLACE_WITH_TENANT_SLUG]`, `[REPLACE_WITH_OWNER_EMAIL]`.
2. In the Cloudflare Zero Trust dashboard, configure an Access application
   protecting `sandbox-*.aigov.<your-domain>` with a policy requiring the
   `security-reviewers` SSO group + compliant device + MFA.
3. `wrangler d1 create ai-sandbox-<slug>` and `wrangler kv namespace create
   SANDBOX_KV` — paste the IDs back into `wrangler.toml`.
4. `wrangler deploy`. Note the URL.
5. Send the URL to the security review queue. Reviewer signs in via SSO.

**Cost**: pennies per sandbox tenant per month.

**Auto-expiry**: the daily cron Worker checks `SANDBOX_EXPIRES_AT` and tears
down R2 / D1 / KV on day 15.

## B. Self-hosted (regulated)

**Best for**: F500, public sector, regulated finance/health, on-prem mandates.

**Stack**:
- `app` — the AI-built app under review (read-only filesystem, no caps)
- `oauth-proxy` — OAuth2-Proxy gating access to the `security-reviewers` group
- `vector` — log shipper to SIEM
- `falco` — eBPF runtime detection
- `egress-firewall` — NGINX forward-proxy restricting outbound

**Files**:
- `docker-compose.yml` — full stack
- `.env.example` — required environment variables
- `vector.yaml` — log pipeline (sketch)
- `falco-rules.yaml` — runtime detections (sketch)
- `egress-allow-list.conf` — outbound allow-list (sketch)

**Setup** (60–90 min on a fresh host):
1. Provision a small VM in an isolated VPC with no production network reach.
2. Install Docker + Compose plugin.
3. Copy `.env.example` to `.env`, fill in OIDC + SIEM details.
4. `docker compose up -d`.
5. Configure DNS / TLS termination at the edge (Caddy / Traefik / ALB) pointing
   at the host's :443.
6. Send the URL to the security review queue.

**Tear-down**: `docker compose down -v && docker volume prune -f`. Schedule
via external cron after 14 days.

## What both variants enforce

| Control | How |
| --- | --- |
| Authenticated to security reviewers only | SSO group gating (Cloudflare Access / OAuth2-Proxy) |
| No production data | Synthetic data backend / read-only mounts; sandbox-only DBs |
| No production network reach | Network policies / private Docker network / egress firewall |
| Full request logging | Cloudflare logs to R2 + SIEM / Vector to SIEM |
| Runtime detection | Cloudflare WAF + bot management / Falco eBPF rules |
| Auto-expiry | Cron Worker / external cron destroys after 14 days |
| Signed artefact verification | Wrangler validates upload hashes / Kyverno admission control |

## Framework references

- NIST AI RMF MANAGE-1.3
- ISO/IEC 42001:2023 A.6.2.7
- NIST SSDF PW.4
- NCSC / CISA Guidelines for Secure AI System Development — Secure Deployment
- NIST SP 800-190 — Container Security
- OWASP LLM03, LLM06
