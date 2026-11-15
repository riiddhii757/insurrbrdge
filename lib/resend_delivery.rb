require "base64"
require "json"
require "net/http"
require "uri"

class ResendDelivery
  class DeliveryError < StandardError; end

  ENDPOINT = URI("https://api.resend.com/emails")

  def initialize(settings = {})
    @settings = settings
  end

  def deliver!(mail)
    api_key = @settings[:api_key].presence || ENV["RESEND_API_KEY"]
    raise DeliveryError, "RESEND_API_KEY is not configured" if api_key.blank?
    raise DeliveryError, "Email requires a from address and at least one recipient" if mail[:from].blank? || Array(mail.to).blank?

    request = Net::HTTP::Post.new(ENDPOINT)
    request["Authorization"] = "Bearer #{api_key}"
    request["Content-Type"] = "application/json"
    request["Accept"] = "application/json"
    request.body = JSON.generate(payload_for(mail))

    response = Net::HTTP.start(
      ENDPOINT.host, ENDPOINT.port,
      use_ssl: true, open_timeout: 5, read_timeout: 15
    ) { |http| http.request(request) }

    unless response.is_a?(Net::HTTPSuccess)
      raise DeliveryError, "Resend email request failed (HTTP #{response.code})"
    end

    response
  rescue Net::OpenTimeout, Net::ReadTimeout, SocketError, Errno::ECONNREFUSED => error
    raise DeliveryError, "Resend email request failed (#{error.class})"
  end

  private

  def payload_for(mail)
    payload = {
      from: Array(mail[:from].formatted).join(", "),
      to: Array(mail.to),
      subject: mail.subject
    }
    payload[:cc] = Array(mail.cc) if mail.cc.present?
    payload[:bcc] = Array(mail.bcc) if mail.bcc.present?
    payload[:reply_to] = Array(mail.reply_to) if mail.reply_to.present?

    if mail.multipart?
      payload[:html] = mail.html_part.body.decoded if mail.html_part
      payload[:text] = mail.text_part.body.decoded if mail.text_part
    elsif mail.content_type.to_s.include?("text/html")
      payload[:html] = mail.body.decoded
    else
      payload[:text] = mail.body.decoded
    end

    if mail.attachments.any?
      payload[:attachments] = mail.attachments.map do |attachment|
        {
          filename: attachment.filename,
          content: Base64.strict_encode64(attachment.body.decoded)
        }
      end
    end

    payload
  end
end
