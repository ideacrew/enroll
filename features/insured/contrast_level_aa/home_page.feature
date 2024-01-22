Feature: Contrast level AA is enabled - Consumer shops for plan
  Background: Setup IVL benefit packages and benefit coverage periods
    Given the contrast level aa feature is enabled
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
    Then the page passes minimum level aa contrast guidelines
