# frozen_string_literal: true

class Notifier::Services::NoticeKindService
  include Notifier::Services::TokenBuilder
  include ::Config::SiteModelConcern

  attr_accessor :market_kind, :model_builder

  delegate :recipients, to: :service
  delegate :setting_placeholders, to: :service

  def initialize(market_kind)
    @market_kind = market_kind.to_sym
  end

  def builder=(builder_str)
    builder_str_value = builder_str.to_s
    raise Notifier::MergeDataModels::InvalidBuilderError, builder_str unless Notifier::MergeDataModels::BUILDER_STRING_KINDS.include?(builder_str_value)
    @model_builder = Notifier::MergeDataModels::BUILDER_STRING_MAPPING[builder_str_value].new
  end

  def service
    if aca_individual? && is_individual_market_enabled?
      Notifier::Services::IndividualNoticeService.new
    elsif is_shop_or_fehb_market_enabled?
      Notifier::Services::ShopNoticeService.new
    end
  end

  def aca_individual?
    market_kind == :aca_individual
  end
end
