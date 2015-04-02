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
        expect(Message.new(**params).created_at).to_not be_nil
      end

      it "should be invalid" do
        expect(Message.new(**params).valid?).to be_false
      end
    end

    context "with no subject" do
      let(:params) {valid_params.except(:subject)}

      it "should be valid" do
        expect(Message.new(**params).valid?).to be_true
      end
    end

    context "with no body" do
      let(:params) {valid_params.except(:body)}

      it "should be valid" do
        expect(Message.new(**params).valid?).to be_true
      end
    end
  end
end
