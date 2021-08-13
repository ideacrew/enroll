
Feature: Customers go to Curam to view notices and verifications

  Background: Set up features
    And EnrollRegistry medicaid_tax_credits_link feature is enabled
    And EnrollRegistry contact_email_header_footer_feature feature is enabled

  Scenario: Consumer can see the Navigation Button
    Given a consumer exists
    And the consumer is logged in
    When the consumer visits verification page
    And the user navigates to the DOCUMENTS tab
    Then a button will be visible to the user labeled MEDICAID & TAX CREDITS

  Scenario: Consumer can see the text on left to the Navigation Button
    Given a consumer exists
    And the consumer is logged in
    When the consumer visits verification page
    And the user navigates to the DOCUMENTS tab
    When MEDICAID & TAX CREDITS button is visible to the user
    Then there will be text to the left of the MEDICAID & TAX CREDITS button

  Scenario: HbxAdmin can see the Navigation Button
    Given a Hbx admin with read only permissions exists
    When Hbx Admin logs on to the Hbx Portal
    And the Hbx Admin clicks on the Families tab
    And selects a Person account and navigates to Verification page
    And the user navigates to the DOCUMENTS tab
    Then a button will be visible to the user labeled MEDICAID & TAX CREDITS

  Scenario: HbxAdmin can see the text on left to the Navigation Button
    Given a Hbx admin with read only permissions exists
    When Hbx Admin logs on to the Hbx Portal
    And the Hbx Admin clicks on the Families tab
    And selects a Person account and navigates to Verification page
    When MEDICAID & TAX CREDITS button is visible to the user
    Then there will be text to the left of the MEDICAID & TAX CREDITS button

  Scenario: Broker can see the Navigation Button
    Given that a broker exists
    And the broker is signed in
    When the broker visits verification page
    And the user navigates to the DOCUMENTS tab
    Then a button will be visible to the user labeled MEDICAID & TAX CREDITS

  Scenario: Broker can see the Navigation Button
    Given that a broker exists
    And the broker is signed in
    When the broker visits verification page
    And the user navigates to the DOCUMENTS tab
    When MEDICAID & TAX CREDITS button is visible to the user
    Then there will be text to the left of the MEDICAID & TAX CREDITS button

  @flaky
  Scenario: Consumer can see the Navigation Button
    Given a consumer exists
    And the consumer is logged in
    When the user visits messages page
    Then there will be messages text to the left of the MEDICAID & TAX CREDITS button
    Then EA sets a flag in IAM to direct the consumer to the curam/ drupal login

  Scenario: HbxAdmin can see the Navigation Button
    Given a Hbx admin with read only permissions exists
    When Hbx Admin logs on to the Hbx Portal
    And the Hbx Admin clicks on the Families tab
    And selects a Person account and navigates to Messages page
    Then there will be messages text to the left of the MEDICAID & TAX CREDITS button
    Then EA sets a flag in IAM to direct the consumer to the curam/ drupal login

  Scenario: Broker can see the Navigation Button
    Given that a broker exists
    And the broker is signed in
    When the user visits messages page
    Then there will be messages text to the left of the MEDICAID & TAX CREDITS button
    Then EA sets a flag in IAM to direct the consumer to the curam/ drupal login