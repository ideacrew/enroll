class AuditLog
    include Mongoid::Document
    include Mongoid::Timestamps

    DEFAULT_EVENT_TYPES = %i[h4cc_grant sep_created].freeze
    DEFAULT_ACTION_TYPES = %i[elegible ineligible].freeze

    # belongs_to :auditable, polymorphic: true, optional: true #<- not sure if this is correct

    field :subject_id, type: BSON::ObjectId # dup of auditable? - object that got affected
    field :subject_klass, type: String # dup of auditable? - object that got affected

    field :user_id, type: BSON::ObjectId # (optional) user that modified the object
    field :process_name, type: String #(optional)name of the operation if it was a process not a user

    field :event_name, type: String # audit_key
    field :action_name, type: String

    field :event_time, type: DateTime
    field :comment, type: String
    field :metadata, type: String
    # field :changes, type: String # JSON string with the changes on the subject.

    field :session_id: type: String
    #are we going to only track top level collections or embedded collections too ?
end

# user 
 # osse_controller
   # create 
     # on success
       # audit { :h4cc_grant, subject, }
       # subject.audit_logs.create()
   # update
     # 

# Is this to track just user actions? or also model changes? <-- this one
  # ex: single user action might result in multiple model changes
