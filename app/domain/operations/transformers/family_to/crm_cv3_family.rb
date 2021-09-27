# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'aca_entities/magi_medicaid/libraries/iap_library'

module Operations
  module Transformers
    module FamilyTo
      # Family params to be transformed.
      class CrmCv3Family
        # Constructs cv3 payload including family and FA Application

        include Dry::Monads[:result, :do]
        include Acapi::Notifiers
        require 'securerandom'

        def call(family)
          request_payload = yield construct_payload(family)

          Success(request_payload)
        end

        private

        def construct_payload(family)
          payload = {
            hbx_id: family.hbx_assigned_id.to_s,
            family_members: transform_family_members(family.family_members),
            renewal_consent_through_year: family.renewal_consent_through_year,
            payment_transactions: transform_payment_transactions(family.payment_transactions),
            documents: transform_documents(family.documents),
            timestamp: {created_at: family.created_at.to_datetime, modified_at: family.updated_at.to_datetime} # ,
          }
          payload.merge!(irs_groups: transform_irs_groups(family.irs_groups)) if family.irs_groups.present?
          Success(payload)
        end

        def transform_payment_transactions(payment_transactions)
          payment_transactions.collect do |transaction|
            {
              enrollment_id: transaction.enrollment_id,
              carrier_id: transaction.carrier_id,
              enrollment_effective_date: transaction.enrollment_effective_date,
              payment_transaction_id: transaction.payment_transaction_id,
              status: transaction.status
            }
          end
        end

        def transform_documents(documents)
          documents.collect do |document|
            {
              title: document.title,
              creator: document.creator,
              subject: document.subject,
              description: document.description,
              publisher: document.publisher,
              contributor: document.contributor,
              date: document.date,
              type: document.type,
              format: document.format,
              identifier: document.identifier,
              source: document.source,
              language: document.language,
              relation: document.relation,
              coverage: document.coverage,
              rights: document.rights,
              tags: document.tags,
              size: document.size,
              doc_identifier: document.doc_identifier
            }
          end
        end

        def transform_irs_groups(irs_groups)
          irs_groups.collect do |irs_group|
            construct_irs_group(irs_group)
          end
        end

        def construct_irs_group(irs_group)
          return if irs_group.nil?
          {
            hbx_id: irs_group.hbx_assigned_id.to_s,
            start_on: irs_group.effective_starting_on,
            end_on: irs_group.effective_ending_on,
            is_active: irs_group.is_active
          }
        end

        def transform_eligibility_determininations(determinations)
          determinations.collect do |determination|
            {
              e_pdc_id: determination.e_pdc_id,
              # benchmark_plan: determination.benchmark_plan,
              max_aptc: determination.max_aptc.to_hash,
              premium_credit_strategy_kind: determination.premium_credit_strategy_kind,
              csr_percent_as_integer: determination.csr_percent_as_integer,
              csr_eligibility_kind: determination.csr_eligibility_kind,
              aptc_csr_annual_household_income: determination.aptc_csr_annual_household_income.to_hash,
              aptc_annual_income_limit: determination.aptc_annual_income_limit.to_hash,
              csr_annual_income_limit: determination.csr_annual_income_limit.to_hash,
              determined_at: determination.determined_at,
              source: determination.source
            }
          end
        end

        def transform_coverage_household_members(members)
          members.collect do |member|
            {
              family_member_reference: transform_family_member_reference(member),
              is_subscriber: member.is_subscriber
            }
          end
        end

        def transform_family_member_reference(member)
          {
            family_member_hbx_id: member.family_member.person.hbx_id.to_s,
            first_name: member.family_member.person.first_name,
            last_name: member.family_member.person.last_name,
            is_primary_family_member: member.family_member.is_primary_applicant,
            age: member.family_member.person.age_on(TimeKeeper.date_of_record)
          }
        end

        def transform_tax_household_members(members)
          members.collect do |member|
            {
              family_member_reference: transform_family_member_reference(member),
              # product_eligibility_determination: member.product_eligibility_determination,
              is_subscriber: member.is_subscriber,
              reason: member.reason
            }
          end
        end

        def transform_family_members(family_members)
          family_members.collect do |member|
            {
              hbx_id: member.hbx_id.to_s,
              is_primary_applicant: member.is_primary_applicant,
              # foreign_keys
              is_consent_applicant: member.is_consent_applicant,
              is_coverage_applicant: member.is_coverage_applicant,
              is_active: member.is_active,
              # magi_medicaid_application_applicants: transform_applicants(member.magi_medicaid_application_applicants),
              person: transform_person(member.person),
              timestamp: {created_at: member.created_at.to_datetime, modified_at: member.updated_at.to_datetime}
            }
          end
        end

        def construct_updated_by(updated_by)
          # To do
        end

        def transform_person(person)
          Operations::Transformers::PersonTo::Cv3Person.new.call(person).value!
        end
      end
    end
  end
end
