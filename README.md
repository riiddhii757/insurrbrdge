# InsurrBrdge

**Commercial insurance quoting and brokerage operations platform.**

InsurrBrdge is being built as a multi-tenant SaaS for commercial insurance agencies. Its core workflow is:

1. Capture a commercial account and reusable submission once.
2. Validate business, exposure, location, class-code and coverage data.
3. Route the submission to eligible carrier integrations.
4. Track each carrier's appetite decision, questions, submission reference and response.
5. Normalize genuine carrier quotes for side-by-side comparison.
6. Support broker review, customer presentation, bind requests, policy tracking and renewals.

## Important quote integrity rule

A quote is represented as a carrier-originated quote only when it comes from an authorized carrier/API, approved aggregator, or documented broker/carrier workflow. Development fixtures and simulated adapters must be visibly labeled DEMO / SIMULATED and must never be represented as real offers, bindable coverage, or guaranteed premiums.

Carrier names in the integration registry are targets only. Production use requires current technical documentation, a commercial agreement/authorization, credentials, state/product availability, and appropriate producer/agency licensing.

## Initial carrier integration targets

- IFG / Grow
- Markel
- Nationwide
- Penn-America
- Atlantic Casualty

Additional adapter candidates can be evaluated separately, including CoverForce, Coterie, Cover Whale and Chubb. A listed carrier is not yet connected merely because it appears in this repository.

## Product modules

- Agency tenancy, users, roles and permissions
- Business customers, contacts and locations
- Commercial lines applications and submissions
- Industry/class-code reference data and validation
- Carrier directory, appetite rules and adapter registry
- Asynchronous multi-carrier submission orchestration
- Quote normalization, comparison and customer proposals
- Documents, tasks, notes, approvals and audit events
- Bind request tracking, policy records and renewal workflows
- Notifications, reporting, API access and exports
- Subscription plans, usage metering and billing integration points

## Architecture direction

The initial implementation uses Ruby on Rails 8.1, PostgreSQL, Hotwire, background jobs and automated tests. Carrier adapters are isolated behind a stable interface so that one carrier's API changes do not leak into the core submission and quote domain.

## Development status

This repository has just been created. The initial implementation is being scaffolded in phases. Do not use it for real customer data, production underwriting, binding, or payment processing until security, legal, licensing, carrier authorization and operational readiness reviews are complete.

See docs/PRODUCT_AND_ARCHITECTURE.md and docs/CARRIER_INTEGRATIONS.md.
