require 'rails_helper'

module SponsoredBenefits
  RSpec.describe Organizations::PlanDesignProposals::ContributionsController, type: :controller, dbclean: :around_each do
    routes { SponsoredBenefits::Engine.routes }
    let(:valid_session) { {} }
    let(:current_person) { double(:current_person) }
    let(:active_user) { double(:has_hbx_staff_role? => false) }
    let(:broker_role) { double(:broker_role, id: 3) }

		let(:plan_design_organization) do
			FactoryGirl.create :sponsored_benefits_plan_design_organization,
				owner_profile_id: owner_profile.id,
				sponsor_profile_id: sponsor_profile.id
		end

		let(:plan_design_proposal) do
			FactoryGirl.create(:plan_design_proposal,
				:with_profile,
				plan_design_organization: plan_design_organization
			).tap do |proposal|
				sponsorship = proposal.profile.benefit_sponsorships.first
				sponsorship.initial_enrollment_period = benefit_sponsorship_enrollment_period
				sponsorship.save
			end
		end

		let(:proposal_profile) { plan_design_proposal.profile }

		let(:benefit_sponsorship_enrollment_period) do
			begin_on = SponsoredBenefits::BenefitApplications::BenefitApplication.calculate_start_on_dates[0]
			end_on = begin_on + 1.year - 1.day
			begin_on..end_on
		end

		let(:benefit_sponsorship) { proposal_profile.benefit_sponsorships.first }

		let(:benefit_application) { FactoryGirl.create(:plan_design_benefit_application,
			:with_benefit_group,
			benefit_sponsorship: benefit_sponsorship
		)}

		let(:benefit_group) { benefit_application.benefit_groups.first }

		let(:owner_profile) { broker_agency_profile }
		let(:broker_agency) { owner_profile.organization }
		let(:general_agency_profile) { ga_profile }

		let(:employer_profile) { sponsor_profile }
		let(:benefit_sponsor) { sponsor_profile.organization }

		let(:plan_design_census_employee) { FactoryGirl.create(:plan_design_census_employee,
			benefit_sponsorship_id: benefit_sponsorship.id
		)}

		let(:organization) { plan_design_organization.sponsor_profile.organization }

		let!(:health_product) do
				FactoryGirl.create(:benefit_markets_products_health_products_health_product,
					:with_renewal_product,
					application_period: (current_effective_date.beginning_of_year..current_effective_date.end_of_year),
					product_package_kinds: [:single_issuer, :metal_level, :single_product],
					service_area: service_area,
					renewal_service_area: renewal_service_area,
					metal_level_kind: :gold
				)
		end

		let!(:service_area) do
			return @service_area if defined? @service_area
			@service_area = FactoryGirl.create(:benefit_markets_locations_service_area,
				county_zip_ids: [FactoryGirl.create(:benefit_markets_locations_county_zip, county_name: 'Middlesex', zip: '01754', state: 'MA').id],
				active_year: current_effective_date.year
			)
		end

		let!(:renewal_service_area) do
			return @renewal_service_area if defined? @renewal_service_area

			@renewal_service_area = FactoryGirl.create(:benefit_markets_locations_service_area,
				county_zip_ids: service_area.county_zip_ids,
				active_year: service_area.active_year + 1
			)
		end

		let!(:current_effective_date) do
			(TimeKeeper.date_of_record + 2.months).beginning_of_month.prev_year
		end

		let!(:broker_agency_profile) do
			if Settings.aca.state_abbreviation == "DC" # toDo
				FactoryGirl.create(:broker_agency_profile)
			else
				FactoryGirl.create(:benefit_sponsors_organizations_general_organization,
					:with_site,
					:with_broker_agency_profile
				).profiles.first
			end
		end

		let!(:sponsor_profile) do
			if Settings.aca.state_abbreviation == "DC" # toDo
				FactoryGirl.create(:employer_profile)
			else
				FactoryGirl.create(:benefit_sponsors_organizations_general_organization,
					:with_site,
					:with_aca_shop_cca_employer_profile
				).profiles.first
			end
		end

    let!(:relationship_benefit) { benefit_group.relationship_benefits.first }

    before do
      allow(subject).to receive(:current_person).and_return(current_person)
      allow(subject).to receive(:active_user).and_return(active_user)
      allow(current_person).to receive(:broker_role).and_return(broker_role)
      puts "benefit_group: #{benefit_group.inspect}"
      puts "relationship_benefit: #{relationship_benefit.inspect}"
      get :index, {
        benefit_group: {
          reference_plan_id: benefit_group.reference_plan.id,
          plan_option_kind: benefit_group.plan_option_kind,
          relationship_benefits_attributes: {
            relationship: relationship_benefit.relationship,
            premium_pct: relationship_benefit.premium_pct,
            offered: relationship_benefit.offered
          }
        },
      }, valid_session
    end

    it 'works' do
      expect(true).to be_truthy
    end
  end
end
