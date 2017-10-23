Feature: After a Financial Assistance Application is Submitted

  Background:
    Given a consumer, with a family, exists1
    And a benchmark plan exists
    And that a consumer has a Financial Assistance application in the submitted state
    Given an HBX admin exists

  Scenario:
    Given that a family member is in any other than Verified verification status for a given data type (SSN, Citizenship, Income, Native Alaskan)
    When the admin navigates to the family “Documents” page
    And visit family and click document
    And clicks on the “Choose Action” dropdown
    Then the admin user will be able to click on the action “Verify”
    When “Verify” is clicked by admin user
    Then a field will expand beneath the verification type field presenting the following

#
#Scenario:
#Given that a family member is in the Verified status for a given verification type (SSN, Citizenship, Income, Native Alaskan)
#When the admin navigates to the family “Documents” page
#And clicks on the “Choose Action” dropdown
#Then the admin user will be able to click on the action “Verify”
#
#Scenario:
#Given that a family member is in the Verified status for a given verification type (SSN, Citizenship, Income, Native Alaskan)
#When there is an existing verification reason
#And the admin navigates to the family “Documents” page
#And clicks on the “Choose Action” dropdown
#And the admin user clicks on the action “Verify”
#And the admin user selects a new reason
#And clicks “complete”
#Then the new reason will be stored.
#
#Scenario:
#Given that a family member is in the Outstanding verification status for a given data type (SSN, Citizenship, Income, Native Alaskan)
#When the admin navigates to the family “Documents” page
#And clicks on the “Choose Action” dropdown
#And the admin user clicks on the action “Verify”
#And the admin user selects a new reason
#And clicks “complete”
#Then the type status will change to the Verified state.
#
#Scenario:
#Given that a family member is in the Outstanding verification status for a given data type (SSN, Citizenship, Income, Native Alaskan)
#When the family member user navigates to the family “Documents” page
#Then family member user can see only verification status for each type
#And not “Choose Action” dropdown will be shown for any family members and verification types