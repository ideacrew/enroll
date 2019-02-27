require "rails_helper"
require "#{SponsoredBenefits::Engine.root}/spec/shared_contexts/sponsored_benefits"

describe Subscribers::DefaultGaChanged do
  include_context "set up broker agency profile for BQT, by using configuration settings"
  it "should subscribe to the correct event" do
    expect(Subscribers::DefaultGaChanged.subscription_details).to eq ["acapi.info.events.broker.default_ga_changed"]
  end

  describe "given a message to handle", dbclean: :after_each do
    let(:person) { FactoryGirl.create(:person, :with_broker_role) }
    let!(:broker_role) { 
      role = person.broker_role
      role.broker_agency_profile = owner_profile
      role.save
      role
    }
    let(:hbx_id) { person.hbx_id }

    context "that has a hbx_id without default_ga" do
      let(:message) { { "broker_id" => hbx_id, "pre_default_ga_id" => general_agency_profile.id.to_s } }
      let(:pdo) {plan_design_organization_with_assigned_ga}

      it "should not do clear without pre_default_ga_id" do
        expect(subject).not_to receive(:send_general_agency_assign_msg)
        subject.call(nil, nil, nil, nil, message.except("pre_default_ga_id"))
      end

      it "should do clear with pre_default_ga_id" do
        pdo
        expect(subject).to receive(:send_general_agency_assign_msg)
        subject.call(nil, nil, nil, nil, message)
        pdo.reload
        expect(pdo.active_general_agency_account).to eq nil
      end
    end

    context "that has a hbx_id with default_ga", dbclean: :after_each do
      let(:message) { { "broker_id" => hbx_id, "pre_default_ga_id" => general_agency_profile.id.to_s } }
      let(:new_ga) { ga_profile }
      let!(:pdo) { plan_design_organization }
      let!(:pdo_with_ga) {plan_design_organization_with_assigned_ga}

      before :each do
        owner_profile.default_general_agency_profile = new_ga
        owner_profile.save
      end

      it "should do change when employer_profile does not have active general_agency_profile" do
        pdo.general_agency_accounts.delete_all
        expect(pdo.active_general_agency_account).to eq nil
        expect(subject).to receive(:send_general_agency_assign_msg)
        subject.call(nil, nil, nil, nil, message)
        pdo.reload
        expect(pdo.active_general_agency_account.general_agency_profile).to eq new_ga
      end

      it "should do not change when employer_profile have active general_agency_profile" do
        expect(pdo_with_ga.active_general_agency_account).not_to eq nil
        expect(subject).not_to receive(:send_general_agency_assign_msg)
        subject.call(nil, nil, nil, nil, message)
        pdo_with_ga.reload
        expect(pdo_with_ga.active_general_agency_account.general_agency_profile).not_to eq new_ga
      end
    end
  end
end
