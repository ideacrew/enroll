# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'aca_entities'
require 'aca_entities/ffe/operations/process_mcr_application'
require 'aca_entities/ffe/transformers/mcr_to/family'
require 'aca_entities/atp/transformers/cv/family'
require 'aca_entities/atp/operations/family'
require 'aca_entities/serializers/xml/medicaid/atp'

# rubocop:disable Metrics/AbcSize, Style/GuardClause, Metrics/MethodLength, Metrics/ClassLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
module Operations
  module Ffe
    # operation to transform mcr data to enroll format
    class MigrateApplication
      include Dry::Monads[:do, :result, :try]

      # @param [ Hash] mcr_application_payload to transform
      # @return [ Hash ] family_hash
      # api public

      attr_reader :external_application_id, :payload, :family, :family_hash, :application, :tax_household_params

      def call(app_payload)
        @payload = app_payload
        @external_application_id = app_payload[:insuranceApplicationIdentifier]

        # ::FinancialAssistance::Application.all.create_indexes
        # Family.all.create_indexes
        # return "already migratred" if migrated.include?(external_application_id.to_s)
        # migrated_fam = Family.where(external_app_id: external_application_id.to_s).first
        # return if migrated_fam.present?
        # if migrated_fam.present?
        #   if migrated_fam.valid?
        #     if migrated_fam.primary_applicant.person.is_applying_for_assistance
        #       migrated_application = ::FinancialAssistance::Application.where(family_id: migrated_fam.id).first
        #       if migrated_application.present? && !migrated_application.valid?
        #         puts "deleting application & family "
        #         migrated_fam.delete
        #         migrated_application.delete
        #       end
        #     else
        #       return
        #     end
        #   else
        #     puts "Deleting family "
        #     migrated_fam.delete
        #   end
        # end

        _dup = yield application_dup
        _migrated = yield application_migrated
        _application = yield import_application

        Success(external_application_id.to_s)
      rescue StandardError => e
        Failure("Exception: Operations::Ffe::MigrateApplication: #{external_application_id} -- #{e}")
      end

      private

      def application_dup
        # migrating list
        # ["3654638599", "3653545566", "3655669235", "3656048335", "3655176192", "3653739431", "3654726512", "3654917025",
        #  "3656046449", "3703540271", "3654186542", "3715498949", "3720039656", "3656296751", "3736090550", "3753262194",
        #  "3698523219", "3726489109", "3752159826", "3690953787", "3789998132", "3942246878", "3783193340", "3791987236",
        #  "3814304009", "4071973876", "3922175933", "3866859385", "3789413969", "4059628869", "3921306099", "4057512462",
        #  "3963681631", "3655447280", "3793679309", "3775505336", "3770687752", "3956526075", "4064839169", "4007554188",
        #  "4023502228", "3783529311","3747430017", "3656133587", "3743174122", "3706289263", "3654714693", "3654745957",
        # "3878412998", "3653852422", "4066027101", "3795341920", "3654714693", "3794924231", "3656490078", "3730462612",
        # "3706289263", "3656133587", "3743174122", "3743146491", "4062488565", "3747430017", "3656490078", "3743146491",
        # "3730462612", "3654745957", "3909927316", "4066027101", "3909927316", "3794924231", "4013144552", "4013144552",
        # "4062488565", "3653852422", "3878412998", "3795341920"]
        # dups in 9/1 missing in new list 10/18
        # 4061853917
        # 3656240817
        # 3656791057
        # 3809789830
        # 3764290138
        # 3725241030
        # 4013177626
        # dups in 10/18
        # 4120932891
        # 4128449232
        # 4094956800
        # 3905775367
        # 4108730061
        # 4126008667
        # 4118339510
        # 4088055106
        # 4108125254
        # 4075486360
        # 4013810941
        # 4075419231
        # dup updated in 10/1
        #  3655195010
        dups = ["3653661530", "3653835451", "3655103341", "3654647425", "3655199651", "3655050863", "3655446385",
                "3655845985", "3655473710", "3655221287", "3656379459", "3655195010", "3656281232", "3656308100",
                "3654881326", "3679195400", "3655508494", "3656101873", "3694631216", "3691339160", "3699716118",
                "3655320635", "3654199812", "3655481814", "3654189404", "4061853917", "3656064729", "3656240817",
                "3656394545", "3653836120", "3887243470", "3656824321", "3996525167", "3763371082", "3655120315",
                "3655429746", "3654370357", "3655797066", "3656791057", "4023970705", "3809789830", "3655485373",
                "3654478431", "3654354357", "3654587217", "3654935600", "3655737145", "3764290138", "3654265734",
                "3796431048", "3655895410", "3655646562", "3655967545", "3655656463", "3656865574", "3656327410",
                "3725241030", "3883632840", "4013177626", "4013810941", "3905775367"]
        if dups.include?(external_application_id.to_s)
          raise "Duplicate Application: #{external_application_id}"
        else
          Success("")
        end
      end

      def application_migrated
        result = Operations::Families::Find.new.call(external_app_id: external_application_id)
        result.success? ? Failure("Family already migrated: #{external_application_id}") : Success("")
      end

      def import_application
        transform_payload = Operations::Ffe::TransformApplication.new.call(payload)

        if transform_payload.success?
          @family_hash = transform_payload.success.to_h.deep_stringify_keys!.merge!(external_app_id: external_application_id)
        else
          puts "Transform Failure: Operations::Ffe::MigrateApplication: #{external_application_id}: #{transform_payload.failure}"
          return Failure("Transform Failure: Operations::Ffe::MigrateApplication: #{external_application_id}: #{transform_payload.failure}")
        end

        if family_hash.empty?
          puts "Family Hash Empty: Operations::Ffe::MigrateApplication:: #{external_application_id}"
          return Failure("Family Hash Empty: Operations::Ffe::MigrateApplication:: #{external_application_id}")
        end

        return Success(external_application_id) if Family.where(external_app_id: external_application_id).present?

        build_family
        if family_hash['magi_medicaid_applications'].present?
          @tax_household_params = family_hash["households"][0]["tax_households"]
          application_result = build_iap(family_hash['magi_medicaid_applications'].first.merge!(family_id: family.id, benchmark_product_id: HbxProfile.current_hbx.benefit_sponsorship.current_benefit_coverage_period.slcsp))

          # Family.create_indexes  TODO: index
          # ::FinancialAssistance::Application.create_indexes #TODO: index
          if application_result.success
            application_id = application_result.success
            @application = ::FinancialAssistance::Application.find(application_id)

            fill_applicants_form
            fix_iap_relationship
            build_eligibility_determination
            fill_application_form
            application.import!
            application.save!
          else
            # binding.pry
            puts "IAP Application Failure: Operations::Ffe::MigrateApplication: #{external_application_id}: #{application_result.failure}"
            return Failure("IAP Application Failure: Operations::Ffe::MigrateApplication: #{external_application_id}: #{application_result.failure}")
          end
        end
        # puts "Success: #{external_application_id}"
        print "."
        Success(application)
      end

      def fill_application_form
        app_hash = family_hash['magi_medicaid_applications'].first

        application.parent_living_out_of_home_terms = app_hash["parent_living_out_of_home_terms"]
        application.attestation_terms = app_hash["parent_living_out_of_home_terms"] ? true : nil #default value
        # application.is_requesting_voter_registration_application_in_mail = true # default value
        application.report_change_terms = app_hash['report_change_terms']
        application.medicaid_terms = app_hash['medicaid_terms']
        application.is_renewal_authorized = app_hash['is_renewal_authorized']
        application.years_to_renew = app_hash['years_to_renew']
        application.renewal_base_year = 2021 + app_hash['years_to_renew'].to_i
      end

      def build_eligibility_determination
        family_hash['households'][0]['tax_households'].collect do |params|
          sanitized_params = sanitize_eligibility_params(params)
          ed = application.eligibility_determinations.new(sanitized_params)
          ext_applicant_ids = params["tax_household_members"].collect {|a| a.dig("family_member_reference", "family_member_hbx_id")}

          application.applicants.where(:ext_app_id.in => ext_applicant_ids).each do |applicant|
            applicant.assign_attributes(eligibility_determination_id: ed.id)
          end
        end
      end

      def sanitize_eligibility_params(params)
        { "max_aptc" => {"cents" => (100 * params.dig("eligibility_determinations", 0, "max_aptc")["cents"].to_r).to_f, "currency_iso" => "USD"},
          "csr_percent_as_integer" => 0,
          "source" => "Ffe",
          "aptc_csr_annual_household_income" => Monetize.parse(params.dig("eligibility_determinations", 0, "aptc_csr_annual_household_income")).to_f,
          "aptc_annual_income_limit" => Monetize.parse(params.dig("eligibility_determinations", 0, "aptc_annual_income_limit")).to_f,
          "csr_annual_income_limit" => Monetize.parse(params.dig("eligibility_determinations", 0, "csr_annual_income_limit")).to_f,
          "effective_starting_on" => params["start_date"],
          "effective_ending_on" => params["end_date"],
          "is_eligibility_determined" => params["is_eligibility_determined"],
          "hbx_assigned_id" => nil,
          "determined_at" => params["start_date"] }
      end

      def fix_iap_relationship
        @matrix = application.build_relationship_matrix
        @missing_relationships = application.find_missing_relationships(@matrix)
        @all_relationships = application.find_all_relationships(@matrix)
        missing_relationships = []
        all_relationships = []
        @missing_relationships.each do |rel|
          from_relation = rel.first[0]
          to_relation = rel.first[1]
          next if application.relationships.where(applicant_id: from_relation, relative_id: to_relation).present?
          from_applicant = application.applicants.where(id: from_relation).first
          to_applicant = application.applicants.where(id: to_relation).first
          from_family_member = ::FamilyMember.find(from_applicant.family_member_id)
          to_family_member = ::FamilyMember.find(to_applicant.family_member_id)
          member_hash = family_hash["family_members"].select { |member| member["hbx_id"] == from_family_member.external_member_id}.first
          relationship = member_hash["person"]["person_relationships"].select { |p_rel| p_rel["relative"]["hbx_id"] == to_family_member.external_member_id }.first
          relation_kind = relationship.present? ? relationship["kind"] : "unrelated"
          missing_relationships << ::FinancialAssistance::Relationship.new({kind: relation_kind, applicant_id: from_applicant.id, relative_id: to_applicant.id})
        end
        application.relationships << missing_relationships if missing_relationships.present?

        @all_relationships.each do |all_rel|
          next if all_rel[:relation].present?
          relationships = application.relationships
          from_relation = all_rel[:applicant]
          to_relation = all_rel[:relative]
          found_relationship = relationships.where(applicant_id: from_relation,relative_id: to_relation).first
          next if found_relationship.present? && found_relationship.kind.present?
          inverse_relationship = relationships.where(applicant_id: to_relation,relative_id: from_relation).first
          if inverse_relationship.present?
            relation = ::FinancialAssistance::Relationship::INVERSE_MAP[inverse_relationship.kind]
            all_relationships << ::FinancialAssistance::Relationship.new({kind: relation, applicant_id: from_relation, relative_id: to_relation})
            next
          end
          from_applicant = application.applicants.find(from_relation)
          to_applicant = application.applicants.find(to_relation)
          from_family_member = ::FamilyMember.find(from_applicant.family_member_id)
          to_family_member = ::FamilyMember.find(to_applicant.family_member_id)
          member_hash = family_hash["family_members"].select { |member| member["hbx_id"] == from_family_member.external_member_id}.first
          relationship = member_hash["person"]["person_relationships"].select { |p_rel| p_rel["relative"]["hbx_id"] == to_family_member.external_member_id }.first
          relation_kind = relationship.present? ? relationship["kind"] : "unrelated"
          relation = ::FinancialAssistance::Relationship::INVERSE_MAP[relation_kind]
          if found_relationship.present?
            found_relationship.update_attributes(kind: relation)
          else
            all_relationships << ::FinancialAssistance::Relationship.new({kind: relation, applicant_id: from_applicant.id, relative_id: to_applicant.id})
          end
        end
        application.relationships << all_relationships
        application.save!
      end

      def build_iap(iap_hash)
        sanitize_iap_hash = sanitize_applicant_params(iap_hash)
        ::FinancialAssistance::Operations::Application::Create.new.call(params: sanitize_iap_hash)
      end

      def build_family
        @family = Family.new(family_hash.except('hbx_id', 'foreign_keys', 'broker_accounts', 'magi_medicaid_applications', 'family_members',
                                                'households'))

        family_hash['family_members'].sort_by { |a| a["is_primary_applicant"] ? 0 : 1 }.each do |family_member_hash|
          # puts "sorting member primary: #{family_member_hash['is_primary_applicant']}"
          create_member(family_member_hash)
        end
        build_tax_households
        add_broker_accounts(family, family_hash)
        family.save!
      end

      def build_tax_households
        @family_members_mappings = family.family_members.collect {|fm| { fm.external_member_id.to_s => fm.id }}
        household = family.active_household

        family_hash['households'][0]['tax_households'].collect do |tax_household_hash|
          params = sanitize_tax_params(tax_household_hash)
          household.tax_households.new(params)
        end
      end

      def sanitize_tax_params(tax_household_hash)
        {
          "allocated_aptc" => {"cents" => (100 * tax_household_hash["allocated_aptc"]["cents"].to_r).to_f, "currency_iso" => "USD"},
          "is_eligibility_determined" => tax_household_hash['is_eligibility_determined'],
          "effective_starting_on" => tax_household_hash['start_date'],
          "effective_ending_on" => tax_household_hash['end_date'],
          "tax_household_members" =>
          tax_household_hash['tax_household_members'].collect do |thhm|
            {
              "applicant_id" => @family_members_mappings.collect {|fm| fm[thhm.dig("family_member_reference", "family_member_hbx_id")]}.compact.first,
              "is_ia_eligible" => thhm.dig("product_eligibility_determination", "is_ia_eligible"),
              "is_subscriber" => thhm["is_subscriber"]
            }
          end,
          "eligibility_determinations" =>
          tax_household_hash['eligibility_determinations'].collect do |ed|
            { "max_aptc" => {"cents" => (100 * ed["max_aptc"]["cents"].to_r).to_f, "currency_iso" => "USD"},
              "csr_percent_as_integer" => 0,
              "source" => "Ffe",
              "aptc_csr_annual_household_income" => Monetize.parse(ed["aptc_csr_annual_household_income"]).to_f,
              "aptc_annual_income_limit" => Monetize.parse(ed["aptc_annual_income_limit"]).to_f,
              "csr_annual_income_limit" => Monetize.parse(ed["csr_annual_income_limit"]).to_f,
              "determined_at" => ed["start_date"] || Date.today }
          end
        }
      end

      def create_member(family_member_hash)
        person_params = sanitize_person_params(family_member_hash)
        person_result = create_or_update_person(person_params)
        if person_result.success?
          @person = person_result.success
          @person.update_attributes(is_applying_for_assistance: person_params[:is_applying_for_assistance], indian_tribe_member: person_params[:indian_tribe_member])
          @family_member = create_or_update_family_member(@person, family_member_hash)
          consumer_role_params = family_member_hash['person']['consumer_role']
          consumer_role_result = create_or_update_consumer_role(consumer_role_params.merge(is_consumer_role: true), @family_member)
          consumer_role = consumer_role_result.success
          consumer_role.contact_method = consumer_role_params["contact_method"]
          consumer_role.language_preference = consumer_role_params["language_preference"]
          consumer_role.import!
          create_or_update_vlp_document(consumer_role_params["vlp_documents"], @person) if consumer_role_params["vlp_documents"].present?
        else
          raise "family member person not found"
        end
      end

      def create_or_update_person(person_params)
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

      def create_or_update_family_member(person, family_member_hash)
        family_member = family.family_members.detect { |fm| fm.person_id.to_s == person.id.to_s }
        return family_member if family_member && (family_member_hash.key?(:is_active) ? family_member.is_active == family_member_hash[:is_active] : true)

        fm_attr = { is_primary_applicant: family_member_hash['is_primary_applicant'],
                    is_consent_applicant: family_member_hash['is_consent_applicant'],
                    is_coverage_applicant: family_member_hash['is_coverage_applicant'],
                    is_active: family_member_hash['is_active'] }

        external_member_id = family_member_hash['hbx_id']

        if family_member_hash['is_primary_applicant']
          family_member = @family.add_family_member(person, fm_attr)
          create_or_update_relationship(person, family_member_hash['person']['person_relationships'][0]['kind'])
        else
          create_or_update_relationship(person, family_member_hash['person']['person_relationships'][0]['kind'])
          family_member = @family.add_family_member(person, fm_attr)
        end

        family_member.external_member_id = external_member_id
        external_person_id = external_person_hbx_id(external_member_id)
        existing_external_person = Person.where(external_person_id: external_person_id).first

        if existing_external_person.present? && existing_external_person.hbx_id != person.hbx_id
          person.update_attributes(external_person_id: "#{external_person_id}_#{external_application_id}")
        else
          person.update_attributes(external_person_id: external_person_id)
        end
        family_member.save!
        @family.save!

        family_member
      end

      def external_person_hbx_id(external_member_id)
        member_hash = family_hash.dig("households", 0, "coverage_households", 0, "coverage_household_members")
        member = member_hash.detect { |m| m["family_member_reference"]["family_member_hbx_id"] == external_member_id }
        member.present? ? member["family_member_reference"]["person_hbx_id"] : nil
      end

      def add_broker_accounts(family, family_hash)
        return unless family_hash['broker_accounts'].present?
        family_hash['broker_accounts'].each do |account|
          start_on = account['start_on']
          npn = account['broker_role_reference']['npn']
          broker_role = BrokerRole.find_by_npn(npn)
          next unless broker_role
          family.broker_agency_accounts.new(benefit_sponsors_broker_agency_profile_id: broker_role.broker_agency_profile.id, writing_agent_id: broker_role.id, start_on: start_on, is_active: true)
        end
      end

      def create_or_update_vlp_document(vlp_params, person)
        return unless vlp_params.present?
        vlp_params.each do |vlp|
          result = Operations::People::CreateOrUpdateVlpDocument.new.call(params: { applicant_params: vlp, person: person })
          vlp_document = result.success
          vlp_document.update_attributes!(status: "verified")
        end
      end

      def create_or_update_relationship(person, relationship_kind)
        @primary_person = @family.primary_person
        exiting_relationship = @primary_person.person_relationships.detect { |rel| rel.relative_id.to_s == person.id.to_s }
        return if exiting_relationship && exiting_relationship.kind == relationship_kind

        @primary_person.ensure_relationship_with(person, relationship_kind)
      end

      def same_address_with_primary(family_member)
        member = family_member.person
        compare_keys = ["address_1", "address_2", "city", "state", "zip"]
        member.is_homeless? == @primary_person.is_homeless? &&
          member.is_temporarily_out_of_state? == @primary_person.is_temporarily_out_of_state? && member.home_address && @primary_person.home_address &&
          member.home_address.attributes.select {|k, _v| compare_keys.include? k} == @primary_person.home_address.attributes.select do |k, _v|
            compare_keys.include? k
          end
      end

      def sanitize_applicant_params(iap_hash)
        applicants_hash = iap_hash['applicants']
        sanitize_params = []
        tax_household_member_params = tax_household_params.collect do |p|
          p['tax_household_members'].collect do |t|
            {t.dig("family_member_reference","family_member_hbx_id").to_s => t.dig("product_eligibility_determination", "is_ia_eligible").to_s}
          end
        end.flatten

        applicants_hash.sort_by { |a| a["is_primary_applicant"] ? 0 : 1 }.each do |applicant_hash|
          family_member = family.family_members.select do |fm|
            fm.external_member_id == applicant_hash["family_member_reference"]["family_member_hbx_id"]
          end.first

          is_ia_eligible = tax_household_member_params.find {|fm| fm[family_member.external_member_id]}
          citizen_status_info = applicant_hash['citizenship_immigration_status_information']
          native_american_info = applicant_hash['native_american_information']
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
            ethnicity: family_member.person.ethnicity,
            race: applicant_hash['demographic']['race'],
            is_veteran_or_active_military: applicant_hash['demographic']['is_veteran_or_active_military'],
            is_vets_spouse_or_child: applicant_hash['demographic']['is_vets_spouse_or_child'],
            same_with_primary: same_address_with_primary(family_member),
            is_incarcerated: applicant_hash['is_applying_coverage'] ? family_member.person.is_incarcerated : nil,
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
            # student_school_kind: applicant_hash.dig('student', 'student_school_kind'),  # disable : no respective key found in inbound payloads from atp & mcr
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
            pregnancy_due_on: nil,
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
            has_american_indian_alaskan_native_income: applicant_hash['has_american_indian_alaskan_native_income'],
            has_enrolled_health_coverage: applicant_hash['has_enrolled_health_coverage'],
            has_eligible_health_coverage: applicant_hash['has_eligible_health_coverage'],

            not_eligible_in_last_90_days: applicant_hash.dig('medicaid_and_chip', 'denied_on') ? applicant_hash.dig('medicaid_and_chip', 'not_eligible_in_last_90_days') : false,
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
            indian_tribe_member: native_american_info['indian_tribe_member'],
            tribal_id: native_american_info['tribal_id'],
            tribal_name: native_american_info['tribal_name'],
            tribal_state: native_american_info['tribal_state'],
            health_service_eligible: native_american_info['health_service_eligible'],
            health_service_through_referral: native_american_info['health_service_through_referral'],

            is_ia_eligible: is_ia_eligible.nil? ? false : is_ia_eligible.values[0],
            is_medicaid_chip_eligible: nil,
            is_non_magi_medicaid_eligible: nil,
            is_totally_ineligible: nil,
            is_without_assistance: nil
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
          if income['employer'].present?
            income['employer_name'] = income['employer']['employer_name']
            income['employer_id'] = income['employer']['employer_id']
            income['employer_phone'] = income['employer']['employer_phone']
          end
          income.except("employer")
        end
      end

      def sanitize_benefit_params(benefits)
        benefits.map do |benefit|
          if benefit["status"]
            benefit["insurance_kind"] = benefit["kind"]
            benefit["kind"] = benefit["status"]
          end

          if benefit['employer'].present?
            benefit['employer_name'] = benefit['employer']['employer_name']
            benefit['employer_id'] = benefit['employer']['employer_id']
            benefit['employer_phone'] =  benefit['employer']['employer_phone']
          end

          benefit.except("status", "employer")
        end
      end

      def sanitize_person_params(family_member_hash)
        person_hash = family_member_hash['person']
        consumer_role_hash = person_hash["consumer_role"]

        {
          first_name: person_hash['person_name']['first_name'],
          middle_name: person_hash['person_name']['middle_name'],
          last_name: person_hash['person_name']['last_name'],
          full_name: person_hash['person_name']['full_name'],
          ssn: person_hash['person_demographics']['ssn'],
          no_ssn: person_hash['person_demographics']['ssn'].nil? ? "1" : "0",
          gender: person_hash['person_demographics']['gender'],
          dob: person_hash['person_demographics']['dob'],
          date_of_death: person_hash['person_demographics']['date_of_death'],
          dob_check: person_hash['person_demographics']['dob_check'],
          race: "",
          ethnicity: person_hash['person_demographics']['ethnicity'],
          is_incarcerated: consumer_role_hash['is_applying_coverage'] ? person_hash['person_demographics']['is_incarcerated'] : nil,
          indian_tribe_member: person_hash['person_demographics']['indian_tribe_member'],
          tribal_id: person_hash['person_demographics']['tribal_id'],
          tribal_name: person_hash['person_demographics']['tribal_name'],
          tribal_state: person_hash['person_demographics']['tribal_state'],
          language_code: person_hash['person_demographics']['language_code'],
          is_tobacco_user: person_hash['person_health']['is_tobacco_user'],
          is_physically_disabled: person_hash['person_health']['is_physically_disabled'],
          is_applying_for_assistance: person_hash['is_applying_for_assistance'],
          is_homeless: person_hash['is_homeless'] || false, # TODO: update match with primary
          is_temporarily_out_of_state: person_hash['is_temporarily_out_of_state'] || false,
          age_off_excluded: person_hash['age_off_excluded'],
          is_active: person_hash['is_active'],
          is_disabled: person_hash['is_disabled'],
          individual_market_transitions: person_hash['individual_market_transitions'],
          verification_types: person_hash['verification_types'],
          addresses: person_hash['addresses'].nil? ? [] : person_hash['addresses'],
          emails: person_hash['emails'],
          phones: person_hash['phones']
        }
      end

      def fill_applicants_form
        applicants_hash = family_hash['magi_medicaid_applications'].first[:applicants]
        applicants_hash.each do |applicant|

          persisted_applicant = if applicant[:person_hbx_id]
                                  application.applicants.where(person_hbx_id: applicant[:person_hbx_id]).first
                                else
                                  application.applicants.where(first_name: applicant[:first_name], last_name: applicant[:last_name]).first
                                end

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
          # persisted_applicant.student_school_kind = applicant[:student_school_kind] # disable : no respective key found in inbound payloads from atp & mcr
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
          persisted_applicant.has_american_indian_alaskan_native_income = applicant[:has_american_indian_alaskan_native_income]
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

          if persisted_applicant.eligible_immigration_status
            persisted_applicant.medicaid_chip_ineligible = applicant[:ineligible_due_to_immigration_in_last_5_years]
            persisted_applicant.immigration_status_changed = applicant[:immigration_status_changed_since_ineligibility]
          end

          persisted_applicant.is_ia_eligible = applicant[:is_ia_eligible] || false
          persisted_applicant.is_medicaid_chip_eligible = false
          persisted_applicant.is_non_magi_medicaid_eligible = false
          persisted_applicant.is_totally_ineligible = false
          persisted_applicant.is_without_assistance = false

          #'Did this person have coverage through a job (for example, a parent's job) that ended in the last 3 months?*' (conditional question for children under 18 or 19)
          persisted_applicant.has_dependent_with_coverage = false if persisted_applicant.age_on(TimeKeeper.date_of_record) < 19
          #persisted_applicant.dependent_job_end_on = nil

          persisted_applicant.is_veteran_or_active_military = applicant[:is_veteran_or_active_military]
          persisted_applicant.is_vets_spouse_or_child = applicant[:is_vets_spouse_or_child]
          ::FinancialAssistance::Applicant.skip_callback(:update, :after, :propagate_applicant, raise: false)

          # unless persisted_applicant.valid?
          #   binding.pry
          # end
          # persisted_applicant.save!(validate: false)

          # unless persisted_applicant.valid?
          # binding.pry
          # end

          persisted_applicant.save!
          ::FinancialAssistance::Applicant.set_callback(:update, :after, :propagate_applicant, raise: false)
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
end
# rubocop:enable Metrics/AbcSize, Style/GuardClause, Metrics/MethodLength, Metrics/ClassLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
