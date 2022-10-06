# frozen_string_literal: true

Dotenv.require_keys("CLIENT") if ['development', 'test'].include? ENV['RAILS_ENV']
