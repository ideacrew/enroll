Feature: Add Plan Year For Employer
  Scenario: Setup site, employer, and benefit market
    Given a DC site exists with a benefit market
    And there is an employer ABC Widgets
    And ABC Widgets employer has a staff role
    And staff role person logged in
    And ABC Widgets is logged in and on the home page
    And staff role person clicked on benefits tab
    Then employer should see add plan year button
    And employer clicked on add plan year button
    Then employer should see continue button disabled
    And employer filled all the fields on benefit application form
    And employer clicked on continue button
    Then employer should see form for benefit package
    And employer filled all the fields on benefit package form
    And employer selected by metal level plan offerings
    Then employer should see gold metal level type
    And employer clicked on gold metal level
    Then employer should see create plan year button disabled
    And employer selected contribution levels for the application
    Then employer should see your estimated montly cost
    And employer clicked on create plan year button
    Then employer should see a draft benefit application
