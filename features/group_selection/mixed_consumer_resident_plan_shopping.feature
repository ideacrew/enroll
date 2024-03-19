Feature: Mixed household with consumer and resident role plan purchase

  Scenario: IVL purchase plan for coverage household with consumer and resident roles
    Given a consumer exists
    And the consumer is logged in
    And consumer has a dependent in spouse relationship with resident role
    And consumer has successful ridp
    When consumer visits home page
    And consumer clicked on "Married" qle
    And I select a past qle date
    Then I should see confirmation and continue
    When ivl clicked continue on household info page
    Then consumer should see all the family members names
    And consumer should see eligibility failed error on dependent with resident role
    When consumer switched for coverall benefits
    Then consumer should see all family members eligible
    And consumer should see warning dialog on CoverAll selection
    Then consumer clicked close on CoverAll selection warning dialog
    And consumer clicked on shop for new plan
    Then consumer should see both dependent and primary
    And consumer should see the list of plans
    Then consumer selects a plan on the plan shopping page
    And consumer completes agreement terms and conditions sections on thankyou page
    When consumer clicks on Confirm button on the coverage summary page
    Then the consumer clicks continue to my account button
    Then consumer should see primary and dependent person on enrollment