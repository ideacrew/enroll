Feature: A dedicated page that gives the user access to household member creation/edit as well as Financial application forms for each household member.

  Background: Household Info page
    Given EnrollRegistry show_download_tax_documents feature is enabled
    And EnrollRegistry medicaid_tax_credits_link feature is enabled
    Given the FAA feature configuration is enabled
    Given the date is within open enrollment
    Given a plan year, with premium tables, exists
    Given that the user is on FAA Household Info: Family Members page
  
  Scenario: primary member with other household members
    And the primary member exists
    And at least one other household members exist
    And all applicants are in Info Completed state
    Then Family Relationships left section WILL display
    And the CONTINUE button will be ENABLED