module Effective
  class MongoidDatatable < Effective::Datatable
    include ::L10nHelper

    def global_search_method
      :datatable_search
    end

    protected

    def table_tool 
      @table_tool ||= MongoidDatatableTool.new(self, table_columns.reject { |_, col| col[:array_column] })
    end

    def active_record_collection?
      @active_record_collection ||= true
    end

    def authorized?(_current_user, _controller, _action, _resource)
      false
    end
  end
end
