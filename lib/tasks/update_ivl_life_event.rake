namespace :update_ivl do
  desc "update ivl qle title"
  task :life_event => :environment do 
    qles = QualifyingLifeEventKind.where(title: 'My Employer failed to pay COBRA premiums on time')
    if qles.present?
      qles.update_all(title: 'My employer failed to pay premiums on time')
      puts "update ivl qle title successful."
    end
  end
end
