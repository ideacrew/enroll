# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module People
    # Class for updating due date on VLP Documents
    class UpdateDueDateOnVlpDocuments
      include Dry::Monads[:result, :do]

        # @param [Hash] opts Options to update due date on vlp documents
        # @option opts [date] :due_date required
        # @option opts [Family] :family required
        # @return [Dry::Monad] result

      def call(params)
        values = yield validate(params)
        result = yield update_due_date(values[:family], values[:due_date])

        Success(result)
      end

      private

      def validate(params)
        errors = []
        errors << 'due date missing' unless params[:due_date]
        errors << 'family missing' unless params[:family]

        errors.empty? ? Success(params) : Failure(errors)
      end

      def update_due_date(family, due_date)
        family.contingent_enrolled_active_family_members.each do |family_member|
          family_member.person.verification_types.active.each do |verification_type|
            verification_type.update_attributes!(due_date: due_date, due_date_type: 'notice') if can_update_due_date?(verification_type)
          end
        end
        Success(true)
      end

      def can_update_due_date?(verification_type)
        ::VerificationType::DUE_DATE_STATES.include?(verification_type.validation_status) && verification_type.due_date.nil?
      end
    end
  end
end
