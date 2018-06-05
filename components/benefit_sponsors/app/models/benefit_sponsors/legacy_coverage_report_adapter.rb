module BenefitSponsors
  class LegacyCoverageReportAdapter
    def initialize(criterias)
      @criterias = criterias
    end

    def each
      @criterias.each do |criteria|
        s_benefit, query = criteria
        query_ids = query.lazy.map { |q| q["hbx_enrollment_id"] }
        calculator = HbxEnrollmentSponsorEnrollmentCoverageReportCalculator.new(s_benefit, query_ids)
        calculator.each do |calc_result|
          yield calc_result
        end
      end
    end

    def count
      return 0 if criteria.empty?
      @count ||= begin
                   @criterias.inject(0) do |acc, criteria|
                     acc + criteria.last.count
                   end
                 end
    end

    def order_by(v={})
      self
    end

    def skip(num)
      self
    end

    def limit(num)
      self
    end
  end
end
