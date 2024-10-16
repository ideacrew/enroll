Feature: Broker Agency Re-Application

  Background: Broker Application exists in denied state
    Given there is a Broker Agency exists for District Brokers Inc
    And the broker Max Planck is primary broker for District Brokers Inc

  Scenario: HBX Admin should be able to filter for denied broker applicants
    Given bs4_admin_flow feature is disable
    Given the broker Max Planck application is in denied state
    Given there is a Broker Agency exists for Fake Agency
    And the broker Ricky Martin is primary broker for Fake Agency
    Given the broker Ricky Martin application is in pending state
    Given Hbx Admin exists
    When Hbx Admin logs on to the Hbx Portal
    Then Hbx Admin is on Broker Index of the Admin Dashboard
    When Hbx Admin is on Broker Index and clicks Broker Applicants
    Then Hbx Admin clicks on denied tab
    And Hbx Admin should see on the page broker Max Planck
    And Hbx Admin should not see on the page broker Ricky Martin

  Scenario: Hbx Admin should be able to see extended application under extended tab
    Given the broker Max Planck application is in application_extended state
    Given Hbx Admin exists
    When Hbx Admin logs on to the Hbx Portal
    And Hbx Admin is on Broker Index of the Admin Dashboard
    Then Hbx Admin is on Broker Index and clicks Broker Applicants
    Then Hbx Admin clicks on extended tab
    Then Hbx Admin should see broker Max Planck under extended tab
    #And Hbx Admin logs out

  Scenario: Hbx Admin should be able to extend a denied application
    Given the broker Max Planck application is in denied state
    Given Hbx Admin exists
    When Hbx Admin logs on to the Hbx Portal
    And Hbx Admin is on Broker Index of the Admin Dashboard
    Then Hbx Admin is on Broker Index and clicks Broker Applicants
    Then Hbx Admin clicks on denied tab
    When Hbx Admin clicks on the current broker applicant show button
    Then Hbx Admin should see the broker application with carrier appointments
    When Hbx Admin click extend broker button
    Then Hbx Admin should see the broker application extended message
    #And Hbx Admin logs out

  Scenario: Hbx Admin should be able to deny an extended application
    Given the broker Max Planck application is in application_extended state
    Given Hbx Admin exists
    When Hbx Admin logs on to the Hbx Portal
    And Hbx Admin is on Broker Index of the Admin Dashboard
    Then Hbx Admin is on Broker Index and clicks Broker Applicants
    Then Hbx Admin clicks on extended tab
    When Hbx Admin clicks on the current broker applicant show button
    Then Hbx Admin should see the broker application with carrier appointments
    When Hbx Admin click deny broker button
    Then Hbx Admin should see the broker application denied message
    Then broker Max Planck should receive application denial notification
    #And Hbx Admin logs out

  Scenario: Hbx Admin should be able to approve an extended application
    Given the broker Max Planck application is in application_extended state
    Given Hbx Admin exists
    When Hbx Admin logs on to the Hbx Portal
    And Hbx Admin is on Broker Index of the Admin Dashboard
    Then Hbx Admin is on Broker Index and clicks Broker Applicants
    Then Hbx Admin clicks on extended tab
    When Hbx Admin clicks on the current broker applicant show button
    Then Hbx Admin should see the broker application with carrier appointments
    When Hbx Admin click approve broker button
    Then Hbx Admin should see the broker successfully approved message
    Then broker Max Planck should receive application approval notification
    #And Hbx Admin logs out

  Scenario: Hbx Admin should be able to extend an extended application
    Given the broker Max Planck application is in application_extended state
    Given Hbx Admin exists
    When Hbx Admin logs on to the Hbx Portal
    And Hbx Admin is on Broker Index of the Admin Dashboard
    Then Hbx Admin is on Broker Index and clicks Broker Applicants
    Then Hbx Admin clicks on extended tab
    When Hbx Admin clicks on the current broker applicant show button
    Then Hbx Admin should see the broker application with carrier appointments
    When Hbx Admin click extend broker button
    Then Hbx Admin should see the broker application extended message
    Then broker Max Planck should receive application extended notification
    #And Hbx Admin logs out
