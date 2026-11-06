require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = ENV["CI"].present?
  config.consider_all_requests_local = true
  config.action_controller.perform_caching = false
  # Request specs exercise controller behavior without browser-issued CSRF tokens.
  # Forgery protection remains enabled in development and production.
  config.action_controller.allow_forgery_protection = false
  config.cache_store = :null_store
  config.active_storage.service = :test
  config.action_mailer.delivery_method = :test
  config.action_mailer.perform_caching = false
  config.active_support.deprecation = :stderr
  config.active_support.disallowed_deprecation = :raise
  config.active_record.maintain_test_schema = true
end
