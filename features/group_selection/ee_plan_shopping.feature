Feature: EE plan purchase

  Background: Setup site, employer, and benefit application
    Given a CCA site exists with a benefit market
    Given Qualifying life events are present
    And there is an employer Acme Inc.
    And Acme Inc. employer has a staff role

  Scenario: when EE purchase plan for self
    When staff role person logged in
    And this employer has enrollment_open benefit application with offering health and dental
    And Acme Inc. employer visit the Employee Roster
    Then Employer logs out
    And Employee has not signed up as an HBX user
    And Patrick Doe visits the employee portal
    And Patrick Doe has a matched employee role
    And Employee sees the Household Info: Family Members page and clicks Continue
    And Employee sees the Choose Coverage for your Household page and clicks Continue
    And Employee selects the first plan available
    And Employee clicks Confirm
    And Employee sees the Enrollment Submitted page and clicks Continue
    When Employee click the "Married" in qle carousel
    And Employee select a past qle date
    Then Employee should see confirmation and clicks continue
    Then Employee should see the dependents page
    When Employee clicks continue on group selection page for dependents
    When Employee clicks Shop for new plan button
    Then Patrick Doe should see the list of plans
    When Patrick Doe selects a plan on the plan shopping page
    When Employee clicks on Confirm button on the coverage summary page
    Then Employee clicks back to my account button
    Then Patrick Doe should see primary person
    And Employee logs out

  Scenario: when EE purchase plan for self & dependent
    When staff role person logged in
    And this employer has enrollment_open benefit application with offering health and dental
    And Acme Inc. employer visit the Employee Roster
    Then Employer logs out
    And Employee has not signed up as an HBX user
    And Patrick Doe visits the employee portal
    And Patrick Doe has a matched employee role
    And Employee sees the Household Info: Family Members page and clicks Continue
    And Employee sees the Choose Coverage for your Household page and clicks Continue
    And Employee selects the first plan available
    And Employee clicks Confirm
    And Employee sees the Enrollment Submitted page and clicks Continue
    When Employee click the "Married" in qle carousel
    And Employee select a past qle date
    Then Employee should see confirmation and clicks continue
    Then Employee should see the dependents page
    When Employee clicks Add Member
    Then Employee should see the new dependent form
    When Employee enters the dependent info of Patrick wife
    When Employee clicks confirm member
    Then Employee should see 1 dependents
    When Employee clicks continue on group selection page for dependents
    When Employee clicks Shop for new plan button
    Then Patrick Doe should see the list of plans
    When Patrick Doe selects a plan on the plan shopping page
    When Employee clicks on Confirm button on the coverage summary page
    Then Employee clicks back to my account button
    Then Patrick Doe should see active enrollment with their spouse
    And Employee logs out

  Scenario: EE having an ineligible family member & doing plan shop
    When staff role person logged in
    And this employer has enrollment_open benefit application with offering health and dental
    And Acme Inc. employer visit the Employee Roster
    Then Employer logs out
    And Employee has not signed up as an HBX user
    And Patrick Doe visits the employee portal
    And Patrick Doe has a matched employee role
    And Employee sees the Household Info: Family Members page and clicks Continue
    And Employee sees the Choose Coverage for your Household page and clicks Continue
    And Employee selects the first plan available
    And Employee clicks Confirm
    And Employee sees the Enrollment Submitted page and clicks Continue
    When Employee click the "Married" in qle carousel
    And Employee select a past qle date
    Then Employee should see confirmation and clicks continue
    Then Employee should see the dependents page
    When Employee clicks Add Member
    Then Employee should see the new dependent form
    When Employee enters the dependent info of Patrick daughter
    When Employee clicks confirm member
    Then Employee should see 1 dependents
    When Employee clicks continue on group selection page for dependents
    And employee should see the ineligible family member disabled and unchecked
    And employee should see the eligible family member enabled and checked
    And employee should also see the reason for ineligibility
    When Employee clicks Shop for new plan button
    Then Patrick Doe should see the list of plans
    When Patrick Doe selects a plan on the plan shopping page
    When Employee clicks on Confirm button on the coverage summary page
    Then Employee clicks back to my account button
    Then Patrick Doe should see primary person
    And Employee logs out

  Scenario: EE having an ineligible family member & doing plan shop
            - ER offers dental benefits for spouse in active plan year
            - ER not offers dental benefits for spouse in renewal plan year
            - ER is in renewal open enrollment period
    Given a matched Employee exists with active and renwal plan years
    And employee has a dependent in spouse relationship with age greater than 26
    And Employer not offers dental benefits for spouse in renewal plan year
    And employee has a valid "Married" qle
    Then Employee sign in to portal
    When Employee clicks "Shop for Plans" on my account page
    Then Employee should see the group selection page
    Then employee should see all the family members names
    And employee should not see the reason for ineligibility
    And employee should see the dental radio button
    Then employee switched to dental benefits
    And employee should see the ineligible family member disabled and unchecked
    And employee should see the eligible family member enabled and checked
    And employee should also see the reason for ineligibility
    When employee clicked on back to my account
    When Employee click the "Married" in qle carousel
    And I select a past qle date
    Then I should see confirmation and continue
    When employee coverage effective on date is under active plan year
    And employee clicked continue on household info page
    Then employee should see all the family members names
    And employee should not see the reason for ineligibility
    And employee should see the dental radio button
    When employee switched to dental benefits
    Then employee should not see the reason for ineligibility

  Scenario: EE plan shopping by clicking on 'make changes' button on enrollment
    Given a matched Employee exists with only employee role
    And employee has a dependent in child relationship with age greater than 26
    And employee has a dependent in spouse relationship with age greater than 26
    And employee also has a health enrollment with primary person covered
    Then Employee sign in to portal
    Then employee should see the enrollment with make changes button
    When employee clicked on make changes button
    Then employee should see the ineligible family member disabled and unchecked
    And employee should see the eligible family member enabled and checked
    And employee should also see the reason for ineligibility
    When employee clicked on shop for new plan
    Then employee should see primary and valid dependent

