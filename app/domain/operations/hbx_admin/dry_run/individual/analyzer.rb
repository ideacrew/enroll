# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'


module Operations
  module HbxAdmin
    module DryRun
      module Individual
        # This Operation is responsible for getting the renewal dry run count for applications, notices and benefits.
      class Analyzer
        include Dry::Monads[:result, :do]

        APPLICATION_STATES = %w[
          renewal_draft submitted applicants_update_required income_verification_extension_required
          haven_magi_medicaid_eligibility_request_errored mitc_magi_medicaid_eligibility_request_errored
          submission_pending determined determination_response_error
        ].freeze

        NOTICE_TITLE_MAPPING = {
          "Open Enrollment - Medicaid" => "OEM",
          "Open Enrollment - Tax Credit" => "OEA",
          "Open Enrollment - Marketplace Insurance" => "OEU"
        }.freeze

        # @param [Hash] opts The options to fetch application status
        # @option opts [Array] :assistance_years ::Array of assistance years
        # @return [Dry::Monads::Result]
        def call
          benefit_coverage_values, coverage_years = yield fetch_benefits
          eligible_families = yield fetch_eligible_families(coverage_years[0])
          application_states = yield application_states_by_year(coverage_years)
          mapped_states = yield map_states_to_years(application_states, coverage_years)
          person_hbx_ids = yield primary_person_hbx_ids(coverage_years[0])
          oe_determined_notices = yield oe_determined_notices_count(coverage_years[0], person_hbx_ids)

          Success([eligible_families, mapped_states, benefit_coverage_values, oe_determined_notices])
        end

        private

        def fetch_benefits
          result = ::Operations::HbxAdmin::DryRun::Individual::Benefits.new.call

          if result.success?
            Success(result.value!)
          else
            Failure(["Failed in IndividualBenefits: #{result.failure}", {}])
          end
        end

        def fetch_eligible_families(renewal_year)
          family_ids = ::HbxEnrollment.individual_market.enrolled.current_year.distinct(:family_id)

          eligible_family_ids = ::FinancialAssistance::Application.by_year(renewal_year.pred).determined.where(:family_id.in => family_ids).distinct(:family_id)

          Success({"families_eligible_for_application_renewal" => eligible_family_ids.count})
        rescue StandardError => e
          Failure(["fetch_eligible_families: error: #{e.message}", {}])
        end

        def application_states_by_year(coverage_years)
          application_states = aggregate_collection(::FinancialAssistance::Application.collection, application_pipeline(coverage_years)).sort_by { |state| -state['assistance_year'] }

          if application_states.collect { |as| as["assistance_year"] }.compact.flatten.count > 0
            Success(application_states)
          else
            Failure(["application_states_by_year: Unable to query Applications count", skeleton(coverage_years)])
          end
        rescue StandardError => e
          Failure(["application_states_by_year: error: #{e.message}", skeleton(coverage_years)])
        end

        def map_states_to_years(application_states, coverage_years)
          output = application_states.each_with_object({}) do |hash, result|
            year = hash["assistance_year"]
            states = hash["application_states"]

            mapped_states = APPLICATION_STATES.each_with_object({}) do |aasm_state, state_counts|
              application_state = states.find { |state| state["aasm_state"] == aasm_state }
              state_counts[aasm_state] = application_state ? application_state["count"] : 0
            end

            result[year] = mapped_states
          end

          Success(output)
        rescue StandardError => e
          Failure(["map_states_to_years: error: #{e.message}", skeleton(coverage_years)])
        end

        def primary_person_hbx_ids(year)
          person_hbx_ids = aggregate_collection(::FinancialAssistance::Application.collection, applicant_pipeline(year)).collect { |h| h["primary_applicant_person_hbx_id"] }
          Success(person_hbx_ids)
        end

        def oe_determined_notices_count(year, person_hbx_ids)
          return Success(skeleton_for_notices) if person_hbx_ids.blank?

          notices = fetch_notices(year, person_hbx_ids)
          result = notices.count.zero? ? skeleton_for_notices : map_notices(notices)

          Success(result)
        end

        def fetch_notices(year, person_hbx_ids)
          start_date = Date.new(year, 1, 1) - 6.months
          end_date = Date.new(year, 1, 1)

          pipeline = ::Operations::HbxAdmin::DryRun::NoticeQuery.new.call(
            person_hbx_ids: person_hbx_ids,
            start_date: start_date,
            end_date: end_date,
            title_codes: NOTICE_TITLE_MAPPING.keys
          )
          aggregate_collection(Person.collection, pipeline)
        end

        def map_notices(notices)
          notices.each_with_object({}) do |notice, result|
            result[NOTICE_TITLE_MAPPING[notice["title"]]] = notice["count"]
          end
        end

        def aggregate_collection(collection, pipeline)
          collection.aggregate(pipeline).to_a
        end

        # Default Hash
        # Generates a skeleton hash for notices.
        #
        # @return [Hash] The skeleton hash for notices.
        def skeleton_for_notices
          NOTICE_TITLE_MAPPING.values.map(&:downcase).each_with_object({}) do |key, hash|
            hash[key] = 0
          end
        end

        # Default Hash
        # Generates a skeleton hash for application states by coverage years.
        #
        # @param coverage_years [Array<Integer>] The coverage years.
        # @return [Hash] The skeleton hash for application states.
        def skeleton(coverage_years)
          coverage_years.each_with_object({}) do |year, hash|
            hash[year] = APPLICATION_STATES.each_with_object({}) do |aasm_state, h|
              h[aasm_state] = 0
            end
          end
        end

        # Generates an aggregation pipeline for applications.
        #
        # @param coverage_years [Array<Integer>] The coverage years.
        # @return [Array<Hash>] The aggregation pipeline.
        def application_pipeline(coverage_years)
          [
            { '$match' => { 'assistance_year' => { '$in' => coverage_years }, 'predecessor_id' => { '$exists' => true, '$ne' => nil } } },
            { '$group' => { '_id' => { 'assistance_year' => '$assistance_year', 'aasm_state' => '$aasm_state' }, 'count' => { '$sum' => 1 } } },
            { '$group' => { '_id' => '$_id.assistance_year', 'application_states' => { '$push' => { 'aasm_state' => '$_id.aasm_state', 'count' => '$count' } } } },
            { '$project' => { 'assistance_year' => '$_id', 'application_states' => 1, '_id' => 0 } }
          ]
        end

        # Generates an aggregation pipeline for applicants.
        #
        # @param year [Integer] The year.
        # @return [Array<Hash>] The aggregation pipeline.
        def applicant_pipeline(year)
          [
            { '$match' => { 'assistance_year' => year, 'predecessor_id' => { '$exists' => true, '$ne' => nil }, 'aasm_state' => 'determined' } },
            { '$unwind' => '$applicants' },
            {
              '$group' => {
                '_id' => '$family_id',
                'primary_applicant_person_hbx_id' => { '$first' => '$applicants.person_hbx_id' },
                'is_primary_applicant' => { '$first' => '$applicants.is_primary_applicant' }
              }
            },
            {
              '$project' => {
                '_id' => 0,
                'family_id' => '$_id',
                'primary_applicant_person_hbx_id' => 1,
                'is_primary_applicant' => 1
              }
            }
          ]
        end
      end
    end
  end
end
end