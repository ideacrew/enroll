Feature: User should be able to pay for plan

  Background: Hbx Admin navigates to create a user applications
  #   Given Hbx Admin exists
  #   When Hbx Admin logs on to the Hbx Portal
  #   And Hbx Admin creates a consumer application
  #   Then Hbx Admin logs out

  Scenario: User can see pay now button and pop up for gap between Kaiser enrollment
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

  Scenario: User can see pay now button on actions dropdown when feature is turned on & with current effective on
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
    When person should be able to see Actions dropdown
    Then person clicks on the Actions button
    Then person should the the Make Payments button

  Scenario: User can see pay now button on actions dropdown when feature is turned on & with future effective on
    Given the enrollment tile feature is enabled
    Given the kaiser paynow feature configuration is enabled
    And that a person exists in EA
    And the person fills in all personal info
    And the person goes plan shopping in the individual for a new plan
    And the person lands on home page
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

  Scenario: User should not see pay now button on actions dropdown when feature is turned off
    Given the enrollment tile feature is enabled
    Given the kaiser paynow feature configuration is disabled
    And that a person exists in EA
    Given non-Kaiser enrollments exist
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
    Then I should see not pay now button
    Then user continues to their account
    When person should be able to see Actions dropdown
    Then person clicks on the Actions button
    Then person should not see the Make Payments button