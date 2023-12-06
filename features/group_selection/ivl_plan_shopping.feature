Feature: IVL plan purchase

  Scenario: when IVL purchase plan for self & dependent
    Given a consumer exists
    And the consumer is logged in
    And consumer has a dependent in child relationship with age less than 26
    And consumer has successful ridp
    When consumer visits home page
    And consumer clicked on "Married" qle
    And I select a past qle date
    Then I should see confirmation and continue
    When ivl clicked continue on household info page
    Then consumer should see all the family members names
    And consumer clicked on shop for new plan
    Then consumer should see both dependent and primary

  Scenario: when IVL purchase plan only for dependent
    Given a consumer exists
    And the consumer is logged in
    And consumer has a dependent in child relationship with age less than 26
    And consumer has successful ridp
    When consumer visits home page
    And consumer clicked on "Married" qle
    And I select a past qle date
    Then I should see confirmation and continue
    When ivl clicked continue on household info page
    Then consumer should see all the family members names
    When consumer unchecks the primary person
    And consumer clicked on shop for new plan
    Then consumer should only see the dependent name

  Scenario: when consumer selects a plan only primary should be able to confirm plan selection
    Given a consumer exists
    And the consumer is logged in
    And consumer has a dependent in child relationship with age less than 26
    And consumer has successful ridp
    When consumer visits home page
    And consumer clicked on "Married" qle
    And I select a past qle date
    Then I should see confirmation and continue
    When ivl clicked continue on household info page
    Then consumer should see all the family members names
    And consumer clicked on shop for new plan
    And Individual selects a plan on plan shopping page
    And Individual hits tab and enter
    Then Individual does not navigate to the enrollment submitted page

  Scenario: IVL having an ineligible family member & doing plan shop
    Given a consumer exists
    And the consumer is logged in
    And consumer has a dependent in child relationship with age greater than 26
    And consumer has successful ridp
    When consumer visits home page
    And consumer clicked on "Married" qle
    And I select a past qle date
    Then I should see confirmation and continue
    When ivl clicked continue on household info page
    Then consumer should see all the family members names
    And consumer should see the ineligible family member disabled and unchecked
    And consumer should see the eligible family member enabled and checked
    And consumer should also see the reason for ineligibility
    And consumer should see the dental radio button
    When consumer unchecks the primary person
    And consumer switched to dental benefits
    Then the primary person checkbox should be in unchecked status
    And consumer should also see the reason for ineligibility
    When consumer checks the primary person
    And consumer clicked on shop for new plan
    Then consumer should see coverage for primary person

  Scenario: when individual purchases dental plan for self & dependent and tries to filter by Low/High
    Given a consumer exists
    And the consumer is logged in
    And consumer has a dependent in child relationship with age less than 26
    And consumer has successful ridp
    When consumer visits home page
    And consumer clicked on "Married" qle
    And I select a past qle date
    Then I should see confirmation and continue
    When ivl clicked continue on household info page
    Then consumer should see all the family members names
    And individual selects dental for coverage kind
    And consumer clicked on shop for new plan
    Then consumer should see both dependent and primary
    And individual selects high for metal level plan and metal level box appears selected

  Scenario: IVL having an ineligible family member & immigration status failed
    Given a consumer exists
    And the consumer is logged in
    And consumer has successful ridp
    When consumer visits home page
    When citizen status is false for the consumer
    And consumer clicked on "Married" qle
    And I select a past qle date
    Then I should see confirmation and continue
    When ivl clicked continue on household info page
    And the consumer should see the reason for ineligibility

  Scenario: Showing Go To Plan Compare Button
    Given EnrollRegistry go_to_plan_compare_link feature is enabled
    Given a consumer exists
    And the consumer is logged in
    And consumer has a dependent in child relationship with age less than 26
    And consumer has successful ridp
    When consumer visits home page
    And consumer clicked on "Married" qle
    And I select a past qle date
    Then I should see confirmation and continue
    When ivl clicked continue on household info page
    Then consumer should see all the family members names
    And consumer clicked on shop for new plan
    Then employee should see Go To Plan Compare button

  Scenario: Filters HC4CC plans while plan shopping
    Given the osse subsidy feature is enabled
    Given a consumer exists
    And the consumer is logged in
    And consumer has a dependent in child relationship with age less than 26
    And consumer has successful ridp
    And consumer has osse eligibility
    When consumer visits home page
    And consumer clicked on "Married" qle
    And I select a past qle date
    Then I should see confirmation and continue
    When ivl clicked continue on household info page
    Then consumer should see all the family members names
    And consumer clicked on shop for new plan
    Then consumer should see hc4cc filter

  Scenario: APTC eligible consumers should seeing OSSE subsidy when OSSE eligible and individual_osse_plan_filter disabled
    Given plan filter feature is disabled and osse subsidy feature is enabled
    Given a consumer exists
    And the consumer is logged in
    And consumer has a dependent in child relationship with age less than 26
    And consumer has successful ridp
    And consumer has osse eligibility
    And products are marked as hc4cc
    Given every individual is eligible for Plan shopping for CSR plans
    When consumer visits home page
    And consumer clicked on "Married" qle
    And I select a past qle date
    Then I should see confirmation and continue
    When ivl clicked continue on household info page
    Then consumer should see all the family members names
    And consumer clicked on shop for new plan
    Then consumer should see 0 premiums for all plans

  Scenario: Health Plans Title Content should be displayed on Plan Shopping page
    Given EnrollRegistry go_to_plan_compare_link feature is enabled
    Given a consumer exists
    And the consumer is logged in
    And consumer has a dependent in child relationship with age less than 26
    And consumer has successful ridp
    When consumer visits home page
    And consumer clicked on "Married" qle
    And I select a past qle date
    Then I should see confirmation and continue
    When ivl clicked continue on household info page
    Then consumer should see all the family members names
    And consumer clicked on shop for new plan
    Then employee should see health title content

  Scenario: Dental Plans Title Content should be displayed on Plan Shopping page
    Given EnrollRegistry go_to_plan_compare_link feature is enabled
    Given a consumer exists
    And the consumer is logged in
    And consumer has a dependent in child relationship with age less than 26
    And consumer has successful ridp
    When consumer visits home page
    And consumer clicked on "Married" qle
    And I select a past qle date
    Then I should see confirmation and continue
    When ivl clicked continue on household info page
    Then consumer should see all the family members names
    And individual selects dental for coverage kind
    And consumer clicked on shop for new plan
    Then employee should see dental title content
