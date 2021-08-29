Feature: Contact Customer Support and Certified Applicant Counselor Feature

   Background: 
     Given a consumer exists
     And the consumer is logged in
     And consumer has successful ridp
     
   Scenario: consumer home page help modal and the contact customer service representative feature is enabled        
     Given EnrollRegistry contact_customer_service_representative feature is enabled
     And consumer visits home page
     When the consumer clicks the Get Help Signing Up Button
     Then they should see the Contact Customer Support and Certified Applicant Counselor links
     
   Scenario: consumer home page help modal and the contact customer service representative feature is is disabled
     Given EnrollRegistry contact_customer_service_representative feature is disabled
     And consumer visits home page
     When the consumer clicks the Get Help Signing Up Button
     Then they should not see the Contact Customer Support and Certified Applicant Counselor links