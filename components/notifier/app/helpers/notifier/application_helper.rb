module Notifier
  module ApplicationHelper
    def render_flash
      rendered = []
      flash.each do |type, messages|
        if messages.respond_to?(:each)
          messages.each do |m|
            rendered << render(:partial => 'layouts/flash', :locals => {:type => type, :message => m}) unless m.blank?
          end
        else
          rendered << render(:partial => 'layouts/flash', :locals => {:type => type, :message => messages}) unless messages.blank?
        end
      end
      rendered.join('').html_safe
    end

    def site_short_name
      Settings.site.short_name
    end

    def asset_data_base64(path)
      asset = Rails.application.assets.find_asset(path)
      throw "Could not find asset '#{path}'" if asset.nil?
      base64 = Base64.encode64(asset.to_s).gsub(/\s+/, "")
      "data:#{asset.content_type};base64,#{Rack::Utils.escape(base64)}"
    end
  end
end
