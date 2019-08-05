Feature: Hbx Admin can view carriers and its associated products.
  Scenario: Hbx Admin views products
    Given Hbx Admin exists
    When Hbx Admin logs on to the Hbx Portal
    And Hbx Admin clicks on Issuers tab
    When Hbx Admin click on a carrier
    Then Hbx Admin should see a list of products