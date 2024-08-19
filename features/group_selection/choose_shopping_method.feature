Feature: Choose Shopping Method
  Background:
    Given bs4_consumer_flow feature is disable
    Given choose_shopping_method feature is enabled
    Given the FAA feature configuration is enabled
    Given a consumer exists
    And the consumer is logged in
    And consumer has successful ridp
    When consumer visits home page
    And consumer clicked on "Married" qle
    And I select a past qle date
    Then I should see confirmation and continue

 Scenario: New insured user goes to Checkbook via the choose coverage page when shopping for health plan
    When ivl clicked continue on household info page
    And consumer clicked on shop for new plan
    Then the user is on the Choose Shopping Page
    And the checkbook choice is selected
    And the user clicks continue to next step for plan comparison
    Then the checkbook modal should be visible

  Scenario: New insured user goes to plan shopping via the choose coverage page when shopping for health plan
    When ivl clicked continue on household info page
    And consumer clicked on shop for new plan
    Then the user is on the Choose Shopping Page
    And the user says they know the plan they want
    And the user clicks continue to next step for plan shopping
    Then consumer should see coverage for primary person

Scenario: New insured user gets to the plan shopping page after qle when shopping for dental plan
    When ivl clicked continue on household info page
    And Individual switched to dental benefits
    And consumer clicked on shop for new plan
    Then consumer should see coverage for primary person
