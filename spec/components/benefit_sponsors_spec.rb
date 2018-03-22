require 'rails_helper'

if ("BenefitSponsors::Engine".constantize rescue nil)
  Dir[Rails.root.join("components/benefit_sponsors/spec/factories/*.rb")].each do |f|
    require f
  end
  Dir[Rails.root.join("components/benefit_sponsors/spec/**/*_spec.rb")].each do |f|
    require f
  end
end
