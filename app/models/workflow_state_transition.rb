class WorkflowStateTransition
  include Mongoid::Document

  embedded_in :transitional, polymorphic: true

  field :from_state, type: String
  field :to_state, type: String
  field :transition_at, type: DateTime
  field :reason, type: String
  field :comment, type: String
  field :user_id, type: BSON::ObjectId

  # from_state may be nil on initial transition
  validates_presence_of :to_state, :transition_at

end
