Feature: Consumer plan shopping
  Scenario: Consumer cannot update their plan using browser back after enrollment is submitted
    Given bs4_consumer_flow feature is disable
    Given a ME site exists
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
    When user clicks browser back button
    Then user should redirect to receipt page and should see a flash message
