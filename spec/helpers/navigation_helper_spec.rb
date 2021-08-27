# frozen_string_literal: true

require 'rails_helper'

RSpec.describe NavigationHelper, :type => :helper, dbclean: :after_each do

  context 'application_year_selection page' do
    let(:action_name)     {"application_year_selection"}
    let(:controller_name) {'consumer_roles'}

    describe 'tell_us_about_yourself_active?' do
      it "should return true while on application year selection page" do
        expect(tell_us_about_yourself_active?).to eq(true)
      end
    end

    describe 'account_registration_active?' do
      it "should return false while on application year selection page" do
        expect(account_registration_active?).to eq(false)
      end
    end

    describe 'tell_us_about_yourself_current_step?' do
      it "should return true while on application year selection page" do
        expect(tell_us_about_yourself_current_step?).to eq(true)
      end
    end

    describe 'family_members_index_active?' do
      it "should return nil while on application year selection page" do
        expect(family_members_index_active?).to eq(nil)
      end
    end

    describe 'family_members_index_current_step?' do
      it "should return nil while on application year selection page" do
        expect(family_members_index_current_step?).to eq(nil)
      end
    end

  end

end
