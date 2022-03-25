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
        return Failure('No members selected to drop.') if params[:options].select{|string| string.include?("terminate_member")}.empty?
        return Failure('No termination date given.') if params[:options].select{|string| string.include?("termination_date")}.empty?

        Success(params)
      end

      def drop_enrollment_members(params)
        terminate_date = Date.strptime(params[:options]["termination_date_#{params[:hbx_enrollment].id}"], "%m/%d/%Y")
        dropped_enr_members = params[:options].select{|string| string.include?("terminate_member")}.values
        all_enr_members = params[:hbx_enrollment].hbx_enrollment_members
        eligible_members = all_enr_members.reject{ |member| dropped_enr_members.include?(member.id.to_s) }

        reinstatement = Enrollments::Replicator::Reinstatement.new(params[:hbx_enrollment], terminate_date + 1.day, 0, eligible_members).build
        reinstatement.save!

        get_household_applied_aptc(reinstatement, terminate_date + 1.day)

        reinstatement.force_select_coverage! if reinstatement.may_reinstate_coverage?
        reinstatement.begin_coverage! if reinstatement.may_begin_coverage? && reinstatement.effective_on <= TimeKeeper.date_of_record

        params[:hbx_enrollment].update_attributes!(terminated_on: terminate_date)

        dropped_member_info = []
        dropped_enr_members.each do |member_id|
          member = params[:hbx_enrollment].hbx_enrollment_members.where(id: member_id).first
          dropped_member_info << {hbx_id: member.hbx_id,
                                  full_name: member.person.full_name,
                                  terminated_on: terminate_date}
        end

        Success(dropped_member_info)
      end

      def get_household_applied_aptc(hbx_enrollment, effective_date)
        tax_household = hbx_enrollment.family.active_household.latest_tax_household_with_year(hbx_enrollment.effective_on.year)
        return unless tax_household
        applied_aptc = tax_household.monthly_max_aptc(hbx_enrollment, effective_date) #if tax_household
        ::Insured::Factories::SelfServiceFactory.update_enrollment_for_apcts(hbx_enrollment, applied_aptc)
      end
    end
  end
end
