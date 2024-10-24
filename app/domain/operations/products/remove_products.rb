# frozen_string_literal: true

module Operations
  module Products
      # This operation updates benefit packages, renewal_product_ids, and removes products
    class RemoveProducts
      include Dry::Monads[:do, :result]
      def call(params)
        date, products              = yield validate(params)
        _update_benefit_packages    = yield update_benefit_packages(date, products)
        _update_renewal_product_ids = yield update_renewal_product_ids(products)
        _destroy_products           = yield destroy_products(products)

        Success("Updated Benefit Packages and Removed Products")
      end

      private

      def validate(params)
        return Failure("Missing date") if params[:date].blank?
        return Failure("Incorrect date format") if params[:date].to_s.match?(/\d{4}-\d{2}-\d{2}/)
        return Failure("Missing products") if params[:products].blank?
        Success([params[:date], params[:products]])
      end

      def update_benefit_packages(date, products)
        product_ids = products.map(&:id)
        benefit_sponsorship = HbxProfile.current_hbx.benefit_sponsorship
        benefit_coverage_period = benefit_sponsorship.benefit_coverage_period_by_effective_date(date)
        return Failure("Benefit coverage period not found") if benefit_coverage_period.blank?
        return Failure("Benefit packages not found") if benefit_coverage_period.benefit_packages.blank?
        benefit_coverage_period.benefit_packages.each do |benefit_package|
          ids_to_remove = []
          benefit_ids = benefit_package.benefit_ids
          benefit_package.benefit_ids.each do |benefit_id|
            ids_to_remove << benefit_id if product_ids.include?(benefit_id)
          end
          updated_benefit_ids = benefit_ids - ids_to_remove
          benefit_package.update_attributes!(benefit_ids: updated_benefit_ids)
        end
        Success("Updated benefit packages")
      end

      def update_renewal_product_ids(products)
        product_ids = products.map(&:id)
        previous_products = BenefitMarkets::Products::Product.where(:'renewal_product_id'.in => product_ids)
        previous_products.each do |product|
          next unless product.present?
          product.update_attributes!(renewal_product_id: nil)
        end
        Success("Updated renewal product ids")
      end

      def destroy_products(products)
       products.destroy_all
       Success("Removed products")
      end
    end
  end
end