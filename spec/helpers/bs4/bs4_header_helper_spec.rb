# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bs4::Bs4HeaderHelper, :type => :helper, dbclean: :after_each do

  context 'single role user' do
    let(:person) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }
    let(:consumer_role) { person.consumer_role }
    let(:current_user) { FactoryBot.create(:user, person: person) }

    describe 'my_portal_link_roles' do
      it "should return nil" do
        expect(my_portal_link_roles).to be_nil
      end
    end

    describe 'user_has_multiple_roles?' do
      it "should return false" do
        expect(user_has_multiple_roles?).to eq(false)
      end
    end

    describe 'bs4_portal_type' do
      it "should return a link when the consumer is through identity_validation" do
        consumer_role.update_attributes(identity_validation: 'valid', application_validation: 'valid')
        expect(bs4_portal_type("")).to start_with("<a")
      end

      it "should not return a link when the consumer is not through identity_validation" do
        consumer_role.update_attributes(identity_validation: 'na', application_validation: 'na')
        expect(bs4_portal_type("")).not_to start_with("<a")
      end
    end
  end

  context 'multi role user' do
    let(:person) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }
    let(:consumer_role) { person.consumer_role }
    let(:site) { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, site_key: ::EnrollRegistry[:enroll_app].settings(:site_key).item) }
    let(:broker_agency_organization) { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, site: site) }
    let(:broker_agency_id) { broker_agency_organization.broker_agency_profile.id }
    let(:current_user) { FactoryBot.create(:user, person: person) }

    before do
      consumer_role.update_attributes(identity_validation: 'valid', application_validation: 'valid')
      person.broker_agency_staff_roles.create!(
        {
          aasm_state: 'active',
          benefit_sponsors_broker_agency_profile_id: broker_agency_id
        }
      )
    end

    describe 'my_portal_link_roles' do
      it "should return multiple values" do
        expect(my_portal_link_roles.length).to be > 1
      end
    end

    describe 'user_has_multiple_roles?' do
      it "should return true" do
        expect(user_has_multiple_roles?).to eq(true)
      end
    end
  end

end
