require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = ENV["CI"].present?
  config.consider_all_requests_local = true
  config.action_controller.perform_caching = false
  # Request specs exercise controller behavior without browser-issued CSRF tokens.
  # Forgery protection remains enabled in development and production.
  config.action_controller.allow_forgery_protection = false
  # Jobs are asserted or performed explicitly in tests; no queue database is required.
  config.active_job.queue_adapter = :test
  config.cache_store = :null_store
  config.active_storage.service = :test
  config.action_mailer.delivery_method = :test
  config.action_mailer.perform_caching = false
  # Mailers generate absolute links; use a deterministic host in request specs.
  config.action_mailer.default_url_options = { host: "www.example.com", protocol: "http" }
  config.active_support.deprecation = :stderr
  config.active_support.disallowed_deprecation = :raise
  config.active_record.maintain_test_schema = true
end
