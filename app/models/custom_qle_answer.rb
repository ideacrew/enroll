class CustomQleAnswer
  include Mongoid::Document

  embedded_in :custom_qle_question, inverse_of: :answers
  embeds_one :custom_qle_question, as: :questionable

  field :content, type: String
  field :type, type: String
  field :option_1, type: String
  field :option_2, type: String
  field :option_3, type: String

end
