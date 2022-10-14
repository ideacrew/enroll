# frozen_string_literal: true

module Publishers
  module Applications
    module AptcCsrCredits
      module Renewals
    # Publisher will send request payload to medicaid gateway for determinations
        class NoticePublisher
          include ::EventSource::Publisher[amqp: 'enroll.applications.aptc_csr_credits.renewals.notice']

          register_event 'determined_uqhp_eligible'
          register_event 'determined_mixed_determination'
          register_event 'determined_magi_medicaid_eligible'
          register_event 'determined_totally_ineligible'
          register_event 'determined_medicaid_chip_eligible'
          register_event 'determined_aptc_eligible'
        end
      end
    end
  end
end
