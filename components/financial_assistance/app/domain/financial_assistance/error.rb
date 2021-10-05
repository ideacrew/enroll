# frozen_string_literal: true

module FinancialAssistance
  module Error
    # @api private
    module ErrorInitializer
      attr_reader :original

      def initialize(msg, original = $ERROR_INFO)
        super(msg)
        @original = original
      end
    end

    # @api public
    class Error < StandardError
      include ErrorInitializer
    end

    NoMagiMedicaidEngine = Class.new(Error)
  end
end