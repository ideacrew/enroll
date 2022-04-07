# frozen_string_literal: true

module Operations
  module HbxEnrollments
    # This class terminates an existing enrollment and reinstates a new enrollment without members selected to be dropped from coverage
    class DropEnrollmentMembers
      include Dry::Monads[:result, :do]

      # @param [ HbxEnrollment ] hbx_enrollment
      # @return [ Array ] dropped_members
      def call(params)
        values          = yield validate(params)
        dropped_members = yield drop_enrollment_members(values)
        Success(dropped_members)
      end

      private

      def validate(params)
        return Failure('Missing HbxEnrollment Key.') unless params.key?(:hbx_enrollment)
        return Failure('Not a valid HbxEnrollment object.') unless params[:hbx_enrollment].is_a?(HbxEnrollment)
        return Failure('Not an ivl enrollment.') unless params[:hbx_enrollment].is_ivl_by_kind? # Added per the request, also need further development if to be used for shop
        return Failure('No members selected to drop.') if params[:options].select{|string| string.include?("terminate_member")}.empty?
        return Failure('No termination date given.') if params[:options].select{|string| string.include?("termination_date")}.empty?

        Success(params)
      end

      def drop_enrollment_members(params)
        terminate_date = Date.strptime(params[:options]["termination_date_#{params[:hbx_enrollment].id}"], "%m/%d/%Y")
        dropped_enr_members = params[:options].select{|string| string.include?("terminate_member")}.values
        all_enr_members = params[:hbx_enrollment].hbx_enrollment_members
        non_eligible_members = all_enr_members.select{ |member| dropped_enr_members.include?(member.id.to_s) }
        new_effective_date = terminate_date + 1.day
        optionals_params = params[:hbx_enrollment].is_ivl_by_kind? ? ivl_params(params[:hbx_enrollment], new_effective_date) : {}
        clone_enrollment = Operations::HbxEnrollments::Clone.new.call({hbx_enrollment: params[:hbx_enrollment], effective_on: new_effective_date, options: optionals_params})
        return clone_enrollment if clone_enrollment.failure?

        reinstatement = clone_enrollment.value!
        remove_dropped_enr_members(reinstatement, non_eligible_members)
        reinstatement.save!
        terminate_base_enrollment(params[:hbx_enrollment], reinstatement, terminate_date)
        get_household_applied_aptc(reinstatement, new_effective_date) if params[:hbx_enrollment].applied_aptc_amount > 0
        reinstatement.force_select_coverage! if reinstatement.may_reinstate_coverage?
        # reinstatement.begin_coverage! if reinstatement.may_begin_coverage? && reinstatement.effective_on <= TimeKeeper.date_of_record #Note: not needed for ivl enrollments

        dropped_member_info = []
        dropped_enr_members.each do |member_id|
          member = params[:hbx_enrollment].hbx_enrollment_members.where(id: member_id).first
          dropped_member_info << {hbx_id: member.hbx_id,
                                  full_name: member.person.full_name,
                                  terminated_on: terminate_date}
        end

        Success(dropped_member_info)
      end

      def remove_dropped_enr_members(reinstatement, non_eligible_members)
        ineligible_applicant_ids = non_eligible_members.pluck(:applicant_id)
        reinstatement.hbx_enrollment_members.where(:applicant_id.in => ineligible_applicant_ids).delete
      end

      def terminate_base_enrollment(base_enrollment, reinstate_enrollment, terminate_date)
        return if  base_enrollment.coverage_expired?

        if base_enrollment.may_terminate_coverage? && (reinstate_enrollment.effective_on > base_enrollment.effective_on)
          base_enrollment.terminate_coverage!
          base_enrollment.update_attributes!(terminated_on: terminate_date)
        elsif base_enrollment.may_cancel_coverage?
          base_enrollment.cancel_coverage!
        end
      end

      def ivl_params(base_enrollment, new_effective_date)
        { product_id: product_id_csr_variant(base_enrollment, new_effective_date.year),
          consumer_role_id: base_enrollment.consumer_role_id,
          predecessor_enrollment_id: base_enrollment.id,
          rating_area_id: ::BenefitMarkets::Locations::RatingArea.rating_area_for(base_enrollment.consumer_role.rating_address, during: new_effective_date)&.id }
      end

      def product_id_csr_variant(base_enrollment, effective_year)
        tax_household = base_enrollment.family.active_household.latest_active_thh_with_year(effective_year)
        base_enrollment_product_id = base_enrollment.product_id
        return base_enrollment_product_id unless tax_household.present?

        eligible_csr = tax_household.eligibile_csr_kind(base_enrollment.hbx_enrollment_members.map(&:applicant_id))
        csr_variant = EligibilityDetermination::CSR_KIND_TO_PLAN_VARIANT_MAP[eligible_csr]
        products = ::BenefitMarkets::Products::HealthProducts::HealthProduct.by_year(effective_year).where({:hios_id => "#{base_enrollment.product.hios_base_id}-#{csr_variant}"})
        products.count >= 1 ? products.last.id : base_enrollment_product_id
      end

      def get_household_applied_aptc(hbx_enrollment, effective_date)
        tax_household = hbx_enrollment.family.active_household.latest_tax_household_with_year(hbx_enrollment.effective_on.year)
        return unless tax_household

        applied_aptc = tax_household.monthly_max_aptc(hbx_enrollment, effective_date)
        ::Insured::Factories::SelfServiceFactory.update_enrollment_for_apcts(hbx_enrollment, applied_aptc)
      end
    end
  end
end
