# frozen_string_literal: true

require 'aca_entities'
require 'dry/monads'
require 'dry/monads/do'
require 'aca_entities/ffe/operations/mcr_to/enrollment'
require 'aca_entities/ffe/transformers/mcr_to/enrollment'
# rubocop:disable Metrics/AbcSize, Style/GuardClause, Metrics/CyclomaticComplexity
module Operations
  module Ffe
    # operation to transform mcr data to enroll format
    class MigrateEnrollment
      include Dry::Monads[:do, :result, :try]

      # @param [ Hash] mcr_enrollment_payload to transform
      # @return [ Hash ] enrollment_hash
      # api public

      attr_reader :payload, :policy_tracking_id, :enrollment_hash, :family

      FAMILYMAP = { "3653661530" => "3654638599", "3653835451" => "3653545566", "3655103341" => "3655669235",
                    "3654647425" => "3656048335", "3655199651" => "3655176192", "3655050863" => "3653739431",
                    "3655446385" => "3654726512", "3655845985" => "3654917025", "3655473710" => "3656046449",
                    "3655221287" => "3703540271", "3656379459" => "3654186542", "3655195010" => "3715498949",
                    "3656281232" => "3720039656", "3656308100" => "3656296751", "3654881326" => "3736090550",
                    "3679195400" => "3753262194", "3655508494" => "3698523219", "3656101873" => "3726489109",
                    "3694631216" => "3752159826", "3691339160" => "3690953787", "3699716118" => "3789998132",
                    "3655320635" => "3942246878", "3654199812" => "3783193340", "3655481814" => "3791987236",
                    "3654189404" => "3814304009", "4061853917" => "4071973876", "3656064729" => "3922175933",
                    "3656240817" => "3866859385", "3656394545" => "3789413969", "3653836120" => "4059628869",
                    "3887243470" => "3921306099", "3656824321" => "4057512462", "3996525167" => "3963681631",
                    "3763371082" => "3655447280", "3655120315" => "3793679309", "3655429746" => "3775505336",
                    "3654370357" => "3770687752", "3655797066" => "3956526075", "3656791057" => "4064839169",
                    "4023970705" => "4007554188", "3809789830" => "4023502228", "3655485373" => "3783529311",
                    "3654478431" => "3747430017", "3654354357" => "3656133587", "3654587217" => "3743174122",
                    "3654935600" => "3706289263", "3655737145" => "3654714693", "3764290138" => "3654745957",
                    "3654265734" => "3878412998", "3796431048" => "3653852422", "3655895410" => "4066027101",
                    "3655646562" => "3795341920", "3655967545" => "3794924231", "3655656463" => "3656490078",
                    "3656865574" => "3730462612", "3656327410" => "3743146491", "3725241030" => "4062488565",
                    "3883632840" => "3909927316", "4013177626" => "4013144552", "4013810941" => "4086876990",
                    "3905775367" => "4110558923" }.freeze

      def call(payload)
        @payload = payload
        @policy_tracking_id = payload[:policyTrackingNumber]

        _migrated = yield existing_policy
        _transformed = yield transform
        enrollment_id = yield import_enrollment

        Success("#{policy_tracking_id} -- #{enrollment_id}")
      rescue StandardError => e
        Failure("Exception: Operations::Ffe::MigrateEnrolllment: #{policy_tracking_id} -- #{e}")
      end

      private

      def existing_policy
        result = Operations::HbxEnrollments::Find.new.call({external_id: policy_tracking_id })
        result.success? ? Failure("Enrollment already migrated: #{policy_tracking_id}") : Success(policy_tracking_id)
      end

      def transform
        transform_payload = ::AcaEntities::FFE::Operations::McrTo::Enrollment.new.call(payload)
        if transform_payload.success?
          @enrollment_hash = transform_payload.success.to_h.deep_stringify_keys!
          Success(policy_tracking_id)
        else
          Failure("Transform Failure: Operations::Ffe::MigrateEnrollment: #{policy_tracking_id}: #{transform_payload.failure}")
        end
      end

      def import_enrollment
        return Success(policy_tracking_id) if skip_enrollment_migration

        validate_enrollment_members
        sanitize_enrollment_hash(enrollment_hash)
        enrollment = create_hbx_enrollment
        print "."
        Success(enrollment.hbx_id)
      end

      def skip_enrollment_migration
        return_success_case1 || return_success_case2 || return_success_case3
      end

      def renaissance_dental
        payload[:issuerName] == "Renaissance Dental"
      end

      def return_success_case1
        renaissance_dental
      end

      def applications_not_migrated
        ["3653661530", "3653835451", "3655103341", "3654647425", "3655199651", "3655050863", "3655446385",
         "3655845985", "3655473710", "3655221287", "3656379459", "3655195010", "3656281232", "3656308100",
         "3654881326", "3679195400", "3655508494", "3656101873", "3694631216", "3691339160", "3699716118",
         "3655320635", "3654199812", "3655481814", "3654189404", "4061853917", "3656064729", "3656240817",
         "3656394545", "3653836120", "3887243470", "3656824321", "3996525167", "3763371082", "3655120315",
         "3655429746", "3654370357", "3655797066", "3656791057", "4023970705", "3809789830", "3655485373",
         "3654478431", "3654354357", "3654587217", "3654935600", "3655737145", "3764290138", "3654265734",
         "3796431048", "3655895410", "3655646562", "3655967545", "3655656463", "3656865574", "3656327410",
         "3725241030", "3883632840", "4013177626"]
      end

      def return_success_case2
        enrollment_hash["aasm_state"] != "coverage_selected" && applications_not_migrated.include?(enrollment_hash["family_hbx_id"])
      end

      def return_success_case3
        members = enrollment_members
        (members.blank? || members.any? { |mem| mem["applicant_id"].nil? }) && enrollment_hash["aasm_state"] != "coverage_selected"
      end

      def validate_enrollment_members
        members = enrollment_hash["hbx_enrollment_members"]
        raise "no enrollment member" if members.blank?

        raise "family member not found" if members.any? { |mem| mem["applicant_id"].nil? }

        members.each do |mem|
          result = family.active_household.coverage_households.any? do |coverage_household|
            coverage_household.coverage_household_members.detect { |c_mem| c_mem.family_member_id == mem["applicant_id"] }
          end

          raise "coverage household not found" unless result
        end
      end

      def enrollment_members
        @family = find_family(enrollment_hash["family_hbx_id"])
        enrollment_hash["hbx_enrollment_members"] = sanitize_enrollment_member_hash(family, enrollment_hash["hbx_enrollment_members"])
      end

      def sanitize_enrollment_hash(hash)
        hash["external_group_identifiers"] = hash["external_group_identifiers"][0]["external_group_identifiers"]

        hash["kind"] = hash["market_place_kind"]
        hash.delete("market_place_kind")

        hash["enrollment_kind"] = hash["enrollment_period_kind"]
        hash.delete("enrollment_period_kind")

        hash["coverage_kind"] = hash["product_kind"]
        hash.delete("product_kind")

        hash["product_reference"].delete("issuer_profile_reference")
        hash["product_reference"]["benefit_market_kind"] = "aca_individual"
        hash["product_reference"]["kind"] = hash["product_reference"]["product_kind"]

        product_hash = hash["product_reference"].slice("hios_id", "benefit_market_kind", "kind")
        active_year = hash["product_reference"]["active_year"]

        product = find_product(product_hash, active_year)
        hash["product_id"] = product.id
        hash.delete("product_reference")

        hash.delete("issuer_profile_reference")
        hash["issuer_profile_id"] = product.issuer_profile.id

        family = find_family(hash["family_hbx_id"])
        hash["family_id"] = family.id
        hash.delete("family_hbx_id")

        hash["terminated_on"] = nil if hash["aasm_state"] == "coverage_selected"

        subscriber = hash["hbx_enrollment_members"].detect {|hbx_m| hbx_m["is_subscriber"] == true}
        hash["consumer_role_id"] = family.family_members.detect {|fm| fm.id == subscriber["applicant_id"]}.person.consumer_role.id
        hash["household_id"] = family.active_household.id

        hash["coverage_household_id"] = family.active_household.immediate_family_coverage_household.id

        hash["rating_area_id"] = rating_area(hash["rating_area"]).id
        hash.delete("rating_area")
        hash["external_enrollment"] = true

        benefit_coverage_period = find_benefit_coverage_period(hash["effective_on"])
        hash["benefit_coverage_period_id"] = benefit_coverage_period.id
        hash.delete("benefit_coverage_period_reference")

        hash.delete("benefit_package_reference")
        hash.delete("special_enrollment_period_reference")

        hash["created_at"] = hash["timestamp"]["created_at"]
        hash.delete("timestamp")

        hash
      end

      def sanitize_enrollment_member_hash(family, member_hash)
        eligible_members = member_hash.reject {|mem|  mem["coverage_end_on"] == mem["coverage_start_on"]}
        member_result = eligible_members.inject([]) do |members, m_hash|
          applicant = find_family_member(family, m_hash)
          m_hash["applicant_id"] = applicant.try(:id)
          m_hash["coverage_end_on"] = nil
          m_hash.delete("family_member_reference")
          members << m_hash
        end
        member_result.reject {|mem| mem["applicant_id"].nil? }
      end

      def find_benefit_coverage_period(effective_on)
        Rails.cache.fetch("benefit_coverage_period_2021", expires_in: 12.hour) do
          sponsorship = HbxProfile.current_hbx.try(:benefit_sponsorship)
          sponsorship.benefit_coverage_periods.detect{ |bcp| bcp.start_on == effective_on.beginning_of_year }
        end
      end

      def find_family(external_id)
        result = Rails.cache.fetch("family_#{external_id}", expires_in: 12.hour) do
          app_id = FAMILYMAP[external_id.to_s] || external_id
          Operations::Families::Find.new.call(external_app_id: app_id)
        end

        if result&.success?
          result.success
        else
          # subscriber = enrollment_hash["hbx_enrollment_members"].detect {|hbx_m| hbx_m["is_subscriber"] == true}
          # ssn = subscriber["family_member_reference"]["ssn"]
          # dob = subscriber["family_member_reference"]["dob"]
          # fname = subscriber["family_member_reference"]["first_name"]
          # lname = subscriber["family_member_reference"]["last_name"]
          #
          # people = if ssn.blank?
          #            Person.where(first_name: /^#{fname}$/i, last_name: /^#{lname}$/i, dob: dob)
          #          else
          #            Person.where(:encrypted_ssn => SymmetricEncryption.encrypt(ssn), :dob => dob)
          #          end
          #
          # if people.count == 1
          #   person = people.first
          #   families = person.families
          # end
          #
          # if families.present? && families.count == 1
          #   return families.first
          # end
          raise "family not found #{external_id}"
        end
      end

      def find_family_member(family, m_hash)
        fm_hash = m_hash["family_member_reference"]
        family_member = family.family_members.active.detect do |mem|
          ssn_dob_match?(mem.person, fm_hash) || info_match?(mem.person,fm_hash) || ext_id_match?(mem.person, fm_hash)
        end

        return unless family_member
        family_member.person.update_attribute(:is_tobacco_user, m_hash["tobacco_use"])
        family_member
      end

      def ssn_dob_match?(person, fm_hash)
        fm_hash["ssn"] &&
          fm_hash["dob"] &&
          person.ssn == fm_hash["ssn"] &&
          person.dob == fm_hash["dob"]
      end

      def info_match?(person,fm_hash)
        fm_hash["last_name"].downcase.strip == person.last_name.downcase.strip &&
          fm_hash["first_name"].downcase.strip == person.first_name.downcase.strip &&
          fm_hash["dob"] == person.dob
      end

      def ext_id_match?(person, fm_hash)
        person.id == person_by_external_id(fm_hash).try(:id)
      end

      def person_by_external_id(fm_hash)
        people = Rails.cache.fetch("person_#{fm_hash['person_hbx_id']}", expires_in: 12.hour) do
          Person.where(external_person_id: fm_hash["person_hbx_id"])
        end

        raise "more than one person found" if people.count > 1

        people.first
      end

      def find_product(product_hash, year)
        result = Rails.cache.fetch("product_#{product_hash['hios_id']}", expires_in: 12.hour) do
          Operations::HbxEnrollments::FindProduct.new.call(product_hash, year)
        end

        raise "product not found" unless result&.success?

        if result&.success?
          result.success
        else
          raise "product not found"
        end
      end

      def rating_area(rating_area_code)
        Rails.cache.fetch("rating_area_R-#{rating_area_code}", expires_in: 12.hour) do
          BenefitMarkets::Locations::RatingArea.where(exchange_provided_code: "R-#{rating_area_code}", active_year: '2021').first
        end
      end

      def create_hbx_enrollment
        hbx_enrollment = HbxEnrollment.new(enrollment_hash.except("hbx_enrollment_members"))
        hbx_enrollment.hbx_enrollment_members = hbx_enrollment_members
        hbx_enrollment.generate_hbx_signature
        create_state_transition(hbx_enrollment)
        hbx_enrollment.save

        check_duplicate_coverage(hbx_enrollment)

        hbx_enrollment
      end

      def hbx_enrollment_members
        enrollment_hash["hbx_enrollment_members"].inject([]) do |members, hbx_enrollment_member|
          members << HbxEnrollmentMember.new(hbx_enrollment_member)
        end
      end

      def check_duplicate_coverage(new_enrollment)
        return unless new_enrollment.coverage_selected?
        family = Family.find(enrollment_hash["family_id"])
        hbx_enrollments = family.active_household.hbx_enrollments.where(
          {:coverage_kind => enrollment_hash["coverage_kind"],
           :id => {"$ne" => new_enrollment.id},
           :aasm_state.in => ['coverage_selected', 'coverage_terminated'],
           :kind => "individual"}
        )
        overlapping_coverage = hbx_enrollments.select do |enrollment|
          enrollment.subscriber.hbx_id == new_enrollment.subscriber.hbx_id &&
            ((enrollment.effective_on..enrollment.terminated_on || Date.new(2021,12,31)).cover?(new_enrollment.effective_on) ||
              (new_enrollment.effective_on < enrollment.effective_on && new_enrollment.coverage_selected? && enrollment.coverage_selected?))
        end
        overlapping_coverage.each do |enrollment|
          if new_enrollment.external_id > enrollment.external_id || new_enrollment.created_at >= enrollment.created_at
            if enrollment.may_cancel_coverage?
              enrollment.cancel_coverage!
            else
              cancel_term_coverage(enrollment)
            end
          elsif new_enrollment.may_cancel_coverage?
            new_enrollment.cancel_coverage!
          else
            cancel_term_coverage(new_enrollment)
          end
        end
      end

      def cancel_term_coverage(enrollment)
        prevs_state = enrollment.aasm_state
        enrollment.update_attributes(aasm_state: "coverage_canceled", terminated_on: nil, termination_submitted_on: nil, terminate_reason: nil)
        enrollment.workflow_state_transitions << WorkflowStateTransition.new(
          from_state: prevs_state,
          to_state: "coverage_canceled"
        )
      end

      def create_state_transition(enrollment)
        enrollment.workflow_state_transitions << WorkflowStateTransition.new(
          from_state: "shopping",
          comment: "external enrollments",
          to_state: enrollment.aasm_state
        )
      end
    end
  end
end
# rubocop:enable Metrics/AbcSize, Style/GuardClause, Metrics/CyclomaticComplexity
