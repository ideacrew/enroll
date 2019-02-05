require "rails_helper"

describe Queries::IvlEnrollmentsQuery, "IVL enrollments query", dbclean: :after_each do

  describe "given consumers under open enrollment" do

    let(:effective_on) { TimeKeeper.date_of_record.end_of_month.next_day }
    let(:plan) { FactoryGirl.create(:plan) }

    let(:start_time) { Time.now - 17.minutes }
    let(:end_time) { Time.now }

    subject{ Queries::IvlEnrollmentsQuery.new(start_time, end_time) }

    describe "and made the following plan selections:
       - consumer A has purchased:
         - new health coverage (state: coverage selected)
       - consumer B has purchased:
         - active renewal (state: renewing_coverage_selected)
       - consumer C has:
         - passive renewal (state: auto_renewing)
       - consumer D has:
         - passive renewal outside time boundary(state: auto_renewing)
    " do

      let(:consumer_A) {
        FactoryGirl.create(:person, :with_active_consumer_role, :with_consumer_role)
      }

      let(:family_A) {
        FactoryGirl.create(:family, :with_primary_family_member, :person => consumer_A)
      }

      let!(:enrollment_1){ 
         create_enrollment(family: family_A, consumer_role: consumer_A.consumer_role, plan: plan, status: 'coverage_selected', submitted_at: Time.now - 5.minutes, enrollment_kind: 'open_enrollment', effective_date: effective_on, coverage_kind: 'health')
      }

      let(:consumer_B) {
        FactoryGirl.create(:person, :with_active_consumer_role, :with_consumer_role)
      }

      let(:family_B) {
        FactoryGirl.create(:family, :with_primary_family_member, :person => consumer_B)
      }   

      let!(:enrollment_2) {
        create_enrollment(family: family_B, consumer_role: consumer_B.consumer_role, plan: plan, status: 'renewing_coverage_selected', submitted_at: Time.now - 5.minutes, enrollment_kind: 'open_enrollment', effective_date: effective_on, coverage_kind: 'health')
      }

      let(:consumer_C) {
        FactoryGirl.create(:person, :with_active_consumer_role, :with_consumer_role)
      }

      let(:family_C) {
        FactoryGirl.create(:family, :with_primary_family_member, :person => consumer_C)
      }   

      let!(:enrollment_3) {
        create_enrollment(family: family_C, consumer_role: consumer_C.consumer_role, plan: plan, status: 'auto_renewing', submitted_at: Time.now - 5.minutes, enrollment_kind: 'open_enrollment', effective_date: effective_on, coverage_kind: 'health')
      }

      let(:consumer_D) {
        FactoryGirl.create(:person, :with_active_consumer_role, :with_consumer_role)
      }

      let(:family_D) {
        FactoryGirl.create(:family, :with_primary_family_member, :person => consumer_D)
      }   

      let!(:enrollment_4) {
        create_enrollment(family: family_D, consumer_role: consumer_D.consumer_role, plan: plan, status: 'auto_renewing', submitted_at: Time.now - 30.minutes, enrollment_kind: 'open_enrollment', effective_date: effective_on, coverage_kind: 'health')
      }

      it "includes enrollment 1" do
        purchase_ids = subject.purchases.map{|rec| rec["_id"]}
        expect(purchase_ids).to include(enrollment_1.hbx_id)

        term_ids = subject.terminations.map{|rec| rec["_id"]}
        expect(term_ids).not_to include(enrollment_1.hbx_id)
      end

      it "includes enrollment 2" do
        purchase_ids = subject.purchases.map{|rec| rec["_id"]}
        expect(purchase_ids).to include(enrollment_2.hbx_id)

        term_ids = subject.terminations.map{|rec| rec["_id"]}
        expect(term_ids).not_to include(enrollment_2.hbx_id)
      end

      it "includes enrollment 3" do
        purchase_ids = subject.purchases.map{|rec| rec["_id"]}
        expect(purchase_ids).to include(enrollment_3.hbx_id)

        term_ids = subject.terminations.map{|rec| rec["_id"]}
        expect(term_ids).not_to include(enrollment_3.hbx_id)
      end

      it "does not include enrollment 4" do
        purchase_ids = subject.purchases.map{|rec| rec["_id"]}
        expect(purchase_ids).not_to include(enrollment_4.hbx_id)

        term_ids = subject.terminations.map{|rec| rec["_id"]}
        expect(term_ids).not_to include(enrollment_4.hbx_id)
      end
    end

    describe "and made following term/cancel of their coverage:
       - consumer A has:
         - canceled their coverage (state: coverage canceled)
       - consumer B has:
         - termed thier coverage (state: coverage_terminated)
    " do

      let(:consumer_A) {
        FactoryGirl.create(:person, :with_active_consumer_role, :with_consumer_role)
      }

      let(:family_A) {
        FactoryGirl.create(:family, :with_primary_family_member, :person => consumer_A)
      }

      let!(:enrollment_1){ 
         create_enrollment(family: family_A, consumer_role: consumer_A.consumer_role, plan: plan, status: 'coverage_canceled', submitted_at: Time.now - 5.minutes, enrollment_kind: 'open_enrollment', effective_date: effective_on, coverage_kind: 'health')
      }

      let(:consumer_B) {
        FactoryGirl.create(:person, :with_active_consumer_role, :with_consumer_role)
      }

      let(:family_B) {
        FactoryGirl.create(:family, :with_primary_family_member, :person => consumer_B)
      }   

      let!(:enrollment_2) {
        create_enrollment(family: family_B, consumer_role: consumer_B.consumer_role, plan: plan, status: 'coverage_terminated', submitted_at: Time.now - 5.minutes, enrollment_kind: 'open_enrollment', effective_date: TimeKeeper.date_of_record.beginning_of_month, coverage_kind: 'health')
      }

      it "includes enrollment 1" do
        term_ids = subject.terminations.map{|rec| rec["_id"]}
        expect(term_ids).to include(enrollment_1.hbx_id)

        purchase_ids = subject.purchases.map{|rec| rec["_id"]}
        expect(purchase_ids).not_to include(enrollment_1.hbx_id)
      end

      it "includes enrollment 2" do
        term_ids = subject.terminations.map{|rec| rec["_id"]}
        expect(term_ids).to include(enrollment_2.hbx_id)

        purchase_ids = subject.purchases.map{|rec| rec["_id"]}
        expect(purchase_ids).not_to include(enrollment_2.hbx_id)
      end
    end
  end

  def create_enrollment(family: nil, consumer_role: nil, plan: nil, status: 'coverage_selected', submitted_at: nil, enrollment_kind: 'open_enrollment', effective_date: nil, coverage_kind: 'health')
    enrollment = FactoryGirl.create(:hbx_enrollment,:with_enrollment_members,
      enrollment_members: [family.primary_applicant],
      household: family.active_household,
      coverage_kind: coverage_kind,
      effective_on: effective_date,
      enrollment_kind: enrollment_kind,
      kind: "individual",
      submitted_at: submitted_at,
      consumer_role_id: consumer_role.id,
      plan_id: plan.id,
      aasm_state: status
    )

    enrollment.workflow_state_transitions.create(from_state: 'shopping', to_state: status, transition_at: submitted_at)
    enrollment
  end
end
