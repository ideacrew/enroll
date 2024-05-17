# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'csv'

module Operations
  # export evidences
  module Eligibilities
    # Build evidences data
    class FamilyEvidencesDataExport
      include Dry::Monads[:do, :result]

      # @param [Hash] opts Options to update evidence due on dates
      # @option opts [Family] :family required
      # @option opts [Integer] :assistance_year required
      # @return [Dry::Monad] result
      def call(params)
        values = yield validate(params)
        family_data = yield construct_family_data(values)

        Success(family_data)
      end

      private

      def validate(params)
        return Failure('family missing') unless params[:famiy] || params[:family].is_a?(::Family)
        return Failure('assistance year missing') unless params[:assistance_year]

        Success(params)
      end

      def construct_family_data(values)
        enrollments = get_enrollments(values)
        application = find_determined_application(values)
        primary_person = values[:family].primary_person

        results =
          values[:family].active_family_members.collect do |family_member|
            if application
              applicant =
                find_matching_applicant(application, family_member)
            end

            family_member_row = [
              values[:family].hbx_assigned_id,
              primary_person.hbx_id,
              values[:family].primary_applicant.id == family_member.id
            ]
            family_member_row += get_person_data(family_member.person)
            family_member_row += [family_member.is_active]
            family_member_row +=
              get_family_member_coverage_details(enrollments, family_member)
            family_member_row +=
              get_aca_individual_evidence_data(family_member.person)
            family_member_row += get_aptc_csr_evidence_data(family_member, values[:assistance_year], applicant)
            family_member_row
          end

        Success(results)
      end

      def find_determined_application(values)
        ::FinancialAssistance::Application
          .where(family_id: values[:family].id)
          .determined
          .by_year(values[:assistance_year])
          .last
      end

      def find_matching_applicant(application, family_member)
        application.active_applicants.detect do |applicant|
          applicant.family_member_id == family_member.id
        end
      end

      def get_enrollments(values)
        values[:family]
          .hbx_enrollments
          .where(
            :effective_on.gte => Date.new(values[:assistance_year], 1, 1),
            :effective_on.lte => Date.new(values[:assistance_year], 12, 31)
          )
          .enrolled_and_renewing
      end

      def get_family_member_coverage_details(enrollments, family_member)
        coverage_kinds = %w[health dental]
        member_enrollments =
          enrollments.where(
            'hbx_enrollment_members.applicant_id': family_member.id
          )

        coverage_kinds.collect do |coverage_kind|
          enrollments_by_kind =
            member_enrollments.by_coverage_kind(coverage_kind)
          current_coverage = enrollments_by_kind.last

          if current_coverage
            enrollment_member =
              current_coverage.hbx_enrollment_members
                              .detect do |enr_member|
                enr_member.applicant_id == family_member.id
              end

            [
              current_coverage.hbx_id,
              current_coverage.effective_on,
              enrollment_member.coverage_start_on,
              enrollment_member.coverage_end_on,
              (enrollments_by_kind.pluck(:hbx_id) - [current_coverage.hbx_id]).join(',')
            ]
          else
            append_nil(5)
          end
        end.flatten
      end

      def get_person_data(person = nil)
        if person
          [person.hbx_id, person.ssn, person.first_name, person.last_name]
        else
          append_nil(4)
        end
      end

      def get_aca_individual_evidence_data(person)
        verification_type_names = [
          'Social Security Number',
          'American Indian Status',
          'Citizenship',
          'Immigration status'
        ]

        verification_type_names.append(VerificationType::LOCATION_RESIDENCY) if EnrollRegistry.feature_enabled?(:location_residency_verification_type)

        data = if ::ConsumerRole::US_CITIZEN_STATUS_KINDS.include?(person.citizen_status)
                 [person.citizen_status, nil]
               else
                 [nil, person.citizen_status]
               end

        data + verification_type_names.collect do |type_name|
          verification_type =
            person.verification_types.active.where(type_name: type_name).first

          if verification_type
            [verification_type.validation_status, verification_type.due_date]
          else
            append_nil(2)
          end
        end.flatten
      end

      def tax_household_information(family_member, year)
        if EnrollRegistry.feature_enabled?(:temporary_configuration_enable_multi_tax_household_feature)
          thhg = family_member.family.active_thhg(year)
          return append_nil(2) if thhg.blank?

          thh = thhg.tax_households.where(:'tax_household_members.applicant_id' => family_member.id).first
          return append_nil(2) if thhg.blank?

          [thh.max_aptc&.to_f, thh.thhm_by(family_member)&.csr_percent_as_integer]
        else
          thh = family_member.family.active_household.latest_active_thh_with_year(year)
          return append_nil(2) if thh.blank?

          [thh.latest_eligibility_determination&.max_aptc&.to_f, thh.thhm_by(family_member)&.csr_percent_as_integer]
        end
      end

      def get_aptc_csr_evidence_data(family_member, year, applicant = nil)
        data = tax_household_information(family_member, year)

        return (data + append_nil(19)) unless applicant

        evidences = %w[
          income_evidence
          esi_evidence
          non_esi_evidence
          local_mec_evidence
        ]

        data + [
          applicant.application.hbx_id,
          applicant.application.created_at,
          applicant.is_applying_coverage,
          applicant.current_month_earned_incomes.sum(&:amount),
          applicant.current_month_unearned_incomes.sum(&:amount)
        ] + evidences.collect do |evidence_name|
              evidence_record = applicant.send(evidence_name)
              if evidence_record
                [evidence_record.aasm_state, evidence_record.due_on, evidence_record.has_determination_response?]
              else
                append_nil(3)
              end
            end.flatten + old_evidence_updated?(applicant)
      end

      def old_evidence_updated?(applicant)
        [:esi_mec, :aces_mec].collect do |key|
          evidence = applicant.evidences.detect{|rec| rec.key == key}
          (evidence && evidence.created_at != evidence.updated_at) ? true : false
        end
      end

      def append_nil(size)
        size.times.collect { nil }
      end
    end
  end
end
