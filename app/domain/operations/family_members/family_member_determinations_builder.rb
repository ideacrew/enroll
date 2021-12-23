# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module FamilyMembers
    # Build Family Member Determination
    class FamilyMemberDeterminationsBuilder
      send(:include, Dry::Monads[:result, :do])

      def call(params)
        values = yield validate(params)
        evidences = yield build_determination(values)

        Success(evidences)
      end

      private

      def validate(params)
        errors = []
        errors << 'family member missing' unless params[:family_member]
        errors << 'application missing' unless params[:application]

        errors.empty? ? Success(params) : Failure(errors)
      end

      def eligibility_items
        [
          {
            key: 'aptc_csr_credit',
            evidence_items: [
              {
                key: :income_evidence,
                subject_ref: 'gid://enroll_app/Family::FamilyMember',
                evidence_ref: 'gid://enroll_app/FinancialAssitance::Application'
              },
              {
                key: :esi_evidence,
                subject_ref: 'gid://enroll_app/Family::FamilyMember',
                evidence_ref: 'gid://enroll_app/FinancialAssitance::Application'
              },
              {
                key: :non_esi_evidence,
                subject_ref: 'gid://enroll_app/Family::FamilyMember',
                evidence_ref: 'gid://enroll_app/FinancialAssitance::Application'
              },
              {
                key: :local_mec_evidence,
                subject_ref: 'gid://enroll_app/Family::FamilyMember',
                evidence_ref: 'gid://enroll_app/FinancialAssitance::Application'
              }
            ]
          }
        ]
      end

      def build_determination(values)
        output = {}
        determinations =
          construct_determinations(values[:family_member], values[:application])

        if determinations.success?
          output[values[:family_member].to_global_id.uri] = {
            determinations: determinations.success
          }

          Success(output)
        else
          determinations
        end
      end

      def construct_determinations(family_member, application)
        determinations = {}
        eligibility_items.each do |eligibility_item|
          result =
            if eligibility_item[:key] == 'aptc_csr_credit'
              Operations::FinancialAssistance::CreateAptcCsrDetermination.new
                                                                         .call(
                                                                           family_member: family_member,
                                                                           eligibility_item: eligibility_item,
                                                                           application: application
                                                                         )
            end
          return result unless result.success?
          determinations.merge! result.success
        end

        Success(determinations)
      end
    end
  end
end
