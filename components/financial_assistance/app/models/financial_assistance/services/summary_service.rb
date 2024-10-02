# frozen_string_literal: true

module FinancialAssistance
  module Services
    # Manages the data of the sections for a summary page. Constructs the applicants summary, relationships summary, preferences summary, and household summary sections.
    class SummaryService
      include FinancialAssistance::Engine.routes.url_helpers
      include FinancialAssistance::ApplicationHelper
      include L10nHelper

      attr_reader :can_edit_incomes

      # Wrapper for a section of the summary page holding title and subsections
      class Section
        def initialize(section_title, subsections)
          @section_title = section_title
          @subsections = subsections
        end

        def to_h
          {section_title: @section_title, subsections: @subsections.map(&:to_h)}
        end
      end

      # Wrapper for a subsection of a section in the summary page holding title, rows, and an optional edit_link
      class Subsection
        def initialize(title:, rows:, edit_link: nil)
          @title = title
          @rows = rows
          @edit_link = edit_link
        end

        def to_h
          {title: @title, edit_link: @edit_link, rows: @rows}
        end
      end

      # Base class for the applicant summary section. Manages the loading of the raw application data and the mapping of the data into a view-ready hash.
      class ApplicantSummary < Section
        include L10nHelper
        include FinancialAssistance::ApplicationHelper
        include FinancialAssistance::Engine.routes.url_helpers
        include ActionView::Helpers::NumberHelper

        def initialize(application, applicant, can_edit: false)
          @applicant = applicant
          @application = application
          @can_edit = can_edit
          super(capitalize_full_name(applicant.full_name), @subsections = load_applicant_map.values.map(&method(:applicant_subsection_hash)))
        end

        private

        APPLICANT_CONFIGURATION = "./components/financial_assistance/app/models/financial_assistance/services/raw_application.yml.erb"
        COVERAGE_CONFIGURATION = "./components/financial_assistance/app/models/financial_assistance/services/raw_coverage.yml.erb"

        # @method load_applicant_map
        # Translates the applicant summary config data into a symbolized hash.
        #
        # @return [Hash] The hash holding all of the application summary data for the applicant.
        def load_applicant_map
          # load the map from the config
          application_file = File.read(ApplicantSummary::APPLICANT_CONFIGURATION)
          application_map = YAML.safe_load(ERB.new(application_file).result(binding)).deep_symbolize_keys

          # load the coverage data into the base map from the coverage config
          load_coverages_map(application_map, :is_enrolled)
          load_coverages_map(application_map, :is_eligible)

          application_map
        end

        # @method load_coverages_map(application_map, kind)
        # Helper method for `load_applicant_map`.
        # Loads the coverage data from the coverage config into the base application map for the given applicant.
        # Used for the `is_enrolled` and `is_eligible` coverage rows *only* when the row value is true.
        #
        # @param [Hash] applicant The application map to load the coverage data into.
        # @param [Symbol] kind The kind of coverage data to load.
        def load_coverages_map(application_map, kind)
          return unless application_map[:health_coverage][:rows][kind][:value]

          coverage_file = File.read(ApplicantSummary::COVERAGE_CONFIGURATION)
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
        def applicant_subsection_hash(section_data)
          Subsection.new(
            title: section_data[:title],
            rows: section_data[:rows].map do |row_key, row_data|
              if [:addresses, :jobs].include?(row_key) # address and job rows include nested rows
                row_data.map { |nested_section| applicant_subsection_hash(nested_section) }
              else
                row_data[:value] = human_value(row_data[:value])
                row_data
              end
            end,
            edit_link: (section_data[:edit_link] if @can_edit)
          ).to_h
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

        # value helpers

        def immigration_field_value(field)
          @applicant.has_citizen_immigration_status? ? @applicant.send(field) : l10n('faa.not_applicable_abbreviation')
        end

        def applicants_name_by_hbx_id_hash
          @application.active_applicants.each_with_object({}) { |applicant, hash| hash[applicant.person_hbx_id] = applicant.full_name }
        end
      end

      # Manages the applicant summary section for the Admin page context, containing nearly all raw application data.
      class AdminApplicantSummary < ApplicantSummary
        private

        PERSONAL_INFO_ROWS = [:dob, :gender, :relationship, :coverage].freeze

        def load_applicant_map
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

      # Manages the applicant summary section for the Consumer page context, containing only displayable raw application data and allowing for editing.
      class ConsumerApplicantSummary < ApplicantSummary

        def initialize(cfl_service, application, applicant, can_edit:)
          @helper = ApplicantDisplayableHelper.new(cfl_service, applicant.id)
          super(application, applicant, can_edit: can_edit)
        end

        private

        PERSONAL_INFO_ROWS = [:age, :gender, :relationship, :status, :is_incarcerated, :coverage].freeze

        def load_applicant_map
          filter_sections(super)
        end

        # @method filter_sections(map)
        # Modifies the applicant_map for the Consumer page context.
        # Removes the demographics section entirely, and filters the Income, Tax Info, Health Coverage, and Other Questions sections based on the applicant's displayable fields.
        #
        # @param [Hash] map The applicant_map to be modified.
        #
        # @return [Hash] The modified applicant_map.
        def filter_sections(map)
          map.delete(:demographics)
          filter_rows(map, :personal_info, PERSONAL_INFO_ROWS)
          income_section(map)
          tax_info_section(map)
          coverage_section(map)
          other_questions_section(map)
          map
        end

        def income_section(map)
          section = :income
          rows = [
            :has_job_income,
            (:jobs if @helper.displayable?(:incomes_jobs)),
            :self_employment,
            :other_sources,
            :unemployment,
            :ai_an_income
          ]
          filter_rows(map, section, rows)
          map[section][:rows][:jobs]&.each { |job_hash| job_hash[:rows].slice!(:phone) unless job_hash[:has_address] }
        end

        def tax_info_section(map)
          rows = [
            :will_file_taxes,
            :claimed_as_tax_dependent,
            (:filing_jointly if @helper.displayable?(:is_joint_tax_filing)),
            (:claimed_by if @helper.displayable?(:claimed_as_tax_dependent_by))
          ]
          filter_rows(map, :tax_info, rows)
        end

        def coverage_section(map)
          rows = [:is_enrolled, :is_eligible]
          rows += [:indian_health_service_eligible, :indian_health_service_through_referral] if EnrollRegistry[:indian_health_service_question].feature.is_enabled && @applicant.indian_tribe_member
          if FinancialAssistanceRegistry.feature_enabled?(:has_medicare_cubcare_eligible)
            rows += [:not_eligible_for_medicaid_cubcare, :medicaid_cubcare_due_on, :eligibility_change_due_to_medicaid_cubcare, :household_income_change, :medicaid_last_day]
          end
          rows += [:medicaid_chip_ineligible, :immigration_status_changed] if FinancialAssistanceRegistry[:medicaid_chip_driver_questions].enabled? && @applicant.eligible_immigration_status
          rows += [:dependent_coverage_end, :dependent_coverage_end_date]
          filter_rows(map, :health_coverage, rows)
        end

        def other_questions_section(map)
          rows = []
          if @applicant.is_applying_coverage
            rows.append(:ssn_applied) if @helper.displayable?(:is_ssn_applied)
            rows.append(:non_ssn_reason) if @helper.displayable?(:non_ssn_apply_reason)
          end
          rows += pregnancy_question_rows
          rows.append(:former_foster_care) if @helper.displayable?(:is_former_foster_care)
          rows += [:foster_care_state, :age_left_foster_care, :medicaid_during_foster_care] if @helper.displayable?(:foster_care_us_state)
          rows.append(:is_student)
          rows += [:student_kind, :student_status_end_on, :student_school_kind] if @helper.displayable?(:student_kind)
          rows += [:is_blind, :has_daily_living_help, :need_help_paying_bills, :is_physically_disabled]
          rows.append(:primary_caregiver) if FinancialAssistanceRegistry.feature_enabled?(:primary_caregiver_other_question)
          rows.append(:primary_caregiver_for) if FinancialAssistanceRegistry.feature_enabled?(:primary_caregiver_relationship_other_question)
          filter_rows(map, :other_questions, rows)
        end

        def pregnancy_question_rows
          rows = [:is_pregnant]
          rows += [:pregnancy_due_date, :children_expected_count] if @helper.displayable?(:pregnancy_due_on)
          rows += [
            (:post_partum_period if @helper.displayable?(:is_post_partum_period)),
            (:pregnancy_end_on if @helper.displayable?(:pregnancy_end_on)),
            (:is_enrolled_on_medicaid if @helper.displayable?(:is_enrolled_on_medicaid))
          ]
          rows
        end
      end

      # @method instance_for_action(action_name, cfl_service, application, applicants)
      # Creates a new instance of the SummaryService based on the given action name.
      #
      # @param [String] action_name The name of the action to create the SummaryService for.
      # @param [ConditionalFieldsLookupService] cfl_service The ConditionalFieldsLookupService instance.
      # @param [Application] application The application to create the SummaryService for.
      # @param [Array] applicants The applicants to create the SummaryService for.
      # return [SummaryService] The new SummaryService instance.
      def self.instance_for_action(action_name, cfl_service, application, applicants)
        self.new(action_name != "raw_application", action_name == "review_and_submit", cfl_service, application, applicants)
      end

      def initialize(is_concise, can_edit, cfl_service, application, applicants)
        @application = application
        @application_displayable_helper = ApplicationDisplayableHelper.new(cfl_service, @application.id)
        @applicants = applicants
        @applicant_summaries = applicants.map do |applicant|
          if is_concise
            ::FinancialAssistance::Services::SummaryService::ConsumerApplicantSummary.new(cfl_service, application, applicant, can_edit: can_edit)
          else
            ::FinancialAssistance::Services::SummaryService::AdminApplicantSummary.new(application, applicant)
          end
        end
        @can_edit_incomes = can_edit
      end

      # @method sections
      # Loads and returns the applicant summaries, relationships summary, preferences summary, and household summary sections for the application.
      #
      # @return [Array] The sections for the summary.
      def sections
        [*@applicant_summaries.map(&:to_h), relationships_summary, preferences_summary, household_summary].compact
      end

      # @method relationships_summary
      #
      # @return [Hash] The hash for the relationships summary section for the application.
      def relationships_summary
        return unless @application.applicants.count > 1 && @application.relationships.present?

        fr_hash = @application.relationships.map do |relationship|
          if member_name_by_id(relationship.applicant_id).present?
            relationship_key = l10n('faa.review.your_household.relationship', related_name: member_name_by_id(relationship.applicant_id), relationship: relationship.kind.titleize)
            {key: relationship_key, value: member_name_by_id(relationship.relative_id)}
          end
        end

        return if fr_hash.empty?
        Section.new(section_title: l10n('faa.review.your_household'),
                    subsections: [
                      Subsection.new(title: l10n('faa.nav.family_relationships'), 
                                     edit_link: application_relationships_path(@application), 
                                     rows: fr_hash.compact)
                                  ]).to_h
      end

      # @method preferences_summary
      #
      # @return [Hash] The hash for the preferences summary section for the application.
      def preferences_summary
        return unless @application.years_to_renew.present? && @application_displayable_helper.displayable?(:years_to_renew)

        Subsection.new(title: l10n('faa.review.preferences'),
                       edit_link: nil,
                       rows: [{key: l10n('faa.review.preferences.eligibility_renewal'), value: @application.years_to_renew}]).to_h
      end

      # @method household_summary
      #
      # @return [Hash] The hash for the household summary section for the application.
      def household_summary
        return unless @application_displayable_helper.displayable?(:parent_living_out_of_home_terms)

        Subsection.new(title: l10n('faa.review.more_about_your_household'), 
                       edit_link: nil,
                       rows: [{key: l10n('faa.review.more_about_your_household.parent_living_outside'), value: human_boolean(@application.parent_living_out_of_home_terms)}]).to_h
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
