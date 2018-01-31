namespace :update_qle do
  desc "update effective_on_kinds for loss of MEC qle"
  task :events => :environment do 
    reasons = ["new_employment",
     "marriage",
     "domestic_partnership",
     "lost_access_to_mec",
     "divorce",
     "death",
     "child_age_off",
     "new_eligibility_family",
     "new_eligibility_member",
     "relocate",
     "exceptional_circumstances",
     "contract_violation"]

    reasons.each do |reason|
      qles = QualifyingLifeEventKind.where(market_kind: 'shop', reason: reason)
      if qles.present?
        qles.update_all(effective_on_kinds: ["first_of_next_month"])
        puts "update #{reason} qle effective_on_kinds successful."
      end
    end
  end
end
