Feature: User should be able to pay for plan

Background:
    Given bs4_consumer_flow feature is disable
    
  Scenario Outline: User can see make first payments for enrollments with future effective date
    Given a <site_key> site exists
    Given EnrollRegistry <issuer_pay_now> feature is enabled
    Given the enrollment tile feature is enabled
    Given the FAA feature configuration is disabled
    Given individual Qualifying life events are present
    Given Patrick Doe has active individual market role and verified identity and IVL <issuer> enrollment
    And Patrick Doe has HBX enrollment with future effective on date
    And user Patrick Doe logs into the portal
    When person should be able to see Actions dropdown
    Then person clicks on the Actions button
    Then person should the the First Payment button
    And the first payment glossary tooltip should be present
    And user clicks on the first payment button
    Then I should see the <issuer> pop up text

  Examples:
    |              issuer_pay_now                |       issuer      | site_key |
    |              kaiser_permanente_pay_now     | Kaiser Permanente |  DC      |
    | anthem_blue_cross_and_blue_shield_pay_now  |       Anthm       |  ME      |

  Scenario: User can see make payments for enrollments with past effective date when generic redirect enabled
    Given a DC site exists
    Given the generic_redirect setting is enabled
    Given the FAA feature configuration is disabled
    Given individual Qualifying life events are present
    Given Patrick Doe has active individual market role and verified identity and IVL Kaiser enrollment
    And Patrick Doe has HBX enrollment with past effective on date
    And user Patrick Doe logs into the portal
    When person should be able to see Actions dropdown
    Then person clicks on the Actions button
    Then person should the the Make Payments button

  Scenario: User cannot see make payments for enrollments with past effective date when generic redirect disabled
    Given a DC site exists
    Given the generic_redirect setting is disabled
    Given the FAA feature configuration is disabled
    Given individual Qualifying life events are present
    Given Patrick Doe has active individual market role and verified identity and IVL Kaiser enrollment
    And Patrick Doe has HBX enrollment with past effective on date
    And user Patrick Doe logs into the portal
    When person should be able to see Actions dropdown
    Then person clicks on the Actions button
    Then person should not see the Make Payments button

  Scenario: User can see pay now button and pop up for gap between Kaiser enrollment
    Given a DC site exists
    Given the enrollment tile feature is enabled
    Given the kaiser paynow feature configuration is enabled
    And that a person exists in EA
    And the person fills in all personal info
    And the person goes plan shopping in the individual for a new plan
    And the person lands on home page
    When person click the "Had a baby" in qle carousel
    And the consumer select a future qle date
    Then person should see family members page and clicks continue
    Then person should see the group selection page
    When person clicks continue on group selection page
    And the person selects a plan
    And I click on purchase confirm button for matched person
    Then I should see pay now button
    Then user continues to their account
    And person tries to purchase with a break in coverage
    When person click the "Married" in qle carousel
    And the person click on qle continue
    Then person should see family members page and clicks continue
    Then person should see the group selection page
    When person clicks continue on group selection page
    And the person selects a plan
    And I click on purchase confirm button for matched person
    Then I should see pay now button
    Then user continues to their account
    When person should be able to see Actions dropdown
    Then person clicks on the Actions button
    Then person should the the First Payment button
