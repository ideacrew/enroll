controller = Events::PoliciesController.new

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

  def publish(payload, properties)
    if properties[:headers][:return_status] == "200"
      File.open(File.join("policy_cvs", "#{policy_id}.xml"), 'w') do |f|
        f.puts payload
      end
    end
  end
end

hbx_ids = File.read("policies_to_pull.txt").split("\n").map(&:strip)

hbx_ids.each do |pid|
  pol = HbxEnrollment.by_hbx_id(pid).first
  if pol.nil?
    raise "NO SUCH POLICY #{pid}"
  end
  if pol.plan.blank?
    puts "No plan for policy ID #{pid}: plan ID #{pol.plan_id}"
    #  elsif pol.subscriber.nil?
    #    puts "No subscriber for Policy ID #{pid}"
  else
    properties_slug = PropertiesSlug.new("", {:policy_id => pid})
    begin 
      controller.resource(ConnectionSlug.new(pid), "", properties_slug, "")
    rescue => e
      puts pid.inspect
      puts e.backtrace.inspect
    end
  end
end
