Feature: User should be able to pay for plan

  Background: Hbx Admin navigates to create a user applications
  #   Given Hbx Admin exists
  #   When Hbx Admin logs on to the Hbx Portal
  #   And Hbx Admin creates a consumer application
  #   Then Hbx Admin logs out

  Scenario: User can see pay now button and pop up for Kaiser enrollment
    Given the FAA feature configuration is disabled
    Given the kaiser paynow feature configuration is enabled
    And that a person exists in EA
    And the person fills in all personal info
    And the person goes plan shopping in the individual for a new plan
    And the person continues to plan selection
    And the person selects a plan
    And I click on purchase confirm button for matched person
    Then I should see pay now button
    And I should click on pay now button
    Then I should see the Kaiser pop up text
    And the Kaiser user form should be active
    Then the user closes the pop up modal
    Then user continues to their account
    When consumer should be able to see Actions dropdown
    Then consumer clicks on the Actions button
    Then consumer should the the First Payment button
    And the first payment glossary tooltip should be present
    And user clicks on the first payment button
    Then I should see the Kaiser pop up text

  Scenario: User cannot see pay now button and pop up for Kaiser enrollment when feature is turned off
    Given the FAA feature configuration is disabled
    Given the kaiser paynow feature configuration is disabled
    And that a person exists in EA
    And the person fills in all personal info
    And the person goes plan shopping in the individual for a new plan
    And the person continues to plan selection
    And the person selects a plan
    And I click on purchase confirm button for matched person
    Then I should see not pay now button

  Scenario: User can see pay now pop up for non-Kaiser enrollment
    Given the FAA feature configuration is disabled
    And that a person exists in EA
    Given non-Kaiser enrollments exist
    And the person fills in all personal info
    And the person goes plan shopping in the individual for a new plan
    And the person continues to plan selection
    And the person selects a plan
    And I click on purchase confirm button for matched person
    Then I should see not pay now button
    Then user continues to their account
    When consumer should be able to see Actions dropdown
    Then consumer clicks on the Actions button
    Then consumer should the the Make Payments button
    And the make payments glossary tooltip should be present
    And user clicks on the make payments button
    Then I should see the non-Kaiser pop up text

  @flaky
  Scenario Outline: Hbx Admin uploads and verifies application document
    Given the FAA feature configuration is disabled
    And that a person exists in EA
    And the person has an active <role>
    And the person goes plan shopping in the individual for a new plan
    When the person enrolls in a Kaiser plan
    And I click on purchase confirm button for matched person
    Then I should click on pay now button
    And I should see model pop up
    Then I should see Leave DC Health LINK buttton
    And I should be able to click  Leave DC Health LINK buttton
    And I should see an alert with error message

    Examples:
      | role          |
      | consumer role |
      | resident role |

  @flaky
  Scenario Outline: Hbx Admin uploads and verifies application document
    Given the FAA feature configuration is disabled
    And that a person exists in EA
    And the person has an active <role>
    And the person goes plan shopping in the individual for a new plan
    When the person enrolls in a Kaiser plan
    And I click on purchase confirm button for matched person
    And tries to purchase with a break in coverage
    Then I click on purchase confirm button for matched person
    And I should click on pay now button
    Then I should be able to view DC Health LINK text

    Examples:
      | role          |
      | consumer role |
      | resident role |
