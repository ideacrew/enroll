# frozen_string_literal: true

module Queries
  # Helper which provides the sort_query method to sort the query based on the order_by params.
  # The sort_query method performs the sort operation on the query based on the order_by params, allowing for aggregated or direct sorts.
  module Sorter
    # @method sort_query(query, order_by)
    # Performs the sort operation on the query based on the order_by params.
    # When the order_by params contain a column key which is in the aggregatable_columns hash, perform sort via an aggregation.
    # Otherwise, perform the sort operation directly on the Mongoid query.
    #
    # @param [MongoidCriteria] query The query to be sorted.
    # @param [Hash] order_by The sort column key and direction param hash.
    #
    # @return [Array<Klass>|Mongoid::Criteria] The sorted array of Klass objects if using an aggregated sort, or a Mongoid::Criteria object if using a direct sort.
    def sort_query(query, order_by)
      if aggregatable_columns&.key?(@order_by.keys.first)
        aggregate_sort(query, order_by) # perform the sort via an aggregation and return the sorted array of Klass objects
      else
        query.order_by(order_by) # perform the sort directly on the Mongoid query and return the sorted Mongoid::Criteria object
      end
    end

    # @method paginate(scope)
    # Paginate the query based on the skip and limit instance variables if the scope is a Mongoid::Criteria.
    # If it is not a Mongoid::Criteria, we can assume it is an array of `klass` objects sorted AND paginated already, so return it as is.
    #
    # @param [Array<Klass>|Mongoid::Criteria] scope The query to be paginated.
    #
    # @return [Array<Klass>|Mongoid::Criteria] The paginated scope.
    def paginate(scope)
      return scope unless scope.is_a?(Mongoid::Criteria)
      scope.skip(@skip).limit(@limit)
    end

    private

    def aggregatable_columns
      self.class::AGGREGATABLE_COLUMNS if self.class.const_defined?(:AGGREGATABLE_COLUMNS)
    end

    # @method aggregate_sort(scope, order_by)
    # Perform the sort operation on the query based on the order_by params via an aggregation.
    #
    # @param [MongoidCriteria] scope The query to be sorted.
    # @param [Hash] order_by The sort column key and direction param hash.
    #
    # @return [Array<Klass>|Mongoid::Criteria] The sorted array of `klass` records if using an aggregated sort, or a Mongoid::Criteria object if using a direct sort.
    def aggregate_sort(query, order_by)
      pipeline = pipeline_for_sort_column(order_by)
      # aggregate returns json, so we need to transform back to Klass objects for the mongoid datatable to handle
      sorted_ids = query.collection.aggregate(pipeline).map(&:values).map(&:first)
      records = klass.find(sorted_ids)
      sorted_ids.map { |id| records.find { |record| record.id == id } }
    end

    # @method pipeline_for_sort_column(order_by)
    # Construct the aggregation pipeline for sorting and paginating the query based on the order_by params.
    #
    # @param [Hash] order_by The sort column key and direction param hash.
    #
    # @return [Array] The pipeline array containing the aggregation stages for the order_by column key.
    def pipeline_for_sort_column(order_by)
      sort_column, sort_direction = order_by.to_a.flatten
      sort_direction = sort_direction == :asc ? 1 : -1

      base_pipeline = klass.send(aggregatable_columns[sort_column], sort_direction)
      base_pipeline + [{:$project => { '_id': 1 }}, {:$skip => @skip}, {:$limit => @limit}]
    end
  end
end