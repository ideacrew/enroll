# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module Application
      class RelationshipHandler
        include Dry::Monads[:do, :result]

        # @param [ Hash ] params Applicant Attributes
        # @return [ BenefitMarkets::Entities::Applicant ] applicant Applicant
        def call(params)
          _values = yield validate(params)
          _filter_result = yield filter(params)
          result = yield transmit_data

          Success(result)
        end

        private

        def validate(params)
          result = params[:relationship].is_a?(FinancialAssistance::Relationship)
          Success(result)
        end

        def filter(params)
          @application = params[:relationship].application
          applicant = params[:relationship].applicant
          @dependent = params[:relationship].relative
          if applicant.is_primary_applicant?
            Success('Notify enroll app')
          else
            Failure('Do not notify enroll app')
          end
        end

        def transmit_data
          begin
            create_or_update_member_params = { applicant_params: @dependent.attributes_for_export, family_id: @application.family_id }

            if FinancialAssistanceRegistry[:avoid_dup_hub_calls_on_applicant_create_or_update].enabled?
              create_or_update_member_params[:applicant_params].merge!(is_primary_applicant: @dependent.is_primary_applicant?, skip_consumer_role_callbacks: true, skip_person_updated_event_callback: true)
              ::Operations::Families::CreateOrUpdateMember.new.call(create_or_update_member_params)
            else
              ::FinancialAssistance::Operations::Families::CreateOrUpdateMember.new.call(params: create_or_update_member_params)
            end
          rescue StandardError => e
            Rails.logger.error {"Unable to propagate_applicant for person hbx_id: #{@dependent.person_hbx_id} | application_hbx_id: #{@application.hbx_id} | family_id: #{@application.family_id} due to #{e.message}"} unless Rails.env.test?
          end

          Success('Successfully notified enroll app')
        end
      end
    end
  end
end
