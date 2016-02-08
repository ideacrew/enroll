module EventsHelper
  def xml_iso8601_for(date_time)
    return nil if date_time.blank?
    date_time.iso8601
  end

  def simple_date_for(date_time)
    return nil if date_time.blank?
    date_time.strftime("%Y%m%d")
  end

  def vocab_relationship_map(rel)
    rel.gsub(" ", "_")
  end

  def office_location_address_kind(kind)
    if kind == "primary"
      "work"
    elsif kind == "branch"
      "work"
    else
      kind
    end
  end
end
