# frozen_string_literal: true

module Events
  module Families
    module FamilyMembers
      module PrimaryFamilyMember
        # This class will register event 'member_address_updated'
        class ProductServiceAreaRelocated < EventSource::Event
          publisher_path 'publishers.families.family_members.primary_family_member.service_and_rating_area_relocated_publisher'

        end
      end
    end
  end
end

