require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "change_fein_new_model")

describe ChangeFeinNewModel, dbclean: :after_each do
  let(:given_task_name) { "change_fein_new_model" }
  let(:old_fein) { "123456789" }
  let(:new_fein) { "987654321" }
  subject { ChangeFeinNewModel.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "changing organization's fein in new model" do
    let(:site)            { build(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
    let(:issuer_profile)  { FactoryBot.create :benefit_sponsors_organizations_issuer_profile, assigned_site: site}
    let(:exempt_organization) { FactoryBot.create(:benefit_sponsors_organizations_exempt_organization, profiles: [issuer_profile], fein: old_fein)}

    context "when there is no existing fein" do
      before(:each) do
        allow(ENV).to receive(:[]).with("old_fein").and_return(old_fein)
        allow(ENV).to receive(:[]).with("new_fein").and_return(new_fein)
      end

      it "should update from old fein to new fein" do
        exempt_organization
        subject.migrate
        exempt_organization.reload
        expect(exempt_organization.fein).to eq new_fein
      end
    end

    context "when there is existing fein" do
      before(:each) do
        allow(ENV).to receive(:[]).with("old_fein").and_return(old_fein)
        allow(ENV).to receive(:[]).with("new_fein").and_return(old_fein)
      end

      it "should raise error" do
        exempt_organization
        expect { subject.migrate }.to raise_error("organization with fein #{old_fein} already present")
      end
    end
  end

end
