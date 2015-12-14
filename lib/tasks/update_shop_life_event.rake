namespace :update_qle do
  desc "update effective_on_kinds for loss of MEC qle"
  task :mec_event => :environment do 
    qles = QualifyingLifeEventKind.where(market_kind: 'shop', reason: 'lost_access_to_mec')
    if qles.present?
      qles.update_all(effective_on_kinds: ["first_of_next_month"])
      puts "update mec qle effective_on_kinds successful."
    end
  end
end
