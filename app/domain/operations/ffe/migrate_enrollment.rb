# frozen_string_literal: true
require 'aca_entities'
require 'dry/monads'
require 'dry/monads/do'
require 'aca_entities/ffe/operations/mcr_to/enrollment'
require 'aca_entities/ffe/transformers/mcr_to/enrollment'

module Operations
  module Ffe
    # operation to transform mcr data to enroll format
    class MigrateEnrollment
      send(:include, Dry::Monads[:result, :do])
      send(:include, Dry::Monads[:try])

      # @param [ Hash] mcr_enrollment_payload to transform
      # @return [ Hash ] enrollment_hash
      # api public

      attr_reader :payload, :policy_tracking_id, :sanitized_hash

      def call(payload)
        @payload = payload
        @policy_tracking_id = payload[:policyTrackingNumber]

        _migrated = yield existing_policy
        _dont_migrate = yield renaissance_dental
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

      def renaissance_dental
        renaissance_policy = payload[:issuerName] == "Renaissance Dental"
        renaissance_policy ? Failure("Renaissance Dental: #{policy_tracking_id}") : Success(policy_tracking_id)
      end

      def import_enrollment
        transform_payload = ::AcaEntities::FFE::Operations::McrTo::Enrollment.new.call(payload)

        if transform_payload.success?
          enrollment_hash = transform_payload.success.to_h.deep_stringify_keys!
        else
          puts "Transform Failure: Operations::Ffe::MigrateEnrollment: #{policy_tracking_id}: #{transform_payload.failure}"
          return Failure("Transform Failure: Operations::Ffe::MigrateEnrollment: #{policy_tracking_id}: #{transform_payload.failure}")
        end

        @sanitized_hash = sanitize_enrollment_hash(enrollment_hash)

        enrollment = create_hbx_enrollment
        print "."
        Success(enrollment.hbx_id)
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

        if hash["aasm_state"] == "coverage_selected"
          hash["terminated_on"] = nil
        end

        hash["consumer_role_id"] = family.primary_person.consumer_role.id
        hash["household_id"] = family.active_household.id

        hash["coverage_household_id"] = family.active_household.immediate_family_coverage_household.id

        hash["rating_area_id"] = rating_area(hash["rating_area"]).id
        hash.delete("rating_area")
        hash["external_enrollment"] = false

        benefit_coverage_period = find_benefit_coverage_period(hash["effective_on"])
        hash["benefit_coverage_period_id"] = benefit_coverage_period.id
        hash.delete("benefit_coverage_period_reference")

        hash.delete("benefit_package_reference")
        hash.delete("special_enrollment_period_reference")

        hash["created_at"] = hash["timestamp"]["created_at"]
        hash.delete("timestamp")

        hash["hbx_enrollment_members"] = sanitize_enrollment_member_hash(family, hash["hbx_enrollment_members"])
        hash
      end

      def find_benefit_coverage_period(effective_on)
        sponsorship = HbxProfile.current_hbx.try(:benefit_sponsorship)
        sponsorship.benefit_coverage_periods.detect{ |bcp| bcp.start_on ==  effective_on.beginning_of_year }
      end

      def sanitize_enrollment_member_hash(family, member_hash)
        member_hash.inject([]) do |members, m_hash|
          applicant = find_family_member(family, m_hash["family_member_reference"])
          m_hash["applicant_id"] = applicant.id
          m_hash.delete("family_member_reference")
          members << m_hash
        end
      end

      def find_family(external_id)
        result = Operations::Families::Find.new.call(external_app_id: external_id)
        result.success? ? result.success : result
      end

      def find_family_member(family, fm_hash)
        external_person_id = fm_hash["person_hbx_id"]
        person = Person.where(external_person_id: external_person_id).first
        family_member = family.family_members.active.detect { |fam| fam.person_id == person.id}

        coverage_household = family.active_household.immediate_family_coverage_household
        unless coverage_household.coverage_household_members.any? {|c_mem| c_mem.family_member_id == family_member.id}
          raise "coverage household not found"
        else
          family_member
        end
      end

      def find_product(product_hash, year)
        result = Operations::HbxEnrollments::FindProduct.new.call(product_hash, year)
        result.success? ? result.success : result
      end

      def rating_area(rating_area_code)
        BenefitMarkets::Locations::RatingArea.where(exchange_provided_code: "R-#{rating_area_code}", active_year: '2021').first
      end

      def create_hbx_enrollment
        hbx_enrollment = HbxEnrollment.new(sanitized_hash.except("hbx_enrollment_members"))
        hbx_enrollment.hbx_enrollment_members = hbx_enrollment_members
        hbx_enrollment.generate_hbx_signature
        create_state_transition(hbx_enrollment)
        hbx_enrollment.save

        check_duplicate_coverage(hbx_enrollment)

        hbx_enrollment
      end

      def hbx_enrollment_members
        sanitized_hash["hbx_enrollment_members"].inject([]) do |members, hbx_enrollment_member|
          members << HbxEnrollmentMember.new(hbx_enrollment_member)
        end
      end

      def check_duplicate_coverage(new_enrollment)
        family =  Family.find(sanitized_hash["family_id"])
        hbx_enrollments = family.active_household.hbx_enrollments.where(
           {:coverage_kind => sanitized_hash["coverage_kind"],
            :id => {"$ne" => new_enrollment.id},
            :aasm_state.in => ['coverage_selected', 'coverage_terminated'],
            :kind => "individual"}
        )
        overlapping_coverage = hbx_enrollments.select {|enrollment|
         (enrollment.effective_on..enrollment.terminated_on || Date.new(2021,12,31)).cover?(sanitized_hash["effective_on"])
        }
        overlapping_coverage.each do |enrollment|
          if new_enrollment.created_at >= enrollment.created_at
            if enrollment.may_cancel_coverage?
              enrollment.cancel_coverage!
            else
              cancel_term_coverage(enrollment)
            end
          else
            if new_enrollment.may_cancel_coverage?
              new_enrollment.cancel_coverage!
            else
              cancel_term_coverage(new_enrollment)
            end
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
          to_state: enrollment.aasm_state
        )
      end
    end
  end
end
