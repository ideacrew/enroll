Feature: Hbx Admin Bulk Notice

Background: Admin has ability to create a new Bulk Notice
  Given bs4_consumer_flow feature is disable
  Given the shop market configuration is enabled
  Given an HBX admin exists
  And the HBX admin is logged in
  And there is an employer ACME
  And there is a Broker Agency exists for ACME
  And there is a General Agency exists for ACME

Scenario: Admin will create a new bulk notice for Employer
  Given Admin is on the new Bulk Notice view
  When Admin selects Employer
  And Admin fills form with Employer FEIN
  Then Admin should see Employer badge
  When Admin fills in the rest of the form
  And Admin clicks on Preview button
  Then Admin should see the Preview Screen

Scenario: Admin will create a new bulk notice for Broker Agency
  Given Admin is on the new Bulk Notice view
  When Admin selects Broker Agency
  And Admin fills form with BrokerAgency FEIN
  Then Admin should see BrokerAgency badge
  When Admin fills in the rest of the form
  And Admin clicks on Preview button
  Then Admin should see the Preview Screen

Scenario: Admin will create a new bulk notice for General Agency
  Given Admin is on the new Bulk Notice view
  When Admin selects General Agency
  And Admin fills form with GeneralAgency FEIN
  Then Admin should see GeneralAgency badge
  When Admin fills in the rest of the form
  And Admin clicks on Preview button
  Then Admin should see the Preview Screen
