
require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"
require "#{BenefitSponsors::Engine.root}/spec/support/benefit_sponsors_site_spec_helpers"
require "#{BenefitSponsors::Engine.root}/spec/support/benefit_sponsors_product_spec_helpers"

RSpec.describe Insured::GroupSelectionController, :type => :controller, dbclean: :after_each do
  before :each do
    allow(EnrollRegistry[:choose_shopping_method].feature).to receive(:is_enabled).and_return(false)
    allow(EnrollRegistry[:aca_shop_market].feature).to receive(:is_enabled).and_return(true)
    allow(EnrollRegistry[:apply_aggregate_to_enrollment].feature).to receive(:is_enabled).and_return(false)
    allow(controller).to receive(:ridp_verified?).with(any_args).and_return(true)
  end

  let(:site) { BenefitSponsors::SiteSpecHelpers.create_site_with_hbx_profile_and_empty_benefit_market }
  let(:benefit_market) { site.benefit_markets.first }
  let!(:current_benefit_market_catalog) do
    BenefitSponsors::ProductSpecHelpers.construct_simple_benefit_market_catalog(site, benefit_market, effective_period)
    benefit_market.benefit_market_catalogs.where(
      "application_period.min" => effective_period.min
    ).first
  end

  let(:current_effective_date) { TimeKeeper.date_of_record.beginning_of_month + 2.months }

  include_context "setup initial benefit application"

  let(:service_areas) do
    ::BenefitMarkets::Locations::ServiceArea.where(
      :active_year => current_benefit_market_catalog.application_period.min.year
    ).all.to_a
  end

  let(:rating_area) do
    ::BenefitMarkets::Locations::RatingArea.where(
      :active_year => current_benefit_market_catalog.application_period.min.year
    ).first
  end

    let!(:person) {FactoryBot.create(:person, :with_consumer_role)}
    let!(:family) {FactoryBot.create(:family, :with_primary_family_member, :person => person)}
    let(:qle_kind) { FactoryBot.create(:qualifying_life_event_kind, :effective_on_event_date) }
    let!(:sep){
      sep = family.special_enrollment_periods.new
      sep.effective_on_kind = 'date_of_event'
      sep.qualifying_life_event_kind= qle_kind
      sep.qle_on= TimeKeeper.date_of_record - 7.days
      sep.save
      sep
    }

    let!(:household) {FactoryBot.create(:household, family: family)}
    let!(:user) { FactoryBot.create(:user, :person => person)}
    let!(:coverage_household) {household.add_household_coverage_member(family.primary_family_member)}
    let!(:consumer_role) {person.consumer_role}
    let(:plan_year) {initial_application}
    let(:plan_year_start_on) {TimeKeeper.date_of_record.next_month.end_of_month + 1.day}
    let(:plan_year_end_on) {(plan_year_start_on + 1.month) - 1.day}
    let(:blue_collar_benefit_group) {plan_year.benefit_groups[0]}
    let!(:update_plan_year) {
      plan_year.update_attributes(:"effective_period" => plan_year_start_on..plan_year_end_on, aasm_state: :enrollment_open)
      plan_year.save!
      plan_year.reload
    }
    def blue_collar_benefit_group_assignment
      BenefitGroupAssignment.new(benefit_group: blue_collar_benefit_group, start_on: plan_year_start_on)
    end

    let!(:blue_collar_census_employees) {ees = FactoryBot.build_list(:census_employee, 1, employer_profile: benefit_sponsorship.profile, benefit_sponsorship: benefit_sponsorship)
      ees.each() do |ee|
        ee.benefit_group_assignments = [blue_collar_benefit_group_assignment]
        ee.save
        ee.save!
      end
      ees
    }
    let!(:census_employee) {CensusEmployee.all[0]}

    let!(:employee_role) {person.employee_roles.create( employer_profile: abc_profile, census_employee: census_employee,
    hired_on: census_employee.hired_on)}
    let(:blue_collar_benefit_group) {initial_application.benefit_groups[0]}
    let(:plan_year_start_on) {TimeKeeper.date_of_record.next_month.end_of_month + 1.day}
    let(:plan_year_end_on) {(plan_year_start_on + 1.month) - 1.day}
    let!(:update_plan_year) {
      plan_year.update_attributes(:"effective_period" => plan_year_start_on..plan_year_end_on, aasm_state: :enrollment_open)
      plan_year.save!
      plan_year.reload
    }

    let!(:update_person) {person.employee_roles.first.census_employee = census_employee
                        person.employee_roles.first.hired_on =  census_employee.hired_on
                        person.employee_roles.first.save
                        person.save}
    let(:sbc_document) { FactoryBot.build(:document,subject: "SBC",identifier: "urn:openhbx#123") }
    let(:product) { FactoryBot.create(:benefit_markets_products_health_products_health_product, :with_issuer_profile, title: "AAA", sbc_document: sbc_document) }
    let!(:hbx_enrollment) { FactoryBot.create(:hbx_enrollment,
                                              family: family,
                                              household: family.active_household,
                                              sponsored_benefit_package_id: initial_application.benefit_packages.first.id,
                                              product: product)
                                            }

    let(:hbx_enrollments) {double(:enrolled => [hbx_enrollment], :where => collectiondouble)}
    let!(:collectiondouble) { double(where: double(order_by: [hbx_enrollment]))}
    let!(:hbx_profile) {FactoryBot.create(:hbx_profile)}
    let(:benefit_group) { FactoryBot.create(:benefit_group)}
    let(:benefit_package) { FactoryBot.build(:benefit_package,
        benefit_coverage_period: hbx_profile.benefit_sponsorship.benefit_coverage_periods.first,
        title: "individual_health_benefits_2015",
        elected_premium_credit_strategy: "unassisted",
        benefit_eligibility_element_group: BenefitEligibilityElementGroup.new(
          market_places:        ["individual"],
          enrollment_periods:   ["open_enrollment", "special_enrollment"],
          family_relationships: BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS,
          benefit_categories:   ["health"],
          incarceration_status: ["unincarcerated"],
          age_range:            0..0,
          citizenship_status:   ["us_citizen", "naturalized_citizen", "alien_lawfully_present", "lawful_permanent_resident"],
          residency_status:     ["state_resident"],
          ethnicity:            ["any"]
      ))}
      let(:bcp) { double }
  let(:individual_market_transition) {double('IndividualMarketTransition')}
      let(:sponsored_benefit_package) do
        instance_double(
          ::BenefitSponsors::BenefitPackages::BenefitPackage,
          :id => sponsored_benefit_package_id,
          :recorded_rating_area => double(:id => rating_area_id),
          benefit_sponsorship: double(:id => benefit_sponsorship_id),
          sponsored_benefits: [sponsored_benefit])
      end
      let(:existing_product_id) { BSON::ObjectId.new }
      let(:benefit_sponsorship_id) { BSON::ObjectId.new }
      let(:rating_area_id) { BSON::ObjectId.new }
      let(:sponsored_benefit_package_id) { BSON::ObjectId.new }
      let(:coverage_household_id) { BSON::ObjectId.new }
      let(:sponsored_benefit) { instance_double(::BenefitSponsors::BenefitPackages::BenefitPackage, :id => sponsored_benefit_id) }
      let(:sponsored_benefit_id) { BSON::ObjectId.new }

  before do
    hbx_enrollment.hbx_enrollment_members.build(applicant_id: family.family_members.first.id, is_subscriber: true, coverage_start_on: "2018-10-23 19:32:05 UTC", eligibility_date: "2018-10-23 19:32:05 UTC")
    hbx_enrollment.save
    hbx_enrollment.reload
    FactoryBot.create(:special_enrollment_period, family: family)
    allow(person).to receive(:primary_family).and_return(family)
    allow(family).to receive(:active_household).and_return(household)
    allow(person).to receive(:consumer_role).and_return(nil)
    allow(person).to receive(:consumer_role?).and_return(false)
    allow(user).to receive(:last_portal_visited).and_return('/')
    allow(user).to receive(:has_hbx_staff_role?).and_return false
    allow(person).to receive(:active_employee_roles).and_return [employee_role]
    allow(person).to receive(:has_active_employee_role?).and_return true
    allow(employee_role).to receive(:benefit_group).and_return benefit_group
    allow(person).to receive(:current_individual_market_transition).and_return(individual_market_transition)
    allow(individual_market_transition).to receive(:role_type).and_return(nil)
  end

  context 'when user not authorized' do
    before do
      allow(controller).to receive(:is_family_authorized?).and_return(false)
    end

    context '#new' do
      it "should redirect to root path" do
        sign_in user
        get :new, params: { person_id: person.id, consumer_role_id: consumer_role.id, change_plan: "change", hbx_enrollment_id: hbx_enrollment.id, coverage_kind: hbx_enrollment.coverage_kind }
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to('/')
      end
    end

    context '#create' do
      let(:params) do
        {
          person_id: person.id,
          consumer_role_id: consumer_role.id,
          market_kind: "individual",
          change_plan: "change",
          hbx_enrollment_id: hbx_enrollment.id,
          family_member_ids: [BSON::ObjectId.new],
          enrollment_kind: 'sep',
          coverage_kind: hbx_enrollment.coverage_kind
        }
      end
      it "should redirect to root path" do
        sign_in user
        post :create, params: params
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to('/')
      end
    end
  end

  context "GET new" do
    before do
      allow(Person).to receive(:find).and_return(person)
      allow(controller).to receive(:is_user_authorized?).and_return(true)
    end

    let(:hbx_enrollment_member) { FactoryBot.build(:hbx_enrollment_member) }
    let(:family_member) { family.primary_family_member }
    it "return http success" do
      sign_in user
      get :new, params: { person_id: person.id, employee_role_id: employee_role.id }
      expect(response).to have_http_status(:success)
    end

    # it "returns to family home page when employee is not under open enrollment" do
    #   sign_in user
    #   employee_roles = [employee_role]
    #   allow(person).to receive(:employee_roles).and_return(employee_roles)
    #   allow(employee_roles).to receive(:detect).and_return(employee_role)
    #   allow(employee_role).to receive(:is_under_open_enrollment?).and_return(false)
    #   get :new, person_id: person.id, employee_role_id: employee_role.id
    #   expect(response).to redirect_to(family_account_path)
    #   expect(flash[:alert]).to eq "You can only shop for plans during open enrollment."
    # end

    it "return blank change_plan" do
      sign_in user
      get :new, params: { person_id: person.id, employee_role_id: employee_role.id }
      expect(assigns(:change_plan)).to eq ""
    end

    it "return change_plan" do
      sign_in user
      get :new, params: { person_id: person.id, employee_role_id: employee_role.id, change_plan: "change" }
      expect(assigns(:change_plan)).to eq "change"
    end

    it "should get person" do
      sign_in user
      get :new, params: { person_id: person.id, employee_role_id: employee_role.id }
      expect(assigns(:person)).to eq person
    end

    it "should get hbx_enrollment when has active hbx_enrollments and in qle flow" do
      allow(hbx_enrollment).to receive(:can_complete_shopping?).and_return true
      # FIXME: This is no better than mocking the controller itself on the
      # #selected_enrollment method - and we need to actually mock out the items
      # allow(controller).to receive(:selected_enrollment).and_return hbx_enrollment
      # allow_any_instance_of(GroupSelectionPrevaricationAdapter).to receive(:selected_enrollment).with(family, employee_role).and_return(hbx_enrollment)

      sign_in user
      get :new, params: { person_id: person.id, employee_role_id: employee_role.id, change_plan: 'change_by_qle', market_kind: 'shop', hbx_enrollment_id: hbx_enrollment.id }
      expect(assigns(:hbx_enrollment)).to eq hbx_enrollment
    end

    it "should get coverage_family_members_for_cobra when has active hbx_enrollments and in open enrollment" do
      family.active_household.hbx_enrollments << [hbx_enrollment]
      family.save
      allow(hbx_enrollments).to receive(:shop_market).and_return(hbx_enrollments)
      allow(hbx_enrollments).to receive(:enrolled_and_renewing).and_return(hbx_enrollments)
      allow(hbx_enrollments).to receive(:effective_desc).and_return([hbx_enrollment])
      allow(hbx_enrollment).to receive(:may_terminate_coverage?).and_return true
      allow(hbx_enrollment).to receive(:can_complete_shopping?).and_return true
      allow(person.employee_roles.first).to receive(:is_cobra_status?).and_return true
      person.employee_roles.first.census_employee.aasm_state ='cobra_eligible'
      person.employee_roles.first.census_employee.cobra_begin_date = TimeKeeper.date_of_record
      person.employee_roles.first.census_employee.save
      person.employee_roles.first.save
      family.reload
      person.save
      sign_in user
      get :new, params: { person_id: person.id, employee_role_id: employee_role.id, market_kind: 'shop' }
      expect(assigns(:coverage_family_members_for_cobra)).to eq [family.primary_family_member]
    end

    it "should get hbx_enrollment when has enrolled hbx_enrollments and in shop qle flow but user has both employee_role and consumer_role" do
      # FIXME: This is no better than mocking the controller itself on the
      # #selected_enrollment method - and we need to actually mock out the items
      # allow(controller).to receive(:selected_enrollment).and_return hbx_enrollment
      # allow_any_instance_of(GroupSelectionPrevaricationAdapter).to receive(:selected_enrollment).with(family, employee_role).and_return(hbx_enrollment)
      allow(hbx_enrollment).to receive(:can_complete_shopping?).and_return true
      sign_in user
      get :new, params: { person_id: person.id, employee_role_id: employee_role.id, change_plan: 'change_by_qle', market_kind: 'shop', consumer_role_id: consumer_role.id, hbx_enrollment_id: hbx_enrollment.id }
      expect(assigns(:hbx_enrollment)).to eq hbx_enrollment
    end

    it "should not get hbx_enrollment when has active hbx_enrollments and not in qle flow" do
      sign_in user
      get :new, params: { person_id: person.id, employee_role_id: employee_role.id }
      expect(assigns(:hbx_enrollment)).not_to eq hbx_enrollment
    end

    it "should disable individual market kind if selected market kind is shop in dual role SEP" do
      family.reload
      # FIXME: This is no better than mocking the controller itself on the
      # #selected_enrollment method - and we need to actually mock out the items
      # allow(controller).to receive(:selected_enrollment).and_return hbx_enrollment
      # allow_any_instance_of(GroupSelectionPrevaricationAdapter).to receive(:selected_enrollment).with(family, employee_role).and_return(hbx_enrollment)
      allow(hbx_enrollment).to receive(:can_complete_shopping?).and_return true

      sign_in user
      get :new, params: { person_id: person.id, employee_role_id: employee_role.id, change_plan: 'change_by_qle', market_kind: 'shop', consumer_role_id: consumer_role.id }
      expect(assigns(:disable_market_kind)).to eq "individual"
    end

    context 'in ivl annual open enrollment for dual role' do
      let!(:hbx_profile1) {FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period)}

      before do
        allow(person).to receive(:consumer_role).and_return(consumer_role)
        allow(person).to receive(:active_employee_roles).and_return [employee_role]
        allow(person).to receive(:has_active_employee_role?).and_return true
        allow(hbx_profile1).to receive(:under_open_enrollment?).and_return true
        allow(HbxProfile).to receive(:current_hbx).and_return hbx_profile1
        sign_in user
      end

      # TODO: Not sure why this is failing
      xit 'should disable shop market if employee role is not under open enrollment' do
        allow(employee_role).to receive(:is_eligible_to_enroll_without_qle?).and_return(false)
        get :new, params: { person_id: person.id, employee_role_id: employee_role.id, change_plan: 'change_plan', shop_for_plans: 'shop_for_plans' }
        expect(assigns(:disable_market_kind)).to eq "shop"
      end

      it 'should not disable shop market if employee role is under open enrollment' do
        get :new, params: { person_id: person.id, employee_role_id: employee_role.id, change_plan: 'change_plan', shop_for_plans: 'shop_for_plans' }
        expect(assigns(:disable_market_kind)).to eq nil
      end
    end

    context "it should set the instance variables" do

      before do
        allow(HbxEnrollment).to receive(:find).with("123").and_return(hbx_enrollment)
        allow(hbx_enrollment).to receive(:can_complete_shopping?).and_return true
        allow(hbx_enrollment).to receive(:kind).and_return "individual"
        allow(hbx_enrollment).to receive(:coverage_kind).and_return "health"
        sign_in user
        get :new, params: { person_id: person.id, employee_role_id: employee_role.id, change_plan: 'change_plan', hbx_enrollment_id: "123" }
      end

      it "should set market kind when user select to make changes in open enrollment" do
        expect(assigns(:mc_market_kind)).to eq hbx_enrollment.kind
      end

      it "should set the coverage kind when user click on make changes in open enrollment" do
        expect(assigns(:mc_coverage_kind)).to eq hbx_enrollment.coverage_kind
      end

      it "should set effective on date" do
        expect(assigns(:new_effective_on)).to eq hbx_enrollment.effective_on
      end
    end

    #TODO: fix me when group selection controller is refactored per IVL new model.
    context "individual" do
      let(:family_member_ids) {{"0"=>family.family_members.first.id}}
      let!(:person1) {FactoryBot.create(:person, :with_consumer_role)}
      let!(:consumer_role) {person.consumer_role}
      let!(:new_household) {family.households.where(:id => {"$ne"=>"#{family.households.first.id}"}).first}
      let(:benefit_coverage_period) {FactoryBot.build(:benefit_coverage_period)}

      before :each do
        allow(HbxEnrollment).to receive(:find).with("123").and_return(hbx_enrollment)
        allow(hbx_enrollment).to receive(:coverage_kind).and_return "health"
        allow(HbxProfile).to receive(:current_hbx).and_return hbx_profile
        allow(benefit_coverage_period).to receive(:benefit_packages).and_return [benefit_package]
        allow(person).to receive(:is_consumer_role_active?).and_return true
        allow(person).to receive(:has_active_employee_role?).and_return false
        allow(person).to receive(:consumer_role).and_return(consumer_role)
        allow(HbxEnrollment).to receive(:calculate_effective_on_from).and_return TimeKeeper.date_of_record
        allow(hbx_enrollment).to receive(:kind).and_return "individual"
      end

      it "should set session" do
        sign_in user
        get :new, params: { person_id: person.id, consumer_role_id: consumer_role.id, change_plan: "change", hbx_enrollment_id: "123", coverage_kind: hbx_enrollment.coverage_kind }
        expect(session[:pre_hbx_enrollment_id]).to eq "123"
      end

      it "should get new_effective_on" do
        sign_in user
        get :new, params: { person_id: person.id, consumer_role_id: consumer_role.id, change_plan: "change", hbx_enrollment_id: "123", coverage_kind: hbx_enrollment.coverage_kind }
        expect(assigns(:new_effective_on)).to eq TimeKeeper.date_of_record
      end

      context "non active family member has is incarcerated/inactive" do
        let!(:person_to_deactivate) do
          FactoryBot.create(:person)
        end

        before do
          family = person.primary_family
          expect(family.family_members.count).to eq(1)
          person.primary_family.family_members.create!(person_id: person_to_deactivate.id)
          expect(family.family_members.count).to eq(2)
          # This would ressemble the actual deletion from the manage_family UI, such as in the case of a
          # duplicate family member
          incarcerated_family_member = family.family_members.where(person_id: person_to_deactivate).first
          # this will set is_active to false
          family.remove_family_member(person_to_deactivate)
          family.save!
          incarcerated_family_member.reload
        end

        it "should only consider active family members and redirect to coverage household page" do
          sign_in user
          get(
            :new,
            params: {
              person_id: person.id,
              consumer_role_id: consumer_role.id,
              change_plan: "change",
              hbx_enrollment_id: "123",
              coverage_kind: hbx_enrollment.coverage_kind
            }
          )
          fm_hash = assigns(:fm_hash)
          active_family_members = assigns(:active_family_members)
          expect(fm_hash.values.flatten.detect{|err| err.to_s.match(/incarcerated_not_answered/)}).to eq(nil)
          incarcerated_family_member = family.family_members.where(person_id: person_to_deactivate).first
          expect(active_family_members).to_not include(incarcerated_family_member)
          expect(active_family_members.length).to eq(1)
          expect(response).to have_http_status("200")
        end
      end

      context "non applying family member has no incarceration status" do
        let!(:person_1) { FactoryBot.create(:person, :with_consumer_role)}
        let!(:family_1) {FactoryBot.create(:family, :with_primary_family_member, :person => person_1)}
        let!(:person_2) do
          FactoryBot.create(:person, :with_consumer_role)
        end

        before do
          allow(person_1).to receive(:primary_family).and_return(family_1)
          person_2.update_attributes!(is_incarcerated: nil)
          person_2.consumer_role.update_attributes!(is_applying_coverage: false)
          person_1.update_attributes!(is_incarcerated: false)
          family = person_1.primary_family
          expect(family.family_members.count).to eq(1)
          FactoryBot.create(:family_member, family: family, person: person_2)
          expect(family.family_members.count).to eq(2)
        end

        it "should not check incarceration status of non-applying family members" do
          sign_in user
          get(
            :new,
            params: {
              person_id: person_1.id,
              consumer_role_id: person.consumer_role.id,
              change_plan: "change",
              hbx_enrollment_id: "123",
              coverage_kind: hbx_enrollment.coverage_kind
            }
          )
          fm_hash = assigns(:fm_hash)
          active_family_members = assigns(:active_family_members)
          expect(fm_hash.values.flatten.detect{|err| err.to_s.match(/incarcerated_not_answered/)}).to eq(nil)
          nonapplying = family.family_members.where(person_id: person_2).first
          expect(active_family_members).to_not include(nonapplying)
          expect(active_family_members.length).to eq(1)
          expect(response).to have_http_status("200")
        end
      end

      it "should not redirect to coverage household page if incarceration is unanswered" do
        person.unset(:is_incarcerated)
        HbxProfile.current_hbx.benefit_sponsorship.benefit_coverage_periods.last.benefit_packages[0].incarceration_status = ["incarceration_status"]
        sign_in user
        get :new, params: { person_id: person.id, consumer_role_id: consumer_role.id, change_plan: "change", hbx_enrollment_id: "123", coverage_kind: hbx_enrollment.coverage_kind }
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(manage_family_insured_families_path(tab: 'family'))
      end

      it "should create an hbx enrollment" do
        params = {
          person_id: person.id,
          consumer_role_id: consumer_role.id,
          market_kind: "individual",
          change_plan: "change",
          hbx_enrollment_id: "123",
          family_member_ids: family_member_ids,
          enrollment_kind: 'sep',
          coverage_kind: hbx_enrollment.coverage_kind
        }
        sign_in user
        post :create, params: params
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(insured_plan_shopping_path(id: new_household.hbx_enrollments(true).first.id, change_plan: 'change', coverage_kind: 'health', market_kind: 'individual', enrollment_kind: 'sep'))
      end
    end

    context 'dual role household' do
      include_context "setup benefit market with market catalogs and product packages"
      include_context "setup initial benefit application"
      let!(:sponsored_benefit_package) { initial_application.benefit_packages[0] }
      let!(:employer_profile) {benefit_sponsorship.profile}
      let(:employee_role_person)     { FactoryBot.create(:person, :with_employee_role)}
      let(:consumer_role_person)     { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role)}
      let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: employee_role_person)}
      let!(:census_employee) do
        FactoryBot.create(:census_employee,
                          employer_profile: employer_profile,
                          employee_role_id: employee_role_person.employee_roles.first.id,
                          benefit_sponsorship_id: sponsored_benefit_package.benefit_application.benefit_sponsorship.id)
      end

      before do
        family_member = FamilyMember.new(:person => consumer_role_person)
        family.family_members << family_member
      end

      it 'should return success response if primary has employee role and dependent has consumer role' do
        sign_in user
        get :new, params: { person_id: person.id, employee_role_id: employee_role_person.employee_roles.first.id }
        expect(response).to have_http_status(:success)
      end
    end

  end

  context 'IVL edit plan paths', dbclean: :after_each do
    #These paths should only be reached with an IVL enrollment, hence their location here.
    context 'GET edit_plan' do
      before(:each) do
        Family.delete_all
        HbxEnrollment.all.delete_all
        Person.all.delete_all
        person = FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role)
        @family = FactoryBot.create(:family, :with_primary_family_member, person: person)
        second_consumer = FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role)
        FactoryBot.create(:family_member, person: second_consumer, family: @family, is_active: true, is_primary_applicant: false)
        @sep = FactoryBot.create(:special_enrollment_period, family: @family)
        FactoryBot.create(:hbx_enrollment, :individual_unassisted, family: @family, product: @product)
        @enrollment = HbxEnrollment.all[0]
        hbx_enrollment_member1 = @enrollment.hbx_enrollment_members.create(family_member: @family.family_members[0], is_subscriber: true, eligibility_date: (TimeKeeper.date_of_record - 10.days), hbx_enrollment: @enrollment, coverage_start_on: @enrollment.effective_on)
        hbx_enrollment_member2 = @enrollment.hbx_enrollment_members.create(family_member: @family.family_members[1], eligibility_date: (TimeKeeper.date_of_record - 10.days), hbx_enrollment: @enrollment, coverage_start_on: @enrollment.effective_on)
        hbx_profile = FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period)
        @product = BenefitMarkets::Products::Product.all.where(benefit_market_kind: :aca_individual).first
        @product.update_attributes(ehb: 0.9844)
        premium_table = @product.premium_tables.first
        premium_table.premium_tuples.where(age: 59).first.update_attributes(cost: 614.85)
        premium_table.premium_tuples.where(age: 61).first.update_attributes(cost: 679.8)
        @product.save!

        hbx_enrollment_member1.family_member.person.update_attributes!(dob: (@enrollment.effective_on - 61.years))
        hbx_enrollment_member2.family_member.person.update_attributes!(dob: (@enrollment.effective_on - 59.years))
        @enrollment.update_attributes(product: @product, consumer_role_id: person.consumer_role.id)
        @enrollment.save!
        hbx_profile.benefit_sponsorship.benefit_coverage_periods.each {|bcp| bcp.update_attributes!(slcsp_id: @product.id)}
        area = EnrollRegistry[:rating_area].settings(:areas).item.first
        allow(Person).to receive(:find).and_return(person)
        @user = FactoryBot.create(:user, person: person)
        # allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate).with(@product, @enrollment.effective_on, 59, area).and_return(814.85)
        # allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate).with(@product, @enrollment.effective_on, 61, area).and_return(879.8)
      end

      it 'return http success and render' do
        sign_in @user
        @family.special_enrollment_periods << @sep
        attrs = {hbx_enrollment_id: @enrollment.id.to_s, family_id: @family.id}
        get :edit_plan, params: attrs
        expect(response).to have_http_status(:success)
        expect(response).to render_template(:edit_plan)
      end

      it 'raises error if find the HBX enrollment does not belong to the current user' do
        sign_in user
        error_message = "HBX enrollment ID does not belong to the user"
        get :edit_plan, params: {hbx_enrollment_id: "5f6278b81bdce242ca1eb1a1"}
        expect(flash[:error]).to eq 'User not authorized to perform this operation'
      end
    end
  end

  context "#edit_plan with invalid params" do
    let(:person1) {FactoryBot.create(:person, addresses: nil)}
    let(:family1) {FactoryBot.create(:family, :with_primary_family_member_and_dependent, person: person1)}
    let(:enrollment) {HbxEnrollment.all[0] }
    before :each do
      family1.primary_person.rating_address.destroy!
      family1.save!
    end

    it 'redirects to families account when invalid params are passed through' do
      sign_in user
      family1.primary_person.rating_address.destroy!
      attrs = {hbx_enrollment_id: enrollment.id.to_s, family_id: family1.id}
      get :edit_plan, params: attrs
      expect(response).to redirect_to family_account_path
    end
  end

  context 'IVL Market' do
    before do
      allow(Person).to receive(:find).and_return(person)
      allow(controller).to receive(:is_user_authorized?).and_return(true)
    end

    context 'consumer role family' do
      let(:family_member_ids) {{'0' => family.family_members.first.id}}
      let!(:person1) {FactoryBot.create(:person, :with_consumer_role)}
      let!(:consumer_role) {person.consumer_role}
      let!(:new_household) {family.households.where(:id => {'$ne' => '#{family.households.first.id}'}).first}
      let(:benefit_coverage_period) {FactoryBot.build(:benefit_coverage_period)}
      let!(:ivl_hbx_enrollment) {FactoryBot.create(:hbx_enrollment,
                                                   family: family,
                                                   household: family.active_household,
                                                   enrollment_kind: 'special_enrollment')}

      before :each do
        allow(HbxEnrollment).to receive(:find).with('123').and_return(ivl_hbx_enrollment)
        allow(ivl_hbx_enrollment).to receive(:coverage_kind).and_return 'health'
        allow(person).to receive(:is_consumer_role_active?).and_return true
        allow(person).to receive(:consumer_role).and_return(consumer_role)
      end
      it 'should create an hbx enrollment' do
        params = {
            person_id: person.id,
            consumer_role_id: consumer_role.id,
            market_kind: "individual",
            change_plan: "change",
            hbx_enrollment_id: "123",
            family_member_ids: family_member_ids,
            enrollment_kind: 'special_enrollment',
            coverage_kind: ivl_hbx_enrollment.coverage_kind
        }
        sign_in user
        post :create, params: params
        expect(assigns(:change_plan)).to eq 'change_by_qle'
      end
    end

    context 'resident role family' do
      let(:family_member_ids) {{'0' => family.family_members.first.id}}
      let!(:person1) {FactoryBot.create(:person, :with_resident_role)}
      let!(:resident_role) {person.resident_role}
      let!(:new_household) {family.households.where(:id => {'$ne' => "#family.households.first.id}"}).first}
      let(:benefit_coverage_period) {FactoryBot.build(:benefit_coverage_period)}
      let!(:coverall_hbx_enrollment) {FactoryBot.create(:hbx_enrollment,
                                                        family: family,
                                                        household: family.active_household,
                                                        enrollment_kind: 'special_enrollment')}

      before :each do
        allow(HbxEnrollment).to receive(:find).with('123').and_return(coverall_hbx_enrollment)
        allow(coverall_hbx_enrollment).to receive(:coverage_kind).and_return 'health'
        allow(person).to receive(:is_resident_role_active?).and_return true
        allow(person).to receive(:resident_role).and_return(resident_role)
      end
      it 'should create an hbx enrollment' do
        params = {
            person_id: person.id,
            consumer_role_id: consumer_role.id,
            market_kind: "coverall",
            change_plan: "change",
            hbx_enrollment_id: "123",
            family_member_ids: family_member_ids,
            enrollment_kind: 'special_enrollment',
            coverage_kind: coverall_hbx_enrollment.coverage_kind
        }
        sign_in user
        post :create, params: params
        expect(assigns(:change_plan)).to eq 'change_by_qle'
      end
    end

    context 'family has active ivl sep' do
      let(:family_member_ids) {{'0' => family.family_members.first.id}}
      let!(:person1) {FactoryBot.create(:person, :with_consumer_role)}
      let!(:consumer_role) {person.consumer_role}
      let!(:new_household) {family.households.where(:id => {'$ne' => family.households.first.id.to_s}).first}
      let(:benefit_coverage_period) {FactoryBot.build(:benefit_coverage_period)}
      let!(:ivl_hbx_enrollment) do
        FactoryBot.create(:hbx_enrollment,
                          family: family,
                          household: family.active_household,
                          enrollment_kind: 'special_enrollment')
      end

      let(:ivl_qle) do
        QualifyingLifeEventKind.create(
            title: "Married",
            tool_tip: "Enroll or add a family member because of marriage",
            action_kind: "add_benefit",
            event_kind_label: "Date of married",
            market_kind: "individual",
            ordinal_position: 15,
            reason: "marriage",
            edi_code: "32-MARRIAGE",
            effective_on_kinds: ["first_of_next_month"],
            pre_event_sep_in_days: 0,
            post_event_sep_in_days: 30,
            is_self_attested: true,
            is_visible: true,
            is_active: true
        )
      end

      let(:special_enrollment_period) {[double('SpecialEnrollmentPeriod')]}
      let!(:ivl_qle_sep) {family.special_enrollment_periods.build(qualifying_life_event_kind: ivl_qle, start_on: TimeKeeper.date_of_record - 7.days, end_on: TimeKeeper.date_of_record)}

      before :each do
        allow(HbxEnrollment).to receive(:find).with('123').and_return(ivl_hbx_enrollment)
        allow(ivl_hbx_enrollment).to receive(:coverage_kind).and_return 'health'
        allow(person).to receive(:is_consumer_role_active?).and_return true
        allow(person).to receive(:consumer_role).and_return(consumer_role)
        ivl_hbx_enrollment.update_attributes!(kind: 'individual')
        allow(ivl_hbx_enrollment).to receive(:is_ivl_by_kind?).and_return(true)
      end

      it 'should create an hbx enrollment' do
        params = {
            person_id: person.id,
            consumer_role_id: consumer_role.id,
            market_kind: "individual",
            change_plan: "change",
            hbx_enrollment_id: "123",
            family_member_ids: family_member_ids,
            enrollment_kind: 'special_enrollment',
            coverage_kind: ivl_hbx_enrollment.coverage_kind
        }
        sign_in user
        post :create, params: params
        expect(assigns(:change_plan)).to eq 'change_by_qle'
      end
    end
  end

  context 'GET terminate_confirm' do
    let!(:person) { FactoryBot.create(:person, :with_active_consumer_role, :with_consumer_role) }
    let(:user) { FactoryBot.create(:user, person: person) }
    let!(:family) { FactoryBot.create(:family, :with_primary_family_member, :person => person) }
    let!(:new_family) { FactoryBot.create(:family, :with_primary_family_member_and_dependent)}
    let!(:hbx_enrollment_not_tied_to_user) { FactoryBot.create(:hbx_enrollment, family: new_family, household: new_family.active_household) }
    let!(:product) do
      FactoryBot.create(:benefit_markets_products_health_products_health_product,
                        hios_id: '11111111122301-01',
                        csr_variant_id: '01',
                        metal_level_kind: :silver,
                        application_period: TimeKeeper.date_of_record.beginning_of_year..TimeKeeper.date_of_record.end_of_year,
                        benefit_market_kind: :aca_individual)
    end

    let!(:hbx_enrollment) do
      FactoryBot.create(:hbx_enrollment,
                        family: family,
                        household: family.active_household,
                        product: product)
    end

    before do
      family.active_household.hbx_enrollments << [hbx_enrollment]
      family.save
    end

    it 'should find the HBX enrollment if it belongs to the current user' do
      sign_in user
      get :terminate_confirm, params: {hbx_enrollment_id: hbx_enrollment.id}
      expect(response).to render_template(:terminate_confirm)
    end

    it 'finds any HBX enrollment if the user is a HBX staff' do
      sign_in user
      allow(user).to receive(:has_hbx_staff_role?).and_return(true)

      get :terminate_confirm, params: {hbx_enrollment_id: hbx_enrollment_not_tied_to_user.id}
      expect(response).to render_template(:terminate_confirm)
    end

    it 'raises error if find the HBX enrollment does not belong to the current user' do
      sign_in user
      error_message = "HBX enrollment ID does not belong to the user"
      get :terminate_confirm, params: {hbx_enrollment_id: "5f6278b81bdce242ca1eb1a1"}
      expect(flash[:error]).to eq 'User not authorized to perform this operation'
    end
  end

  context 'POST term_or_cancel' do
    before { allow(Person).to receive(:find).and_return(person) }

    let(:family) {FactoryBot.create(:individual_market_family)}
    let(:sep) {FactoryBot.create(:special_enrollment_period, family: family)}
    let(:sbc_document) {FactoryBot.build(:document, subject: 'SBC', identifier: 'urn:openhbx#123')}
    let(:product) {FactoryBot.create(:benefit_markets_products_health_products_health_product, :with_issuer_profile, title: 'AAA', sbc_document: sbc_document)}
    let(:enrollment_to_cancel) {FactoryBot.create(:hbx_enrollment, :individual_unassisted, family: family, product: product, effective_on: Date.today + 1.month)}
    let(:enrollment_to_term) {FactoryBot.create(:hbx_enrollment, :individual_unassisted, family: family, product: product, effective_on: Date.today - 1.month)}

    it 'should cancel enrollment with no term date given' do
      family.family_members.first.person.consumer_role.update_attributes(:aasm_state => :fully_verified)
      sign_in user
      post :term_or_cancel, params: {hbx_enrollment_id: enrollment_to_cancel.id, term_date: nil, term_or_cancel: 'cancel'}
      enrollment_to_cancel.reload
      expect(enrollment_to_cancel.aasm_state).to eq 'coverage_canceled'
      expect(response).to redirect_to(family_account_path)
    end

    it 'should schedule terminate enrollment with term date given' do
      family.family_members.first.person.consumer_role.update_attributes(:aasm_state => :fully_verified)
      sign_in user
      post :term_or_cancel, params: {hbx_enrollment_id: enrollment_to_term.id, term_date: TimeKeeper.date_of_record + 1, term_or_cancel: 'terminate'}
      enrollment_to_term.reload
      expect(enrollment_to_term.aasm_state).to eq 'coverage_terminated'
      expect(response).to redirect_to(family_account_path)
    end

    it 'raises error if find the HBX enrollment does not belong to the current user' do
      sign_in user
      error_message = "HBX enrollment ID does not belong to the user"
      post :term_or_cancel, params: {hbx_enrollment_id: "5f6278b81bdce242ca1eb1a1", term_date: nil, term_or_cancel: 'cancel'}
      expect(flash[:error]).to eq 'User not authorized to perform this operation'
    end

    context "person has a broker role" do
      let(:broker_agency_profile) { FactoryBot.create(:benefit_sponsors_organizations_broker_agency_profile) }
      let(:broker_person) { broker_agency_profile.primary_broker_role.person }
      let(:site)                      { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
      let(:broker_organization)      { FactoryBot.build(:benefit_sponsors_organizations_general_organization, site: site)}
      let(:broker_user) { FactoryBot.create(:user, person: broker_person) }
      let(:family) { FactoryBot.create(:family, :with_primary_family_member) }
      let(:broker_agency_account) { FactoryBot.build(:benefit_sponsors_accounts_broker_agency_account, broker_agency_profile: broker_agency_profile, is_active: true) }
      let(:rating_area) { FactoryBot.create_default(:benefit_markets_locations_rating_area) }
      let(:hbx_enrollment_with_broker) do
        FactoryBot.create(:hbx_enrollment,
                          product_id: product.id,
                          kind: 'individual',
                          family: family,
                          rating_area_id: rating_area.id,
                          broker_agency_profile_id: broker_agency_profile.id)
      end

      it "should be able to terminate coverage if user is valid and has broker role" do
        # broker_role = broker_person.broker_role
        # broker_role.aasm_state = "active"
        # broker_role.save
        family.broker_agency_accounts << broker_agency_account
        family.save
        sign_in broker_user

        post :term_or_cancel, params: {hbx_enrollment_id: hbx_enrollment_with_broker.id, term_date: TimeKeeper.date_of_record + 1, term_or_cancel: 'terminate'}
        hbx_enrollment_with_broker.reload
        expect(hbx_enrollment_with_broker.aasm_state).to eq 'coverage_terminated'
        expect(response).to redirect_to(family_account_path)
      end

      it "should not be able to view page if user does not have active staff role" do
        sign_in broker_user

        post :term_or_cancel, params: {hbx_enrollment_id: hbx_enrollment_with_broker.id, term_date: TimeKeeper.date_of_record + 1, term_or_cancel: 'terminate'}
        hbx_enrollment_with_broker.reload

        expect(hbx_enrollment_with_broker.aasm_state).to eq 'coverage_selected'
        expect(response).to redirect_to(root_path)
      end
    end

    context "person and broker staff role" do
      let(:broker_agency_profile) { FactoryBot.create(:benefit_sponsors_organizations_broker_agency_profile) }
      let(:broker_agency) { FactoryBot.create(:benefit_sponsors_organizations_broker_agency_profile) }
      let(:person1) { FactoryBot.create(:person)}
      let(:user_with_broker_staff_role) { FactoryBot.create(:user, person: person1) }
      let(:broker_staff_role) { FactoryBot.create(:broker_agency_staff_role, benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id, person: person1, broker_agency_profile: broker_agency_profile) }
      let(:family) do
        family = FactoryBot.create(:family, :with_primary_family_member)
        family.broker_agency_accounts << broker_agency_account
        family.save
        family
      end
      let(:rating_area) { FactoryBot.create(:benefit_markets_locations_rating_area) }
      let(:broker_agency_account) { FactoryBot.build(:benefit_sponsors_accounts_broker_agency_account, broker_agency_profile: broker_agency_profile, is_active: true) }

      let(:hbx_enrollment_with_broker) do
        FactoryBot.create(:hbx_enrollment,
                          product_id: product.id,
                          kind: 'individual',
                          family: family,
                          rating_area_id: rating_area.id,
                          writing_agent_id: broker_agency_profile.primary_broker_role.id,
                          broker_agency_profile_id: broker_agency_profile.id)
      end
      it "should be able to terminate coverage if user is valid and has active broker staff role" do
        person.broker_agency_staff_roles = [broker_staff_role]
        person.save!
        sign_in user_with_broker_staff_role
        post :term_or_cancel, params: {hbx_enrollment_id: hbx_enrollment_with_broker.id, term_date: TimeKeeper.date_of_record + 1, term_or_cancel: 'terminate'}
        hbx_enrollment_with_broker.reload

        expect(hbx_enrollment_with_broker.aasm_state).to eq 'coverage_terminated'
        expect(response).to redirect_to(family_account_path)
      end
    end

    context "person and general agency staff role" do
      let(:organization)     { FactoryBot.create(:benefit_sponsors_organizations_general_organization, "with_aca_shop_#{EnrollRegistry[:enroll_app].setting(:site_key).item}_employer_profile".to_sym, site: site)}
      let(:general_agency_profile) { FactoryBot.create(:benefit_sponsors_organizations_general_agency_profile, organization: organization) }
      let(:broker_agency_profile) do
        FactoryBot.create(:benefit_sponsors_organizations_broker_agency_profile,
                          default_general_agency_profile_id: general_agency_profile.id)
      end
      let(:person1) { FactoryBot.create(:person)}
      let(:user_with_general_staff_role) { FactoryBot.create(:user, person: person1) }
      let(:general_staff_role) do
        FactoryBot.create(:general_agency_staff_role,
                          benefit_sponsors_general_agency_profile_id: general_agency_profile.id,
                          person: person1, general_agency_profile: general_agency_profile,
                          aasm_state: 'active')
      end
      let(:family) do
        family = FactoryBot.create(:family, :with_primary_family_member)
        family.broker_agency_accounts << broker_agency_account
        family.save
        family
      end
      let(:broker_role) { broker_agency_profile.primary_broker_role }
      let(:broker_agency_account) { FactoryBot.build(:benefit_sponsors_accounts_broker_agency_account, broker_agency_profile: broker_agency_profile, is_active: true, writing_agent: broker_role) }
      let(:rating_area) { FactoryBot.create(:benefit_markets_locations_rating_area) }

      let(:hbx_enrollment_with_broker) do
        FactoryBot.create(:hbx_enrollment,
                          product_id: product.id,
                          kind: 'individual',
                          family: family,
                          rating_area_id: rating_area.id,
                          writing_agent_id: broker_agency_profile.primary_broker_role.id,
                          broker_agency_profile_id: broker_agency_profile.id)
      end

      before do
        allow(::SponsoredBenefits::Organizations::PlanDesignOrganization).to receive(:where).and_return([double('PlanDesignOrganization')])
      end

      it "should be able to terminate coverage if user is valid and has active ga staff role" do
        person.general_agency_staff_roles = [general_staff_role]
        person.save!
        sign_in user_with_general_staff_role
        post :term_or_cancel, params: {hbx_enrollment_id: hbx_enrollment_with_broker.id, term_date: TimeKeeper.date_of_record + 1, term_or_cancel: 'terminate'}
        hbx_enrollment_with_broker.reload

        expect(hbx_enrollment_with_broker.aasm_state).to eq 'coverage_terminated'
        expect(response).to redirect_to(family_account_path)
      end
    end
  end

  context 'POST edit_aptc', dbclean: :after_each do

    before do
      current_year = TimeKeeper.date_of_record.year
      is_tax_credit_btn_enabled = TimeKeeper.date_of_record < Date.new(current_year, 11, HbxProfile::IndividualEnrollmentDueDayOfMonth + 1)
      unless is_tax_credit_btn_enabled
        allow(TimeKeeper).to receive(:date_of_record).and_return(Date.new(current_year, 10, 5))
        hbx_enrollment_14.update!(effective_on: TimeKeeper.date_of_record.next_month.beginning_of_month)
      end
    end

    after do
      allow(TimeKeeper).to receive(:date_of_record).and_call_original
    end

    let!(:silver_product) do
      prod =
        FactoryBot.create(
          :benefit_markets_products_health_products_health_product,
          :with_issuer_profile,
          benefit_market_kind: :aca_individual,
          kind: :health,
          assigned_site: site,
          service_area: service_area,
          csr_variant_id: '01',
          metal_level_kind: 'silver',
          application_period: application_period_14
        )
      prod.premium_tables = [premium_table]
      prod.save
      prod
    end
    let(:premium_table)        { build(:benefit_markets_products_premium_table, effective_period: application_period_14, rating_area: rating_area_14) }

    let!(:person_14) do
      person = FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role, is_incarcerated: false)
      person.consumer_role.update_attributes(aasm_state: 'fully_verified')
      person
    end
    let!(:family_14) {FactoryBot.create(:family, :with_primary_family_member, person: person_14)}
    let!(:person2) do
      member = FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role, dob: (TimeKeeper.date_of_record - 40.years))
      person_14.ensure_relationship_with(member, 'spouse')
      member.save!
      member.consumer_role.update_attributes(aasm_state: 'fully_verified')
      member
    end
    let(:user_14) { FactoryBot.create(:user, person: person_14) }
    let!(:family_member2) {FactoryBot.create(:family_member, family: family_14, person: person2)}
    let!(:tax_household) {FactoryBot.create(:tax_household, household: family_14.active_household, effective_ending_on: nil, effective_starting_on: effective_on)}
    let!(:tax_household_member1) {FactoryBot.create(:tax_household_member, applicant_id: family_14.family_members[0].id, tax_household: tax_household)}
    let!(:tax_household_member2) {FactoryBot.create(:tax_household_member, applicant_id: family_member2.id, tax_household: tax_household)}
    let!(:eligibilty_determination) {FactoryBot.create(:eligibility_determination, max_aptc: 500.00, tax_household: tax_household, csr_eligibility_kind: 'csr_73')}
    let(:current_year) { TimeKeeper.date_of_record.year }
    let(:effective_on) { TimeKeeper.date_of_record.next_month.beginning_of_month }
    let!(:rating_area_14) do
      ::BenefitMarkets::Locations::RatingArea.rating_area_for(person_14.rating_address, during: effective_on) || FactoryBot.create_default(:benefit_markets_locations_rating_area)
    end
    let!(:service_area) do
      ::BenefitMarkets::Locations::ServiceArea.service_areas_for(person_14.rating_address, during: effective_on).first || FactoryBot.create_default(:benefit_markets_locations_service_area)
    end

    let!(:hbx_enrollment_14) do
      FactoryBot.create(:hbx_enrollment,
                        family: family_14,
                        household: family_14.active_household,
                        coverage_kind: 'health',
                        effective_on: effective_on,
                        enrollment_kind: 'open_enrollment',
                        kind: 'individual',
                        consumer_role: person_14.consumer_role,
                        rating_area_id: rating_area_14.id,
                        product: product34)
    end

    let!(:hbx_enrollment_member2) do
      FactoryBot.create(:hbx_enrollment_member, hbx_enrollment: hbx_enrollment_14, eligibility_date: effective_on, coverage_start_on: effective_on, applicant_id: family_14.family_members[1].id)
    end

    let(:application_period_14) {effective_on.beginning_of_year..effective_on.end_of_year}

    let!(:product34) do
      FactoryBot.create(:benefit_markets_products_health_products_health_product,
                        hios_id: '11111111122301-01',
                        csr_variant_id: '01',
                        metal_level_kind: :silver,
                        application_period: application_period_14,
                        benefit_market_kind: :aca_individual)
    end

    let(:new_aptc_amount) {250.0}
    let(:new_aptc_pct) {'0.39772'}

    let(:params) {{'applied_pct_1' => new_aptc_pct, 'aptc_applied_total' => new_aptc_amount, 'hbx_enrollment_id' => hbx_enrollment_14.id.to_s}}

    before :each do
      BenefitMarkets::Products::Product.all.each do |prod|
        prod.update_attributes(application_period: application_period_14)
        prod.premium_tables.each do |pt|
          pt.update_attributes(effective_period: application_period_14)
        end
      end
      BenefitMarkets::Products::ProductRateCache.initialize_rate_cache!
      sign_in user_14
      family_member2.person.update_attributes(is_incarcerated: false)
      post :edit_aptc, params: params
    end

    # as per self_service_factory #update_aptc, we create reinstatement with effective_date two months in the future when the current date is greater than the 15th of the month
    # ie. today is 3/16, then reinstatement effective_date will be 5/1
    # ie. if today is 3/15, then reinstatement effective_date will be 4/1
    it 'should update current enrollment(cancel/terminate)' do
      hbx_enrollment_14.reload
      if TimeKeeper.date_of_record.day > HbxProfile::IndividualEnrollmentDueDayOfMonth
        expect(hbx_enrollment_14.aasm_state).to eq 'coverage_terminated'
        new_enrollment = family_14.hbx_enrollments.coverage_selected.first
        expect(hbx_enrollment_14.terminated_on.to_date).to eq new_enrollment.effective_on.prev_day.to_date
      else
        expect(hbx_enrollment_14.aasm_state).to eq 'coverage_canceled'
      end
    end

    it 'should create new enrollment' do
      family_14.reload
      expect(family_14.hbx_enrollments.coverage_selected.present?).to be_truthy
    end

    it 'should update APTC amount on the new enrollment' do
      family_14.reload
      new_enrollment = family_14.hbx_enrollments.coverage_selected.first
      expect(new_enrollment.applied_aptc_amount.to_f.to_s).to eq '198.86'
    end

    it 'should update APTC pct on the new enrollment' do
      family_14.reload
      new_enrollment = family_14.hbx_enrollments.coverage_selected.first
      expect(new_enrollment.elected_aptc_pct.to_s).to eq new_aptc_pct
    end

    it 'should update APTC amount on the hbx enrollment members' do
      family_14.reload
      new_enrollment = family_14.hbx_enrollments.coverage_selected.first
      expect(new_enrollment.hbx_enrollment_members.any?(&:applied_aptc_amount)).to be_truthy
    end

    it 'should redirect successfully' do
      expect(response).to redirect_to(family_account_path)
    end

    context 'Overlapping plan year enrollments' do
      before do
        allow(TimeKeeper).to receive(:date_of_record).and_return(Date.new(current_year, 11, 17))
        sign_in user_14
        post :edit_aptc, params: params
      end

      after do
        allow(TimeKeeper).to receive(:date_of_record).and_call_original
      end

      it 'should return flash error message' do
        expect(flash[:notice]).to eq 'Action cannot be performed because of the overlapping plan years.'
      end
    end
  end

  context 'update aptc in the mthh context' do
    let!(:person) do
      person = FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role, is_incarcerated: false)
      person.consumer_role.update_attributes(aasm_state: 'fully_verified')
      person
    end
    let!(:family) {FactoryBot.create(:family, :with_primary_family_member, person: person)}

    let!(:hbx_enrollment) do
      FactoryBot.create(:hbx_enrollment,
                        family: family,
                        household: family.active_household,
                        coverage_kind: 'health',
                        effective_on: TimeKeeper.date_of_record.beginning_of_month,
                        enrollment_kind: 'open_enrollment',
                        kind: 'individual',
                        consumer_role: person.consumer_role,
                        rating_area_id: rating_area.id,
                        product: product)
    end

    let!(:rating_area) do
      ::BenefitMarkets::Locations::RatingArea.rating_area_for(person.rating_address, during: TimeKeeper.date_of_record.beginning_of_month) || FactoryBot.create_default(:benefit_markets_locations_rating_area)
    end

    let!(:product) do
      FactoryBot.create(:benefit_markets_products_health_products_health_product,
                        hios_id: '11111111122301-01',
                        csr_variant_id: '01',
                        metal_level_kind: :silver,
                        application_period: TimeKeeper.date_of_record.beginning_of_year..TimeKeeper.date_of_record.end_of_year,
                        benefit_market_kind: :aca_individual)
    end

    let(:new_aptc_amount) {'1000'}
    let(:new_aptc_pct) {'0.55' }
    let(:max_tax_credit) {'2000'}
    let(:new_aptc_amount_float) { new_aptc_amount.to_f }
    let(:max_tax_credit_float) { max_tax_credit.to_f }
    let(:new_effective_date) { Insured::Factories::SelfServiceFactory.find_enrollment_effective_on_date(TimeKeeper.date_of_record.in_time_zone('Eastern Time (US & Canada)'), hbx_enrollment.effective_on).to_date }

    let(:params) {{'applied_pct_1' => new_aptc_pct, 'aptc_applied_total' => new_aptc_amount, 'hbx_enrollment_id' => hbx_enrollment.id.to_s, max_aptc: max_tax_credit}}

    before :each do
      allow(EnrollRegistry[:temporary_configuration_enable_multi_tax_household_feature].feature).to receive(:is_enabled).and_return(true)
      allow(EnrollRegistry[:fifteenth_of_the_month_rule_overridden].feature).to receive(:is_enabled).and_return(true)
      sign_in user
      post :edit_aptc, params: params
    end

    it "should update APTC amount on the new enrollment based on the aggregate aptc amount" do
      family.reload
      new_enrollment = family.hbx_enrollments.last
      new_enrollment.effective_on
      if hbx_enrollment.effective_on.year == new_effective_date.year
        expect(new_enrollment.elected_aptc_pct).to eq(new_aptc_amount_float / max_tax_credit_float)
      else
        # Can't create a corresponding enrollment during the end of the year due to overlapping plan year issue and hence disabling the change tax credit button
        expect(new_enrollment.elected_aptc_pct).to eq(hbx_enrollment.elected_aptc_pct)
      end
    end
  end

  context "GET terminate_selection" do
    before { allow(Person).to receive(:find).and_return(person) }
    it "return http success and render" do
      sign_in user
      get :terminate_selection, params: { person_id: person.id }
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:terminate_selection)
    end

    context 'for termination_date_options' do
      before :each do
        @shop_sep = person.primary_family.latest_shop_sep
        @shop_sep.qualifying_life_event_kind.update_attributes!(termination_on_kinds: ['exact_date'])
        sign_in user
        get :terminate_selection, params: { person_id: person.id }
      end

      it 'should assign termination_date_options' do
        expect(assigns(:termination_date_options)).to eq({ hbx_enrollment.id.to_s => [@shop_sep.qle_on] })
      end
    end
  end

  context "POST terminate" do

    before do
      allow(Person).to receive(:find).and_return(person)
      sign_in user
      request.env["HTTP_REFERER"] = edit_plan_insured_group_selections_path(person_id: person.id, hbx_enrollment_id: hbx_enrollment.id)
      allow(HbxEnrollment).to receive(:find).and_return(hbx_enrollment)
    end

    it "should redirect to family home if termination is possible" do
      allow(hbx_enrollment).to receive(:may_terminate_coverage?).and_return(true)
      allow(hbx_enrollment).to receive(:terminate_benefit)
      expect(HbxEnrollment.aasm.state_machine.events[:terminate_coverage].transitions[0].opts.values.include?(:propogate_terminate)).to eq true
      expect(hbx_enrollment.termination_submitted_on).to eq nil
      post :terminate, params: { term_date: TimeKeeper.date_of_record, hbx_enrollment_id: hbx_enrollment.id }
      expect(hbx_enrollment.termination_submitted_on.to_date).to eq(TimeKeeper.datetime_of_record.to_date)
      expect(response).to redirect_to(family_account_path)
    end

    it "should redirect back if hbx enrollment can't be terminated" do
      hbx_enrollment.assign_attributes(aasm_state: "shopping")
      post :terminate, params: { term_date: TimeKeeper.date_of_record, hbx_enrollment_id: hbx_enrollment.id }
      expect(hbx_enrollment.may_terminate_coverage?).to be_falsey
      expect(response).to redirect_to(edit_plan_insured_group_selections_path(person_id: person.id, hbx_enrollment_id: hbx_enrollment.id))
    end


    it "should redirect back if termination date is in the past" do
      allow(hbx_enrollment).to receive(:terminate_benefit)
      post :terminate, params: { term_date: TimeKeeper.date_of_record - 10.days, hbx_enrollment_id: hbx_enrollment.id }
      expect(hbx_enrollment.may_terminate_coverage?).to be_truthy
      expect(response).to redirect_to(edit_plan_insured_group_selections_path(person_id: person.id, hbx_enrollment_id: hbx_enrollment.id))
    end

  end

  context "POST CREATE" do
    let(:family_member_ids) {{"0"=>family.family_members.first.id}}

    before do
      allow(Person).to receive(:find).and_return(person)
      allow(hbx_enrollment).to receive(:is_shop?).and_return(true)
      allow(controller).to receive(:is_user_authorized?).and_return(true)
      sign_in user
      family.reload
    end

    it "should redirect" do
      family.active_household.hbx_enrollments << [hbx_enrollment]
      family.save
      sign_in user
      allow(hbx_enrollment).to receive(:save).and_return(true)
      post :create, params: { person_id: person.id, employee_role_id: employee_role.id, family_member_ids: family_member_ids }
      family.reload
      family.active_household.reload
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(insured_plan_shopping_path(id: family.active_household.hbx_enrollments[1].id, market_kind: 'shop', coverage_kind: 'health', enrollment_kind: ''))
    end

    it "with change_plan" do
      family.active_household.hbx_enrollments << [hbx_enrollment]
      family.save
      user = FactoryBot.create(:user, id: 98, person: FactoryBot.create(:person))
      sign_in user
      allow(hbx_enrollment).to receive(:save).and_return(true)
      post :create, params: { person_id: person.id, employee_role_id: employee_role.id, family_member_ids: family_member_ids, change_plan: 'change' }
      family.reload
      family.active_household.reload
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(insured_plan_shopping_path(id: family.active_household.hbx_enrollments[1].id, change_plan: 'change', coverage_kind: 'health', market_kind: 'shop', enrollment_kind: ''))
    end

    context "when keep_existing_plan" do
      let(:old_hbx) {hbx_enrollment}

      before :each do
        family.active_household.hbx_enrollments << [hbx_enrollment]
        family.save
        user = FactoryBot.create(:user, person: FactoryBot.create(:person))
        sign_in user
        allow(old_hbx).to receive(:is_shop?).and_return true
        allow(employee_role.census_employee).to receive(:coverage_effective_on).with(hbx_enrollment.sponsored_benefit_package).and_return(hbx_enrollment.effective_on)
        family.active_household.reload
        old_hbx.update_attributes(effective_on: employee_role.census_employee.employer_profile.plan_years.first.effective_period.min)
        post :create, params: { person_id: person.id, employee_role_id: employee_role.id, family_member_ids: family_member_ids, commit: 'Keep existing plan', change_plan: 'change', hbx_enrollment_id: old_hbx.id }
        family.reload
        family.active_household.reload
      end

      it "should redirect" do
        expect(response).to have_http_status(:redirect)
        expect(response).not_to redirect_to(purchase_insured_families_path(change_plan:'change', coverage_kind: 'health', market_kind:'shop', hbx_enrollment_id: old_hbx.id))
      end

      it "should get special_enrollment_period_id" do
        expect(family.active_household.hbx_enrollments[1].special_enrollment_period_id).to eq family.earliest_effective_shop_sep.id
      end
    end

    context "family has active sep" do
      let(:person1) { FactoryBot.create(:person, :with_family, :with_employee_role, first_name: "mock")}
      let(:family1) { person1.primary_family }
      let(:family_member_ids) {{"0" => family1.family_members.first.id}}
      let!(:new_household) {family1.households.where(:id => {"$ne" => family.households.first.id.to_s}).first}
      let(:start_on) { TimeKeeper.date_of_record }
      let(:benefit_package) {hbx_enrollment.sponsored_benefit_package}

      let(:qle) do
        QualifyingLifeEventKind.create(
          title: "Married",
          tool_tip: "Enroll or add a family member because of marriage",
          action_kind: "add_benefit",
          event_kind_label: "Date of married",
          market_kind: "shop",
          ordinal_position: 15,
          reason: "marriage",
          edi_code: "32-MARRIAGE",
          effective_on_kinds: ["first_of_next_month"],
          pre_event_sep_in_days: 0,
          post_event_sep_in_days: 30,
          is_self_attested: true,
          is_visible: true,
          is_active: true
        )
      end
      let(:special_enrollment_period) {[double("SpecialEnrollmentPeriod")]}
      let!(:sep) { family1.special_enrollment_periods.create(qualifying_life_event_kind: qle, qle_on: qle.created_at, effective_on_kind: qle.event_kind_label, effective_on: benefit_package.effective_period.min, start_on: start_on, end_on: start_on + 30.days) }

      let(:params) do
        { :person_id => person1.id,
          :employee_role_id => person1.employee_roles.first.id,
          :market_kind => "shop",
          :change_plan => "change_plan",
          :hbx_enrollment_id => hbx_enrollment.id,
          :family_member_ids => family_member_ids,
          :enrollment_kind => 'special_enrollment',
          :coverage_kind => hbx_enrollment.coverage_kind}
      end
      it "should create an hbx enrollment" do
        sign_in user
        allow(Person).to receive(:find).and_return(person1)
        post :create, params: {person_id: person1.id, employee_role_id: person1.employee_roles.first.id, market_kind: "shop", family_member_ids: family_member_ids, change_plan: 'change_plan', hbx_enrollment_id: hbx_enrollment.id, enrollment_kind: 'special_enrollment', coverage_kind: hbx_enrollment.coverage_kind }
        expect(assigns(:change_plan)).to eq "change_by_qle"
      end
    end

    context "when keep_existing_plan_id_is_nil" do
      let(:existing_product) { ::BenefitMarkets::Products::Product.new(:id => existing_product_id) }
      let(:old_hbx) { HbxEnrollment.new(:sponsored_benefit_package_id => sponsored_benefit_package_id, :sponsored_benefit_id => sponsored_benefit_id, :product => existing_product) }
      before :each do
        user = FactoryBot.create(:user, person: FactoryBot.create(:person))
        sign_in user
        allow(hbx_enrollments).to receive(:show_enrollments_sans_canceled).and_return []
        allow(hbx_enrollments).to receive(:build).and_return(hbx_enrollment)
        allow(hbx_enrollment).to receive(:save).and_return(true)
        allow(hbx_enrollment).to receive(:plan=).and_return(true)
        allow(HbxEnrollment).to receive(:find).and_return old_hbx
        allow(old_hbx).to receive(:is_shop?).and_return true
        allow(old_hbx).to receive(:family).and_return family
        post :create, params: { person_id: person.id, employee_role_id: employee_role.id, family_member_ids: family_member_ids, commit: 'Keep existing plan', change_plan: 'change', hbx_enrollment_id: old_hbx.id }
      end

      it "should redirect" do
        expect(response).to have_http_status(:redirect)
        expect(response).not_to redirect_to(purchase_insured_families_path(change_plan:'change', coverage_kind: 'health', market_kind:'shop', hbx_enrollment_id: old_hbx.id))
      end

      it "should get special enrollment id as nil" do
        expect(flash[:error]).not_to match /undefined method `id' for nil:NilClass/
      end
    end

    it "should not render group selection page if valid" do
      sign_in user

      allow(hbx_enrollments).to receive(:show_enrollments_sans_canceled).and_return []
      allow(person).to receive(:employee_roles).and_return([employee_role])
      allow(hbx_enrollment).to receive(:save).and_return(false)

      post :create, params: { person_id: person.id, employee_role_id: employee_role.id, family_member_ids: family_member_ids }
      expect(response).to have_http_status(:redirect)
      expect(flash[:error]).not_to eq 'You must select the primary applicant to enroll in the healthcare plan'
      expect(response).not_to redirect_to(new_insured_group_selection_path(person_id: person.id, employee_role_id: employee_role.id, change_plan: '', market_kind: 'shop', enrollment_kind: ''))
    end

    context 'should block user from shopping' do

      it 'when benefit application is in termination pending' do
        initial_application.update_attributes(aasm_state: :termination_pending)
        user = FactoryBot.create(:user, id: 190, person: FactoryBot.create(:person))
        sign_in user
        post :create, params: { person_id: person.id, employee_role_id: employee_role.id, family_member_ids: family_member_ids }
        expect(flash[:error]).to eq "Your employer is no longer offering health insurance through #{EnrollRegistry[:enroll_app].setting(:short_name).item}." \
        " Please contact your employer or call our Customer Care Center at #{EnrollRegistry[:enroll_app].setting(:health_benefit_exchange_authority_phone_number).item}."
      end

      it 'when benefit application is terminated' do
        initial_application.update_attributes(aasm_state: :terminated)
        user = FactoryBot.create(:user, id: 191, person: FactoryBot.create(:person))
        sign_in user
        post :create, params: { person_id: person.id, employee_role_id: employee_role.id, family_member_ids: family_member_ids }
        expect(flash[:error]).to eq "Your employer is no longer offering health insurance through #{EnrollRegistry[:enroll_app].setting(:short_name).item}. Please contact your employer."
      end
    end

    it "for cobra with invalid date" do
      user = FactoryBot.create(:user, id: 196, person: FactoryBot.create(:person))
      sign_in user
      allow(census_employee).to receive(:have_valid_date_for_cobra?).and_return(false)
      allow(census_employee).to receive(:coverage_terminated_on).and_return(TimeKeeper.date_of_record)
      allow(census_employee).to receive(:cobra_begin_date).and_return(TimeKeeper.date_of_record + 1.day)
      allow(hbx_enrollments).to receive(:show_enrollments_sans_canceled).and_return []
      person.employee_roles.first.census_employee.update_attributes(aasm_state: "cobra_eligible", coverage_terminated_on: TimeKeeper.date_of_record, cobra_begin_date: TimeKeeper.date_of_record - 1.day)
      person.reload
      post :create, params: { person_id: person.id, employee_role_id: employee_role.id, family_member_ids: family_member_ids }
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(insured_plan_shopping_path(id: family.active_household.hbx_enrollments[0].id, coverage_kind: 'health', market_kind: 'shop', enrollment_kind: ''))
    end

    it "should render group selection page if without family_member_ids" do
      post :create, params: { person_id: person.id, employee_role_id: employee_role.id }
      expect(response).to have_http_status(:redirect)
      expect(flash[:error]).to eq 'You must select at least one Eligible applicant to enroll in the healthcare plan'
      expect(response).to redirect_to(new_insured_group_selection_path(person_id: person.id, employee_role_id: employee_role.id, change_plan: '', market_kind: 'shop', enrollment_kind: ''))
    end
  end

  context 'With keep_existing_plan' do
    context 'and osse subsidy eligible' do
      let(:family_member_ids) {{ "0" => family.family_members.first.id }}
      let(:old_hbx) {hbx_enrollment}
      let(:subsidy_amount) { 300.00 }

      before do
        family.active_household.hbx_enrollments << [hbx_enrollment]
        family.save
        user = FactoryBot.create(:user, person: FactoryBot.create(:person))

        allow_any_instance_of(HbxEnrollment).to receive(:shop_osse_eligibility_is_enabled?).and_return(true)
        allow_any_instance_of(BenefitSponsors::BenefitApplications::BenefitApplication).to receive(:osse_eligible?).and_return(true)
        allow_any_instance_of(HbxEnrollment).to receive(:osse_subsidy_for_member).and_return(subsidy_amount)
        allow(controller).to receive(:is_user_authorized?).and_return(true)

        sign_in user
        allow(old_hbx).to receive(:is_shop?).and_return true
        allow(employee_role.census_employee).to receive(:coverage_effective_on).with(hbx_enrollment.sponsored_benefit_package).and_return(hbx_enrollment.effective_on)
        family.active_household.reload
        old_hbx.update_attributes(effective_on: employee_role.census_employee.employer_profile.plan_years.first.effective_period.min)
        post :create, params: { person_id: person.id, employee_role_id: employee_role.id, family_member_ids: family_member_ids, commit: 'Keep existing plan', change_plan: 'change', hbx_enrollment_id: old_hbx.id }
        family.reload
        family.active_household.reload
      end

      it 'should update childcare subsidy amount' do
        new_enrollment_id = response.redirect_url.scan(%r{.*plan_shoppings/(.+)/thankyou.*}).flatten[0]

        enrollment = HbxEnrollment.find(new_enrollment_id)
        expect(enrollment.eligible_child_care_subsidy).to be_a(Money)
        expect(enrollment.eligible_child_care_subsidy.to_f).to eq(subsidy_amount)
      end
    end
  end

  context "POST CREATE for IVL" do
    context "for nil rating area" do
      before do
        allow(EnrollRegistry[:enroll_app].setting(:geographic_rating_area_model)).to receive(:item).and_return('county')
        allow(EnrollRegistry[:enroll_app].setting(:rating_areas)).to receive(:item).and_return('county')
        allow(controller).to receive(:is_user_authorized?).and_return(true)
        ::BenefitMarkets::Locations::RatingArea.all.update_all(covered_states: nil)
        sign_in user
        @person1 = FactoryBot.create(:person, :with_active_consumer_role, :with_consumer_role)
        @family = FactoryBot.create(:family, :with_primary_family_member, :person => @person1)
        @person1.consumer_role
        @person1.addresses.update_all(county: nil)
      end

      it "should redirect to family home page" do
        post :create, params: { "person_id" => @person1.id, "family_member_ids" => {"0" => @family.primary_applicant.id}, "market_kind" => "individual", "coverage_kind" => "health"}
        expect(response).to have_http_status(:redirect)
        expect(flash[:error]).to eq l10n("insured.out_of_state_error_message")
      end
    end

    context 'create enrollment' do
      let(:family_member) { family.family_members.first }
      let(:params) do
        {
          "person_id" => person.id,
          "family_member_ids" => {"0" => family_member.id },
          "is_tobacco_user_#{family_member.id}" => "Y",
          "market_kind" => "individual",
          "coverage_kind" => "health",
          "change_plan" => "change_by_qle",
          "commit" => "Shop for new plan"
        }
      end

      before do
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:fehb_market).and_return(false)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:aca_shop_market).and_return(false)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:tobacco_cost).and_return(true)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:prevent_concurrent_sessions).and_return(false)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:preferred_user_access).and_return(false)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:choose_shopping_method).and_return(false)
        sign_in user
      end

      it 'creates enrollment & set tobacco_use on hbx_enrollment member' do
        expect(family.active_household.hbx_enrollments.size).to eq 0
        post :create, params: {
          "person_id" => person.id,
          "family_member_ids" => {"0" => family_member.id },
          "is_tobacco_user_#{family_member.id}" => "Y",
          "market_kind" => "individual",
          "coverage_kind" => "health",
          "change_plan" => "change_by_qle",
          "effective_on_option_selected" => TimeKeeper.date_of_record.to_s,
          "commit" => "Shop for new plan"
        }

        expect(response).to have_http_status(:redirect)
        ivl_enrollments = HbxEnrollment.where(kind: 'individual')
        expect(ivl_enrollments.size).to eq 1
        expect(ivl_enrollments.first.hbx_enrollment_members.first.tobacco_use).to eq 'Y'
      end
    end
  end
end
