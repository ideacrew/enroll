# frozen_string_literal: true

require 'brakeman/checks/base_check'

class Brakeman::CheckPunditAuthorization < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @@description = "Check for usage of 'authorize' in a controller action"

  def run_check
    actions = Hash.new { |h,k| h[k] = Hash.new }
    tracker.controllers.each do |name, controller|
      @current_class = name
      controller.each_method do |n, m|
        if route?(n)
          actions[name][n] = m
        end
      end
    end
    tracker.find_call(:target => nil, :method => :authorize).each do |result|
      if result[:location] && result[:location][:class] && result[:location][:method]
        cn = result[:location][:class]
        mn = result[:location][:method]
        if actions[cn] && actions[cn][mn]
          actions[cn].delete(mn)
        end
      end
    end
    actions.each_pair do |k, v|
      v.each_pair do |mn, m|
        warn :file => m[:file],
          :line => m[:src].line,
          :controller => k,
          :warning_type => "Pundit Authorization",
          :warning_code => :custom_check,
          :message => "Endpoint not authorized",
          :confidence => :medium,
          :code => m[:src]
      end
    end
  end

  def route?(method)
    routes = @tracker.routes[@current_class]
    routes and routes.include?(method)
  end

  def check_authorized_route?(n,m)
    m.source
  end
end