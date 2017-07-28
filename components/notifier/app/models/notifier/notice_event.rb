module Notifier
  class NoticeEvent
    include Mongoid::Document

    field :event_name, type: String
    field :event_model_name, type: String
    field :event_model_id,   type: BSON::ObjectId
    field :event_model_payload, type: Hash
    field :received_at, type: DateTime

  end
end
