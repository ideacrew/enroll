Feature: Contrast level AA is enabled - Consumer goes to the applications page
  Scenario: Consumer visits the Applications Page
    Given the contrast level aa feature is enabled
    Given EnrollRegistry medicaid_tax_credits_link feature is enabled
    And EnrollRegistry contact_email_header_footer_feature feature is enabled
    Given a consumer exists
    And the consumer is logged in
    When the user visits the applications page
    Then the page passes minimum level aa contrast guidelines
