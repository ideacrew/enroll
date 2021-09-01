Feature: Create General Agency and General Agency Staff Role
  
  Scenario: A General Agency Submits Application
    Given the shop market configuration is enabled
    Given the general agency feature is enabled
    Given a CCA site exists with a benefit market
    Given a general agency agent visits the DCHBX
    When they click the 'New General Agency' button
    Then they should see the new general agency form
    When they complete the new general agency form and hit the 'Submit' button
    Then they should see a confirmation message
    And a pending approval status
   
  Scenario: A General Agency is Approved
    Given a CCA site exists with a benefit market
    Given the general agency feature is enabled

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
    Given a CCA site exists with a benefit market
    Given the general agency feature is enabled
    Given a general agency, approved, awaiting account creation, exists
    When the HBX admin visits the link received in the approval email
    Then they should see an account creation form
    When they complete the account creation form and hit the 'Submit' button
    Then they should see a welcome message
    And they see the General Agency homepage
   
  
  Scenario: Broker assigns general agency to an employer
    Given a CCA site exists with a benefit market
    Given there is a General Agency exists for ABC Inc
    And the broker Max Planck is primary broker for District Brokers Inc
    And there is an employer Netflix
    And employer Netflix hired broker Max Planck from District Brokers Inc
    When Max Planck logs on to the Broker Agency Portal
    And Primary Broker clicks on the Employers tab
    And Primary broker clicks Actions dropdown and clicks Assign General Agency
    And Primary broker selects ABC Inc from dropdown
    Then Primary Broker should see assign successful message
    