# frozen_string_literal: true

module Events
  module Iap
    module Applications
      # This class will register event
      class RequestFamilyPvcDetermination < EventSource::Event
        publisher_path 'publishers.iap.family_pvc_determination_publisher'

      end
    end
  end
end
