# InsurrBrdge

**Commercial insurance brokerage workflow SaaS.**

InsurrBrdge is a multi-tenant workspace for commercial insurance agencies. It captures business risks, prepares insurance applications, screens configured market appetite, coordinates market submissions and tracks carrier-originated responses without fabricating quotes.

## Working MVP workflow

1. Register an agency and sign in through verified, tenant-scoped membership.
2. Create and manage customer accounts.
3. Create a commercial insurance application for a customer.
4. Capture line of business, state, effective/expiration dates, industry, entity type, website, revenue, employee count, payroll, sales, subcontractor costs, location count, square footage, requested coverage limits and broker notes.
5. Edit draft/ready applications; changes are audit logged. Applications lock after marketing begins.
6. Screen and submit independently to configured demo/sandbox markets.
7. Track market responses and normalize genuine carrier/aggregator quote records for comparison when an authorized adapter returns quote details.

## Quote integrity and regulatory boundary

A quote is represented as carrier-originated only when it comes from an authorized carrier API, approved aggregator, or documented broker/carrier workflow. Demo and simulated market outcomes are always labeled DEMO / SIMULATED. They do not create premiums, coverage terms, bindable offers, or guaranteed prices.

Carrier names in the integration register are targets, not active connections. Production use requires current technical documentation, commercial authorization, credentials, state/product availability, and appropriate producer/agency licensing. InsurrBrdge is not a rate-making or underwriting authority.

## Current implementation

- Rails 8.1 and PostgreSQL foundation.
- Agency registration, password authentication, email verification, password recovery, MFA challenge/recovery and session-version revocation.
- Agency memberships, roles and tenant-scoped workspace.
- Customer create/read/update/delete workflows with audit events.
- Insurance application intake, edit, detail and list workflows with structured risk data.
- Draft/ready edit lock after market submission; tenant-scoped access and audit logging.
- Active Job and Solid Queue market orchestration.
- Deterministic line-of-business/state appetite screening and four explicitly simulated demo markets.
- Carrier quote normalization, idempotent quote storage by carrier reference, and side-by-side quote comparison.
- PostgreSQL-backed GitHub Actions request tests.

## Carrier integration targets (not yet connected)

- IFG / Grow
- Markel
- Nationwide
- Penn-America
- Atlantic Casualty

CoverForce authentication and API client foundations exist, but no agency credentials, carrier appointments, provider-approved sandbox access or live adapter configuration have been supplied. These markets remain disabled. Demo responses never produce quotes.

## Remaining release work

- Document uploads, malware scanning, encrypted object storage and retention.
- Multiple risk locations, contacts, vehicles/property schedules and document extraction.
- Versioned appetite rules and provider-specific supplemental questions.
- Authorized CoverForce/carrier sandbox adapter, webhook handling and production quote tests.
- Proposal approvals, bind requests, policy records and renewals.
- Staff invitations, granular role permissions and audit-event export.
- Subscription plans, usage metering and billing.
- Production email delivery, deployment secrets, durable storage, monitoring, backups and restore drills.
- Security, privacy, producer licensing and regulatory review before real customer data or binding.

## Architecture

Ruby on Rails 8.1, PostgreSQL, Hotwire, Active Job, Solid Queue, Active Storage and isolated carrier adapters. Provider-specific behavior stays behind adapter boundaries.

Do not use this early development build for real customer data, production underwriting, binding or payment processing until security, legal, licensing, carrier authorization and operational readiness reviews are complete.

See docs/PRODUCT_AND_ARCHITECTURE.md, docs/CARRIER_INTEGRATIONS.md, docs/DEVELOPMENT.md, docs/SECURITY_AND_ACCESS.md and docs/DEPLOYMENT.md.
