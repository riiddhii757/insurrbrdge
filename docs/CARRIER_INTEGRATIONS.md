# Carrier integration register

This register distinguishes verified public integration capabilities from connections that still require appointment, contracts, credentials and provider documentation. A carrier appearing here does not mean InsurrBrdge is appointed, connected, or authorized to quote or bind.

## Provider-by-provider access plan

| Provider | Verified public capability | What InsurrBrdge needs before implementation | Current status |
|---|---|---|---|
| Markel | Markel's apiConnect developer portal documents commercial API products and a workflow including submission/quote, bind, issue, documents, status and reference data. API calls use an OAuth access token plus an API subscription key. | Markel partner approval, API product subscription, sandbox API specification/OpenAPI file, OAuth client/application details, subscription key, producer/agency code and approved products/states. | API path identified; no agency authorization or credentials supplied. |
| Nationwide | Nationwide provides commercial quote and servicing tools to appointed agents. A published commercial-lines verification API is not the same as new-business quote access. | Active commercial appointment, agent code, access to the applicable commercial digital platform/API, integration documentation, test account and product/state permissions. | Agent access required; no public general new-business quote API confirmed. |
| IFG / Grow | IFG's Grow portal is an authenticated external-user portal with MFA. IFG distributes products through contracted producers. | Confirm the exact IFG business unit/program and whether Grow exposes an approved API/web-service or platform partner integration for this agency; obtain the integration specification, account/producer code and sandbox access. | Portal access documented; public API contract not confirmed. |
| Penn-America | PennLINK is a login-protected wholesale-agent portal with Quick Rater and forms. Penn-America describes web-services capability and a selective wholesale-GA appointment model. | Wholesale agency appointment or authorized GA relationship, PennLINK account, web-services documentation, Quick Rater integration access, product/state appetite and sandbox credentials. | Web-services path indicated; access and technical contract required. |
| Atlantic Casualty | ACES supports online rating/quote/bind/issue and renewals/endorsements; Atlantic says general agents can provide agency rating via web services or branded portal. | Authorized general-agent relationship, ACES account, web-services/API specification, producer/agency code, product/state access and test credentials. | Web-services route identified through GA; no public API contract or account supplied. |

## Official access resources

- Markel digital distribution: https://www.markel.com/us/digital-distribution
- Markel API offerings: https://developer.markel.com/api-offerings
- Markel apiConnect getting started: https://apiconnect.developer.markel.com/getting-started
- Markel API support: https://apiconnect.developer.markel.com/support
- Markel API partner questionnaire: https://www.markel.com/us/digital-distribution/api-partner-questionnaire
- Nationwide appointed-agent resources: https://www.nationwide.com/agents/appointed-agents/
- Nationwide appointment request: https://marketing.nationwide.com/GetAppointedwithNationwide/BecomeAnAgent
- IFG Companies: https://www.ifgcompanies.com/Pages/Who-We-Are.html
- IFG Grow external-user login instructions: https://grow.ifgcompanies.com/GROW%20Login%20Process.pdf
- Penn-America wholesale appointment: https://penn-america.com/become-an-agent/
- PennLINK: https://faa.penn-america.com/agents/pennlink.aspx
- Atlantic Casualty technology: https://atlanticcasualty.net/about-acic/our-technology/
- Atlantic ACES portal information: https://agency.atlanticcasualty.net/GAPortal/login/loginstart.aspx


## Potential multi-carrier gateway: CoverForce

A promising route for the four named markets below is to integrate InsurrBrdge with CoverForce's commercial insurance API rather than build four independent carrier APIs first.

CoverForce's public 2026 carrier index lists Atlantic Casualty as API available and its broker-code help center has carrier setup guides for Markel, Nationwide and PennAmerica. Its developer page advertises a unified API for appetite, quote, bind, status, document AI and renewals. It also states that agents must already hold the relevant carrier appointments; CoverForce does not create appointments on their behalf.

- Developer/API overview: https://www.coverforce.com/developers
- Carrier index: https://www.coverforce.com/integration
- Broker-code setup overview: https://helpcenter.coverforce.com/adding-your-broker-codes
- Markel broker-code setup: https://helpcenter.coverforce.com/markel-find-direct-appointment-information
- Nationwide broker-code setup: https://helpcenter.coverforce.com/nationwide-find-direct-appointment-information
- Penn-America broker-code setup: https://helpcenter.coverforce.com/adding-your-broker-codes

