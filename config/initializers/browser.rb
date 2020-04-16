Rails.configuration.middleware.use Browser::Middleware do
  redirect_to unsupportive_browser_path if Settings.aca.block_ie_browser && browser.ie?
end

