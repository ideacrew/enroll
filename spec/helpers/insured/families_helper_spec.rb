require "rails_helper"
require "#{SponsoredBenefits::Engine.root}/spec/shared_contexts/sponsored_benefits"

RSpec.describe Insured::FamiliesHelper, :type => :helper, dbclean: :after_each  do
  include_context "set up broker agency profile for BQT, by using configuration settings"

  describe "#plan_shopping_dependent_text", dbclean: :after_each  do
    let(:person) { FactoryBot.build_stubbed(:person)}
    let(:family) { FactoryBot.build_stubbed(:family, :with_primary_family_member, person: person) }
    let(:household) { FactoryBot.build_stubbed(:household, family: family) }
    let(:hbx_enrollment) { FactoryBot.build_stubbed(:hbx_enrollment, household: household, hbx_enrollment_members: [hbx_enrollment_member, hbx_enrollment_member_two]) }
    let(:hbx_enrollment_member) { FactoryBot.build_stubbed(:hbx_enrollment_member) }
    let(:hbx_enrollment_member_two) { FactoryBot.build_stubbed(:hbx_enrollment_member, is_subscriber: false) }

    it "it should return subscribers full name in span with dependent-text class" do
      allow(hbx_enrollment_member_two).to receive(:is_subscriber).and_return(true)
      allow(hbx_enrollment_member).to receive_message_chain("person.full_name").and_return("Bobby Boucher")
      expect(helper.plan_shopping_dependent_text(hbx_enrollment)).to eq "<span class=\"dependent-text\">Bobby Boucher</span>"
    end

    it "it should return subscribers and dependents modal" do
      allow(hbx_enrollment_member).to receive_message_chain("person.full_name").and_return("Bobby Boucher")
      allow(hbx_enrollment_member).to receive_message_chain("person.find_relationship_with").and_return("Spouse")
      allow(hbx_enrollment_member_two).to receive_message_chain("person.full_name").and_return("Danny Boucher")
      expect(helper.plan_shopping_dependent_text(hbx_enrollment)).to match '<h4 class="modal-title">Coverage For</h4>'
    end

  end

  describe "#generate_options_for_effective_on_kinds", dbclean: :after_each  do
    let(:qle) {FactoryBot.create(:qualifying_life_event_kind, effective_on_kinds: ['date_of_event', 'fixed_first_of_next_month'])}
    let(:person) {FactoryBot.create(:person, :with_family)}
    let(:family) { FactoryBot.create(:family, :with_primary_family_member) }
    let(:date) { TimeKeeper.date_of_record }

    context "QLEK with no effective_on_kind" do
      it "it should return blank array" do
        options = helper.generate_options_for_effective_on_kinds(nil, TimeKeeper.date_of_record)
        expect(options).to eq []
      end
    end

    context "QLEK with effective_on_kind" do

      before :each do
        assign(:family, family)
      end

      context "QLEK with date_of_event, fixed_first_of_next_month effective_on_kind" do
        it "it should return options" do
          options = helper.generate_options_for_effective_on_kinds(qle, TimeKeeper.date_of_record)
          expect(options).to eq [[date.to_s, 'date_of_event'], [(date.end_of_month + 1.day).to_s, 'fixed_first_of_next_month']]
        end
      end

      context "QLEK with first_of_this_month effective_on_kind" do

        it "it should return options for first_of_this_month for shop market" do
          qle.update_attributes(market_kind: 'shop', effective_on_kinds: ['first_of_this_month'])
          options = helper.generate_options_for_effective_on_kinds(qle, TimeKeeper.date_of_record)
          expect(options).to eq [[date.beginning_of_month.to_s, 'first_of_this_month']]
        end

        it "it should return options for first_of_this_month for individual market" do
          qle.update_attributes(market_kind: 'individual', effective_on_kinds: ['first_of_this_month'])
          options = helper.generate_options_for_effective_on_kinds(qle, TimeKeeper.date_of_record)
          expect(options).to eq [[date.beginning_of_month.to_s, 'first_of_this_month']]
        end
      end

      context "QLEK with first_of_month effective_on_kind" do

        it "it should return options for first_of_month for shop market" do
          qle.update_attributes(market_kind: 'shop', effective_on_kinds: ['first_of_month'])
          options = helper.generate_options_for_effective_on_kinds(qle, TimeKeeper.date_of_record)
          effective_date = date.day <= 15 ? date.end_of_month + 1.day : date.next_month.end_of_month + 1.day
          expect(options).to eq [[effective_date.to_s, 'first_of_month']]
        end

        it "it should return options for first_of_month for individual market" do
          qle.update_attributes(market_kind: 'individual', effective_on_kinds: ['first_of_month'])
          options = helper.generate_options_for_effective_on_kinds(qle, TimeKeeper.date_of_record)
          effective_date = date.day <= 15 ? date.end_of_month + 1.day : date.next_month.end_of_month + 1.day
          expect(options).to eq [[effective_date.to_s, 'first_of_month']]
        end
      end

      context "QLEK with first_of_next_month effective_on_kind" do

        it "it should return options for first_of_next_month for shop market" do
          qle.update_attributes(market_kind: 'shop', effective_on_kinds: ['first_of_next_month'])
          options = helper.generate_options_for_effective_on_kinds(qle, TimeKeeper.date_of_record)
          effective_date = date <= date.beginning_of_month ? date : date.end_of_month + 1.day
          expect(options).to eq [[effective_date.to_s, 'first_of_next_month']]
        end

        it "it should return options for first_of_next_month for individual market" do
          qle.update_attributes(market_kind: 'individual', effective_on_kinds: ['first_of_next_month'])
          options = helper.generate_options_for_effective_on_kinds(qle, TimeKeeper.date_of_record)
          expect(options).to eq [[(date.end_of_month + 1.day).to_s, 'first_of_next_month']]
        end
      end

      context "QLEK with first_of_next_month_coinciding effective_on_kind" do

        it "it should return options for first_of_next_month_coinciding for shop market" do
          qle.update_attributes(market_kind: 'shop', effective_on_kinds: ['first_of_next_month_coinciding'])
          options = helper.generate_options_for_effective_on_kinds(qle, TimeKeeper.date_of_record)
          effective_date = date == date.beginning_of_month ? date : date.end_of_month + 1.day
          expect(options).to eq [[effective_date.to_s, 'first_of_next_month_coinciding']]
        end

        it "it should return options for first_of_next_month_coinciding for individual market" do
          qle.update_attributes(market_kind: 'individual', effective_on_kinds: ['first_of_next_month_coinciding'])
          options = helper.generate_options_for_effective_on_kinds(qle, TimeKeeper.date_of_record)
          effective_date = date == date.beginning_of_month ? date : date.end_of_month + 1.day
          expect(options).to eq [[effective_date.to_s, 'first_of_next_month_coinciding']]
        end
      end

      context "QLEK with first_of_next_month_plan_selection effective_on_kind" do

        it "it should return options for first_of_next_month_plan_selection for shop market" do
          qle.update_attributes(market_kind: 'shop', effective_on_kinds: ['first_of_next_month_plan_selection'])
          options = helper.generate_options_for_effective_on_kinds(qle, TimeKeeper.date_of_record)
          expect(options).to eq [[(date.end_of_month + 1.day).to_s, 'first_of_next_month_plan_selection']]
        end

        it "it should return options for first_of_next_month_plan_selection for individual market" do
          qle.update_attributes(market_kind: 'individual', effective_on_kinds: ['first_of_next_month_plan_selection'])
          options = helper.generate_options_for_effective_on_kinds(qle, TimeKeeper.date_of_record)
          expect(options).to eq [[(date.end_of_month + 1.day).to_s, 'first_of_next_month_plan_selection']]
        end
      end

      context "QLEK with first_of_reporting_month effective_on_kind" do

        it "it should return options for first_of_reporting_month for shop market" do
          qle.update_attributes(market_kind: 'shop', effective_on_kinds: ['first_of_reporting_month'])
          options = helper.generate_options_for_effective_on_kinds(qle, TimeKeeper.date_of_record)
          expect(options).to eq [[date.next_month.beginning_of_month.to_s, 'first_of_reporting_month']]
        end

        it "it should return options for first_of_reporting_month for individual market" do
          qle.update_attributes(market_kind: 'individual', effective_on_kinds: ['first_of_reporting_month'])
          options = helper.generate_options_for_effective_on_kinds(qle, TimeKeeper.date_of_record)
          expect(options).to eq [[date.next_month.beginning_of_month.to_s, 'first_of_reporting_month']]
        end
      end

      context "QLEK with first_of_next_month_reporting effective_on_kind" do

        it "it should return options for first_of_next_month_reporting for shop market" do
          qle.update_attributes(market_kind: 'shop', effective_on_kinds: ['first_of_next_month_reporting'])
          options = helper.generate_options_for_effective_on_kinds(qle, TimeKeeper.date_of_record)
          expect(options).to eq [[(date.end_of_month + 1.day).to_s, 'first_of_next_month_reporting']]
        end

        it "it should return options for first_of_next_month_reporting for individual market" do
          qle.update_attributes(market_kind: 'individual', effective_on_kinds: ['first_of_next_month_reporting'])
          options = helper.generate_options_for_effective_on_kinds(qle, TimeKeeper.date_of_record)
          expect(options).to eq [[(date.end_of_month + 1.day).to_s, 'first_of_next_month_reporting']]
        end
      end

      context "QLEK with date_of_event effective_on_kind" do

        it "it should return options for date_of_event for shop market" do
          qle.update_attributes(market_kind: 'shop', effective_on_kinds: ['date_of_event'])
          options = helper.generate_options_for_effective_on_kinds(qle, TimeKeeper.date_of_record)
          expect(options).to eq [[date.to_s, 'date_of_event']]
        end

        it "it should return options for date_of_event for individual market" do
          qle.update_attributes(market_kind: 'individual', effective_on_kinds: ['date_of_event'])
          options = helper.generate_options_for_effective_on_kinds(qle, TimeKeeper.date_of_record)
          expect(options).to eq [[date.to_s, 'date_of_event']]
        end
      end

      context "QLEK with similar effective_on_kinds" do

        it "it should return uniq options" do
          qle.update_attributes(market_kind: 'shop', effective_on_kinds: ['date_of_event'])
          options = helper.generate_options_for_effective_on_kinds(qle, TimeKeeper.date_of_record)
          expect(options.count).to eq 1
          expect(options).to eq [[date.to_s, 'date_of_event']]
        end
      end

      context "QLE with event and reporting effective kinds" do

        it "it should return dates based on effective kinds" do
          qle.update_attributes(qle_event_date_kind: :submitted_at, effective_on_kinds: ['date_of_event', 'first_of_reporting_month'])
          options = helper.generate_options_for_effective_on_kinds(qle, TimeKeeper.date_of_record.last_month)
          expect(options).to eq [[TimeKeeper.date_of_record.last_month.to_s, 'date_of_event'],[TimeKeeper.date_of_record.beginning_of_month.to_s, 'first_of_reporting_month']]
        end
      end

      context "QLEK with date_of_event_plus_one effective_on_kind" do

        it "it should return options for date_of_event_plus_one for shop market" do
          qle.update_attributes(market_kind: 'shop', effective_on_kinds: ['date_of_event_plus_one'])
          options = helper.generate_options_for_effective_on_kinds(qle, TimeKeeper.date_of_record)
          expect(options).to eq [[date.next_day.to_s, 'date_of_event_plus_one']]
        end

        it "it should return options for date_of_event_plus_one for individual market" do
          qle.update_attributes(market_kind: 'individual', effective_on_kinds: ['date_of_event_plus_one'])
          options = helper.generate_options_for_effective_on_kinds(qle, TimeKeeper.date_of_record)
          expect(options).to eq [[date.next_day.to_s, 'date_of_event_plus_one']]
        end
      end
    end
  end

  describe "#render_plan_type_details", dbclean: :after_each do
    let(:dental_plan_2015){FactoryBot.create(:plan_template,:shop_dental, active_year: 2015, metal_level: "dental")}
    let(:dental_plan_2016){FactoryBot.create(:plan_template,:shop_dental, active_year: 2016, metal_level: "dental", dental_level: "high")}
    let(:health_plan_2016){FactoryBot.create(:plan_template,:shop_health, active_year: 2016, metal_level: "silver")}

    it "should return dental plan with dental_level = high for 2016 plan" do
      expect(helper.render_plan_type_details(dental_plan_2016)).to eq "<span class=\"dental-icon\">High</span>"
    end

    it "should return dental plan with metal_level = dental for 2015 plan" do
      expect(helper.render_plan_type_details(dental_plan_2015)).to eq "<span class=\"dental-icon\">Dental</span>"
    end

    it "should return health plan with metal_level = bronze" do
      expect(helper.render_plan_type_details(health_plan_2016)).to eq "<span class=\"silver-icon\">Silver</span>"
    end
  end

  describe "#current_premium", dbclean: :after_each do
    let!(:hbx_enrollment_double) do
      double(
        :is_shop? => false,
        :kind => kind,
        :hbx_id => "12345"
      )
    end

    let(:kind) { "coverall" }

    context "SHOP hbx_enrollment" do
      before :each do
        allow(hbx_enrollment_double).to receive(:is_shop?).and_return(true)
        allow(hbx_enrollment_double).to receive(:total_employee_cost).and_return("$100.00")
      end

      it "shows total employee cost" do
        expect(helper.current_premium(hbx_enrollment_double)).to eq("$100.00")
      end
    end

    context "hbx_enrollment total_premium throws error" do
      before :each do
        hbx_enrollment_double.stub(:total_premium).and_raise(StandardError.new("error"))
      end

      it "should not throw exception" do
        expect(helper.current_premium(hbx_enrollment_double)).to eq('Not Available.')
      end
    end

    context "IVL hbx_enrollment" do
      let(:kind) { "individual" }

      before :each do
        allow(hbx_enrollment_double).to receive(:total_premium).and_return(400.00)
        allow(hbx_enrollment_double).to receive(:total_ehb_premium).and_return(140.00)
        allow(hbx_enrollment_double).to receive(:applied_aptc_amount).and_return(150.00)
        allow(hbx_enrollment_double).to receive(:eligible_child_care_subsidy).and_return(0.00)
      end

      it "shows total employee cost" do
        expect(helper.current_premium(hbx_enrollment_double)).to eq(260.00)
      end

      context 'when childcare subsidy present' do
        before do
          allow(hbx_enrollment_double).to receive(:eligible_child_care_subsidy).and_return(260.00)
        end

        it "shows zero total employee cost" do
          expect(helper.current_premium(hbx_enrollment_double)).to eq(0.00)
        end
      end
    end
  end

  describe "#show_employer_panel", dbclean: :after_each do
    let(:person) {FactoryBot.build(:person)}
    let(:employee_role) {FactoryBot.build(:employee_role)}
    let(:census_employee) {FactoryBot.build(:census_employee)}
    let(:person_with_employee_role) {FactoryBot.create(:person, :with_employee_role)}

    it "should return false without employee_role" do
      expect(helper.newhire_enrollment_eligible?(nil)).to eq false
    end

    it "should return false with employee_role who has no census_employee" do
      allow(employee_role).to receive(:census_employee).and_return nil
      expect(helper.newhire_enrollment_eligible?(employee_role)).to eq false
    end

    context "with employee_role who has census_employee and newhire_enrollment_eligible" do
      before :each do
        allow(employee_role).to receive(:census_employee).and_return census_employee
        allow(census_employee).to receive(:newhire_enrollment_eligible?).and_return true
      end

      it "should return false when person can not select coverage" do
        allow(employee_role).to receive(:can_enroll_as_new_hire?).and_return false
        expect(helper.newhire_enrollment_eligible?(employee_role)).to eq false
      end

      it "should return true when person can select coverage" do
        allow(employee_role).to receive(:can_enroll_as_new_hire?).and_return true
        expect(helper.newhire_enrollment_eligible?(employee_role)).to eq true
      end
    end
  end

  describe "has_writing_agent?" do
    let(:employee_role) { FactoryBot.build(:employee_role) }
    let(:person) { FactoryBot.build(:person) }

    it "should return false when employee_role is passwed with out writing_agent" do
      expect(helper.has_writing_agent?(employee_role)).to eq false
    end

    it "should return false when person is passwed with out writing_agent" do
      expect(helper.has_writing_agent?(person)).to eq false
    end

    it "should return true when employee_role is passed with out writing_agent" do
      allow(person).to receive_message_chain(:primary_family,:current_broker_agency,:writing_agent).and_return(true)
      expect(helper.has_writing_agent?(person)).to eq true
    end

  end

  describe "display_aasm_state?" do
    let(:person) { FactoryBot.build_stubbed(:person)}
    let(:family) { FactoryBot.build_stubbed(:family, :with_primary_family_member, person: person) }
    let(:household) { FactoryBot.build_stubbed(:household, family: family) }
    let(:hbx_enrollment) { FactoryBot.build_stubbed(:hbx_enrollment, household: household, hbx_enrollment_members: [hbx_enrollment_member]) }
    let(:hbx_enrollment_member) { FactoryBot.build_stubbed(:hbx_enrollment_member) }
    states = ["coverage_selected", "coverage_canceled", "coverage_terminated", "shopping", "inactive", "unverified", "coverage_enrolled", "auto_renewing", "any_state"]
    show_for_ivl = ["coverage_selected", "coverage_canceled", "coverage_terminated", "auto_renewing", "renewing_coverage_selected"]

    context "IVL market" do
      before :each do
        allow(hbx_enrollment).to receive(:is_shop?).and_return(false)
      end
      states.each do |status|
        it "returns #{show_for_ivl.include?(status)} for #{status}" do
          hbx_enrollment.aasm_state = status
          expect(helper.display_aasm_state?(hbx_enrollment)).to eq show_for_ivl.include?(status)
        end
      end
    end

    context "SHOP market" do
      before :each do
        allow(hbx_enrollment).to receive(:is_shop?).and_return(true)
      end
      states.each do |status|
        it "returns true for #{status}" do
          hbx_enrollment.aasm_state = status
          expect(helper.display_aasm_state?(hbx_enrollment)).to eq true
        end
      end
    end
  end

  describe "ShopForPlan using SEP", dbclean: :after_each do
    let(:qle_on) {Date.new(TimeKeeper.date_of_record.year, 04, 14)}
    let(:person) {FactoryBot.create(:person, :with_employee_role, :with_family)}
    let(:family) { FactoryBot.create(:family, :with_primary_family_member) }
    let(:qle_first_of_month) { FactoryBot.create(:qualifying_life_event_kind, :effective_on_first_of_month ) }
    let(:qle_with_date_options_available) { FactoryBot.create(:qualifying_life_event_kind, :effective_on_first_of_month, date_options_available: true ) }
    let(:sep_without_date_options) {
      sep = family.special_enrollment_periods.new
      sep.effective_on_kind = 'first_of_month'
      sep.qualifying_life_event_kind= qle_first_of_month
      sep.qualifying_life_event_kind_id = qle_first_of_month.id
      sep.qle_on= Date.new(TimeKeeper.date_of_record.year, 04, 14)
      sep.admin_flag = true
      sep
    }

    let(:sep_with_date_options) {
      sep = family.special_enrollment_periods.new
      sep.effective_on_kind = 'first_of_month'
      sep.qualifying_life_event_kind= qle_first_of_month
      sep.qualifying_life_event_kind_id = qle_with_date_options_available.id
      sep.qle_on = qle_on
      sep.optional_effective_on = [qle_on+5.days, qle_on+6.days, qle_on+7.days]
      sep.admin_flag = true
      sep
    }
    context "when building ShopForPlan link" do
      it "should have class 'existing-sep-item' for a SEP with date options QLE and optional_effective_on populated " do
        expect(helper.build_link_for_sep_type(sep_with_date_options, family.id.to_s)).to include "class=\"existing-sep-item\""
      end

      it "should be a link to 'insured/family_members' for a QLE type without date options available" do
        expect(helper.build_link_for_sep_type(sep_without_date_options, family.id.to_s)).to include "href=\"/insured/family_members"
      end
    end

    context "#build_link_for_sep_type" do
      it "returns nil if sep nil" do
        expect(helper.build_link_for_sep_type(nil)).to be_nil
      end

      it "can find qle" do
        expect(QualifyingLifeEventKind).to receive(:find)
        helper.build_link_for_sep_type(sep_with_date_options)
      end
    end

    context "find QLE for SEP" do
      it "needs to return the right QLE for a given SEP" do
        expect(find_qle_for_sep(sep_with_date_options)).to eq qle_with_date_options_available
        expect(find_qle_for_sep(sep_without_date_options)).to eq qle_first_of_month
      end
    end
  end

  describe "#tax_info_url" do
    context "production environment" do
      it "should redirect from production environment" do
        ClimateControl.modify(AWS_ENV: 'prod') do
          expect(helper.tax_info_url).to eq EnrollRegistry[:enroll_app].setting(:prod_tax_info).item
        end
      end
    end

    context "non-production environment" do
      it "should redirect from test environment" do
        ClimateControl.modify(AWS_ENV: 'preprod') do
          expect(helper.tax_info_url).to eq EnrollRegistry[:enroll_app].setting(:staging_tax_info_url).item
        end
      end
    end
  end

  context "build consumer role" do
    let(:person) { FactoryBot.create(:person)}
    let(:family) { FactoryBot.create(:family, :with_primary_family_member)}

    before do
      allow(EnrollRegistry[:alive_status].feature).to receive(:is_enabled).and_return(true)
      helper.build_consumer_role(person,family)
    end

    it "should build consumer role for a person" do
      expect(person.consumer_role.present?).to eq true
    end

    it 'should build demographics_group and alive_status for a person' do
      demographics_group = person.demographics_group

      expect(demographics_group).to be_a DemographicsGroup
      expect(demographics_group.alive_status).to be_a AliveStatus
    end
  end

  context "build resident role " do
    let(:person) { FactoryBot.create(:person)}
    let(:family) { FactoryBot.create(:family, :with_primary_family_member)}
    let(:consumer_person) { FactoryBot.create(:person, :with_family, :with_consumer_role) }

    it "should build resident role for a person" do
      helper.build_resident_role(person,family)
      expect(person.resident_role.present?). to eq true
      expect(person.resident_role.contact_method). to eq "Paper and Electronic communications"
    end

    it "should build resident role for a person and with their consumer role contact method" do
      expect(consumer_person.consumer_role.contact_method). to eq "Paper and Electronic communications"
      consumer_person.consumer_role.update_attributes!(contact_method: "Only Electronic communications")
      helper.build_resident_role(consumer_person, consumer_person.primary_family)
      expect(consumer_person.resident_role.present?). to eq true
      expect(consumer_person.resident_role.contact_method). to eq "Only Electronic communications"
    end
  end

  describe "show_download_tax_documents_button?" do
    let(:person) { FactoryBot.create(:person)}

    before do
      helper.instance_variable_set(:@person, person)
    end

    context "as consumer" do
      let(:consumer_role) {FactoryBot.build(:consumer_role)}
      context "had a SSN" do
        before do
          allow(EnrollRegistry[:show_download_tax_documents].feature).to receive(:is_enabled).and_return(true)
          person.consumer_role = consumer_role
            person.ssn = '123456789'
        end
        it "should display the download tax documents button" do
         expect(helper.show_download_tax_documents_button?).to eq true
        end

        context "current user is hbx staff" do
          let(:current_user) { FactoryBot.build(:hbx_staff)}
          it "should display the download tax documents button" do
            expect(helper.show_download_tax_documents_button?).to eq true
          end
        end
      end

      context "had no SSN" do
        before do
          person.ssn = ''
        end

        it "should not display the download tax documents button" do
          expect(helper.show_download_tax_documents_button?).to eq false
        end
      end

    end

    context "as employee and has no consumer role", dbclean: :after_each do
      let(:person) { FactoryBot.create(:person)}
      let(:employee_role) {FactoryBot.build(:employee_role)}

      before do
        person.employee_roles = [employee_role]
      end

      context "had a SSN" do
        before do
          person.ssn = '123456789'
        end

        it "should not display the download tax documents button" do
          expect(helper.show_download_tax_documents_button?).to eq false
        end
      end
    end
  end

  describe "#display_termination_reason?" do
    let!(:person) { FactoryBot.create(:person, last_name: 'John', first_name: 'Doe') }
    let!(:family) { FactoryBot.create(:family, :with_primary_family_member, :person => person) }
    let!(:hbx_enrollment) do
      FactoryBot.create(
        :hbx_enrollment,
        created_at: (TimeKeeper.date_of_record.in_time_zone("Eastern Time (US & Canada)") - 2.days),
        family: family,
        household: family.households.first,
        coverage_kind: "health",
        kind: "individual",
        aasm_state: 'coverage_terminated',
        terminate_reason: 'non_payment'
      )
    end

    context "when termination reason config is enabled and enrollment is IVL" do
      before :each do
        allow(EnrollRegistry[:display_ivl_termination_reason].feature).to receive(:is_enabled).and_return(true)
      end

      it "should return true" do
        expect(helper.display_termination_reason?(hbx_enrollment)).to eq true
      end
    end

    context "when termination reason config is disabled and enrollment is IVL" do
      before :each do
        allow(EnrollRegistry[:display_ivl_termination_reason].feature).to receive(:is_enabled).and_return(false)
      end

      it "should return false" do
        expect(helper.display_termination_reason?(hbx_enrollment)).to eq false
      end
    end

    context "when termination reason config is enabled and enrollment is shop" do
      before :each do
        hbx_enrollment.update_attributes(kind: "shop")
        allow(EnrollRegistry[:display_ivl_termination_reason].feature).to receive(:is_enabled).and_return(false)
      end

      it "should return false" do
        expect(helper.display_termination_reason?(hbx_enrollment)).to eq false
      end
    end
  end

  describe "#Enrollment coverage", dbclean: :after_each do
    let!(:person) { FactoryBot.build_stubbed(:person)}
    let!(:family) { FactoryBot.build_stubbed(:family, :with_primary_family_member, person: person) }
    let!(:household) { FactoryBot.build_stubbed(:household, family: family) }

    context "IVL enrollment", dbclean: :after_each do

      let!(:hbx_enrollment) { FactoryBot.build_stubbed(:hbx_enrollment, household: household, aasm_state: "coverage_expired", effective_on: TimeKeeper.date_of_record) }
      let!(:hbx_profile) { FactoryBot.create(:hbx_profile)}
      let!(:benefit_coverage_periods) { HbxProfile.current_hbx.benefit_sponsorship.benefit_coverage_periods.by_date(hbx_enrollment.effective_on).first}

      it "should return benefit coverage period" do
        expect(benefit_coverage_periods.present?).to eq true
      end

      it "should return benefit coverage period end date" do
        expect(enrollment_coverage_end(hbx_enrollment)).to eq hbx_enrollment.effective_on.end_of_year
      end
    end

    context "shop enrollment", dbclean: :after_each do
      let(:site)                  { build(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
      let(:benefit_sponsor)        { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile_initial_application, site: site) }
      let(:benefit_sponsorship)    { benefit_sponsor.active_benefit_sponsorship }
      let(:employer_profile)      {  benefit_sponsorship.profile }
      let!(:benefit_package) { benefit_sponsorship.benefit_applications.first.benefit_packages.first}
      let(:census_employee)   { FactoryBot.create(:census_employee, employer_profile: employer_profile) }
      let(:benefit_group_assignment) {FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: benefit_package, census_employee: census_employee)}
      let(:start_on)          { benefit_package.start_on }
      let(:terminated_on)          { benefit_package.start_on + 1.month }
      let!(:shop_hbx_enrollment) do
        FactoryBot.build_stubbed(:hbx_enrollment, kind: "employer_sponsored", household: household, benefit_group_assignment: benefit_group_assignment, aasm_state: "coverage_expired", effective_on: TimeKeeper.date_of_record)
      end
      let!(:termed_shop_hbx_enrollment) do
        FactoryBot.build_stubbed(:hbx_enrollment, terminated_on: terminated_on, kind: "employer_sponsored", household: household, benefit_group_assignment: benefit_group_assignment,
                                                  aasm_state: "coverage_terminated", effective_on: TimeKeeper.date_of_record)
      end


      it "should return benefit applictaion end date for expired enrollment" do
        expect(enrollment_coverage_end(shop_hbx_enrollment)).to eq benefit_package.end_on
      end

      it "should return terminated date for term enrollment" do
        expect(enrollment_coverage_end(termed_shop_hbx_enrollment)).to eq terminated_on
      end
    end
  end

  describe '#render_product_type_details', dbclean: :after_each do
    it 'should return gold icon with nationwide' do
      expect(helper.render_product_type_details(:gold, true)).to eq "<span class=\"gold-icon\">Gold</span> <label class=\"separator\"></label>NATIONWIDE NETWORK"
    end

    it 'should return gold icon without nationwide' do
      expect(helper.render_product_type_details(:gold, false)).to eq "<span class=\"gold-icon\">Gold</span>"
    end
  end

  describe '#fetch_counties_by_zip', dbclean: :after_each do
    let!(:person) { FactoryBot.create(:person)}
    let!(:county) {BenefitMarkets::Locations::CountyZip.create(zip: "04642", county_name: "Hancock")}

    context 'for 9 digit zip' do
      it "should return county" do
        person.addresses.update_all(zip: "04642-3116", county: 'Hancock')
        address = person.addresses.first
        result = helper.fetch_counties_by_zip(address)
        expect(result).to eq ['Hancock']
      end
    end

    context 'for 5 digit zip' do
      it "should return county" do
        person.addresses.update_all(zip: "04642", county: 'Hancock', state: 'ME')
        address = person.addresses.first
        result = helper.fetch_counties_by_zip(address)
        expect(result).to eq ['Hancock']
      end
    end

    context 'for nil address' do
      it "should return empty array" do
        result = helper.fetch_counties_by_zip(nil)
        expect(result).to eq []
      end
    end

    context 'for nil zip' do
      it "should return empty array" do
        person.addresses.update_all(zip: nil, county: 'Hancock')
        address = person.addresses.first
        result = helper.fetch_counties_by_zip(address)
        expect(result).to eq []
      end
    end
  end

  describe '#latest_transition', dbclean: :after_each do
    let(:family) { FactoryBot.create(:family, :with_primary_family_member) }
    let(:hbx_enr) { FactoryBot.create(:hbx_enrollment, aasm_state: 'shopping', kind: 'individual', family: family) }

    context 'with state transitions including transition args' do
      let(:transition_reason) { { reason: Enrollments::TerminationReasons::SUPERSEDED_SILENT } }

      before { hbx_enr.renew_enrollment!(transition_reason) }

      it 'returns latest_transition_data' do
        expect(helper.all_transitions(hbx_enr)).to match(/From shopping to auto_renewing at/)
      end

      it 'returns transition reason' do
        expect(helper.all_transitions(hbx_enr)).to match(/Silent/)
      end
    end

    context 'with state transitions' do
      before { hbx_enr.renew_enrollment! }

      it 'returns latest_transition_data' do
        expect(helper.all_transitions(hbx_enr)).to match(/From shopping to auto_renewing at/)
      end

      it 'does not return transition reason' do
        expect(helper.all_transitions(hbx_enr)).not_to match(/Silent/)
      end
    end

    context 'created_at nil on workflowstate_transitions' do
      before { hbx_enr.renew_enrollment }

      it 'returns latest_transition_data' do
        hbx_enr.workflow_state_transitions.first.update_attributes(created_at: nil)
        expect(helper.all_transitions(hbx_enr)).to match(/From shopping to auto_renewing at/)
      end
    end

    context 'without state transitions' do
      it 'does not return latest_transition_data' do
        expect(helper.all_transitions(hbx_enr)).to eq(l10n('not_available'))
      end
    end
  end

  # Though we primarily care to test the functionality of the method and not the exact html we use the existence of
  # expected html elements as a positive indicator. If the related state_groups hash fields are updated, this test will
  # need to be updated as well.
  describe 'enrollment_state_label' do
    let(:enrollment) { instance_double(HbxEnrollment, is_shop?: false, is_reinstated_enrollment?: false) }

    shared_examples 'a label checker' do |aasm_state, terminate_reason, is_outstanding, expected_label|
      before do
        allow(EnrollRegistry[:display_ivl_termination_reason].feature).to receive(:is_enabled).and_return(true)
        allow(enrollment).to receive(:aasm_state).and_return(aasm_state)
        allow(enrollment).to receive(:terminate_reason).and_return(terminate_reason)
        allow(enrollment).to receive(:is_any_enrollment_member_outstanding).and_return(is_outstanding)
      end

      it "returns the #{expected_label} label" do
        expect(enrollment_state_label(enrollment)).to include(*expected_label)
      end
    end

    context 'when enrollment is blank' do
      before do
        allow(enrollment).to receive(:blank?).and_return(true)
      end

      it 'returns nil' do
        expect(enrollment_state_label(enrollment)).to be_nil
      end
    end

    context 'when enrollment is not blank' do

      context 'when condition is present in state group' do
        it_behaves_like 'a label checker', 'coverage_canceled', HbxEnrollment::TermReason::NON_PAYMENT, false, ['red', 'Canceled by Insurance Company']
        it_behaves_like 'a label checker', 'auto_renewing', nil, true, ['yellow', 'Action Needed']
      end

      context 'when is reinstated' do
        before do
          allow(enrollment).to receive(:is_reinstated_enrollment?).and_return(true)
        end
        # should return Coverage Reinstated only if the color is green (active)
        it_behaves_like 'a label checker', 'coverage_selected', nil, true, ['yellow', 'Action Needed']
        it_behaves_like 'a label checker', 'coverage_selected', nil, false, ['green', 'Coverage Reinstated']
      end

      context 'when condition is not present in state group' do
        it_behaves_like 'a label checker', 'auto_renewing', nil, false, ['green', 'Auto Renewing']
      end

      context 'when aasm_state is not found in state_groups' do
        it_behaves_like 'a label checker', 'unknown_state', nil, false, ['grey', 'Unknown State']
      end
    end
  end

  describe '#is_broker_authorized' do
    context 'when current user is not a ga staff' do
      let(:user) { FactoryBot.create(:user, :with_consumer_role) }
      let(:family) { FactoryBot.create(:person, :with_family) }

      it 'return false' do
        expect(helper.is_broker_authorized?(user, family)).to eq false
      end
    end

    context 'when family does not have an assigned broker' do
      let(:user) { FactoryBot.create(:user, :with_consumer_role) }
      let(:family) { FactoryBot.create(:person, :with_family).primary_family }

      it 'return false' do
        expect(helper.is_broker_authorized?(user, family)).to eq false
      end
    end

    context 'when family an assigned broker' do
      context 'when current user does not belong to family broker' do
        let(:user) { FactoryBot.create(:user, person: person) }
        let(:person) { FactoryBot.create(:person, :with_broker_role) }
        let(:family) { FactoryBot.create(:person, :with_family).primary_family }

        before do
          allow(family).to receive(:current_broker_agency).and_return double('BrokerAgencyAccount', benefit_sponsors_broker_agency_profile_id: BSON::ObjectId.new)
        end

        it 'return false' do
          expect(helper.is_broker_authorized?(user, family)).to eq false
        end
      end

      context 'when current user belongs to family broker' do
        let(:user) { FactoryBot.create(:user, person: person) }
        let(:person) do
          person = FactoryBot.create(:person, :with_broker_role)
          person.broker_role.update_attributes(benefit_sponsors_broker_agency_profile_id: BSON::ObjectId.new)
          person
        end
        let(:family) { FactoryBot.create(:person, :with_family).primary_family }

        context 'ivl role' do
          before do
            allow(family).to receive(:current_broker_agency).and_return double('BrokerAgencyAccount', benefit_sponsors_broker_agency_profile_id: person.broker_role.benefit_sponsors_broker_agency_profile_id)
          end

          it 'return true' do
            expect(helper.is_broker_authorized?(user, family)).to eq true
          end
        end

        context 'shop role' do

          before do
            allow(family).to receive(:current_broker_agency).and_return nil
            allow(helper).to receive(:shop_broker_agency_ids).with(family).and_return [person.broker_role.benefit_sponsors_broker_agency_profile_id]
          end

          it 'return true' do
            expect(helper.is_broker_authorized?(user, family)).to eq true
          end
        end
      end
    end
  end

  describe '#is_general_agency_authorized' do
    context 'when current user is not a ga staff' do
      let(:user) { FactoryBot.create(:user, :with_consumer_role) }
      let(:family) { FactoryBot.create(:person, :with_family) }

      it 'return false' do
        expect(helper.is_general_agency_authorized?(user, family)).to eq false
      end
    end

    context 'when family does not have an assigned broker' do
      let(:user) { FactoryBot.create(:user, :with_consumer_role) }
      let(:family) { FactoryBot.create(:person, :with_family).primary_family }

      before do
        allow(user).to receive_message_chain(:person, :active_general_agency_staff_roles).and_return [double('GeneralAgencyStaffRole')]
      end

      it 'return false' do
        expect(helper.is_general_agency_authorized?(user, family)).to eq false
      end
    end

    context 'when family an assigned broker & current user has ga staff role' do
      context 'when current user ga does not belong to family broker' do
        let(:user) { FactoryBot.create(:user, :with_consumer_role) }
        let(:family) { FactoryBot.create(:person, :with_family).primary_family }

        before do
          allow(user).to receive_message_chain(:person, :active_general_agency_staff_roles).and_return [double('GeneralAgencyStaffRole', benefit_sponsors_general_agency_profile_id: general_agency_profile.id)]
          allow(family).to receive(:current_broker_agency).and_return double('BrokerAgencyAccount', benefit_sponsors_broker_agency_profile_id: BSON::ObjectId.new)
          plan_design_organization_with_assigned_ga
        end

        it 'return false' do
          expect(helper.is_general_agency_authorized?(user, family)).to eq false
        end
      end

      context 'when current user ga belongs to family broker' do
        let(:user) { FactoryBot.create(:user, :with_consumer_role) }
        let(:family) { FactoryBot.create(:person, :with_family).primary_family }

        context 'ivl role' do
          before do
            allow(user).to receive_message_chain(:person, :active_general_agency_staff_roles).and_return [double('GeneralAgencyStaffRole', benefit_sponsors_general_agency_profile_id: general_agency_profile.id)]
            allow(family).to receive(:current_broker_agency).and_return double('BrokerAgencyAccount', benefit_sponsors_broker_agency_profile_id: owner_profile.id)
            plan_design_organization_with_assigned_ga
          end

          it 'return true' do
            expect(helper.is_general_agency_authorized?(user, family)).to eq true
          end
        end

        context 'shop role' do

          before do
            allow(user).to receive_message_chain(:person, :active_general_agency_staff_roles).and_return [double('GeneralAgencyStaffRole', benefit_sponsors_general_agency_profile_id: general_agency_profile.id)]
            allow(family).to receive(:current_broker_agency).and_return nil
            allow(helper).to receive(:shop_broker_agency_ids).with(family).and_return [owner_profile.id]
            plan_design_organization_with_assigned_ga
          end

          it 'return true' do
            expect(helper.is_general_agency_authorized?(user, family)).to eq true
          end
        end
      end
    end

  end
end
