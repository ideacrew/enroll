# frozen_string_literal: true

module Publishers
  module Families
    module IapApplications
      module Rrvs
        # This class will register event 'determination_build_requested' and 'determination_requested'
        class IncomeEvidencesPublisher < EventSource::Event
          include ::EventSource::Publisher[amqp: 'enroll.ivl_market.families.iap_applications.rrvs.income_evidences']

          register_event 'determination_build_requested'
          register_event 'determination_requested'
        end
      end
    end
  end
end

