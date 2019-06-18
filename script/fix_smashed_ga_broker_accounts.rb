["5ae9fc0b082e7620c90001f7", "5ae9fc0a082e7620c90001ed", "5ae9fc09082e7620c90001e8", "5ae9fc09082e7620c90001e3", "5ae9fc09082e7620c90001de", "5ae9fc07082e7620c90001cf", "5ae9fc06082e7620c90001c5", "57e29f27faca143688000248", "57362281faca140ac9000114", "57c78191faca1428a1003c1e", "57c7818cfaca1428a1003aa5", "57c7818cfaca1428a1003a8a", "5ae9fc0b082e7620c90001fc", "57758376faca14780100097c", "5734b65f082e761a8f000a09", "57c7814cfaca1428a1002700", "57c78137faca1428a1002126", "57c78129faca1428a1001c9f", "57c0b36450526c055e000221", "579ea214faca143fe50003db", "57c780e1faca1428a10006ba", "57c0b36650526c055e00023f", "57c0b36650526c055e000230", "57c0b36450526c055e000217", "57c78101faca1428a10010ae", "57a8977e082e761b7000001f", "57a8977e082e761b7000001a", "57a8977d082e761b70000015", "57a8977d082e761b7000000b", "57c7817dfaca1428a10035ff", "576aec2c50526c16020000b3", "579ea21bfaca143fe500065f", "574f4c6dfaca147872000717", "57c0b36550526c055e00022b", "57c78178faca1428a1003451", "57b1d1c1faca140f79000331", "57c0b36650526c055e000235", "579ea21cfaca143fe50006af", "57d6c271082e7660f500002a", "57339e0f082e761ca3000065", "57362284faca140ac900014b", "57362280faca140ac900010f", "57c7810dfaca1428a1001466", "57758373faca14780100086b", "5775836cfaca1478010005b8", "57758372faca1478010007ef", "5772bf1250526c636a00083c", "58484f90f1244e2a1700001b", "58d97244faca14056b000015", "574f4c68faca1478720006ea", "5995b2da50526c7b5300002a", "57c0b36650526c055e00023a", "5734a25650526c21080006e0", "57362284faca140ac9000150", "57c780ebfaca1428a10009b5", "57758367faca1478010003b9", "57362285faca140ac900015a", "5ae9fc0a082e7620c90001f2", "5ae9fc07082e7620c90001d4", "57758368faca1478010003d5", "5ae9fc06082e7620c90001ca", "57362283faca140ac9000137", "5775837afaca147801000b0d", "574da736082e7654b1000ff0", "577e71a150526c5856000045", "576aec09082e76777c000063", "577bc3fcf1244e32c0000085", "576aec2d50526c16020000b8", "57758366faca147801000357", "57758370faca14780100070b", "57758377faca147801000a06", "57c9f510f1244e0b63000019", "57c0b36450526c055e00021c", "5805402ef1244e6d38000180", "592dc4d4faca146cd20000f4", "580f7db7f1244e5143000195", "5820aebff1244e3c8b00001d", "57758377faca1478010009ec", "57a8977c082e761b70000006", "57a8977d082e761b70000010", "57583213f1244e5427000037", "584f143af1244e74ac000143", "5787edb9082e76436700007d", "57507264082e767965000030", "587e42cefaca143f7b000032", "57c0b36550526c055e000226", "58a3926e50526c166f00010f", "579ea22ffaca143fe5000c9b", "579f9d07faca1409190002c5", "58c063d1f1244e21cb0001e1", "57f6ff2e082e76673b00007d", "597b7722f1244e2c4100006d", "57758375faca14780100090d", "58c187a1f1244e537e000079", "58d14624f1244e359900003f", "58d2c7ea50526c23da000068", "57bb3509f1244e40530000e2", "57c7816cfaca1428a100309c", "590b72ab082e7621f5000094", "595fbed5faca1426e10000b9", "5977b718082e767c2900007f", "5980d663f1244e4819000237", "5ae9fc07082e7620c90001d9", "590896f550526c4100000012", "57c7815cfaca1428a1002bab", "57c7814dfaca1428a1002729", "57c78163faca1428a1002de8", "579ea239faca143fe500100a"].each do |id|
  employer_profile = Organization.where("employer_profile.general_agency_accounts._id" => BSON::ObjectId.from_string(id)).first.employer_profile
  account = employer_profile.general_agency_accounts.where(id: id).first
  if account.aasm_state != "active"
    puts "Skipped Bad record with State Inactive. #{id} - aasm_state - #{account.aasm_state}"
    next
  end

  if employer_profile.general_agency_accounts.size == 1 && employer_profile.broker_agency_accounts.size == 1
    broker_account = employer_profile.broker_agency_accounts.first
    if account.broker_role_id.to_s != broker_account.writing_agent_id.to_s
      if account.update_attributes(broker_role_id: broker_account.writing_agent_id)
        puts "Success - account #{id} GA-#{account.general_agency_profile.legal_name} BROKER-#{account.broker_role.broker_agency_profile.legal_name} ER-#{account.employer_profile.legal_name} -> Fixed GA Account(which has 1 of each type)"
      else
        puts "Failure - account #{id} GA-#{account.general_agency_profile.legal_name} BROKER-#{account.broker_role.broker_agency_profile.legal_name} ER-#{account.employer_profile.legal_name} -> Smashed Account Save failed"
      end
    else
      puts "Failure - account #{id} GA-#{account.general_agency_profile.legal_name} BROKER-#{account.broker_role.broker_agency_profile.legal_name} ER-#{account.employer_profile.legal_name} -> Smashed Accounts!"
    end
    next
  end

  if !employer_profile.broker_agency_accounts.any? {|broker_account| broker_account.writing_agent_id.to_s == account.broker_role_id.to_s }
    broker_account = employer_profile.broker_agency_accounts.where(is_active: true).first

    if broker_account.present?
      if employer_profile.general_agency_accounts.where(aasm_state: "active").size > 1
        puts "What: account #{id} - has more than 1 active GA accounts - ER-{account.employer_profile.legal_name} - GA's-employer_profile.general_agency_accounts.where(aasm_state: 'active').map(&:legal_name)"
        next
      end
      if account.update_attributes(broker_role_id: broker_account.writing_agent_id)
        puts "Success: account #{id} GA-#{account.general_agency_profile.legal_name} BROKER-#{account.broker_role.broker_agency_profile.legal_name} ER-#{account.employer_profile.legal_name} -> Updated Broker Role on GA account"
      else
        puts "Failure: account #{id} GA-#{account.general_agency_profile.legal_name} BROKER-#{account.broker_role.broker_agency_profile.legal_name} ER-#{account.employer_profile.legal_name} -> Failed to update Broker Role on GA account"
      end
    elsif account.update_attributes(aasm_state: "inactive")
      puts "Success: account #{id} GA-#{account.general_agency_profile.legal_name} BROKER-#{account.broker_role.broker_agency_profile.legal_name} ER-#{account.employer_profile.legal_name} -> No active broker assigned. Changed GA account status to inactive"
    else
      puts "Failure: account #{id} GA-#{account.general_agency_profile.legal_name} BROKER-#{account.broker_role.broker_agency_profile.legal_name} ER-#{account.employer_profile.legal_name} -> No active broker assigned. GA account status to inactive failed"
    end
  else
    puts "Nothing to fix -- #{id}"
  end
end
