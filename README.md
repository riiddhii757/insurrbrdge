# InsurrBrdge

**Commercial insurance brokerage workflow SaaS.**

InsurrBrdge is being built as a multi-tenant workspace for commercial insurance agencies. Its product direction is simple: capture a business risk once, check it against configured market appetite, coordinate submissions to eligible markets, and track carrier-originated responses without fabricating quotes.

## Core workflow

1. Capture a commercial account and reusable insurance application once.
2. Validate line of business, effective date, risk state and (as the product expands) exposure, class-code and coverage data.
3. Pre-screen markets against configured line and state appetite.
4. Submit independently to eligible carrier adapters and track each market's status.
5. Normalize genuine carrier quotes for side-by-side comparison when authorized carrier/API or aggregator integrations are available.
6. Support broker review, customer presentation, bind requests, policy tracking and renewals.

## Quote integrity and regulatory boundary

A quote is represented as carrier-originated only when it comes from an authorized carrier API, approved aggregator, or documented broker/carrier workflow. Demo and simulated market outcomes are always labeled DEMO / SIMULATED. They do not create premiums, coverage terms, bindable offers, or guaranteed prices.

Carrier names in the integration register are targets, not active connections. Production use requires current technical documentation, commercial authorization, credentials, state/product availability, and appropriate producer/agency licensing. InsurrBrdge is not a rate-making or underwriting authority.

## Current implementation

- Rails 8.1 and PostgreSQL foundation.
- Agency registration, password authentication, memberships, roles and tenant-scoped workspace.
- Customer account create/read/update/delete workflows with audit events.
- Insurance application create/list/detail workflow scoped to the active agency.
- Market submission orchestration through Active Job.
- Deterministic line-of-business and state appetite pre-screening.
- Four explicitly simulated demo markets with distinct eligible, referral, outside-appetite and needs-information outcomes.
- Solid Queue schema and production worker configuration; in-memory async jobs in development and test adapter in request specs.
- PostgreSQL-backed GitHub Actions request test workflow.

## Carrier integration targets (not yet connected)

- IFG / Grow
- Markel
- Nationwide
- Penn-America
- Atlantic Casualty

Each target remains planned until its current API/portal requirements, credentials, contract and agency authorization are verified. The demo adapter is not a substitute for a carrier connection.

## Roadmap

- Expanded business intake: contacts, locations, exposures, industry codes, payroll, revenue, schedules and documents.
- Versioned carrier appetite rules and explainable match reasons.
- Authorized carrier/aggregator adapters and quote normalization.
- Quote comparison, proposal generation and broker/customer approvals.
- Document processing, tasks, notes, notifications and workflow automation.
- Bind request tracking, policy records and renewals.
- Staff invitations, password reset, MFA and enhanced access controls.
- Subscription plans, usage metering, billing, reporting and API access.
- Production security, privacy, licensing and operational readiness reviews.

## Architecture

Ruby on Rails 8.1, PostgreSQL, Hotwire, Active Job, Solid Queue and isolated carrier adapters. Carrier-specific API behavior must remain behind the adapter boundary so provider changes do not leak into the core submission and quote domain.

Do not use this early development build for real customer data, production underwriting, binding or payment processing until security, legal, licensing, carrier authorization and operational readiness reviews are complete.

See docs/PRODUCT_AND_ARCHITECTURE.md, docs/CARRIER_INTEGRATIONS.md, docs/DEVELOPMENT.md and docs/SECURITY_AND_ACCESS.md.
