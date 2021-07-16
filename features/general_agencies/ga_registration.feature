Feature: Create a General Agency Profile

  Background: Enabling proper configuration
    Given the shop market configuration is enabled
    Given a CCA site exists with a benefit market
    Given EnrollRegistry hbx_admin_config feature is enabled
    Given EnrollRegistry general_agency feature is enabled

  Scenario: A General Agency Submits Application
    Given a general agency agent visits the DCHBX
    When they click the 'New General Agency' button
    Then they should see the new general agency form
    When they complete the new general agency form and hit the 'Submit' button
    Then they should see a confirmation message
    And a pending approval status

  Scenario: A General Agency is Approved
    When that a user with a HBX staff role with HBX Staff subrole exists and is logged in
    And a general agency, pending approval, exists
    And Hbx Admin is on Broker Index of the Admin Dashboard
    And Hbx Admin is on Broker Index and clicks General Agencies
    Then they should see the pending general agency
    When they click the link of general agency
    Then they should see the home of general agency
    When they visit the list of staff
    Then they should see the name of staff
    When they approve the general agency
    Then they should see updated status
    And the general agency should receive an email

  Scenario: A General Agency Creates an Account
    Given a general agency, approved, awaiting account creation, exists
    When the HBX admin visits the link received in the approval email
    Then they should see an account creation form
    When they complete the account creation form and hit the 'Submit' button
    Then they should see a welcome message
    And they see the General Agency homepage
