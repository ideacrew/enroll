# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Families
    class DropFamilyMember
      include Dry::Monads[:do, :result]

      #family id and person hbx_id
      def call(params)
        family = yield get_family(params)
        family_member = yield validate(family, params)
        result = yield drop_member(family, family_member)

        Success(result)
      end

      private

      def get_family(params)
        Operations::Families::Find.new.call(id: params[:family_id])
      end

      def validate(family, params)
        family_member = family.family_members.detect{|fm| fm.hbx_id == params[:person_hbx_id]}

        if family_member.present?
          Success(family_member)
        else
          Failure("Family and family member Id's does not match")
        end
      end

      def drop_member(family, family_member)
        family_member.update(is_active: false)
        family.active_household.remove_family_member(family_member)
        family.save!

        Success(true)
      rescue StandardError => e
        Failure("Failed to drop family_member due to #{e}")
      end
    end
  end
end
