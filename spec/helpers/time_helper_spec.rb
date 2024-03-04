require "rails_helper"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe TimeHelper, :type => :helper, dbclean: :after_each do
  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup initial benefit application"

  let(:employer_profile) { abc_profile }
  let(:plan_year) { initial_application }
  let(:person) { FactoryBot.create(:person) }
  let(:employee_role) {FactoryBot.create(:employee_role, person: person, employer_profile: employer_profile)}
  let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}
  let!(:enrollment) do
    FactoryBot.create(:hbx_enrollment, :with_enrollment_members, :with_product,
                      household: family.active_household,
                      family: family,
                      aasm_state: "coverage_selected",
                      submitted_at: initial_application.open_enrollment_period.max,
                      rating_area_id: initial_application.recorded_rating_area_id,
                      sponsored_benefit_id: initial_application.benefit_packages.first.health_sponsored_benefit.id,
                      sponsored_benefit_package_id: initial_application.benefit_packages.first.id,
                      benefit_sponsorship_id: initial_application.benefit_sponsorship.id,
                      employee_role_id: employee_role.id)
  end
  let(:individual_family) { FactoryBot.create(:family, :with_primary_family_member)}
  let(:individual_enrollment) {FactoryBot.create(:hbx_enrollment, :individual_unassisted, family: individual_family,  household: individual_family.active_household)}

  before :all do
    TimeKeeper.set_date_of_record_unprotected!(Date.today)
  end

  describe "time remaining in words" do
    it "counts 95 days from the passed in date" do
      expect(helper.time_remaining_in_words(TimeKeeper.date_of_record)).to eq("95 days")
    end
  end

  describe "set earliest date for terminating enrollment" do
    it "counts -7 days from enrollment effective date" do
      enrollment.effective_on = (TimeKeeper.date_of_record - 7.days)
      expect(helper.set_date_min_to_effective_on(enrollment)).to eq(TimeKeeper.date_of_record - 6.days)
    end
  end

  describe "set earliest date to beginning of year" do
    it "returns beginning of the year plus the given offset" do
      enrollment.effective_on = (TimeKeeper.date_of_record)
      expect(helper.set_date_min_to_beginning_of_year(enrollment)).to eq(TimeKeeper.date_of_record.beginning_of_year)
      expect(helper.set_date_min_to_beginning_of_year(enrollment, 7)).to eq(TimeKeeper.date_of_record.beginning_of_year + 7.days)
    end
  end

  describe "set latest date for terminating enrollment" do
    context "for enrollment in shop market"do
      it "sets the latest date able to terminate an enrollment to be 1 year less 1 day from the enrollment start date" do
        enrollment.effective_on = (TimeKeeper.date_of_record - 7.days)
        #latest_date = Date.new(enrollment.effective_on.year, 12, 31)
        latest_date = enrollment.sponsored_benefit_package.end_on
        expect(helper.set_date_max_to_plan_end_of_year(enrollment)).to eq(latest_date)
      end
    end

    context "for employee with cobra enrollment" do
      it "sets the plan years last day on the calendar widget and allows to change the enrollment termination date" do
        enrollment.update_attributes(kind: "employer_sponsored_cobra")
        enrollment.effective_on = (TimeKeeper.date_of_record - 7.days)
        #latest_date = Date.new(enrollment.effective_on.year, 12, 31)
        latest_date = enrollment.sponsored_benefit_package.end_on
        expect(helper.set_date_max_to_plan_end_of_year(enrollment)).to eq(latest_date)
      end
    end

    context "for enrollment in individual market"do
      it "sets the latest date able to terminate an enrollment to be the last day of the calendar year in which the enrollment starts" do
        individual_enrollment.effective_on = (TimeKeeper.date_of_record - 7.days)
        latest_date = Date.new(individual_enrollment.effective_on.year, 12, 31)
        expect(helper.set_date_max_to_plan_end_of_year(individual_enrollment)).to eq(latest_date)
      end
    end
  end

  describe "set_default_termination_date_value" do
    before do
      allow(family).to receive_message_chain("primary_applicant.person").and_return(person)
      allow(person).to receive(:has_consumer_role?).and_return true
      allow(person).to receive(:active_employee_roles).and_return([employee_role])
      allow(employer_profile).to receive(:plan_years).and_return(plan_year)
    end
    it "sets to todays date if current_date is within the enrollments plan_year" do
      enrollment.effective_on = (TimeKeeper.date_of_record - 1.month)
      expect(helper.set_default_termination_date_value(enrollment)).to eq(TimeKeeper.date_of_record)
    end

    context "inside a leap year" do
      if TimeKeeper.date_of_record.leap?
        it "sets to last day of enrollment if current_date is outside the plan_year" do
          enrollment.effective_on = (TimeKeeper.date_of_record - 4.year)
          expect(helper.set_default_termination_date_value(enrollment)).to eq(enrollment.effective_on + 4.year)
        end
      end
    end

    context "outside of leap year" do
      unless TimeKeeper.date_of_record.leap?
        it "sets to last day of enrollment if current_date is outside the plan_year" do
          enrollment.effective_on = (TimeKeeper.date_of_record - 2.year)
          expect(helper.set_default_termination_date_value(enrollment)).to eq(enrollment.effective_on + 2.year)
        end
      end
    end
  end

  describe "SET optional_effective_on date on a SEP" do
    let!(:employee_role)   { FactoryBot.create(:employee_role, benefit_sponsors_employer_profile_id: abc_profile.id, hired_on: hired_on, person: person, census_employee: census_employee) }

    let(:census_employee) { create(:census_employee, benefit_sponsorship: benefit_sponsorship, benefit_sponsors_employer_profile_id: benefit_sponsorship.profile.id) }
    let(:person) { FactoryBot.create(:person) }
    let(:hired_on)        { plan_year.start_on - 10.days }

    context "for shop market" do
      before do
        census_employee.benefit_group_assignments << build(:benefit_group_assignment, benefit_group: current_benefit_package, census_employee: census_employee, start_on: plan_year.start_on, end_on: plan_year.end_on)
        census_employee.reload
      end

      it "returns minimum range as start_date of plan_year" do
        plan_year.update_attributes(effective_period: (TimeKeeper.date_of_record - 1.month)..(TimeKeeper.date_of_record - 1.month + 1.year - 1.day))
        census_employee.reload
        expect(helper.sep_optional_date(family, 'min', nil, plan_year.start_on)).to eq(plan_year.start_on)
      end

      it "returns maximum range as end_date of plan_year" do
        expect(helper.sep_optional_date(family, 'max', nil, plan_year.start_on)).to eq(plan_year.end_on)
      end
    end

    context '#prior_plan_year_shop_sep feature turned on' do
      let!(:employee_role)   { FactoryBot.create(:employee_role, benefit_sponsors_employer_profile_id: abc_profile.id, hired_on: hired_on, person: person, census_employee: census_employee) }

      let(:census_employee) { create(:census_employee, benefit_sponsorship: benefit_sponsorship, benefit_sponsors_employer_profile_id: benefit_sponsorship.profile.id) }
      let(:person) { FactoryBot.create(:person) }
      let(:hired_on)        { plan_year.start_on - 10.days }

      before do
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:prior_plan_year_shop_sep).and_return(true)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:fehb_market).and_return(true)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:validate_quadrant).and_return true
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:display_county).and_return false
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:validate_ssn).and_return(false)
        census_employee.benefit_group_assignments << build(:benefit_group_assignment, benefit_group: current_benefit_package, census_employee: census_employee, start_on: initial_application.start_on, end_on: initial_application.end_on)
        census_employee.link_employee_role!
        census_employee.update_attributes(employee_role_id: employee_role.id)
        census_employee.reload
      end

      context 'when PY is active' do
        it "returns maximum range as end_date of plan_year" do
          expect(helper.sep_optional_date(family, 'max', nil, TimeKeeper.date_of_record + 5.days)).to eq(initial_application.end_on)
        end
      end

      context 'when py is expired' do
        before do
          start_date = TimeKeeper.date_of_record.beginning_of_month - 12.months
          end_date = start_date + 12.months - 1.day
          effective_period = start_date..end_date
          initial_application.update_attributes(effective_period: effective_period)
          initial_application.expire!
          census_employee.reload
        end
        it "returns maximum range when py is expired" do
          expect(helper.sep_optional_date(family, 'max', nil, TimeKeeper.date_of_record.beginning_of_month - 5.days)).to eq(initial_application.end_on)
        end
      end
      # TODO: Enable this when terminated state is included for prior py shopping(proj 200)
      # context 'when py is terminated' do
      #   before do
      #     start_date = TimeKeeper.date_of_record.beginning_of_month - 12.months
      #     end_date = start_date + 12.months - 1.day
      #     effective_period = start_date..end_date
      #     initial_application.update_attributes(effective_period: effective_period)
      #     initial_application.terminate_enrollment!
      #     census_employee.reload
      #   end
      #   it "returns maximum range when py is terminated" do
      #     expect(helper.sep_optional_date(family, 'max', nil, TimeKeeper.date_of_record.beginning_of_month - 5.days)).to eq(initial_application.end_on)
      #   end
      # end
    end

    context '#prior_plan_year_shop_sep feature turned off' do
      let!(:employee_role)   { FactoryBot.create(:employee_role, benefit_sponsors_employer_profile_id: abc_profile.id, hired_on: hired_on, person: person, census_employee: census_employee) }

      let(:census_employee) { create(:census_employee, benefit_sponsorship: benefit_sponsorship, benefit_sponsors_employer_profile_id: benefit_sponsorship.profile.id) }
      let(:person) { FactoryBot.create(:person) }
      let(:hired_on)        { plan_year.start_on - 10.days }
      before do
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:prior_plan_year_shop_sep).and_return(false)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:fehb_market).and_return(true)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:validate_quadrant).and_return true
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:display_county).and_return false
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:validate_ssn).and_return(false)
        census_employee.benefit_group_assignments << build(:benefit_group_assignment, benefit_group: current_benefit_package, census_employee: census_employee, start_on: initial_application.start_on, end_on: initial_application.end_on)
        census_employee.link_employee_role!
        census_employee.update_attributes(employee_role_id: employee_role.id)
      end

      context 'when py is expired' do
        before do
          initial_application.expire!
          census_employee.reload
        end
        it "not returns maximum range when py is expired" do
          expect(helper.sep_optional_date(family, 'max', nil, TimeKeeper.date_of_record - 5.days)).to eq(nil)
        end
      end

      context 'when py is terminated' do
        before do
          allow(EnrollRegistry).to receive(:feature_enabled?).with(:cancel_renewals_for_term).and_return(true)
          initial_application.terminate_enrollment!
          census_employee.reload
        end
        it "not returns maximum range when py is expired" do
          expect(helper.sep_optional_date(family, 'max', nil, TimeKeeper.date_of_record - 5.days)).to eq(nil)
        end
      end

      context 'when PY is active' do
        it "returns maximum range as end_date of plan_year" do
          expect(helper.sep_optional_date(family, 'max', nil, TimeKeeper.date_of_record + 5.days)).to eq(plan_year.end_on)
        end
      end
    end

    context '#prior_plan_year_sep feature turned on' do
      let!(:employee_role)   { FactoryBot.create(:employee_role, benefit_sponsors_employer_profile_id: abc_profile.id, hired_on: hired_on, person: person, census_employee: census_employee) }

      let(:census_employee) { create(:census_employee, benefit_sponsorship: benefit_sponsorship, benefit_sponsors_employer_profile_id: benefit_sponsorship.profile.id) }
      let(:person) { FactoryBot.create(:person) }
      let(:hired_on)        { plan_year.start_on - 10.days }

      before do
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:prior_plan_year_sep).and_return(true)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:fehb_market).and_return(true)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:prior_plan_year_shop_sep).and_return(true)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:validate_quadrant).and_return true
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:display_county).and_return false
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:validate_ssn).and_return(false)
        census_employee.benefit_group_assignments << build(:benefit_group_assignment, benefit_group: current_benefit_package, census_employee: census_employee, start_on: initial_application.start_on, end_on: initial_application.end_on)
        census_employee.link_employee_role!
        census_employee.update_attributes(employee_role_id: employee_role.id)
        census_employee.reload
      end

      context 'when PY is active' do
        it "returns maximum range as end_date of plan_year" do
          expect(helper.sep_optional_date(family, 'max', nil, TimeKeeper.date_of_record + 5.days)).to eq(initial_application.end_on)
        end
      end

      context 'when py is expired' do
        before do
          start_date = TimeKeeper.date_of_record.beginning_of_month - 12.months
          end_date = start_date + 12.months - 1.day
          effective_period = start_date..end_date
          initial_application.update_attributes(effective_period: effective_period)
          initial_application.expire!
          census_employee.reload
        end
        it "returns maximum range when py is expired" do
          expect(helper.sep_optional_date(family, 'max', nil, TimeKeeper.date_of_record.beginning_of_month - 5.days)).to eq(initial_application.end_on)
        end
      end

      context 'when py is terminated' do
        before do
          start_date = TimeKeeper.date_of_record.beginning_of_month - 12.months
          end_date = start_date + 12.months - 1.day
          effective_period = start_date..end_date
          initial_application.update_attributes(effective_period: effective_period)
          initial_application.terminate_enrollment!
          census_employee.reload
        end
        #TODO: Enable this when terminated enrollments are allowed for prior year end date changes
        xit "returns maximum range when py is terminated" do
          expect(helper.sep_optional_date(family, 'max', nil, TimeKeeper.date_of_record.beginning_of_month - 5.days)).to eq(initial_application.end_on)
        end
      end
    end

    context '#prior_plan_year_sep feature turned off' do
      let!(:employee_role)   { FactoryBot.create(:employee_role, benefit_sponsors_employer_profile_id: abc_profile.id, hired_on: hired_on, person: person, census_employee: census_employee) }

      let(:census_employee) { create(:census_employee, benefit_sponsorship: benefit_sponsorship, benefit_sponsors_employer_profile_id: benefit_sponsorship.profile.id) }
      let(:person) { FactoryBot.create(:person) }
      let(:hired_on)        { plan_year.start_on - 10.days }
      before do
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:prior_plan_year_sep).and_return(false)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:fehb_market).and_return(true)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:prior_plan_year_shop_sep).and_return(false)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:validate_quadrant).and_return true
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:display_county).and_return false
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:validate_ssn).and_return(false)
        census_employee.benefit_group_assignments << build(:benefit_group_assignment, benefit_group: current_benefit_package, census_employee: census_employee, start_on: initial_application.start_on, end_on: initial_application.end_on)
        census_employee.link_employee_role!
        census_employee.update_attributes(employee_role_id: employee_role.id)
      end

      context 'when py is expired' do
        before do
          initial_application.expire!
          census_employee.reload
        end
        it "not returns maximum range when py is expired" do
          expect(helper.sep_optional_date(family, 'max', nil, TimeKeeper.date_of_record - 5.days)).to eq(nil)
        end
      end

      context 'when py is terminated' do
        before do
          allow(EnrollRegistry).to receive(:feature_enabled?).with(:cancel_renewals_for_term).and_return(true)
          initial_application.terminate_enrollment!
          census_employee.reload
        end
        it "not returns maximum range when py is expired" do
          expect(helper.sep_optional_date(family, 'max', nil, TimeKeeper.date_of_record - 5.days)).to eq(nil)
        end
      end

      context 'when PY is active' do
        it "returns maximum range as end_date of plan_year" do
          expect(helper.sep_optional_date(family, 'max', nil, TimeKeeper.date_of_record + 5.days)).to eq(plan_year.end_on)
        end
      end
    end

    context "for individual market" do
      let(:person_with_consumer_role) { FactoryBot.create(:person, :with_consumer_role) }
      before do
        allow(family).to receive_message_chain("primary_applicant.person").and_return(person_with_consumer_role)
        allow(person).to receive(:has_consumer_role?).and_return false
      end

      it "should return nil as minmum range" do
        expect(helper.sep_optional_date(family, 'min')).to eq nil
      end

      it "should return nil as maximum range" do
        end_of_year = TimeKeeper.date_of_record.end_of_year
        expect(helper.sep_optional_date(family, 'max')).to eq nil
      end
    end

    context "for person with dual roles" do
      before do
        allow(family).to receive_message_chain("primary_applicant.person").and_return(person)
        allow(person).to receive(:has_consumer_role?).and_return true
      end

      it "returns minmum range as nil when market kind is ivl" do
        expect(helper.sep_optional_date(family, 'min', 'ivl')).to eq nil
      end

      it "returns maximum range as nil when market kind is ivl" do
        expect(helper.sep_optional_date(family, 'max', 'ivl')).to eq nil
      end

      it "returns minmum range as start_date of plan_year when market kind is shop" do
        expect(helper.sep_optional_date(family, 'min', 'shop', plan_year.start_on)).to eq(plan_year.start_on)
      end

      it "returns maximum range as end_date of plan_year when market kind is shop" do
        expect(helper.sep_optional_date(family, 'max', 'shop', plan_year.start_on)).to eq(plan_year.end_on)
      end

      it "returns minmum range as start_date of plan_year when market kind is shop" do
        expect(helper.sep_optional_date(family, 'min', 'fehb', plan_year.start_on)).to eq(plan_year.start_on)
      end

      it "returns maximum range as end_date of plan_year when market kind is shop" do
        expect(helper.sep_optional_date(family, 'max', 'fehb', plan_year.start_on)).to eq(plan_year.end_on)
      end

      it "returns minimum range as nil when market kind is nil" do
        expect(helper.sep_optional_date(family, 'min', nil)).to eq nil
      end

      it "returns maximum range as nil when market kind is nil" do
        expect(helper.sep_optional_date(family, 'max', nil)).to eq nil
      end
    end

    context "for person with no consumer or active employee roles" do
      before do
        allow(family).to receive_message_chain("primary_applicant.person").and_return(person)
        allow(person).to receive(:has_consumer_role?).and_return false
        allow(person).to receive(:active_employee_roles).and_return []
      end

      it "returns minmum range as nil" do
        expect(helper.sep_optional_date(family, 'min')).to eq nil
      end

      it "returns maximum range as nil" do
        expect(helper.sep_optional_date(family, 'max')).to eq nil
      end
    end
  end
end
