Feature: Consumer with existing login
  As a consumer without an enrollment but having created an account through EA,
  when the the HBX admin enrolls me in CoverAll, my original application in the
  exchange should be deleted. Also when I attempt to log into EA with my original
  credentials I should see that I am enrolled in CoverAll.

  Scenario: HBX admin enrolls consumer with login in CoverAll
    Given I have already created an account in EA
    And the HBX admin has enrolled me in CoverAll
    When I enter my login credentials
    Then I should see that I have been entered in CoverAll
    And my application in the exchange should be deleted
