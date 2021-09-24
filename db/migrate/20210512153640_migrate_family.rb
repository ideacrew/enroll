# frozen_string_literal: true

require 'aca_entities'
require 'aca_entities/ffe/operations/process_mcr_application'
require 'aca_entities/ffe/transformers/mcr_to/family'
require 'aca_entities/atp/transformers/cv/family'
require 'aca_entities/atp/operations/family'
require 'aca_entities/serializers/xml/medicaid/atp'

# rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/ClassLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

# RAILS_ENV=production bundle exec rails db:migrate:up source=MCR dir="file_path" VERSION="20210512153640"
# RAILS_ENV=production bundle exec rails db:migrate:up source=atp file_path="file_path" VERSION="20210512153640"
# RAILS_ENV=production bundle exec rails db:migrate:up source=atp dir="directory_path" VERSION="20210512153640"
class MigrateFamily < Mongoid::Migration
  include EventSource::Command
  include Acapi::Notifiers

  def self.up
    @source = ENV["source"].to_s.downcase # MCR or ATP
    @directory_name = ENV['dir'].to_s || nil

    start migration_for: @source, path: @file_path, dir: @directory_name
  end

  def self.down; end

  class << self
    include EventSource::Command

    attr_accessor :extract_klass, :transform_klass, :ext_input_hash, :cv3_family_hash, :path_name
    attr_reader :file_path

    def migrate_for_mcr
      ::AcaEntities::Ffe::Transformers::McrTo::Family.call(@filepath, { transform_mode: :batch }) do |payload|
        if Rails.env.development?
          result = Operations::Ffe::MigrateApplication.new.call(payload)
          puts result
        else
          notify("acapi.info.events.migration.mcr_application_payload", {:body => JSON.dump(payload)})
          # event("events.json.stream", attributes: payload).success.publish
        end
      rescue StandardError => e
        puts "Error: #{payload[:insuranceApplicationIdentifier]}"
      end
    end

    def fix_iap_relationship(app_id, family_hash)
      @application = FinancialAssistance::Application.where(id: app_id).first
      @matrix = @application.build_relationship_matrix
      @missing_relationships = @application.find_missing_relationships(@matrix)
      @all_relationships = @application.find_all_relationships(@matrix)
      missing_relationships = []
      all_relationships = []
      @missing_relationships.each do |rel|
        from_relation = rel.first[0]
        to_relation = rel.first[1]
        next if @application.relationships.where(applicant_id: from_relation, relative_id: to_relation).present?
        from_applicant = @application.applicants.where(id: from_relation).first
        to_applicant = @application.applicants.where(id: to_relation).first
        from_family_member = ::FamilyMember.find(from_applicant.family_member_id)
        to_family_member = ::FamilyMember.find(to_applicant.family_member_id)
        member_hash = family_hash["family_members"].select { |member| member["hbx_id"] == from_family_member.external_member_id}.first
        relationship = member_hash["person"]["person_relationships"].select do |p_rel|
          p_rel["relative"]["hbx_id"] == to_family_member.external_member_id
        end.first
        relation_kind = relationship.present? ? relationship["kind"] : "unrelated"
        missing_relationships << ::FinancialAssistance::Relationship.new({ kind: relation_kind, applicant_id: from_applicant.id,
                                                                           relative_id: to_applicant.id })
      end
      @application.relationships << missing_relationships

      @all_relationships.each do |all_rel|
        next if all_rel[:relation].present?
        relationships = @application.relationships
        from_relation = all_rel[:applicant]
        to_relation = all_rel[:relative]
        found_relationship = relationships.where(applicant_id: from_relation, relative_id: to_relation).first
        next if found_relationship.present? && found_relationship.kind.present?
        inverse_relationship = relationships.where(applicant_id: to_relation, relative_id: from_relation).first
        if inverse_relationship.present?
          relation = ::FinancialAssistance::Relationship::INVERSE_MAP[inverse_relationship.kind]
          all_relationships << ::FinancialAssistance::Relationship.new({ kind: relation, applicant_id: from_relation, relative_id: to_relation })
          next
        end
        from_applicant = @application.applicants.find(from_relation)
        to_applicant = @application.applicants.find(to_relation)
        from_family_member = ::FamilyMember.find(from_applicant.family_member_id)
        to_family_member = ::FamilyMember.find(to_applicant.family_member_id)
        member_hash = family_hash["family_members"].select { |member| member["hbx_id"] == from_family_member.external_member_id}.first
        relationship = member_hash["person"]["person_relationships"].select do |p_rel|
          p_rel["relative"]["hbx_id"] == to_family_member.external_member_id
        end.first
        relation_kind = relationship.present? ? relationship["kind"] : "unrelated"
        relation = ::FinancialAssistance::Relationship::INVERSE_MAP[relation_kind]
        if found_relationship.present?
          found_relationship.update_attributes(kind: relation)
        else
          all_relationships << ::FinancialAssistance::Relationship.new({ kind: relation, applicant_id: from_applicant.id,
                                                                         relative_id: to_applicant.id })
        end
      end
      @application.relationships << all_relationships
      @application.save!
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
      add_broker_accounts(@family, family_hash)

      @family.save!
    end

    def create_member(family_member_hash)
      person_params = sanitize_person_params(family_member_hash)
      person_result = create_or_update_person(person_params)
      if person_result.success?
        @person = person_result.success
        @person.update_attributes(is_applying_for_assistance: person_params[:is_applying_for_assistance])
        @family_member = create_or_update_family_member(@person, @family, family_member_hash)
        consumer_role_params = family_member_hash['person']['consumer_role']
        consumer_role_result = create_or_update_consumer_role(consumer_role_params.merge(is_consumer_role: true), @family_member)
        consumer_role = consumer_role_result.success
        consumer_role.import!
        if consumer_role_params["vlp_documents"].present?
          vlp_document_result = create_or_update_vlp_document(consumer_role_params["vlp_documents"], @person)
          vlp_document = vlp_document_result.success
          vlp_document.update_all(status: "verified")
        end
      else
        @person
      end
    end

    def create_or_update_person(person_params)
      person_params[:is_temporarily_out_of_state] = false # TODO
      person_params[:is_disabled] = false # TODO
      person_params[:addresses] = person_params[:addresses].nil? ? [] : person_params[:addresses] # TODO
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

      external_member_id = family_member_hash['hbx_id']

      if family_member_hash['is_primary_applicant']
        family_member = family.add_family_member(person, fm_attr)
        create_or_update_relationship(person, family, family_member_hash['person']['person_relationships'][0]['kind'])
      else
        create_or_update_relationship(person, family, family_member_hash['person']['person_relationships'][0]['kind'])
        family_member = family.add_family_member(person, fm_attr)
      end

      family_member.external_member_id = external_member_id
      family_member.save!
      family.save!

      family_member
    end

    def add_broker_accounts(family, family_hash)
      return unless family_hash['broker_accounts'].present?
      family_hash['broker_accounts'].each do |account|
        start_on = account['start_on']
        npn = account['broker_role_reference']['npn']
        broker_role = BrokerRole.find_by_npn(npn)
        next unless broker_role
        family.broker_agency_accounts.new(benefit_sponsors_broker_agency_profile_id: broker_role.broker_agency_profile.id,
                                          writing_agent_id: broker_role.id, start_on: start_on, is_active: true)
      end
    end

    def create_or_update_vlp_document(vlp_params, person)
      return unless vlp_params.present?

      vlp_params.each do |vlp|
        Operations::People::CreateOrUpdateVlpDocument.new.call(params: { applicant_params: vlp, person: person })
      end
    end

    def create_or_update_relationship(person, family, relationship_kind)
      @primary_person = family.primary_person
      exiting_relationship = @primary_person.person_relationships.detect { |rel| rel.relative_id.to_s == person.id.to_s }
      return if exiting_relationship && exiting_relationship.kind == relationship_kind

      @primary_person.ensure_relationship_with(person, relationship_kind)
    end

    def same_address_with_primary(family_member)
      member = family_member.person

      compare_keys = ["address_1", "address_2", "city", "state", "zip"]
      member.is_homeless? == @primary_person.is_homeless? &&
        member.is_temporarily_out_of_state? == @primary_person.is_temporarily_out_of_state? && member.home_address &&
        member.home_address.attributes.select {|k, _v| compare_keys.include? k} == @primary_person.home_address.attributes.select do |k, _v|
                                                                                     compare_keys.include? k
                                                                                   end
    end

    def sanitize_applicant_params(iap_hash)
      applicants_hash = iap_hash['applicants']
      sanitize_params = []
      applicants_hash.sort_by { |a| a["is_primary_applicant"] ? 0 : 1 }.each do |applicant_hash|
        family_member = @family.family_members.select do |fm|
          fm.person.first_name == applicant_hash['name']['first_name'] && fm.person.last_name == applicant_hash['name']['last_name']
        end.first

        citizen_status_info = applicant_hash['citizenship_immigration_status_information']

        sanitize_params << {
          family_member_id: family_member.id,
          relationship: family_member.relationship,
          first_name: applicant_hash['name']['first_name'],
          middle_name: applicant_hash['name']['middle_name'],
          last_name: applicant_hash['name']['last_name'],
          full_name: applicant_hash['name']['full_name'],
          name_sfx: applicant_hash['name']['name_sfx'].present? ? applicant_hash['name']['name_sfx'] : "",
          name_pfx: applicant_hash['name']['name_pfx'].present? ? applicant_hash['name']['name_pfx'] : "",
          alternate_name: applicant_hash['name']['alternate_name'],
          ssn: family_member.person.ssn,
          # "encrypted_ssn": applicant_hash['identifying_information']['encrypted_ssn'],
          has_ssn: applicant_hash['identifying_information']['has_ssn'],
          gender: applicant_hash['demographic']['gender'].to_s.downcase,
          dob: applicant_hash['demographic']['dob'],
          ethnicity: applicant_hash['demographic']['ethnicity'],
          race: applicant_hash['demographic']['race'],
          is_veteran_or_active_military: applicant_hash['demographic']['is_veteran_or_active_military'],
          is_vets_spouse_or_child: applicant_hash['demographic']['is_vets_spouse_or_child'],
          same_with_primary: same_address_with_primary(family_member),
          is_incarcerated: applicant_hash['is_applying_coverage'] ? (applicant_hash.dig('attestation', 'is_incarcerated') || false) : nil,
          is_physically_disabled: applicant_hash.dig('attestation', 'is_self_attested_disabled'),
          is_self_attested_disabled: applicant_hash.dig('attestation', 'is_self_attested_disabled'),
          is_self_attested_blind: applicant_hash.dig('attestation', 'is_self_attested_blind'),
          is_self_attested_long_term_care: applicant_hash.dig('attestation', 'is_self_attested_long_term_care'),

          is_primary_applicant: applicant_hash['is_primary_applicant'],
          native_american_information: applicant_hash['native_american_information'],

          citizen_status: citizen_status_info ? citizen_status_info['citizen_status'] : nil,
          is_resident_post_092296: citizen_status_info ? citizen_status_info['is_resident_post_092296'] : nil,
          is_lawful_presence_self_attested: citizen_status_info ? citizen_status_info['is_lawful_presence_self_attested'] : nil,

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
          is_filing_as_head_of_household: applicant_hash['is_filing_as_head_of_household'],
          is_claimed_as_tax_dependent: applicant_hash['is_claimed_as_tax_dependent'],
          claimed_as_tax_dependent_by: sanitize_claimed_as_tax_dependent_by_params(applicant_hash),

          is_student: applicant_hash.dig('student', 'is_student'),
          student_kind: applicant_hash.dig('student', 'student_kind'),
          student_school_kind: applicant_hash.dig('student', 'student_school_kind'),
          student_status_end_on: applicant_hash.dig('student', 'student_status_end_on'),

          is_refugee: applicant_hash['is_refugee'],
          is_trafficking_victim: applicant_hash['is_trafficking_victim'],

          is_former_foster_care: applicant_hash.dig('foster_care', 'is_former_foster_care'),
          age_left_foster_care: applicant_hash.dig('foster_care', 'age_left_foster_care'),
          foster_care_us_state: applicant_hash.dig('foster_care', 'foster_care_us_state'),
          had_medicaid_during_foster_care: applicant_hash.dig('foster_care', 'had_medicaid_during_foster_care'),

          is_pregnant: applicant_hash.dig('pregnancy_information', 'is_pregnant'),
          is_enrolled_on_medicaid: applicant_hash.dig('pregnancy_information', 'is_enrolled_on_medicaid'),
          is_post_partum_period: applicant_hash.dig('pregnancy_information', 'is_post_partum_period'),
          children_expected_count: applicant_hash.dig('pregnancy_information', 'expected_children_count'),
          pregnancy_due_on: applicant_hash.dig('pregnancy_information', 'pregnancy_due_on'),
          pregnancy_end_on: applicant_hash.dig('pregnancy_information', 'pregnancy_end_on'),

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

          not_eligible_in_last_90_days: applicant_hash.dig('medicaid_and_chip', 'not_eligible_in_last_90_days'),
          denied_on: applicant_hash.dig('medicaid_and_chip', 'denied_on'),
          ended_as_change_in_eligibility: applicant_hash.dig('medicaid_and_chip', 'ended_as_change_in_eligibility'),
          hh_income_or_size_changed: applicant_hash.dig('medicaid_and_chip', 'hh_income_or_size_changed'),
          medicaid_or_chip_coverage_end_date: applicant_hash.dig('medicaid_and_chip', 'medicaid_or_chip_coverage_end_date'),
          ineligible_due_to_immigration_in_last_5_years: applicant_hash.dig('medicaid_and_chip', 'ineligible_due_to_immigration_in_last_5_years'),
          immigration_status_changed_since_ineligibility: applicant_hash.dig('medicaid_and_chip', 'immigration_status_changed_since_ineligibility'),

          addresses: applicant_hash['addresses'],
          emails: applicant_hash['emails'],
          phones: applicant_hash['phones'],
          incomes: sanitize_income_params(applicant_hash['incomes']),
          benefits: sanitize_benefit_params(applicant_hash['benefits']),
          deductions: applicant_hash['deductions'],

          is_medicare_eligible: applicant_hash['is_medicare_eligible'],
          has_insurance: applicant_hash['has_insurance'],
          has_state_health_benefit: applicant_hash['has_state_health_benefit'],
          had_prior_insurance: applicant_hash['had_prior_insurance'],
          age_of_applicant: applicant_hash['age_of_applicant'],
          hours_worked_per_week: applicant_hash['hours_worked_per_week'],
          indian_tribe_member: applicant_hash['indian_tribe_member'] || false,
          tribal_id: applicant_hash['tribal_id'],
          tribal_name: applicant_hash['tribal_name'],
          tribal_state: applicant_hash['tribal_state']
        }
      end
      iap_hash.except!('applicants').merge!(applicants: sanitize_params)
    end

    def sanitize_claimed_as_tax_dependent_by_params(applicant_hash)
      return nil unless applicant_hash['is_claimed_as_tax_dependent']
      claimed_as_tax_dependent_by = applicant_hash['claimed_as_tax_dependent_by']
      claimed_as_tax_dependent_by.instance_of?(Hash) ? claimed_as_tax_dependent_by["person_hbx_id"] : claimed_as_tax_dependent_by
    end

    def sanitize_income_params(incomes)
      incomes.map do |income|
        income["frequency_kind"] = income["frequency_kind"].downcase
        income
      end
    end

    def sanitize_benefit_params(benefits)
      benefits.map do |benefit|
        if benefit["status"]
          benefit["insurance_kind"] = benefit["kind"]
          benefit["kind"] = benefit["status"]
        end

        if benefit['employer'].present?
          benefit['employer_name']
          benefit['employer_id'] = benefit['employer']['employer_id']
        end

        benefit.except("status", "employer")
      end
    end

    def sanitize_person_params(family_member_hash)
      person_hash = family_member_hash['person']
      consumer_role_hash = person_hash["consumer_role"]

      {
        first_name: person_hash['person_name']['first_name'],
        last_name: person_hash['person_name']['last_name'],
        full_name: person_hash['person_name']['full_name'],
        ssn: person_hash['person_demographics']['ssn'],
        no_ssn: person_hash['person_demographics']['no_ssn'] ? "1" : "0",
        gender: person_hash['person_demographics']['gender'],
        dob: person_hash['person_demographics']['dob'],
        date_of_death: person_hash['person_demographics']['date_of_death'],
        dob_check: person_hash['person_demographics']['dob_check'],
        race: "",
        ethnicity: person_hash['person_demographics']['ethnicity'],
        is_incarcerated: consumer_role_hash['is_applying_coverage'] ? person_hash['person_demographics']['is_incarcerated'] : nil,
        tribal_id: person_hash['person_demographics']['tribal_id'],
        tribal_name: person_hash['person_demographics']['tribal_name'],
        tribal_state: person_hash['person_demographics']['tribal_state'],
        language_code: person_hash['person_demographics']['language_code'],
        is_tobacco_user: person_hash['person_health']['is_tobacco_user'],
        is_physically_disabled: person_hash['person_health']['is_physically_disabled'],
        is_applying_for_assistance: person_hash['is_applying_for_assistance'],
        is_homeless: person_hash['is_homeless'] || false, # TODO: update match with primary
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
            # result = validate cv3_family_hash
            # puts "CV validation failed: #{result.errors.to_h}" if result.errors.present?
            load_data cv3_family_hash # unless result.errors.present?
            puts "Ended processing file: #{@filepath}"
            # rescue StandardError => e
            # puts "Error processing file: #{@filepath} , error: #{e.backtrace}"
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
        # migrate_for_mcr
        # TODO: refactor and enable accordingly
        read_directory @dir_name do
          migrate_for_mcr
        end
      end
    end

    def validate(cv3_family_hash)
      AcaEntities::Contracts::Families::FamilyContract.new.call(cv3_family_hash[:family].except(:magi_medicaid_applications))
    end

    def read_directory(directory_name, &block)
      if Rails.env.development?
        Dir.foreach(directory_name) do |filename|
          if File.extname(filename) == '.xml' || File.extname(filename) == ".json"
            @filepath = "#{directory_name}/#{filename}"
            instance_eval(&block) if block_given?
          end
        end
      else
        Dir.foreach(directory_name) do |filename|
          next unless /batch/.match(filename.to_s)
          Dir.foreach("#{directory_name}/#{filename}") do |batch_file|
            if File.extname(batch_file) == '.xml' || File.extname(batch_file) == ".json"
              @filepath = "#{directory_name}/#{filename}/#{batch_file}"
              instance_eval(&block) if block_given?
            end
          end
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
      app_id = build_iap(result_payload["family"]['magi_medicaid_applications'].first.merge!(family_id: @family.id,
                                                                                             benchmark_product_id: BSON::ObjectId.new, years_to_renew: 5))
      fill_applicants_form(app_id, result_payload["family"]['magi_medicaid_applications'].first)
      print "."
    rescue StandardError => e
      puts "E: #{payload[:insuranceApplicationIdentifier]}, f: #{@family.hbx_id}  error: #{e}"
    end

    def fill_applicants_form(app_id, applications)
      applicants_hash = applications[:applicants]
      application = ::FinancialAssistance::Application.where(id: app_id).first

      applicants_hash.each do |applicant|
        persisted_applicant = application.applicants.where(first_name: applicant[:first_name], last_name: applicant[:last_name]).first
        claimed_by = application.applicants.where(ext_app_id: applicant[:claimed_as_tax_dependent_by]).first
        persisted_applicant.is_physically_disabled = applicant[:is_physically_disabled]
        persisted_applicant.is_self_attested_blind = applicant[:is_self_attested_blind]
        persisted_applicant.is_self_attested_disabled = applicant[:is_self_attested_disabled]
        persisted_applicant.is_required_to_file_taxes = applicant[:is_required_to_file_taxes]
        persisted_applicant.tax_filer_kind = applicant[:tax_filer_kind]
        persisted_applicant.is_joint_tax_filing = applicant[:is_joint_tax_filing]
        persisted_applicant.is_filing_as_head_of_household = applicant[:is_filing_as_head_of_household]
        persisted_applicant.is_claimed_as_tax_dependent = applicant[:is_claimed_as_tax_dependent]
        persisted_applicant.claimed_as_tax_dependent_by = claimed_by.try(:id)

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
        persisted_applicant.deductions = applicant[:deductions].collect {|d| d.except("amount_tax_exempt", "is_projected")}
        persisted_applicant.is_medicare_eligible = applicant[:is_medicare_eligible]

        if applicant[:vlp_document].present?
          persisted_applicant.vlp_subject = applicant[:vlp_document]["subject"]
          persisted_applicant.alien_number = applicant[:vlp_document]["alien_number"]
          persisted_applicant.i94_number = applicant[:vlp_document]["i94_number"]
          persisted_applicant.visa_number = applicant[:vlp_document]["visa_number"]
          persisted_applicant.passport_number = applicant[:vlp_document]["passport_number"]
          persisted_applicant.sevis_id = applicant[:vlp_document]["sevis_id"]
          persisted_applicant.naturalization_number = applicant[:vlp_document]["naturalization_number"]
          persisted_applicant.receipt_number = applicant[:vlp_document]["receipt_number"]
          persisted_applicant.citizenship_number = applicant[:vlp_document]["citizenship_number"]
          persisted_applicant.card_number = applicant[:vlp_document]["card_number"]
          persisted_applicant.country_of_citizenship = applicant[:vlp_document]["country_of_citizenship"]
          persisted_applicant.vlp_description = applicant[:vlp_document]["description"]
          persisted_applicant.expiration_date = applicant[:vlp_document]["expiration_date"]
          persisted_applicant.issuing_country = applicant[:vlp_document]["issuing_country"]
        end

        persisted_applicant.has_eligible_medicaid_cubcare = applicant[:not_eligible_in_last_90_days]
        persisted_applicant.medicaid_cubcare_due_on = applicant[:denied_on]
        persisted_applicant.has_eligibility_changed = applicant[:ended_as_change_in_eligibility]
        persisted_applicant.has_household_income_changed = applicant[:hh_income_or_size_changed]
        persisted_applicant.person_coverage_end_on = applicant[:medicaid_or_chip_coverage_end_date]
        persisted_applicant.medicaid_chip_ineligible = applicant[:ineligible_due_to_immigration_in_last_5_years]
        persisted_applicant.immigration_status_changed = applicant[:immigration_status_changed_since_ineligibility]

        ::FinancialAssistance::Applicant.skip_callback(:update, :after, :propagate_applicant)

        unless persisted_applicant.valid?
          # binding.pry
        end
        # persisted_applicant.save!(validate: false)

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

    def validate_applicant_information(*args)
      array = args[0][:params]

      array.each_with_object([]) do  |params, collect|
        collect << "AcaEntities::MagiMedicaid::#{args[0][:class]}".constantize.new(params.except(:kind))
      end
    end
  end
end
# rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Metrics/ClassLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

