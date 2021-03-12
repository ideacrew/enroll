# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module Application
      class FindDraft
        include Dry::Monads[:result, :do]

        def call(params:)
          values = yield validate(params)
          result = yield find_draft(values)

          Success(result)
        end

        private

        def validate(params)
          return Failure('Missing key') unless params.key?(:family_id)
          Success(params)
        end

        def find_draft(values)
          application = ::FinancialAssistance::Application.where(family_id: values[:family_id], aasm_state: 'draft').first
          application ? Success(application) : Failure('No matching draft application')
        end
      end
    end
  end
end