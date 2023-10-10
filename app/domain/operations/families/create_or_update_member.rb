# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Families
    # Class for creating and updating family members in cooperation with Financial Assistance engine
    class CreateOrUpdateMember
      send(:include, Dry::Monads[:result, :do])

      # @param [ Bson::ID ] application_id Application ID
      # @param [ Bson::ID ] family_id Family ID
      # @return [ Family ] family Family

      def call(params)
        family_id, applicant_params = yield validate(params)
        applicant_params = yield sanitize_params(applicant_params)
        person = yield find_or_match_person(applicant_params)
        family_member_id = yield create_or_update_member(applicant_params, family_id, person)

        Success(family_member_id)
      end

      private

      def validate(params)
        Failure("family id is required") unless params[:family_id].present?
        Success([params[:family_id], params.except(:family_id)])
      end

      def sanitize_params(applicant_params)
        dob_value = applicant_params[:dob]

        applicant_params.merge!(dob: dob_value.strftime('%d/%m/%Y')) unless dob_value.is_a?(String)
        Success(applicant_params)
      end

      def create_or_update_member(params, family_id, person)
        result = if person.blank?
                   Operations::Families::CreateMember.new.call({applicant_params: params, family_id: family_id})
                 else
                   Operations::Families::UpdateMember.new.call({applicant_params: params, family_id: family_id, person: person})
                 end
        if result.success?
          family_member_id = result.success
          Success(family_member_id)
        else
          Failure(result.failure)
        end
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
