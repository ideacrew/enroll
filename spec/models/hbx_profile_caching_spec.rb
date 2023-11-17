# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HbxProfile, "retrieved via .current_hbx, with some messages" do
  let(:hbx_profile) do
    FactoryBot.create(:hbx_profile,
                      :normal_ivl_open_enrollment,
                      us_state_abbreviation: EnrollRegistry[:enroll_app].setting(:state_abbreviation).item,
                      cms_id: "#{EnrollRegistry[:enroll_app].setting(:state_abbreviation).item.upcase}0")
  end

  before :each do
    org = Organization.where("hbx_profile._id" => hbx_profile.id).first
    profile = org.hbx_profile
    profile.inbox.messages << Message.new(
      {
        body: "A MESSAGE BODY"
      }
    )
    profile.inbox.save!
  end

  it "can access those messages" do
    expect(HbxProfile.current_hbx.inbox.messages.count).to eq(1)
  end
end