# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'aca_entities/magi_medicaid/libraries/iap_library'

module Operations
  module Transformers
    module FamilyTo
      # Family params to be transformed.
      class Cv3Family
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
            hbx_id: family.id,
            family_members: transform_family_members(family.family_members),
            households: transform_households(family.households), # TO DO
            irs_groups: transform_irs_groups(family.irs_groups),
            renewal_consent_through_year: family.renewal_consent_through_year,
            special_enrollment_periods: transform_special_enrollment_periods(family.special_enrollment_periods),
            payment_transactions: transform_payment_transactions(family.payment_transactions),
            magi_medicaid_applications: transform_applications(family.id),
            documents: transform_documents(family.documents),
            timestamp: {created_at: family.created_at.to_datetime, modified_at: family.updated_at.to_datetime} # ,
            # foreign_keys TO DO ??
            # general_agency_accounts = transform_general_agency_accounts(family.general_agency_accounts), #TO DO
            # broker_accounts = transform_broker_accounts(family.broker_accounts), #TO DO
            # updated_by: construct_updated_by(updated_by)
          }
          Success(payload)
        end

        def transform_applications(primary_id)
          return unless EnrollRegistry.feature_enabled?(:financial_assistance)
          applications = ::FinancialAssistance::Application.where(family_id: primary_id).where(aasm_state: 'submitted')
          applications.collect do |application|
            ::FinancialAssistance::Operations::Applications::Transformers::ApplicationTo::Cv3Application.new.call(application).value!
          end
        end

        def transform_special_enrollment_periods(special_enrollment_periods)
          special_enrollment_periods.collect do |period|
            {
              qualifying_life_event_kind_reference: construct_qle_reference(period.qualifying_life_event_kind),
              qle_on: period.qle_on,
              start_on: period.start_on,
              end_on: period.end_on,
              effective_on_kind: period.effective_on_kind,
              submitted_at: period.submitted_at,
              effective_on: period.effective_on,
              is_valid: period.is_valid,
              title: period.title,
              qle_answer: period.qle_answer,
              next_poss_effective_date: period.next_poss_effective_date,
              option1_date: period.option1_date,
              option2_date: period.option2_date,
              option3_date: period.option3_date,
              optional_effective_on: period.optional_effective_on,
              csl_num: period.csl_num,
              market_kind: period.market_kind,
              admin_flag: period.admin_flag,
              timestamp: {created_at: period.created_at.to_datetime, modified_at: period.updated_at.to_datetime}
            }
          end
        end

        def construct_qle_reference(reference)
          return if reference.nil?
          {
            start_on: reference.start_on,
            end_on: reference.end_on,
            title: reference.title,
            reason: reference.reason,
            market_kind: reference.market_kind
          }
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

        def transform_general_agency_accounts(general_agency_accounts)
          general_agency_accounts.collect do |account|
            {
              start_on: account.start_on,
              end_on: account.end_on,
              is_active: account.aasm_state == "active",
              aasm_state: account.aasm_state
              # general_agency_reference: construct_general_agency_reference(account.general_agency_reference),
              # broker_role_reference: account.broker_role_reference,
              # updated_by
            }
          end
        end

        def construct_general_agency_reference(general_agency_reference)
          # { agency: general_agency_reference.broker_agency_profile }
        end

        def transform_broker_accounts(broker_accounts)
          broker_accounts.collect do |account|
            {
              start_on: account.start_on,
              end_on: account.end_on,
              is_active: account.aasm_state == "active",
              aasm_state: account.aasm_state
              # general_agency_reference: account.general_agency_reference,
              # broker_role_reference: account.broker_role_reference,
              # updated_by: account.updated_by
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
            hbx_id: irs_group.hbx_assigned_id,
            start_on: irs_group.effective_starting_on,
            end_on: irs_group.effective_ending_on,
            is_active: irs_group.is_active
          }
        end

        def transform_households(households)
          households.collect do |household|
            {
              start_date: household.effective_starting_on,
              end_date: household.effective_ending_on,
              is_active: household.is_active,
              irs_groups: construct_irs_group(household.irs_group),
              tax_households: transform_tax_households(household.tax_households), # TO DO
              coverage_households: transform_coverage_households(household.coverage_households) # TO DO
              # hbx_enrollments: hbx_enrollments
            }
          end
        end

        def transform_coverage_households(households)
          households.collect do |household|
            {
              is_immediate_family: household.is_immediate_family,
              is_determination_split_household: household.is_determination_split_household,
              submitted_at: household.submitted_at,
              aasm_state: household.aasm_state
              # coverage_household_members: household.coverage_household_members,
              # broker_agency_reference: household.broker_agency_reference,
              # broker_role_reference: household.broker_role_reference
            }
          end
        end

        def transform_tax_households(households)
          households.collect do |household|
            {
              hbx_id: household.hbx_assigned_id,
              allocated_aptc: household.allocated_aptc,
              is_eligibility_determined: household.is_eligibility_determined,
              effective_starting_on: household.start_date,
              effective_ending_on: household.end_date,
              tax_household_members: transform_tax_household_members(household.tax_household_members),
              eligibility_determinations: transform_eligibility_determininations(household.eligibility_determinations)
            }
          end
        end

        def transform_eligibility_determininations(determinations)
          determinations.collect do |determination|
            {
              e_pdc_id: determination.e_pdc_id,
              # benchmark_plan: determination.benchmark_plan,
              max_aptc: determination.max_aptc,
              premium_credit_strategy_kind: determination.premium_credit_strategy_kind,
              csr_percent_as_integer: determination.csr_percent_as_integer,
              csr_eligibility_kind: determination.csr_eligibility_kind,
              aptc_csr_annual_household_income: determination.aptc_csr_annual_household_income,
              aptc_annual_income_limit: determination.aptc_annual_income_limit,
              csr_annual_income_limit: determination.csr_annual_income_limit,
              determined_at: determination.determined_at,
              source: determination.source
            }
          end
        end

        def transform_tax_household_members(members)
          members.collect do |member|
            {
              family_member_reference: member.family_member_id,
              # product_eligibility_determination: member.product_eligibility_determination,
              is_subscriber: member.is_subscriber,
              reason: member.reason
            }
          end
        end

        def transform_family_members(family_members)
          family_members.collect do |member|
            {
              hbx_id: member.hbx_id,
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