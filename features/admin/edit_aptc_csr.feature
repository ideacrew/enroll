Feature: Update APTC and CSR
    In order to update APTC and CSR
    User should have the role of an admin
    
    Scenario: Admin views the Edit APTC / CSR grid for an individual without an assistance recieving (with APTC) enrollment
        Given Hbx Admin exists
            When Hbx Admin logs on to the Hbx Portal
            And Hbx Admin clicks on the Update APTC / CSR button
            Then Hbx Admin should see the list of APTC / CSR Enrollments and an Edit button
            When Hbx Admin clicks on the Edit button
            Then Hbx Admin should see the edit APTC / CSR form for the individual
            Then Hbx Admin should see a text saying there is no Active Enrollment


    Scenario: Admin sees MAX APTC and CSR PERCENTAGE as editable fields when no active enrollment
        Given Hbx Admin exists
            When Hbx Admin logs on to the Hbx Portal
            And Hbx Admin clicks on the Update APTC / CSR button
            Then Hbx Admin should see the list of APTC / CSR Enrollments and an Edit button
            When Hbx Admin clicks on the Edit button
            Then Hbx Admin should see the edit APTC / CSR form for the individual
            Then Hbx Admin should see APTC and CSR as editable fields