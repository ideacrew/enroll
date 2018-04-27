module BenefitMarkets
  class Products::PremiumTable
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :product,
                class_name: "Products::Product"

    field :age,                 type: Integer
    field :effective_period,    type: Range
    field :cost,                type: Float



    validates_presence_of :age, :start_on, :end_on, :cost


    # TODO: Test that cover includes begin and end date
    def cover?(effective_date)
    end



  end
end
