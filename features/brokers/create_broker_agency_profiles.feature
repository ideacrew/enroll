Feature: Create Primary Broker and Broker Agency
  In order for Brokers to help individuals and SHOP employees
  The Primary Broker must create and manage an account on the HBX for their organization.
  Such organizations are referred to as a Broker Agency
  The Primary Broker should be able to create a Broker Agency account application
  The HBX Admin should be able to approve the application and send an email invite
  The Primary Broker should receive the invite and create an Account
  The Employer should be able to select the Primary Broker as their Broker
  The Broker should be able to manage that Employer
  The Broker should be able to select a family covered by that Employer
  The Broker should be able to purchase insurance for that family

  Background: Broker registration
    Given a CCA site exists with a benefit market
    Given benefit market catalog exists for draft initial employer with health benefits
    Given Broker Agency exists in Enroll
    And there is an employer ABC Widgets
    And employer ABC Widgets has draft benefit application
    And ABC Widgets employer has a staff role
    And employer ABC Widgets has draft benefit application
    When there is a Broker
    And the broker is assigned to a broker agency

    Scenario: Employer assigns broker agency
      And staff role person logged in
      And ABC Widgets goes to the brokers tab
      Then Employer should see no active broker
      When Employer click on Browse Brokers button
      Then Employer should see broker agencies index view
      When Employer searches broker agency by name
      Then Employer should see broker agency
      When Employer clicks select broker button
      Then Employer should see confirm modal dialog box
      When Employer confirms broker selection
      Then Employer should see broker selected successful message
      When Employer clicks on the Brokers tab
      Then Employer should see broker active for the employer
      When Employer terminates broker
      Then Employer should see broker terminated message
      When Employer clicks on the Brokers tab
      Then Employer should see no active broker
      When Employer clicks on Browse Brokers button
      Then Employer should see broker agencies index view
      When Employer searches broker agency by name
      Then Employer should see broker agency
      When Employer clicks select broker button
      Then Employer should see confirm modal dialog box
      When Employer confirms broker selection
      Then Employer should see broker selected successful message
      And Employer logs out

      And that a Broker logs into a given Broker Agency Portal
      And Primary Broker clicks on the Employers tab
      Then Primary Broker should see Employer and click on legal name
      Then Primary Broker should see the Employer Profile page as Broker
      Then Primary Broker logs out

      # TODO: need to fix it
      # When Primary Broker creates and publishes a plan year
      # Then Primary Broker should see a published success message without employee
      # When Primary Broker clicks on the Employees tab
      # Then Primary Broker clicks on the add employee button
      # Then Primary Broker creates Broker Assisted as a roster employee
      # Then Primary Broker sees employer census family created
      # And I log out
      #
      # When I go to the employee account creation page
      # When Broker Assisted creates an HBX account
      # #Then Broker Assisted should be logged on as an unlinked employee
      # When Broker Assisted goes to register as an employee
      # Then Broker Assisted should see the employee search page
      # When Broker Assisted enter the identifying info of Broker Assisted
      # Then Broker Assisted should see the matched employee record form
      # When Broker Assisted accepts the matched employer
      # Then Broker Assisted completes the matched employee form for Broker Assisted
      # And I log out
      #
      # Then Primary Broker logs on to the Broker Agency Portal
      # And Primary Broker clicks on the Employers tab
      # Then Primary Broker should see Employer and click on legal name
      # Then Primary should see the Employer Profile page as Broker
      # When Primary Broker clicks on the Families tab
      # Then Broker Assisted is a family
      # Then Primary Broker goes to the Consumer page
      # # Then Primary Broker is on the consumer home page
      # # Then Primary Broker shops for plans
      # # Then Primary Broker sees covered family members
      # # Then Primary Broker should see the list of plans
      # # Then Primary Broker selects a plan on the plan shopping page
      # # And Primary Broker clicks on purchase button on the coverage summary page
      # # And Primary Broker should see the receipt page
      # Then Primary Broker logs out
