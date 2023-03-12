module AuditLog
  module Actions
    class H4ccElegibility < AuditLog::Entry
        def initialize
            super
            self.action_name = "determine_hc4cc_eligibility"
        end

        def grant
            self.event_name = "h4cc_granted"
        end

        def deny
            self.event_name = "h4cc_denied"
        end    
    end
  end
end