Feature: Broker Manages Employee Account
  In order to help Employees with plan shopping, brokers can access their employers employees accounts
  The Broker should be able to do plan shopping for employees

  Background: Broker registration
    Given EnrollRegistry disable_family_link_in_broker_agency feature is disabled
    And EnrollRegistry crm_update_family_save feature is disabled
    And EnrollRegistry crm_publish_primary_subscriber feature is disabled
    And the shop market configuration is enabled
    And a CCA site exists with a benefit market
    And benefit market catalog exists for draft initial employer with health benefits
    And there is a Broker Agency exists for District Brokers Inc
    And the broker Max Planck is primary broker for District Brokers Inc
    And there is an employer ABC Widgets
    And ABC Widgets employer has a staff role
    And employer ABC Widgets hired broker Max Planck from District Brokers Inc
    And initial employer ABC Widgets has enrollment_open benefit application
    And there is a census employee record and employee role for Patrick Doe for employer ABC Widgets
    And employer ABC Widgets is listed under the account for broker District Brokers Inc

  Scenario: Broker manages employer account
    When Max Planck logs on to the Broker Agency Portal
    And Primary Broker clicks on the Families tab
    Then Primary Broker should see Patrick Doe as family and click on name
    Then Primary Broker should see Patrick Doe account
