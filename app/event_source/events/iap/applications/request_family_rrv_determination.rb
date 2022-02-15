# frozen_string_literal: true

module Events
  module Iap
    module Applications
      # This class will register event
      class RequestFamilyRrvDetermination < EventSource::Event
        publisher_path 'publishers.iap.family_rrv_determination_publisher'

      end
    end
  end
end