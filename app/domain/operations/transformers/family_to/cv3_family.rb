# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'aca_entities/magi_medicaid/libraries/iap_library'

module Operations
  module Transformers
    module FamilyTo
      # Person params to be transformed.
      class Cv3Family
        # constructs cv3 payload for medicaid gateway.

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
            hbx_id: family.primary_applicant.hbx_id,  # TODO: Need to change witth family hbx_id once hbx_id added to family
            # foreign_keys TO DO
            family_members: transform_family_members(family.family_members),
            # households: transform_households(family.households), TO DO
            # irs_groups
            # magi_medicaid_applications ?
            renewal_consent_through_year: family.renewal_consent_through_year,
            # special_enrollment_periods = transform_special_enrollment_periods(family.special_enrollment_periods),
            # general_agency_accounts
            # broker_accounts
            payment_transactions: transform_payment_transactions(family.payment_transactions),
            documents: transform_documents(person.documents),
            # updated_by
            timestamp: {created_at: family.created_at.to_datetime, modified_at: family.updated_at.to_datetime}
          }

          Success(payload)
        end

        def transform_special_enrollment_periods(special_enrollment_periods)
          special_enrollment_periods.collect do |period|
            {
              #qualifying_life_event_kind_reference: construct_qle_reference(period.qualifying_life_event_kind_reference)TO DO,
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
          {

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

        def transform_households(households)
          households.collect do |household|
            start_date: household.start_date,
            end_date: household.end_date,
            is_active: household.is_active,
            irs_group: {
              hbx_id: household.irs_group.hbx_assigned_id,
              start_on: household.irs_group.effective_starting_on,
              end_on: household.irs_group.effective_ending_on,
              is_active: household.irs_group.is_active
            },
            #tax_households: tax_households,
            #coverage_households: coverage_households,
            #hbx_enrollments: hbx_enrollments
          end
        end

        def tax_households(households)
          households.collect do |household|
            hbx_id: household.hbx_assigned_id,
            allocated_aptc: household.allocated_aptc,
            is_eligibility_determined: household.is_eligibility_determined,
            effective_starting_on: household.start_date,
            effective_ending_on: household.end_date,
            # tax_household_members: transform_tax_household_members(household.tax_household_members),
            # eligibility_determinations: transform_eligibility_determininations(household.eligibility_determinations)
          end
        end

        def transform_eligibility_determininations(determinations)
          determinations.collect do |determination|

          end
        end

        def transform_tax_household_members(members)
          members.collect do |member|
            # family_member_reference: member.family_member_id,
            # product_eligibility_determination: member.product_eligibility_determination,
            is_subscriber: member.is_subscriber,
            reason: member.reason
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
              #magi_medicaid_application_applicants: transform_applicants(member.magi_medicaid_application_applicants),
              person: transform_person(member.person),
              timestamp: {created_at: member.created_at.to_datetime, modified_at: member.updated_at.to_datetime}
            }
          end
        end

        def transform_person(person)
          # TODO find person first, then transform
          Operations::Transformers::PersonTo::Cv3Person.new.call(person).value!
        end
      end
    end
  end
end