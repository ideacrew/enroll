module AuditLog
    class Entry
        include Mongoid::Document
        include Mongoid::Timestamps
    
        belongs_to :auditable, polymorphic: true, optional: true

        #optional, nested actions
        has_many :sub_actions, class_name: "AuditLog::Entry", foreign_key: "parent_id"                             
        belongs_to :parent, class_name: "AuditLog::Entry", optional: true                                                    
      
        # (optional) user that modified the object
        # field :user, type:User
        belongs_to :user,class_name: "User",  optional: true                                                    
  
        # this may be dup, since with STI we will get the kind of action
        field :action_name, type: String
        field :event_name, type: String # audit_key
        field :event_time, type: DateTime # when it happened

        field :comment, type: String
        field :session_id, type: String
        
    end
end