**Do not assume IFG / Grow is covered.** IFG was not confirmed in the public CoverForce carrier list or broker-code guide reviewed for this plan. IFG needs a separate confirmation from IFG or CoverForce before it is promised as a connected market.

Before choosing this route, InsurrBrdge must obtain CoverForce commercial approval, API agreement, sandbox access, API schema, tenant/broker-code mapping rules, pricing and production approval. Then implement one CoverForce adapter in InsurrBrdge and enable only carrier products for which the agency has valid appointments and state/product authority. This route may shorten integration work but does not remove licensing, appointment, or contractual requirements.

## Recommended integration order

1. **Evaluate CoverForce first for Markel, Nationwide, PennAmerica and Atlantic Casualty.** Request its API partnership, commercial terms, sandbox and carrier/product availability confirmation. Its public index and help center indicate these four carrier routes exist, but the agency still needs active appointments and broker codes.
2. **Confirm IFG / Grow separately.** Ask IFG and CoverForce in writing whether the exact IFG program/product is available through a supported API or authorized platform integration. Do not automate the portal with stored human passwords unless IFG explicitly authorizes that method.
3. **If CoverForce is not commercially viable, build direct adapters:** Markel first using its apiConnect OpenAPI docs; then Atlantic ACES, Penn-America web services, Nationwide's appointed-agent platform, and IFG Grow after receiving each provider's current technical specification.

## Required InsurrBrdge connector contract

Each production adapter must implement the same lifecycle while preserving carrier-specific behavior:

- provider authentication and token refresh, with credentials kept in a secret manager
- risk/application mapping and carrier-required supplemental questions
- appetite/eligibility pre-check where the provider exposes it
- idempotent submission creation and provider correlation IDs
- asynchronous status polling or signed webhook handling
- quote normalization for premium, fees, taxes, limits, deductibles, forms, exclusions, conditions, effective dates and expiration
- document retrieval and audit trail
- bind/issue only where the provider's contract, agency appointment and API explicitly permit it
- retries with bounded exponential backoff, rate-limit handling, dead-letter review and redacted logs

No carrier-specific endpoint, payload, authentication grant or quote response may be guessed. The adapter must remain disabled until its provider specification and sandbox access have been received and tested.

## Current demo markets

The seed data includes four simulated markets for workflow development:

- Demo Market · Standard: requests additional broker information.
- Demo Market · Preferred: returns a simulated eligible appetite outcome.
- Demo Market · Referral: returns a simulated human-review referral.
- Demo Market · Outside Appetite: returns a simulated ineligible outcome.

All are stored with the `demo` environment. Every response carries a DEMO / SIMULATED label. These outcomes are not carrier decisions, do not include premiums, and cannot be exported or presented as real offers.

## Security and release gates

1. Never commit credentials, API keys, client secrets, certificates or customer data.
2. Store secrets in an encrypted secret manager; never expose them to browser JavaScript, logs, analytics or support tickets.
3. Keep sandbox and production credentials and endpoints separate.
4. Respect provider rate limits, authentication, idempotency and retry guidance.
5. Retain carrier response IDs and raw payloads only when contractually permitted; redact sensitive fields.
6. Do not infer a quote from appetite rules. Appetite is pre-screening, not a carrier offer.
7. Do not claim bind capability unless the provider explicitly supports it and the agency has authorization.
8. Test with sanitized fixtures and the provider's sandbox before enabling a carrier for a tenant.
9. Surface unavailable, declined, referred, needs-information and error outcomes distinctly.
10. Require agency-level authorization and audit every credential change, submission, quote, bind request and document download.

## What the agency must provide

For each carrier, InsurrBrdge needs the authorized legal agency name, agency/producer code, appointed lines and states, named technical/business contact, current API agreement or written permission, sandbox documentation, and provider-issued sandbox credentials. Production activation additionally requires production approval and credentials.

Do not send passwords, API keys, OAuth secrets, certificates or tokens in ChatGPT. Add them only through the deployment's approved secret manager after the integration has been implemented and tested.
