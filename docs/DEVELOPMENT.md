# Local development

## Requirements

- Ruby 3.3+
- PostgreSQL 14+
- Bundler
- Node.js is not required for the initial Importmap/Hotwire setup.

## Setup

1. Install dependencies: bundle install
2. Create and migrate the database: bin/rails db:prepare
3. Load the carrier directory: bin/rails db:seed
4. Start the app: bin/rails server

The database configuration reads DATABASE_HOST, DATABASE_USER, DATABASE_PASSWORD and DATABASE_NAME. Never commit production credentials.

## Current implementation notes

- The public landing page links to agency registration and sign-in.
- Agency registration creates an agency, user and agency_admin membership transactionally.
- Sign-in rotates the session; sign-out clears it. Disabled accounts and accounts without active memberships are denied workspace access.
- The agency workspace displays counts and recent submissions using the active agency scope.
- Core tenant, customer, submission, carrier, market submission, quote and audit models are scaffolded.
- Initial request specs cover registration, password length and tenant separation. They are authored but have not been executed in a provisioned environment.
- The carrier directory seed includes the requested five integration targets plus one clearly labeled demo market.
- Only the demo market has an adapter. The requested commercial insurers remain planned until their current integration requirements and authorizations are confirmed.
- The demo adapter intentionally does not fabricate a premium or quote.
- Customer/submission CRUD, staff invitations, password reset, MFA, stronger login throttling, carrier API adapters, document handling, billing and production deployment remain to be implemented.

## Validation

Run bin/rails db:prepare, bin/rails db:seed and bundle exec rspec after dependencies are installed. This repository has not yet been built or test-run in a provisioned Ruby/PostgreSQL environment.
