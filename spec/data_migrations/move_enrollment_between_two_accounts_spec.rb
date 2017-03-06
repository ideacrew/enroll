require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "move_enrollment_between_two_accounts")

describe MoveEnrollmentBetweenTwoAccount do

  let(:given_task_name) { "move_enrollment_between_two_accounts" }
  subject { MoveEnrollmentBetweenTwoAccount.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end


  describe "move one enrollment from one person to another person", dbclean: :after_each do
    include_context "BradyWorkAfterAll"
    subject { MoveEnrollmentBetweenTwoAccount.new(given_task_name, double(:current_scope => nil)) }
    before do
      allow(ENV).to receive(:[]).with('old_account_hbx_id').and_return person2.hbx_id
      allow(ENV).to receive(:[]).with('new_account_hbx_id').and_return person1.hbx_id
    end
    context "move an ivl hbx_enrollment" do
      let!(:person1) { FactoryGirl.create(:person, :with_consumer_role,hbx_id: "0000") }
      let!(:family1) { FactoryGirl.create(:family, :with_primary_family_member, person: person1)}
      let!(:person2) { FactoryGirl.create(:person, :with_consumer_role,hbx_id: "1111") }
      let!(:family2) { FactoryGirl.create(:family, :with_primary_family_member, person: person2)}
      let!(:hbx_profile) { FactoryGirl.create(:hbx_profile, :open_enrollment_coverage_period) }

      let!(:hbx_enrollment) {FactoryGirl.create(:hbx_enrollment, :individual_assisted,  household: family2.active_household, consumer_role_id: person2.consumer_role.id)}
      let!(:hbx_enrollment_member) {FactoryGirl.create(:hbx_enrollment_member,applicant_id:person2.id, eligibility_date:Date.new(),hbx_enrollment: hbx_enrollment)
      }
      before do

        family1.add_family_member(person2)
        family1.relate_new_member(person2, "child")
        person2.save
        family2.save

      end
      it "should be movable" do
        expect(person2.primary_family.active_household.hbx_enrollments).to include(hbx_enrollment)
        expect(person1.primary_family.active_household.hbx_enrollments).not_to include(hbx_enrollment)
        subject.migrate
        family1.reload
        family2.reload
        expect(person1.primary_family.active_household.hbx_enrollments).not_to include(hbx_enrollment)
        expect(person2.primary_family.active_household.hbx_enrollments).to include(hbx_enrollment)
      end
    end



  end


  describe "move one enrollment from one person to another person", dbclean: :after_each do
    include_context "BradyWorkAfterAll"
    before :all do
      create_brady_census_families
    end

    subject { MoveEnrollmentBetweenTwoAccount.new(given_task_name, double(:current_scope => nil)) }
    before do
      #allow(ENV).to receive(:[]).with('old_account_hbx_id').and_return @household1.family.person.hbx_id
      #allow(ENV).to receive(:[]).with('new_account_hbx_id').and_return @household2.family.person.hbx_id
      create_brady_families

    end
    context "move an ivl hbx_enrollment" do
      
      let(:consumer_role){FactoryGirl.create :consumer_role, person: mike}
      let!(:hbx_profile) { FactoryGirl.create(:hbx_profile, :open_enrollment_coverage_period) }
      before :each do
        
        
        @household1 =mikes_family.households.first
        @household2 =carols_family.households.first
        allow(ENV).to receive(:[]).with('old_account_hbx_id').and_return @household1.family.person.hbx_id
        allow(ENV).to receive(:[]).with('new_account_hbx_id').and_return @household2.family.person.hbx_id
        @coverage_household1=@household1.coverage_households.first
        @coverage_household2=@household2.coverage_households.first
        allow(@coverage_household1).to receive(:family).and_return mikes_family
        allow(@coverage_household2).to receive(:family).and_return carols_family
        @consumer_role=FactoryGirl.create :consumer_role, person: mike
        @enrollment1 = @household1.create_hbx_enrollment_from(
                           consumer_role: @consumer_role,
                           coverage_household: @coverage_household1
                                                            )
        @enrollment1.save!
        @enrollment2 = @household1.create_hbx_enrollment_from(
                           consumer_role: @consumer_role,
                           coverage_household: @coverage_household1
                                                            )
        @enrollment2.save!
      end

      it "should be movable" do
        
        expect(@household1.hbx_enrollments).to include(@enrollment1)
        expect(@household1.hbx_enrollments).to include(@enrollment2)
        expect(@household2.hbx_enrollments).not_to include(@enrollment1)
        expect(@household2.hbx_enrollments).not_to include(@enrollment2)
        
        subject.migrate
        household1.reload
        household2.reload
        expect(@household1.hbx_enrollments).not_to include(@enrollment1)
        expect(@household1.hbx_enrollments).not_to include(@enrollment2)
        expect(@household2.hbx_enrollments).to include(@enrollment1)
        expect(@household2.hbx_enrollments).to include(@enrollment2)
      end
    end
  end
  end
