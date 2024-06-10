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

        # rubocop:disable Style/OptionalBooleanParameter
        # !!!Important!!!
        # Args param is a temporary solution and currently accepts attribute (exclude_seps)in cv3_hbx_enrollment - developed for Pivotal-184575110,
        # **Do not pass in args(exclude_seps) elsewhere unless approved from Dan/leadership team**
        # !!!Important!!!
        def call(family, exclude_applications = false, *args)
          options = args.first || {}
          @transformed_family_members = yield transform_family_members(family.family_members)
          @transformed_applications = yield transform_applications(family, exclude_applications)
          @transformed_households = yield transform_households(family.households, options)
          request_payload = yield construct_payload(family, exclude_applications, args)

          Success(request_payload)
        end
        # rubocop:enable Style/OptionalBooleanParameter

        private

        def construct_payload(family, exclude_applications, args)
          @family_hbx_id = family.hbx_assigned_id.to_s
          payload = {
            hbx_id: @family_hbx_id,
            family_members: @transformed_family_members,
            renewal_consent_through_year: family.renewal_consent_through_year,
            special_enrollment_periods: transform_special_enrollment_periods(family.special_enrollment_periods),
            payment_transactions: transform_payment_transactions(family.payment_transactions),
            magi_medicaid_applications: @transformed_applications,
            documents: transform_documents(family.documents),
            timestamp: {created_at: family.created_at.to_datetime, modified_at: family.updated_at.to_datetime}
            # foreign_keys TO DO ??
            # general_agency_accounts = transform_general_agency_accounts(family.general_agency_accounts), #TO DO
            # broker_accounts = transform_broker_accounts(family.broker_accounts), #TO DO
            # updated_by: construct_updated_by(updated_by)
          }
          payload.merge!(eligibility_determination: transform_eligibility_determinination(family)) if family.eligibility_determination.present?
          payload.merge!(min_verification_due_date: family.min_verification_due_date) if family.min_verification_due_date.present?
          payload.merge!(irs_groups: transform_irs_groups(family.irs_groups)) if family.irs_groups.present?
          payload.merge!(households: @transformed_households) if @transformed_households.present?
          payload.merge!(tax_household_groups: transform_tax_household_groups(family.tax_household_groups)) if family.tax_household_groups.present?

          Success(payload)
        end

        def transform_eligibility_determinination(family)
          return {} if family.eligibility_determination.nil?
          family.eligibility_determination.serializable_cv_hash
        end

        def transform_applications(family, exclude_applications)
          return Success(nil) unless EnrollRegistry.feature_enabled?(:financial_assistance)
          return Success([]) if exclude_applications

          applications = ::FinancialAssistance::Application.where(family_id: family.id).determined
          transformed_applications = applications.collect do |application|
            ::FinancialAssistance::Operations::Applications::Transformers::ApplicationTo::Cv3Application.new.call(application)
          end.compact
          return Failure("Could not transform applications for family with hbx_id #{family.hbx_assigned_id}: #{transformed_applications.select(&:failure?).map(&:failure)}") unless transformed_applications.all?(&:success?)
          Success(transformed_applications.map(&:value!))
        end

        def transform_special_enrollment_periods(special_enrollment_periods)
          special_enrollment_periods.collect do |period|
            sep_hash = {
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
              optional_effective_on: period.optional_effective_on,
              csl_num: period.csl_num,
              market_kind: period.market_kind,
              admin_flag: period.admin_flag,
              timestamp: {created_at: period.created_at.to_datetime, modified_at: period.updated_at.to_datetime}
            }
            sep_hash.merge!(next_poss_effective_date: period.next_poss_effective_date) if period.next_poss_effective_date.present?
            sep_hash.merge!(option1_date: period.option1_date) if period.option1_date.present?
            sep_hash.merge!(option2_date: period.option2_date) if period.option2_date.present?
            sep_hash.merge!(option3_date: period.option3_date) if period.option3_date.present?
            sep_hash
          end
        end

        def construct_qle_reference(reference)
          return if reference.nil?

          qle_hash = {
            start_on: reference.start_on,
            title: reference.title,
            reason: reference.reason,
            market_kind: reference.market_kind
          }
          qle_hash.merge!(end_on: reference.end_on) if reference.end_on.present?
          qle_hash
        end

        def transform_payment_transactions(payment_transactions)
          payment_transactions.collect do |transaction|
            {
              enrollment_id: transaction.enrollment_id.to_s,
              carrier_id: transaction.carrier_id.to_s,
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
            hbx_id: irs_group.hbx_assigned_id.to_s,
            start_on: irs_group.effective_starting_on,
            end_on: irs_group.effective_ending_on,
            is_active: irs_group.is_active
          }
        end

        def transform_households(households, options)
          return Success([]) unless households.present?

          transformed_households = households.collect do |household|
            enrollments = household.hbx_enrollments.where(:aasm_state.ne => "shopping", :product_id.ne => nil)
            household_data = {
              start_date: household.effective_starting_on,
              end_date: household.effective_ending_on,
              is_active: household.is_active,
              irs_groups: construct_irs_group(household.family.irs_groups.last),
              tax_households: transform_tax_households(household.tax_households),
              coverage_households: transform_coverage_households(household.coverage_households)
            }
            if enrollments.present?
              transformed_enrollments = transform_hbx_enrollments(enrollments, options)
              return transformed_enrollments if transformed_enrollments.failure?

              household_data.merge!(hbx_enrollments: transformed_enrollments.value!)
            end
            household_data
          end

          Success(transformed_households)
        end

        def transform_tax_household_groups(tax_household_groups)
          tax_household_groups.collect do |th_group|
            {
              hbx_id: th_group.hbx_id,
              assistance_year: th_group.assistance_year,
              start_on: th_group.start_on,
              end_on: th_group.end_on,
              source: th_group.source,
              application_hbx_id: th_group.application_id,
              tax_households: transform_tax_households(th_group.tax_households)
            }
          end
        end

        def transform_coverage_households(households)
          households.collect do |household|
            {
              is_immediate_family: household.is_immediate_family,
              is_determination_split_household: household.is_determination_split_household,
              submitted_at: household.submitted_at,
              aasm_state: household.aasm_state,
              coverage_household_members: transform_coverage_household_members(household.coverage_household_members)
            }
          end
        end

        def transform_tax_households(households)
          households.collect do |household|
            {
              hbx_id: household.hbx_assigned_id.to_s,
              allocated_aptc: household.allocated_aptc.to_hash,
              is_eligibility_determined: household.is_eligibility_determined,
              start_date: household.effective_starting_on,
              end_date: household.effective_ending_on,
              tax_household_members: transform_tax_household_members(household),
              eligibility_determinations: transform_eligibility_determininations(household.eligibility_determinations),
              yearly_expected_contribution: household.yearly_expected_contribution&.to_hash,
              eligibility_determination_hbx_id: household.eligibility_determination_hbx_id.to_s,
              max_aptc: household.max_aptc&.to_hash
            }
          end
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
              source: determination.source.titleize
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
            age: member.family_member.person.age_on(TimeKeeper.date_of_record),
            relation_with_primary: member.family_member&.primary_relationship
          }
        end

        def transform_tax_household_members(tax_household)
          slcsp_info = fetch_slcsp_info(tax_household)
          application = latest_application_in_tax_household_year(tax_household)
          tax_household.tax_household_members.collect do |member|
            next unless member.family_member.present?

            person_hbx_id = member.family_member.person.hbx_id
            {
              family_member_reference: transform_family_member_reference(member),
              product_eligibility_determination: product_eligibility_determination_hash(member),
              is_subscriber: member.is_subscriber,
              tax_filer_status: fetch_tax_filer_status(person_hbx_id, application),
              slcsp_benchmark_premium: fetch_slcsp_benchmark_premium_for_member(person_hbx_id, slcsp_info),
              reason: member.reason
            }
          end.compact
        end

        def fetch_tax_filer_status(person_hbx_id, application)
          return unless application
          applicant = application.applicants.where(person_hbx_id: person_hbx_id).first
          return unless applicant

          applicant.tax_filer_kind
        end

        def fetch_slcsp_benchmark_premium_for_member(person_hbx_id, slcsp_info)
          return if slcsp_info == {}

          slcsp_info.dig(person_hbx_id, :health_only_slcsp_premiums, :cost)&.to_money&.to_hash
        end

        def latest_application_in_tax_household_year(tax_household)
          assistance_year = tax_household.effective_starting_on.year
          ::FinancialAssistance::Application.where(family_id: tax_household.family.id, aasm_state: "determined", assistance_year: assistance_year).max_by(&:created_at)
        end

        def fetch_slcsp_info(tax_household)
          effective_date = tax_household.effective_starting_on
          premiums = ::Operations::Products::Fetch.new.call({family: tax_household.family, effective_date: effective_date})
          return {} if premiums.failure?

          slcsp_info = ::Operations::Products::FetchSlcsp.new.call(member_silver_product_premiums: premiums.success)
          return {} if slcsp_info.failure?
          slcsp_info.success
        end

        def product_eligibility_determination_hash(member)
          {
            is_ia_eligible: member.is_ia_eligible,
            is_medicaid_chip_eligible: member.is_medicaid_chip_eligible,
            is_non_magi_medicaid_eligible: member.is_non_magi_medicaid_eligible,
            is_totally_ineligible: member.is_totally_ineligible,
            is_without_assistance: member.is_without_assistance,
            magi_medicaid_monthly_household_income: member.magi_medicaid_monthly_household_income&.to_hash,
            medicaid_household_size: member.medicaid_household_size,
            magi_medicaid_monthly_income_limit: member.magi_medicaid_monthly_income_limit&.to_hash,
            magi_as_percentage_of_fpl: member.magi_as_percentage_of_fpl,
            magi_medicaid_category: member.magi_medicaid_category,
            csr: member.csr_eligibility_kind.split('_').last
          }
        end

        def transform_family_members(family_members)
          transformed_family_members = family_members.collect do |member|
            person = transform_person(member.person)
            return person if person.failure?

            {
              hbx_id: member.hbx_id.to_s,
              is_primary_applicant: member.is_primary_applicant,
              # foreign_keys
              is_consent_applicant: member.is_consent_applicant,
              is_coverage_applicant: member.is_coverage_applicant,
              is_active: member.is_active,
              person: person.value!,
              timestamp: {created_at: member.created_at.to_datetime, modified_at: member.updated_at.to_datetime}
            }
          end
          Success(transformed_family_members)
        end

        def transform_hbx_enrollments(enrollments, options)
          transformed_enrollments = enrollments.collect do |enrollment|
            transform_hbx_enrollment(enrollment, options)
          end
          return Failure("Could not transform enrollment for family with hbx_id #{@family_hbx_id}: #{transformed_enrollments.select(&:failure?).map(&:failure)}") unless transformed_enrollments.all?(&:success?)

          Success(transformed_enrollments.map(&:value!))
        end

        def construct_updated_by(updated_by)
          # To do
        end

        def transform_hbx_enrollment(enrollment, options)
          Operations::Transformers::HbxEnrollmentTo::Cv3HbxEnrollment.new.call(enrollment, options)
        end

        def transform_person(person)
          Operations::Transformers::PersonTo::Cv3Person.new.call(person)
        end
      end
    end
  end
end