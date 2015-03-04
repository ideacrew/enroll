Feature: Create Employer
  In order to offer health and dental insurance benefits to my employees, employers must create and manage an account on the HBX for their organization.  Such organizations are referred to as an Employer
  An Employer Representative 
  Should be able to create an Employer account

    Scenario: An Employer Representative has not signed up on the HBX
      Given I haven't signed up as an HBX user
      When I visit the Employer portal
        And I sign up with valid user data
      Then I should see a successful sign up message
        And I should see an initial form to enter information about my Employer and myself

    Scenario: Employer Representative has previously signed up on HBX
      Given I have signed up previously through consumer, broker agency or previous visit to the Employer portal
      When I visit the Employer portal
        And I sign in with valid user data
      Then I should see a successful sign up message
        And I should see an initial form with a fieldset for Employer information, including: legal name, DBA, fein, entity_kind, broker agency, URL, address, and phone
        And I should see a second fieldset to enter my name and email
        And My user data from existing the fieldset values are prefilled using data from my existing account

    Scenario: Employer Representative provides a valid FEIN
      Given I complete the Employer initial form with a valid FEIN
      When I submit the form
      Then My form information is saved to the database
        And My FEIN is compared against the list of HBX-registered FEINs
      When My FEIN match succeeds
      Then My record is updated to include Employer Representative Role
        And My Employer's record is created
        And My Employer Role is set as the Employer administrator
        And My Employer's FEIN is linked to my Employer Reprsentative Role
        And I see my Employer's landing page

    Scenario: Employer Representative  provides an unrecognized FEIN 
      Given I complete the Employer initial form with an invalid FEIN
      When I submit the form
      Then My form information is saved to the database
        And the supplied FEIN is compared against the list of registered FEINs
      When The FEIN match fails
      Then I see a message explaining the error and instructing me to either: correct the FEIN and resubmit, or contact reprentatives at the HBX

