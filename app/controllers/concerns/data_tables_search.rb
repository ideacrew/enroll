module DataTablesSearch

  def search_families(search_str, all_families)
    if search_str.blank?
      all_families
    else
      person_ids = Person.search(search_str).pluck(:id)
      all_families.where({
        "family_members.person_id" => {"$in" => person_ids}
      })
    end
  end

  def input_sort_request
    if params[:order].present? && params[:order]["0"][:column] == "4"
      order = params[:order]["0"][:dir]
      return :min_verification_due_date_on_family, order
    elsif params[:order].present? && params[:order]["0"][:column] == "6"
      order = params[:order]["0"][:dir]
      return :review_status, order
    end
    return nil, nil
  end

  def sorted_families(sorted_by, order, dt_query, families)
    case sorted_by
    when :min_verification_due_date_on_family
      order == "asc" ? asc_due_date(dt_query) : desc_due_date(dt_query)
    when :review_status
      order == "asc" ? asc_review_status(dt_query) : desc_review_status(dt_query)
    else
      paginated_families(dt_query, families)
    end
  end

  def paginated_families(dt_query, families)
    families.skip(dt_query.skip).limit(dt_query.take)
  end

  def asc_due_date(dt_query)
    a = Family.collection.aggregate([
          {"$match" => {"households.hbx_enrollments.aasm_state" => "enrolled_contingent"}},
          {"$group" => {
            "_id" => { 
              "due_date" => {"$ifNull" => ["$min_verification_due_date", Date.today + 95.days]},
              "family_id" => "$_id"
              }
            }
          },
          {"$sort" => {"_id.due_date" => 1}},
          {"$skip" => dt_query.skip},
          {"$limit" => dt_query.take}
          ], :allow_disk_use => true).map do |record|
            record["_id"]
          end

    family_ids = a.map(&:values).map(&:last)
    families = []
    family_ids.each { |_id| families << Family.find(_id)}
    families
  end

  def desc_due_date(dt_query)
    a = Family.collection.aggregate([
          {"$match" => {"households.hbx_enrollments.aasm_state" => "enrolled_contingent"}},
          {"$group" => {
            "_id" => { 
              "due_date" => {"$ifNull" => ["$min_verification_due_date", Date.today + 95.days]},
              "family_id" => "$_id"
              }
            }
          },
          {"$sort" => {"_id.due_date" => -1}},
          {"$skip" => dt_query.skip},
          {"$limit" => dt_query.take}
          ], :allow_disk_use => true).map do |record|
            record["_id"]
          end

    family_ids = a.map(&:values).map(&:last)
    families = []
    family_ids.each { |_id| families << Family.find(_id)}
    families
  end

  def asc_review_status(dt_query)
    b = Family.collection.aggregate([
          {"$unwind" => "$households"},
          {"$unwind" => "$households.hbx_enrollments"},
          {"$match" => {"households.hbx_enrollments.aasm_state" => "enrolled_contingent"}},
          {"$group" => {
            "_id" => { 
              "status" => "$households.hbx_enrollments.review_status",
              "family_id" => "$_id"
              }
            }
          },
          {"$sort" => {"_id.status" => 1}},
          {"$skip" => dt_query.skip},
          {"$limit" => dt_query.take}
          ], :allow_disk_use => true).map do |record|
            record["_id"]
          end

    family_ids = b.map(&:values).map(&:last)
    families = []
    family_ids.each { |_id| families << Family.find(_id)}
    families
  end

  def desc_review_status(dt_query)
    b = Family.collection.aggregate([
          {"$unwind" => "$households"},
          {"$unwind" => "$households.hbx_enrollments"},
          {"$match" => {"households.hbx_enrollments.aasm_state" => "enrolled_contingent"}},
          {"$group" => {
            "_id" => { 
              "status" => "$households.hbx_enrollments.review_status",
              "family_id" => "$_id"
              }
            }
          },
          {"$sort" => {"_id.status" => -1}},
          {"$skip" => dt_query.skip},
          {"$limit" => dt_query.take}
          ], :allow_disk_use => true).map do |record|
            record["_id"]
          end

    family_ids = b.map(&:values).map(&:last)
    families = []
    family_ids.each { |_id| families << Family.find(_id)}
    families
  end
end
