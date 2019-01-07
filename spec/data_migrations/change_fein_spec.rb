require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "change_fein")

describe ChangeFein, dbclean: :after_each do
  let(:given_task_name) { "change_fein" }
  let(:old_fein) { "123456789" }
  let(:new_fein) { "987654321" }
  subject { ChangeFein.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "changing organization's fein" do
    let(:organization) { FactoryGirl.create(:organization, fein: old_fein)}


    let(:site)                  { build(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
    let(:issuer_profile)  { FactoryGirl.create :benefit_sponsors_organizations_issuer_profile, assigned_site: site}
    let(:new_model_exempt_organization) { FactoryGirl.create(:benefit_sponsors_organizations_exempt_organization, profiles: [issuer_profile], fein: organization.fein)}

    before(:each) do
      allow(ENV).to receive(:[]).with("old_fein").and_return(old_fein)
      allow(ENV).to receive(:[]).with("new_fein").and_return(new_fein)
    end

    it "should update from old fein to new fein" do
      new_model_exempt_organization
      subject.migrate
      organization.reload
      expect(organization.fein).to eq new_fein
      new_model_exempt_organization.reload
      expect(new_model_exempt_organization.fein).to eq new_fein
    end

  end
end
