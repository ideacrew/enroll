RSpec.shared_context "set up", :shared_context => :metadata do
  
  let(:plan_design_organization) { FactoryGirl.create(:sponsored_benefits_plan_design_organization,
    owner_profile_id: owner_profile.id,
    sponsor_profile_id: sponsor_profile.id
  )}

  let(:prospect_plan_design_organization) { FactoryGirl.create(:plan_design_organization,
    owner_profile_id: owner_profile.id,
    sponsor_profile_id: nil
  )}

  let(:plan_design_proposal) { FactoryGirl.create(:plan_design_proposal,
    :with_profile,
    plan_design_organization: plan_design_organization
  )}

  let(:prospect_plan_design_proposal) { FactoryGirl.create(:plan_design_proposal,
    :with_profile,
    plan_design_organization: prospect_plan_design_organization
  )}

  let(:proposal_profile) { plan_design_proposal.profile }
  let(:prospect_proposal_profile) {prospect_proposal_profile.profile}

  let(:benefit_sponsorship) { proposal_profile.benefit_sponsorships.first }
  let(:prospect_benefit_sponsorship) { prospect_proposal_profile.benefit_sponsorships.first}

  let(:benefit_application) { FactoryGirl.create(:plan_design_benefit_application,
    :with_benefit_group,
    benefit_sponsorship: benefit_sponsorship
  )}

  let(:prospect_benefit_application) { FactoryGirl.create(:plan_design_benefit_application,
    :with_benefit_group,
    benefit_sponsorship: benefit_sponsorship
  )}

  let(:benefit_group) { benefit_application.benefit_groups.first }
  let(:prospect_benefit_group) { prospect_benefit_application.benefit_groups.first }

  let(:owner_profile) { broker_agency_profile }
  let(:broker_agency) { owner_profile.organization }

  let(:employer_profile) { sponsor_profile }
  let(:benefit_sponsor) { sponsor_profile.organization }

  let(:plan_design_census_employee) { FactoryGirl.create(:plan_design_census_employee,
    benefit_sponsorship_id: benefit_sponsorship.id
  )}

  let(:prospect_plan_design_census_employee) { FactoryGirl.create(:plan_design_census_employee,
    benefit_sponsorship_id: prospect_benefit_sponsorship.id
  )}

  let(:organization) { plan_design_organization.sponsor_profile.organization }


  def broker_agency_profile
    if Settings.aca.state_abbreviation == "DC" # toDo
      FactoryGirl.create(:broker_agency_profile)
    else
      FactoryGirl.create(:benefit_sponsors_organizations_general_organization,
        :with_site,
        :with_broker_agency_profile
      ).profiles.first
    end
  end

  def sponsor_profile
    if Settings.aca.state_abbreviation == "DC" # toDo
      FactoryGirl.create(:employer_profile)
    else
      FactoryGirl.create(:benefit_sponsors_organizations_general_organization,
        :with_site,
        :with_aca_shop_cca_employer_profile
      ).profiles.first
    end
  end
end
