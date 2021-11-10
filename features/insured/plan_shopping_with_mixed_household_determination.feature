Feature: plan shopping with mixed household determination

  Background: Consumer work flow while plan shopping for mixed household determinations
    
    Given the FAA feature configuration is enabled
    Given Individual has not signed up as an HBX user
    #When Individual visits the Consumer portal during open enrollment
    When Individual visits the Insured portal outside of open enrollment
    Then Individual creates a new HBX account
    Then Individual should see a successful sign up message
    And Individual sees Your Information page
    When user registers as an individual
    When Individual clicks on continue
    And Individual sees form to enter personal information
    When Individual clicks on continue
    Then Individual agrees to the privacy agreeement
    And Individual answers the questions of the Identity Verification page and clicks on submit
    Then Individual is on the Help Paying for Coverage page
    Then Individual does not apply for assistance and clicks continue
    Then Individual should see the dependents form
    And Individual clicks on add member button
    When csr plans exists in db
    And Individual clicks on the Continue button of the Family Information page
   
  @wip
  Scenario: plan shopping with mixed pdc eligible taxhoushold members
    Given all plan shopping are of mixed determination
    And I click on continue button on group selection page
    Then the page should not have any csr plans
   

   #@flaky
  Scenario: plan shopping with all eligible taxhoushold members
    Given every individual is eligible for Plan shopping for CSR plans
    When Individual click the "Married" in qle carousel
    And Individual selects a past qle date
    Then Individual should see confirmation and continue
    And Individual clicks on continue button on Choose Coverage page
    #And I click on continue button on group selection page
    Then the page should have csr plans
    
  @wip
  Scenario: plan shopping with all eligible taxhoushold members shops for CSR plan
    Given every individual is eligible for Plan shopping for CSR plans
    And I click on continue button on group selection page
    Then the page should have csr plans
    And selects a csr plan
    Then the page should redirect to thankyou page
    
  @wip
  Scenario: plan shopping with all eligible taxhoushold members shops for non CSR plan
    Given every individual is eligible for Plan shopping for CSR plans
    When the db has standard plans
    #And I click on continue button on group selection page
    When Individual click the "Married" in qle carousel
    And Individual selects a past qle date
    Then Individual should see confirmation and continue
    And Individual clicks on continue button on Choose Coverage page
    And selects a non csr plan
    Then the page should open a model pop-up for confirmation
    Then user clicks close button
