Feature: IVL plan purchase

  Scenario: when IVL purchase plan for self & dependent
    Given a consumer exists
    And the consumer is logged in
    And consumer has a dependent in child relationship with age less than 26
    When consumer visits home page after successful ridp
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
    When consumer visits home page after successful ridp
    And consumer clicked on "Married" qle
    And I select a past qle date
    Then I should see confirmation and continue
    When ivl clicked continue on household info page
    Then consumer should see all the family members names
    When consumer unchecks the primary person
    And consumer clicked on shop for new plan
    Then consumer should only see the dependent name

  Scenario: IVL having an ineligible family member & doing plan shop
    Given a consumer exists
    And the consumer is logged in
    And consumer has a dependent in child relationship with age greater than 26
    When consumer visits home page after successful ridp
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
    Then consumer should see primary person

  Scenario: IVL plan shopping by clicking on 'make changes' button on enrollment
    Given a consumer exists
    And the consumer is logged in
    And consumer has a dependent in child relationship with age greater than 26
    And consumer has a dependent in spouse relationship with age greater than 26
    And consumer also has a health enrollment with primary person covered
    When consumer visits home page after successful ridp
    Then consumer should see the enrollment with make changes button
    When consumer clicked on make changes button
    Then consumer should see the ineligible family member disabled and unchecked
    And consumer should see the eligible family member enabled and checked
    And consumer should also see the reason for ineligibility
    When consumer clicked on shop for new plan
    Then consumer should see primary and valid dependent

  Scenario: IVL keep existing plan by clicking on 'make changes' button on sep enrollment
    Given a consumer exists
    And the consumer is logged in
    And consumer has a dependent in child relationship with age greater than 26
    And consumer has a dependent in spouse relationship with age greater than 26
    And consumer also has a health enrollment with primary person covered
    When consumer visits home page after successful ridp
    Then consumer should see the enrollment with make changes button
    When consumer clicked on make changes button
    Then consumer should see the ineligible family member disabled and unchecked
    When consumer clicked on keep existing plan button
    Then consumer should land on confirm page
    And consumer clicks Confirm
    Then consumer should enrollment submitted confirmation page
    And consumer clicks back to my account button
    Then cosumer should see the home page

  Scenario: IVL keep existing plan by clicking on 'make changes' button on open enrollment
    Given Individual has not signed up as an HBX user
    When Individual visits the Insured portal during open enrollment
    Then Individual creates a new HBX account
    Then I should see a successful sign up message
    And user should see your information page
    When user goes to register as an individual
    When user clicks on continue button
    Then user should see heading labeled personal information
    Then Individual should click on Individual market for plan shopping #TODO re-write this step
    Then Individual should see a form to enter personal information
    When Individual clicks on Save and Exit
    Then Individual resumes enrollment
    And Individual click on sign in existing account
    And I signed in
    Then Individual sees previously saved address
    Then Individual agrees to the privacy agreeement
    Then Individual should see identity verification page and clicks on submit
    Then Individual should see the dependents form
    And Individual clicks on add member button
    And Individual again clicks on add member button #TODO re-write this step
    And I click on continue button on household info form
    And I click on continue button on group selection page
    And I select three plans to compare
    And I should not see any plan which premium is 0
    And I select a plan on plan shopping page
    And I click on purchase button on confirmation page
    And I click on continue button to go to the individual home page
    And I should see the individual home page
    When I click the "Had a baby" in qle carousel
    And I select a past qle date
    Then I should see confirmation and continue
    And I can see the select effective date
    When I click on continue button on select effective date
    Then I can see the error message Please Select Effective Date
    And I select a effective date from list
    And I click on continue button on select effective date
    When I click on continue button on household info form
    And I click on continue button on household info form
    And I click on back to my account
    When consumer clicked on make changes button
    Then consumer clicked on keep existing plan button
    Then consumer should land on confirm page
    And consumer clicks Confirm
    Then consumer should enrollment submitted confirmation page
    Then consumer clicked on continue for plan shopping
    Then cosumer should see the home page

  Scenario: IVL plan shopping by clicking on 'shop for plan' button should land on Plan shopping page
    Given a consumer exists
    And the consumer is logged in
    And consumer has a dependent in child relationship with age less than 26
    And consumer also has a health enrollment with primary person covered
    When consumer visits home page after successful ridp
    Then consumer should see the enrollment with make changes button
    When consumer clicked on make changes button
    And consumer clicked on shop for new plan
    Then consumer should see both dependent and primary

  Scenario: IVL plan shopping by clicking on 'make changes' button on dental enrollment
    Given a consumer exists
    And the consumer is logged in
    And consumer has a dependent in child relationship with age greater than 26
    And consumer has a dependent in spouse relationship with age greater than 26
    And consumer also has a dental enrollment with primary person covered
    When consumer visits home page after successful ridp
    Then consumer should see the dental enrollment with make changes button
    When consumer clicked on make changes button
    Then consumer should see the ineligible family member disabled and unchecked
    And consumer should see the eligible family member enabled and checked
    And consumer should also see the reason for ineligibility
    Then consumer should see keep existing plan and select plan to terminate button
    When consumer clicked on shop for new plan
    Then consumer should see primary and valid dependent
