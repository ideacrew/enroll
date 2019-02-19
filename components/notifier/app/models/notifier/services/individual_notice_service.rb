module Notifier
  class Services::IndividualNoticeService

    def placeholders
    end

    def configurations
    end

    def tokens
    end
    
    def recipients
      {
        "Consumer" => "Notifier::MergeDataModels::ConsumerRole"
      }
    end
  end
end