# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module Application
      class FindDraft
        include Dry::Monads[:do, :result]

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
          draft_application = ::FinancialAssistance::Application.where(aasm_state: 'draft', family_id: values[:family_id]).asc(:created_at).last
          draft_application ? Success(draft_application) : Failure('No matching draft application')
        end
      end
    end
  end
end
