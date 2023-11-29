# frozen_string_literal: true
# Usage: bundle exec rails runner script/fix_invalid_county_information_for_dependents.rb

def same_address_with_primary(family_member, primary_person, address_type)
  member = family_member.person
  compare_keys = ["address_1", "address_2", "city", "state", "zip", "kind"]
  member_address = member.send("#{address_type}_address")
  primary_address = primary_person.send("#{address_type}_address")
  if member_address && primary_address
    member_selected_attributes = member_address.attributes.select {|k, _v| compare_keys.include? k}
    capitalized_member_attributes = member_selected_attributes.transform_values { |value| value.capitalize }

    primary_selected_attributes = primary_address.attributes.select {|k, _v| compare_keys.include? k}
    capitalized_primary_attributes = primary_selected_attributes.transform_values { |value| value.capitalize }

    capitalized_member_attributes == capitalized_primary_attributes
  end
end

Family.all.no_timeout.each do |family|
  family_members = family.family_members
  primary_person = family.primary_person

  ['home', 'mailing'].each do |address_type|
    primary_address = primary_person.send("#{address_type}_address")
    next if primary_address.blank?
    next if primary_address.state != "ME"
    next if primary_address.kind == 'home' && address_type == 'mailing'

    family_members.where(is_primary_applicant: false).each do |member|
      person = member.person
      if person.present? && same_address_with_primary(member, primary_person, address_type)
        address = person.send("#{address_type}_address")

        if primary_address.county&.capitalize != address&.county&.capitalize
          address.update_attributes!(county: primary_address.county)
          address.save!
          person.save!
        end
      end
    end
  end
rescue => e
  puts "Unable to process family #{family.hbx_assigned_id} due to error #{e}"
end
