module AuditLog
    class AuditLog
        include Mongoid::Document
        include Mongoid::Timestamps
   
        has_many :entries, class_name: "AuditLog::Entry" #, foreign_key: "audit_log_id"
          
    end
end