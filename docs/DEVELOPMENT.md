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

- The home page is a product landing page, not a completed agency workspace.
- Core tenant, customer, submission, carrier, market submission, quote and audit models are scaffolded.
- The carrier directory seed includes the requested five integration targets plus one clearly labeled demo market.
- Only the demo market has an adapter. The requested commercial insurers remain planned until their current integration requirements and authorizations are confirmed.
- The demo adapter intentionally does not fabricate a premium or quote.
- Authentication screens, agency onboarding, authorization policies, operational CRUD screens, carrier API adapters, document handling, tests and production deployment remain to be implemented.

## Validation

Run bin/rails db:prepare and bundle exec rspec after dependencies are installed. This repository has not yet been built or test-run in a provisioned Ruby/PostgreSQL environment.
