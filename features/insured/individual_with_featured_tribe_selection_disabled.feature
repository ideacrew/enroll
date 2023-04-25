# frozen_string_literal: true

Feature: For the enabled AI/AN feature, existing consumer edits the personal info page
  Background:
    When site is for ME
    Given AI AN Details feature is enabled
    Given Featured Tribe Selection feature is disabled
    Given Individual has not signed up as an HBX user
    Given the FAA feature configuration is enabled
    Given a consumer exists
    And the consumer is logged in
    And consumer is an indian_tribe_member
    And consumer has successful ridp
    And consumer visits home page

  Scenario: For the previously selected tribal state without tribal name, the consumer should see the empty tribal name text box
    Given individual clicks on the Manage Family button
    Then individual clicks on the Personal portal
    And the consumer should see tribal name textbox without text