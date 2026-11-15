# Local development

## Requirements

- Ruby 3.3+
- PostgreSQL 14+
- Bundler
- Node.js is not required for the initial Importmap/Hotwire setup.

## Setup

1. Install dependencies: `bundle install`
2. Create and migrate the database: `bin/rails db:prepare`
3. Load/update the carrier directory: `bin/rails db:seed`
4. Start the app: `bin/rails server`

The database configuration reads DATABASE_HOST, DATABASE_USER, DATABASE_PASSWORD and DATABASE_NAME. Rails can also use DATABASE_URL in hosted environments. Never commit production credentials.

## Background jobs

- Development uses Active Job's in-process `:async` adapter; queued work is not durable across process restarts.
- Tests use the `:test` adapter. Specs can assert enqueued jobs or call `perform_now` explicitly.
- Production uses Solid Queue on the primary PostgreSQL database.
- Start a separate production worker with `bin/jobs start`, or enable the optional Solid Queue Puma plugin with `SOLID_QUEUE_IN_PUMA=true` and `config/puma.rb`.
- The Puma plugin's async mode is intended for a small single-service deployment. A dedicated worker is preferable for production scale.
- Deployments must run `bin/rails db:prepare` and ensure Solid Queue is running.

## Current implementation

- Agency registration creates an agency, user and agency_admin membership transactionally.
- Sign-in rotates the session; sign-out clears it. Email verification, password recovery, MFA challenge/recovery and session-version revocation are implemented; configure a real email delivery provider before enabling production registration.
- The active agency is derived from authenticated membership; controllers do not trust a submitted agency ID.
- Customer CRUD and insurance application CRUD are tenant-scoped; read-only members cannot write.
- Applications capture structured business details, exposure values, requested coverage limits and broker notes in JSONB fields.
- Draft/ready applications can be edited; marketed applications are locked to preserve the submission snapshot.
- Application create/update and market response events are audit logged.
- Marketing requires a risk state and effective date. Market eligibility is filtered by configured line-of-business and state appetite.
- Carrier responses can persist normalized quote fields, fees, taxes, coverages, conditions and exclusions. Quote rows are idempotent by carrier quote reference.
- The seed data includes five planned carrier integration targets and four clearly labeled demo markets. Demo responses never produce a premium or quote.
- Only the demo environment has an adapter. IFG / Grow, Markel, Nationwide, Penn-America and Atlantic Casualty remain planned until technical access and authorization are confirmed.

## Not implemented yet

- Document uploads, scanning, encrypted object storage and extraction.
- Multiple risk locations and full supplemental-question mapping.
- Authorized live carrier/aggregator integrations, webhooks and production quote normalization tests.
- Proposal approval, bind request, policy servicing and renewal workflows.
- Staff invitations, complete permission matrix, billing and production email/deployment setup.

## Validation

Run `bin/rails db:prepare`, `bin/rails db:seed` and `bundle exec rspec` after dependencies are installed. GitHub Actions runs the RSpec suite against PostgreSQL. A green request suite is not a production security, carrier authorization or regulatory certification.
