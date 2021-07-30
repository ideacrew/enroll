# frozen_string_literal: true

# require 'aca_entities'
# require 'aca_entities/ffe/operations/process_mcr_application'
# require 'aca_entities/ffe/transformers/mcr_to/family'
require 'aca_entities/atp/transformers/cv/family'
require 'aca_entities/atp/operations/family'
require 'aca_entities/serializers/xml/medicaid/atp'

# rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/ClassLength

# RAILS_ENV=production bundle exec rails db:migrate:up source=MCR file_path="file_path" VERSION="20210512153640"
# RAILS_ENV=production bundle exec rails db:migrate:up source=atp file_path="file_path" VERSION="20210512153640"
# RAILS_ENV=production bundle exec rails db:migrate:up source=atp dir="directory_path" VERSION="20210512153640"
class MigrateFamily < Mongoid::Migration
  def self.up
    @source =  ENV["source"].to_s.downcase # MCR or ATP
    @file_path = ENV["file_path"].to_s || nil
    @directory_name = ENV['dir'].to_s || nil

    start migration_for: @source, path: @file_path, dir: @directory_name
  end

  def self.down; end

  class << self
    attr_accessor :extract_klass, :transform_klass, :ext_input_hash, :cv3_family_hash, :path_name

    def migrate_for_mcr
      ::AcaEntities::Ffe::Transformers::McrTo::Family.call(file_path, { transform_mode: :batch }) do |payload|
        transform_payload = Operations::Ffe::TransformApplication.new.call(payload)

        if transform_payload.success?
          family_hash = transform_payload.success.to_h.deep_stringify_keys!
        else
          puts "app_identifier: #{payload[:insuranceApplicationIdentifier]} | failed: #{transform_payload.failure}"
          next
        end

        if family_hash.empty?
          puts "app_identifier: #{payload[:insuranceApplicationIdentifier]} | family_hash: #{family_hash.empty?}"
          next
        end

        build_family(family_hash.merge!(ext_app_id: payload[:insuranceApplicationIdentifier])) # remove this after fixing ext_app_id in aca entities
        build_iap(family_hash['magi_medicaid_applications'].first.merge!(family_id: @family.id, benchmark_product_id: BSON::ObjectId.new,
                                                                         years_to_renew: 5))
        print "."
      rescue StandardError => e
        puts "E: #{payload[:insuranceApplicationIdentifier]}, f: @family.hbx_id  error: #{e.message.split('.').first}"
      end
    end

    def file_path
      case Rails.env
      when 'development'
        "spec/test_data/transform_example_payloads/mcr_applications.json"
      when 'test'
        "spec/test_data/transform_example_payloads/application.json"
      end
    end

    def build_iap(iap_hash)
      sanitize_iap_hash = sanitize_applicant_params(iap_hash)
      result = ::FinancialAssistance::Operations::Application::Create.new.call(params: sanitize_iap_hash)

      result.success? ? result.success : result.failure
    end

    def build_family(family_hash)
      @family = Family.new(family_hash.except('hbx_id', 'foreign_keys', 'broker_accounts', 'magi_medicaid_applications', 'family_members',
                                              'households'))

      family_hash['family_members'].sort_by { |a| a["is_primary_applicant"] ? 0 : 1 }.each do |family_member_hash|
        puts "sorting member primary: #{family_member_hash['is_primary_applicant']}"
        create_member(family_member_hash)
      end

      @family.save!
    end

    def create_member(family_member_hash)
      person_params = sanitize_person_params(family_member_hash)
      person_result = create_or_update_person(person_params)

      if person_result.success?
        @person = person_result.success
        @family_member = create_or_update_family_member(@person, @family, family_member_hash)
        consumer_role_params = family_member_hash['person']['consumer_role']
        create_or_update_consumer_role(consumer_role_params.merge(is_consumer_role: true), @family_member)
        # create_or_update_vlp_document(applicant_params, @person)
      else
        @person
      end
    end

    def create_or_update_person(person_params)
      Operations::People::CreateOrUpdate.new.call(params: person_params)
    end

    def create_or_update_consumer_role(applicant_params, family_member)
      return unless applicant_params[:is_consumer_role]

      # assign_citizen_status
      params = applicant_params.except("lawful_presence_determination")
      merge_params = params.merge(citizen_status: applicant_params["lawful_presence_determination"]["citizen_status"])

      Operations::People::CreateOrUpdateConsumerRole.new.call(params: { applicant_params: merge_params, family_member: family_member })
    end

    def create_or_update_family_member(person, family, family_member_hash)
      family_member = family.family_members.detect { |fm| fm.person_id.to_s == person.id.to_s }
      return family_member if family_member && (family_member_hash.key?(:is_active) ? family_member.is_active == family_member_hash[:is_active] : true)

      fm_attr = { is_primary_applicant: family_member_hash['is_primary_applicant'],
                  is_consent_applicant: family_member_hash['is_consent_applicant'],
                  is_coverage_applicant: family_member_hash['is_coverage_applicant'],
                  is_active: family_member_hash['is_active'] }

      family_member = family.add_family_member(person, fm_attr)
      family_member.save!

      create_or_update_relationship(person, family, family_member_hash['person']['person_relationships'][0]['kind'])
      family.save!
      family_member
    end

    def create_or_update_vlp_document(applicant_params, person)
      Operations::People::CreateOrUpdateVlpDocument.new.call(params: { applicant_params: applicant_params, person: person })
    end

    def create_or_update_relationship(person, family, relationship_kind)
      primary_person = family.primary_person
      exiting_relationship = primary_person.person_relationships.detect { |rel| rel.relative_id.to_s == person.id.to_s }
      return if exiting_relationship && exiting_relationship.kind == relationship_kind

      primary_person.ensure_relationship_with(person, relationship_kind)
    end

    def sanitize_applicant_params(iap_hash)
      applicants_hash = iap_hash['applicants']
      sanitize_params = []
      applicants_hash.each do |applicant_hash|
        family_member = @family.family_members.select do |fm|
          fm.person.first_name == applicant_hash['name']['first_name'] && fm.person.last_name == applicant_hash['name']['last_name']
        end.first

        sanitize_params << {
          family_member_id: family_member.id,
          relationship: family_member.relationship,
          first_name: applicant_hash['name']['first_name'],
          middle_name: applicant_hash['name']['middle_name'],
          last_name: applicant_hash['name']['last_name'],
          full_name: applicant_hash['name']['full_name'],
          name_sfx: applicant_hash['name']['name_sfx'],
          name_pfx: applicant_hash['name']['name_pfx'],
          alternate_name: applicant_hash['name']['alternate_name'],
          ssn: family_member.person.ssn,
          # "encrypted_ssn": applicant_hash['identifying_information']['encrypted_ssn'],
          has_ssn: applicant_hash['identifying_information']['has_ssn'],
          gender: applicant_hash['demographic']['gender'],
          dob: applicant_hash['demographic']['dob'],
          ethnicity: applicant_hash['demographic']['ethnicity'],
          race: applicant_hash['demographic']['race'],
          is_veteran_or_active_military: applicant_hash['demographic']['is_veteran_or_active_military'],
          is_vets_spouse_or_child: applicant_hash['demographic']['is_vets_spouse_or_child'],

          is_incarcerated: applicant_hash['attestation']['is_incarcerated'],
          is_physically_disabled: applicant_hash['attestation']['is_self_attested_disabled'],
          is_self_attested_disabled: applicant_hash['attestation']['is_self_attested_disabled'],
          is_self_attested_blind: applicant_hash['attestation']['is_self_attested_blind'],
          is_self_attested_long_term_care: applicant_hash['attestation']['is_self_attested_long_term_care'],

          is_primary_applicant: applicant_hash['is_primary_applicant'],
          native_american_information: applicant_hash['native_american_information'],

          citizen_status: applicant_hash['citizenship_immigration_status_information']['citizen_status'],
          is_resident_post_092296: applicant_hash['citizenship_immigration_status_information']['is_resident_post_092296'],
          is_lawful_presence_self_attested: applicant_hash['citizenship_immigration_status_information']['is_lawful_presence_self_attested'],

          is_consumer_role: true, # applicant_hash['is_consumer_role'],
          is_resident_role: applicant_hash['is_resident_role'],
          is_applying_coverage: applicant_hash['is_applying_coverage'],
          is_consent_applicant: applicant_hash['is_consent_applicant'],
          vlp_document: applicant_hash['vlp_document'],

          person_hbx_id: family_member.person.hbx_id,
          ext_app_id: applicant_hash['person_hbx_id'],
          is_required_to_file_taxes: applicant_hash['is_required_to_file_taxes'],
          tax_filer_kind: applicant_hash['tax_filer_kind'],
          is_joint_tax_filing: applicant_hash['is_joint_tax_filing'],
          is_claimed_as_tax_dependent: applicant_hash['is_claimed_as_tax_dependent'],
          claimed_as_tax_dependent_by: applicant_hash['claimed_as_tax_dependent_by'],

          is_student: applicant_hash['student']['is_student'],
          student_kind: applicant_hash['student']['student_kind'],
          student_school_kind: applicant_hash['student']['student_school_kind'],
          student_status_end_on: applicant_hash['student']['student_status_end_on'],

          is_refugee: applicant_hash['is_refugee'],
          is_trafficking_victim: applicant_hash['is_trafficking_victim'],

          is_former_foster_care: applicant_hash['foster_care']['is_former_foster_care'],
          age_left_foster_care: applicant_hash['foster_care']['age_left_foster_care'],
          foster_care_us_state: applicant_hash['foster_care']['foster_care_us_state'],
          had_medicaid_during_foster_care: applicant_hash['foster_care']['had_medicaid_during_foster_care'],

          is_pregnant: applicant_hash['pregnancy_information']['is_pregnant'],
          is_enrolled_on_medicaid: applicant_hash['pregnancy_information']['is_enrolled_on_medicaid'],
          is_post_partum_period: applicant_hash['pregnancy_information']['is_post_partum_period'],
          children_expected_count: applicant_hash['pregnancy_information']['expected_children_count'],
          pregnancy_due_on: applicant_hash['pregnancy_information']['pregnancy_due_on'],
          pregnancy_end_on: applicant_hash['pregnancy_information']['pregnancy_end_on'],

          is_subject_to_five_year_bar: applicant_hash['is_refugee'],
          is_five_year_bar_met: applicant_hash['is_refugee'],
          is_forty_quarters: applicant_hash['is_forty_quarters'],
          is_ssn_applied: applicant_hash['is_ssn_applied'],
          non_ssn_apply_reason: applicant_hash['non_ssn_apply_reason'],
          moved_on_or_after_welfare_reformed_law: applicant_hash['moved_on_or_after_welfare_reformed_law'],
          is_currently_enrolled_in_health_plan: applicant_hash['is_currently_enrolled_in_health_plan'],
          has_daily_living_help: applicant_hash['has_daily_living_help'],
          need_help_paying_bills: applicant_hash['need_help_paying_bills'],
          has_job_income: applicant_hash['has_job_income'],
          has_self_employment_income: applicant_hash['has_self_employment_income'],
          has_unemployment_income: applicant_hash['has_unemployment_income'],
          has_other_income: applicant_hash['has_other_income'],
          has_deductions: applicant_hash['has_deductions'],
          has_enrolled_health_coverage: applicant_hash['has_enrolled_health_coverage'],
          has_eligible_health_coverage: applicant_hash['has_eligible_health_coverage'],

          addresses: applicant_hash['addresses'],
          emails: applicant_hash['emails'],
          phones: applicant_hash['phones'],
          incomes: applicant_hash['incomes'],
          benefits: applicant_hash['benefits'],
          deductions: applicant_hash['deductions'],

          is_medicare_eligible: applicant_hash['is_medicare_eligible'],
          has_insurance: applicant_hash['has_insurance'],
          has_state_health_benefit: applicant_hash['has_state_health_benefit'],
          had_prior_insurance: applicant_hash['had_prior_insurance'],
          age_of_applicant: applicant_hash['age_of_applicant'],
          hours_worked_per_week: applicant_hash['hours_worked_per_week'],
          indian_tribe_member: applicant_hash['indian_tribe_member'],
          tribal_id: applicant_hash['tribal_id'],
          tribal_name: applicant_hash['tribal_name'],
          tribal_state: applicant_hash['tribal_state']
        }
      end
      iap_hash.except!('applicants').merge!(applicants: sanitize_params)
    end

    def sanitize_person_params(family_member_hash)
      person_hash = family_member_hash['person']
      consumer_role_hash = person_hash["consumer_role"]

      {
        first_name: person_hash['person_name']['first_name'],
        last_name: person_hash['person_name']['last_name'],
        full_name: person_hash['person_name']['full_name'],
        ssn: person_hash['person_demographics']['ssn'],
        no_ssn: person_hash['person_demographics']['no_ssn'], #update in aca entities contracts to receive as string
        gender: person_hash['person_demographics']['gender'],
        dob: person_hash['person_demographics']['dob'],
        date_of_death: person_hash['person_demographics']['date_of_death'],
        dob_check: person_hash['person_demographics']['dob_check'],
        race: consumer_role_hash['is_applying_coverage'] ? person_hash['race'] : nil,
        ethnicity: consumer_role_hash['is_applying_coverage'] ? [person_hash['race']] : nil,
        is_incarcerated: consumer_role_hash['is_applying_coverage'] ? person_hash['person_demographics']['is_incarcerated'] : nil,
        tribal_id: person_hash['person_demographics']['tribal_id'],
        tribal_name: person_hash['person_demographics']['tribal_name'],
        tribal_state: person_hash['person_demographics']['tribal_state'],
        language_code: person_hash['person_demographics']['language_code'],
        is_tobacco_user: person_hash['person_health']['is_tobacco_user'],
        is_physically_disabled: person_hash['person_health']['is_physically_disabled'],
        is_homeless: person_hash['is_homeless'],
        is_temporarily_out_of_state: person_hash['is_temporarily_out_of_state'],
        age_off_excluded: person_hash['age_off_excluded'],
        is_active: person_hash['is_active'],
        is_disabled: person_hash['is_disabled'],
        individual_market_transitions: person_hash['individual_market_transitions'],
        verification_types: person_hash['verification_types'],
        addresses: person_hash['addresses'],
        emails: person_hash['emails'],
        phones: person_hash['phones']
      }
    end

    def extract(file_path = nil)
      input_xml = File.read("#{Rails.root}/#{file_path}")
      record = @extract_klass.parse(input_xml)
      result = record.is_a?(Array) ? record.first : record
      @ext_input_hash = result.to_hash(identifier: true)
    end

    def define_etl_variables(source)
      @extract_klass, @transform_klass = case source
                                         when 'mcr'
                                         # [::AcaEntities::Atp::Operations::Family, ::AcaEntities::Atp::Transformers::Family]
                                         when 'atp'
                                           [::AcaEntities::Serializers::Xml::Medicaid::Atp::AccountTransferRequest,
                                            ::AcaEntities::Atp::Transformers::Cv::Family]
                                         end
    end

    def transform(input = {})
      @cv3_family_hash = @transform_klass.transform(input)
    end

    def start(*args)
      options = args.first
      @path_name = options[:path]
      @dir_name = options[:dir]
      # return "there is no corresponding migration for #{options[:migration_for]}" unless respond_to?(options[:migration_for])
      define_etl_variables(options[:migration_for])

      # refactor below logic
      case options[:migration_for]
      when 'atp'
        if !@dir_name&.empty?
          read_directory @dir_name do
            puts "Started processing file: #{@filepath}"
            extract @filepath
            transform ext_input_hash
            load_data cv3_family_hash
            puts "Ended processing file: #{@filepath}"
          rescue StandardError => e
            puts "Error processing file: #{@filepath} , error: #{e.backtrace}"
          end
        elsif !path_name&.empty?
          begin
            puts "Started processing file: #{path_name}"
            extract path_name
            transform ext_input_hash
            load_data cv3_family_hash
            puts "Ended processing file: #{path_name}"
          rescue StandardError => e
            puts "Error processing file: #{path_name} , error: #{e.inspect}"
          end
        end
      when 'mcr'
        migrate_for_mcr
      end
    end

    def read_directory(directory_name, &block)
      Dir.foreach(directory_name) do |filename|
        if File.extname(filename) == ".xml"
          @filepath = "#{directory_name}/#{filename}"
          instance_eval(&block) if block_given?
        end
      end
    end

    def load_data(payload = {})
      # transform_payload = Operations::Ffe::TransformApplication.new.call(payload)
      # if transform_payload.success?
      result_payload = payload.to_h.deep_stringify_keys!
      # else
      #   puts "app_identifier: #{payload[:insuranceApplicationIdentifier]} | failed: #{transform_payload.failure}"
      #   next
      # end

      if result_payload.empty?
        puts "app_identifier: #{payload[:insuranceApplicationIdentifier]} | family_hash: #{result_payload.empty?}"
        # next
      end
      build_family(result_payload["family"])
      app_id = build_iap(result_payload["family"]['magi_medicaid_applications'].first.merge!(family_id: @family.id, benchmark_product_id: BSON::ObjectId.new, years_to_renew: 5))
      fill_applicants_form(app_id, result_payload["family"]['magi_medicaid_applications'].first)
      print "."
    rescue StandardError => e
      puts "E: #{payload[:insuranceApplicationIdentifier]}, f: @family.hbx_id  error: #{e}"
    end

    def fill_applicants_form(app_id, applications)
      applicants_hash = applications[:applicants]
      application = FinancialAssistance::Application.where(id: app_id).first

      applicants_hash.each do |applicant|
        persisted_applicant = application.applicants.where(first_name: applicant[:first_name], last_name: applicant[:last_name]).first
        claimed_by = application.applicants.where(ext_app_id: applicant[:claimed_as_tax_dependent_by]).first
        persisted_applicant.is_physically_disabled = applicant[:is_physically_disabled]
        persisted_applicant.is_self_attested_blind = applicant[:is_self_attested_blind]
        persisted_applicant.is_self_attested_disabled = applicant[:is_self_attested_disabled]
        persisted_applicant.is_required_to_file_taxes = applicant[:is_required_to_file_taxes]
        persisted_applicant.tax_filer_kind = applicant[:tax_filer_kind]
        persisted_applicant.is_joint_tax_filing = applicant[:is_joint_tax_filing]
        persisted_applicant.is_claimed_as_tax_dependent = applicant[:is_claimed_as_tax_dependent]
        persisted_applicant.claimed_as_tax_dependent_by = claimed_by.id

        persisted_applicant.is_student = applicant[:is_student]
        persisted_applicant.student_kind = applicant[:student_kind]
        persisted_applicant.student_school_kind = applicant[:student_school_kind]
        persisted_applicant.student_status_end_on = applicant[:student_status_end_on]

        persisted_applicant.is_refugee = applicant[:is_refugee]
        persisted_applicant.is_trafficking_victim = applicant[:is_trafficking_victim]

        persisted_applicant.is_former_foster_care = applicant[:is_former_foster_care]
        persisted_applicant.age_left_foster_care = applicant[:age_left_foster_care]
        persisted_applicant.foster_care_us_state = applicant[:foster_care_us_state]
        persisted_applicant.had_medicaid_during_foster_care = applicant[:had_medicaid_during_foster_care]

        persisted_applicant.is_pregnant = applicant[:is_pregnant]
        persisted_applicant.is_enrolled_on_medicaid = applicant[:is_enrolled_on_medicaid]
        persisted_applicant.is_post_partum_period = applicant[:is_post_partum_period]
        persisted_applicant.children_expected_count = applicant[:children_expected_count]
        persisted_applicant.pregnancy_due_on = applicant[:pregnancy_due_on]
        persisted_applicant.pregnancy_end_on = applicant[:pregnancy_end_on]

        persisted_applicant.is_subject_to_five_year_bar = applicant[:is_subject_to_five_year_bar]
        persisted_applicant.is_five_year_bar_met = applicant[:is_five_year_bar_met]
        persisted_applicant.is_forty_quarters = applicant[:is_forty_quarters]
        persisted_applicant.is_ssn_applied = applicant[:is_ssn_applied]
        persisted_applicant.non_ssn_apply_reason = applicant[:non_ssn_apply_reason]
        persisted_applicant.moved_on_or_after_welfare_reformed_law = applicant[:moved_on_or_after_welfare_reformed_law]
        persisted_applicant.is_currently_enrolled_in_health_plan = applicant[:is_currently_enrolled_in_health_plan]
        persisted_applicant.has_daily_living_help = applicant[:has_daily_living_help]
        persisted_applicant.need_help_paying_bills = applicant[:need_help_paying_bills]
        persisted_applicant.has_job_income = applicant[:has_job_income]
        persisted_applicant.has_self_employment_income = applicant[:has_self_employment_income]
        persisted_applicant.has_unemployment_income = applicant[:has_unemployment_income]
        persisted_applicant.has_other_income = applicant[:has_other_income]
        persisted_applicant.has_deductions = applicant[:has_deductions]
        persisted_applicant.has_enrolled_health_coverage = applicant[:has_enrolled_health_coverage]
        persisted_applicant.has_eligible_health_coverage = applicant[:has_eligible_health_coverage]

        persisted_applicant.incomes = applicant[:incomes]
        persisted_applicant.benefits = applicant[:benefits].first.nil? ? [] : applicant[:benefits].compact
        persisted_applicant.deductions = applicant[:deductions]

        persisted_applicant.is_medicare_eligible = applicant[:is_medicare_eligible]
        ::FinancialAssistance::Applicant.skip_callback(:update, :after, :propagate_applicant)
        persisted_applicant.save!
        ::FinancialAssistance::Applicant.set_callback(:update, :after, :propagate_applicant)
        # persisted_applicant.has_insurance = applicant[:has_insurance]
        # persisted_applicant.has_state_health_benefit = applicant[:has_state_health_benefit]
        # persisted_applicant.had_prior_insurance = applicant[:had_prior_insurance]
        # persisted_applicant.age_of_applicant = applicant[:age_of_applicant]
        # persisted_applicant.hours_worked_per_week = applicant[:hours_worked_per_week]

        # persisted_applicant.is_consent_applicant = applicant.
        # persisted_applicant.is_tobacco_user = applicant.

        # persisted_applicant.assisted_income_validation = applicant.
        # validates_inclusion_of :assisted_income_validation, :in => INCOME_VALIDATION_STATES, :allow_blank => false
        # persisted_applicant.assisted_mec_validation = applicant.
        # validates_inclusion_of :assisted_mec_validation, :in => MEC_VALIDATION_STATES, :allow_blank => false
        # persisted_applicant.assisted_income_reason = applicant.
        # persisted_applicant.assisted_mec_reason = applicant.

        # persisted_applicant.aasm_state = applicant.

        # persisted_applicant.person_hbx_id = applicant.
        # persisted_applicant.ext_app_id = applicant.

        # persisted_applicant.is_active = applicant.

        # persisted_applicant.has_fixed_address = applicant.
        # persisted_applicant.is_living_in_state = applicant.

        # persisted_applicant.is_ia_eligible = applicant.

        # persisted_applicant.is_medicaid_chip_eligible = applicant.
        # persisted_applicant.is_non_magi_medicaid_eligible = applicant.
        # persisted_applicant.is_totally_ineligible = applicant.
        # persisted_applicant.is_without_assistance = applicant.
        # persisted_applicant.has_income_verification_response = applicant.
        # persisted_applicant.has_mec_verification_response = applicant.

        # persisted_applicant.magi_medicaid_monthly_household_income = applicant.
        # persisted_applicant.magi_medicaid_monthly_income_limit = applicant.

        # persisted_applicant.magi_as_percentage_of_fpl = applicant.
        # persisted_applicant.magi_medicaid_type = applicant.
        # persisted_applicant.magi_medicaid_category = applicant.
        # persisted_applicant.medicaid_household_size = applicant.

        # # We may not need the following two fields
        # persisted_applicant.is_magi_medicaid = applicant.
        # persisted_applicant.is_medicare_eligible = applicant.

        # split this out : change XSD too.
        # persisted_applicant.is_self_attested_blind_or_disabled = applicant.
        # persisted_applicant.is_self_attested_blind = applicant.
        # persisted_applicant.is_self_attested_disabled = applicant.

        # persisted_applicant.is_self_attested_long_term_care = applicant.

        # persisted_applicant.is_veteran = applicant.
        # persisted_applicant.is_refugee = applicant.
        # persisted_applicant.is_trafficking_victim = applicant.
      end
    end
  end
end
# rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Metrics/ClassLength
