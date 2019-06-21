# frozen_string_literal: true

module Config
  module SiteHelper
    def site_byline
      Settings.site.byline
    end

    def site_key
      Settings.site.key
    end
  end
end