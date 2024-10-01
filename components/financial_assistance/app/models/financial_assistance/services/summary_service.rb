# frozen_string_literal: true

module FinancialAssistance
  module Services
    # Manages the data of the sections for a summary page
    class SummaryService
      include FinancialAssistance::Engine.routes.url_helpers
      include FinancialAssistance::ApplicationHelper
      include ActionView::Helpers::NumberHelper
      include L10nHelper

      attr_reader :can_edit

      APPLICANT_CONFIGURATION = "./components/financial_assistance/app/models/financial_assistance/services/raw_application.yml.erb"
      COVERAGE_CONFIGURATION = "./components/financial_assistance/app/models/financial_assistance/services/raw_coverage.yml.erb"

      def initialize(cfl_service, application, applicants, can_edit: false)
        @application = application
        @application_displayable_helper = ApplicationDisplayableHelper.new(cfl_service, @application.id)
        @applicants = applicants
        @can_edit = can_edit
      end

      # @method applicant_summaries
      # Loads the applicant summary section hashes for all applicants in the application.
      #
      # @return [Hash] The hash holding the application summary data for each applicant.
      def applicant_summaries
        @applicants.map do |applicant|
          applicant_map = load_applicant_map(applicant)
          {applicant_name: applicant.full_name, sections: applicant_map.values.map(&method(:applicant_section_hash))}
        end
      end

      # @method relationships_summary
      #
      # @return [Hash] The hash for the relationships summary section for the application.
      def relationships_summary
        return unless @application.relationships.present?

        fr_hash = @application.relationships.map do |relationship|
          if member_name_by_id(relationship.applicant_id).present?
            relationship_key = l10n('faa.review.your_household.relationship', related_name: member_name_by_id(relationship.applicant_id), relationship: relationship.kind.titleize)
            {key: relationship_key, value: member_name_by_id(relationship.relative_id)}
          end
        end

        section_hash(title: l10n('faa.nav.family_relationships'), edit_link: application_relationships_path(@application), rows: fr_hash) unless fr_hash.empty?
      end

      # @method preferences_summary
      #
      # @return [Hash] The hash for the preferences summary section for the application.
      def preferences_summary
        return unless @application.years_to_renew.present? && @application_displayable_helper.displayable?(:years_to_renew)

        section_hash(title: l10n('faa.review.preferences'), edit_link: nil, rows: [{key: l10n('faa.review.preferences.eligibility_renewal'), value: @application.years_to_renew}])
      end

      # @method household_summary
      #
      # @return [Hash] The hash for the household summary section for the application.
      def household_summary
        return unless @application_displayable_helper.displayable?(:parent_living_out_of_home_terms)

        section_hash(title: l10n('faa.review.more_about_your_household'), edit_link: nil, rows: [{key: l10n('faa.review.more_about_your_household.parent_living_outside'), value: human_boolean(@application.parent_living_out_of_home_terms)}])
      end

      private

      # @method load_applicant_map(applicant)
      # Translates the applicant summary config data into a symbolized hash.
      #
      # @param [FinancialAssistance::Applicant] applicant The applicant for whom the summary data is being loaded.
      #
      # @return [Hash] The hash holding all of the application summary data for the applicant.
      def load_applicant_map(applicant)
        # load the map from the config
        application_file = File.read(SummaryService::APPLICANT_CONFIGURATION)
        application_map = YAML.safe_load(ERB.new(application_file).result(binding)).deep_symbolize_keys

        # load the coverage data into the map from the coverage config
        load_coverages_map(applicant, application_map, :is_enrolled)
        load_coverages_map(applicant, application_map, :is_eligible)

        application_map
      end

      # @method load_coverages_map(applicant, application_map, kind)
      # Helper method for `load_applicant_map`.
      # Loads the coverage data from the coverage config into the application map for the given applicant.
      # Used for the `is_enrolled` and `is_eligible` coverage rows *only* when the row value is true.
      #
      # @param [FinancialAssistance::Applicant] applicant The applicant for whom the coverage data is being loaded.
      # @param [Hash] applicant The application map to load the coverage data into.
      # @param [Symbol] kind The kind of coverage data to load.
      def load_coverages_map(applicant, application_map, kind)
        return unless application_map[:health_coverage][:rows][kind][:value]

        coverage_file = File.read(SummaryService::COVERAGE_CONFIGURATION)
        coverage_map = YAML.safe_load(ERB.new(coverage_file).result(binding)).map { |kind_array| kind_array.map(&:deep_symbolize_keys) }
        application_map[:health_coverage][:rows][kind][:coverages] = coverage_map
      end

      # @method section_hash(section_data)
      # Maps the raw section hash into a view-ready hash of the form:
      # { title: <section_title>,
      #   edit_link: <section_edit_link>,
      #   rows: [{
      #     key: <row_label>, value: <row_value>, <... special row data ...>
      #   }]
      # }
      #
      # @param [Hash] section_data The section hash from the config.
      #
      # @return [Hash] The view-ready section hash.
      def applicant_section_hash(section_data)
        section_hash(
          title: section_data[:title],
          edit_link: (section_data[:edit_link] if @can_edit),
          rows: section_data[:rows].map do |row_key, row_data|
            if [:addresses, :jobs].include?(row_key) # address and job rows include nested rows
              row_data.map { |nested_section| applicant_section_hash(nested_section) }
            else
              row_data[:value] = human_value(row_data[:value])
              row_data
            end
          end
        )
      end

      def section_hash(title:, edit_link:, rows:)
        {title: title, edit_link: edit_link, rows: rows}
      end

      # @method filter_rows(base_map, section_key, rows)
      # Filters the rows of a section from the base map based on the provided list of row keys.
      #
      # @param [Hash] base_map The entire summary hash from the config.
      # @param [Symbol] section_key The key of the section to filter rows for.
      # @param [Array] rows The row keys to keep in the section.
      #
      # @return [Hash] The modified section hash containing only the specified rows.
      def filter_rows(base_map, section_key, rows)
        base_map[section_key][:rows].slice!(*rows)
      end

      def human_value(value)
        case value
        when true
          l10n('yes')
        when false
          l10n('no')
        else
          value || l10n('faa.not_applicable_abbreviation')
        end
      end

      def immigration_field_value(applicant, field)
        applicant.has_citizen_immigration_status? ? applicant.send(field) : l10n('faa.not_applicable_abbreviation')
      end

      # Class which manages the summary hash for the admin review page containing nearly all raw application data.
      class AdminSummaryService < SummaryService
        private

        PERSONAL_INFO_ROWS = [:dob, :gender, :relationship, :coverage].freeze

        def load_applicant_map(applicant)
          filter_sections(super)
        end

        # @method filter_sections(map)
        # Modifies the applicant_map for the Admin page context.
        # Removes the ai_an_income row from the Income section and the HRA rows if enrolled.
        #
        # @param [Hash] map The applicant_map to be modified.
        #
        # @return [Hash] The modified applicant_map.
        def filter_sections(map)
          map[:income][:rows].delete(:ai_an_income)
          filter_rows(map, :personal_info, PERSONAL_INFO_ROWS)
          map[:personal_info][:rows].merge!(map[:demographics][:rows])
          map.delete(:demographics)
          filter_rows(map, :health_coverage, [:is_enrolled, :is_eligible]) if FinancialAssistanceRegistry[:has_enrolled_health_coverage].setting(:currently_enrolled).item
          map
        end
      end

      # Class which manages the summary hash for the consumer review pages containing limited raw application data and supporting editable sections.
      class ConsumerSummaryService < SummaryService

        def initialize(cfl_service, application, applicants, can_edit)
          @applicant_displayable_helpers = applicants.map { |applicant| ApplicantDisplayableHelper.new(cfl_service, applicant.id) }
          super
        end

        private

        PERSONAL_INFO_ROWS = [:age, :gender, :relationship, :status, :is_incarcerated, :coverage].freeze

        def load_applicant_map(applicant)
          filter_sections(super, applicant)
        end

        # @method filter_sections(map)
        # Modifies the applicant_map for the Consumer page context.
        # Removes the demographics section entirely, and filters the Income, Tax Info, Health Coverage, and Other Questions sections based on the applicant's displayable fields.
        #
        # @param [Hash] map The applicant_map to be modified.
        #
        # @return [Hash] The modified applicant_map.
        def filter_sections(map, applicant)
          map.delete(:demographics)
          filter_rows(map, :personal_info, PERSONAL_INFO_ROWS)
          helper = @applicant_displayable_helpers.find { |curr_helper| curr_helper.applicant_id == applicant.id }
          income_section(map, helper)
          tax_info_section(map, helper)
          coverage_section(map, applicant)
          other_questions_section(map, applicant, helper)
          map
        end

        def income_section(map, helper)
          section = :income
          rows = [
            :has_job_income,
            (:jobs if helper.displayable?(:incomes_jobs)),
            :self_employment,
            :other_sources,
            :unemployment,
            :ai_an_income
          ]
          filter_rows(map, section, rows)
          map[section][:rows][:jobs]&.each { |job_hash| job_hash[:rows].slice!(:phone) unless job_hash[:has_address] }
        end

        def tax_info_section(map, helper)
          rows = [
            :will_file_taxes,
            :claimed_as_tax_dependent,
            (:filing_jointly if helper.displayable?(:is_joint_tax_filing)),
            (:claimed_by if helper.displayable?(:claimed_as_tax_dependent_by))
          ]
          filter_rows(map, :tax_info, rows)
        end

        def coverage_section(map, applicant)
          rows = [:is_enrolled, :is_eligible]
          rows += [:indian_health_service_eligible, :indian_health_service_through_referral] if EnrollRegistry[:indian_health_service_question].feature.is_enabled && applicant.indian_tribe_member
          if FinancialAssistanceRegistry.feature_enabled?(:has_medicare_cubcare_eligible)
            rows += [:not_eligible_for_medicaid_cubcare, :medicaid_cubcare_due_on, :eligibility_change_due_to_medicaid_cubcare, :household_income_change, :medicaid_last_day]
          end
          rows += [:medicaid_chip_ineligible, :immigration_status_changed] if FinancialAssistanceRegistry[:medicaid_chip_driver_questions].enabled? && applicant.eligible_immigration_status
          rows += [:dependent_coverage_end, :dependent_coverage_end_date]
          filter_rows(map, :health_coverage, rows)
        end

        def other_questions_section(map, applicant, helper)
          rows = []
          if applicant.is_applying_coverage
            rows.append(:ssn_applied) if helper.displayable?(:is_ssn_applied)
            rows.append(:non_ssn_reason) if helper.displayable?(:non_ssn_apply_reason)
          end
          rows += pregnancy_question_rows(helper)
          rows.append(:former_foster_care) if helper.displayable?(:is_former_foster_care)
          rows += [:foster_care_state, :age_left_foster_care, :medicaid_during_foster_care] if helper.displayable?(:foster_care_us_state)
          rows.append(:is_student)
          rows += [:student_kind, :student_status_end_on, :student_school_kind] if helper.displayable?(:student_kind)
          rows += [:is_blind, :has_daily_living_help, :need_help_paying_bills, :is_physically_disabled]
          rows.append(:primary_caregiver) if FinancialAssistanceRegistry.feature_enabled?(:primary_caregiver_other_question)
          rows.append(:primary_caregiver_for) if FinancialAssistanceRegistry.feature_enabled?(:primary_caregiver_relationship_other_question)
          filter_rows(map, :other_questions, rows)
        end

        def pregnancy_question_rows(helper)
          rows = [:is_pregnant]
          rows += [:pregnancy_due_date, :children_expected_count] if helper.displayable?(:pregnancy_due_on)
          rows += [
            (:post_partum_period if helper.displayable?(:is_post_partum_period)),
            (:pregnancy_end_on if helper.displayable?(:pregnancy_end_on)),
            (:is_enrolled_on_medicaid if helper.displayable?(:is_enrolled_on_medicaid))
          ]
          rows
        end
      end

      # displayable field helpers
      class DisplayableHelper
        def initialize(service, id)
          @service = service
          @id = id
        end

        def displayable?(attribute)
          @service.displayable_field?(@class.name.demodulize.downcase, @id, attribute)
        end
      end

      # display helper for applicant
      class ApplicantDisplayableHelper < DisplayableHelper
        attr_reader :applicant_id

        def initialize(service, id)
          @class = FinancialAssistance::Applicant
          @applicant_id = id
          super
        end
      end

      # display helper for application
      class ApplicationDisplayableHelper < DisplayableHelper
        def initialize(service, id)
          @class = FinancialAssistance::Application
          super
        end
      end
    end
  end
end
