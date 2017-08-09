require 'rails_helper'

RSpec.describe Users::SecurityQuestionResponsesController do
  context "new user" do
    let(:user) { create(:user, person: person) }
    let(:person) { double("Person", has_active_consumer_role?: true)}
    let(:security_question_one) { create(:security_question, title: "What was your dog's name?")}
    let(:security_question_two) { create(:security_question, title: "What elementary school did you attend?")}
    let(:security_question_three) { create(:security_question, title: "What is your favorite color?")}

    context "a signed in user" do
      before(:each) do
        sign_in user
        allow(User).to receive(:find).with(user.id).and_return(user)
      end

      it "should be able to create responses" do
        xhr :post, :create, { user_id: user.id, security_question_responses: [
                                                      { security_question_id: security_question_one.id, question_answer: 'Pluto' },
                                                      { security_question_id: security_question_two.id, question_answer: 'Wayside' },
                                                      { security_question_id: security_question_three.id, question_answer: 'Mauve' }
                                                    ]
                      }

        expect(response).to be_success
      end
    end
  end

end
