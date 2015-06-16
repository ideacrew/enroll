class Message
  include Mongoid::Document

  embedded_in :inbox

  field :sender_id, type: BSON::ObjectId
  field :subject, type: String
  field :body, type: String
  field :message_read, type: Boolean
  field :created_at, type: DateTime

  after_initialize :set_timestamp
  validate :message_has_content

  alias_method :message_read?, :message_read

private
  def set_timestamp
    self.created_at = Time.now.utc
  end

  def message_has_content
    errors.add(:base, "message subject and body cannot be blank") if subject.blank? && body.blank?
  end

end
