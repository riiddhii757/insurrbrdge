# Carrier integration register

This register records requested integration targets. It does not mean an integration is live or that InsurrBrdge is authorized to quote or bind for that market.

| Market | Initial scope | Production prerequisites | Status |
|---|---|---|---|
| IFG / Grow | General Liability quote workflow; policy reference and bind lifecycle where supported | Current API docs, partner approval, credentials, state/product appetite, test account | Planned |
| Markel | Eligible commercial products and quote workflow | Current API/portal agreement, credentials, product/state access | Planned |
| Nationwide | Eligible commercial products and quote workflow | Current partner authorization, credentials and approved distribution channel | Planned |
| Penn-America | General Liability / specialty-market workflow | Current API/portal documentation and authorization | Planned |
| Atlantic Casualty | General Liability / commercial submission workflow | Current API/portal documentation and authorization | Planned |

## Adapter implementation rules

1. Implement one adapter per market behind a shared interface.
2. Store credentials in encrypted secret management; never commit credentials, API keys, client secrets, certificates or customer data.
3. Separate sandbox and production environments.
4. Respect provider rate limits, authentication, idempotency and retry guidance.
5. Preserve carrier response IDs and raw response payloads only when contractually permitted; redact sensitive fields.
6. Map provider statuses and quote terms to a normalized internal schema without losing the original carrier wording.
7. Do not infer a quote from appetite rules. Appetite is pre-screening, not a carrier offer.
8. Do not claim bind capability unless the provider explicitly supports it and the agency has authorization.
9. Add contract tests with sanitized fixtures and provider sandbox tests before enabling production.
10. Surface unavailable, declined, referred and error outcomes distinctly.

## Demo mode

A local demo adapter may return deterministic sample appetite and quote fixtures for product development. Every record and UI surface must display DEMO / SIMULATED; it must not be emailed or exported as a real carrier quote or presented as bindable coverage.
