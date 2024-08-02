# frozen_string_literal: true

require 'rails_helper'

describe 'shared/_address_fields_for_dependent.html.erb' do
  let(:view) { ActionController::Base.new.view_context }
  let(:person) do
    double(
      'Person',
      same_with_primary: false,
      is_homeless: true,
      is_moving_to_state: true,
      is_temporarily_out_of_state: true
    )
  end
  let(:address) { FactoryBot.build(:address, kind: 'home') }

  before :each do
    allow(person).to receive(:addresses).and_return([address])
    @mock_form = ActionView::Helpers::FormBuilder.new(:person, person, view, {})
  end

  context 'when features are enabled' do
    before do
      allow(EnrollRegistry[:moving_to_state].feature).to receive(:is_enabled).and_return(true)
      allow(EnrollRegistry[:living_outside_state].feature).to receive(:is_enabled).and_return(true)

      render 'shared/address_fields_for_dependent', f: @mock_form, show_no_dc_address: true
    end

    it 'should have is_moving_to_state checkbox' do
      expect(rendered).to have_selector('input#is_moving_to_state')
    end

    it 'should have is_temporarily_out_of_state checkbox' do
      expect(rendered).to have_selector('input#is_temporarily_out_of_state')
    end
  end

  context 'when features are disabled' do
    before do
      allow(EnrollRegistry[:moving_to_state].feature).to receive(:is_enabled).and_return(false)
      allow(EnrollRegistry[:living_outside_state].feature).to receive(:is_enabled).and_return(false)

      render 'shared/address_fields_for_dependent', f: @mock_form, show_no_dc_address: true
    end

    it 'should not have is_moving_to_state checkbox' do
      expect(rendered).not_to have_selector('input#is_moving_to_state')
    end

    it 'should not have is_temporarily_out_of_state checkbox' do
      expect(rendered).not_to have_selector('input#person_is_temporarily_out_of_state')
    end
  end
end
