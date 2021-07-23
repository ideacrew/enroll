Feature: Assisted consumer documents page medicaid and tax credits link
  
   Background: Consumer my account page
      Given a consumer exists
      And the consumer is logged in
      And consumer has successful ridp   

    Scenario: consumer is logged in and the the medicaid tax credits link is enabled
    Given medicaid tax credits link is enabled
     Given a consumer visits the home page
     And the consumer clicks the Documents link
     Then they should see the medicaid and tax credits link tile 

   Scenario: consumer is logged in and the the medicaid tax credits link is disabled
    Given medicaid tax credits link is disabled
     Given a consumer visits the home page
     And the consumer clicks the Documents link
     Then they should not see the medicaid and tax credits link tile  


