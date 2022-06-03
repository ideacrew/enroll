class Document
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :documentable, polymorphic: true
end