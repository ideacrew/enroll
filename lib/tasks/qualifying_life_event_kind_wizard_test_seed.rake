# For Ex: RAILS_ENV=production bundle exec rake qle_kind_wizard_test_seed:seed_qle_kind_data
# This is to provide QLE Kinds ready to edit, deactivate, and display as SEP for testing
namespace :qle_kind_wizard_test_seed do
  desc "Upload invoice to and associate with employer"
  task :seed_qle_kind_data => :environment do
    # For Editing
    editable_qle_kind = QualifyingLifeEventKind.find_or_create_by(
      title: "Yet another new birth",
      tool_tip: "Household adds a new family member due to marriage, birth, adoption, placement for adoption, or placement in foster care",
      action_kind: "add_benefit",
      is_active: false,
      reason: "birth",
      edi_code: "99-YET-ANOTHER-NEW-BIRTH", 
      market_kind: "shop", 
      effective_on_kinds: ["date_of_event"],
      pre_event_sep_in_days: 0,
      post_event_sep_in_days: 30, 
      is_self_attested: true, 
      date_options_available: false,
      ordinal_position: 25,
    )
    puts("Editable QLE Kind present.") if editable_qle_kind.present?
    # For Deactivation
    deactivatable_qle_kind = QualifyingLifeEventKind.find_or_create_by!(
      title: "Federal Government order to provide coverage for someone",
      end_on: nil,
      tool_tip: "",
      action_kind: "add_member",
      market_kind: "shop",
      event_kind_label: "Date that court orders that coverage starts",
      ordinal_position: 100,
      reason: "court_order",
      edi_code: " ",
      effective_on_kinds: ["exact_date"],
      pre_event_sep_in_days: 0,
      post_event_sep_in_days: 60,
      is_self_attested: false,
      date_options_available: false,
    )
    puts("Deactivatable QLE Kind present.") if deactivatable_qle_kind.present?
    # For display on the families home page/wherever SEP is showed
    individual_self_attested_qle_kind = QualifyingLifeEventKind.find_or_create_by!(
      title: "Federal Government order to provide coverage for someone",
      tool_tip: "",
      action_kind: "add_member",
      market_kind: "shop",
      event_kind_label: "Date that court orders that coverage starts",
      ordinal_position: 100,
      reason: "court_order",
      edi_code: " ",
      effective_on_kinds: ["exact_date"],
      pre_event_sep_in_days: 0,
      post_event_sep_in_days: 60,
      is_self_attested: true,
      visible_to_customer: true,
      date_options_available: false,
    )
    puts("Individual self attested QLE Kind present.") if individual_self_attested_qle_kind.present?
  end
end
