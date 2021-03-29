module Config::SiteModelConcern
  extend ActiveSupport::Concern

  included do
    delegate :site_short_name, :to => :class
    delegate :site_key, :to => :class
  end

  class_methods do
    def site_short_name
      Settings.site.short_name
    end

    def site_key
      EnrollRegistry[:enroll_app].settings(:site_key).item
    end
  end
end
