# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module FinancialAssistance
    # FindFamilyMember
    class CreateAptcCsrDetermination
      send(:include, Dry::Monads[:result, :do])

      def call(params)
        values = yield validate(params)
        visitor = yield application_visitor(values)
        evidences = yield find_evidences(values[:application], visitor)
        determination = yield create_determination(values[:application], evidences)
        # yield validate_determination(determination)

        Success(determination)
      end

      private

      def validate(params)
        errors = []
        errors << 'family member missing' unless params[:family_member]
        errors << 'eligibility item missing' unless params[:eligibility_item]
        errors << 'application missing' unless params[:application]

        errors.empty? ? Success(params) : Failure(errors)
      end

      def application_visitor(values)
        visitor = Eligibilities::Visitors::AptcCsrVisitor.new
        visitor.family_member = values[:family_member]
        visitor.evidence_items = values[:eligibility_item][:evidence_items]

        Success(visitor)
      end

      def find_application(values)
        family = values[:family_member].family
        application =
          ::FinancialAssistance::Application.where(
            family_id: family.id,
            aasm_state: :determined
          ).last

        if application
          Success(application)
        else
          Failure('unable to find FAA application')
        end
      end

      def find_evidences(application, visitor)
        application.accept(visitor)

        Success(visitor.evidences)
      end

      def create_determination(application, evidences)
        determination =
          Hash[
            :aptc_csr_credit,
            {
              status: 'eligible',
              determined_at: DateTime.now,
              earliest_due_date: Date.today + 1.day,
              evidence_states: evidences
            }
          ]

        Success(determination)
      end

      def validate_determination(determination)
        binding.irb
        result = AcaEntities::Eligibilities::Contracts::DeterminationContract.new.call(determinations: determination)
      end

      def create
      end
    end
  end
end
