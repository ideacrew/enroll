class SecurityQuestionResponse
  include Mongoid::Document
  include Mongoid::Timestamps

  field :question_answer, type: String
  field :security_question_id, type: String

  embedded_in :user
  validates_presence_of :question_answer
end
