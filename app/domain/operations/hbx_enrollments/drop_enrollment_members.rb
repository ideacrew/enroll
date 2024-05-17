# frozen_string_literal: true

module Operations
  module HbxEnrollments
    # This class terminates an existing enrollment and reinstates a new enrollment without members selected to be dropped from coverage
    class DropEnrollmentMembers
      include Dry::Monads[:do, :result]

      attr_reader :new_effective_date, :termination_date, :base_enrollment, :new_enrollment, :future_effective

      # @param [ HbxEnrollment ] hbx_enrollment
      # @return [ Array ] dropped_members
      def call(params)
        values          = yield validate(params)
        dropped_members = yield drop_enrollment_members(values)

        Success(dropped_members)
      end

      private

      def validate(params)
        return Failure('Unable to disenroll member(s). Admin does not have access to use this tool.') if params[:options]["admin_permission"].in? ["false", false]
        return Failure('Member drop feature is turned off.') unless EnrollRegistry.feature_enabled?(:drop_enrollment_members)
        return Failure('Missing HbxEnrollment Key.') unless params.key?(:hbx_enrollment)
        return Failure('Not a valid HbxEnrollment object.') unless params[:hbx_enrollment].is_a?(HbxEnrollment)
        @base_enrollment = params[:hbx_enrollment]
        return Failure('Enrollment need be in an active state to drop dependent.') unless base_enrollment.is_admin_terminate_eligible?
        return Failure('Not an ivl enrollment.') unless base_enrollment.is_ivl_by_kind? # Added per the request, also need further development if to be used for shop
        return Failure('Member(s) have not been selected for termination.') if params[:options].select{|string| string.include?("terminate_member")}.empty?
        return Failure('Termination date has not been selected.') if params[:options].select{|string| string.include?("termination_date")}.empty?
        @termination_date = Date.strptime(params[:options]["termination_date_#{params[:hbx_enrollment].id}"], "%m/%d/%Y")
        @future_effective = termination_date > base_enrollment.effective_on
        @new_effective_date = future_effective ? termination_date + 1.day : base_enrollment.effective_on
        return Failure('Termination date must be in current calendar year.') unless future_effective || (new_effective_date.year == termination_date.year)
        return Failure('Termination date cannot be outside of the current calendar year.') unless termination_date.year == TimeKeeper.date_of_record.year
        return Failure('Unable to disenroll member(s) because of retroactive date selection.') if termination_date < TimeKeeper.date_of_record && EnrollRegistry[:drop_retro_scenario].disabled?

        Success(params)
      end

      def drop_enrollment_members(params)
        custom_params_result = custom_params
        return custom_params_result if custom_params_result.failure?

        clone_enrollment = Operations::HbxEnrollments::Clone.new.call({hbx_enrollment: base_enrollment, effective_on: new_effective_date, options: custom_params_result.value!})
        return clone_enrollment if clone_enrollment.failure?

        @new_enrollment = clone_enrollment.value!
        dropped_enr_members = params[:options].select{|string| string.include?("terminate_member")}.values
        drop_selected_members(dropped_enr_members)
        return Failure('No members were being dropped.') if base_enrollment.hbx_enrollment_members.map(&:applicant_id) == new_enrollment.hbx_enrollment_members.map(&:applicant_id)

        set_product_result = set_product_id
        return set_product_result if set_product_result.failure?

        new_enrollment.check_for_subscriber
        updates_for_subscriber_drop unless check_subscriber_drop
        return Failure('Failed to save dropped member enrollment') unless new_enrollment.save

        update_member_effective_dates
        terminate_base_enrollment
        update_household_applied_aptc if base_enrollment.applied_aptc_amount > 0
        new_enrollment.select_coverage! if new_enrollment.may_select_coverage?
        notify_trading_partner(params)

        dropped_member_info = []
        dropped_enr_members.each do |member_id|
          member = base_enrollment.hbx_enrollment_members.where(id: member_id).first
          dropped_member_info << {hbx_id: member.hbx_id,
                                  full_name: member.person.full_name,
                                  terminated_on: termination_date}
        end

        Success(dropped_member_info)
      end

      def drop_selected_members(dropped_enr_members)
        all_enr_members = base_enrollment.hbx_enrollment_members
        non_eligible_members = all_enr_members.select{ |member| dropped_enr_members.include?(member.id.to_s) }
        new_enrollment.hbx_enrollment_members.delete_if {|mem| non_eligible_members.pluck(:applicant_id).include?(mem.applicant_id)}
      end

      def notify_trading_partner(params)
        base_enrollment.notify_enrollment_cancel_or_termination_event(true)
        new_enrollment.notify_of_coverage_start(true)
      end

      def check_subscriber_drop
        new_enrollment.subscriber.hbx_id == base_enrollment.subscriber.hbx_id
      end

      def updates_for_subscriber_drop
        new_enrollment.generate_hbx_signature
        new_enrollment.consumer_role_id = new_enrollment.subscriber.person.consumer_role.id
      end

      def update_member_effective_dates
        same_product = base_enrollment.product.is_same_plan_by_hios_id_and_active_year?(new_enrollment.product)
        new_enrollment.hbx_enrollment_members.each do |member|
          if same_product
            matched_member = match_member_on_enrollment(base_enrollment, member)
            member.update_attributes(eligibility_date: new_enrollment.effective_on, coverage_start_on: matched_member.coverage_start_on)
          else
            member.update_attributes(eligibility_date: new_enrollment.effective_on)
          end
        end
      end

      def match_member_on_enrollment(base_enrollment, member)
        base_enrollment.hbx_enrollment_members.detect{|a| a.hbx_id == member.hbx_id}
      end

      def terminate_base_enrollment
        if base_enrollment.may_terminate_coverage? && (new_enrollment.effective_on > base_enrollment.effective_on)
          base_enrollment.terminate_coverage!
          base_enrollment.update_attributes!(terminated_on: termination_date)
        elsif base_enrollment.may_cancel_coverage?
          base_enrollment.cancel_coverage!
        end
      end

      def custom_params
        rating_area = ::BenefitMarkets::Locations::RatingArea.rating_area_for(base_enrollment.consumer_role.rating_address, during: new_effective_date)
        return Failure('Rating area could not be found.') unless rating_area.present?
        Success({ predecessor_enrollment_id: base_enrollment.id,
                  rating_area_id: rating_area&.id })
      end

      def set_product_id
        return Success() unless base_enrollment.is_health_enrollment?

        if EnrollRegistry.feature_enabled?(:temporary_configuration_enable_multi_tax_household_feature)
          return Success() unless is_mthh_assisted?
        else
          tax_household = base_enrollment.family.active_household.latest_active_thh_with_year(new_enrollment.effective_on.year)
          return Success() unless tax_household.present?
        end

        products = products_for_csr_variant(base_enrollment, new_enrollment, tax_household, current_enrolled_aptc_grants)
        return Failure('Could not find product for new enrollment with present csr kind.') unless products.count >= 1

        new_enrollment.product_id = products.last.id
        service_area_check = ::Operations::Products::ProductOfferedInServiceArea.new.call({enrollment: new_enrollment})
        return Failure('Product is NOT offered in service area.') if service_area_check.failure?

        Success()
      end

      def is_mthh_assisted?
        current_enrolled_aptc_grants.present?
      end

      def current_enrolled_aptc_grants
        return @current_enrolled_aptc_grants if defined? @current_enrolled_aptc_grants

        premium_credits = ::Operations::PremiumCredits::FindAll.new.call({ family: new_enrollment.family, year: new_enrollment.effective_on.year, kind: 'AdvancePremiumAdjustmentGrant' })
        return [] if premium_credits.failure?

        aptc_grants = premium_credits.value!
        return [] if aptc_grants.blank?

        @current_enrolled_aptc_grants = aptc_grants.where(:member_ids.in => enrolled_family_member_ids)
      end

      def enrolled_family_member_ids
        return @enrolled_family_member_ids if defined? @enrolled_family_member_ids

        @enrolled_family_member_ids = new_enrollment.hbx_enrollment_members.map { |member| member.applicant_id.to_s }
      end

      def products_for_csr_variant(base_enrollment, new_enrollment, tax_household, _aptc_grants)
        eligible_csr = if EnrollRegistry.feature_enabled?(:temporary_configuration_enable_multi_tax_household_feature)
                         extract_csr_kind
                       else
                         tax_household.eligibile_csr_kind(new_enrollment.hbx_enrollment_members.map(&:applicant_id))
                       end

        return [base_enrollment.product] if eligible_csr.blank?

        csr_variant = EligibilityDetermination::CSR_KIND_TO_PLAN_VARIANT_MAP[eligible_csr]
        ::BenefitMarkets::Products::HealthProducts::HealthProduct.by_year(new_enrollment.effective_on.year).where({:hios_id => "#{base_enrollment.product.hios_base_id}-#{csr_variant}"})
      end

      def extract_csr_kind
        if EnrollRegistry.feature_enabled?(:native_american_csr) && all_american_indian_members
          'csr_limited'
        else
          subjects = new_enrollment.family.eligibility_determination&.subjects
          if subjects&.where(:"eligibility_states.eligibility_item_key" => 'aptc_csr_credit').present?
            result = ::Operations::PremiumCredits::FindCsrValue.new.call({
                                                                           family: new_enrollment.family,
                                                                           year: new_enrollment.effective_on.year,
                                                                           family_member_ids: enrolled_family_member_ids
                                                                         })

            result.value! if result.success?
          end
        end
      end

      def all_american_indian_members
        shopping_family_members = new_enrollment.family.family_members.where(:id.in => enrolled_family_member_ids)
        shopping_family_members.all?{|fm| fm.person.indian_tribe_member }
      end

      def update_household_applied_aptc
        if EnrollRegistry.feature_enabled?(:temporary_configuration_enable_multi_tax_household_feature)
          return unless is_mthh_assisted?

          default_percentage = EnrollRegistry[:aca_individual_assistance_benefits].setting(:default_applied_aptc_percentage).item
          elected_aptc_pct = base_enrollment.elected_aptc_pct > 0 ? base_enrollment.elected_aptc_pct : default_percentage

          ::Insured::Factories::SelfServiceFactory.mthh_update_enrollment_for_aptcs(new_enrollment.effective_on, new_enrollment, elected_aptc_pct, [base_enrollment.hbx_id])
        else
          tax_household = new_enrollment.family.active_household.latest_tax_household_with_year(new_enrollment.effective_on.year)
          return unless tax_household

          applied_aptc = tax_household.monthly_max_aptc(new_enrollment, new_effective_date)
          ::Insured::Factories::SelfServiceFactory.update_enrollment_for_apcts(new_enrollment, applied_aptc, age_as_of_coverage_start: true)
        end
      end
    end
  end
end
