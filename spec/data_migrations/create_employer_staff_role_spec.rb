require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "create_employer_staff_role")
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"

describe CreateEmployerStaffRole, dbclean: :after_each do
  let(:given_task_name) { "create_employer_staff_role" }
  subject { CreateEmployerStaffRole.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe 'for migrate' do
    let!(:person)                       { FactoryBot.create(:person) }
    let!(:rating_area)                  { FactoryBot.create_default :benefit_markets_locations_rating_area }
    let!(:service_area)                 { FactoryBot.create_default :benefit_markets_locations_service_area }
    let!(:site)                         { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
    let!(:organization)                 { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
    let!(:employer_profile)             { organization.employer_profile }

    context 'for successful data_migration' do
      let!(:user)                        { FactoryBot.create(:user, person: person) }

      before :each do
        ENV['person_hbx_id'] = person.hbx_id
        ENV['employer_profile_id'] = employer_profile.id.to_s
        subject.migrate
        person.reload
        user.reload
        @staff_role ||= person.employer_staff_roles.first
      end

      it 'should have the expected employer_profile id' do
        expect(@staff_role.benefit_sponsor_employer_profile_id.to_s).to eq employer_profile.id.to_s
      end

      it 'should have the expected aasm_state' do
        expect(@staff_role.aasm_state).to eq 'is_active'
      end

      it 'should have employer_staff as one of the roles' do
        expect(user.roles).to include('employer_staff')
      end
    end

    context 'for unsuccessful data migration' do
      before :each do
        ENV['person_hbx_id'] = person.hbx_id
        ENV['employer_profile_id'] = employer_profile.id.to_s
        subject.migrate
        person.reload
        @staff_role ||= person.employer_staff_roles.first
      end

      it 'should return nil as there is no user' do
        expect(@staff_role).to eq nil
      end      
    end
  end
end
