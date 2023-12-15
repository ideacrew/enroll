# frozen_string_literal: true

module EventLogs
  class SessionDetail
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :sessionable, polymorphic: true

    field :session_id, type: String
    field :login_session_id, type: String
    field :portal, type: Symbol
  end
end
