class RidpDocument
  include Mongoid::Document
  include Mongoid::Timestamps
  RIDP_DOCUMENT_KINDS = ['Driver License']
end
