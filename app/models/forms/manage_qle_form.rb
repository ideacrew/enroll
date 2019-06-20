module Forms
  class ManageQleForm
  	include Virtus.model

    attribute :market_kind, String
    attribute :create, Boolean
    attribute :modify, Boolean
    attribute :deactivate, Boolean
    attribute :qle_options, Array

    def self.for_new(params)
      new(params)
    end

    def self.for_create(params)
      new(params)
    end

  end
end