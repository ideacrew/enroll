Feature: Anonymous Shop
  In order to decide whether to offer health insurance to my employees
  A business owner
  Should be able to anonymous shop

    Scenario: Business Owner has not registered business on the HBX
      Given I do not have a business account
      When I visit the HBX employer portal
        And I enter minimal information about my company
      Then I see whether my business is eligible to participate on the HBX
        And I see health and dental plans offered by carriers
        And I see available employer premium contribution scenarios
      When I specify premium contribution amounts
        And enter non-identifiable information about each of my staff
      When I select an offered plan
      Then I see employer- and employee-responsible premium costs for each
      When I choose to purchase insurance
      Then I create a user account
        And I create an associated employer account



        # And I see comparative features of selected plans
