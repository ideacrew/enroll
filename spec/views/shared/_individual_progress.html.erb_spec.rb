require 'rails_helper'

# !WARNING! This test file is only a starting point for testing the shared/_individual_progress.html.erb partial.
# It is in no way exhaustive and should be expanded upon to include all logic in all steps.

describe "shared/_individual_progress.html.erb" do
  context "last step" do
    before :each do
      allow(view).to receive(:policy_helper).and_return(double("FamilyPolicy", updateable?: true))
      render 'shared/individual_progress', step: '6'
    end

    it "should only have the continue button; without back_to_account_all_shop" do
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:back_to_account_all_shop).and_return(false)
      expect(rendered).to have_selector('a#btn-continue', count: 1)

      expect(rendered).not_to have_selector('a', text: l10n("previous_step"))
      expect(rendered).not_to have_selector('a', text: l10n("help_sign_up"))
      expect(rendered).not_to have_selector('a', text: l10n("save_and_exit"))
    end

    it "should only have the continue button; with back_to_account_all_shop" do
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:back_to_account_all_shop).and_return(true)
      expect(rendered).to have_selector('a#btn-continue', count: 1)

      expect(rendered).not_to have_selector('a', text: l10n("previous_step"))
      expect(rendered).not_to have_selector('a', text: l10n("help_sign_up"))
      expect(rendered).not_to have_selector('a', text: l10n("save_and_exit"))
    end
  end
end