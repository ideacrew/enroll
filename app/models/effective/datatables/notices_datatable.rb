module Effective
  module Datatables
    class NoticesDatatable < Effective::MongoidDatatable
      include Config::SiteModelConcern

      datatable do

        bulk_actions_column do
          bulk_action 'Delete', notifier.delete_notices_notice_kinds_path, data: { confirm: "This will remove selected notices. Are you sure?", no_turbolink: true }
          # bulk_action 'Download', notifier.download_notices_notice_kinds_path, target: '_blank'
        end

        table_column :market_kind, :proc => Proc.new { |row|
          row.market_kind.to_s.titleize
        }, :filter => false, :sortable => true
        table_column :mpi_indicator, :proc => Proc.new { |row|
          prepend_glyph_to_text(row)
        }, :filter => false, :sortable => false
        table_column :title, :proc => Proc.new { |row|
          link_to row.title, notifier.preview_notice_kind_path(row), target: '_blank'
        }, :filter => false, :sortable => false
        table_column :description, :proc => Proc.new { |row|
          row.description
        }, :filter => false, :sortable => false
        table_column :recipient, :proc => Proc.new { |row|
         row.recipient_klass_name.to_s.titleize
        }, :filter => false, :sortable => false
        table_column :last_updated_at, :proc => Proc.new { |row|
         row.updated_at.in_time_zone('Eastern Time (US & Canada)').strftime('%m/%d/%Y %H:%M')
        }, :filter => false, :sortable => false
        table_column :actions, :width => '50px', :proc => Proc.new { |row|
          dropdown = [
           ['Edit', notifier.edit_notice_kind_path(row), 'ajax']
          ]
          render partial: 'datatables/shared/dropdown', locals: {dropdowns: dropdown, row_actions_id: "notice_actions_#{row.id}"}, formats: :html
        }, :filter => false, :sortable => false
      end

      def collection
        return @notices_collection if defined? @notices_collection
        notices = Notifier::NoticeKind.all
        notices = cast_notice_filter_market_kind(attributes, notices)
        @notices_collection = notices
      end

      def cast_notice_filter_market_kind(params, current_scope)
        case params[:market_kind].to_s
        when "individual"
          current_scope.individual
        when "shop"
          current_scope.shop
        else
          current_scope
        end
      end

      def nested_filter_definition
        return unless is_shop_or_fehb_market_enabled?

        filters = {
        market_kind:
         [
           {scope:'all', label: 'All'},
           {scope:'individual', label: 'Individual'},
           {scope:'shop', label: 'Shop'}
         ],
        top_scope: :market_kind
        }
      end

      def authorized?(current_user, _controller, _action, _resource)
        return false if current_user.blank?

        Notifier::NoticeKindPolicy.new(current_user, nil).index?
      end
    end
  end
end
