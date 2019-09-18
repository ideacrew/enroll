Feature: An employee can make self service updates to their household
  The applicable Employer Roster should be or not be updated accordingly


Background: Setup site, employer, and benefit application
  Given a CCA site exists with a benefit market
  Given benefit market catalog exists for enrollment_open initial employer with health benefits
  Given Qualifying life events are present
  And there is an employer Acme Inc.
  And Acme Inc. employer has a staff role
  And initial employer Acme Inc. has enrollment_open benefit application
  And there is an employer Acme2 Inc.
  And second employer Acme2 Inc. has a staff role
  And second employer Acme2 Inc. has enrollment_open benefit application


  Scenario: Employee has an active enrollment with one employer and initiates household update(s) from self-serve
    Given Employer exists and logs in
    And Acme Inc. employer visit the Employee Roster
    And there is a census employee record for Patrick Doe for employer Acme Inc.
    Then Employer logs out

    And Employee has not signed up as an HBX user
    And Patrick Doe visits the employee portal
    When Patrick Doe creates an HBX account
    When Employee goes to register as an employee
    Then Employee should see the employee search page
    When Employee enters the identifying info of Patrick Doe
    Then Employee should see the matched employee record form
    When Employee accepts the matched employer
    When Employee completes the matched employee form for Patrick Doe
    Then Employee should see the dependents page
    When Employee clicks Add Member
    Then Employee should see the new dependent form
    When Employee enters the dependent info of Patrick wife
    When Employee clicks confirm member
    Then Employee should see 1 dependents
    Then Employee logs out

    Then Employer exists and logs in
    And Employer visit the Employer portal
    And Employer staff clicks employees tab
    And clicks on the employee profile for Patrick
    Then Employer should see dependents including Patrick's wife


  Scenario: Employee is active with multiple employers and initiates household update(s) from self-serve
    Given Employer exists and logs in
    And Acme Inc. employer visit the Employee Roster
    And there is a census employee record for Patrick Doe for employer Acme Inc.
    Then Employer logs out

    Then second Employer exists and logs in
    And Acme2 Inc. employer visit the Employee Roster
    And there is a second census employee record for Patrick Doe for employer Acme2 Inc.
    Then Employer logs out

    And Employee has not signed up as an HBX user
    Then Patrick Doe matches all employee roles to employers and is logged in
    When Employee goes to register as an employee
    Then Employee should see the employee search page
    When Employee enters the identifying info of Patrick Doe
    Then Employee should see the matched employee record form
    When Employee accepts the matched employer
    When Employee completes the matched employee form for Patrick Doe
    And Employee sees the Household page and clicks Continue
    And Employee selects the first plan available
    And Employee clicks Confirm
    Then Employee sees the Enrollment Submitted page and clicks Continue

    Then Employee shops for the second sponsored plan
    And Employee clicks Confirm
    Then Employee sees the Enrollment Submitted page and clicks Continue

    Then visits My Insured Portal
    Then Employee should click on Manage Family button
    When Employee clicks Add Member
    Then Employee should see the new dependent form
    When Employee enters the spouse info of Patrick wife
    When Employee clicks confirm member
    Then Employee should see 1 dependents
    Then Employee logs out

    Then Employer exists and logs in
    And Employer visit the Employer portal
    And Employer staff clicks employees tab
    And clicks on the employee profile for Patrick
    Then Employer should see dependents including Patrick's wife

    Then second Employer exists and logs in
    And Employer visit the Employer portal
    And Employer staff clicks employees tab
    And clicks on the employee profile for Patrick
    Then Employer should see dependents including Patrick's wife


  Scenario: Employee is active with one or multiple employers and initiates a Dependent Relationship Change that is not supported in SHOP
    Given Employer exists and logs in
    And Acme Inc. employer visit the Employee Roster
    And there is a census employee record for Patrick Doe for employer Acme Inc.
    Then Employer logs out

    Then second Employer exists and logs in
    And Acme2 Inc. employer visit the Employee Roster
    And there is a second census employee record for Patrick Doe for employer Acme2 Inc.
    Then Employer logs out

    And Employee has not signed up as an HBX user
    Then Patrick Doe matches all employee roles to employers and is logged in
    When Employee goes to register as an employee
    Then Employee should see the employee search page
    When Employee enters the identifying info of Patrick Doe
    Then Employee should see the matched employee record form
    When Employee accepts the matched employer
    When Employee completes the matched employee form for Patrick Doe
    And Employee sees the Household page and clicks Continue
    And Employee selects the first plan available
    And Employee clicks Confirm
    Then Employee sees the Enrollment Submitted page and clicks Continue

    Then Employee shops for the second sponsored plan
    And Employee clicks Confirm
    Then Employee sees the Enrollment Submitted page and clicks Continue

    Then visits My Insured Portal
    Then Employee should click on Manage Family button
    When Employee clicks Add Member
    Then Employee should see the new dependent form
    When Employee enters the parent info of Patrick father
    When Employee clicks confirm member
    Then Employee should see 1 dependents
    Then Employee logs out

    Then Employer exists and logs in
    And Employer visit the Employer portal
    And Employer staff clicks employees tab
    And clicks on the employee profile for Patrick
    Then Employer should not see dependents

    Then second Employer exists and logs in
    And Employer visit the Employer portal
    And Employer staff clicks employees tab
    And clicks on the employee profile for Patrick
    Then Employer should not see dependents


  Scenario: Employee initiated updates that are not resulting from a QLE will not update the employer roster if the enrollment is in coverage_terminated state
    Given Employer exists and logs in
    And initial employer Acme Inc. has enrollment_open benefit application
    And Acme Inc. employer visit the Employee Roster
    And there is a census employee record for Patrick Doe for employer Acme Inc.
    Then Employer logs out

    And Employee has not signed up as an HBX user
    Then Patrick Doe matches all employee roles to employers and is logged in
    When Employee goes to register as an employee
    Then Employee should see the employee search page
    When Employee enters the identifying info of Patrick Doe
    Then Employee should see the matched employee record form
    When Employee accepts the matched employer
    When Employee completes the matched employee form for Patrick Doe
    And Employee sees the Household page and clicks Continue
    And Employee selects the first plan available
    And Employee clicks Confirm
    Then Employee sees the Enrollment Submitted page and clicks Continue
    Then Employee logs out

    Then Employer exists and logs in
    And Employer visit the Employer portal
    And Employer staff clicks employees tab
    Then Employer clicks on Actions button
    And Employer clicks on terminate button for an employee
    And clicks terminated employees tab
    Then should see terminated employee
    Then Employer logs out

    Then Patrick Doe visits Returning User Portal
    Then visits My Insured Portal
    Then Employee should click on Manage Family button
    When Employee clicks Add Member
    Then Employee should see the new dependent form
    When Employee enters the spouse info of Patrick's wife without address
    When Employee clicks confirm member
    Then Employee should see 1 dependents
    Then Employee logs out

    Then Employer exists and logs in
    And Employer visit the Employer portal
    And Employer staff clicks employees tab
    And clicks terminated employees tab
    And clicks on the employee profile for Patrick
    Then Employer should not see dependents


  Scenario: Employee initiated updates will update the employer roster if in coverage_waived state
    Given Employer exists and logs in
    And initial employer Acme Inc. has enrollment_open benefit application
    And Acme Inc. employer visit the Employee Roster
    And there is a census employee record for Patrick Doe for employer Acme Inc.
    Then Employer logs out

    And Employee has not signed up as an HBX user
    Then Patrick Doe matches all employee roles to employers and is logged in
    When Employee goes to register as an employee
    Then Employee should see the employee search page
    When Employee enters the identifying info of Patrick Doe
    Then Employee should see the matched employee record form
    When Employee accepts the matched employer
    When Employee completes the matched employee form for Patrick Doe
    And Employee sees the Household page and clicks Continue
    And Employee continues to Plan Shopping

    Then Employee see the waive coverage button
    Then Employee selects waiver on the plan shopping page
    And Employee submits waiver reason
    Then Employee should see waiver summary page
    Then Employee clicks continue on waiver summary page
    Then Employee should able to see Waiver tile

    Then visits My Insured Portal
    Then Employee should click on Manage Family button
    When Employee clicks Add Member
    Then Employee should see the new dependent form
    When Employee enters the spouse info of Patrick wife
    When Employee clicks confirm member
    Then Employee should see 1 dependents
    Then Employee logs out

    Then Employer exists and logs in
    And Employer visit the Employer portal
    And Employer staff clicks employees tab
    And clicks on the employee profile for Patrick
    Then Employer should see dependents including Patrick's wife


  Scenario: Employee initiated updates will still update the employer roster if the enrollment is in coverage_termination_pending state
    Given Employer exists and logs in
    And initial employer Acme Inc. has enrollment_open benefit application
    And Acme Inc. employer visit the Employee Roster
    And there is a census employee record for Patrick Doe for employer Acme Inc.
    Then Employer logs out

    And Employee has not signed up as an HBX user
    Then Patrick Doe matches all employee roles to employers and is logged in
    When Employee goes to register as an employee
    Then Employee should see the employee search page
    When Employee enters the identifying info of Patrick Doe
    Then Employee should see the matched employee record form
    When Employee accepts the matched employer
    When Employee completes the matched employee form for Patrick Doe
    And Employee sees the Household page and clicks Continue
    And Employee selects the first plan available
    And Employee clicks Confirm
    Then Employee sees the Enrollment Submitted page and clicks Continue
    Then Employee logs out

    Then Employer exists and logs in
    And Employer visit the Employer portal
    And Employer staff clicks employees tab
    Then Employer clicks on Actions button
    And Employer clicks on future termination button for an employee
    Then should see terminated employee
    Then Employer logs out

    Then Patrick Doe matches all employee roles to employers and is logged in
    Then Employee should click on Manage Family button
    When Employee clicks Add Member
    Then Employee should see the new dependent form
    When Employee enters the spouse info of Patrick wife
    When Employee clicks confirm member
    Then Employee should see 1 dependents
    Then Employee logs out

    Then Employer exists and logs in
    And Employer visit the Employer portal
    And Employer staff clicks employees tab
    And clicks on the employee profile for Patrick
    Then Employer should see dependents including Patrick's wife
