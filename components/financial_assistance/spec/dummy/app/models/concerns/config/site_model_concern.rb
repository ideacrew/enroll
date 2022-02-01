# frozen_string_literal: true

module Config
  module SiteModelConcern
    extend ActiveSupport::Concern

    included do
      delegate :site_short_name, :to => :class
      delegate :site_key, :to => :class
    end

    class_methods do
      def site_short_name
        EnrollRegistry[:enroll_app].setting(:short_name).item
      end

      def site_key
        EnrollRegistry[:enroll_app].settings(:site_key).item
      end
    end
  end
end
