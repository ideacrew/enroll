# frozen_string_literal: true

module Queries
  # Datatable query for eligibilities in outtstanding verification state
  class EligibilitiesOutstandingVerificationDatatableQuery
    include ::ParseDateHelper
    # Helpers driving the sort query
    module Sorter
      # @method sort_query(query, order_by)
      # Performs the sort operation on the query based on the order_by params.
      # When the order_by params contain the 'name' or 'verification_due' column key, perform sort via an aggregation.
      # Otherwise, perform the sort operation directly on the Mongoid query.
      #
      # @param [MongoidCriteria] query The query to be sorted.
      # @param [Hash] order_by The sort column key and direction param hash.
      #
      # @return [Array<Family>|Mongoid::Criteria] The sorted array of Family objects if using an aggregated sort, or a Mongoid::Criteria object if using a direct sort.
      def sort_query(query, order_by)
        case order_by.keys.first
        when 'name', 'verification_due'
          aggregate_sort(query, order_by) # perform the sort via an aggregation and return the sorted array of Family objects
        else
          query.order_by(order_by) # perform the sort directly on the Mongoid query and return the sorted Mongoid::Criteria object
        end
      end

      # @method aggregate_sort(scope, order_by)
      # Perform the sort operation on the query based on the order_by params via an aggregation.
      #
      # @param [MongoidCriteria] scope The query to be sorted.
      # @param [Hash] order_by The sort column key and direction param hash.
      #
      # @return [Array<Family>|Mongoid::Criteria] The sorted array of Family objects if using an aggregated sort, or a Mongoid::Criteria object if using a direct sort.
      def aggregate_sort(query, order_by)
        pipeline = pipeline_for_sort_column(order_by)
        # aggregate returns json, so we need to transform back to Family objects for the mongoid datatable to handle
        ids = query.collection.aggregate(pipeline).map { |doc| doc["_id"] }
        families = Family.where(:_id.in => ids).to_a
        ids.map { |id| families.find { |family| family.id == id } }
      end

      # @method pipeline_for_sort_column(order_by)
      # Construct the aggregation pipeline for sorting the query based on the order_by params.
      #
      # @param [Hash] order_by The sort column key and direction param hash.
      #
      # @return [Array] The pipeline array containing the aggregation stages for the order_by column key.
      def pipeline_for_sort_column(order_by)
        sort_column, sort_direction = order_by.to_a.flatten
        sort_direction = sort_direction == :asc ? 1 : -1
        base_pipeline = case sort_column
                        when 'name'
                          Family.sort_by_eligible_primary_full_name_pipeline(sort_direction)
                        when 'verification_due'
                          Family.sort_by_eligible_verification_earliest_due_date_pipeline(sort_direction)
                        end
        base_pipeline + [{:$skip => @skip}, {:$limit => @limit}]
      end
    end

    include Sorter

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
