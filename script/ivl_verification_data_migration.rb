# OLD STATES >>
    # state :verifications_pending, initial: true
    # state :verifications_outstanding
    # state :fully_verified
# >> old states


# NEW STATES
    # state :unverified, initial: true
    # state :ssa_pending
    # state :dhs_pending
    # state :verification_outstanding
    # state :fully_verified
    # state :verification_period_ended
# >> new states


Person.where("consumer_role.aasm_state" => "verifications_pending").update_all("$set" => {"consumer_role.aasm_state" => "unverified"})
Person.where("consumer_role.aasm_state" => "verifications_outstanding").update_all("$set" => {"consumer_role.aasm_state" => "verification_outstanding"})

