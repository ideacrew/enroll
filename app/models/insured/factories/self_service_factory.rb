# frozen_string_literal: true

module Insured
  module Factories
    class SelfServiceFactory
      include L10nHelper
      extend ::FloatHelper
      include ::FloatHelper
      extend Acapi::Notifiers
      attr_accessor :document_id, :enrollment_id, :family_id, :product_id, :qle_id, :sep_id

      def initialize(args)
        self.document_id   = args[:document_id] || nil
        self.enrollment_id = args[:enrollment_id] || nil
        self.family_id     = args[:family_id] || nil
        self.product_id    = args[:product_id] || nil
        self.qle_id        = args[:qle_id] || nil
        self.sep_id        = args[:sep_id] || nil
      end

      def self.find(enrollment_id, family_id)
        new({enrollment_id: enrollment_id, family_id: family_id}).build_form_params
      end

      def validate_rating_address
        family = Family.where(id: family_id).first
        primary_person = family.primary_person
        primary_person_address = primary_person.rating_address
        rating_area = ::BenefitMarkets::Locations::RatingArea.rating_area_for(primary_person_address) if primary_person_address.present?
        if rating_area.nil?
          [false, l10n("insured.out_of_state_error_message")]
        else
          [true, nil]
        end
      end

      def self.term_or_cancel(enrollment_id, term_date, term_or_cancel, cancellation_reason)
        enrollment = HbxEnrollment.find(BSON::ObjectId.from_string(enrollment_id))
        enrollment.term_or_cancel_enrollment(enrollment, term_date, cancellation_reason)
        return unless term_or_cancel == 'cancel'

        transmit_flag = true
        notify(
          "acapi.info.events.hbx_enrollment.terminated",
          {
            :reply_to => "#{Rails.application.config.acapi.hbx_id}.#{Rails.application.config.acapi.environment_name}.q.glue.enrollment_event_batch_handler",
            "hbx_enrollment_id" => @enrollment_id,
            "cancellation_reason" => cancellation_reason,
            "enrollment_action_uri" => "urn:openhbx:terms:v1:enrollment#terminate_enrollment",
            "is_trading_partner_publishable" => transmit_flag
          }
        )
      end

      def self.update_aptc(enrollment_id, applied_aptc_amount, exclude_enrollments_list: nil, elected_aptc_pct: nil)
        # field :elected_aptc_pct, type: Float, default: 0.0
        # field :applied_aptc_amount, type: Money, default: 0.0
        enrollment = HbxEnrollment.find(BSON::ObjectId.from_string(enrollment_id))

        new_effective_date = Insured::Factories::SelfServiceFactory.find_enrollment_effective_on_date(TimeKeeper.date_of_record.in_time_zone('Eastern Time (US & Canada)'), enrollment.effective_on).to_date
        reinstatement = Enrollments::Replicator::Reinstatement.new(enrollment, new_effective_date, applied_aptc_amount).build

        drop_invalid_enrollment_members(reinstatement) if EnrollRegistry[:check_enrollment_member_eligibility].feature.is_enabled
        can_renew = ::Operations::Products::ProductOfferedInServiceArea.new.call({enrollment: reinstatement})

        unless can_renew.success?
          log("ERROR in SelfServiceFactory: #{can_renew.failure}, cannot create reinstatement enrollment. person_hbx_id: #{enrollment.family.primary_person.hbx_id}, enrollment_hbx_id: #{enrollment.hbx_id}")
          raise
        end

        reinstatement.save!

        if EnrollRegistry.feature_enabled?(:temporary_configuration_enable_multi_tax_household_feature)
          mthh_update_enrollment_for_aptcs(new_effective_date, reinstatement, elected_aptc_pct.to_f, exclude_enrollments_list)
        else
          update_enrollment_for_apcts(reinstatement, applied_aptc_amount)
        end

        reinstatement.select_coverage!
      end

      def self.drop_invalid_enrollment_members(reinstatement)
        @invalid_family_member_ids = []

        reinstatement.family.active_family_members.each do |fm|
          @invalid_family_member_ids << fm.id if fm.person.consumer_role.is_applying_coverage == false || fm.person.is_incarcerated == true || ConsumerRole::INELIGIBLE_CITIZEN_VERIFICATION.include?(fm.person.citizen_status)
        end

        dropped_member_ids(reinstatement)

        @invalid_family_member_ids.flatten.uniq.compact.each do |id|
          enrollment_member = reinstatement.hbx_enrollment_members.select{|em| em.applicant_id.to_s == id.to_s}.first
          enrollment_member.delete if enrollment_member.present?
        end
      end

      def self.dropped_member_ids(reinstatement)
        all_family_member_ids = reinstatement.family.active_family_members.map(&:id)
        reinstatement_family_member_ids = reinstatement.hbx_enrollment_members.map(&:applicant_id)

        @invalid_family_member_ids << (all_family_member_ids | reinstatement_family_member_ids) - (all_family_member_ids & reinstatement_family_member_ids)
      end

      def self.update_child_care_subsidy_amount_for(enrollment)
        cost_calculator = enrollment.build_plan_premium(qhp_plan: enrollment.product, elected_aptc: enrollment.applied_aptc_amount, apply_aptc: true)
        enrollment.update(eligible_child_care_subsidy: cost_calculator.total_childcare_subsidy_amount)
      end

      def self.mthh_update_enrollment_for_aptcs(new_effective_date, reinstatement, elected_aptc_pct, exclude_enrollments_list)
        result = ::Operations::PremiumCredits::FindAptc.new.call({
                                                                   hbx_enrollment: reinstatement,
                                                                   effective_on: new_effective_date,
                                                                   exclude_enrollments_list: exclude_enrollments_list
                                                                 })
        return result unless result.success?

        aggregate_aptc_amount = result.value!
        ehb_premium = reinstatement.total_ehb_premium

        applied_aptc_amount = float_fix([(aggregate_aptc_amount * elected_aptc_pct), ehb_premium].min)

        reinstatement.update_attributes(elected_aptc_pct: elected_aptc_pct, applied_aptc_amount: applied_aptc_amount, aggregate_aptc_amount: aggregate_aptc_amount, ehb_premium: ehb_premium)
        update_child_care_subsidy_amount_for(reinstatement)
      end

      def self.update_enrollment_for_apcts(reinstatement, applied_aptc_amount, age_as_of_coverage_start: false)
        applicable_aptc_by_member = member_level_aptc_breakdown(reinstatement, applied_aptc_amount, age_as_of_coverage_start: age_as_of_coverage_start)
        cost_decorator = UnassistedPlanCostDecorator.new(reinstatement.product, reinstatement, applied_aptc_amount)
        reinstatement.hbx_enrollment_members.each do |enrollment_member|
          member_aptc_value = applicable_aptc_by_member[enrollment_member.applicant_id.to_s]
          next enrollment_member unless member_aptc_value
          member_ehb_premium = cost_decorator.member_ehb_premium(enrollment_member)

          if member_aptc_value > member_ehb_premium
            member_aptc_value = round_down_float_two_decimals(member_aptc_value)
          else
            member_aptc_value
          end

          enrollment_member.update_attributes!(applied_aptc_amount: member_aptc_value)
        end
        max_applicable_aptc = if EnrollRegistry[:apply_aggregate_to_enrollment].feature.is_enabled
                                tax_household = reinstatement.family.active_household.latest_tax_household_with_year(reinstatement.effective_on.year)
                                tax_household.monthly_max_aptc(reinstatement, reinstatement.effective_on)
                              else
                                eli_fac_obj = ::Factories::EligibilityFactory.new(reinstatement.id, reinstatement.effective_on)
                                eli_fac_obj.fetch_max_aptc
                              end

        cd_total_aptc = cost_decorator.total_aptc_amount
        reinstatement.update_attributes!(elected_aptc_pct: (cd_total_aptc / max_applicable_aptc), applied_aptc_amount: cd_total_aptc, aggregate_aptc_amount: max_applicable_aptc)
        update_child_care_subsidy_amount_for(reinstatement)
      end

      def self.member_level_aptc_breakdown(new_enrollment, applied_aptc_amount, age_as_of_coverage_start: false)
        applicable_aptc = fetch_applicable_aptc(new_enrollment, applied_aptc_amount, new_enrollment.effective_on)
        eli_fac_obj = ::Factories::EligibilityFactory.new(new_enrollment.id, new_enrollment.effective_on)
        eli_fac_obj.fetch_member_level_applicable_aptcs(applicable_aptc, age_as_of_coverage_start: age_as_of_coverage_start)
      end

      def self.fetch_applicable_aptc(new_enrollment, selected_aptc, effective_on, excluding_enrollment_id = nil)
        service = ::Services::ApplicableAptcService.new(new_enrollment.id, effective_on, selected_aptc, [new_enrollment.product_id], excluding_enrollment_id)
        service.applicable_aptcs[new_enrollment.product_id.to_s]
      end

      def is_aptc_eligible(enrollment, family)
        return false if enrollment.kind == "coverall" || enrollment.coverage_kind == "dental"

        allowed_metal_levels = ["platinum", "silver", "gold", "bronze"]
        product = enrollment.product
        if family.active_household.latest_active_tax_household.present?
          tax_household = family.active_household.latest_active_tax_household
          aptc_members = tax_household.aptc_members if tax_household.present?
          true if allowed_metal_levels.include?(product.metal_level_kind.to_s) && enrollment.household.tax_households.present? && aptc_members.present?
        else
          false
        end
      end

      def build_form_params
        enrollment                = HbxEnrollment.find(BSON::ObjectId.from_string(enrollment_id))
        new_effective_on          = Insured::Factories::SelfServiceFactory.find_enrollment_effective_on_date(TimeKeeper.date_of_record.in_time_zone('Eastern Time (US & Canada)'), enrollment.effective_on).to_date
        family                    = Family.find(BSON::ObjectId.from_string(family_id))
        sep                       = SpecialEnrollmentPeriod.find(BSON::ObjectId.from_string(family.latest_active_sep.id)) if family.latest_active_sep.present?
        qle                       = QualifyingLifeEventKind.find(BSON::ObjectId.from_string(sep.qualifying_life_event_kind_id))  if sep.present?
        available_aptc            = calculate_max_applicable_aptc(enrollment, new_effective_on)
        max_tax_credit            = calculate_max_tax_credit(enrollment, new_effective_on)
        elected_aptc_pct          = calculate_elected_aptc_pct(enrollment, available_aptc, max_tax_credit)
        default_tax_credit_value  = default_tax_credit_value(enrollment, available_aptc)
        {
          enrollment: enrollment,
          family: family,
          qle: qle,
          is_aptc_eligible: is_aptc_eligible(enrollment, family),
          new_effective_on: new_effective_on,
          available_aptc: available_aptc,
          max_tax_credit: max_tax_credit,
          default_tax_credit_value: default_tax_credit_value,
          elected_aptc_pct: elected_aptc_pct,
          new_enrollment_premium: new_enrollment_premium(default_tax_credit_value, enrollment),
          cancellation_reason: nil
        }
      end

      def calculate_max_applicable_aptc(enrollment, new_effective_on)
        if EnrollRegistry.feature_enabled?(:temporary_configuration_enable_multi_tax_household_feature)
          max_aptc = fetch_aptc_value(enrollment, new_effective_on)
          float_fix([max_aptc, enrollment.total_ehb_premium].min)
        else
          selected_aptc = ::Services::AvailableEligibilityService.new(enrollment.id, new_effective_on, enrollment.id).available_eligibility[:total_available_aptc]
          Insured::Factories::SelfServiceFactory.fetch_applicable_aptc(enrollment, selected_aptc, new_effective_on, enrollment.id)
        end
      end

      def calculate_max_tax_credit(enrollment, new_effective_on)
        if EnrollRegistry.feature_enabled?(:temporary_configuration_enable_multi_tax_household_feature)
          max_aptc = fetch_aptc_value(enrollment, new_effective_on)
          return float_fix(max_aptc)
        end
        0.0
      end

      def self.find_enrollment_effective_on_date(hbx_created_datetime, current_enrollment_effective_on)
        day = 1
        hour = hbx_created_datetime.hour
        min = hbx_created_datetime.min
        sec = hbx_created_datetime.sec
        override_enabled = EnrollRegistry[:fifteenth_of_the_month_rule_overridden].feature.is_enabled
        # this condition is for self service APTC feature ONLY.
        if eligible_for_1_1_effective_date?(hbx_created_datetime, current_enrollment_effective_on)
          year = current_enrollment_effective_on.year
          month = day = 1
        elsif current_enrollment_effective_on.year != hbx_created_datetime.year
          monthly_enrollment_due_on = override_enabled ? 31 : Settings.aca.individual_market.monthly_enrollment_due_on
          condition = (Date.new(hbx_created_datetime.year, 11, 1)..Date.new(hbx_created_datetime.year, 12, monthly_enrollment_due_on)).include?(hbx_created_datetime.to_date)
          offset_month = condition ? 0 : 1
          year = current_enrollment_effective_on.year
          month = hbx_created_datetime.next_month.month + offset_month
        else
          offset_month = (hbx_created_datetime.day <= HbxProfile::IndividualEnrollmentDueDayOfMonth || override_enabled) ? 1 : 2
          year = hbx_created_datetime.year
          month = hbx_created_datetime.month + offset_month
        end
        if month > 12
          year += 1
          month -= 12
        end

        DateTime.new(year, month, day, hour, min, sec)
      end

      # Checks if case is eligible for 1/1 effective date for Prospective Year's enrollments.
      def self.eligible_for_1_1_effective_date?(system_date, current_effective_on)
        last_eligible_date_for_1_1_effective_date = Date.new(system_date.year, system_date.end_of_year.month, HbxProfile::IndividualEnrollmentDueDayOfMonth)
        current_effective_on.year > system_date.year && HbxProfile.current_hbx.under_open_enrollment? && last_eligible_date_for_1_1_effective_date > system_date
      end

      private

      def fetch_aptc_value(enrollment, effective_on)
        @fetch_aptc_value ||= ::Operations::PremiumCredits::FindAptc.new.call({hbx_enrollment: enrollment, effective_on: effective_on}).value!
      end

      def default_tax_credit_value(enrollment, available_aptc)
        enrollment.applied_aptc_amount.to_f > available_aptc ? available_aptc : enrollment.applied_aptc_amount.to_f
      end

      def calculate_elected_aptc_pct(enrollment, available_aptc, max_aptc)
        pct = if EnrollRegistry.feature_enabled?(:temporary_configuration_enable_multi_tax_household_feature)
                float_fix(enrollment.applied_aptc_amount.to_f / max_aptc).round(2)
              else
                float_fix(enrollment.applied_aptc_amount.to_f / available_aptc).round(2)
              end
        pct > 1 ? 1 : pct
      end

      def new_enrollment_premium(default_tax_credit_value, enrollment)
        float_fix(enrollment.total_premium - default_tax_credit_value)
      end

    end
  end
end
