# frozen_string_literal: true

# Uses prettier gem to beautify your code
# For Ex: RAILS_ENV=production bundle exec rake prettier:beautify_changed_files

namespace :prettier do
  desc("Beautifies files changed since master with prettier gem")
  task :beautify_changed_files do
    filelist = `git diff --name-only --staged | grep *.rb`
    puts("No rb files to lint") if filelist.blank?
    return if filelist.blank?
    puts("Executing RB prettier for #{filelist}") if filelist.present?
    `bundle exec rbprettier --write #{filelist}`
  end
end
