require 'rails_helper'

RSpec.describe 'ModelEvents::GenerateInitialEmployerInvoice', dbclean: :after_each do

  let(:notice_event) { "generate_initial_employer_invoice" }
  let(:start_on) { TimeKeeper.date_of_record.next_month.beginning_of_month}
  let(:organization) { FactoryGirl.create(:organization) }
  let!(:employer_profile) { FactoryGirl.create(:employer_profile, organization: organization) }
  let(:plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, start_on: start_on, aasm_state: 'enrolled') }
  let(:person){ FactoryGirl.create(:person, :with_family)}
  let(:family) { person.primary_family}
  let!(:census_employee) { FactoryGirl.create(:census_employee, employer_profile: employer_profile, employee_role_id: employee_role.id) }
  let!(:employee_role) { FactoryGirl.create(:employee_role, employer_profile: employer_profile, person: person) }
  let(:benefit_group) {FactoryGirl.create(:benefit_group, plan_year: plan_year)}
  let(:benefit_group_assignment)    { FactoryGirl.create(:benefit_group_assignment, census_employee: census_employee, start_on: start_on, benefit_group_id: benefit_group.id, hbx_enrollment_id: hbx_enrollment.id ) }
  let!(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment, :with_enrollment_members,
    household: family.active_household,
    employee_role_id: employee_role.id, 
    benefit_group_id: benefit_group.id,
    effective_on: start_on
  )}

  describe "NoticeTrigger" do
    context "when initial invoice is generated" do
      subject { Services::NoticeService.new }

      it "should trigger notice event" do
        expect(subject).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employer.generate_initial_employer_invoice"
          expect(payload[:employer_id]).to eq employer_profile.hbx_id.to_s
          expect(payload[:event_object_kind]).to eq 'PlanYear'
          expect(payload[:event_object_id]).to eq plan_year.id.to_s
        end
        subject.deliver(recipient: employer_profile, event_object: plan_year, notice_event: notice_event)
      end
    end
  end

  describe "NoticeBuilder" do

    let(:data_elements) {
      [
        "employer_profile.notice_date",
        "employer_profile.account_number",
        "employer_profile.invoice_number",
        "employer_profile.invoice_date",
        "employer_profile.coverage_month",
        "employer_profile.date_due",
        "employer_profile.total_amount_due"
      ]
    }
    let(:merge_model) { subject.construct_notice_object }
    let(:recipient) { "Notifier::MergeDataModels::EmployerProfile" }
    let(:template)  { Notifier::Template.new(data_elements: data_elements) }

    context "when notice event received" do

      let(:payload) do
        {
          "event_object_kind" => "PlanYear",
          "event_object_id" => plan_year.id
        }
      end
      subject { Notifier::NoticeKind.new(template: template, recipient: recipient) }

      before do
        allow(subject).to receive(:resource).and_return(employer_profile)
        allow(subject).to receive(:payload).and_return(payload)
      end

      it "should retrun merge model" do
        expect(merge_model).to be_a(recipient.constantize)
      end

      it "should retrun account number" do
        expect(merge_model.account_number).to eq (employer_profile.organization.hbx_id)
      end

      it "should retrun invoice number" do
        expect(merge_model.invoice_number).to eq (employer_profile.organization.hbx_id+DateTime.now.next_month.strftime('%m%Y'))
      end

      it "should retrun invoice date" do
        expect(merge_model.invoice_date).to eq (TimeKeeper.date_of_record.strftime("%m/%d/%Y"))
      end

      it "should retrun coverage month" do
        expect(merge_model.coverage_month).to eq (TimeKeeper.date_of_record.next_month.strftime("%m/%Y"))
      end

      it "should retrun due date" do
        due_date = PlanYear.calculate_open_enrollment_date(plan_year.start_on)[:binder_payment_due_date]
        expect(merge_model.date_due).to eq due_date.strftime("%m/%d/%Y")
      end

      it "should return total amount due" do
        currency = ActionView::Base.new
        expect(merge_model.total_amount_due).to eq currency.number_to_currency(hbx_enrollment.total_premium)
      end
    end

    context "if invoice is generated for initial employer with active plan year" do
      let(:start_on) { TimeKeeper.date_of_record.beginning_of_month}
      let(:plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, start_on: start_on, aasm_state: 'active') }
      let(:subject) { Notifier::NoticeKind.new(template: template, recipient: recipient) }
      let(:payload) do
        {
          "event_object_kind" => "PlanYear",
          "event_object_id" => plan_year.id
        }
      end

      before do
        allow(subject).to receive(:resource).and_return(employer_profile)
        allow(subject).to receive(:payload).and_return(payload)
      end

      it "should return total amount due" do
        currency = ActionView::Base.new
        expect(merge_model.total_amount_due).to eq currency.number_to_currency(hbx_enrollment.total_premium)
      end
    end
  end
end
