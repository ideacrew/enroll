require 'csv'

namespace :qle do
  desc "Populate date_options_available"
  task populate_date_options_available: :environment do
    # QLE with Date options 
    qles_titles = [ "Not eligible for marketplace coverage due to citizenship or immigration status",
           "Provided documents proving eligibility"]
    qles_titles.each do |qle_title|
      QualifyingLifeEventKind.where(title: qle_title).each do |qle|
        qle.update_attributes!(date_options_available: true)
      end
  end
  end
end