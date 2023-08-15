# frozen_string_literal: true

# NOTE: The current tests provide a baseline coverage for the shared/_sep_progress.html.erb partial.
# As the logic in the view evolves, it's crucial to expand upon these tests to ensure comprehensive coverage.
# These tests are not exhaustive and should be considered a starting point. As features or functionalities
# are added to or modified in the view, corresponding tests should be updated or added accordingly to
# maintain a robust test suite.
require 'rails_helper'

describe "shared/_sep_progress.html.erb" do
  let(:person_user) { FactoryBot.create(:person) }
  let(:current_user) { FactoryBot.create(:user, person: person_user) }

  before do
    sign_in current_user
  end

  def validate_continue_button
    expect(rendered).to have_selector('#btn-continue', count: 1)
  end

  def validate_link_visibility(should_be_visible)
    %w[previous_step help_sign_up save_and_exit].each do |link_name|
      action = should_be_visible ? :to : :not_to
      expect(rendered).send(action, have_selector('a', text: l10n(link_name)))
    end
  end

  # Currently testing for steps 0 and 7, where 7 is the last step. You can add more steps
  # to the array if you want to test for more steps and update the test accordingly (e.g. the validate_link_visibility parameter)
  %w[0 7].each do |step|
    context "on step #{step}" do
      before { render 'shared/sep_progress', step: step }

      [true, false].each do |feature_state|
        context "with back_to_account_all_shop feature #{feature_state ? 'enabled' : 'disabled'}" do
          before { allow(EnrollRegistry).to receive(:feature_enabled?).with(:back_to_account_all_shop).and_return(feature_state) }

          it "validates button and link visibility" do
            validate_continue_button
            validate_link_visibility(step == '0')
          end
        end
      end
    end
  end
end