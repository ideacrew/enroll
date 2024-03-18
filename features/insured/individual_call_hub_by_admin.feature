Feature: Consumer verification process

  Scenario: Failed consumer esi evidence determination request
    Given the FAA feature configuration is enabled
    And FAA display_medicaid_question feature is enabled
    And FAA mec_check feature is enabled
    And validate_and_record_publish_application_errors feature is enabled
    And a family with financial application and applicants in determined state exists with unverified evidences
    And the user is RIDP verified
    Given an HBX admin exists
    And the HBX admin is logged in
    When admin visits home page
    When Hbx Admin click Families link
    Then Hbx Admin clicks on a family member
    And Individual clicks on Documents link
    Then Individual should see cost saving documents for evidences
    And Admin clicks on esi evidence action dropdown
    Then Admin should see and click Call HUB option
    And Admin clicks confirm
    When evidence determination payload is failed to publish
    Then Admin should see the error message unable to submit request
    And Admin should see the esi evidence state as attested
    And Admin clicks on esi evidence action dropdown
    Then Admin navigates to view history section
    Then Admin should see the failed request recorded in the view history table
