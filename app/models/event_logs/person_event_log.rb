# frozen_string_literal: true

module EventLogs
  class PersonEventLog
    include Mongoid::Document
    include Mongoid::Timestamps
    include ::EventLog
  end
end
