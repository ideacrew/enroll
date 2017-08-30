module Notifier
  class MergeDataModels::BrokerProfile

    include Virtus.model
    include ActiveModel::Model
    include Notifier::MergeDataModels::TokenBuilder


    def collections
      %w{addresses}
    end

    def conditions
      %w{broker_present?}
    end

    def broker_present?
      self.broker.present?
    end
  end
end