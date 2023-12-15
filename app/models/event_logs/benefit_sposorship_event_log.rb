# frozen_string_literal: true

module EventLogs
  class BenefitSponsorshipEventLog
    include Mongoid::Document
    include Mongoid::Timestamps
    include ::EventLog
  end
end
