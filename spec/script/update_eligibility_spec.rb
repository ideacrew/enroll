# frozen_string_literal: true

require "rails_helper"

describe "UpdateEligibility", :dbclean => :after_each do
  let(:hbx_profile) {FactoryBot.create(:hbx_profile)}

  it "should invoke without errors" do
    expect { system 'script/update_eligibility.rb' }.to_not raise_error
  end
end
