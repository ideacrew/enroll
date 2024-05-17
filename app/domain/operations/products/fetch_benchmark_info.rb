# frozen_string_literal: true

# Operations::Products::FetchBenchmarkInfo.new.call({family: family, effective_date: effective_date})

module Operations
  module Products
    # This class is to fetch product premiums for slcsp & lcsp
    class FetchBenchmarkInfo
      include Dry::Monads[:do, :result]


      # @param [Date] effective_date
      # @param [Family] family

      def call(params)
        values                     = yield validate(params)
        premiums                   = yield fetch_premiums(values[:family], values[:effective_date])
        slcsp = yield fetch_slcsp(premiums)
        lcsp = yield fetch_lcsp(premiums)
        benchmark_info = yield fetch_benchmark_info(slcsp, lcsp)

        Success(benchmark_info)
      end

      private

      def validate(params)
        return Failure('Missing Family') if params[:family].blank?
        return Failure('Missing Effective Date') if params[:effective_date].blank?
        Success(params)
      end

      def fetch_premiums(family, effective_date)
        premiums = Operations::Products::Fetch.new.call({family: family, effective_date: effective_date})
        return Failure("unable to fetch silver_products for - #{address_combinations}") if premiums.failure?

        Success(premiums.value!)
      end

      def fetch_slcsp(premiums)
        slcsp = Operations::Products::FetchSlcsp.new.call({member_silver_product_premiums: premiums})
        return Failure("unable to fetch silver_products for - #{address_combinations}") if slcsp.failure?

        Success(slcsp.value!)
      end

      def fetch_lcsp(premiums)
        lcsp = Operations::Products::FetchLcsp.new.call({member_silver_product_premiums: premiums})
        return Failure("unable to fetch silver_products for - #{address_combinations}") if lcsp.failure?

        Success(lcsp.value!)
      end

      def fetch_benchmark_info(slcsp, lcsp)
        benchmark_info = slcsp.each_pair {|k, v| v.merge! lcsp[k] }
        Success(benchmark_info)
      end
    end
  end
end
