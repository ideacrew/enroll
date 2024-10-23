# frozen_string_literal: true

# This module is a utility module that is used to display dropdowns with apostrophes.
module RelationshipDropdownHelper
  def display_relationship(relationship)
    relationship_mapping = {
      'domestic_partners_child' => "Domestic partner's child",
      'parents_domestic_partner' => "Parent's domestic partner"
    }

    relationship_mapping[relationship].try(:humanize) || relationship.try(:humanize)
  end
end
