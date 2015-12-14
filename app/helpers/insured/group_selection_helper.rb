module Insured
  module GroupSelectionHelper
    def can_shop_individual?(person)
      @person.try(:has_active_consumer_role?)
    end

    def can_shop_shop?(person)
      @person.try(:has_active_employee_role?)
    end

    def can_shop_both_markets?(person)
      can_shop_individual?(person) && can_shop_shop?(person)
    end
  end
end
