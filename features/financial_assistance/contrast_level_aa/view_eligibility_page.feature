Feature: Contrast level AA is enabled - A dedicated page that visit the eligibility determination page

  Background: Submit Your Application page
    Given the contrast level aa feature is enabled
    And the FAA feature configuration is enabled

  Scenario: External verification link
    Given FAA fa_send_to_external_verification feature is enabled
    Given FAA display_eligibility_results_per_tax_household feature is disabled
    Given FAA transfer_service feature is enabled
    Given FAA non_magi_transfer feature is disabled
    Given that a user with a family has a Financial Assistance application with tax households
    And the user has a 73% CSR
    And the user navigates to the "Help Paying For Coverage" portal
    And clicks the "Action" dropdown corresponding to the "determined" application
    And all applicants are not medicaid chip eligible and are non magi medicaid eligible
    And clicks the "View Eligibility Determination" link
    Then the page passes minimum level aa contrast guidelines
