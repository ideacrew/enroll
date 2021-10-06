# Be sure to restart your server when you modify this file.

# Rails.application.config.session_store :cookie_store, key: '_enroll_session'
Rails.application.config.session_store :mongoid_store, same_site: :lax
