# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'csv'

module Operations
  # export evidences
  module Eligibilities
    class FamilyEvidencesDataExport
      include Dry::Monads[:result, :do]

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
        unless params[:famiy] || params[:family].is_a?(::Family)
          return Failure('family missing')
        end
        unless params[:assistance_year]
          return Failure('assistance year missing')
        end

        Success(params)
      end

      def construct_family_data(values)
        enrollments = get_enrollments(values)
        application = find_determined_application(values)
        primary_person = values[:family].primary_person

        results =
          values[:family].family_members.collect do |family_member|
            applicant =
              find_matching_applicant(application, family_member) if application

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
            family_member_row += get_aptc_csr_evidence_data(applicant)
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
                .detect do |enrollment_member|
                enrollment_member.applicant_id == family_member.id
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
          [person.hbx_id, person.first_name, person.last_name]
        else
          append_nil(3)
        end
      end

      def get_aca_individual_evidence_data(person)
        verification_type_names = [
          'Social Security Number',
          'American Indian Status',
          'Citizenship',
          'Immigration status'
        ]

        verification_type_names.collect do |type_name|
          verification_type =
            person.verification_types.active.where(type_name: type_name).first

          if verification_type
            [verification_type.validation_status, verification_type.due_date]
          else
            append_nil(2)
          end
        end.flatten
      end

      def get_aptc_csr_evidence_data(applicant = nil)
        return append_nil(10) unless applicant

        evidences = %w[
          income_evidence
          esi_evidence
          non_esi_evidence
          local_mec_evidence
        ]

        [applicant.application.hbx_id, applicant.is_applying_coverage] +
          evidences.collect do |evidence_name|
            evidence_record = applicant.send(evidence_name)
            if evidence_record
              [evidence_record.aasm_state, evidence_record.due_on]
            else
              append_nil(2)
            end
          end.flatten
      end

      def append_nil(size)
        size.times.collect { nil }
      end
    end
  end
end
