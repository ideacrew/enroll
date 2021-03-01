Feature: Any Person with User account should be able to add employer role

  Background: Setup site and benefit market catalog
    Given a CCA site exists with a benefit market
    Given benefit market catalog exists for enrollment_open initial employer with health benefits  

  Scenario Outline: User should be able to see My Hub page
    Given that a person with <role> exists in EA
    And person with <role> signs in and visits Go to My Hub Page
    Then person should see their <role> information under My Hub page
    And person logs out

    Examples:
      | role           |
      | Employee       |
      | Consumer       |
      | Employer Staff |
      | GA Staff       |
      | Broker Staff   |

  Scenario Outline: User should be able to add employer role based on eligibility
    Given that a person with <role> exists in EA
    And person with <role> signs in and visits Go to My Hub Page
    Then person should see their <role> information under My Hub page
    And person should see Add Account button
    Then person clicks on Add Account
    Then person should see a pop up with text What Do You Want To Do?
    And person should see a link to add EmployerStaff role
    And person clicks on EMPLOYER text
    Then person should be redirected to Employer Registration page
    And person filled all the fields in the employer information form
    Then person should see the Add Office Location button
    And person clicks on ADD PORTAL
    #Then person should see a modal confirmation pop up
    #And person clicks on add role on pop up
    Then person should see employer home page
    And employer logs out
    
    Examples:
      | role           |
      | Employee       |
      | Consumer       |
      | Employer Staff |
      | GA Staff       |
      | Broker Staff   |
