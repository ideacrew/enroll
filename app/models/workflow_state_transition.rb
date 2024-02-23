# frozen_string_literal: true

class WorkflowStateTransition
  include Mongoid::Document
  include Mongoid::Timestamps
  include HtmlScrubberUtil

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
      sanitize_html("<div>#{transition_at.strftime('%m/%d/%Y %H:%M UTC')} - Application received.</div>")
    else
      sanitize_html("<div>#{transition_at.strftime('%m/%d/%Y %H:%M UTC')} - State changed from <b>#{from_state.camelcase}</b> to <b>#{to_state.camelcase}</b>.</div>")
    end
  end

  def metadata_has?(matching_hash)
    return false if metadata.blank? || !matching_hash.is_a?(Hash)

    compare_hash = metadata.stringify_keys

    matching_hash.all? do |k, v|
      compare_hash.key?(k.to_s) && compare_hash[k.to_s] == v
    end
  end

private
  def set_transition_timestamp
    self.transition_at ||= Time.now
  end
end
