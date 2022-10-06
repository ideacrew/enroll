Feature: Transfer History

  Background: transfer history enabled
    Given the FAA feature configuration is enabled
    Given the Transfer history feature configuration is enabled
    
    Scenario: Admin logins and visits transfer history page 
    And a family with financial application and applicants in determined state exists with evidences
    And the user with hbx_staff role is logged in
    When admin visits home page
    And admin clicks on the Cost Savings link
    And admin clicks on actions dropdown
    Then admin should see Transfer history
    When admin clicks on Transfer History
    Then Transfer History page should display
