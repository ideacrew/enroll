# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module Application
      # This class will query the application by given HBX ID
      # Syntax: FinancialAssistance::Operations::Application::FindByHbxId::new.call("123456")
      class FindByHbxId
        send(:include, Dry::Monads[:result, :do])

        def call(application_hbx_id:)
          value = yield validate(application_hbx_id)
          result = yield fetch_app(value)

          Success(result)
        end

        private

        def validate(application_hbx_id)
          return Failure('Missing application hbx_id key') unless application_hbx_id.present?

          Success(application_hbx_id)
        end

        def find(value)
          applications = ::FinancialAssistance::Application.by_hbx_id(value)
          if applications.count == 1
            Success(applications.first)
          else
            Failure("Found #{applications.count} applications with given hbx_id: #{application_entity.hbx_id}")
          end
        end
      end
    end
  end
end