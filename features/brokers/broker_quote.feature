Feature: Broker creates a quote for a prospect employer
  In order for Brokers to create a quote to Employers
  The Broker should be able to add Employer and Employees
  And Generate a quote

  Background: Broker Quoting Tool
   Given a CCA site exists with a benefit market
   And there is a Broker Agency exists for District Brokers Inc
   And the broker Max Planck is primary broker for District Brokers Inc 

  Scenario: Broker should be able to create an Employer
    Given Max Planck logs on to the Broker Agency Portal
    When Primary Broker clicks on the Employers tab
    And Primary Broker clicks on the Add Prospect Employer button
    And Primary Broker creates new Prospect Employer with default_office_location