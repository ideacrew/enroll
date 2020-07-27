Feature: Create Benefit Application by admin UI

  Background: Setup site, employer, and benefit application
    Given a CCA site exists with a benefit market
    Given benefit market catalog exists for draft initial employer with health benefits
    And there is an employer ABC Widgets
    And ABC Widgets employer has a staff role

    Scenario Outline: Existing Draft Application
      Given initial employer ABC Widgets has <aasm_state> benefit application with terminated on <event>
      And that a user with a HBX staff role with Super Admin subrole exists and is logged in
      And the user is on the Employer Index of the Admin Dashboard
      And the user clicks Action for that Employer
      And the user has clicked the Create Plan Year button
      And the user has a valid input for all required fields
      When the admin clicks SUBMIT
      Then the user will see a <message> message
      And staff role person logged in
      And ABC Widgets goes to the benefits tab I should see plan year information
      And the draft application will <action>
      And the existing applications for ABC Widgets will be <title>

    # draft_py_date_gt_term_on: 'draft benefit application' effective on is greater than 'termination pending benefit application' terminated on
    # draft_py_date_lt_term_on: 'draft benefit application' effective on is less than 'termination pending benefit application' terminated on
      Examples:
        | aasm_state          | title               |         event             | message                                             | action          |
        | draft               | Canceled            | draft_py_effective_on     | Successfully created a draft plan year              |  be created     |


    Scenario Outline: Existing <title> Application for confirm  button
      Given initial employer ABC Widgets has <aasm_state> benefit application
      And that a user with a HBX staff role with Super Admin subrole exists and is logged in
      And the user is on the Employer Index of the Admin Dashboard
      And the user clicks Action for that Employer
      And the user has clicked the Create Plan Year button
      And the user has a valid input for all required fields
      When the admin clicks SUBMIT
      Then the user will see a <message> message
      And staff role person logged in
      And ABC Widgets goes to the benefits tab I should see plan year information
      And the existing applications for ABC Widgets will be <after_submit_title>

      Examples:
        | title                 | aasm_state            | after_submit_title                | message |
        | Publish Pending       | pending               | Publish Pending                   | Existing plan year with overlapping coverage exists |
        | Enrolling             | enrollment_open       | Enrolling                         | Existing plan year with overlapping coverage exists |
        | Enrollment Closed     | enrollment_closed     | Enrollment Closed                 | Existing plan year with overlapping coverage exists |
        | Enrolled              | binder_paid           | Enrolled                          | Existing plan year with overlapping coverage exists |
        | Enrollment Ineligible | enrollment_ineligible | Enrollment Ineligible             | Existing plan year with overlapping coverage exists |
        | Active                | active                | Active                            | Existing plan year with overlapping coverage exists |

  Scenario: Creating New Plan Year while application is in termination_pending aasm_state
    And initial employer ABC Widgets has active benefit application
    Given that a user with a HBX staff role with HBX staff subrole exists and is logged in
    And the user is on the Employer Index of the Admin Dashboard
    When the user clicks Action for that Employer
    And the user clicks the Plan Years button
    Then the user will select benefit application to terminate
    When the user clicks Actions for current benefit application
    When the user clicks Actions for that benefit application
    Then the user will see Terminate button
    When the user enters last_day and other details for voluntary termination
    When user clicks submit button
    Then user should see termination successful message
    And user logs out
    And staff role person logged in
    And update rating area
    When ABC Widgets is logged in and on the home page
    And staff role person clicked on benefits tab
    And staff role person clicked on benefits tab
    Then employer should see benefit application in termination pending state
    And employer should see Add Plan Year link
    Then employer should see add plan year button
    And employer clicks Add Plan Year link
    And employer clicks OK in warning modal
    #Then employer should see continue button disabled
    And employer filled all the fields on benefit application form
    And employer clicked on continue button
    Then employer should see form for benefit package
    And employer filled all the fields on benefit package form
    And employer selected by metal level plan offerings
    Then employer should see gold metal level type
    And employer clicked on gold metal level
    Then employer should see create plan year button disabled
    And employer selected 100 contribution percent for the application
    Then employer should see your estimated montly cost
    And employer should see that the create plan year is true


  Scenario: Census Employee Roster will show off cycle benefit packages and employee can shop with off cycle benefit package
    Given Qualifying life events are present
    And initial employer ABC Widgets has active benefit application
    And there is a census employee record and employee role for Patrick Doe for employer ABC Widgets
    And employees for employer ABC Widgets have selected a coverage
    Given that a user with a HBX staff role with HBX staff subrole exists and is logged in
    And the user is on the Employer Index of the Admin Dashboard
    When the user clicks Action for that Employer
    And the user clicks the Plan Years button
    Then the user will select benefit application to terminate
    When the user clicks Actions for current benefit application
    When the user clicks Actions for that benefit application
    Then the user will see Terminate button
    When the user enters last_day and other details for voluntary termination
    When user clicks submit button
    Then user should see termination successful message
    And user logs out
    And staff role person logged in
    And update rating area
    When ABC Widgets is logged in and on the home page
    And staff role person clicked on benefits tab
    And staff role person clicked on benefits tab
    Then employer should see benefit application in termination pending state
    And employer should see Add Plan Year link
    Then employer should see add plan year button
    And employer clicks Add Plan Year link
    And employer clicks OK in warning modal
    #Then employer should see continue button disabled
    And employer filled all the fields on benefit application form
    And employer clicked on continue button
    Then employer should see form for benefit package
    And employer filled all the fields on benefit package form
    And employer selected by metal level plan offerings
    Then employer should see gold metal level type
    And employer clicked on gold metal level
    Then employer should see create plan year button disabled
    And employer selected 100 contribution percent for the application
    Then employer should see your estimated montly cost
    And employer should see that the create plan year is true
    And employer clicks Create Plan Year
    And staff role person clicked on employees tab
    And staff role person clicks on employees link
    And staff role person clicks on employee Patrick Doe
    Then the user should see a dropdown for Off Plan Year benefit package
    And census employee Patrick Doe has benefit group assignment of the off cycle benefit application
    # And employee Patrick Doe already matched with employer ABC Widgets and logged into employee portal
    # When Employee click the "Had a baby" in qle carousel
    # And Employee select a past qle date
    # Then Employee should see confirmation and clicks continue
    # Then Employee should see family members page and clicks continue
    # Then Employee should see the group selection page
    # When Employee clicks continue on the group selection page
    # Then Employee should see the list of plans
    # And Patrick Doe should see the plans from the expired plan year
    # When Employee selects a plan on the plan shopping page
    # Then Patrick Doe should see coverage summary page with qle effective date
    # Then Patrick Doe should see the receipt page with qle effective date as effective date
    # Then Patrick Doe should see "my account" page with enrollment