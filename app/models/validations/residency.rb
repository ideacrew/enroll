module Validations
  module Residency
    def self.included(klass)
      klass.class_eval do
        validates :citizen_status,
          inclusion: { in: Consumer::CITIZEN_STATUS_KINDS, message: "%{value} is not a valid citizen status" },
          allow_blank: false
        validates_presence_of :is_state_resident, :citizen_status
      end
    end
  end
end
