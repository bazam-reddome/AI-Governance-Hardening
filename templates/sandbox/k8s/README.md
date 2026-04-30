# Kubernetes hardening — AI-built application reference

A minimal, opinionated set of manifests for deploying an AI-built application
to Kubernetes safely. Adapt placeholders (`<your-app>`, `<your-namespace>`,
`<your-org>`, `<DIGEST>`) before applying.

## What's in this directory

| File | Purpose |
| --- | --- |
| `deployment.yaml` | Namespace with PSS-restricted enforcement, dedicated ServiceAccount with `automountServiceAccountToken: false`, hardened Deployment (runAsNonRoot, readOnlyRootFilesystem, drop ALL caps, RuntimeDefault seccomp, resource requests + limits, ephemeral-storage limit, topology spread, PDB). |
| `networkpolicy.yaml` | Default-deny ingress + egress, plus targeted allow-lists for DNS, ingress controller, and the model API. |
| `kyverno-policies.yaml` | Five Kyverno cluster policies: image signature verification (cosign keyless), deny privileged / host-namespaces / default-SA, require resource limits + non-root + read-only-root, require image digests in prod, harden the default ServiceAccount. |

## Aligned to

- **Kubernetes Pod Security Standards (PSS)** — restricted profile
- **NSA / CISA Kubernetes Hardening Guide v1.2** (Aug 2022) — pod security, network separation, supply-chain
- **CIS Kubernetes Benchmark** — Pod and PodSpec sections (5.x)
- **Sigstore cosign + Rekor** for signature verification
- **NIST SSDF + SLSA v1.0** — image provenance and signing match what `templates/ci/ai-app-gates.yml` produces

## Apply order

```bash
# 1. Install Kyverno (one-time per cluster)
helm repo add kyverno https://kyverno.github.io/kyverno/
helm repo update
helm install kyverno kyverno/kyverno -n kyverno --create-namespace

# 2. Apply admission policies cluster-wide
kubectl apply -f kyverno-policies.yaml

# 3. Create namespace + ServiceAccount + Deployment + PDB
kubectl apply -f deployment.yaml

# 4. Apply network segmentation (CNI must enforce NetworkPolicy)
kubectl apply -f networkpolicy.yaml
```

## Stage-rolling the policies

If you have legacy workloads that may not pass on day one, change every
`validationFailureAction: Enforce` in `kyverno-policies.yaml` to `Audit`,
deploy, watch the violations for a sprint, fix the offenders, then flip
back to `Enforce`.

The image-signature verification policy (`verify-image-signatures`) cannot
be safely run in `Audit` — it's the primary supply-chain control. Either
enforce it or remove it; running it in audit mode communicates a false sense
of security.

## What this does NOT cover (deliberately)

- **Service mesh** — mTLS, authz policies, traffic shaping. If you run istio /
  linkerd, layer their authorisation policies on top of these NetworkPolicies.
- **Runtime detection** — Falco, KubeArmor, Tetragon. See category 13 of
  `templates/ci/TOOL_CATALOG.md`.
- **Secrets management at scale** — use the External Secrets Operator backed
  by AWS Secrets Manager / Azure Key Vault / GCP Secret Manager / HashiCorp
  Vault, rather than relying on plain `Secret` resources.
- **Multi-tenancy isolation** — vcluster / Capsule / Loft if you need stronger
  tenant separation than namespaces + NetworkPolicy provide.
- **GPU / accelerator pools** — if your workload uses GPUs, add the NVIDIA
  device plugin policies and review `nvidia-smi` access controls separately.

## Tracked controls

The hardening posture in this directory maps to these workbook control IDs
(see `templates/AI-Hardening-Controls-v1.0.xlsx`):

| Control ID | What it covers |
| --- | --- |
| HRD-I05 | Egress allow-list (NetworkPolicy) |
| HRD-J01 | Deny external actions by default (default-deny + targeted allow) |
| HRD-L02 | Image signing + provenance attestation produced in CI |
| HRD-L06 | CycloneDX SBOM with AI/ML extension shipped per image |
| HRD-L07 | Pre-deploy verification (Kyverno verifyImages) |
| HRD-L13 | Branch-protection + admission-gate on production cluster |
| HRD-M13 | Egress allow-list — application can only reach approved model APIs |
