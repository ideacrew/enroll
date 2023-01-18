# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module EdiGateway
    # Publish event to generate bulk 1095a notices
    class TriggerBulkTax1095aNotices
      include Dry::Monads[:result, :do, :try]
      include EventSource::Command

      TAX_FORM_TYPES = %w[IVL_TAX Corrected_IVL_TAX IVL_VTA IVL_CAP].freeze

      MAP_FORM_TYPE_TO_EVENT = { "IVL_TAX" => "initial_notice_requested",
                                 "IVL_VTA" => "void_notice_requested",
                                 "Corrected_IVL_TAX" => "corrected_notice_requested",
                                 "IVL_CAP" => "catastrophic_notice_requested" }.freeze

      # params {tax_year: ,tax_form_type: }
      def call(params)
        tax_year, tax_form_type = yield validate(params)
        result = yield publish(tax_year, tax_form_type)

        Success(result)
      end

      private

      def validate(params)
        tax_form_type = params[:tax_form_type]
        tax_year = params[:tax_year]
        return Failure("Valid tax form type is not present") unless TAX_FORM_TYPES.include?(tax_form_type)
        return Failure("tax_year is not present") unless tax_year.present?

        Success([tax_year, tax_form_type])
      end

      def publish(tax_year, tax_form_type)
        event_name = MAP_FORM_TYPE_TO_EVENT[tax_form_type]
        event_key = "families.notices.ivl_tax1095a.#{event_name}"
        event = event("events.#{event_key}", attributes: {tax_year: tax_year, tax_form_type: tax_form_type}).success
        event.publish
        Success("Successfully published bulk event")
      end
    end
  end
end
