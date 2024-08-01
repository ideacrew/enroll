# frozen_string_literal: true

require 'rails_helper'

describe 'shared/_consumer_home_address_fields.html.erb' do
  let(:view) { ActionController::Base.new.view_context }
  let(:person) do
    double(
      'Person',
      same_with_primary: false,
      is_homeless: true,
      is_moving_to_state: true,
      is_temporarily_out_of_state: true,
      addresses: address
    )
  end
  let(:address) { FactoryBot.build(:address, kind: 'home') }

  before :each do
    allow(view).to receive(:policy_helper).and_return(double("PersonPolicy", updateable?: true))
    allow(person).to receive(:no_dc_address).and_return(false)
    # allow(address).to receive(:object).and_return(address)
    @mock_form = ActionView::Helpers::FormBuilder.new(:person, person, view, {})
  end

  context 'when features are enabled' do
    before do
      allow(EnrollRegistry[:moving_to_state].feature).to receive(:is_enabled).and_return(true)
      allow(EnrollRegistry[:living_outside_state].feature).to receive(:is_enabled).and_return(true)

      render 'shared/consumer_home_address_fields', f: @mock_form, no_dc_address: true
    end

    it 'should have is_moving_to_state checkbox' do
      expect(rendered).to include('is_moving_to_state')
    end

    it 'should have is_temporarily_out_of_state checkbox' do
      expect(rendered).to include('is_temporarily_out_of_state')
    end
  end

  context 'when features are disabled' do
    before do
      allow(EnrollRegistry[:moving_to_state].feature).to receive(:is_enabled).and_return(false)
      allow(EnrollRegistry[:living_outside_state].feature).to receive(:is_enabled).and_return(false)

      render 'shared/consumer_home_address_fields', f: @mock_form, no_dc_address: true
    end

    it 'should not have is_moving_to_state checkbox' do
      expect(rendered).not_to include('is_moving_to_state')
    end

    it 'should not have is_temporarily_out_of_state checkbox' do
      expect(rendered).not_to include('person_is_temporarily_out_of_state')
    end
  end
end
