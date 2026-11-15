# Puma configuration. Solid Queue can share this process for small deployments.
threads_count = ENV.fetch("RAILS_MAX_THREADS", 5).to_i
threads threads_count, threads_count

workers ENV.fetch("WEB_CONCURRENCY", 0).to_i
preload_app!

port ENV.fetch("PORT", 3000)
environment ENV.fetch("RAILS_ENV", "development")
pidfile ENV["PIDFILE"] if ENV["PIDFILE"]

if ENV["SOLID_QUEUE_IN_PUMA"]
  plugin :solid_queue
  solid_queue_mode :async
end

plugin :tmp_restart
