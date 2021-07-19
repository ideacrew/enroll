# frozen_string_literal: true

require "rails_helper"

# Enroll Translations load by default before RSpec
RSpec.describe L10nHelper, :type => :helper do
  # All translations are configured to load before every rspec
  it "should translate existing translations" do
    expect(helper.l10n('date_label')).to eq("Date")
  end

  it "should handle non existent translations gracefully" do
    expect(helper.l10n('Pizza')).to eq("Pizza")
  end

  it "should handle non string translation keys gracefully" do
    expect(helper.l10n({:formats => {:default => "%m/%d/%Y"}})).to eq("Formatsdefaultmd Y")
  end

  it "should handle non string results gracefully" do
    allow(helper).to receive(:t).with({:formats => {:default => "%m/%d/%Y"}}, default: "Formatsdefaultmd Y").and_return(
      {:formats => {:default => "%m/%d/%Y"}}
    )
    expect(helper.l10n({:formats => {:default => "%m/%d/%Y"}})).to eq("{:formats=>{:default=>\"%m/%d/%Y\"}}")
  end

  context "interpolated keys" do
    context "existing translations" do
      it "should handle key with string passed" do
        expect(
          l10n('devise.login_history.admin.history_for_user', email: "fakeemail@gmail.com")
        ).to eq("Login history for fakeemail@gmail.com")
      end
    end
    context "non exiting translations" do
      it "should handle everything passed" do
        expect(l10n('fake_translation', fake_key: "Fake")).to eq("Fake Translation")
      end
    end
  end
end
