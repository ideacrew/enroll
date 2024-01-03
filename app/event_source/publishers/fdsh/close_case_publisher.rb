# frozen_string_literal: true

module Publishers
  module Fdsh
    # Publisher will send a close case request to cms
    class CloseCasePublisher
      include ::EventSource::Publisher[amqp: 'fdsh.close_case_request']

      register_event 'close_case_request'

    end
  end
end
