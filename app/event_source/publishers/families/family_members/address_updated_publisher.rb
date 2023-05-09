# frozen_string_literal: true

module Publishers
  module Families
    module FamilyMembers
      # This class will register events for person address update
      class AddressUpdatedPublisher < EventSource::Event
        include ::EventSource::Publisher[amqp: 'enroll.families.family_members']

        register_event 'primary_member_address_relocated'
        register_event 'member_address_relocated'
      end
    end
  end
end

