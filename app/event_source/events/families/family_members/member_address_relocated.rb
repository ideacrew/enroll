# frozen_string_literal: true

module Events
  module Families
    module FamilyMembers
        # This class will register event 'member_address_updated'
      class MemberAddressRelocated < EventSource::Event
        publisher_path 'publishers.families.family_members.address_updated_publisher'

      end
    end
  end
end

