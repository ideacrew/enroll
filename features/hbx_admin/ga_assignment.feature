Feature: Admin Assigns a General Agency to an Employer

  Background:
    Given a general agency, approved, confirmed, exists
    And a broker exists
    And a Hbx admin with read and write permissions exists

  Scenario: When the general agency is enabled through settings, then the Admin should see the 'Assign' link under the broker profile
    When the general agency is enabled through settings
    And Hbx Admin logs on to the Hbx Portal
    And Hbx Admin clicks on the Broker Agencies tab
    And Hbx Admin clicks on the broker
    Then he should be able to see the Assign link under his profile

  Scenario: When the general agency is disabled through settings, then the Broker should not see the 'Assign' link under his profile
    When the general agency is disabled through settings
    And Hbx Admin logs on to the Hbx Portal
    And Hbx Admin clicks on the Broker Agencies tab
    And Hbx Admin clicks on the broker
    Then he should not be able to see the Assign link under his profile