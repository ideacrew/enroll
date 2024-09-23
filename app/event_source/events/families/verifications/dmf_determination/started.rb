# frozen_string_literal: true

module Events
  module Families
    module Verifications
      module DmfDetermination
        # This class will register event to initialize family dmf determination
        class Started < EventSource::Event
          publisher_path 'publishers.families.verifications.dmf_determination_publisher'
        end
      end
    end
  end
end