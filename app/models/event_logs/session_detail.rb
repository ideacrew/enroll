module EventLogs
  class SessionDetail
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :sessionable, polymorphic: true

    field :session_id, type: String
    field :portal, type: Symbol
    field :person_id, type: String
  end
end
