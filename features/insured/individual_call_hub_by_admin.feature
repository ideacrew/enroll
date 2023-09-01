Feature: Consumer verification process

  Scenario: Consumer has determined Financial Assistance application
    Given the FAA feature configuration is enabled
    And FAA display_medicaid_question feature is enabled
    And FAA mec_check feature is enabled
    And validate_and_record_publish_application_errors feature is enabled
    And a family with financial application and applicants in determined state exists with unverified evidences
    And the user with hbx_staff role is logged in
    When admin visits home page
    And Individual clicks on Documents link
    Then Individual should see cost saving documents for evidences
    And Admin clicks on esi evidence action dropdown
    Then Admin should see and click Call HUB option
    And Admin clicks confirm
    When evidence determination payload is failed to publish
    Then Admin should see the error message unable to submited request
    And Admin should see the esi evidence state as attested