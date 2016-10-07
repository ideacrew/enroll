module Effective
  class MongoidDatatable
    protected

    def array_tool
      @array_tool ||= MongoidDatatableTool.new(self, table_columns.select { |_, col| col[:array_column] })
    end

    def array_collection?
      true
    end
  end
end
