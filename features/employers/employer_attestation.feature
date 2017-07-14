# Feature: Employer Profile
#   In order for initial employers to submit application
#   Employer Staff should upload attestation document

#   Scenario: Initial employer tries to submit application without uploading attestation
#     Given Initial Employer exists with draft plan year
#     And Employer Staff did not submit attestation
#     When Employer Staff tries to publish plan year
#     Then Employer Staff should see dialog with Attestation warning
#     When Employer Staff clicks cancel
#     Then Employer Staff should redirect to plan year edit page
#     And Employer Staff should see Attestation warning
#     When Employer Staff clicks attestation link
#     Then Employer Staff should see documents tab
#     When Employer Staff clicks upload
#     Then Employer Staff should see option to upload attestation document
  
#   Scenario: Initial employer tries to submit application after submitting the attestation
#     Given Initial Employer exists with draft plan year
#     And Employer Staff submitted attestation
#     When Employer Staff tries to publish plan year
#     Then Employer Staff should see published plan year
  
#   Scenario: Admin approves the attestation
#     Given Initial Employer exists with draft plan year
#     And Employer Staff submitted attestation
#     When Admin clicks employer attestation filter
#     And Admin clicks submitted filter
#     Then Admin should see Initial Employer with submitted status
#     When Admin clicks attestation action
#     Then Admin should see attestation document
#     When Admin clicks view attestation document
#     Then Admin should see preview and attestation form 
#     When Admin clicks accept and submit 
#     Then Admin should see attestation approved message
    
#     When Admin clicks employer attestation filter
#     And Admin clicks approved filter
#     Then Admin should see Initial Employer with approved status

#     When Employer Staff logs into employer portal
#     And Employer Staff clicks documents tab
#     Then Employer Staff should see attestation status approved

#   Scenario: Admin requests more information
#     Given Initial Employer exists with draft plan year
#     And Employer Staff submitted attestation
#     When Admin clicks employer attestation filter
#     And Admin clicks submitted filter
#     Then Admin should see Initial Employer with submitted status
#     When Admin clicks attestation action
#     Then Admin should see attestation document
#     When Admin clicks view attestation document
#     Then Admin should see preview and attestation form
#     When Admin clicks requests information
#     And Admin enters the information needed
#     And Admin clicks submit
#     Then Admin should see confirmation message
    
#     When Admin clicks employer attestation filter
#     And Admin clicks pending filter
#     Then Admin should see Initial Employer with pending status

#     When Employer Staff logs into employer portal
#     And Employer Staff clicks documents tab
#     Then Employer Staff should see attestation status pending

#   Scenario: Initial Employer with enrolled plan year and Admin denies Attestation
#     Given Initial Employer exists with enrolled plan year
#     And Employees enrolled through the plan year
#     And Employer Staff submitted attestation
#     When Admin clicks employer attestation filter
#     And Admin clicks submitted filter
#     Then Admin should see Initial Employer with submitted status
#     When Admin clicks attestation action
#     Then Admin should see attestation document
#     When Admin clicks view attestation document
#     Then Admin should see preview and attestation form
#     When Admin clicks requests information
#     And Admin enters the information needed
#     And Admin clicks submit
#     Then Admin should see confirmation message
    
#     When Admin clicks employer attestation filter
#     And Admin clicks denied filter
#     Then Admin should see Initial Employer with denied status

#     When Employer Staff logs into employer portal
#     And Employer Staff clicks documents tab
#     Then Employer Staff should see attestation status denied
#     When Employer staff clicks benefits tab
#     Then Employer Staff should see canceled plan year
#     When Employer staff clicks employees tab
#     Then Employer staff should employees coverage status as canceled
    
#   Scenario: Initial Employer with active plan year and Admin denies Attestation

#     Given Initial Employer exists with enrolled plan year
#     And Employees enrolled through the plan year
#     And Employer Staff submitted attestation
#     When Admin clicks employer attestation filter
#     And Admin clicks submitted filter
#     Then Admin should see Initial Employer with submitted status
#     When Admin clicks attestation action
#     Then Admin should see attestation document
#     When Admin clicks view attestation document
#     Then Admin should see preview and attestation form
#     When Admin clicks requests information
#     And Admin enters the information needed
#     And Admin clicks submit
#     Then Admin should see confirmation message
    
#     When Admin clicks employer attestation filter
#     And Admin clicks denied filter
#     Then Admin should see Initial Employer with denied status

#     When Employer Staff logs into employer portal
#     And Employer Staff clicks documents tab
#     Then Employer Staff should see attestation status denied
#     When Employer staff clicks benefits tab
#     Then Employer Staff should see plan year in termination pending state
#     When Employer staff clicks employees tab
#     Then Employer staff should employees coverage status as termination pending
