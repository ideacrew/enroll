# frozen_string_literal: true

module FinancialAssistance
  module Services
    # Manages the data of the summary sections for a review page. Constructs the applicants, relationships, preferences, and household summary sections.
    # The applicant data is managed by `Summary::ApplicantSummary`, which loads from the configuration files containing the raw sections of key-value pairs.
    # The subclasses `AdminApplicantSummary` & `ConsumerApplicantSummary` drive the differences between the Admin and Consumer page contexts.
    #
    # The application data is managed by `Summary::ApplicationSummary`, loads the top-level Application data directly.
    class SummaryService

      attr_reader :can_edit_incomes

      # @method instance_for_action(action_name, cfl_service, application, applicants)
      # Creates a new instance of the SummaryService based on the given action name.
      #
      # @param [String] action_name The name of the action to create the SummaryService for.
      # @param [ConditionalFieldsLookupService] cfl_service The ConditionalFieldsLookupService instance.
      # @param [Application] application The application to create the SummaryService for.
      # @param [Array] applicants The applicants to create the SummaryService for.
      # return [SummaryService] The new SummaryService instance.
      def self.instance_for_action(action_name, cfl_service, application, applicants)
        new(is_concise: concise_action?(action_name), can_edit: editable_action?(action_name), cfl_service: cfl_service, application: application, applicants: applicants)
      end

      def initialize(is_concise:, can_edit:, cfl_service:, application:, applicants:)
        @application_summary = Summary::ApplicationSummary.new(application, cfl_service)
        @applicant_summaries = create_applicant_summaries(is_concise, can_edit, cfl_service, application, applicants)
        @can_edit_incomes = can_edit
      end

      # @method sections
      # Loads and returns the applicant summaries, relationships summary, preferences summary, and household summary sections for the application.
      #
      # @return [Array] The sections for the summary.
      def sections
        [*@applicant_summaries.map(&:hash), @application_summary.relationships_summary, @application_summary.preferences_summary, @application_summary.household_summary].compact
      end

      private       
      
      # @method concise_action?(action_name)
      # Static helper for initialization which determines if the action uses the concise/consumer summary flavor.
      #
      # @param [String] action_name The name of the action to check.
      # 
      # @return [Boolean] True if the action is concise, false otherwise.
      def self.concise_action?(action_name)
        action_name != "raw_application"
      end

      # @method editable_action?(action_name)
      # Static helper for initialization which determines if the action uses the summary with edit links.
      #
      # @param [String] action_name The name of the action to check.
      #
      # @return [Boolean] True if the action is editable, false otherwise.
      def self.editable_action?(action_name)
        action_name == "review_and_submit"
      end

      # @method create_applicant_summaries(is_concise, can_edit, cfl_service, application, applicants)
      # Helper method for initialization of the service that creates the applicant summaries based on the given context.
      def create_applicant_summaries(is_concise, can_edit, cfl_service, application, applicants)
        applicants.map { |applicant| Summary::ApplicantSummary::ApplicantSummaryFactory.create(is_concise, can_edit, cfl_service, application, applicant) }
      end

      # Base class for a summary section. Provides an interface for section and subsection hashes.
      class Summary
        def section_hash(title:, subsections:)
          {section_title: title, subsections: subsections}
        end

        def subsection_hash(title:, rows:, edit_link: nil)
          {title: title, rows: rows, edit_link: edit_link}
        end

        module ApplicantSummary
          
          # Factory class for creating the appropriate applicant summary section based on the context.
          class ApplicantSummaryFactory
            def self.create(is_concise, can_edit, cfl_service, application, applicant)
              if is_concise
                ApplicantSummary::ConsumerApplicantSummary.new(cfl_service, application, applicant, can_edit: can_edit)
              else
                ApplicantSummary::AdminApplicantSummary.new(application, applicant)
              end
            end
          end

          # Base class for the config loader. Manages the loading of the raw configuration data and the mapping of the data into a view-ready hash.
          class ConfigLoader
            include L10nHelper
            include FinancialAssistance::ApplicationHelper
            include FinancialAssistance::Engine.routes.url_helpers
            include ActionView::Helpers::NumberHelper

            def initialize(config:)
              @config = config
            end

            def load_config           
              config = File.read(@config)
              deep_symbolize_keys(YAML.safe_load(ERB.new(config).result(binding)))
            end

            private

            # @method deep_symbolize_keys(data)
            # Recursively converts the keys of a hash into symbols.
            def deep_symbolize_keys(data)
              return data.map(&method(:deep_symbolize_keys)) if data.is_a?(Array)
              data.deep_symbolize_keys
            end

            # @method human_value(value)
            # Converts a boolean value into a human-readable string.
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

            # Config loader for the applicant base hash
            class ApplicantConfigLoader < ConfigLoader
              def initialize(applicant, application)
                super(config: APPLICANT_CONFIGURATION)
                @applicant = applicant
                @application = application
              end

              # @method load_config
              # Loads the raw applicant hash from the config and constructs coverage subtables from the `ApplicantCoverageConfigLoader`.
              def load_config
                base_hash = super
                load_coverages_map(base_hash, :is_enrolled)
                load_coverages_map(base_hash, :is_eligible)
                base_hash
              end

              private

              APPLICANT_CONFIGURATION = "./components/financial_assistance/app/models/financial_assistance/services/raw_applicant.yml.erb"

              # Display the value of the immigration field based on the applicant's citizenship status
              def immigration_field_value(field)
                @applicant.has_citizen_immigration_status? ? @applicant.send(field) : l10n('faa.not_applicable_abbreviation')
              end
  
              # Constructs a hash of hbx_ids to full names for the application's active applicants
              def applicants_name_by_hbx_id_hash
                @application.active_applicants.each_with_object({}) { |applicant, hash| hash[applicant.person_hbx_id] = applicant.full_name }
              end

              # Config loader for the applicant coverage subtables within the base hash
              class ApplicantCoverageConfigLoader < ConfigLoader
                def initialize(applicant, kind)
                  super(config: COVERAGE_CONFIGURATION)
                  @benefits = applicant.benefits.has_valid_insurance_kind.where(kind: kind)
                end

                private

                COVERAGE_CONFIGURATION = "./components/financial_assistance/app/models/financial_assistance/services/raw_coverage.yml.erb"
              end

              # @method load_coverages_map(hash, kind)
              # Loads the coverage subtables for the specified kind only when the applicant has the kind.
              # After reading the kind, it formats it into a human-readable string and constructs the coverage subtables if needed.
              def load_coverages_map(hash, kind)
                has_kind = hash[:health_coverage][:rows][kind][:value]
                hash[:health_coverage][:rows][kind][:value] = human_value(has_kind)
                return unless has_kind
  
                coverage_map = ApplicantCoverageConfigLoader.new(@applicant, kind).load_config
                hash[:health_coverage][:rows][kind][:coverages] = coverage_map
              end
            end
          end

          # Base class for the applicant summary section. Manages the loading of the raw application data and the mapping of the data into a view-ready hash.
          class ApplicantSummary < Summary
            include FinancialAssistance::ApplicationHelper

            attr_reader :hash

            def initialize(application, applicant)
              super()
              @application = application
              @applicant = applicant
              @hash = section_hash(title: capitalize_full_name(applicant.full_name), subsections: load_summary.values.map(&method(:applicant_subsection_hash)))
            end

            private
            
            # @method load_summary
            # Loads the raw summary hash from the config and filters the sections based on the context.
            #
            # @return [Hash] The view-ready summary hash.
            def load_summary()
              applicant_hash = ConfigLoader::ApplicantConfigLoader.new(@applicant, @application).load_config
              filter_sections(applicant_hash)
            end

            # @method applicant_subsection_hash(section_data)
            # Maps the raw subsection hash into a view-ready hash by removing the outer row_keys and recursively handling nested subsections.
            #
            # @param [Hash] section_data The section hash from the config.
            #
            # @return [Hash] The view-ready section hash.
            def applicant_subsection_hash(section_data)
              section_data[:rows] = section_data[:rows].values
              section_data[:rows].map { |row| row.is_a?(Array) ? row.map(&method(:applicant_subsection_hash)) : row }
              subsection_hash(title: section_data[:title], rows: section_data[:rows])
            end

            # stub method child classes can override to conditionlly render rows
            def filter_sections(map) end

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

            # Manages the applicant summary section for the Admin page context, containing nearly all raw application data.
            class AdminApplicantSummary < ApplicantSummary
              private

              PERSONAL_INFO_ROWS = [:dob, :gender, :relationship, :coverage].freeze

              # @method filter_sections(map)
              # Modifies the applicant_map for the Admin page context.
              # Removes the ai_an_income row from the Income section and the HRA rows if enrolled. Also filter the Personal Info rows and combines them with the Demographics rows.
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
                @helper = DisplayableHelper::ApplicantDisplayableHelper.new(cfl_service, applicant.id)
                @can_edit = can_edit
                super(application, applicant)
              end

              private

              PERSONAL_INFO_ROWS = [:age, :gender, :relationship, :status, :is_incarcerated, :coverage].freeze

              # @method applicant_subsection_hash(section_data)
              # Maps the raw section hash for the consumer into a view-ready hash of the form:
              # { title: <section_title>,
              #   edit_link: <section_edit_link>,
              #   rows: [{
              #     key: <row_label>, value: <row_value>, <... special row data ...>
              #   }]
              # }
              #
              # Overrides the base class method to optionally include the edit link.
              #
              # @param [Hash] section_data The section hash from the config.
              #
              # @return [Hash] The view-ready section hash.
              def applicant_subsection_hash(section_data)
                hash = super
                subsection_hash(title: hash[:title], rows: hash[:rows], edit_link: (section_data[:edit_link] if @can_edit))
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
          end
        end

        # Manages the application summary sections for the review page context, containing the relationships, preferences, and household summaries.
        class ApplicationSummary < Summary
          include L10nHelper
          include FinancialAssistance::ApplicationHelper
          include FinancialAssistance::Engine.routes.url_helpers
          
          def initialize(application, cfl_service)
            super()
            @application = application
            @application_displayable_helper = DisplayableHelper::ApplicationDisplayableHelper.new(cfl_service, @application.id)
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
            section_hash(title: l10n('faa.review.your_household'),
                        subsections: [subsection_hash(
                          title: l10n('faa.nav.family_relationships'),
                          edit_link: application_relationships_path(@application),
                          rows: fr_hash.compact
                        )])
          end

          # @method preferences_summary
          #
          # @return [Hash] The hash for the preferences summary section for the application.
          def preferences_summary
            return unless @application.years_to_renew.present? && @application_displayable_helper.displayable?(:years_to_renew)

            subsection_hash(title: l10n('faa.review.preferences'), rows: [{key: l10n('faa.review.preferences.eligibility_renewal'), value: @application.years_to_renew}])
          end

          # @method household_summary
          #
          # @return [Hash] The hash for the household summary section for the application.
          def household_summary
            return unless @application_displayable_helper.displayable?(:parent_living_out_of_home_terms)

            subsection_hash(title: l10n('faa.review.more_about_your_household'), rows: [{key: l10n('faa.review.more_about_your_household.parent_living_outside'), value: human_boolean(@application.parent_living_out_of_home_terms)}])
          end
        end
      end

      # Displayable field helpers
      module DisplayableHelper
        # Helper class for checking if a field is displayable for an applicant or application.
        class DisplayableHelper
          def initialize(service, id)
            @service = service
            @id = id
          end

          def displayable?(attribute)
            @service.displayable_field?(@class.name.demodulize.downcase, @id, attribute)
          end
        end

        # Display helper for Applicant class
        class ApplicantDisplayableHelper < DisplayableHelper
          attr_reader :applicant_id

          def initialize(service, id)
            @class = FinancialAssistance::Applicant
            @applicant_id = id
            super
          end
        end

        # Display helper for Application class
        class ApplicationDisplayableHelper < DisplayableHelper
          def initialize(service, id)
            @class = FinancialAssistance::Application
            super
          end
        end
      end
    end
  end
end
