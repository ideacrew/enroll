Before do |scenario|
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
  restart_phantomjs
end

def restart_phantomjs
  puts "-> Restarting phantomjs: iterating through capybara sessions..."
  session_pool = Capybara.send('session_pool')
  session_pool.each do |mode,session|
    driver = session.driver
    if driver.is_a?(Capybara::Poltergeist::Driver)
      driver.restart
    else
      puts msg += "not poltergeist: #{driver.class}"
    end
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
