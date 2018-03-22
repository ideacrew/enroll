unless Rails.env.production?
  if ENV["YARD"] == "true"
    require 'yard'

    YARD::Rake::YardocTask.new do |t|
    end

    YARD::Rake::YardocTask.new("yard:engines") do |t|
      t.files = [
        'components/*/lib/**/*.rb',
        'components/*/app/**/*.rb'
      ]
    end
  end
end
