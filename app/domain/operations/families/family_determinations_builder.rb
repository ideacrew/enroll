# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Families
    # FindFamilyMember
    class FamilyDeterminationsBuilder
      send(:include, Dry::Monads[:result, :do])

      def call(params)
        values = yield validate(params)
        application = yield find_application(values)
        determination = yield build_determination(values, application)

        Success(determination)
      end

      private

      def validate(params)
        params[:family] ? Success(params) : Failure('family missing')
      end

      def find_application(values)
        application =
          ::FinancialAssistance::Application.where(
            family_id: values[:family].id,
            aasm_state: :determined
          ).last

        if application
          Success(application)
        else
          Failure('unable to find valid determined FAA application')
        end
      end

      def build_determination(values, application)
        member_determinations =
          values[:family].family_members.collect do |family_member|
            ::Operations::FamilyMembers::FamilyMemberDeterminationsBuilder.new.call(
              family_member: family_member,
              application: application
            )
          end

        if member_determinations.any?(&:failure?)
          Failure(member_determinations.select(&:failure?).collect(&:failure))
        else
          Success(
            {
              subjects: member_determinations.collect(&:success).inject(:merge)
            }
          )
        end
      end
    end
  end
end
