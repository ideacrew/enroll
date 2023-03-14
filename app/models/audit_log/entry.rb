module AuditLog
    class Entry
        include Mongoid::Document
        include Mongoid::Timestamps
    
        # belongs_to :auditable, polymorphic: true, optional: true

        belongs_to :audit_log, class_name: "AuditLog::AuditLog" #, foreign_key: "audit_log_id"

        belongs_to :user,class_name: "User",  optional: true                                                    
  
        field :event_name, type: String # audit_key
        field :event_time, type: DateTime # when it happened

        field :comment, type: String
        field :session_id, type: String
        
    end
end