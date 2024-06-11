# frozen_string_literal: true

module Events
  module Private
    class FamilyMemberCreated < EventSource::Event
      publisher_path 'publishers.private.family_member_publisher'
    end
  end
end
