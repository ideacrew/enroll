Feature: County should be loaded based on zip code in broker registration form

  Background:
    Given zip code for county exists as rate reference

  Scenario: User enters valid zipcode
    Given a broker visits the HBX Broker Registration form
    And enters the existing zip code
    Then the county should be autopopulated appropriately

  Scenario: User enters invalid zipcode
    Given a broker visits the HBX Broker Registration form
    And enters a non existing zip code
    Then the county should not be autopopulated appropriately
