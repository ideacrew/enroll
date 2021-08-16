Feature: State Residency Document Type

   Background: consumer my account page
     Given a consumer exists
     And the consumer is logged in
     And consumer has successful ridp

   Scenario: consumer visits documents page and the the location residency verification type feature is enabled
     Given EnrollRegistry location_residency_verification_type feature is enabled
     And consumer visits home page
     When the consumer visits the Documents page
     Then they should see the state residency tile 

   Given EnrollRegistry location_residency_verification_type feature is disabled
     Given EnrollRegistry location_residency_verification_type feature is disabled
     And consumer visits home page
     When the consumer visits the Documents page
     Then they should not see the state residency tile  
   