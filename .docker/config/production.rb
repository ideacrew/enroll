# frozen_string_literal: true

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.cache_classes = true
  # config.cache_store = :memory_store

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local = ENV['ENROLL_REVIEW_ENVIRONMENT'] == 'true'
  config.action_controller.perform_caching = true

  # Enable Rack::Cache to put a simple HTTP cache in front of your application
  # Add `rack-cache` to your Gemfile before enabling this.
  # For large-scale production use, consider using a caching reverse proxy like
  # NGINX, varnish or squid.
  # config.action_dispatch.rack_cache = true

  # Disable serving static files from the `/public` folder by default since
  # Apache or NGINX already handles this.
  config.serve_static_files = false

  # Compress JavaScripts and CSS.
  config.assets.js_compressor = Uglifier.new(harmony: true)
  # config.assets.css_compressor = :sass

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  config.assets.compile = false

  # Asset digests allow you to set far-future HTTP expiration dates on all assets,
  # yet still be able to expire them through the digest params.
  config.assets.digest = true

  # `config.assets.precompile` and `config.assets.version` have moved to config/initializers/assets.rb

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = 'X-Sendfile' # for Apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for NGINX

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = ENV['ENABLE_FORCE_SSL'] == 'true'

  if ENV['ENABLE_CONTENT_SECURITY_POLICY'] == 'true'
    config.content_security_policy do |policy|
      policy.default_src :self, :https
      policy.font_src :self, :https, :data, "*.gstatic.com  *.fontawesome.com"
      policy.img_src :self, :https, :data, "*.google-analytics.com *.gstatic.com *.googletagmanager.com"
      policy.script_src :self, :https, :unsafe_inline, :unsafe_eval, "https://tagmanager.google.com https://www.googletagmanager.com https://apps.usw2.pure.cloud *.fontawesome.com *.google-analytics.com"
      policy.style_src :self, :https, :unsafe_inline, "https://tagmanager.google.com https://www.googletagmanager.com https://fonts.googleapis.com *.fontawesome.com"
      policy.media_src :self, :https, :data
    end
  end

  config.static_cache_control = 'public, max-age=31536000'
  config.public_file_server.headers = {
    'Cache-Control' => 'public, max-age=31536000',
    'Expires' => 1.year.from_now.to_formatted_s(:rfc822)
  }

  # Use the lowest log level to ensure availability of diagnostic information
  # when problems arise.
  config.log_level = :debug

  # Prepend all log lines with the following tags.
  # config.log_tags = [ :subdomain, :uuid ]

  # Use a different logger for distributed setups.
  # config.logger = ActiveSupport::TaggedLogging.new(SyslogLogger.new)

  # Use a different cache store in production.
  # config.cache_store = :mem_cache_store
  # config.cache_store = :redis_store, { :host => "localhost",
                                     #:port => 6379,
                                     #:db => 0,
                                     #:password => "mysecret",
                                     #:namespace => "cache",
                                     #:expires_in => 90.minutes }

  config.cache_store = :redis_store, "redis://#{ENV['REDIS_HOST_ENROLL']}:6379", {  }

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.action_controller.asset_host = 'http://assets.example.com'

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners.
  config.active_support.deprecation = :notify

  # Use default logging formatter so that PID and timestamp are not suppressed.
  config.log_formatter = Logger::SimpleJsonFormatter.new

  # Do not dump schema after migrations.
#  config.active_record.dump_schema_after_migration = false
#  config.acapi.add_async_subscription(Subscribers::DateChange)
  config.acapi.publish_amqp_events = true
  config.acapi.app_id = "enroll"
  config.acapi.remote_broker_uri = ENV['RABBITMQ_URL']
  config.acapi.remote_request_exchange = "#{ENV['HBX_ID']}.#{ENV['ENV_NAME']}.e.fanout.requests"
  config.acapi.remote_event_queue = "#{ENV['HBX_ID']}.#{ENV['ENV_NAME']}.q.application.enroll.inbound_events"
  config.action_mailer.default_url_options = { :host => (ENV['ENROLL_FQDN']).to_s }
  config.acapi.hbx_id = (ENV['HBX_ID']).to_s
  config.acapi.environment_name = (ENV['ENV_NAME']).to_s

  # Add Google Analytics tracking ID
  config.ga_tracking_id = ENV['GA_TRACKING_ID'] || "dummy"
  config.ga_tagmanager_id = ENV['GA_TAGMANAGER_ID'] || "dummy"

  #Environment URL stub
  config.checkbook_services_base_url = ENV['CHECKBOOK_BASE_URL'] || "https://checkbook_url"
  config.checkbook_services_ivl_path = ENV['CHECKBOOK_IVL_PATH'] || "/ivl/"
  config.checkbook_services_shop_path = ENV['CHECKBOOK_SHOP_PATH'] || "/shop/"
  config.checkbook_services_congress_url = ENV['CHECKBOOK_CONGRESS_URL'] || "https://checkbook_url/congress/"
  config.checkbook_services_remote_access_key = ENV['CHECKBOOK_REMOTE_ACCESS_KEY'] || "9876543210"
  config.checkbook_services_reference_id = ENV['CHECKBOOK_REFERENCE_ID'] || "0123456789"
  # for Employer Auto Pay
  config.wells_fargo_api_url = ENV['WF_API_URL'] || "dummy"
  config.wells_fargo_api_key = ENV['WF_API_KEY'] || "dummy"
  config.wells_fargo_biller_key = ENV['WF_BILLER_KEY'] || "dummy"
  config.wells_fargo_api_secret = ENV['WF_API_SECRET'] || "dummy"
  config.wells_fargo_api_version = ENV['WF_API_VERSION'] || "dummy"
  config.wells_fargo_private_key_location = '/wfpk.pem'
  config.wells_fargo_api_date_format = '%Y-%m-%dT%H:%M:%S.0000000%z'

  # Cartafact config
  config.cartafact_document_base_url = "http://#{ENV['CARTAFACT_HOST']}:3000/api/v1/documents"

  # Action_cable config values
  config.action_cable.url = "wss://#{ENV['ENROLL_FQDN']}/cable"
  config.action_cable.allowed_request_origins = ["http://#{ENV['ENROLL_FQDN']}", "https://#{ENV['ENROLL_FQDN']}"]

# Mongoid logger levels
  Mongoid.logger.level = Logger::ERROR
  Mongo::Logger.logger.level = Logger::ERROR

  ::IdentityVerification::InteractiveVerificationService.slug!

  unless ENV["CLOUDFLARE_PROXY_IPS"].blank?
    proxy_ip_env = ENV["CLOUDFLARE_PROXY_IPS"]
    proxy_ips = proxy_ip_env.split(",").map(&:strip).map { |proxy| IPAddr.new(proxy) }
    all_proxies = proxy_ips + ActionDispatch::RemoteIp::TRUSTED_PROXIES
    config.middleware.swap ActionDispatch::RemoteIp, ActionDispatch::RemoteIp, false, all_proxies
  end

end

