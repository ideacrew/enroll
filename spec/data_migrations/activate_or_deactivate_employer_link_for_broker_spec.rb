require "rails_helper"
require File.join(Rails.root, 'app', 'data_migrations', 'activate_or_deactivate_employer_link_for_broker')

describe ActivateOrDeactivateEmployerLinkForBroker, dbclean: :around_each do

  let(:given_task_name) { 'activate_or_deactivate_employer_link_for_broker' }
  subject { ActivateOrDeactivateEmployerLinkForBroker.new(given_task_name, double(:current_scope => nil)) }

  let!(:rating_area)                    { FactoryBot.create_default :benefit_markets_locations_rating_area }
  let!(:service_area)                   { FactoryBot.create_default :benefit_markets_locations_service_area }
  let!(:site)                           { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
  let!(:organization)                   { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
  let!(:employer_profile)               { organization.employer_profile }
  let!(:broker_organization)            { FactoryBot.build(:benefit_sponsors_organizations_general_organization, site: site)}
  let!(:broker_agency_profile1)         { FactoryBot.create(:benefit_sponsors_organizations_broker_agency_profile, organization: broker_organization, legal_name: 'Legal Name1') }
  let(:active_plan_design_organization) {
                                          SponsoredBenefits::Organizations::PlanDesignOrganization.new(
                                            owner_profile_id: broker_agency_profile1._id,
                                            sponsor_profile_id: employer_profile._id,
                                            office_locations: employer_profile.office_locations,
                                            fein: organization.fein,
                                            legal_name: organization.legal_name,
                                            has_active_broker_relationship: false,
                                            sic_code: employer_profile.sic_code,
                                            broker_agency_profile:broker_agency_profile1
                                          )
                                        }

  describe 'given a task name', dbclean: :around_each do
    it 'has the given task name' do
      expect(subject.name).to eql given_task_name
    end
  end

  describe 'given plan design organization', dbclean: :around_each do

    context 'when both valid employer_profile feins is passed' do
      before :each do
        active_plan_design_organization.save!
      end

      it 'should successfully update plan_design_organization1' do
        ClimateControl.modify plan_design_org_id: active_plan_design_organization.id do
          expect(active_plan_design_organization.has_active_broker_relationship).to eq false
          subject.migrate
          active_plan_design_organization.reload
          expect(active_plan_design_organization.has_active_broker_relationship).to eq true
        end
      end
    end

    context 'when both invalid feins is passed' do
      it "should exit as there is no plan_design_organization for the given fein" do
        with_modified_env plan_design_org_id: broker_organization.id do
          expect(active_plan_design_organization.has_active_broker_relationship).to eq false
          subject.migrate
          expect(active_plan_design_organization.has_active_broker_relationship).to eq false
        end
      end
    end

    context 'when both invalid feins is passed' do
      it 'should not raise any exception' do
        with_modified_env plan_design_org_id: '' do
          expect {subject.migrate}.not_to raise_error
        end
      end
    end

    def with_modified_env(options, &block)
      ClimateControl.modify(options, &block)
    end
  end
end
