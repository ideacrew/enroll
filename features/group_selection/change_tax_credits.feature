Feature: Change Tax Credit button

  Background:
    Given enable change tax credit button is enabled
    Given a consumer exists
    Given the FAA feature configuration is enabled
    Given the automatic application of aptc on enrollment feature configuration is disabled
    And the consumer is logged in
    And consumer has a dependent in child relationship with age greater than 26
    And consumer has a dependent in spouse relationship with age greater than 26
    And consumer also has a health enrollment with primary person covered
    And the family has an active tax household
    And consumer has successful ridp
    When consumer visits home page

  Scenario: Change Tax Credit button is available for Health Plans
    Given the enrollment is a Health plan
    And the metal level is gold
    And the tax household has at least one member that is APTC eligible
    When consumer should be able to see Actions dropdown
    Then consumer clicks on the Actions button
    When consumer clicks on the make changes to my coverage button
    Then the Change Tax Credit button should be available

  Scenario: Change Tax Credit button is available for families with at least 1 member that is APTC eligible
    And the tax household has at least one member that is APTC eligible
    When consumer should be able to see Actions dropdown
    Then consumer clicks on the Actions button
    When consumer clicks on the make changes to my coverage button
    And the Change Tax Credit button should be available
    When the user clicks on the Change Tax Credit button
    And the user sees the Change Tax Credit Form

  Scenario: Eligible IVL Family can Modify APTC
    And the tax household has at least one member that is APTC eligible
    When consumer should be able to see Actions dropdown
    Then consumer clicks on the Actions button
    When consumer clicks on the make changes to my coverage button
    And the Change Tax Credit button should be available
    When the user clicks on the Change Tax Credit button
    And the user sees the Change Tax Credit Form
    And the user confirms "Yes" to change the tax credit
    And the user changes Tax credit applied to 50%
    When the user submits the Change Tax Credit form
    Then the user should see a message that their Tax Credits were updated
    And current user visits the family home page
    When consumer should be able to see Actions dropdown
    Then consumer clicks on the Actions button
    When consumer clicks on the make changes to my coverage button
    When the user clicks on the Change Tax Credit button
    Then the user should see that applied tax credit has been set accordingly


