Feature: Display Enrollment Summary
  Only admins and brokers are able to see this page

  Background:
    Given the display enrollment summary configuration is enabled
    Given a Hbx admin with hbx_staff role exists
    Given a consumer exists
    And consumer also has a health enrollment with primary person covered
    And the family has an active tax household
    And consumer has successful ridp
    
  Scenario: Consumer views the Enrollment Summary page
    And the consumer is logged in
    When consumer visits home page
    And consumer should be able to see Actions dropdown
    Then consumer clicks on the Actions button
    When consumer clicks on the View my coverage details
    Then additional Enrollment Summary does not exists

  Scenario: Admin views the Enrollment Summary page
    And a Hbx admin logs on to Portal
    When Hbx Admin click Families link
    And Hbx Admin clicks on a family member
    When Admin should be able to see Actions dropdown
    Then Admin clicks on the Actions button
    When Admin clicks on the View my coverage details
    Then additional Enrollment Summary exists

  Scenario: Admin navigates to Enrollment Summary page and sees service area value
    And a Hbx admin logs on to Portal
    When Hbx Admin click Families link
    And Hbx Admin clicks on a family member
    When Admin should be able to see Actions dropdown
    Then Admin clicks on the Actions button
    When Admin clicks on the View my coverage details
    And navigates to Enrollment Summary page
    Then the Admin should see "Service Area" text
    Then the Admin should see "Rating Area" text