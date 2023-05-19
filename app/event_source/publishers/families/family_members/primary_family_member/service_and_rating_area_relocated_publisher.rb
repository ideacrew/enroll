# frozen_string_literal: true

module Publishers
  module Families
    module FamilyMembers
      module PrimaryFamilyMember
        # This class will register events for person address update
        class ServiceAndRatingAreaRelocatedPublisher < EventSource::Event
          include ::EventSource::Publisher[amqp: 'enroll.families.family_members.primary_family_member']

          register_event 'product_service_area_relocated'
          register_event 'premium_rating_area_relocated'
        end
      end
    end
  end
end

