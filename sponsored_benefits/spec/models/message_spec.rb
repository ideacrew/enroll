require 'rails_helper'

RSpec.describe Message, :type => :model do

  let (:subject) {"marsha, marsha, marsha"}
  let (:body) {"she gets all the attention!"}

  describe ".new" do
    let(:valid_params) do
      {
        subject: subject,
        body: body
      }
    end

    context "with no arguments" do
      let(:params) {{}}

      it "should set created_at attribute" do
        expect(Message.new(**params).created_at).to be_nil
      end

      it "should be invalid" do
        message = Message.new(**params)
        expect(message.valid?).to be_falsey
        expect(message.errors.any?).to be_truthy
        expect(message.errors[:base]).to eq ["message subject and body cannot be blank"]
      end
    end

    context "with no subject" do
      let(:params) {valid_params.except(:subject)}

      it "should be valid" do
        expect(Message.new(**params).valid?).to be_truthy
      end
    end

    context "with no body" do
      let(:params) {valid_params.except(:body)}

      it "should be valid" do
        expect(Message.new(**params).valid?).to be_truthy
      end
    end
  end
end
