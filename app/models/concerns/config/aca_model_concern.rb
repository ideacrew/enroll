module Config::AcaModelConcern
  extend ActiveSupport::Concern

  included do
    delegate :aca_state_abbreviation, :to => :class
    delegate :aca_state_name, :to => :class
  end

  class_methods do
    def aca_state_abbreviation
      Settings.aca.state_abbreviation
    end

    def aca_state_name
      Settings.aca.state_name
    end
  end
end
