# frozen_string_literal: true

# NOTE: The current tests provide a baseline coverage for the shared/_individual_progress.html.erb partial.
# As the logic in the view is complex, it's crucial to expand upon these tests to ensure comprehensive coverage.
# These tests are not exhaustive and should be considered a starting point. As features or functionalities
# are added to or modified in the view, corresponding tests should be updated or added accordingly to
# maintain a robust test suite.
require 'rails_helper'

describe "shared/_individual_progress.html.erb" do
  # Define the steps to test.
  tested_steps = %w[0 6].freeze

  let(:person_user) { FactoryBot.create(:person) }
  let(:current_user) { FactoryBot.create(:user, person: person_user) }

  before do
    sign_in current_user
    allow(view).to receive(:policy_helper).and_return(double("FamilyPolicy", updateable?: true))
    allow(EnrollRegistry).to receive(:feature_enabled?).with(:bs4_consumer_flow).and_return false
  end
  # Helper to assert the presence of the continue button.
  def assert_continue_button_present(step)
    expect(rendered).to have_selector('#btn-continue', count: 1) if step != "6"
  end

  # Helper to assert the visibility of specific links.
  def assert_links_visibility(should_be_visible, skip_links: [])
    links = %w[previous_step help_sign_up save_and_exit] - skip_links

    links.each do |link_name|
      action = should_be_visible ? :to : :not_to
      expect(rendered).send(action, have_selector('a', text: t(link_name)))
    end
  end

  # Mocks the feature enabled state, defaulting all to false.
  def mock_feature_state(feature, state)
    allow(EnrollRegistry).to receive(:feature_enabled?).and_return(false)
    allow(EnrollRegistry).to receive(:feature_enabled?).with(feature).and_return(state)
  end

  # Tests for specific steps. Extend tested_steps to test additional ones.
  tested_steps.each do |step|
    context "on step #{step}" do
      [true, false].each do |feature_state|
        context "with back_to_account_all_shop feature #{feature_state ? 'enabled' : 'disabled'}" do
          before do
            mock_feature_state(:back_to_account_all_shop, feature_state)
            render 'shared/individual_progress', step: step
          end

          it "validates button and link visibility" do
            assert_continue_button_present(step)
            #  # Help sign up is inconsistent when back_to_account_all_shop is disabled.
            skip_links = feature_state ? [] : ['help_sign_up']
            # Validate links based on the current step and feature state.
            assert_links_visibility(step == '0', skip_links: skip_links)
          end
        end
      end
    end
  end
end
