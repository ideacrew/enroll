Feature: Edit Plan Button

  Background: 
    Given a consumer exists
    And the consumer is logged in
    And consumer has a dependent in child relationship with age greater than 26
    And consumer has a dependent in spouse relationship with age greater than 26
    And consumer also has a health enrollment with primary person covered
    When consumer visits home page after successful ridp

  Scenario: Submit button disabled with date and "no" answered for "Are you sure?"
    When consumer clicks on the edit plan button
    Then consumer should see the edit plan page
    When consumer clicks on the Cancel Plan button
    And consumer selects "no" to are you sure
    And consumer selects a date
    Then the submit button should be disabled

  Scenario: Submit button disabled with date and and no answer for "Are you sure?"
    When consumer clicks on the edit plan button
    Then consumer should see the edit plan page
    When consumer clicks on the Cancel Plan button
    And consumer selects a date
    Then the submit button should be disabled
  
  Scenario Outline: Submit button disabled with no date
    When consumer clicks on the edit plan button
    Then consumer should see the edit plan page
    When consumer clicks on the Cancel Plan button
    And consumer selects "<answer>" to are you sure
    Then the submit button should be disabled

    Examples:
      | answer |
      | no     |
      | yes    |

  Scenario Outline: Consumer, EE with IVL coverage, or resident terminates plan
    Given consumer has a <secondary_role> role
    When consumer clicks on the edit plan button
    Then consumer should see the edit plan page
    When consumer clicks on the Cancel Plan button
    Then consumer should see the calender
    And the submit button should be disabled
    When consumer selects a date
    And  consumer selects yes to are you sure
    Then the submit button should be enabled
    When consumer clicks the submit button
    Then the enrollment should be terminated

    Examples:
      | secondary_role |
      | consumer |
      | resident |
      | employee |

  Scenario Outline: Consumer, EE with IVL coverage, or resident cancels plan
    Given consumer has a <secondary_role> role 
    When consumer's health enrollment has an effective date in the future
    When consumer clicks on the edit plan button
    And consumer clicks on the Cancel Plan button
    Then consumer should not see the calender
    When consumer selects yes to are you sure
    Then the submit button should be enabled
    When consumer clicks the submit button
    Then the enrollment should be canceled

    Examples:
      | secondary_role |
      | consumer |
      | resident |
      | employee |
