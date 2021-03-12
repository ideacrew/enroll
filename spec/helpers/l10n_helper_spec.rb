<<<<<<< HEAD
# frozen_string_literal: true

require "rails_helper"

=======
require "rails_helper"
>>>>>>> 893f50570ecee2769f63ebfb5ac0d364616f2139
RSpec.describe L10nHelper, :type => :helper do
  describe "#l10n" do
    it "Should titelize nonexistent translations" do
      expect(helper.l10n("test_translation_key")).to eq "Test Translation Key"
    end
  end
end