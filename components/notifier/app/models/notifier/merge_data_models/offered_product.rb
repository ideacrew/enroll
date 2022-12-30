module Notifier
  class MergeDataModels::OfferedProduct
    include Virtus.model
    include ActionView::Helpers::NumberHelper

    attribute :product_name, String
    attribute :enrollments, Array[MergeDataModels::Enrollment]

    def self.stubbed_object
      offered_product = Notifier::MergeDataModels::OfferedProduct.new({product_name: 'Aetna SILVER'})
      offered_product.enrollments = [Notifier::MergeDataModels::Enrollment.stubbed_object]
      offered_product
    end

    def covered_subscribers
      enrollments.count
    end

    def covered_dependents
      enrollments.sum{|enrollment| enrollment.dependents.count }
    end

    def total_charges
      number_to_currency(enrollments.sum{|enrollment| enrollment.premium_amount.to_f })
    end

    def total_charges_after_subsidy
      number_to_currency(enrollments.sum{|enrollment| enrollment.premium_amount.to_f } - enrollments.sum{|enrollment| enrollment.eligible_child_care_subsidy.to_f })
    end

    def total_employer_responsible_amount
      number_to_currency(enrollments.sum{|enrollment| enrollment.employer_responsible_amount.to_f })
    end
  end
end
