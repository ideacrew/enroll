require "rails_helper"

describe Subscribers::PolicyTerminationsSubscriber do
  let(:existing_enrollment) { instance_double(HbxEnrollment, :hbx_id => 1, terminated_on: nil, effective_on: Date.new(2017, 1, 1)) }
  let(:enrollment_id) { "urn:some:id#123456" }
  let(:termination_event_name) { "acapi.info.events.policy.terminated" }
  let(:cancelation_event_name) { "acapi.info.events.policy.canceled" }

  before :each do
    allow(HbxEnrollment).to receive(:by_hbx_id).with("123456").and_return([existing_enrollment])
  end

  describe "given a termination event" do
    let(:termination_date) { Date.new(2017, 5, 30) }

    let(:termination_payload) do
      {
        :resource_instance_uri => "urn:some_thing:policy#policy_id",
        :event_effective_date => termination_date.strftime("%Y%m%d"),
        :hbx_enrollment_ids => JSON.dump([enrollment_id])
      }
    end

    before :each do
      allow(existing_enrollment).to receive(:may_terminate_for_non_payment?).and_return(true)
      allow(existing_enrollment).to receive(:may_terminate_coverage?).and_return(true)
    end

    it "terminates the enrollment" do
      expect(existing_enrollment).to receive(:terminate_coverage!).with(termination_date)
      subject.call(termination_event_name, nil, nil, nil, termination_payload)
    end
  end

  describe "given a termination event with termination date before the start date" do
    let(:existing_enrollment) { instance_double(HbxEnrollment, :hbx_id => 1, effective_on: Date.new(2017, 1, 1)) }
    let!(:termination_date) { Date.new(2016, 12, 31) }

    let(:termination_payload) do
      {
        :resource_instance_uri => "urn:some_thing:policy#policy_id",
        :event_effective_date => termination_date.strftime("%Y%m%d"),
        :hbx_enrollment_ids => JSON.dump([enrollment_id])
      }
    end

    before :each do
      allow(existing_enrollment).to receive(:may_cancel_coverage?).and_return(true)
      allow(existing_enrollment).to receive(:may_cancel_for_non_payment?).and_return(true)
      allow(existing_enrollment).to receive(:may_terminate_coverage?).and_return(true)
      allow(existing_enrollment).to receive(:may_terminate_for_non_payment?).and_return(true)
    end

    it "cancel the enrollment" do
      expect(existing_enrollment).to receive(:cancel_coverage!)
      subject.call(termination_event_name, nil, nil, nil, termination_payload)
    end
  end

  describe "given a termination event with qualify reason non_payment" do
    let(:termination_date) { Date.new(2017, 5, 30) }

    let(:termination_payload) do
      {
        :resource_instance_uri => "urn:some_thing:policy#policy_id",
        :event_effective_date => termination_date.strftime("%Y%m%d"),
        :hbx_enrollment_ids => JSON.dump([enrollment_id]),
        :qualifying_reason => "non_payment"
      }
    end

    before :each do
      allow(existing_enrollment).to receive(:may_terminate_coverage?).and_return(true)
      allow(existing_enrollment).to receive(:may_terminate_for_non_payment?).and_return(true)
    end

    it "terminates the enrollment" do
      expect(existing_enrollment).to receive(:terminate_for_non_payment!).with(termination_date)
      subject.call(termination_event_name, nil, nil, nil, termination_payload)
    end
  end

  describe "given a cancel event" do
    let(:termination_payload) do
      {
        :resource_instance_uri => "urn:some_thing:policy#policy_id",
        :hbx_enrollment_ids => JSON.dump([enrollment_id])
      }
    end

    before :each do
      allow(existing_enrollment).to receive(:coverage_canceled?).and_return(false)
      allow(existing_enrollment).to receive(:may_cancel_coverage?).and_return(true)
      allow(existing_enrollment).to receive(:may_cancel_for_non_payment?).and_return(true)
    end

    it "cancels the enrollment" do
      expect(existing_enrollment).to receive(:cancel_coverage!)
      subject.call(cancelation_event_name, nil, nil, nil, termination_payload)
    end
  end

  describe "given a cancel event with qualify reason non_payment" do
    let(:termination_payload) do
      {
        :resource_instance_uri => "urn:some_thing:policy#policy_id",
        :hbx_enrollment_ids => JSON.dump([enrollment_id]),
        :qualifying_reason => "non_payment"
      }
    end

    before :each do
      allow(existing_enrollment).to receive(:coverage_canceled?).and_return(false)
      allow(existing_enrollment).to receive(:may_cancel_coverage?).and_return(true)
      allow(existing_enrollment).to receive(:may_cancel_for_non_payment?).and_return(true)
    end

    it "cancels the enrollment" do
      expect(existing_enrollment).to receive(:cancel_for_non_payment!)
      subject.call(cancelation_event_name, nil, nil, nil, termination_payload)
    end
  end

  describe "given termination_pending enrollment with termination date" do

    let(:existing_enrollment) { instance_double(HbxEnrollment, :hbx_id => 1, effective_on: Date.new(2017, 1, 1), terminated_on: Date.new(2017, 6, 30), aasm_state: 'coverage_termination_pending') }

    let(:termination_payload) do
      {
        :resource_instance_uri => "urn:some_thing:policy#policy_id",
        :event_effective_date => termination_date.strftime("%Y%m%d"),
        :hbx_enrollment_ids => JSON.dump([enrollment_id]),
        :qualifying_reason => "non_payment"
      }
    end

    before :each do
      allow(existing_enrollment).to receive(:may_terminate_coverage?).and_return(true)
      allow(existing_enrollment).to receive(:may_terminate_for_non_payment?).and_return(true)
      allow(existing_enrollment).to receive(:update_attributes).and_return(true)
    end

    context "given termination date less than termination date on enrollment" do

      let(:termination_date) { Date.new(2017, 5, 30) }

      it "should terminates the enrollment" do
        expect(existing_enrollment).to receive(:terminate_for_non_payment!).with(termination_date)
        subject.call(termination_event_name, nil, nil, nil, termination_payload)
      end
    end


    context "given termination date greater than termination date on enrollment" do

      let(:termination_date) { Date.new(2017, 7, 30) }

      it "should terminates the enrollment" do
        expect(existing_enrollment).not_to receive(:terminate_for_non_payment!).with(termination_date)
        subject.call(termination_event_name, nil, nil, nil, termination_payload)
      end
    end
  end

  describe "given termimated enrollment with termination date" do

    let(:existing_enrollment) { instance_double(HbxEnrollment, :hbx_id => 1, effective_on: Date.new(2017, 1, 1), terminated_on: Date.new(2017, 6, 30), aasm_state: 'coverage_terminated') }

    let(:termination_payload) do
      {
        :resource_instance_uri => "urn:some_thing:policy#policy_id",
        :event_effective_date => termination_date.strftime("%Y%m%d"),
        :hbx_enrollment_ids => JSON.dump([enrollment_id])
      }
    end

    before :each do
      allow(existing_enrollment).to receive(:may_terminate_coverage?).and_return(true)
      allow(existing_enrollment).to receive(:may_terminate_for_non_payment?).and_return(true)
      allow(existing_enrollment).to receive(:update_attributes).and_return(true)
    end

    context "given termination date less than termination date on enrollment" do

      let(:termination_date) { Date.new(2017, 5, 30) }

      it "should terminates the enrollment" do
        expect(existing_enrollment).to receive(:terminate_coverage!).with(termination_date)
        subject.call(termination_event_name, nil, nil, nil, termination_payload)
      end
    end


    context "given termination date greater than termination date on enrollment" do

      let(:termination_date) { Date.new(2017, 7, 30) }

      it "should terminates the enrollment" do
        expect(existing_enrollment).not_to receive(:terminate_coverage!).with(termination_date)
        subject.call(termination_event_name, nil, nil, nil, termination_payload)
      end
    end
  end
