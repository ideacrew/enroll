# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Configure Rails to filter out sensitive parameters from the logs.
# The parameters :password, :question_answer, :password_confirmation, :new_password, and :ssn will be replaced with [FILTERED] in the logs.
Rails.application.config.filter_parameters += [
  :password, :question_answer, :password_confirmation, :new_password, :passw, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn
]
