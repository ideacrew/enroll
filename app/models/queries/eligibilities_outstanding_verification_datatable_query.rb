# frozen_string_literal: true

module Queries
  # Datatable query for eligibilities in outtstanding verification state
  class EligibilitiesOutstandingVerificationDatatableQuery
    include ::ParseDateHelper

    attr_reader :search_string, :custom_attributes

    def datatable_search(string)
      @search_string = string
      self
    end

    def initialize(attributes)
      @custom_attributes = attributes
    end

    def person_search(search_string)
      klass if search_string.blank?
    end

    def build_scope
      family = klass
      family = family.send(@custom_attributes[:documents_uploaded]) if @custom_attributes[:documents_uploaded].present?
      if @custom_attributes[:custom_datatable_date_from].present? & @custom_attributes[:custom_datatable_date_to].present?
        from_date = parse_date(@custom_attributes[:custom_datatable_date_from])
        to_date = parse_date(@custom_attributes[:custom_datatable_date_to])
        family = family.eligibility_due_date_in_range(from_date, to_date)
      end

      #add other scopes here
      return family if @search_string.blank? || @search_string.length < 2

      family_scope = family.eligibility_determination_family_member_search(@search_string.to_s.strip)
      return family_scope if @order_by.blank?
      family_scope.order_by(@order_by)
    end

    def skip(num)
      @skip = num
      self
    end

    def limit(num)
      @limit = num
      self
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

    def sort_by_name_col(scope, sort_direction)
      # Family name column is calculated using eligibility_determination.subjects.full_name/last_name on the primary
      # use an aggregation to access the fields and perform the sort

      # build the pipeline to sort by primary applicant's full name
      sort_direction == :asc ? 1 : -1
      pipeline = Family.sort_by_subject_primary_full_name_pipeline(sort_direction)
      pipeline += [{:$skip => @skip}, {:$limit => @limit}]
      # aggregate returns json, so we need to transform back to Family objects for the mongoid datatable to handle
      ids = scope.collection.aggregate(pipeline).map { |doc| doc["_id"] }
      families = Family.where(:_id.in => ids).to_a
      ids.map { |id| families.find { |family| family.id == id } }
    end

    def build_query
      limited_scope = build_scope
      if @order_by
        sort_query(limited_scope, @order_by)
      else
        limited_scope.skip(@skip).limit(@limit)
      end
    end

    def each(&block)
      return to_enum(:each) unless block

      build_query.each(&block)
    end

    def each_with_index(&block)
      return to_enum(:each_with_index) unless block

      build_query.each_with_index(&block)
    end

    def order_by(var)
      @order_by = var
      self
    end

    def klass
      return @klass if defined? @klass

      @klass = Family.eligibility_determination_outstanding_verifications
    end

    def size
      build_scope.count
    end

  end
end
