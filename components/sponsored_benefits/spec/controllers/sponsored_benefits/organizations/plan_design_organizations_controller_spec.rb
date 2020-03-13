require 'rails_helper'

USER_ROLES = [:with_hbx_staff_role, :without_hbx_staff_role]

module SponsoredBenefits
  RSpec.describe Organizations::PlanDesignOrganizationsController, type: :controller, dbclean: :around_each  do
    routes { SponsoredBenefits::Engine.routes }

    let(:valid_session) { {} }
    let(:current_person) { double(:current_person) }
    let(:active_user) { double(:active_user) }
    let(:employer) { double(:employer, id: "11111", name: 'ABC Company', sic_code: '0197') }
    let(:broker) { double(:broker, id: 2) }
    let(:broker_role) { double(:broker_role, id: 3) }

    let(:broker_agency_profile_id) { "5ac4cb58be0a6c3ef400009b" }
    let(:broker_agency_profile) { double(:sponsored_benefits_broker_agency_profile, id: broker_agency_profile_id, persisted: true, fein: "5555", hbx_id: "123312",
                                    legal_name: "ba-name", dba: "alternate", is_active: true, organization: plan_design_organization, office_locations: []) }
    let(:old_broker_agency_profile) { build(:sponsored_benefits_broker_agency_profile) }
    let!(:plan_design_organization) { create(:sponsored_benefits_plan_design_organization, sponsor_profile_id: employer.id,
                                                                        owner_profile_id: broker_agency_profile_id,
                                                                        legal_name: employer.name,
                                                                        sic_code: employer.sic_code ) }

    let!(:prospect_plan_design_organization) { create(:sponsored_benefits_plan_design_organization, sponsor_profile_id: nil,
                                                                    owner_profile_id: broker_agency_profile_id,
                                                                    legal_name: employer.name,
                                                                    sic_code: employer.sic_code ) }
    let(:user) { double(:user) }
    let(:datatable) { double(:datatable) }
    let(:sic_codes) { double(:sic_codes) }

    let(:valid_attributes) {
      {
        "legal_name"  =>  "Some Name",
        "dba"         =>  "",
        "entity_kind" =>  "",
        "sic_code"    =>  "0116",
        "office_locations_attributes" =>
              {"0"=>
                  { "_destroy" => "false",
                    "address_attributes" =>
                      { "kind"      =>  "primary",
                        "address_1" =>  "",
                        "address_2" =>  "",
                        "city"      =>  "",
                        "state"     =>  "",
                        "zip"       =>  "01001",
                        "county"    =>  "Hampden"
                      }
                  }
        }
      }
    }

    let(:invalid_attributes) {
      {
        "legal_name"  =>  nil,
        "sic_code"    =>  nil,
        "office_locations_attributes" =>
              {"0"=>
                  { "address_attributes" =>
                      { "kind"      =>  "primary",
                        "zip"       =>  "01001",
                        "county"    =>  "Hampden"
                      }
                  }
        }
      }
    }

    before do
      allow(subject).to receive(:current_person).and_return(current_person)
      allow(current_person).to receive(:broker_role).and_return(broker_role)
      allow(broker_role).to receive(:broker_agency_profile_id).and_return(broker_agency_profile.id)
      allow(subject).to receive(:active_user).and_return(active_user)
      allow(active_user).to receive(:has_hbx_staff_role?).and_return(false)
      allow(broker_role).to receive(:benefit_sponsors_broker_agency_profile_id).and_return(broker_agency_profile.id)
      allow(BenefitSponsors::Organizations::Profile).to receive(:find).with(broker_agency_profile.id).and_return(broker_agency_profile)
    end

    describe "GET #new" do
      USER_ROLES.each do |role|
        context "for user #{role}" do
          before do
            allow(subject).to receive(:init_organization).and_return(prospect_plan_design_organization)
            allow(active_user).to receive(:has_hbx_staff_role?).and_return( role == :with_hbx_staff_role ? true : false)
          end

          it "returns a success response" do
            get :new, { plan_design_organization_id: prospect_plan_design_organization.id, broker_agency_id:  broker_agency_profile.id}, valid_session
            expect(response).to be_success
          end
        end
      end
    end

    describe "GET #edit" do
      USER_ROLES.each do |role|
        context "for user #{role}" do
          before do
            allow(subject).to receive(:get_sic_codes).and_return(sic_codes)
            allow(active_user).to receive(:has_hbx_staff_role?).and_return( role == :with_hbx_staff_role ? true : false)
          end

          it "returns a success response" do
            get :edit, { id: prospect_plan_design_organization.to_param }, valid_session
            expect(response).to be_success
          end
        end
      end
    end

    describe "POST #create" do
      USER_ROLES.each do |role|
        context "for user #{role}" do
          before do
            allow(BrokerAgencyProfile).to receive(:find).with(BSON::ObjectId.from_string(broker_agency_profile.id)).and_return(broker_agency_profile)
            allow(SponsoredBenefits::Organizations::BrokerAgencyProfile).to receive(:find_or_initialize_by).with(:fein).and_return("223232323")
            allow(active_user).to receive(:has_hbx_staff_role?).and_return( role == :with_hbx_staff_role ? true : false)
          end

          context "with valid params" do
            it "creates a new Organizations::PlanDesignOrganization" do
              expect {
                post :create, { organization: valid_attributes, broker_agency_id: broker_agency_profile.id, format: 'js'}, valid_session
              }.to change { Organizations::PlanDesignOrganization.all.count }.by(1)
            end

            it "redirects to employers_organizations_broker_agency_profile_path(broker_agency_profile)" do
              post :create, { organization: valid_attributes, broker_agency_id: broker_agency_profile.id, format: 'js'}, valid_session
              expect(subject).to redirect_to(employers_organizations_broker_agency_profile_path(broker_agency_profile))
            end
          end

          context "with invalid params" do
            before do
              allow(subject).to receive(:init_organization).and_return(prospect_plan_design_organization)
            end

            it "creates a new Organizations::PlanDesignOrganization" do
              expect {
                post :create, { organization: invalid_attributes, broker_agency_id: broker_agency_profile.id, format: 'js'}, valid_session
              }.to change { Organizations::PlanDesignOrganization.all.count }.by(0)
            end

            it "renders the new view" do
              post :create, { organization: invalid_attributes, broker_agency_id: broker_agency_profile.id, format: 'js'}, valid_session
              expect(response).to render_template(:new)
            end
          end
        end
      end
    end

    describe "PATCH #update" do

      let!(:valid_attributes) {
        {
          "legal_name"  =>  "Some Name",
          "dba"         =>  "",
          "entity_kind" =>  "",
          "sic_code"    =>  "0116",
          "office_locations_attributes" =>
            {
              "0"=>
                {"id" => prospect_plan_design_organization.office_locations.first.id.to_s,
                 "_destroy" => "false",
                 "address_attributes" =>
                   { "id" => prospect_plan_design_organization.office_locations.first.address.id.to_s,
                     "kind"      =>  "primary",
                     "address_1" =>  "",
                     "address_2" =>  "",
                     "city"      =>  "",
                     "state"     =>  "",
                     "zip"       =>  "01001",
                     "county"    =>  "Hampden"
                   }
                }
            }
        }
      }

      USER_ROLES.each do |role|
        context "for user #{role}" do
          before do
            allow(BrokerAgencyProfile).to receive(:find).with(BSON::ObjectId.from_string(broker_agency_profile.id)).and_return(broker_agency_profile)
            allow(SponsoredBenefits::Organizations::BrokerAgencyProfile).to receive(:find_or_initialize_by).with(:fein).and_return("223232323")
            allow(subject).to receive(:get_sic_codes).and_return(sic_codes)
            allow(active_user).to receive(:has_hbx_staff_role?).and_return( role == :with_hbx_staff_role ? true : false)
          end

          context "with valid params" do
            let(:updated_valid_attributes) {
              valid_attributes["legal_name"] = "Some New Name"
              valid_attributes
            }

            it "updates Organizations::PlanDesignOrganization" do
              expect {
                patch :update, { organization: updated_valid_attributes, id: prospect_plan_design_organization.id, format: 'js' }, valid_session
              }.to change { prospect_plan_design_organization.reload.legal_name }.to('Some New Name')
            end

            it "redirects to employers_organizations_broker_agency_profile_path(broker_agency_profile)" do
              patch :update, { organization: updated_valid_attributes, id: prospect_plan_design_organization.id, format: 'js' }, valid_session
              expect(subject).to redirect_to(employers_organizations_broker_agency_profile_path(broker_agency_profile))
            end

            it "does not create a new Organizations::PlanDesignOrganization" do
              expect {
                patch :update, { organization: valid_attributes, id: prospect_plan_design_organization.id, format: 'js'}, valid_session
              }.to change { Organizations::PlanDesignOrganization.all.count }.by(0)
            end
          end

          context 'office locations #update' do
            let(:effective_period_start_on) {TimeKeeper.date_of_record.end_of_month + 1.day + 1.month}
            let(:effective_period_end_on) {effective_period_start_on + 1.year - 1.day}
            let(:effective_period) {effective_period_start_on..effective_period_end_on}

            let(:open_enrollment_period_start_on) {effective_period_start_on.prev_month}
            let(:open_enrollment_period_end_on) {open_enrollment_period_start_on + 9.days}
            let(:open_enrollment_period) {open_enrollment_period_start_on..open_enrollment_period_end_on}

            let(:params) do
              {
                effective_period: effective_period,
                open_enrollment_period: open_enrollment_period,
              }
            end
            let(:plan_design_proposal) {build(:plan_design_proposal)}
            let(:benefit_application) {SponsoredBenefits::BenefitApplications::BenefitApplication.new(params)}
            let(:benefit_sponsorship) do
              SponsoredBenefits::BenefitSponsorships::BenefitSponsorship.new(
                benefit_market: 'aca_shop_cca',
                enrollment_frequency: 'rolling_month'
              )
            end

            let!(:new_attributes) {
              {
                "legal_name"  =>  "Some Name",
                "dba"         =>  "",
                "entity_kind" =>  "",
                "sic_code"    =>  "0116",
                "office_locations_attributes" =>
                  {
                    "0"=>
                      {"_destroy" => "false",
                       "address_attributes" =>
                         { "kind"      =>  "primary",
                           "address_1" =>  "test 2nd primary",
                           "address_2" =>  "",
                           "city"      =>  "",
                           "state"     =>  "mn",
                           "zip"       =>  "01001",
                           "county"    =>  "Hampden"
                         }
                      }
                  }
              }
            }

            let(:profile) {SponsoredBenefits::Organizations::AcaShopCcaEmployerProfile.new}
            let(:updated_valid_attributes) {
              valid_attributes['legal_name'] = 'Some New Name'
              valid_attributes
            }
            let(:plan) {FactoryGirl.create(:plan, :with_premium_tables)}

            before do
              prospect_plan_design_organization.plan_design_proposals << [plan_design_proposal]
              plan_design_proposal.profile = profile
              profile.benefit_sponsorships = [benefit_sponsorship]
              benefit_sponsorship.benefit_applications = [benefit_application]
              bg = benefit_application.benefit_groups.build
              bg.build_relationship_benefits
              bg.build_composite_tier_contributions
              bg.assign_attributes(reference_plan_id: plan.id, plan_option_kind: 'sole_source', elected_plans: [plan])
              bg.composite_tier_contributions[0].employer_contribution_percent = 60
              bg.composite_tier_contributions[3].employer_contribution_percent = 50
              bg.save!
              prospect_plan_design_organization.save
            end

            it 'should not delete persisted office locations when embedded models are invalid' do
              address_1_before_update = prospect_plan_design_organization.office_locations.first.address.address_1
              prospect_plan_design_organization.plan_design_proposals.first.profile.benefit_sponsorships.first.benefit_applications.first.benefit_groups.first.relationship_benefits.delete_all
              patch :update, {organization: updated_valid_attributes, id: prospect_plan_design_organization.id, format: 'js'}, valid_session
              expect(subject).to redirect_to(edit_organizations_plan_design_organization_path(prospect_plan_design_organization))
              prospect_plan_design_organization.reload
              address_1_after_update = prospect_plan_design_organization.office_locations.first.address
              expect(address_1_after_update.address_1).to eq address_1_before_update
            end

            it 'should update office locations when embedded models are valid' do
              address_1_before_update = prospect_plan_design_organization.office_locations.first.address.address_1
              patch :update, {organization: updated_valid_attributes, id: prospect_plan_design_organization.id, format: 'js'}, valid_session
              expect(subject).to redirect_to(employers_organizations_broker_agency_profile_path(broker_agency_profile))
              prospect_plan_design_organization.reload
              address_1_after_update = prospect_plan_design_organization.office_locations.first.address
              expect(address_1_after_update).not_to eq address_1_before_update
            end

            it 'should not update office locations when embedded models are valid and primary location exists' do
              locations_before_update = prospect_plan_design_organization.office_locations.count
              patch :update, {organization: updated_valid_attributes, id: prospect_plan_design_organization.id, format: 'js'}, valid_session
              expect(subject).to redirect_to(employers_organizations_broker_agency_profile_path(broker_agency_profile))
              prospect_plan_design_organization.reload
              locations_after_update = prospect_plan_design_organization.office_locations.count
              expect(locations_before_update).to eq locations_after_update
            end
          end

          context "with invalid params" do
            it "does not update Organizations::PlanDesignOrganization" do
              expect {
                patch :update, { organization: invalid_attributes, id: prospect_plan_design_organization.id, format: 'js' }, valid_session
              }.not_to change { prospect_plan_design_organization.reload.legal_name }
            end

            it "renders edit with flash error" do
              patch :update, { organization: invalid_attributes, id: prospect_plan_design_organization.id, format: 'js' }, valid_session
              expect(subject).to redirect_to(edit_organizations_plan_design_organization_path(prospect_plan_design_organization))
            end
          end
        end
      end
    end

    describe "DELETE #destroy" do
      USER_ROLES.each do |role|
        context "for user #{role}" do
          let(:broker_agency_profile) { double(id: "5ac4cb58be0a6c3ef400009b") }

          before do
            allow(BrokerAgencyProfile).to receive(:find).with(BSON::ObjectId.from_string(broker_agency_profile.id)).and_return(broker_agency_profile)
          end

          context "when attempting to delete plan design organizations without existing quotes" do
            let!(:prospect_plan_design_organization) { create(:sponsored_benefits_plan_design_organization, sponsor_profile_id: nil, owner_profile_id: broker_agency_profile.id,
                                                                                legal_name: 'ABC Company', sic_code: '0197' ) }

            it "destroys the requested prospect_plan_design_organization" do
              expect {
                delete :destroy, {:id => prospect_plan_design_organization.to_param}, valid_session
              }.to change(SponsoredBenefits::Organizations::PlanDesignOrganization, :count).by(-1)
            end

            it "redirects to employers_organizations_broker_agency_profile_path(broker_agency_profile)" do
              delete :destroy, {:id => prospect_plan_design_organization.to_param}, valid_session
              expect(response).to redirect_to(employers_organizations_broker_agency_profile_path(broker_agency_profile))
            end
          end

          context "when attempting to delete plan design organizations with existing quotes" do
            let!(:prospect_plan_design_organization) { create(:sponsored_benefits_plan_design_organization, sponsor_profile_id: '1', owner_profile_id: '5ac4cb58be0a6c3ef400009b',
                                                      plan_design_proposals: [ plan_design_proposal ], sic_code: '0197' ) }
            let(:plan_design_proposal) { build(:plan_design_proposal) }

            it "does not destroy the requested prospect_plan_design_organization" do
              expect {
                delete :destroy, {:id => prospect_plan_design_organization.to_param}, valid_session
              }.to change(SponsoredBenefits::Organizations::PlanDesignOrganization, :count).by(0)
            end

            it "redirects to employers_organizations_broker_agency_profile_path(broker_agency_profile)" do
              delete :destroy, {:id => prospect_plan_design_organization.to_param}, valid_session
              expect(response).to redirect_to(employers_organizations_broker_agency_profile_path(broker_agency_profile))
            end
          end

        end
      end
    end

  end
end
