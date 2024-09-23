# frozen_string_literal: true

module Events
  module Fdsh
    module Verifications
      module DmfDetermination
        # This class will register the event to send a cv3 family to FDSH for dmf determination
        class Requested < EventSource::Event
          publisher_path 'publishers.fdsh.verifications.dmf_determination.requested'

        end
      end
    end
  end
end