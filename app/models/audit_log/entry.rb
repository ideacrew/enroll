module AuditLog
    class Entry
        include Mongoid::Document
        include Mongoid::Timestamps
    
        belongs_to :auditable, polymorphic: true, optional: true #<- not sure if the opional is correct

        #optional, nested actions
        has_many :sub_actions, class_name: "AuditLog::Entry", foreign_key: "parent_id"                             
        belongs_to :parent, class_name: "AuditLog::Entry", optional: true                                                    
      
        # (optional) user that modified the object
        field :user, type:User
  
        field :action_name, type: String
        field :event_name, type: String # audit_key
        field :event_time, type: DateTime # when it happened

        field :comment, type: String
        field :session_id, type: String
        
    end
end