# frozen_string_literal: true

module Insured
  module Factories
    class SelfServiceFactory
      attr_accessor :document_id, :enrollment_id, :family_id, :product_id, :qle_id, :sep_id
      extend ::ApplicationHelper
      extend Acapi::Notifiers

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

      def self.term_or_cancel(enrollment_id, term_date, term_or_cancel)
        enrollment = HbxEnrollment.find(BSON::ObjectId.from_string(enrollment_id))
        enrollment.term_or_cancel_enrollment(enrollment, term_date)
        return unless term_or_cancel == 'cancel'

        transmit_flag = true
        notify(
          "acapi.info.events.hbx_enrollment.terminated",
          {
            :reply_to => "#{Rails.application.config.acapi.hbx_id}.#{Rails.application.config.acapi.environment_name}.q.glue.enrollment_event_batch_handler",
            "hbx_enrollment_id" => @enrollment_id,
            "enrollment_action_uri" => "urn:openhbx:terms:v1:enrollment#terminate_enrollment",
            "is_trading_partner_publishable" => transmit_flag
          }
        )
      end

      def self.update_aptc(enrollment_id, elected_aptc_pct, applied_aptc_amount)
        # field :elected_aptc_pct, type: Float, default: 0.0
        # field :applied_aptc_amount, type: Money, default: 0.0
        enrollment = HbxEnrollment.find(BSON::ObjectId.from_string(enrollment_id))

        new_effective_date = self.find_enrollment_effective_on_date(DateTime.now)
        reinstatement = Enrollments::Replicator::Reinstatement.new(enrollment, new_effective_date, applied_aptc_amount).build
        reinstatement.save!
        update_enrollment_for_apcts(elected_aptc_pct, reinstatement, applied_aptc_amount, enrollment)
        reinstatement.select_coverage!
      end

      def self.update_enrollment_for_apcts(elected_aptc_pct, reinstatement, applied_aptc_amount, enrollment)
        applicable_aptc_by_member = member_level_aptc_breakdown(reinstatement, applied_aptc_amount)
        reinstatement.hbx_enrollment_members.each do |enrollment_member|
          aptc_value = applicable_aptc_by_member[enrollment_member.applicant_id.to_s]
          next enrollment_member unless aptc_value
          aptc_value = round_down_float_two_decimals(aptc_value)
          enrollment_member.update_attributes!(applied_aptc_amount: aptc_value)
        end
        total_aptc = round_down_float_two_decimals(reinstatement.hbx_enrollment_members.pluck(:applied_aptc_amount).sum)
        reinstatement.update_attributes!(elected_aptc_pct: elected_aptc_pct, applied_aptc_amount: total_aptc)
      end

      def self.member_level_aptc_breakdown(new_enrollment, applied_aptc_amount)
        applicable_aptc = fetch_applicable_aptc(new_enrollment, applied_aptc_amount)
        eli_fac_obj = ::Factories::EligibilityFactory.new(new_enrollment.id)
        eli_fac_obj.fetch_member_level_applicable_aptcs(applicable_aptc)
      end

      def self.fetch_applicable_aptc(new_enrollment, selected_aptc)
        service = ::Services::ApplicableAptcService.new(new_enrollment.id, selected_aptc, [new_enrollment.product_id])
        service.applicable_aptcs[new_enrollment.product_id.to_s]
      end

      def is_aptc_eligible(enrollment, family)
        return false if enrollment.kind == "coverall" || enrollment.coverage_kind == "dental"

        allowed_metal_levels = ["platinum", "silver", "gold", "bronze"]
        product = enrollment.product
        tax_household = family.active_household.latest_active_tax_household if family.active_household.latest_active_tax_household.present?
        aptc_members = tax_household.aptc_members if tax_household.present?
        true if allowed_metal_levels.include?(product.metal_level_kind.to_s) && enrollment.household.tax_households.present? && aptc_members.present?
      end

      def build_form_params
        enrollment = HbxEnrollment.find(BSON::ObjectId.from_string(enrollment_id))
        family     = Family.find(BSON::ObjectId.from_string(family_id))
        sep        = SpecialEnrollmentPeriod.find(BSON::ObjectId.from_string(family.latest_active_sep.id)) if family.latest_active_sep.present?
        qle        = QualifyingLifeEventKind.find(BSON::ObjectId.from_string(sep.qualifying_life_event_kind_id))  if sep.present?
        {
          enrollment: enrollment,
          family: family,
          qle: qle,
          is_aptc_eligible: is_aptc_eligible(enrollment, family),
          new_effective_on: self.class.find_enrollment_effective_on_date(DateTime.current),
          available_aptc: calculate_max_applicable_aptc(enrollment)
        }
      end

      def calculate_max_applicable_aptc(enrollment)
        selected_aptc = ::Services::AvailableEligibilityService.new(enrollment.id, enrollment.id).available_eligibility[:total_available_aptc]
        Insured::Factories::SelfServiceFactory.fetch_applicable_aptc(enrollment, selected_aptc)
      end

      def self.find_enrollment_effective_on_date(hbx_created_datetime)
        offset_month = hbx_created_datetime.day <= 15 ? 1 : 2
        year = hbx_created_datetime.year
        month = hbx_created_datetime.month + offset_month
        if month > 12
          year = year + 1
          month = month - 12
        end
        day = 1
        hour = hbx_created_datetime.hour
        min = hbx_created_datetime.min
        sec = hbx_created_datetime.sec
        return DateTime.new(year, month, day, hour, min, sec)
      end

    end
  end
end
