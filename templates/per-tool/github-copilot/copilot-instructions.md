# GitHub Copilot — repository instructions

> Drop this file at `.github/copilot-instructions.md` in every repository.
> Copilot Chat in VS Code / JetBrains / Visual Studio reads it and prepends
> its content to every chat session within that repository.
>
> Replace `[Organization Name]` and adapt the rules to your stack before
> publishing.

## Organization standards

This project is owned by **[Organization Name]**. The following rules apply
to every code suggestion you produce, regardless of language or framework.

### Hard rules (never violate)

1. **Never include real secrets.** No API keys, tokens, passwords, JWT secrets,
   connection strings, certificates, or `.env` values in code, comments, tests,
   docs, or commit messages. Use the placeholder pattern `${ENV_VAR_NAME}` and
   call out in a comment what env var the reader must set.
2. **Never disable TLS / signature / certificate verification** in production
   code. No `verify=False`, no `rejectUnauthorized: false`, no `--insecure`.
3. **Never use eval / exec / `Function()` / `os.system` on user-controlled
   input.** Always parameterise.
4. **Never weaken auth/z checks** "to make it work". Auth must be on every
   non-public route. Authorisation must be checked per request, not at session
   creation.
5. **Never default CORS to `*` in production** code. Default to a specific
   origin allow-list.
6. **Never write code that bulk-deletes, modifies, or exfiltrates data**
   without explicit user confirmation in the same session.

### Generation defaults

- Prefer the **stdlib** over adding a new dependency for trivial functionality.
- When suggesting a new dependency, pick one with active maintenance, no known
   high-severity CVEs, and a permissive licence (MIT / Apache-2.0 / BSD).
- **Pin versions** in lockfiles. No `*` or `latest` ranges in production
   manifests.
- For SQL, **use parameterised queries** (no string concatenation).
- For HTTP, **set explicit timeouts** on every outbound call.
- For randomness, **use the cryptographic RNG** (Python `secrets`, JS
   `crypto.randomBytes`, Go `crypto/rand`) not the regular `random` API.

### Test defaults

- Tests must actually exercise the code under test. **No tautological
   assertions** like `expect(x).toBe(x)` or `assert True`.
- Edge cases include empty inputs, very large inputs, malicious inputs.
- Mock external services; do not hit real APIs in unit tests.

### When asked to write something risky

If a request is for code that disables a security control, includes a real
credential, scrapes data without permission, bypasses an auth check, or
otherwise looks like it would harm the user or others:

- **Refuse** and explain why.
- Offer an alternative that achieves the legitimate goal safely.

### Stack-specific guidance (edit per repo)

- **Language**: [primary language here, e.g. TypeScript 5.x with strict mode]
- **Framework**: [e.g. Next.js 14, FastAPI 0.110, Spring Boot 3.x]
- **Test runner**: [e.g. Vitest, pytest, JUnit 5]
- **Lint / format**: [e.g. ESLint + Prettier, Ruff + Black, golangci-lint]
- **Type checker**: [e.g. tsc --strict, mypy --strict, Pyright]
- **Style guide**: [link to internal style guide]
- **Forbidden imports / packages**: [list any libraries banned by Legal,
   Security, or platform engineering]

### Commit-message conventions

Use Conventional Commits (`feat:`, `fix:`, `docs:`, `refactor:`, `chore:`,
`test:`, `ci:`). Keep the subject under 72 characters. If the change was
materially AI-assisted, include the trailer:

```
Co-Authored-By: GitHub Copilot <[email protected]>
```

The kit's pre-commit hook detects this trailer and routes the PR for senior
reviewer approval.

### Pull-request defaults

- Include a one-paragraph description of what changed and why.
- Tick the security self-checklist in the PR template (see
  `.github/pull_request_template.md`).
- Confirm that all CI gates pass before requesting review.
