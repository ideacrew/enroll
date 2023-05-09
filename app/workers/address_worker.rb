# frozen_string_literal: true

# Class to build address worker to perform later
class AddressWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform(params)
    Operations::People::Addresses::Compare.new.call(params)
  end
end
