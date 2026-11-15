# Deployment plan

## Current state

The repository is not yet deployed as an InsurrBrdge service. The Render workspace currently has no InsurrBrdge web service or database. Do not deploy with a Render Free Postgres database as the permanent database.

## Low-cost demo architecture

- Render Free Web Service for the Rails app.
- Neon Free Postgres for application and Solid Queue tables, supplied as DATABASE_URL.
- Solid Queue may run through the Puma plugin in a single small service by setting SOLID_QUEUE_IN_PUMA=true. This is a low-volume demo arrangement; the queue pauses when the free web service sleeps and resumes when it starts again.
- Use an external object-storage provider before enabling document uploads. The current local Active Storage path is ephemeral on Render Free.
- Configure email delivery through an HTTPS API provider before allowing public registration. Render Free web services cannot send outbound SMTP traffic on ports 25, 465 or 587.

## Free-tier limits to understand

Render Free web services spin down after 15 minutes without inbound traffic and lose local filesystem changes on restart, redeploy or spin-down. Render Free Postgres expires after 30 days and has no backups. Render documents that other service types do not support Free instances; a dedicated worker requires a paid compute plan. See [Render's Free deployment limits](https://render.com/docs/free).

Neon Free includes 1 GB Postgres storage per project, 100 compute-unit hours per month and 5 GB public network transfer. Compute scales to zero after five minutes and suspends when the monthly quota is exhausted, but stored data remains. See [Neon's Free plan limits](https://neon.com/docs/introduction/plans) and [free-plan quotas](https://neon.com/docs/introduction/limits).

These limits make the proposed setup suitable for a demo or early MVP, not production availability guarantees. For production, use an always-on web service, a dedicated worker, backups/restore testing, managed object storage and monitored database capacity.

## Required environment

- RAILS_ENV=production
- SECRET_KEY_BASE (generate once and keep stable; protect it because Rails encryption keys derive from it)
- DATABASE_URL (Neon pooled connection string for the app; confirm provider guidance for the Solid Queue workload)
- APP_HOST (the deployed hostname, without protocol)
- RAILS_SERVE_STATIC_FILES=true
- SOLID_QUEUE_IN_PUMA=true only when using the single-service Puma plugin arrangement
- MAILER_FROM and an HTTPS email-provider API key after an API delivery adapter is configured
- COVERFORCE_ENV=sandbox and sandbox credentials only after CoverForce issues credentials and approves the integration

Never place credentials in GitHub source, README files or client-side code. Do not enable production carrier credentials until the agency's appointments, product/state authority and provider agreement are confirmed.

## Release checklist

1. Create the Neon database and store its connection string as DATABASE_URL in Render.
2. Configure SECRET_KEY_BASE and APP_HOST in Render.
3. Confirm database connectivity and run `bin/rails db:prepare` as a deploy pre-start command.
4. Verify the Solid Queue process is running and test a queued market submission.
5. Configure HTTPS email delivery and verify signup and password-reset messages.
6. Configure external object storage before adding document upload UI.
7. Verify health checks, logs, backups and a restore procedure.
8. Run a full smoke test with demo markets only; do not use real customer data until the production readiness review is complete.
