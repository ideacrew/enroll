Feature: Create Broker Agency
  In order to support individual and SHOP market clients, brokers must create and manage an account on the HBX for their organization.  Such organizations are referred to as a Broker Agency
  A Broker Representative
  Should be able to create a Broker Agency account

    Scenario: Broker Representative has not signed up on the HBX
      Given I haven't signed up as an HBX user
      When I visit the HBX Broker Agency portal
        And I sign up with valid user data
      Then I should see a successful sign up message
        And I should see an initial form to enter information about my Broker Agency and myself

    Scenario: Broker Representative has previously signed up on HBX
      Given I have signed up previously through consumer, employer or previous visit to the Broker Agency portal
      When I visit the Broker Agency portal
        And I sign in with valid user data
      Then I should see a successful sign up message
        And I should see an initial form with a fieldset for Broker Agency information, including: legal name, DBA, fein, entity_kind, market_kind, address, URL, and phone
        And I should see a second fieldset to enter my name, email and NPN
        And My user data from existing the fieldset values are prefilled using data from my existing account

    Scenario: Broker Representative provides a valid NPN
      Given I complete the Broker Agency initial form with a valid NPN
      When I submit the form
      Then My form information is saved to the database
        And My NPN is compared against the list of HBX-registered NPNs that haven't already been linked
      When My NPN match succeeds
      Then My record is updated to include Broker Role
        And My Broker Agency record is created
        And My Broker Role is set as the Broker Agency administrator
        And My NPN is set as the Broker Agency's primary broker
        And My NPN is linked to my Broker Role
        And I see the Broker Agency landing page

    Scenario: Broker Representative provides an unrecognized NPN 
      Given I complete the Broker Agency initial form with an invalid NPN
      When I submit the form
      Then My form information is saved to the database
        And the supplied NPN is compared against the list of registered NPNs that haven't already been linked
      When The NPN match fails
      Then I see a message explaining the error and instructing me to either: correct the NPN and resubmit, or contact reprentatives at the HBX

