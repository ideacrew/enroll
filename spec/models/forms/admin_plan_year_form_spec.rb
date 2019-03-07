require 'rails_helper'

  RSpec.describe Forms::AdminPlanYearForm, type: :model, dbclean: :after_each do
    subject { Forms::AdminPlanYearForm.new }
    let!(:user)                { FactoryGirl.create(:user) }
    let!(:person)              { FactoryGirl.create(:person, user: user) }
    let!(:permission)          { FactoryGirl.create(:permission, :super_admin) }
    let!(:hbx_staff_role)      { FactoryGirl.create(:hbx_staff_role, person: person, permission_id: permission.id) }
    let!(:organization)        { FactoryGirl.create(:organization) }
    let!(:employer_profile)    { FactoryGirl.create(:employer_profile, organization: organization) }
    let!(:plan_year)           { FactoryGirl.create(:plan_year, fte_count: valid_fte_count, employer_profile: employer_profile) }
    let!(:benefit_group)       { FactoryGirl.create(:benefit_group, plan_year: plan_year) }
    let(:start_on)             { TimeKeeper.date_of_record.beginning_of_month.next_month }
    let(:end_on)               { start_on + 1.year - 1.day }
    let(:valid_fte_count)      { 5 }
    let(:valid_params) do
      {
        'organization_id' => organization.id,
        'start_on' => start_on,
        'end_on' => end_on,
        'open_enrollment_start_on' => start_on - 20.days,
        'open_enrollment_end_on' => start_on - 10.days,
        'fte_count' => 10
      }
    end

    let(:invalid_params) do
      {
        'organization_id' => organization.id,
        'start_on' => TimeKeeper.date_of_record + 4.months,
        'end_on' =>  TimeKeeper.date_of_record + 1.year + 4.months - 1.day,
        'open_enrollment_start_on' => TimeKeeper.date_of_record + 3.months + 20.day,
        'open_enrollment_end_on' => TimeKeeper.date_of_record + 3.months
      }
    end

    let(:invalid_params1) do
      {
        'organization_id' => organization.id,
        'start_on' => TimeKeeper.date_of_record + 4.months,
        'end_on' =>  TimeKeeper.date_of_record + 1.year + 4.months - 1.day,
        'open_enrollment_start_on' => TimeKeeper.date_of_record + 3.months + 20.day,
        'open_enrollment_end_on' => TimeKeeper.date_of_record + 21.day
      }
    end

    describe 'model attributes' do
      it {
        %i[start_on end_on open_enrollment_start_on open_enrollment_end_on admin_dt_action].each do |key|
          expect(subject.attributes.key?(key)).to be_truthy
        end
      }
    end

    describe 'validate_oe_dates' do
      context 'with invalid params' do
        let(:build_admin_plan_year_form) { Forms::AdminPlanYearForm.new(invalid_params) }

        it 'should return false' do
          expect(build_admin_plan_year_form.valid?).to be_falsey
        end
      end

      context 'with valid params' do
        let(:build_admin_plan_year_form) { Forms::AdminPlanYearForm.new(valid_params) }

        it 'should return true' do
          expect(build_admin_plan_year_form.valid?).to be_truthy
        end
      end
    end

    describe 'validate_minimum_oe_range' do
      context 'with invalid params' do
        let(:build_admin_plan_year_form) { Forms::AdminPlanYearForm.new(invalid_params1) }

        it 'should return false' do
          expect(build_admin_plan_year_form.valid?).to be_falsey
        end
      end

      context 'with valid params' do
        let(:build_admin_plan_year_form) { Forms::AdminPlanYearForm.new(valid_params) }

        it 'should return true' do
          expect(build_admin_plan_year_form.valid?).to be_truthy
        end
      end
    end

    describe '#for_new' do
      let(:admin_plan_year_form) { Forms::AdminPlanYearForm.new(valid_params) }

      it 'should assign benefit sponsorship' do
        form = ::Forms::AdminPlanYearForm.for_new(:organization_id => organization.id.to_s)
        expect(form.start_on_options).not_to be nil
        expect(form.organization_id).to eq organization.id.to_s
      end
    end

    describe '#for_create' do
      let(:params) do
        {
          'start_on' => (TimeKeeper.date_of_record.beginning_of_month + 2.months).strftime("%m/%d/%Y"),
          'end_on' => (TimeKeeper.date_of_record.beginning_of_month + 1.year + 2.months - 1.day).strftime("%m/%d/%Y"),
          'open_enrollment_start_on' => TimeKeeper.date_of_record.beginning_of_month.strftime("%m/%d/%Y"),
          'open_enrollment_end_on' => (TimeKeeper.date_of_record.beginning_of_month + 1.month + Settings.aca.shop_market.open_enrollment.monthly_end_on.days).strftime("%m/%d/%Y"),
          'employer_actions_id' => "family_actions_5c5b3afd83d00d6b750001e9",
          'organization_id' => organization.id.to_s
        }
      end

      it 'should create the form assign the params for forms' do
        form = Forms::AdminPlanYearForm.for_create(params)
        expect(form.start_on).to eq params['start_on']
        expect(form.open_enrollment_end_on).to eq params['open_enrollment_end_on']
        expect(form.start_on_options).not_to be nil
      end
    end

    describe '.create_plan_year' do
      let!(:plan_year)           { FactoryGirl.create(:plan_year, employer_profile: employer_profile) }
      let!(:benefit_group)       { FactoryGirl.create(:benefit_group, plan_year: plan_year) }
      let(:admin_plan_year_form) { Forms::AdminPlanYearForm.new(valid_params) }

      context 'for create plan year' do
        it 'should save successfully if update request received false' do
          expect(admin_plan_year_form.create_plan_year).to be_truthy
        end

        it 'should return false if applicat2ion has errors' do
          states = PlanYear::ACTIVE_STATES_PER_DT + PlanYear::RENEWING
          states.each do |state|
            plan_year.update_attribute(:aasm_state, state)
            expect(admin_plan_year_form.create_plan_year).to be_falsey
          end
        end
      end
    end
  end
