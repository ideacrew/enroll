class Message
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :inbox

  field :sender_id, type: BSON::ObjectId
  field :subject, type: String
  field :body, type: String

end
