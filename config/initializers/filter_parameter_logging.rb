Rails.application.config.filter_parameters += %i[
  password
  password_confirmation
  authorization
  access_token
  refresh_token
  api_key
  client_secret
  secret
  ssn
  tax_id
  bank_account
]
