Feature: Start a new Financial Assistance Application
  Background:
    Given the FAA feature configuration is enabled
    Given the date is within open enrollment
    Given a consumer, with a family, exists
    And is logged in
    And the consumer is RIDP verified
    And a benchmark plan exists

  @flaky
  Scenario: A consumer wants to start a new financial assistance application
    When a consumer visits the Get Help Paying for coverage page
    And selects yes they would like help paying for coverage
    Then they should see a new finanical assistance application
    And they should see each of their dependents listed

  Scenario: A consumer is subject to a successful MEC check
    Given the MEC check feature configuration is enabled
    And the consumer has received a successful MEC check response
    When a consumer visits the Get Help Paying for coverage page
    Then they should see the Medicaid Currently Enrolled warning text

  Scenario: A consumer enters tax information for an application's applicant
    Given the consumer has started a financial assistance application
    When they view the financial assistance application
    And they click ADD INCOME & COVERAGE INFO for an applicant
    Then they should be taken to the applicant's Tax Info page

  Scenario: A consumer adds Job income for an application's applicant
    Given the consumer has started a financial assistance application
    And has added tax information for an applicant
    And they visit the applicant's Job income page
    And they answer job income question and complete the form for the Job income
    Then they should see the newly added Job income
    And they should see the dates in correct format

  Scenario: A consumer adds Job income with incorrect date format
    Given the consumer has started a financial assistance application
    And has added tax information for an applicant
    And they visit the applicant's Job income page
    And they answer job income question and complete the form with incorrect data format
    Then I should see a JS alert
