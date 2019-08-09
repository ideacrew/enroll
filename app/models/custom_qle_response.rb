class CustomQleResponse
  include Mongoid::Document

  embedded_in :custom_qle_question

  field :content, type: String
  field :accepted, type: Boolean
end
