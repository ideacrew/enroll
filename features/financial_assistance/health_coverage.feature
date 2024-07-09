# frozen_string_literal: true

Feature: Start a new Financial Assistance Application and answers questions on health coverage page

  Background: User logs in and visits applicant's health coverage page
    Given bs4_consumer_flow feature is disable
    Given the shop market configuration is enabled
    Given a consumer, with a family, exists
    And is logged in
    And the consumer is RIDP verified
    And the FAA feature configuration is enabled
    And the user will navigate to the FAA Household Info page
    And FAA display_medicaid_question feature is enabled
    When they click ADD INCOME & COVERAGE INFO for an applicant
    Then they should be taken to the applicant's Tax Info page (health coverage)
    And they visit the Health Coverage page via the left nav (also confirm they are on the Health Coverage page)

  Scenario: User answers no to currently having health coverage
    Given the user answers no to currently having health coverage
    Then the health coverage choices should not show

  Scenario: User answers no to currently having access to other health coverage
    Given the user answers no to currently having access to other health coverage
    Then the other health coverage choices should not show

  Scenario: Confirmation pop-up functionality
    When the user clicks the BACK TO ALL HOUSEHOLD MEMBERS link
    Then a modal should show asking the user are you sure you want to leave this page

  Scenario: Indian Health Service Eligible Question feature is enabled
    Given Indian Health Service Question feature is enabled
    And the user is a member of an indian tribe
    And they visit the Health Coverage page via the left nav (also confirm they are on the Health Coverage page)
    Then they should see the Indian Healthcare Eligible question

  Scenario: Indian Health Service Question feature is enabled
    Given Indian Health Service Question feature is enabled
    And the user is a member of an indian tribe
    And they visit the Health Coverage page via the left nav (also confirm they are on the Health Coverage page)
    Then they should see the Indian Healthcare question

  Scenario: MaineCare Questions feature is enabled
    Given FAA medicaid_chip_driver_questions feature is enabled
    And the user has an eligible immigration status
    And they visit the Health Coverage page via the left nav (also confirm they are on the Health Coverage page)
    Then they should see the MaineCare ineligible question
    Then they clicks yes for MaineCare ineligible
    Then they should see the immigration status question

  

  
