# frozen_string_literal: true

# Class to publish CRM gateway
class CrmWorker
  include Sidekiq::Worker
  include CableReady::Broadcaster

  def perform(record_id, class_name, method_name)
    class_name.constantize.find(record_id).send(method_name)
  end
end
