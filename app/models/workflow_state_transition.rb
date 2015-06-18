class WorkflowStateTransition
  include Mongoid::Document

  embedded_in :transitional, polymorphic: true

  field :end_state, type: String
  field :transition_on, type: Date
  field :reason, type: String
  field :comment, type: String
  field :user_id, type: BSON::ObjectId

  validates_presence_of :end_state, :transition_on

end
