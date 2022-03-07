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

        return Failure("Enrollment cannot exist without at least one member that is 18 years or older.") unless eligible_members.any? { |member| member.age_on_effective_date > 18 }

        applied_aptc = get_household_applied_aptc(params[:hbx_enrollment])

        reinstatement = Enrollments::Replicator::Reinstatement.new(params[:hbx_enrollment], terminate_date + 1.day, applied_aptc, eligible_members).build(terminate_date)
        reinstatement.save!
        params[:hbx_enrollment].update_attributes!(terminated_on: terminate_date)

        dropped_member_info = []
        dropped_enr_members.each do |member_id|
          dropped_member_info << {hbx_id: member_id,
                                full_name: params[:hbx_enrollment].hbx_enrollment_members.where(id: member_id).first.family_member.person.full_name,
                                terminated_on: terminate_date}
        end

        Success(dropped_member_info)
      end

      def get_household_applied_aptc(hbx_enrollment)
        if hbx_enrollment.applied_aptc_amount > 0
          tax_household = hbx_enrollment.family.active_household.latest_tax_household_with_year(hbx_enrollment.effective_on.year)
          applied_aptc = tax_household.monthly_max_aptc(hbx_enrollment, effective_date) if tax_household
        end
        applied_aptc.present? ? applied_aptc : 0
      end
    end
  end
end
