module IvlEligibilityAudits

  class AuditQueryCache

    def self.benefit_packages_for(year)
      hbx = HbxProfile.current_hbx
      return [] unless hbx
      bcps = hbx.benefit_sponsorship.benefit_coverage_periods
      bcp = bcps.detect { |bcp| bcp.start_on.year == year }
      return [] unless bcp
      bcp.benefit_packages.select do |bp|
        (bp.title.include? "health_benefits")
      end
    end

    def self.person_ids_for_audit_period_starting(audit_start_date)
      non_curam_ivl = Person.collection.aggregate([
        {"$project" => {
          _id: 1,
          created_at: 1,
          updated_at: 1,
          consumer_role: 1
        }},
        {"$match" => {
          "consumer_role._id" => {"$ne" => nil},
          "$or" => [
            {"created_at" => {"$gte" => audit_start_date}},
            {"created_at" => {"$lt" => audit_start_date}, "updated_at" => {"$gte" => audit_start_date}}
          ]
        }},
        {"$project" => {_id: 1}}
      ])
      non_curam_ivl.map do |rec|
        rec["_id"]
      end
    end

    def self.generate_family_map_for(ivl_person_ids)
      families_of_interest = Family.where(
        {"family_members.person_id" => {"$in" => ivl_person_ids}}
      )
      person_family_map = Hash.new { |h,k| h[k] = Array.new }
      families_of_interest.each do |fam|
        fam.family_members.each do |fm|
          person_family_map[fm.person_id] = person_family_map[fm.person_id] + [fam]
        end
      end
      person_family_map
    end
  end

  class EligibilityQueryCursor
    include Enumerable
  
    def initialize(person_ids, exclusions)
      @person_ids = person_ids
      @exclusions = exclusions
      @query_ids = person_ids.reject do |p_id|
        exclusions.include?(p_id.to_s)
      end
    end
  
    def each
      @query_ids.each do |p_id|
        pers = Person.where("_id" => {"$in" => [p_id]}).first
        yield pers
      end
    end
  end

end