require "cancan/matchers"
require "rails_helper"

describe "User" do
  describe "abilities" do
    subject(:ability){ Ability.new(user) }
    let(:user) { FactoryGirl.create(:user) }

    context "when is an hbx staff user" do
      let(:user) { FactoryGirl.create(:user, :hbx_staff) }

      it { should be_able_to(:edit_plan_year, PlanYear.new) }
    end

    context "when is user" do
      it { should_not be_able_to(:edit_plan_year, PlanYear.new) }
    end
  end
end
