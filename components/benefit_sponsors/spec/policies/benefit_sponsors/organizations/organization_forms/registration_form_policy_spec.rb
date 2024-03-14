# frozen_string_literal: true

require "rails_helper"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

# benefit_sponsors module
module BenefitSponsors
  RSpec.describe Organizations::OrganizationForms::RegistrationFormPolicy, dbclean: :after_each  do
    let!(:user) { FactoryBot.create(:user, :with_hbx_staff_role) }
    let!(:person) {FactoryBot.create(:person, user: user)}
    let!(:super_admin_permission) { FactoryBot.create(:permission, :super_admin) }
    let!(:read_only_permission) { FactoryBot.create(:permission, :hbx_read_only) }
    let!(:profile_type) {'broker_agency'}
    let!(:site) { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
    let!(:organization_with_hbx_profile)  { site.owner_organization }

    subject { BenefitSponsors::Organizations::OrganizationForms::RegistrationFormPolicy.new(user, nil) }

    before :each do
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:edit_broker_agency_profile).and_return(true)
      allow(subject).to receive(:profile_type).and_return(profile_type)
    end

    context "broker_agency_profile with an hbx_admin with edit_broker_agency_profile permissions" do

      before do
        user.person.build_hbx_staff_role(hbx_profile_id: organization_with_hbx_profile.hbx_profile.id)
        user.person.hbx_staff_role.permission_id = super_admin_permission.id
        user.person.hbx_staff_role.save!
      end

      it "should be updatable" do
        expect(subject.update?).to be_truthy
      end
    end

    context "broker_agency_profile with an hbx_admin without edit_broker_agency_profile permissions" do
      before do
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:edit_broker_agency_profile).and_return(true)
        allow(subject).to receive(:profile_type).and_return(profile_type)
        user.person.build_hbx_staff_role(hbx_profile_id: organization_with_hbx_profile.hbx_profile.id)
        user.person.hbx_staff_role.permission_id = read_only_permission.id
        user.person.hbx_staff_role.save!
      end

      it "should not be updatable" do
        expect(subject.update?).to be_falsey
      end
    end
  end
end
