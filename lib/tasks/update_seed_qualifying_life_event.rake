namespace :update_seed do
  desc "QLE fit and finish updates"
  task :qualifying_life_event => :environment do 
    visited_count = 0
    changed_count = 0

    (ivl_updates + shop_updates).each do |update|
      visited_count += 1
      qle = QualifyingLifeEventKind.where(update[:criteria]).first
      if qle.blank?
        puts "#{update[:criteria][:title]} - #{update[:criteria][:market_kind]} not found!!"
        next
      end
      qle.update_attributes(update[:attribs])
      changed_count += 1
    end

    puts "visited #{visited_count} and updated #{changed_count} QualifyingLifeEventKinds with reason, title and tool tip"
  end




  def ivl_updates
    [
      { criteria: { title: "I've had a baby", market_kind: "individual" }, 
         attribs: { reason: "birth", 
                    title: "Had a baby", 
                    tool_tip: "Household adds a member due to birth" 
                  } 
        },

      { criteria: { title: "I've adopted a child", market_kind: "individual" }, 
         attribs: { reason: "adoption", 
                    title: "Adopted a child", 
                    tool_tip: "A child has been adopted, placed for adoption, or placed in foster care" 
                  } 
        },

      { criteria: { title: "I'm losing other health insurance", market_kind: "individual" }, 
         attribs: { reason: "lost_access_to_mec", 
                    title: "Lost or will soon lose other health insurance ", 
                    tool_tip: "Someone in the household is losing other health insurance involuntarily" 
                  } 
        },

      { criteria: { title: "I've married", market_kind: "individual" }, 
         attribs: { reason: "marriage", 
                    title: "Married", 
                    tool_tip:  " "
                  } 
        },

      { criteria: { title: "Losing Employer-Subsidized Insurance because employee is going on Medicare", market_kind: "individual" }, 
         attribs: { reason: "employee_gaining_medicare", 
                    title: "Dependent loss of employer-sponsored insurance because employee is enrolling in Medicare ", 
                    tool_tip: " "
                  } 
        },

      { criteria: { title: "I've entered into a legal domestic partnership", market_kind: "individual" }, 
         attribs: { reason: "domestic_partnership", 
                    title: "Entered into a legal domestic partnership", 
                    tool_tip: "Entering a domestic partnership as permitted or recognized by the District of Columbia" 
                  } 
        },

      { criteria: { title: "I've divorced or ended domestic partnership", market_kind: "individual" }, 
         attribs: { reason: "divorce", 
                    title: "Divorced or ended domestic partnership", 
                    tool_tip: "Divorced, ended a domestic partnership, or legally separated" 
                  } 
        },

      { criteria: { title: "I'm moving to the District of Columbia", market_kind: "individual" }, 
         attribs: { reason: "relocate", 
                    title: "Moved or moving to the District of Columbia", 
                    tool_tip: " " 
                  } 
        },

      { criteria: { title: "Change in APTC/CSR", market_kind: "individual" }, 
         attribs: { reason: "eligibility_change_income", 
                    title: "Change in income that may impact my tax credits/cost-sharing reductions ", 
                    tool_tip: "Increases or decreases to income that may impact eligibility for or the dollar amount of household tax credits or cost-sharing reductions. (Only applies to those currently enrolled in a plan through Be Well NM)." 
                  } 
        },

      { criteria: { title: "My immigration status has changed", market_kind: "individual" }, 
         attribs: { reason: "eligibility_change_immigration_status", 
                    title: "Newly eligible due to citizenship or immigration status change", 
                    tool_tip: " "
                  } 
        },

      { criteria: { title: "I'm a Native American", market_kind: "individual" }, 
         attribs: { reason: "qualified_native_american", 
                    title: "Native American or Alaskan Native", 
                    tool_tip: " " 
                  } 
        },

      { criteria: { title: "Problem with my enrollment caused by Be Well NM", market_kind: "individual" }, 
         attribs: { reason: "enrollment_error_or_misconduct_hbx", 
                    title: "Enrollment error caused by Be Well NM", 
                    tool_tip: "You are not enrolled or are enrolled in the wrong plan because of an error made by Be Well NM or the Department of Health and Human Services" 
                  } 
        },

      { criteria: { title: "Problem with my enrollment caused by my health insurance company", market_kind: "individual" }, 
         attribs: { reason: "enrollment_error_or_misconduct_issuer", 
                    title: "Enrollment error caused by my health insurance company", 
                    tool_tip: "You are not enrolled or are enrolled in the wrong plan because of an error made by your insurance company" 
                  } 
        },

      { criteria: { title: "Problem with my enrollment caused by someone providing me with enrollment assistance", market_kind: "individual" }, 
         attribs: { reason: "enrollment_error_or_misconduct_non_hbx", 
                    title: "Enrollment error caused by someone providing me with enrollment assistance", 
                    tool_tip: "You are not enrolled or are enrolled in the wrong plan because of an error made by a broker, in-person assister, or another expert trained by Be Well NM" 
                  } 
        },

      { criteria: { title: "My health plan violated its contract", market_kind: "individual" }, 
         attribs: { reason: "contract_violation", 
                    title: "Health plan contract violation", 
                    tool_tip: " " 
                  } 
        },

      { criteria: { title: "I applied during open enrollment but got my Medicaid denial after open enrollment ended", market_kind: "individual" }, 
         attribs: { reason: "eligibility_change_medicaid_ineligible", 
                    title: "Found ineligible for Medicaid after open enrollment ended", 
                    tool_tip: "Household member(s) had pending Medicaid eligibility at the end of open enrollment but ineligible determination received after open enrollment ended." 
                  } 
        },

      { criteria: { title: "My employer applied for small business coverage during open enrollment but was denied after open enrollment ended", market_kind: "individual" }, 
         attribs: { reason: "eligibility_change_employer_ineligible", 
                    title: "Found ineligible for employer-sponsored insurance after open enrollment ended", 
                    tool_tip: "Did not enroll in individual or family coverage because employer was applying to provide coverage through Be Well NM during open enrollment"
                  } 
        },

      { criteria: { title: "A natural disaster prevented me from enrolling", market_kind: "individual" }, 
         attribs: { reason: "exceptional_circumstances_natural_disaster", 
                    title: "A natural disaster prevented enrollment", 
                    tool_tip: "A natural disaster during open or special enrollment prevented enrollment." 
                  } 
        },

      { criteria: { title: "A medical emergency prevented me from enrolling", market_kind: "individual" }, 
         attribs: { reason: "exceptional_circumstances_medical_emergency", 
                    title: "A medical emergency prevented enrollment", 
                    tool_tip: "A serious medical emergency during open enrollment or special enrollment prevented enrollment" 
                  } 
        },

      { criteria: { title: "I was unable to enroll because of a system outage", market_kind: "individual" }, 
         attribs: { reason: "exceptional_circumstances_system_outage", 
                    title: "System outage prevented enrollment", 
                    tool_tip: "A Be Well NM outage or outage in federal or local data sources close to an open enrollment or special enrollment deadline prevented enrollment" 
                  } 
        },

      { criteria: { title: "I have experienced domestic abuse", market_kind: "individual" }, 
         attribs: { reason: "exceptional_circumstances_domestic_abuse", 
                    title: "Domestic abuse", 
                    tool_tip: "A person is leaving an abusive spouse or domestic partner" 
                  } 
        },

      { criteria: { title: "I lost eligibility for a hardship exemption", market_kind: "individual" }, 
         attribs: { reason: "lost_hardship_exemption", 
                    title: "Lost eligibility for a hardship exemption", 
                    tool_tip: "Someone in the household had an exemption from the individual mandate to have health insurance this year but is no longer eligible for the exemption" 
                  } 
        },

      { criteria: { title: "I am beginning or ending service with AmeriCorps State and National, VISTA, or NCCC", market_kind: "individual" }, 
         attribs: { reason: "exceptional_circumstances_civic_service", 
                    title: "Beginning or ending service with AmeriCorps State and National, VISTA, or NCCC", 
                    tool_tip: " " 
                  } 
        },

      { criteria: { title: "I’ve been ordered by a court to provide coverage for someone", market_kind: "individual" }, 
         attribs: { reason: "court_order", 
                    title: "Court order to provide coverage for someone", 
                    tool_tip: " " 
                  } 
        },

      { criteria: { title: "My employer did not pay my premiums on time", market_kind: "individual" }, 
         attribs: { reason: "employer_sponsored_coverage_termination", 
                    title: "Employer did not pay premiums on time", 
                    tool_tip: "Employer coverage is ending due to employer’s failure to make payments" 
                  } 
        },

    ]
  end

  def shop_updates 
    [
      { criteria: { title: "I've had a baby", market_kind: "shop" }, 
         attribs: { reason: "birth", 
                    title: "Had a baby", 
                    tool_tip: "Household adds a member due to birth" 
                  } 
        },

      { criteria: { title: "I've adopted a child", market_kind: "shop" }, 
         attribs: { reason: "adoption", 
                    title: "Adopted a child", 
                    tool_tip: "A child has been adopted, placed for adoption, or placed in foster care" 
                  } 
        },

      { criteria: { title: "I've married", market_kind: "shop" }, 
         attribs: { reason: "marriage", 
                    title: "Married", 
                    tool_tip:  " "
                  } 
        },

      { criteria: { title: "I've entered into a legal domestic partnership", market_kind: "shop" }, 
         attribs: { reason: "domestic_partnership", 
                    title: "Entered into a legal domestic partnership", 
                    tool_tip: "Entering a domestic partnership as permitted or recognized by the District of Columbia" 
                  } 
        },

      { criteria: { title: "I've divorced", market_kind: "shop" }, 
         attribs: { reason: "divorce", 
                    title: "Divorced or ended domestic partnership", 
                    tool_tip: "Divorced, ended a domestic partnership, or legally separated" 
                  } 
        },

      { criteria: { title: "I've moved", market_kind: "shop" }, 
         attribs: { reason: "relocate", 
                    title: "Moved or moving to the District of Columbia", 
                    tool_tip: " " 
                  } 
        },

      { criteria: { title: "Contract violation", market_kind: "shop" }, 
         attribs: { reason: "contract_violation", 
                    title: "Health plan contract violation", 
                    tool_tip: " " 
                  } 
        },

      { criteria: { title: "Myself or a family member has lost other coverage", market_kind: "shop" }, 
         attribs: { reason: "lost_access_to_mec", 
                    title: "Lost or will soon lose other health insurance ", 
                    tool_tip: "Someone in the household is losing other health insurance involuntarily" 
                  } 
        },

      { criteria: { title: "A family member has died",  market_kind: "shop" }, 
         attribs: { reason: "death", 
                    title: "A family member has died", 
                    tool_tip: "Remove a family member due to death" 
                  }
        },
      { criteria: { title: "My child has lost coverage due to age",  market_kind: "shop" }, 
         attribs: { reason: "child_age_off", 
                    title: "Child losing or lost coverage due to age", 
                    tool_tip: "Remove a child who is no longer eligible due to turning age 26" 
                  }
        },
      { criteria: { title: "Drop self due to new eligibility",  market_kind: "shop" }, 
         attribs: { reason: "new_eligibility_family", 
                    title: "Drop coverage due to new eligibility", 
                    tool_tip: "Drop coverage for myself or family member due to new eligibility for other coverage" 
                  }
        },
      { criteria: { title: "Drop family member due to new eligibility",  market_kind: "shop" }, 
         attribs: { reason: "new_eligibility_member", 
                    title: "Drop family member due to new eligibility", 
                    tool_tip: "Drop coverage for a family member due to their new eligibility for other coverage" 
                  }
        },
      { criteria: { title: "Exceptional circumstances",  market_kind: "shop" }, 
         attribs: { reason: "exceptional_circumstances", 
                    title: "Exceptional circumstances", 
                    tool_tip: "Enroll due to an inadvertent or erroneous enrollment or another exceptional circumstance" 
                  }
        },
      { criteria: { title: "I've started a new job",  market_kind: "shop" }, 
         attribs: { reason: "new_employment", 
                    title: "Started a new job", 
                    tool_tip: "Enroll due to becoming newly eligibile" 
                  }
        }
    ]
  end

end