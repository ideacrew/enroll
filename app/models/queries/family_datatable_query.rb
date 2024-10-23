module Queries
  class FamilyDatatableQuery

    attr_reader :search_string, :custom_attributes

    def datatable_search(string)
      @search_string = string
      self
    end

    def initialize(attributes)
      @custom_attributes = attributes
      @skip = 0
      @limit = 25
    end

    def person_search search_string
      return Family if search_string.blank?
    end

    def sort_query(query, order_by)
      sort_column, sort_direction = order_by.to_a.flatten
      case sort_column
      when 'name'
        sort_by_name_col(query, sort_direction == :asc ? 1 : -1)
      else
        query
      end
    end

    def sort_by_name_col(query, sort_direction)
      # Family name column is calculated using Family.family_members.primary_applicant.full_name
      # primary_applicant is a Family model method, not a DB field
      # full_name is a Person model method, not a DB field
      # use an aggregation to perform the sort on name

      # build the pipeline to sort by primary applicant's full name
      pipeline = Family.sort_by_primary_full_name_pipeline(sort_direction)
      pipeline += [{:$skip => @skip}, {:$limit => @limit}]
      # aggregate returns json, so we need to transform back to Family objects for the mongoid datatable to handle
      ids = query.collection.aggregate(pipeline).map { |doc| doc["_id"] }
      families = Family.where(:_id.in => ids).to_a
      ids.map { |id| families.find { |family| family.id == id } }
    end

    def build_scope
      family = klass.where("is_active" => true)
      if @custom_attributes['families'] == 'by_enrollment_individual_market'
        family = family.all_enrollments
        family = family.by_enrollment_individual_market
      end
      if @custom_attributes['families'] == 'by_enrollment_shop_market'
        family = family.all_enrollments
        family = family.by_enrollment_shop_market
      end
      if @custom_attributes['families'] == 'non_enrolled'
        family = family.non_enrolled
      end
      if @custom_attributes['families'] == 'by_enrollment_coverall'
        resident_ids = Person.all_resident_roles.pluck(:_id)
        family = family.where('family_members.person_id' => {"$in" => resident_ids})
      end
      if @custom_attributes['employer_options'] == 'by_enrollment_renewing'
        family = family.by_enrollment_renewing
      end
      if @custom_attributes['employer_options'] == 'sep_eligible'
        family = family.sep_eligible
      end
      if @custom_attributes['employer_options'] == 'coverage_waived'
        family = family.coverage_waived
      end
      if @custom_attributes['individual_options'] == 'all_assistance_receiving'
        family = family.all_assistance_receiving
      end
      if @custom_attributes['individual_options'] == 'sep_eligible'
        family = family.sep_eligible
      end
      if @custom_attributes['individual_options'] == 'all_unassisted'
        family = family.all_unassisted
      end
      #add other scopes here
      return family if @search_string.blank? || @search_string.length < 2
      if EnrollRegistry[:display_external_id_in_family_datatable].enabled?
        ext_family = family.where(external_app_id: @search_string)
        return ext_family if ext_family.any?
      end
      person_id = build_people_id_criteria(@search_string)
      #Caution Mongo optimization on chained "$in" statements with same field
      #is to do a union, not an interactionl
      family.and('family_members.person_id' => {"$in" => person_id})
    end

    def build_people_id_criteria(s_string)
      clean_str = s_string.strip

      if clean_str =~ /[a-z]/i
        Person.collection.aggregate([
          {"$match" => {
              "$text" => {"$search" => clean_str}
          }.merge(Person.search_hash(clean_str))
          },
          {"$project" => {"first_name" => 1, "last_name" => 1, "full_name" => 1}},
          {"$sort" => {"last_name" => 1, "first_name" => 1}},
          {"$project" => {"_id" => 1}}
        ], {allowDiskUse: true}).map do |rec|
          rec["_id"]
        end
      else
        Person.search(s_string, nil, nil, true).pluck(:_id)
      end
    end

    def each
      return to_enum(:each) unless block_given?
      limited_scope, enrollment_cache = build_iteration_caches
      limited_scope.each do |fam|
        fam.set_admin_dt_enrollments(enrollment_cache[fam.id])
        yield fam
      end
    end

    def each_with_index
      return to_enum(:each_with_index) unless block_given?
      limited_scope, enrollment_cache = build_iteration_caches
      limited_scope.each_with_index do |fam, idx|
        fam.set_admin_dt_enrollments(enrollment_cache[fam.id])
        yield fam, idx if block_given?
      end
    end

    def skip(num)
      @skip = num
      self
    end

    def limit(num)
      @limit = num
      self
    end

    def order_by(var)
      @order_by = var
      self
    end

    def klass
      Family
    end

    def size
      build_scope.count
    end

    private

    def build_iteration_caches
      limited_scope = build_scope
      if @order_by
        limited_scope = sort_query(limited_scope, @order_by)
      else
        limited_scope = apply_skip(limited_scope)
        limited_scope = apply_limit(limited_scope)
      end
      family_ids = limited_scope.pluck(:id)
      enrollment_cache = load_enrollment_cache_for(family_ids)
      [limited_scope, enrollment_cache]
    end

    def load_enrollment_cache_for(family_ids)
      enrollment_cache = Hash.new { |h, k| h[k] = Array.new }
      HbxEnrollment.where(:family_id => {"$in" => family_ids}).without(:enrollment_members).each do |en|
        enrollment_cache[en.family_id] = enrollment_cache[en.family_id] + [en]
      end
      enrollment_cache
    end

    def apply_skip(scope)
      return scope unless @skip
      scope.skip(@skip)
    end

    def apply_limit(scope)
      return scope unless @limit
      scope.limit(@limit)
    end
  end
end
