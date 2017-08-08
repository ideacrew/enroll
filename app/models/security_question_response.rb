class SecurityQuestionResponse
  include Mongoid::Document
  include Mongoid::Timestamps

  field :answer, type: String
  field :question_id, type: String

  embedded_in :user
  validates_presence_of :answer
end
