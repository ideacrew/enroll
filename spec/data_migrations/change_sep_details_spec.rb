require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "change_sep_details")

describe ChangeSepDetails, dbclean: :after_each do

  let(:given_task_name) { "change_sep_details" }
  subject { ChangeSepDetails.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  context "add coverage household member", dbclean: :after_each do

    let(:family) { FactoryGirl.create(:family, :with_primary_family_member)}
    let(:sep) { FactoryGirl.create(:special_enrollment_period, family: family, market_kind: "shop")}
    let(:enrollment) { FactoryGirl.create(:hbx_enrollment, special_enrollment_period_id: sep.id, 
                        household: family.active_household, aasm_state: "coverage_selected", enrollment_kind: "special_enrollment")}

    before :each do
      allow(ENV).to receive(:[]).with('action').and_return "change_market_kind"
      allow(ENV).to receive(:[]).with('sep_id').and_return sep.id
    end

    it "should not change the sep market kind if matches with qle market kind" do
      subject.migrate
      sep.reload
      expect(sep.market_kind).to eq "shop"
    end

    it "should not change the sep market kind if household has active coverage with this SEP" do
      enrollment
      sep.qualifying_life_event_kind.update_attributes(market_kind: "individual")
      subject.migrate
      sep.reload
      expect(sep.market_kind).to eq "shop"
    end

    it "should change the sep market kind if not matches with qle market kind" do
      sep.qualifying_life_event_kind.update_attributes(market_kind: "individual")
      subject.migrate
      sep.reload
      expect(sep.market_kind).to eq "individual"
    end
  end
end
