Rails.configuration.middleware.use Browser::Middleware do
  setting = Settings.aca.block_ie_browser_after
  date = (setting.is_a? Date) ? setting : Date.strptime(setting, '%m/%d/%y')
  redirect_to unsupportive_browser_path if browser.ie? && Settings.aca.block_ie_browser && date <= TimeKeeper.date_of_record
end

