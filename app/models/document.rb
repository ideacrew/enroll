class Document
  include Mongoid::Document
  include Mongoid::Timestamps

  # Enable polymorphic associations
  embedded_in :documentable, polymorphic: true

  field :uri, type: String

  # Dublin Core metadata elements
  field :title, type: String
  field :creator, type: String
  field :subject, type: String
  field :description, type: String
  field :publisher, type: String
  field :contributor, type: String
  field :date, type: Date
  field :type, type: String
  field :format, type: String
  field :identifier, type: String
  field :source, type: String
  field :language, type: String, default: "en"
  field :relation, type: String
  field :coverage, type: String
  field :rights, type: String

  field :tags, type: Array, default: []


end
