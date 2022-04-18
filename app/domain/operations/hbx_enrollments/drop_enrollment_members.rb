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
        return Failure('Member drop feature is turned off.') unless EnrollRegistry.feature_enabled?(:drop_enrollment_members)
        return Failure('Missing HbxEnrollment Key.') unless params.key?(:hbx_enrollment)
        return Failure('Not a valid HbxEnrollment object.') unless params[:hbx_enrollment].is_a?(HbxEnrollment)
        return Failure('Enrollment need be in an active state to drop dependent') unless params[:hbx_enrollment].is_admin_terminate_eligible?
        return Failure('Not an ivl enrollment.') unless params[:hbx_enrollment].is_ivl_by_kind? # Added per the request, also need further development if to be used for shop
        return Failure('No members selected to drop.') if params[:options].select{|string| string.include?("terminate_member")}.empty?
        return Failure('No termination date given.') if params[:options].select{|string| string.include?("termination_date")}.empty?
        return Failure('Termination date cannot be outside of the current calender year.') unless Date.strptime(params[:options]["termination_date_#{params[:hbx_enrollment].id}"], "%m/%d/%Y").year == TimeKeeper.date_of_record.year

        Success(params)
      end

      def drop_enrollment_members(params)
        termination_date = Date.strptime(params[:options]["termination_date_#{params[:hbx_enrollment].id}"], "%m/%d/%Y")
        dropped_enr_members = params[:options].select{|string| string.include?("terminate_member")}.values
        all_enr_members = params[:hbx_enrollment].hbx_enrollment_members
        non_eligible_members = all_enr_members.select{ |member| dropped_enr_members.include?(member.id.to_s) }
        new_effective_date = (termination_date > params[:hbx_enrollment].effective_on) ? termination_date + 1.day : params[:hbx_enrollment].effective_on
        return Failure('Select termination date that would result member drop in present calender year.') unless new_effective_date.year == termination_date.year

        custom_params = custom_params(params[:hbx_enrollment], new_effective_date)
        clone_enrollment = Operations::HbxEnrollments::Clone.new.call({hbx_enrollment: params[:hbx_enrollment], effective_on: new_effective_date, options: custom_params})
        return clone_enrollment if clone_enrollment.failure?

        new_enrollment = clone_enrollment.value!
        new_enrollment.hbx_enrollment_members.delete_if {|mem| non_eligible_members.pluck(:applicant_id).include?(mem.applicant_id)}
        set_product_id(params[:hbx_enrollment], new_enrollment)
        new_enrollment.check_for_subscriber
        new_enrollment.generate_hbx_signature
        new_enrollment.select_coverage! if new_enrollment.may_select_coverage?
        update_member_effective_dates(new_enrollment)
        return Failure('Failed to save dropped member enrollment') unless new_enrollment.persisted?

        get_household_applied_aptc(new_enrollment, new_effective_date) if params[:hbx_enrollment].applied_aptc_amount > 0
        terminate_base_enrollment(params[:hbx_enrollment], new_enrollment, termination_date)

        dropped_member_info = []
        dropped_enr_members.each do |member_id|
          member = params[:hbx_enrollment].hbx_enrollment_members.where(id: member_id).first
          dropped_member_info << {hbx_id: member.hbx_id,
                                  full_name: member.person.full_name,
                                  terminated_on: termination_date}
        end

        Success(dropped_member_info)
      end

      def update_member_effective_dates(new_enrollment)
        new_enrollment.hbx_enrollment_members.each do |member|
          member.update_attributes(eligibility_date: new_enrollment.effective_on, coverage_start_on: new_enrollment.effective_on)
        end
      end

      def terminate_base_enrollment(base_enrollment, new_enrollment, termination_date)
        if base_enrollment.may_terminate_coverage? && (new_enrollment.effective_on > base_enrollment.effective_on)
          base_enrollment.terminate_coverage!
          base_enrollment.update_attributes!(terminated_on: termination_date)
        elsif base_enrollment.may_cancel_coverage?
          base_enrollment.cancel_coverage!
        end
      end

      def custom_params(base_enrollment, new_effective_date)
        { predecessor_enrollment_id: base_enrollment.id,
          rating_area_id: ::BenefitMarkets::Locations::RatingArea.rating_area_for(base_enrollment.consumer_role.rating_address, during: new_effective_date)&.id }
      end

      def set_product_id(base_enrollment, new_enrollment)
        tax_household = base_enrollment.family.active_household.latest_active_thh_with_year(new_enrollment.effective_on.year)
        return unless tax_household.present?

        products = products_for_csr_variant(base_enrollment, new_enrollment, tax_household)
        return Failure('Could not find product for new enrollment with present csr kind.') unless products.count >= 1

        new_enrollment.product_id = products.last.id
      end

      def products_for_csr_variant(base_enrollment, new_enrollment, tax_household)
        eligible_csr = tax_household.eligibile_csr_kind(new_enrollment.hbx_enrollment_members.map(&:applicant_id))
        csr_variant = EligibilityDetermination::CSR_KIND_TO_PLAN_VARIANT_MAP[eligible_csr]
        ::BenefitMarkets::Products::HealthProducts::HealthProduct.by_year(new_enrollment.effective_on.year).where({:hios_id => "#{base_enrollment.product.hios_base_id}-#{csr_variant}"})
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
