class WorkflowStateTransition
  include Mongoid::Document

  embedded_in :transitional, polymorphic: true

  field :from_state, type: String
  field :to_state, type: String
  field :transition_at, type: DateTime
  field :reason, type: String
  field :comment, type: String
  field :user_id, type: BSON::ObjectId

  default_scope   ->{ order(:"transition_at".desc) }

  # from_state may be nil on initial transition
  validates_presence_of :to_state, :transition_at

  def to_html
    if from_state.blank?
      "<div>#{transition_at.strftime("%m/%d/%Y")} - Application received.</div>".html_safe
    else
      "<div>#{transition_at.strftime("%m/%d/%Y")} - State changed from <b>#{from_state.camelcase}</b> to <b>#{to_state.camelcase}</b>.</div>".html_safe
    end
  end
end
