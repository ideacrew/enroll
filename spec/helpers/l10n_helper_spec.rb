# frozen_string_literal: true

require "rails_helper"

RSpec.describe L10nHelper, :type => :helper do
  describe "#l10n" do
    it "Should titelize nonexistent translations" do
      expect(helper.l10n("test_translation_key")).to eq "Test Translation Key"
    end
  end
end