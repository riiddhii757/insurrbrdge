# Product and architecture

## Product promise

A commercial insurance account is entered once, then routed to multiple eligible markets. Brokers receive a traceable view of where it was submitted, what each market needs, and which genuine quotes have been returned.

The platform is not a rate-making engine and does not invent premiums. Underwriting decisions, terms and prices belong to the carrier or an authorized quoting provider.

## Tenancy and access

- Every agency-owned business record is scoped to an agency/tenant.
- Users belong to one or more agencies through memberships.
- Roles begin with platform admin, agency owner/admin, producer/broker, account manager and read-only service user.
- Authorization is enforced server-side for every read and write; hiding UI controls is not authorization.
- Audit events capture actor, tenant, action, target, timestamp and safe change metadata.

## Domain model (initial)

- Agency, User, Membership
- Customer, Business, Contact, Location
- Application, CoverageRequest, Exposure, Classification
- Carrier, CarrierProduct, CarrierAppetiteRule
- MarketSubmission, CarrierSubmissionAttempt
- Quote, QuoteCoverage, QuoteCondition, QuoteExclusion
- Document, Task, Note, Approval
- BindRequest, Policy, Renewal
- AuditEvent, Notification, Subscription, UsageEvent

Records with commercial or personal information must be tenant-scoped. Carrier credentials belong in encrypted secret storage/environment configuration, never source control or ordinary database text fields.

## Submission lifecycle

Draft -> Validating -> Ready -> Marketing -> Partially Quoted / Quoted / Needs Information / Declined -> Selected -> Bind Requested -> Bound / Not Taken.

Each market submission has its own state and immutable event history. A failure at one carrier must not cancel other carrier attempts.

## Carrier adapter contract

A carrier adapter accepts a normalized submission and returns a typed result:
- eligible / ineligible / refer / needs-information / unsupported
- carrier submission reference, if supplied
- quote response with carrier-originated identifiers and timestamps
- structured coverage, limit, deductible, premium, fees, taxes and conditions
- bind capability and requirements, if authorized

Every response records source, environment (sandbox/production), request correlation ID, timestamps and redacted diagnostics. Retries must be idempotent where the provider supports it.

## Security and compliance foundations

- HTTPS in deployed environments; secure cookies and CSRF protection.
- Password hashing and optional MFA; session revocation.
- Tenant isolation tests and least-privilege authorization.
- Encrypt sensitive fields and uploaded files; signed, short-lived file access.
- Validate file type/size and scan uploads before production use.
- Redact secrets and personal data from logs.
- Rate limiting, audit logging, backups and restore drills.
- Retention, deletion, privacy notices and incident-response procedures.
- Legal review for state producer licensing, surplus-lines rules, privacy, insurance advertising, quote presentation, payments and electronic signatures.

## Commercial model

Start with agency subscriptions, seat tiers and usage limits (e.g. active users, submissions and document storage). Keep billing behind an interface so a payment provider can be added after pricing, tax, invoicing and merchant requirements are decided. Do not store card numbers.

## Delivery phases

1. Rails foundation, database, authentication, tenancy and authorization.
2. Customer, business, location and application workflows.
3. Carrier registry, appetite rules, adapter contract and demo adapters.
4. Submission orchestration, quote normalization and comparison.
5. Documents, tasks, notifications, audit and reporting.
6. Bind/policy/renewal workflow and approved provider integrations.
7. Subscription metering, billing integration, security hardening and deployment.
