# frozen_string_literal: true

module Operations
  module HbxEnrollments
    # This class terminates an existing enrollment and reinstates a new enrollment without members selected to be dropped from coverage
    class DropEnrollmentMembers
      include Dry::Monads[:result, :do]

      attr_reader :new_effective_date, :termination_date, :base_enrollment, :new_enrollment

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
        @base_enrollment = params[:hbx_enrollment]
        return Failure('Enrollment need be in an active state to drop dependent') unless base_enrollment.is_admin_terminate_eligible?
        return Failure('Not an ivl enrollment.') unless base_enrollment.is_ivl_by_kind? # Added per the request, also need further development if to be used for shop
        return Failure('No members selected to drop.') if params[:options].select{|string| string.include?("terminate_member")}.empty?
        return Failure('No termination date given.') if params[:options].select{|string| string.include?("termination_date")}.empty?
        @termination_date = Date.strptime(params[:options]["termination_date_#{params[:hbx_enrollment].id}"], "%m/%d/%Y")
        @new_effective_date = (termination_date > base_enrollment.effective_on) ? termination_date + 1.day : base_enrollment.effective_on
        return Failure('Select termination date that would result member drop in present calender year.') unless new_effective_date.year == termination_date.year
        return Failure('Termination date cannot be outside of the current calender year.') unless termination_date.year == TimeKeeper.date_of_record.year
        return Failure('Termination date not within the allowed range') unless valid_termination_date?(params)
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
        set_product_result = set_product_id
        return set_product_result if set_product_result.failure?

        new_enrollment.check_for_subscriber
        updates_for_subscriber_drop unless check_subscriber_drop
        new_enrollment.select_coverage! if new_enrollment.may_select_coverage?
        update_member_effective_dates
        return Failure('Failed to save dropped member enrollment') unless new_enrollment.persisted?

        update_household_applied_aptc if base_enrollment.applied_aptc_amount > 0
        terminate_base_enrollment
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
        transmit_drop = params.key?("transmit_hbx_#{base_enrollment.id}") ? true : false
        base_enrollment.notify_enrollment_cancel_or_termination_event(transmit_drop)
        new_enrollment.notify_of_coverage_start(transmit_drop)
      end

      def check_subscriber_drop
        new_enrollment.subscriber.hbx_id == base_enrollment.subscriber.hbx_id
      end

      def updates_for_subscriber_drop
        new_enrollment.generate_hbx_signature
        new_enrollment.consumer_role_id = new_enrollment.subscriber.person.consumer_role.id
      end

      def update_member_effective_dates
        new_enrollment.hbx_enrollment_members.each do |member|
          if check_subscriber_drop
            member.update_attributes(eligibility_date: new_enrollment.effective_on)
          else
            member.update_attributes(eligibility_date: new_enrollment.effective_on, coverage_start_on: new_enrollment.effective_on)
          end
        end
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
        return Failure('Rating area could be found.') unless rating_area.present?
        Success({ predecessor_enrollment_id: base_enrollment.id,
                  rating_area_id: rating_area&.id })
      end

      def set_product_id
        tax_household = base_enrollment.family.active_household.latest_active_thh_with_year(new_enrollment.effective_on.year)
        return Success() unless tax_household.present?

        products = products_for_csr_variant(base_enrollment, new_enrollment, tax_household)
        return Failure('Could not find product for new enrollment with present csr kind.') unless products.count >= 1

        new_enrollment.product_id = products.last.id
        service_area_check = ::Operations::Products::ProductOfferedInServiceArea.new.call({enrollment: new_enrollment})
        return Failure('Product is NOT offered in service area.') if service_area_check.failure?

        Success()
      end

      def products_for_csr_variant(base_enrollment, new_enrollment, tax_household)
        eligible_csr = tax_household.eligibile_csr_kind(new_enrollment.hbx_enrollment_members.map(&:applicant_id))
        csr_variant = EligibilityDetermination::CSR_KIND_TO_PLAN_VARIANT_MAP[eligible_csr]
        ::BenefitMarkets::Products::HealthProducts::HealthProduct.by_year(new_enrollment.effective_on.year).where({:hios_id => "#{base_enrollment.product.hios_base_id}-#{csr_variant}"})
      end

      def update_household_applied_aptc
        tax_household = new_enrollment.family.active_household.latest_tax_household_with_year(new_enrollment.effective_on.year)
        return unless tax_household

        applied_aptc = tax_household.monthly_max_aptc(new_enrollment, new_effective_date)
        ::Insured::Factories::SelfServiceFactory.update_enrollment_for_apcts(new_enrollment, applied_aptc)
      end

      def valid_termination_date?(params)
        hbx_enrollment = params[:hbx_enrollment]
        term_date = params[:options]["termination_date_#{hbx_enrollment.id}"]

        min = (hbx_enrollment.effective_on.beginning_of_year + 1)
        max = if (hbx_enrollment.kind == "employer_sponsored") || (hbx_enrollment.kind == "employer_sponsored_cobra")
                hbx_enrollment.sponsored_benefit_package.end_on
              else
                Date.new(hbx_enrollment.effective_on.year, 12, 31)
              end
        (min..max).include?(term_date.to_date)
      end
    end
  end
end
