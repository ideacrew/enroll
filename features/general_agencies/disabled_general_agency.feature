Feature: General Agency is disabled
  Background: Disable General Agency Feature
    Given the general agency feature is disabled
    Given all permissions are present

  Scenario: Main General Agency Link is Disabled
    When a non logged in user visits the Enroll home page
    Then they should not see any General Agency link

  Scenario: External Routing
    When the user types in the GA registration URL
    Then the user will not be able to access GA Registration page

  Scenario: HBX Admin portal No General Agencies link
    Given that a user with a HBX staff role with HBX staff subrole exists and is logged in
    Given user visits the Hbx Portal
    Then they should not see any General Agency link

  Scenario: Broker portal - No General Agencies Link
    Given there is a Broker Agency exists for District Brokers Inc
    And the broker Max Planck is primary broker for District Brokers Inc
    When Max Planck logs on to the Broker Agency Portal
    # Need to double check there isnt a step after this to wherer the GA link is supposed to be
    Then they should not see any General Agency link

  Scenario: Bulk Notices General Agencies recipient type
    Given the shop market configuration is enabled
    Given an HBX admin exists
    And the HBX admin is logged in
    And there is an employer ACME
    Given Admin is on the new Bulk Notice view
    Then user should not see General Agencies option for bulk notice