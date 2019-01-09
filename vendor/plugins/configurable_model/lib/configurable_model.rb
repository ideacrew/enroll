require 'configurable_model/version'
require 'configurable_model/base'
require 'configurable_model/setting'
require 'configurable_model/options'
require 'configurable_model/sources/hash_source'
require 'configurable_model/caches/setting_cache'

module ConfigurableModel
  extend ActiveSupport::Concern
  include ConfigurableModel::Base

  included do
    embeds_many :settings, class_name: "ConfigurableModel::Setting", as: :configurable
  end
end



