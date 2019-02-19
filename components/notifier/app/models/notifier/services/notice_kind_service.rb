module Notifier
  class Services::NoticeKindService

    attr_accessor :market_kind

    def initialize(market_kind)
      @market_kind = market_kind.to_sym
    end

    def placeholders
      service.placeholders
    end

    def configurations
      service.configurations
    end

    def tokens
      service.tokens
    end

    def recipients
      service.recipients
    end

    def service
      if aca_individual?
        Notifier::Services::IndividualNoticeService.new
      else
        Notifier::Services::ShopNoticeService.new
      end
    end

    def aca_individual?
      market_kind == :aca_individual
    end
  end
end