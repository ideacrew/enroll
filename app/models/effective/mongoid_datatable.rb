module Effective
  class MongoidDatatable < Effective::Datatable
    include ::L10nHelper
    include ::DropdownHelper

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

    # map legacy dropdowns to BS4 dropdowns
    # NOTE: should remove & refactor dropdowns from callers once BS4 is turned on
    def map_dropdown(options)
      options.each { |option| option[2] = dropdown_type(option[2]) }
      options.select! { |option| option[2].present? }
      construct_options(options)
    end

    private

    # map legacy dropdown types to BS4 dropdown types
    # NOTE: should remove & update dropdown types from callers once BS4 is turned on
    def dropdown_type(legacy_type)
      case legacy_type
      when "static"
        :default
      when "ajax"
        :remote
      when "edit_aptc_csr"
        :remote_edit_aptc_csr
      when "disabled"
        nil # disabled dropdowns are not rendered on BS4
      end
    end
  end
end
