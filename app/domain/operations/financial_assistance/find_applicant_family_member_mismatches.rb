# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module FinancialAssistance
    # Find application family mismatches on the members
    class FindApplicantFamilyMemberMismatches
      include Dry::Monads[:do, :result]

      # @param [Hash] opts Options to find applicant family member mismatches
      # @option opts [String] :assistance_year required
      # @return [Dry::Monad] result
      def call(params)
        values = yield validate(params)
        mismatched_records =
          yield find_family_member_mismatches(values[:assistance_year])

        Success(mismatched_records)
      end

      private

      def validate(params)
        return Failure('assistance_year is expected') unless params[:assistance_year]
        Success(params)
      end

      def find_family_member_mismatches(assistance_year)
        mismatched_records = families_with_determined_applications(assistance_year).no_timeout.collect do |family|
          application = determined_application_for(family, assistance_year)
          next unless application
          next unless is_aptc_or_csr_eligible?(application)

          family_member_hbx_ids = family.active_family_members.map(&:id)
          applicant_hbx_ids = application.applicants.pluck(:family_member_id)
          next if family_member_hbx_ids.to_set == applicant_hbx_ids.to_set

          {
            assistance_year: assistance_year,
            family: family.hbx_assigned_id,
            application: application.hbx_id,
            inactive_family_members_on_application: inactive_family_members_on_application(family, application),
            active_family_members_not_on_application: active_family_members_not_on_application(family, application),
            applicants_with_no_matching_family_member: applicants_with_no_matching_family_member(family, application)
          }
        end.compact

        Success(mismatched_records)
      end

      def inactive_family_members(family)
        family.family_members.find_all {|family_member| !family_member.is_active? }
      end

      def inactive_family_members_on_application(family, application)
        inactive_family_members(family).select{|family_member| application.applicants.pluck(:family_member_id).include?(family_member.id) }.map(&:id)
      end

      def active_family_members_not_on_application(family, application)
        family.active_family_members.map(&:id) - application.applicants.pluck(:family_member_id)
      end

      def applicants_with_no_matching_family_member(family, application)
        application.applicants.select{|applicant| family.family_members.pluck(:id).exclude?(applicant.family_member_id)}.map(&:id)
      end

      def determined_application_for(family, assistance_year)
        ::FinancialAssistance::Application
          .where(
            assistance_year: assistance_year,
            aasm_state: 'determined',
            family_id: family.id
          )
          .max_by(&:created_at)
      end

      def families_with_determined_applications(assistance_year)
        family_ids =
          ::FinancialAssistance::Application
          .where(aasm_state: 'determined', assistance_year: assistance_year)
          .distinct(:family_id)
        ::Family.where(:_id.in => family_ids)
      end

      def is_aptc_or_csr_eligible?(application)
        eligibility =
          application.eligibility_determinations.max_by(&:determined_at)
        eligibility.present? &&
          (eligibility.is_aptc_eligible? || eligibility.is_csr_eligible?)
      end
    end
  end
end
