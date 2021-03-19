# frozen_string_literal: true

# This will switch between Rails 5 and 6
# For Ex: RAILS_ENV=production bundle exec rake rails_version_toggler:toggle

require "#{Rails.root}/lib/rails_version_toggler.rb"

namespace :rails_version_toggler do
  desc("Toggles between rails 5 and 6")
  task :toggle do
    RailsVersionToggler.new.toggle
  end
end