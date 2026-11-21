# Security Assessment Template — Client Onboarding / POC

> Reusable checklist applied per engagement. Copy per client, fill the brackets.

## 0. Authorization & Scope (gate before anything)

| Field | Value |
|---|---|
| **Client / Domain** | `________________` |
| **Date of assessment** | `____/__/__` |
| **Authorization on file?** | ☐ Yes ☐ No |
| **Scope defined?** | ☐ Web ☐ API ☐ Infra ☐ Other: `___` |
| **Testing window** | `from __________ to __________` |
| **Staging available?** | ☐ Yes (URL: `___`) ☐ No |
| **Read-only agreed?** | ☐ Yes ☐ No |
| **Blast-radius plan** | ☐ Documented ☐ Pending |

---

## 1. Passive Reconnaissance

| # | Check | Result | Read / Risk |
|---|---|---|---|
| P-1 | DNS trace + records | `____` | `____` |
| P-2 | Origin IP geolocation | `____` | `____` |
| P-3 | Reverse DNS / hostname | `____` | `____` |
| P-4 | Mail/DNS (SPF/DKIM/DMARC) | `____` | `____` |
| P-5 | WHOIS lookup | `____` | `____` |

**Hosting model:** ☐ Shared hosting ☐ Dedicated ☐ CDN-backed ☠️ Direct exposure
**CDN/WAF present?** ☐ Yes (`___`) ☐ No → wider attack surface

---

## 2. Attack Surface Mapping

| # | Vector | Result (404/403/Exposed) | Risk if failed |
|---|---|---|---|
| S-1 | Common paths | `____` | `____` |
| S-2 | Sensitive files | `____` | `____` |
| S-3 | Version control | `____` | `____` |
| S-4 | Config leaks | `____` | `____` |
| S-5 | Server-info exposure | `____` | `____` |
| S-6 | JS/CSS surface | `____` | `____` |
| S-7 | SQLi login surface | `____` | `____` |

**Surface risk:** ☐ LOW (nothing exposed) ☐ MEDIUM ☐ HIGH (something leaked)

---

## 3. Response Headers & Session Security

| # | Header / Flag | Present? | Risk if missing |
|---|---|---|---|
| H-1 | `Content-Security-Policy` | ☐ Yes ☐ No | XSS gap |
| H-2 | `X-Frame-Options` | ☐ Yes ☐ No | Clickjacking |
| H-3 | Cookie flags (HttpOnly/Secure/SameSite) | ☐ All set ☐ Gaps | Session hijack |
| H-4 | `Referrer-Policy` | ☐ Yes ☐ No | Data leak |
| H-5 | `Cache-Control: no-cache` | ☐ Yes ☐ No | Page caching |

**Header risk:** ☐ LOW ☐ MEDIUM ☐ HIGH

---

## 4. Performance & Behavior Baseline

| # | Check | Result | Notes |
|---|---|---|---|
| F-1 | Response speed / latency | `____` | `____` |
| F-2 | Error page behavior | `____` | `____` |
| F-3 | Session lifecycle | `____` | `____` |

**Behavior risk:** ☐ LOW ☐ MEDIUM ☐ HIGH

---

## 5. Authentication & MFA (core gap)

| # | Check | Result | Risk if failed |
|---|---|---|---|
| A-1 | 2FA / MFA enforced | `____` | Auth bypass |
| A-2 | Rate limiting on auth fields | `____` | Brute-force |
| A-3 | Generic error messages | `____` | Username enumeration |
| A-4 | Password reset flow secured | `____` | Token abuse |
| A-5 | Privilege escalation path? | `____` | Full compromise |

**Auth risk:** ☐ LOW ☐ MEDIUM ☐ HIGH ← usually the priority gap

---

## 6. Findings Summary (fill per finding)

| ID | Finding | Severity | Evidence | Remediation | Owner | Due |
|---|---|---|---|---|---|---|
| F1 | `____` | Low/Med/High | `____` | `____` | `____` | `____` |
| F2 | `____` | Low/Med/High | `____` | `____` | `____` | `____` |
| F3 | `____` | Low/Med/High | `____` | `____` | `____` | `____` |

---

## 📊 FINAL VERDICT
