module AuditLog
    class OseeAuditLogEntry < Entry
        belongs_to :evidence, class_name: "Eligibilities::Osse::Evidence"

    end
        
end