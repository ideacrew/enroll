# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::Notices::IvlAccountTransferNotice, dbclean: :after_each do

  it 'should be a container-ready operation' do
    expect(subject.respond_to?(:call)).to be_truthy
  end

  describe 'ivl account transfer notice' do
    let(:person) { create(:person, :with_consumer_role, is_incarcerated: nil)} #operation handles nil incarceration statuses
    let(:family) { create(:family, :with_primary_family_member, person: person)}

    context 'with invalid params' do
      let(:params) {{}}

      it 'should return failure' do
        result = subject.call(params)
        expect(result.failure?).to be_truthy
        expect(result.failure).to eq 'Missing family'
      end
    end

    context 'with valid params' do
      before :each do
        allow_any_instance_of(Events::Individual::Notices::AccountTransferred).to receive(:publish).and_return true
      end

      let(:params) {{ family: family }}

      it 'should return success' do
        result = subject.call(params)
        expect(result.success?).to be_truthy
      end
    end
  end
end
