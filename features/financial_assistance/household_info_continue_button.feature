Feature: A dedicated page that gives the user access to household member creation/edit as well as Financial application forms for each household member.

  Background: Household Info page
    Given EnrollRegistry show_download_tax_documents feature is enabled
    And EnrollRegistry medicaid_tax_credits_link feature is enabled
    Given the FAA feature configuration is enabled
    Given the date is within open enrollment
    Given a plan year, with premium tables, exists
    Given that the user is on FAA Household Info: Family Members page

  Scenario: CONTINUE button navigation
    When at least one applicant is in the Info Needed state
    Then the CONTINUE button will be disabled

  Scenario: primary member with NO other household members
    And the primary member exists
    And NO other household members exist
    Then Family Relationships left section will NOT display


