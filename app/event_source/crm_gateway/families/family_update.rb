# frozen_string_literal: true

module Events
  module SugarCrm
    module Families
      # This class will register event
      class FamilyUpdate < EventSource::Event
        publisher_path 'events.crm_gateway.families.family_update'
      end
    end
  end
end