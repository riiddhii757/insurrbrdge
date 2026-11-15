require Rails.root.join("lib/resend_delivery")
ActionMailer::Base.add_delivery_method :resend, ResendDelivery
