module Queries
  class VerificationsDatatableQuery < ShopMonthlyEnrollments

    def initialize(dt_query, filter_param=nil)
      @skip = dt_query.skip
      @take = dt_query.take
      @search_str = dt_query.search_string
      @filter = filter_param
      @pipeline = []
    end

    def all_families
      Family.by_enrollment_individual_market.where(:'households.hbx_enrollments.aasm_state' => "enrolled_contingent")
    end

    def query_families
      add({"$match" => {"households.hbx_enrollments.aasm_state" => "enrolled_contingent"}})
      self
    end

    def query_on_min_verification_due_date
      add({"$group" => {
            "_id" => { 
              "due_date" => {"$ifNull" => ["$min_verification_due_date", Date.today + 95.days]},
              "family_id" => "$_id"
              }
          }})
      self
    end

    def sort_asc
      add({"$sort" => {"_id.due_date" => 1}})
      self
    end

    def sort_desc
      add({"$sort" => {"_id.due_date" => -1}})
      self
    end

    def skip
      add({"$skip" => @skip})
      self
    end

    def take
      add({"$limit" => @take})
      self
    end

    def search_and_filter
      return all_families if (@search_str.blank? && @filter.blank?)
      return all_families.send("with_#{@filter}_verifications") if (@search_str.blank? && @filter.present? )
      return all_families.where({"family_members.person_id" => {"$in" => get_person_ids}}) if (@search_str.present? && @filter.blank?)
      return all_families.send("with_#{@filter}_verifications").where({"family_members.person_id" => {"$in" => get_person_ids}})
    end

    def sort_with_search_key
      return self if @search_str.blank?
      add({ "$match" => {"family_members.person_id" => {"$in" => get_person_ids}}})
      self
    end

    def sort_with_filter
      return self if @filter.blank?
      status = @filter == "partial" ? "in review" : (@filter == "all" ? "ready" : "incomplete")

      add({"$unwind" => '$households'})
      add({"$unwind" => '$households.hbx_enrollments'})
      add({"$match" => {"households.hbx_enrollments.aasm_state" => "enrolled_contingent" }})
      add({"$match" => {"households.hbx_enrollments.review_status" => status}})

      self
    end

    def get_person_ids
      Person.search(@search_str).pluck(:id)
    end
  end
end
