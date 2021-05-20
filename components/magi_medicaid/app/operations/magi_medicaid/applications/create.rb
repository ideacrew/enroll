# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module MagiMedicaid
  module Applications
    # Operation to create application in magi medicaid.
    class Create
      send(:include, Dry::Monads[:result, :do])

      def call(params:)
        values = yield validate(params)
        result = yield create(values)

        Success(result)
      end

      private

      def validate(params)
        result = ::MagiMedicaid::ApplicationContract.new.call(params)

        if result.success?
          Success(result.to_h)
        else
          Failure(result)
        end
      end

      def create(values)
        application = ::MagiMedicaid::Application.new(values.except(:applicants))

        applicants_results = values[:applicants].map do |applicant|
          ::MagiMedicaid::Applicants::Build.new.call(params: applicant.merge(application: application))
        end

        applicants_results.map do |result|
          if result.success?
            applicant = application.applicants.build
            applicant.assign_attributes(result.success.to_h)
          else
            result.failure
          end
        end

        if application.save
          Success(application.id)
        else
          Failure(application.errors)
        end
      end
    end
  end
end