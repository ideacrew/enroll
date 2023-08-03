require 'haml-rails'
require 'kaminari'
require 'simple_form'
require 'effective_datatables/engine'
require 'effective_datatables/version'

module EffectiveDatatables
  mattr_accessor :authorization_method
  mattr_accessor :date_format
  mattr_accessor :datetime_format
  mattr_accessor :integer_format
  mattr_accessor :boolean_format

  mattr_accessor :default_entries
  mattr_accessor :actions_column # A Hash

  mattr_accessor :google_chart_packages

  def self.setup
    yield self
  end

  # rubocop:disable Style/MethodCallWithoutArgsParentheses
  # rubocop:disable Style/RaiseArgs
  # rubocop:disable Style/SoleNestedConditional
  def self.authorized?(datatable, controller, action, resource)
    if authorization_method.respond_to?(:call) || authorization_method.kind_of?(Symbol)
      raise Effective::AccessDenied.new() unless (controller || self).instance_exec(datatable, controller, action, resource, &authorization_method)
    end
    true
  end
  # rubocop:enable Style/MethodCallWithoutArgsParentheses
  # rubocop:enable Style/RaiseArgs
  # rubocop:enable Style/SoleNestedConditional

end
