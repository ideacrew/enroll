# frozen_string_literal: true

module Operations
  module ProductSelectionEffects
    # This class is invoked when a product selection is made.
    # It will execute the side effects of making a product selection, as
    # specific to the DCHBX customer.
    class DchbxProductSelectionEffects
      include Dry::Monads[:do, :result]

      # Invoke the operation.
      # @param opts [Entities::ProductSelection] the invocation options
      def self.call(opts = {})
        self.new.call(opts)
      end

      # Invoke the operation.
      # @param opts [Entities::ProductSelection] the invocation options
      def call(opts = {})
        enrollment = opts.enrollment
        if enrollment.is_shop?
          enrollment.update_existing_shop_coverage
        else
          ::Operations::ProductSelectionEffects::TerminatePreviousSelections.call(opts)
        end

        if enrollment.benefit_group_assignment
          benefit_group_assignment = enrollment.benefit_group_assignment
          benefit_group_assignment.select_coverage if benefit_group_assignment.may_select_coverage?
          benefit_group_assignment.hbx_enrollment = enrollment
          benefit_group_assignment.save
        end

        try_to_renew = if ::EnrollRegistry.feature_enabled?(:prior_plan_year_ivl_sep) && enrollment.special_enrollment_period&.present? && enrollment.prior_year_ivl_coverage?
                         renew_prior_py_ivl_enrollments(enrollment)
                       else
                         renew_ivl_if_is_open_enrollment(enrollment)
                       end
        return try_to_renew if try_to_renew
        Success(:ok)
      end

      private

      def renew_ivl_if_is_open_enrollment(enrollment)
        return nil if enrollment.is_shop? || !HbxProfile.current_hbx&.under_open_enrollment?
        bcp = fetch_bcp_by_oe_period

        return if bcp.blank?
        return unless enrollment_effective_on_eligible_for_renewal?(enrollment, bcp)
        cancel_renewal_enrollments(enrollment)
        renewal_enrollment = Operations::Individual::RenewEnrollment.new.call(hbx_enrollment: enrollment,
                                                                              effective_on: bcp.start_on)
        return renewal_enrollment if renewal_enrollment.success.nil?

        transition_enrollment(renewal_enrollment.success, bcp)
      end

      def renew_prior_py_ivl_enrollments(enrollment)
        sep = enrollment.special_enrollment_period
        return nil unless sep&.coverage_renewal_flag
        return nil if enrollment.is_shop?
        @benefit_coverage_periods = fetch_bcp_gt_enr_effective_year(enrollment)
        return nil if @benefit_coverage_periods.empty?
        renew_enrollments(enrollment)
        Success(@enrollment)
      end

      def renew_enrollments(enrollment)
        @enrollment = enrollment
        @benefit_coverage_periods.each do |bcp|
          next if bcp.start_on.year > TimeKeeper.date_of_record.year && !HbxProfile.current_hbx&.under_open_enrollment?
          cancel_renewal_enrollments(enrollment, bcp.start_on.year)
          renewal_enrollment = Operations::Individual::RenewEnrollment.new.call(hbx_enrollment: @enrollment,
                                                                                effective_on: bcp.start_on)
          next if renewal_enrollment.success.nil?
          transition_enrollment(renewal_enrollment.success, bcp)
          @enrollment = renewal_enrollment.success
        end
        @enrollment
      end

      def enrollment_effective_on_eligible_for_renewal?(enrollment, bcp)
        enrollment.effective_on.year == (bcp.start_on.year - 1)
      end

      def fetch_renewal_enrollment_year(enrollment)
        current_year = TimeKeeper.date_of_record.year
        current_year == enrollment.effective_on.year ? (current_year + 1) : current_year
      end

      def cancel_renewal_enrollments(enrollment, effective_year = nil)
        year = effective_year || fetch_renewal_enrollment_year(enrollment)
        renewal_enrollments = fetch_renewal_enrollments(enrollment, year)
        generate_enrollment_signature(enrollment)
        renewal_enrollments.each do |renewal_enrollment|
          handle_renewal_enrollment(enrollment, renewal_enrollment)
        end
      end

      def handle_renewal_enrollment(enrollment, renewal_enrollment)
        generate_enrollment_signature(renewal_enrollment)
        return unless enrollment.same_signatures(renewal_enrollment) && !renewal_enrollment.is_shop?

        process_renewal_enrollment(enrollment, renewal_enrollment)
      end

      def process_renewal_enrollment(enrollment, renewal_enrollment)
        is_product_matched = product_matched?(enrollment, renewal_enrollment)
        transition_args = is_product_matched ? { "reason" => Enrollments::TerminationReasons::SUPERSEDED_SILENT } : {}

        if EnrollRegistry.feature_enabled?(:cancel_superseded_terminated_enrollments)
          cancel_coverage_for_superseded_enrollment(renewal_enrollment, transition_args)
        elsif renewal_enrollment.may_cancel_coverage?
          renewal_enrollment.cancel_ivl_enrollment
        end
      end

      def cancel_coverage_for_superseded_enrollment(renewal_enrollment, transition_args)
        if renewal_enrollment.coverage_terminated?
          renewal_enrollment.cancel_coverage_for_superseded_term!(transition_args)
        else
          renewal_enrollment.cancel_coverage!(transition_args)
        end
      end

      def fetch_renewal_enrollments(enrollment, year)
        enrollment.family.hbx_enrollments.by_coverage_kind(enrollment.coverage_kind).by_year(year).show_enrollments_sans_canceled.by_kind(enrollment.kind)
      end

      def product_matched?(enrollment, renewal_enrollment)
        return false unless enrollment.product.present?

        renewal_product = renewal_enrollment&.product
        return false unless renewal_product.present?

        product_id_match = enrollment.product.renewal_product_id == renewal_product.id
        hios_base_id_match = enrollment.product.renewal_product.hios_base_id == renewal_product.hios_base_id

        product_id_match || hios_base_id_match
      end

      def generate_enrollment_signature(enrollment)
        return if enrollment.enrollment_signature.present?
        enrollment.generate_hbx_signature
        enrollment.save
      end

      def fetch_bcp_by_oe_period
        HbxProfile.current_hbx.benefit_sponsorship.benefit_coverage_periods.detect do |bcp|
          bcp.open_enrollment_contains?(TimeKeeper.date_of_record)
        end
      end

      def transition_enrollment(enrollment, bcp)
        enrollment.begin_coverage! if TimeKeeper.date_of_record >= bcp.start_on && enrollment.may_begin_coverage?
        Success(enrollment)
      end

      def fetch_bcp_gt_enr_effective_year(enrollment)
        HbxProfile.current_hbx.benefit_sponsorship.benefit_coverage_periods.select{|bcp| bcp.start_on.year > enrollment.effective_on.year }
      end
    end
  end
end
