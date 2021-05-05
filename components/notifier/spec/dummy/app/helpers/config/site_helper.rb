# frozen_string_literal: true

module Config
  module SiteHelper
    def site_byline
      EnrollRegistry[:enroll_app].settings(:byline).item
    end

    def site_key
      EnrollRegistry[:enroll_app].settings(:site_key).item
    end
  end
end