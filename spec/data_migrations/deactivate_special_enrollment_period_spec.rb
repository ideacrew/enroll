require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "deactivate_special_enrollment_period")
describe DeactivateSpecialEnrollmentPeriod, dbclean: :after_each do

    let(:given_task_name) { "deactivate_special_enrollment_period" }
    subject { DeactivateSpecialEnrollmentPeriod.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
  	it "has the given task name" do
  	  expect(subject.name).to eql given_task_name
  	end
  end

  describe "disable sepcial enrollment period ", dbClean: :before_each do
    let!(:person)  { FactoryGirl.create(:person, :with_employee_role) }
    let!(:primary_applicant) { double }
    let!(:family)  { FactoryGirl.create(:family, :with_primary_family_member, person: person) }
    let(:special_enrollment_period) {FactoryGirl.build(:special_enrollment_period,family:family,qualifying_life_event_kind_id: qualifying_life_event_kind.id, market_kind: "shop")}
    let!(:add_special_enrollment_period) {family.special_enrollment_periods = [special_enrollment_period]
                                          family.save
    }
    let!(:qualifying_life_event_kind)  { FactoryGirl.create(:qualifying_life_event_kind, market_kind: "shop") }

    context 'update sep market kind to shop', dbclean: :after_each  do
      
      before(:each) do
        allow(ENV).to receive(:[]).with('person_hbx_id').and_return person.hbx_id
        allow(ENV).to receive(:[]).with('sep_id').and_return special_enrollment_period.id
      end
      it "should update market kind" do
        expect(special_enrollment_period.is_active?).to eq true
        subject.migrate
        family.reload
        special_enrollment_period.reload
        expect(special_enrollment_period.is_active?).to eq false
      end
    end
  end
end
