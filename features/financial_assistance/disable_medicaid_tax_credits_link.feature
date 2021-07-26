Feature: Assisted consumer home page medicaid and tax credits link
  
   Background: Consumer my account page
      Given a consumer exists
      And the consumer is logged in
      And consumer has successful ridp

   Scenario: consumer home page and the the medicaid tax credits link is enabled
      Given medicaid tax credits link feature is enabled
      Given consumer visits home page
      Then they should see the Medicaid and Tax Credits Link tile 
      
   Scenario: consumer home page and the the medicaid tax credits link is disabled
      Given medicaid tax credits link feature is disabled
      Given consumer visits home page
      Then they should not see the Medicaid and Tax Credits Link tile 

   Scenario: consumer visits documents page and the the medicaid tax credits link is enabled
      Given medicaid tax credits link feature is enabled
      Given consumer visits home page
      And the consumer navigates to the Documents page
      Then they should see the Medicaid and Tax Credits Link tile 

   Scenario: consumer vists documents page and the the medicaid tax credits link is disabled
      Given medicaid tax credits link feature is disabled
      Given consumer visits home page
      And the consumer navigates to the Documents page
      Then they should not see the Medicaid and Tax Credits Link tile 

   Scenario: consumer visits messages page and the the medicaid tax credits link is enabled
      Given medicaid tax credits link feature is enabled
      Given consumer visits home page
      And the consumer clicks the Messages link
      Then they should see the Medicaid and Tax Credits Link tile 

   Scenario: consumer vists messages page and the the medicaid tax credits link is disabled
      Given medicaid tax credits link feature is disabled
      Given consumer visits home page
      And the consumer clicks the Messages link
      Then they should not see the Medicaid and Tax Credits Link tile 


   
 



