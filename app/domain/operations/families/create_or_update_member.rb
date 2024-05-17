# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Families
    # Class for creating and updating family members in cooperation with Financial Assistance engine
    class CreateOrUpdateMember
      include Dry::Monads[:do, :result]

      def call(params)
        family_id, applicant_params = yield validate(params)
        applicant_params = yield sanitize_params(applicant_params)
        person = yield find_or_match_person(applicant_params)
        member_hash = yield transform(applicant_params)
        family_member_id = yield create_or_update_member(member_hash, family_id, person)

        Success({ family_member_id: family_member_id })
      end

      private

      def validate(params)
        Failure("family id is required") unless params[:family_id].present?
        Success([params[:family_id], params[:applicant_params]])
      end

      def sanitize_params(applicant_params)
        dob_value = applicant_params[:dob]
        return Failure("dob is required") unless dob_value.present?

        applicant_params.merge!(dob: dob_value.strftime('%d/%m/%Y')) unless dob_value.is_a?(String)
        Success(applicant_params)
      end

      def transform(applicant_params)
        result = Operations::People::TransformApplicantToMember.new.call(applicant_params)
        return result if result.failure?

        hash = result.success
        hash.merge!(relationship: applicant_params[:relationship])

        Success(hash)
      end

      def create_or_update_member(member_hash, family_id, person)
        result = if person.blank?
                   Operations::Families::CreateMember.new.call({member_params: member_hash, family_id: family_id})
                 else
                   Operations::Families::UpdateMember.new.call({member_params: member_hash, family_id: family_id, person_hbx_id: person.hbx_id})
                 end

        if result.success?
          family_member_id = result.success
          Success(family_member_id)
        else
          Failure(result.failure)
        end
      rescue StandardError => e
        Rails.logger.error "Error while creating/updating family member: #{e.message}"
        Failure("Person creation failed: #{e.message}")
      end

      def find_or_match_person(applicant_params)
        params_hbx_id = applicant_params[:person_hbx_id]
        unless params_hbx_id.nil?
          person = Person.by_hbx_id(params_hbx_id).first
          return Success(person) if person.present?
        end

        match_criteria, records = Operations::People::Match.new.call({:dob => applicant_params[:dob],
                                                                      :last_name => applicant_params[:last_name],
                                                                      :first_name => applicant_params[:first_name],
                                                                      :ssn => applicant_params[:ssn]})

        return Success([]) unless records.present?
        return Success([]) unless [:ssn_present, :dob_present].include?(match_criteria)
        return Success([]) if match_criteria == :dob_present && params[:ssn].present? && records.first.ssn != params[:ssn]

        Success(records.first)
      end
    end
  end
end
