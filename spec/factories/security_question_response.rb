FactoryGirl.define do
  factory :security_question_response do
    answer 'First security question'
    question_id { create(:security_question).id }
  end
end
