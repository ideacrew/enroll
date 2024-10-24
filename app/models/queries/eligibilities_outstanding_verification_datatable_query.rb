# frozen_string_literal: true

module Queries
  # Datatable query for eligibilities in outtstanding verification state
  class EligibilitiesOutstandingVerificationDatatableQuery
    include ::ParseDateHelper
    include Sorter

    # Helpers driving the sort query

    attr_reader :search_string, :custom_attributes

    AGGREGATABLE_COLUMNS = {
      "name" => :sort_by_eligible_primary_full_name_pipeline,
      "verification_due" => :sort_by_eligible_verification_earliest_due_date_pipeline
    }.freeze

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
      family = klass.eligibility_determination_outstanding_verifications
      family = family.send(@custom_attributes[:documents_uploaded]) if @custom_attributes[:documents_uploaded].present?
      if @custom_attributes[:custom_datatable_date_from].present? & @custom_attributes[:custom_datatable_date_to].present?
        from_date = parse_date(@custom_attributes[:custom_datatable_date_from])
        to_date = parse_date(@custom_attributes[:custom_datatable_date_to])
        family = family.eligibility_due_date_in_range(from_date, to_date)
      end

      #add other scopes here
      return family if @search_string.blank? || @search_string.length < 2
      family.eligibility_determination_family_member_search(@search_string.to_s.strip)
    end

    def skip(num)
      @skip = num
      self
    end

    def limit(num)
      @limit = num
      self
    end

    def build_query
      limited_scope = build_scope
      limited_scope = sort_query(limited_scope, @order_by) if @order_by
      paginate(limited_scope)
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

      @klass = Family
    end

    def size
      build_scope.count
    end
  end
end
