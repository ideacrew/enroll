Feature: Assign General Agency Staff to General Agency

  Scenario: General Staff has not signed up on the HBX
    Given a CCA site exists with a benefit market
    And a general agency, approved, awaiting account creation, exists
    Given a general agency agent visits the DCHBX
    When they click the 'New General Agency' button

    Given GA Staff has not signed up as an HBX user
    Then GA Staff should see the General Agency Staff Registration form
    When GA staff enters his personal information
    And GA staff searches for General Agency which exists in EA
    And GA staff should see a list of General Agencies searched and selects his agency
    Then GA staff submits his application and see successful message
