module Forms
  class ManageQleForm
  	include Virtus.model
    
    attribute :action, String
    attribute :market_kind, String
    attribute :new_qle, Boolean
    attribute :modify_qle, Boolean
    attribute :deactivate_qle, Boolean
    attribute :qle_options, Array

    def self.for_new(params)
      new(params)
    end

    def self.for_create(params)
      new(params)
    end

    def self.for_edit(params)
      new(params)
    end

    def self.for_deactivate(params)
      new(params)
    end
  end
end
