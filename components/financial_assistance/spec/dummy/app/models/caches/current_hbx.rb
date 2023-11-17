# frozen_string_literal: true

module Caches
  # Dummy instance of the master cache for testing
  class CurrentHbx
    def self.fetch
      return Thread.current[:__current_hbx_lookup_cache] if Thread.current[:__current_hbx_lookup_cache]
      yield
    end

    def self.cache!
      Thread.current[:__current_hbx_lookup_cache] = HbxProfile.find_current_with_proxy_inbox
    end

    def self.purge!
      Thread.current[:__current_hbx_lookup_cache] = nil
    end

    def self.with_cache
      cache!
      yield
      purge!
    end
  end
end