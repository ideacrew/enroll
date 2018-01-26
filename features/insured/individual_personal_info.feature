Feature: IVL personal information

  Scenario: when IVL entered incorrect information for verification types as personal information
    Given a consumer exists
    And the consumer is logged in
    And consumer has a dependent in child relationship with age less than 26
    When consumer visits home page after successful ridp
    And consumer clicked on manage family
    And consumer clicked on personal section
    Then Individual should see demographic questions
    And Individual click on no for us citizen
    Then Individual should see immigration question
    And Individual click on yes for immigration status
    And Individual selected I-551 document type
    Then Individual should see input boxes for alien number, card number, expiration date
    And Individual enters incorrect person information for verification types
    And Individual clicked on save button
    Then Individual should see error messages
    And Individul should also see the incorrect information they entered

  Scenario: when IVL entered incorrect information for verification types as dependent information
    Given a consumer exists
    And the consumer is logged in
    And consumer has a dependent in child relationship with age less than 26
    When consumer visits home page after successful ridp
    And consumer clicked on manage family
    And Individual clicked on pencil to edit dependent information
    Then Individual should see demographic questions
    And Individual click on no for us citizen
    Then Individual should see immigration question
    And Individual click on yes for immigration status
    And Individual selected I-551 document type
    And Individual enters incorrect dependent information for verification types
    And Individual clicked on confirm member button
    Then Individual should see error messages
    And Individul should also see the incorrect information they entered
