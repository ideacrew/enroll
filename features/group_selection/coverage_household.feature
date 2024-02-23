Feature: Coverage Household Page

  Scenario: when tobacco cost feature is enabled
    Given EnrollRegistry tobacco_cost feature is enabled
    And a consumer exists
    And the consumer is logged in
    And consumer has successful ridp
    When consumer visits home page
    And consumer clicked on "Married" qle
    And I select a past qle date
    Then I should see confirmation and continue
    And ivl clicked continue on household info page
    And consumer should see all the family members names
    And consumer reselects family member
    Then consumer should be able to toggle tobacco use question
