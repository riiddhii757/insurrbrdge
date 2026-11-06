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

The database configuration reads DATABASE_HOST, DATABASE_USER, DATABASE_PASSWORD and DATABASE_NAME. Never commit production credentials.

## Background jobs

- Development uses Active Job's in-process `:async` adapter; queued work is not durable across process restarts.
- Tests use the `:test` adapter. Specs can assert enqueued jobs or call `perform_now` explicitly.
- Production uses Solid Queue on the primary PostgreSQL database. Its tables are included in the normal Rails migration set.
- Start production job workers with `bin/jobs start` (or `ruby bin/jobs start` if the executable bit is not preserved by a deployment system).
- Deployments must run `bin/rails db:prepare` and run the Solid Queue worker process alongside the web process.

## Current implementation notes

- The public landing page links to agency registration and sign-in.
- Agency registration creates an agency, user and agency_admin membership transactionally.
- Sign-in rotates the session; sign-out clears it. Disabled accounts and accounts without active memberships are denied workspace access.
- The active agency is derived from the authenticated user's active membership; controllers do not trust a submitted agency ID.
- Agency members can create, view, update and remove customer accounts. Every customer lookup is scoped through the authenticated agency; read-only members cannot write, and customers with submissions cannot be deleted.
- Customer create/update actions write agency audit events.
- Producers and agency admins can create and view insurance applications for customers in their own agency.
- Marketing an application requires a risk state and effective date. Market eligibility is filtered by configured line-of-business and state appetite.
- The seed data includes five planned carrier integration targets and four clearly labeled demo markets. The demo markets return distinct appetite outcomes; they never produce a premium or quote.
- Only the demo environment has an adapter. IFG / Grow, Markel, Nationwide, Penn-America and Atlantic Casualty remain planned until technical access and authorization are confirmed.
- GitHub Actions prepares PostgreSQL and runs the RSpec request suite on pushes and pull requests.

## Not implemented yet

- Full application editing, document intake, exposure schedules and data extraction.
- Versioned carrier appetite rules beyond the initial line/state match.
- Live carrier or aggregator API connections and genuine quote normalization.
- Proposal presentation, bind requests, policy servicing and renewals.
- Staff invitation flow, password reset, MFA and stronger login throttling.
- Complete authorization policy coverage, encrypted document storage, billing and production deployment.

## Validation

Run `bin/rails db:prepare`, `bin/rails db:seed` and `bundle exec rspec` after dependencies are installed. The CI workflow runs the request suite against PostgreSQL. A green request suite is not a production security, carrier authorization or regulatory certification.
