Feature: A dedicated page that gives the user access to household member creation/edit as well as Financial application forms for each household member.

  Background: Household Info page
    Given bs4_consumer_flow feature is disable
    Given EnrollRegistry show_download_tax_documents feature is enabled
    And EnrollRegistry medicaid_tax_credits_link feature is enabled
    Given the FAA feature configuration is enabled
    Given the date is within open enrollment
    Given a plan year, with premium tables, exists
    Given that the user is on FAA Household Info: Family Members page
      
  Scenario: CONTINUE button enabled when non-applying dependent does not enter ssn
    And the primary member exists
    And a new household member is not applying
    Then the no ssn warning will appear
    And primary applicant is in Info Completed state
    Then the CONTINUE button will be ENABLED

  Scenario: Consumer fields when dependent is not applying for coverage
    And the primary member exists
    And a new household member is not applying
    Then the new household member should not see consumer fields