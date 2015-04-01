class Message
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :inbox

  field :sender_id, type: BSON::ObjectId
  field :subject, type: String
  field :body, type: String

  validate :message_has_content

private
  def message_has_content
    errors.add(:base, "message subject and body cannot be blank") if subject.blank? && body.blank?
  end

end
