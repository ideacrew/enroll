# frozen_string_literal: true

class WorkflowStateTransition
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :transitional, polymorphic: true

  field :event, type: String
  field :from_state, type: String
  field :to_state, type: String
  field :transition_at, type: DateTime
  field :reason, type: String
  field :comment, type: String
  field :user_id, type: BSON::ObjectId
  field :metadata, type: Hash, default: {}

  before_validation :set_transition_timestamp

  default_scope   ->{ order(:"transition_at".desc) }

  # from_state may be nil on initial transition
  validates_presence_of :to_state, :transition_at

  def to_html
    if from_state.blank?
      "<div>#{transition_at.strftime("%m/%d/%Y %H:%M UTC")} - Application received.</div>".html_safe
    else
      "<div>#{transition_at.strftime("%m/%d/%Y %H:%M UTC")} - State changed from <b>#{from_state.camelcase}</b> to <b>#{to_state.camelcase}</b>.</div>".html_safe
    end
  end

  def metadata_has?(matching_hash)
    return false unless metadata.present?
    matching_hash.each_pair do |k,v|
      return false unless metadata.key?(k.to_s)
      return false unless metadata[k.to_s] == v
    end
    true
  end

private
  def set_transition_timestamp
    self.transition_at ||= Time.now
  end
end
