Feature: Start a new Financial Assistance Application
  Background:
    Given a consumer, with a family, exists
    And is logged in

  Scenario: A consumer wants to start a new financial assistance application
    When the consumer views their applications
    And they click 'New Financial Assistance Application' button
    Then they should see a new finanical assistance application
    And they should see each of their dependents listed

  Scenario: A consumer enters tax information for an application's applicant
    Given the consumer has started a financial assistance application
    When they view the financial assistance application
    And they click edit for an applicant
    And they complete and submit the tax information
    Then they should be taken to the applicant's details page
    And see some of the tax information on the applicant's detail page

  Scenario: A consumer adds income for an application's applicant
    Given the consumer has started a financial assistance application
    And has added tax information for an applicant
    When they view the applicant's details page
    And they click on the 'Add Income' button
    And they complete the form for the income
    Then they should be taken back to the applicant's detail page
    And they should see the newly added income

  Scenario: A consumer adds benefit for an application's applicant
    Given the consumer has started a financial assistance application
    And has added tax information for an applicant
    When they view the applicant's details page
    And they click on 'Add Benefit' button
    And they complete the form for the benefit
    Then they should be taken back to the applicant's detail page
    And they should see the newly added benefit

  Scenario: A consumer adds deduction for an application's applicant
    Given the consumer has started a financial assistance application
    And has added tax information for an applicant
    When they view the applicant's details page
    And they click on the 'Add deduction' button
    And they complete the form for the deduction
    Then they should be taken back to the applicant's detail page
    And they should see the newly added deduction

  Scenario: A consumer removes an income for an application's applicant
    Given the consumer has started a financial assistance application
    And has added tax information for an applicant
    When they view the applicant's details page
    And they click on the 'Add Income' button
    And they complete the form for the income
    When they view the applicant's details page
    And they click on 'Remove Income' button
    Then they should be taken back to the application's details page for income
    And the income should be no longer be shown

  Scenario: A consumer removes an benefit for an application's applicant
    Given the consumer has started a financial assistance application1
    And has added tax information for an applicant
    When they click on 'Add Benefit' button
    And they complete the form for the benefit
    When they view the applicant's details page
    Then they click on 'Remove Benefit' button
    And they should be taken back to the application's details page for benefit
    #And the benefit should be no longer be shown

  Scenario: A consumer removes an deduction for an application's applicant
    Given the consumer has started a financial assistance application1
    And has added tax information for an applicant
    #And has added an deduction
    When they click on 'Add Deduction' button
    And they complete the form for the deduction
    When they view the applicant's details page
    And they click on 'Remove deduction' button
    And they should be taken back to the application's details page for deduction
    #And the deduction should be no longer be shown

  Scenario: A consumer reviews and submits an application
    Given the consumer has completed a financial assistance application
    When they view the financial assistance application for review
    And click the 'Review and Continue' button
    And they review and submit the application
    Then they are taken back to view all applications
    And they will see that their application has been submitted