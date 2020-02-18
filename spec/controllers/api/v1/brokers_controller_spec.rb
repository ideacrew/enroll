require 'rails_helper'

RSpec.describe Api::V1::BrokersController, :type => :controller, :dbclean => :after_each do
  let(:user) { FactoryBot.create(:user) }

  describe "#index" do
    before :each do
      sign_in(user)
    end

    it "is successful" do
      expect(response.status).to eq 200
    end
  end
end
