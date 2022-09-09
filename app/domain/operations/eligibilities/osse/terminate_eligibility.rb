# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Eligibilities
    module Osse
      # Terminate eligibility for the subject with given eligibility and termination date
      class TerminateEligibility
        send(:include, Dry::Monads[:result, :do])

        # @param [Hash] opts Options to build eligibility
        # @option opts [<GlobalID>] :subject_gid required
        # @option opts [<String>]   :evidence_key required
        # @option opts [Date]       :termination_date required
        # @return [Dry::Monad] result
        def call(params)
          values = yield validate(params)
          output = yield terminate(values)

          Success(output)
        end

        private

        def validate(params)
          errors = []
          errors << 'subject global id missing' unless params[:subject_gid]
          errors << 'evidence key missing' unless params[:evidence_key]
          errors << 'termination date missing' unless params[:termination_date]

          errors.empty? ? Success(params) : Failure(errors)
        end

        def terminate(values)
          subject_instance = GlobalID::Locator.locate(values[:subject_gid])
          termination_date = values[:termination_date].to_date
          evidence_key = values[:evidence_key]

          eligibilities = subject_instance.eligibilities.where(:'evidences.key' => evidence_key)
          eligibilities.each do |eligibility|
            evidence = eligibility.evidences.by_key(evidence_key).last
            next unless evidence

            eligibility.end_on = termination_date if update_end_on?(eligibility, termination_date)
            evidence.is_satisfied = false
            evidence.save! if evidence.changed?
            eligibility.save! if eligibility.changed?
          end
          Success('Eligibilities have been terminated')
        end

        def update_end_on?(eligibility, termination_date)
          eligibility.end_on.nil? || (eligibility.end_on.present? && eligibility.end_on > termination_date)
        end
      end
    end
  end
end
