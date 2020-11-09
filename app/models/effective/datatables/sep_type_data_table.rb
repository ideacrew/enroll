# frozen_string_literal: true

module Effective
  module Datatables
    class SepTypeDataTable < Effective::MongoidDatatable
      include Config::AcaModelConcern
      datatable do
        table_column :title, :label => l10n("datatables.sep_type_data_table.title"), :proc => proc { |row| link_to(row.title, edit_exchanges_manage_sep_type_path(row.id), data: {turbolinks: false})}, :filter => false, :sortable => true
        table_column :Market, :label => l10n("datatables.sep_type_data_table.market"), :proc => proc { |row|  market_kind(row)}, :filter => false, :sortable => false
        table_column :start_date, :label => l10n("datatables.sep_type_data_table.start_date"), :proc => proc { |row| row.start_on }, :filter => false, :sortable => false
        table_column :state, :label => l10n("datatables.sep_type_data_table.state"), :proc => proc { |row| row.aasm_state}, :filter => false, :sortable => false
        table_column :published_by, :label => l10n("datatables.sep_type_data_table.published_by"), :proc => proc { |row|  find_user(row)}, :filter => false, :sortable => false
        table_column :actions, :width => '50px', :proc => proc { |row|
          dropdown = [
              [l10n("datatables.sep_type_data_table.expire"), sep_type_to_expire_exchanges_manage_sep_types_path(qle_id: row.id, qle_action_id: "sep_type_actions_#{row.id}"),
               can_expire_sep_type?(row, pundit_allow(QualifyingLifeEventKind, :can_manage_qles?))]
          ]
          if can_clone_sep_type?(row, pundit_allow(QualifyingLifeEventKind, :can_manage_qles?))
            dropdown += [
              [l10n("datatables.sep_type_data_table.clone"), clone_exchanges_manage_sep_types_path(id: row.id), 'static']
            ]
          end
          render partial: 'datatables/shared/dropdown', locals: {dropdowns: dropdown, row_actions_id: "sep_type_actions_#{row.id}"}, formats: :html
        }, :filter => false, :sortable => false
      end

      def collection
        @qles = Queries::SepTypeDatatableQuery.new(attributes) unless (defined? @qles) && @qles.present?
        @qles
      end

      def global_search?
        true
      end

      def market_kind(qle)
        if qle.shop?
          "SHOP"
        else
          qle.fehb? ? "Congress" : qle.market_kind.capitalize
        end
      end

      def can_expire_sep_type?(qle, allow)
        return 'disabled' unless allow
        [:active, :expire_pending].include?(qle.aasm_state) ? 'ajax' : 'disabled'
      end

      def find_user(qle)
        user_id = (qle.published_by || qle.created_by)
        User.find(user_id).person.full_name
      rescue StandardError => _e
        "admin"
      end

      def can_clone_sep_type?(qle, allow)
        allow && [:active, :expire_pending, :expired].include?(qle.aasm_state)
      end

      def nested_filter_definition
        manage_qles_tab = [
          {scope: 'all', label: l10n("datatables.sep_type_data_table.all")},
          {scope: 'shop_qles', label: l10n("datatables.sep_type_data_table.shop_qles"), subfilter: :employer_options},
          {scope: 'fehb_qles', label: l10n("datatables.sep_type_data_table.fehb_qles"), subfilter: :congress_options}
        ]
        manage_qles_tab.insert(1, {scope: 'ivl_qles', label: l10n("datatables.sep_type_data_table.ivl_qles"), subfilter: :individual_options}) if individual_market_is_enabled?
        {
          employer_options: [
            {scope: 'all', label:  l10n("datatables.sep_type_data_table.all")},
            {scope: 'shop_active_qles', label: l10n("datatables.sep_type_data_table.active")},
            {scope: 'shop_inactive_qles', label: l10n("datatables.sep_type_data_table.inactive")},
            {scope: 'shop_draft_qles', label: l10n("datatables.sep_type_data_table.draft")}
          ],
          congress_options: [
            {scope: 'all', label: 'All'},
            {scope: 'fehb_active_qles', label: l10n("datatables.sep_type_data_table.active")},
            {scope: 'fehb_inactive_qles', label: l10n("datatables.sep_type_data_table.inactive")},
            {scope: 'fehb_draft_qles', label: l10n("datatables.sep_type_data_table.draft")}
          ],
          individual_options: [
            {scope: 'all', label: 'All'},
            {scope: 'ivl_active_qles', label: l10n("datatables.sep_type_data_table.active")},
            {scope: 'ivl_inactive_qles', label: l10n("datatables.sep_type_data_table.inactive")},
            {scope: 'ivl_draft_qles', label: l10n("datatables.sep_type_data_table.draft")}
          ],
          manage_qles: manage_qles_tab,
          top_scope: :manage_qles
        }
      end
    end
  end
end
