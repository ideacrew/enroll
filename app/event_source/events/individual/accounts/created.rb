# frozen_string_literal: true

module Events
  module Individual
    module Accounts
      # This class will register event
      class  Created < EventSource::Event
        publisher_path 'publishers.account_publisher'
      end
    end
  end
end