Feature: Create Primary Broker and Broker Agency
  In order for Brokers to help SHOP employees only
  The Primary Broker must create and manage an account on the HBX for their organization.
  Such organizations are referred to as a Broker Agency
  The Primary Broker should be able to create a Broker Agency account application
  The HBX Admin should be able to approve the application and send an email invite
  The Primary Broker should receive the invite and create an Account
  The Employer should be able to select the Primary Broker as their Broker
  The Broker should be able to manage that Employer
  The Broker should be able to select a family covered by that Employer
  The Broker should be able to purchase insurance for that family

  # TODO: Keep this commented out for DC. This is a Massachusetts feature:
  # https://github.com/health-connector/enroll/blob/68cb76ed84baeb0a3afaa0fadf2d74c9667b567c/config/settings.yml#L156
  #Scenario: Broker can enter ACH information
  #  Given the shop market configuration is enabled
  #  Given a CCA site exists with a benefit market
  #  Given benefit market catalog exists for enrollment_open initial employer with health benefits
  #  And there is an employer ABC Widgets
  #  Given a valid ach record exists
  #  Given Primary Broker has not signed up as an HBX user
  #  When a Primary Broker visits the HBX Broker Registration form
  #  When Primary Broker enters personal information
  #  And Primary Broker enters broker agency information for SHOP markets
  #  And Primary Broker enters office location for default_office_location
  #  Then Primary Broker should see broker registration successful message


  Scenario: Broker purchase insurance for a family
    Given the shop market configuration is enabled
    Given choose_shopping_method feature is disabled
    And a CCA site exists with a benefit market
    And benefit market catalog exists for active initial employer with health benefits
    And there is a Broker Agency exists for District Brokers Inc
    And the broker Max Planck is primary broker for District Brokers Inc
    And there is an employer Acme Inc.
    And employer Acme Inc. hired broker Max Planck from District Brokers Inc
    And initial employer Acme Inc. has active benefit application
    And there is a census employee record and employee role for Patrick Doe for employer Acme Inc.
    And employer Acme Inc. is listed under the account for broker District Brokers Inc
    When Max Planck logs on to the Broker Agency Portal
    And Primary Broker clicks on the Families tab
    And Primary Broker should see Patrick Doe as family and click on name
    And Primary Broker clicks on shop for plans
    And Primary Broker selects a plan on the plan shopping page
    And Primary Broker clicks on confirm Confirm button on the coverage summary page
    And Primary Broker sees Enrollment Submitted and clicks Continue
    Then Primary Broker should see Coverage Selected
