require 'rails_helper'

RSpec.describe ShopEmployeeNotices::EmployeeMatchesEmployerRoosterNotice, :dbclean => :after_each do
  let(:start_on) { TimeKeeper.date_of_record.beginning_of_month + 1.month - 1.year}
  let!(:employer_profile){ create :employer_profile, aasm_state: "active"}
  let!(:person){ create :person}
  let!(:plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, start_on: start_on, :aasm_state => 'draft' ) }
  let!(:active_benefit_group) { FactoryGirl.create(:benefit_group, plan_year: plan_year, title: "Benefits #{plan_year.start_on.year}") }
  let(:employee_role) {FactoryGirl.create(:employee_role, person: person, employer_profile: employer_profile)}
  let(:census_employee) { FactoryGirl.create(:census_employee, employee_role_id: employee_role.id, employer_profile_id: employer_profile.id) }
  let(:application_event){ double("ApplicationEventKind",{
                            :name =>'Employee must be notified when they successfully match to their employer',
                            :notice_template => 'notices/shop_employee_notices/employee_matches_employer_rooster_notification',
                            :notice_builder => 'ShopEmployeeNotices::EmployeeMatchesEmployerRoosterNotice',
                            :event_name => 'employee_matches_employer_rooster',
                            :mpi_indicator => 'SHOP_M050',
                            :title => "Eligible to Apply for Employer-sponsored Health Insurance"})
                          }

    let(:valid_parmas) {{
        :subject => application_event.title,
        :mpi_indicator => application_event.mpi_indicator,
        :event_name => application_event.event_name,
        :template => application_event.notice_template
    }}

  describe "New" do
    before do
      @employee_notice = ShopEmployeeNotices::EmployeeMatchesEmployerRoosterNotice.new(census_employee, valid_parmas)
      allow(employer_profile).to receive_message_chain("staff_roles.first").and_return(person)
    end
    context "valid params" do
      it "should initialze" do
        expect{ShopEmployeeNotices::EmployeeMatchesEmployerRoosterNotice.new(census_employee, valid_parmas)}.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator,:subject,:template].each do  |key|
        it "should NOT initialze with out #{key}" do
          valid_parmas.delete(key)
          expect{ShopEmployeeNotices::EmployeeMatchesEmployerRoosterNotice.new(census_employee, valid_parmas)}.to raise_error(RuntimeError,"Required params #{key} not present")
        end
      end
    end
  end

  describe "Build" do
    before do
      @employee_notice = ShopEmployeeNotices::EmployeeMatchesEmployerRoosterNotice.new(census_employee, valid_parmas)
      allow(census_employee).to receive("employer_profile").and_return(employer_profile)
    end
    it "should build notice with all necessary information" do
      @employee_notice.build
      expect(@employee_notice.notice.employer_name).to eq employer_profile.organization.legal_name
    end
  end

  describe "append_data" do
    before do
      @employee_notice = ShopEmployeeNotices::EmployeeMatchesEmployerRoosterNotice.new(census_employee, valid_parmas)
      allow(census_employee).to receive("employer_profile").and_return(employer_profile)
      allow(employer_profile).to receive_message_chain("staff_roles.first").and_return(person)
    end
    it "should append necessary information" do
      @employee_notice.append_data
      expect(@employee_notice.notice.employer_full_name).to eq person.full_name.titleize
    end
  end

end