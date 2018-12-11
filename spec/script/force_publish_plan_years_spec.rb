require 'rails_helper'
require File.join(Rails.root, "script", "force_publish_plan_years.rb")


describe ForcePublishPlanYears, dbclean: :after_each do

  before :each do
    TimeKeeper.set_date_of_record_unprotected!(current_date)
  end

  after :each do 
    FileUtils.rm_rf(Dir["#{unassigned_file}"]) if File.exists?(unassigned_file)
    FileUtils.rm_rf(Dir["#{not_enrolling_file}"]) if File.exists?(not_enrolling_file)
  end
  
  let(:current_date)      { Date.new(2018,10,9) }
  let(:publish_date)      { Date.new(2018,12,1) }
  let!(:renewing_draft_employer_profile) { renewing_draft_plan_year.employer_profile }
  let!(:renewing_draft_employer_profile_2) { renewing_draft_plan_year_2.employer_profile }
  let!(:census_employee_1)   { FactoryGirl.create(:census_employee, employer_profile: renewing_draft_employer_profile) }
  let!(:census_employee_2)   { FactoryGirl.create(:census_employee, employer_profile: renewing_draft_employer_profile) }
  let!(:bg) { Organization.all[1].employer_profile.plan_years.last.benefit_groups.first}
  let!(:not_enrolling_file) {"#{Rails.root}/employers_not_in_renewing_enrolling_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.csv"}
  let!(:unassigned_file) {"#{Rails.root}/unnassigned_packages_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.csv"}

  let(:renewing_draft_plan_years)  {Organization.where({
                                      :'employer_profile.plan_years' =>{ :$elemMatch => {
                                        :start_on => publish_date,
                                        :aasm_state => 'renewing_draft'
                                        }}
                                       })
                                    } 

  let(:renewing_enrolling_plan_years)  { Organization.where({
                                          :'employer_profile.plan_years' =>{ :$elemMatch => {
                                            :start_on => publish_date,
                                            :aasm_state => 'renewing_enrolling'
                                            }}
                                          })
                                        } 

          

  let!(:renewing_draft_plan_year)        do
    py = FactoryGirl.create(:renewing_draft_plan_year)
    bg = FactoryGirl.create(:benefit_group, plan_year: py)
    PlanYear.find(py.id)
  end
  
  let!(:renewing_published_plan_year)        do
    py = FactoryGirl.create(:renewing_published_plan_year)
    bg = FactoryGirl.create(:benefit_group, plan_year: py)
    PlanYear.find(py.id)
  end

  let!(:renewing_draft_plan_year_2)        do
    py = FactoryGirl.create(:renewing_draft_plan_year, open_enrollment_start_on: (current_date + 1.day))
    bg = FactoryGirl.create(:benefit_group, plan_year: py)
    PlanYear.find(py.id)
  end
  
  subject {ForcePublishPlanYears.new(publish_date, current_date)}
  
  describe "force publish process" do
    
    it 'reverts plan years from renewing published to renewing draft' do 
      expect(renewing_published_plan_year.aasm_state).to eq("renewing_published")

      subject.revert_plan_years
      renewing_published_plan_year.reload

      expect(renewing_published_plan_year.aasm_state).to eq("renewing_draft")
      expect(renewing_published_plan_year.open_enrollment_start_on).to eq(current_date)
    end
      
    it 'assigns benefit packages to CEs that are not assigned' do 
      census_employee_1.benefit_group_assignments.first.delete
      expect(census_employee_1.benefit_group_assignments).to be_empty

      subject.assign_packages
      census_employee_1.reload

      expect(File).to exist(unassigned_file)
      expect(census_employee_1.benefit_group_assignments).not_to be_empty
    end

    it 'sets back the OE date for renewing draft employers with a OE date greater than current date' do
      expect(renewing_draft_employer_profile_2.plan_years.first.open_enrollment_start_on).to eq(current_date + 1.day)
      
      subject.set_back_oe_date
      renewing_draft_employer_profile_2.reload
      
      expect(renewing_draft_employer_profile_2.plan_years.first.open_enrollment_start_on).to eq(current_date)
    end
    
    it 'force publishes plan years from renewing draft to renwing enrolling' do 
      expect(renewing_draft_plan_years.count).to eq 2

      subject.force_publish
      renewing_draft_plan_year.reload
      renewing_draft_plan_year_2.reload

      expect(renewing_draft_plan_years.count).to eq 0
      expect(renewing_enrolling_plan_years.count).to eq 1
    end

    it 'logs plan years not in renewing enrolling to a csv not_enrolling_file' do
      subject.clean_up

      expect(File).to exist(not_enrolling_file)
      expect(File.read(not_enrolling_file)).to include('renewing_draft')
      expect(File.read(not_enrolling_file)).not_to include('renewing_enrolling')
      expect(File.read(not_enrolling_file)).to include(renewing_published_plan_year.employer_profile.organization.fein)
      expect(File.read(not_enrolling_file)).to include(renewing_draft_plan_year.employer_profile.organization.fein)
    end

    it 'calls all processes in the force publish class' do 
      census_employee_1.benefit_group_assignments.first.delete
      expect(census_employee_1.benefit_group_assignments).to be_empty
      expect(renewing_published_plan_year.aasm_state).to eq("renewing_published")
      expect(renewing_draft_employer_profile_2.plan_years.first.open_enrollment_start_on).to eq(current_date + 1.day)
      expect(renewing_draft_plan_years.count).to eq 2


      subject.call
      renewing_draft_employer_profile_2.reload
      renewing_draft_plan_year.reload
      renewing_draft_plan_year_2.reload
      renewing_published_plan_year.reload
      census_employee_1.reload
      
      expect(renewing_draft_employer_profile_2.plan_years.first.open_enrollment_start_on).to eq(current_date)
      expect(census_employee_1.benefit_group_assignments.first.class).to eq BenefitGroupAssignment
      expect(renewing_draft_plan_years.count).to eq 0
      expect(renewing_enrolling_plan_years.count).to eq 3
    end
  end
end
