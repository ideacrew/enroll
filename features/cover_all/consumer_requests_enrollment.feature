
Feature: Consumer requests enrollment in CoverAll
  As a person who is aware in advance that he is not qualified for QHP through the
  exchange, and has not initialized an application through EA, he can request to
  be enrolled in CoverAll. The HBX admin can then enter their information and
  process their application through the families index page.

  Background: Enables features
    Given bs4_consumer_flow feature is disable
    Given EnrollRegistry no_transition_families feature is enabled
    Given individual Qualifying life events are present

  Scenario: When we login as Hbx admin with read and write permissions then on family tab we should see link DC Resident Application
    Given a Hbx admin with super admin access exists
    When Hbx Admin logs on to the Hbx Portal
    And Hbx Admin click Families dropdown
    Then Hbx Admin should see an DC Resident Application link
    When Hbx Admin clicks on DC Resident Application link
    Then Hbx Admin should see DC Resident Personal Information page
    When Hbx Admin goes to register a user as individual
    And Hbx Admin clicks on continue button
    Then Hbx Admin should see a form to enter personal information
    When Hbx Admin clicks on continue button
    And Hbx Admin clicks "Married" in qle carousel
    And Hbx Admin select a past qle date
    Then Hbx Admin should see confirmation and clicks continue
    When Hbx Admin clicks on continue button on Choose Coverage page
    Then Hbx Admin should see the list of plans
    And Hbx admin should see the Metal Level filter
    When Hbx Admin selects a plan from shopping plan page
    Then Hbx Admin should see the summary page of plan selection
    When Hbx Admin clicks on Confirm button on the summary page of plan selection
    Then Hbx Admin should see the enrollment receipt page
    When Hbx Admin clicks on Continue button on receipt page
    Then Hbx Admin should see the home page with text coverage selected

  Scenario: When we login as Hbx admin with only read permissions then on family tab we should not see link New DC Resident Application
    Given a Hbx admin with read only permissions exists
    When Hbx Admin logs on to the Hbx Portal
    When Hbx Admin click Families dropdown
    Then Hbx Admin should see a DC Resident Application link disabled
  
  Scenario: When we login as Hbx admin with read and write permissions then on family tab we should not see link New DC Resident Application
    Given a Hbx admin with super admin access exists
    When Hbx Admin logs on to the Hbx Portal
    When Hbx Admin click Families dropdown
    Then Hbx Admin should not see an New DC Resident Application link

  Scenario: When we login as Hbx admin then on family tab admin should not see link New Consumer Phone Application and New Consumer Paper Application
    Given a Hbx admin with read and write permissions exists
    When Hbx Admin logs on to the Hbx Portal
    When Hbx Admin click Families dropdown
    Then Hbx Admin should not see an New Consumer Phone Application link and New Consumer Paper Application link