end

describe "given cancel event to cancel terminated coverage" do
  let(:termination_date) { Date.new(2022, 1, 1) }
  let(:cancelation_event_name) { "acapi.info.events.policy.canceled" }
  let(:cancelation_payload) do
    {
      :resource_instance_uri => "urn:some_thing:policy#policy_id",
      :hbx_enrollment_ids => JSON.dump(["1234"]),
      :qualifying_reason => "non_payment",
      :event_effective_date => termination_date.strftime("%Y%m%d"),
    }
  end
  let(:family) {FactoryBot.create(:family, :with_primary_family_member)}
  let!(:hbx_enrollment) {FactoryBot.create(:hbx_enrollment, effective_on: Date.new(2022,1,1),
                                          hbx_id: '1234', household: family.active_household,
                                          terminated_on: Date.new(2022,1,31),
                                          aasm_state: "coverage_terminated", family: family)}

  it "should cancel terminated enrollment" do
    Subscribers::PolicyTerminationsSubscriber.new.call(cancelation_event_name, nil, nil, nil, cancelation_payload)
    hbx_enrollment.reload
    expect(hbx_enrollment.terminated_on).to eq nil
    expect(hbx_enrollment.coverage_canceled?).to eq true
  end
end

describe "given term event to cancel terminated coverage" do
  let(:termination_date) { Date.new(2022, 1, 1) }
  let(:term_event_name) { "acapi.info.events.policy.terminated" }
  let(:term_payload) do
    {
      :resource_instance_uri => "urn:some_thing:policy#policy_id",
      :hbx_enrollment_ids => JSON.dump(["4321"]),
      :qualifying_reason => "non_payment",
      :event_effective_date => termination_date.strftime("%Y%m%d"),
    }
  end
  let(:family) {FactoryBot.create(:family, :with_primary_family_member)}
  let!(:hbx_enrollment) {FactoryBot.create(:hbx_enrollment, effective_on: Date.new(2022,2,1),
                                           hbx_id: '4321', household: family.active_household,
                                           terminated_on: Date.new(2022,2,28),
                                           aasm_state: "coverage_terminated", family: family)}

  it "should cancel terminated enrollment" do
    Subscribers::PolicyTerminationsSubscriber.new.call(term_event_name, nil, nil, nil, term_payload)
    hbx_enrollment.reload
    expect(hbx_enrollment.terminated_on).to eq nil
    expect(hbx_enrollment.coverage_canceled?).to eq true
  end
end
