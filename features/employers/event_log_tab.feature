Feature: Employer should be able to view event logs

  Background: Setup site, employer
    Given the shop market configuration is enabled
    Given all announcements are enabled for user to select
    Given a DC site exists with a benefit market
    Given benefit market catalog exists for enrollment_open initial employer with health benefits
    And an employer ABC Widgets exists with statements and premium payments
    And ABC Widgets employer has a staff role
    And staff role person logged in
    And Audit Log Feature is enabled

  Scenario: Verify initial state of the page
    When ABC Widgets is logged in and on the home page
    And staff role person clicked on audit-log tab
    Then the "export-table" button should be disabled
    And the "Filters" section should be hidden

#  Scenario: Verify the behavior of filters
#    Given I visit the page
#    When I click on the "Filters" toggle
#    Then the "Filters" section should be visible
#    And the "Run Query" button should be visible
#    And the "Export Table" button should be disabled
#
#  Scenario: Verify date filtering
#    Given I visit the page
#    When I select a start date
#    Then the end date input should be enabled with a minimum date set
#
#  Scenario: Verify run query button behavior
#    Given I visit the page
#    When I click on the "Run Query" button
#    Then the "Run Query" and "Export Table" buttons should be disabled during the Ajax call
#    And after the Ajax call is complete, the buttons should be re-enabled
#
#  Scenario: Verify export table button behavior
#    Given I visit the page
#    When I click on the "Export Table" button
#    Then a window should be redirected to '/event_logs.csv'
#
#  Scenario: Verify initial Ajax request behavior
#    Given I visit the page
#    Then the "Export Table" button should be disabled
#    And the "Filters" section should be hidden
#    When the initial Ajax request is complete
#    Then the "Export Table" button should be enabled
#    And the "Filters" section should be visible
#
#  Scenario: An Employer should be able to view event logs
#    When ABC Widgets is logged in and on the home page
#    And staff role person clicked on audit-log tab
#    Then the employer should see export table button
#    When the employer clicks on statements
#    Then the employer should see statements histroy
#    When the employer clicks on pay my bill
#    Then the employer should see billing information
