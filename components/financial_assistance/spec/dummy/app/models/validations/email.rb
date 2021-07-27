# frozen_string_literal: true

require 'mail'

module Validations
  module Email
    class EmailValidator < ActiveModel::EachValidator
      def validate_each(record, attribute, value)
        begin
          parsed = Mail::Address.new(value)
        record.errors.add attribute, "is not valid" unless !parsed.nil? && parsed.address == value && parsed.local != value #cannot be a local address
      end
    end
  end
end
