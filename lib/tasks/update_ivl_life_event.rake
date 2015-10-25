namespace :update_ivl do
  desc "update ivl qle title"
  task :life_event => :environment do 
    qles = QualifyingLifeEventKind.where(title: 'My Employer failed to pay COBRA premiums on time')
    if qles.present?
      qles.update_all(title: 'My employer failed to pay premiums on time')
      puts "update ivl qle title successful."
    end
  end

  desc "change effective_on_kinds for losing other health insurance qle"
  task :change_kind_for_losing_event => :environment do
    qles = QualifyingLifeEventKind.where(title: "I'm losing other health insurance")
    if qles.present?
      qles.update_all(effective_on_kinds: ["first_of_next_month"])
      puts "update ivl qle effective_on_kinds successful."
    end
  end
end
