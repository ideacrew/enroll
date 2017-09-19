module Effective
  module Datatables
    class NoticesDatatable < Effective::MongoidDatatable
      datatable do

        bulk_actions_column do
          bulk_action 'Delete', notifier.delete_notices_notice_kinds_path, data: { confirm: "This will remove selected notices. Are you sure?", no_turbolink: true }
          # bulk_action 'Download', notifier.download_notices_notice_kinds_path, target: '_blank'
        end

        table_column :notice_number, :proc => Proc.new { |row|
          link_to row.notice_number, preview_notice_kind_path(row), target: '_blank'
        }, :filter => false, :sortable => false
        table_column :title, :proc => Proc.new { |row|
          link_to row.title, preview_notice_kind_path(row), target: '_blank'
        }, :filter => false, :sortable => false
        table_column :description, :proc => Proc.new { |row|
          row.description
        }, :filter => false, :sortable => false
        table_column :receipient, :proc => Proc.new { |row|
         row.receipient_class_name.to_s.titleize
        }, :filter => false, :sortable => false
        table_column :created_date, :proc => Proc.new { |row|
         row.created_at.strftime('%m/%d/%Y')
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
        @notices_collection = Notifier::NoticeKind.all
      end
    end
  end
end
