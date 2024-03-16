Feature: Assign Broker Agency Staff to Broker Agency

  Scenario: Adding Existing person as Broker Staff to Broker Agency
    Given there is a Broker Agency exists for District Brokers Inc
    And the broker Max Planck is primary broker for District Brokers Inc
    And person record exists for John Doe
    And Max Planck logs on to the Broker Agency Portal
    And the Broker clicks on the “Add Broker Staff Role” button
    And a form appears that requires the Broker to input First Name, Last Name, and DOB to submit
    When the Broker enters the First Name, Last Name, and DOB of existing user John Doe
    Then the Broker will be given a broker staff role with the given Broker Agency
    And the Broker will now appear within the “Broker Staff” table as Active and Linked

  Scenario: Adding Non Existing person as Broker Staff to Broker Agency
    Given there is a Broker Agency exists for District Brokers Inc
    And the broker Max Planck is primary broker for District Brokers Inc
    And Max Planck logs on to the Broker Agency Portal
    And the Broker clicks on the “Add Broker Staff Role” button
    And a form appears that requires the Broker to input First Name, Last Name, and DOB to submit
    When the Broker enters the First Name, Last Name, and DOB of an non existing user in EA
    Then the Broker will not be given a broker staff role with the given Broker Agency
