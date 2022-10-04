# frozen_string_literal: true

require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"
require "#{Rails.root}/spec/models/shared_contexts/census_employee.rb"

RSpec.describe Subscribers::BenefitSponsors::BenefitApplicationSubscriber,
               type: :model,
               dbclean: :after_each do

  include_context 'setup benefit market with market catalogs and product packages'
  include_context 'setup initial benefit application'
  include_context "census employee base data"

  let(:current_effective_date) { TimeKeeper.date_of_record.beginning_of_year }
  let(:effective_period)          { current_effective_date..(current_effective_date.next_year.prev_day) }
  let(:aasm_state) { :enrollment_open }

  let(:sponsor_osse_params) do
    {
      subject_gid: benefit_sponsorship.to_global_id,
      evidence_key: :osse_subsidy,
      evidence_value: "true",
      effective_date: current_effective_date
    }
  end

  let(:create_sponsor_eligibility) do
    entity = ::Operations::Eligibilities::Osse::BuildEligibility.new.call(sponsor_osse_params)

    if entity.success?
      eligibility = benefit_sponsorship.eligibilities.build(entity.success.to_h)
      eligibility.save!
    end
  end

  let(:payload) do
    {
      application_global_id: initial_application.to_global_id.to_s
    }.to_json
  end

  let(:delivery_info) do
    OpenStruct.new({
                     routing_key: 'enroll.benefit_sponsors.benefit_application.open_enrollment_began'
                   })
  end

  let(:params) {valid_params}
  let(:hired_on) { current_effective_date - 2.months }
  let(:initial_census_employee) {CensusEmployee.create(**params)}
  let(:valid_employee_role) {FactoryBot.build(:benefit_sponsors_employee_role, ssn: initial_census_employee.ssn, dob: initial_census_employee.dob, employer_profile: employer_profile)}
  let!(:user) {FactoryBot.create(:user, person: valid_employee_role.person)}

  let(:subscribe_operation) do
    connection_manager = EventSource::ConnectionManager.instance
    connection_manager.find_subscribe_operation({
                                                  protocol: :amqp,
                                                  subscribe_operation_name: "on_enroll.enroll.benefit_sponsors.benefit_application"
                                                })
  end

  let(:queue_proxy) { subscribe_operation.subject }
  let(:channel) { queue_proxy.channel_proxy.subject }

  before do
    create_sponsor_eligibility
    initial_census_employee.employee_role = valid_employee_role
  end

  context 'with payload' do

    context 'on success' do
      before do
        allow_any_instance_of(::BenefitSponsors::BenefitApplications::BenefitApplication).to receive(:shop_osse_eligibility_is_enabled?).and_return(true)
      end

      it 'should receive ack' do
        expect(channel).to receive(:ack)
        queue_proxy.on_receive_message(
          described_class,
          delivery_info,
          {},
          payload
        )
      end

      it 'should create eligibility for employee' do
        valid_employee_role.reload
        expect(valid_employee_role.eligibilities).to be_blank

        queue_proxy.on_receive_message(
          described_class,
          delivery_info,
          {},
          payload
        )

        valid_employee_role.reload
        expect(valid_employee_role.eligibilities).to be_present
      end
    end
  end

  context 'invalid payload' do
    context 'on failure' do
      it 'should receive ack' do
        pending("ack failing with an error message: cannot use a closed channel!")
        expect_any_instance_of(described_class).to receive(:create_employee_osse_eligibilies).with(initial_application).and_raise("eligibility create failed!!")
        expect(channel).to receive(:ack)
        queue_proxy.on_receive_message(
          described_class,
          delivery_info,
          {},
          payload
        )
      end

      it 'should not create eligibility for employee' do
        valid_employee_role.reload
        expect(valid_employee_role.eligibilities).to be_blank
        expect_any_instance_of(described_class).to receive(:create_employee_osse_eligibilies).with(initial_application).and_raise("eligibility create failed!!")

        queue_proxy.on_receive_message(
          described_class,
          delivery_info,
          {},
          payload
        )

        valid_employee_role.reload
        expect(valid_employee_role.eligibilities).to be_blank
      end
    end
  end
end
