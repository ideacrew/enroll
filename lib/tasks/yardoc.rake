unless Rails.env.production?
  if ENV["YARD"] == "true"
    require 'yard'

    YARD::Rake::YardocTask.new do |t|
      t.files = [
        'STATUS.md',
        'app/**/*.rb',
        'lib/**/*.rb',
        'components/benefit_markets/lib/**/*.rb',
        'components/benefit_markets/app/**/*.rb',
        'components/benefit_sponsors/lib/**/*.rb',
        'components/benefit_sponsors/app/**/*.rb',
        'components/notifier/lib/**/*.rb',
        'components/notifier/app/**/*.rb',
        'components/sponsored_benefits/lib/**/*.rb',
        'components/sponsored_benefits/app/**/*.rb',
        'components/transport_gateway/lib/**/*.rb',
        'components/transport_gateway/app/**/*.rb',
        'components/transport_profiles/lib/**/*.rb',
        'components/transport_profiles/app/**/*.rb'
      ]
      t.options = [
        "--main STATUS.md"
      ]
    end

    YARD::Rake::YardocTask.new("yard:engines") do |t|
      t.files = [
        'components/benefit_markets/lib/**/*.rb',
        'components/benefit_markets/app/**/*.rb',
        'components/benefit_sponsors/lib/**/*.rb',
        'components/benefit_sponsors/app/**/*.rb'
      ]
    end
  end
end
