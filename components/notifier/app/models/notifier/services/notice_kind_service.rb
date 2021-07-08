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
    @model_builder = builder_str.constantize.new
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
