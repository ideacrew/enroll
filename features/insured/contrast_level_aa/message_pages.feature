  
Feature: Customers go to Messages to view inbox and deleted messages

  Background: Set up features
    Given bs4_consumer_flow feature is disable
    Given the contrast level aa feature is enabled
    Given EnrollRegistry medicaid_tax_credits_link feature is enabled
    And EnrollRegistry contact_email_header_footer_feature feature is enabled
    Given a consumer exists
    And consumer has successful ridp
    And the consumer is logged in

  Scenario: Consumer navigates to the Inbox
    When the user visits messages page
    Then the page passes minimum level aa contrast guidelines

  Scenario: Consumer navigates to the Inbox
    When the user visits messages page
    And the user clicks the deleted messages button
    Then the page passes minimum level aa contrast guidelines
