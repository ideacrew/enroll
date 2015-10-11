Recaptcha.configure do |config|
  config.public_key  = '6Ldo0QgTAAAAAJBE9jsAc28Ak5uSYcS3e31d-7Jc'
  config.private_key = '6Ldo0QgTAAAAAGq4GOdlmpaU4NXFaj-TtJtPfd0-'
  config.skip_verify_env << "production"
  config.skip_verify_env << "development"
  # Uncomment if you want to use the newer version of the API,
  # only works for versions >= 0.3.7:
  # config.api_version = 'v2'
end
