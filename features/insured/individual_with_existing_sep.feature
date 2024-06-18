Feature: Consumer shops for plan with existing seps
  Background: Setup IVL benefit packages and benefit coverage periods
    Given bs4_consumer_flow feature is disable
    Given the FAA feature configuration is enabled
    And Individual market is not under open enrollment period
  
  Scenario: Individual add SEP and see SHOP for Plans Banner
    Given there exists Patrick Doe with active individual market role and verified identity
    And Patrick Doe logged into the consumer portal
    When Patrick Doe click the "Married" in qle carousel
    And Patrick Doe selects a past qle date
    When Patrick Doe clicks continue from qle
    Then Patrick Doe should see family members page and clicks continue
    And Patrick Doe should see the group selection page
    When Patrick Doe clicks Back to my account button
    Then Patric Doe should land on Home page and should see Shop for Plans Banner