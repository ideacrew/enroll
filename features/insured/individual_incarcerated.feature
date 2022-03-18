Feature: UI validations for incarcerated individual

Background: Individual market setup
  Given Individual has not signed up as an HBX user
  Given the FAA feature configuration is enabled
  Given Individual visits the Consumer portal during open enrollment
  And Benefit package updated with incarceration status

Scenario: New user with incarceration status blocked from plan shopping
  When Individual creates a new HBX account
  And Individual clicks on continue
  And user registers as an individual
  And Individual clicks on continue
  And Individual enters personal information with incarceration details
  And Individual navigates to Choose Coverage for your Household page
  Then Individual should see incarceration message blocking individual from plan shopping