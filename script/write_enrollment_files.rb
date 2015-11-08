controller = Events::PoliciesController.new

vs = VitalSign.new(
  start_at: DateTime.new(2015,10,27,23,43,0,'-4'),
  end_at: DateTime.new(2015,11,2,23,55,0,'-4')
)

PropertiesSlug = Struct.new(:reply_to, :headers)

ConnectionSlug = Struct.new(:policy_id) do
  def create_channel
    self
  end

  def default_exchange
    self
  end

  def close
  end

  def publish(payload, headers)
    File.open(File.join("policy_cvs", "#{policy_id}.xml"), 'w') do |f|
      f.puts payload
    end
  end
end

CSV.foreach("effective_date_changes.csv", headers: true) do |row|
   pid, *rest = row.fields
   properties_slug = PropertiesSlug.new("", {:policy_id => pid})
   controller.resource(ConnectionSlug.new(pid), "", properties_slug, "")
end
