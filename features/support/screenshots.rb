begin
  require 'database_cleaner'
  require 'database_cleaner/cucumber'

  DatabaseCleaner.strategy = :truncation
  #DatabaseCleaner.strategy = :transaction
rescue NameError
  raise "You need to add database_cleaner to your Gemfile (in the :test group) if you wish to use it."
end

Before do |scenario|
  page.driver.restart
  Capybara.reset_sessions!
  page.driver.clear_memory_cache
  page.driver.clear_cookies
  DatabaseCleaner.clean
  @count = 0
  case scenario
  when Cucumber::RunningTestCase::ScenarioOutlineExample
    @scenario_name = scenario.scenario_outline.name.downcase.gsub(' ', '_')
    @feature_name = scenario.scenario_outline.feature.name.downcase.gsub(' ', '_')
  when Cucumber::RunningTestCase::Scenario
    @scenario_name = scenario.name.downcase.gsub(' ', '_')
    @feature_name = scenario.feature.name.downcase.gsub(' ', '_')
  else
    raise("Unhandled class, look in features/support/screenshots.rb")
  end
end

module Screenshots
  def screenshot(name, options={})
    if ENV['SCREENSHOTS'] == 'true' or options[:force]
      page.save_screenshot "tmp/#{@feature_name}/#{@scenario_name}/#{@count += 1} - #{name}.png", full: true
    end
  end
end

World(Screenshots)
