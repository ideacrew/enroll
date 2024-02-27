# frozen_string_literal: true

module People
  class EligibilitiesEventLog
    include Mongoid::Document
    include Mongoid::Timestamps
    include ::EventLog
  end
end
