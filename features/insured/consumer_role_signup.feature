Feature: Contrast level AA is enabled - User is not applying for financial assistance
  Scenario: Consumer role try to signup
    Given bs4_consumer_flow feature is enabled
    When user signup
    When user clicks inside the email field
    When user clicks outside the email field
    Then user should not see the error message