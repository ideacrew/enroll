
Feature: Customers go to Curam to view notices and verifications

  Background: Set up features
    Given EnrollRegistry medicaid_tax_credits_link feature is enabled
    And EnrollRegistry contact_email_header_footer_feature feature is enabled

  Scenario: Consumer can see the Navigation Button
    Given a consumer exists
    And the user is RIDP verified
    And the consumer is logged in
    When the consumer visits verification page
    And the user navigates to the DOCUMENTS tab
    Then MEDICAID & TAX CREDITS button is visible to the user
    Then consumer logs out

  Scenario: Consumer can see the text on left to the Navigation Button
    Given a consumer exists
    And the user is RIDP verified
    And the consumer is logged in
    When the consumer visits verification page
    And the user navigates to the DOCUMENTS tab
    When MEDICAID & TAX CREDITS button is visible to the user
    Then there will be text to the left of the MEDICAID & TAX CREDITS button
    Then consumer logs out

  Scenario: HbxAdmin can see the Navigation Button
    Given a Hbx admin with read only permissions exists
    When Hbx Admin logs on to the Hbx Portal
    And the Hbx Admin clicks on the Families tab
    And selects a Person account and navigates to Verification page
    And the user navigates to the DOCUMENTS tab
    Then MEDICAID & TAX CREDITS button is visible to the user
    Then Hbx Admin logs out

  Scenario: HbxAdmin can see the text on left to the Navigation Button
    Given a Hbx admin with read only permissions exists
    When Hbx Admin logs on to the Hbx Portal
    And the Hbx Admin clicks on the Families tab
    And selects a Person account and navigates to Verification page
    When MEDICAID & TAX CREDITS button is visible to the user
    Then there will be text to the left of the MEDICAID & TAX CREDITS button
    Then Hbx Admin logs out

  Scenario: Broker can see the Navigation Button
    Given an individual market broker exists
    And a consumer role family exists with broker
    And the broker is signed in
    And broker lands on broker agency home page
    And the broker clicks on Families tab
    And broker clicks on the name of the person in family index
    And the broker sees the documents tab
    When the broker visits verification page
    Then MEDICAID & TAX CREDITS button is visible to the user
    And there will be text to the left of the MEDICAID & TAX CREDITS button
    Then broker logs out

  Scenario: Consumer can see the Navigation Button
    Given a consumer exists
    And the user is RIDP verified
    And the consumer is logged in
    When the user visits messages page
    Then there will be text to the left of the MEDICAID & TAX CREDITS button
    Then EA sets a flag in IAM to direct the consumer to the curam/ drupal login
    Then consumer logs out

  Scenario: HbxAdmin can see the Navigation Button
    Given a Hbx admin with read only permissions exists
    When Hbx Admin logs on to the Hbx Portal
    And the Hbx Admin clicks on the Families tab
    And selects a Person account and navigates to Messages page
    Then there will be text to the left of the MEDICAID & TAX CREDITS button
    Then EA sets a flag in IAM to direct the consumer to the curam/ drupal login
    Then Hbx Admin logs out

  @flaky
  Scenario: Broker can see the Navigation Button
    Given an individual market broker exists
    And a consumer role family exists with broker
    And the broker is signed in
    And broker lands on broker agency home page
    And the broker clicks on Families tab
    And broker clicks on the name of the person in family index
    When the user visits messages page
    Then there will be text to the left of the MEDICAID & TAX CREDITS button
    Then EA sets a flag in IAM to direct the consumer to the curam/ drupal login
    Then broker logs out
