Feature: Create Eligibility
  User should have the role of an admin

  Scenario:
    Given a consumer exists
    Given all permissions are present
    Given Hbx Admin exists
    When Hbx Admin logs on to the Hbx Portal
    When Hbx Admin click Families link
    And Hbx Admin clicks Actions button
    And Hbx Admin clicks on Create Eligibility
    And Hbx Admin select CSR 100
    And Hbx Admin select tax group one
    And Hbx Admin click Continue To Tax Group Details
    And Hbx Admin choose Effective Date
    And Hbx Admin set Expected Contribution
    And Hbx Admin click Save Changes
    Then Hbx Admin see successful message

  Scenario:
    Given a consumer exists without coverage
    Given all permissions are present
    Given Hbx Admin exists
    When Hbx Admin logs on to the Hbx Portal
    When Hbx Admin click Families link
    And Hbx Admin clicks Actions button
    And Hbx Admin clicks on Create Eligibility
    And Hbx Admin select CSR 100
    And Hbx Admin select tax group one
    And Hbx Admin click Continue To Tax Group Details
    And Hbx Admin choose Effective Date
    And Hbx Admin set Expected Contribution
    And Hbx Admin click Save Changes
    Then Hbx Admin see error message
