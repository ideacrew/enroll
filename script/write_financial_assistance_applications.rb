controller = Events::FinancialAssistanceController.new

PropertiesSlug = Struct.new(:reply_to, :headers)

ConnectionSlug = Struct.new(:family_id) do
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
      File.open(File.join("policy_cvs", "#{family_id}.xml"), 'w') do |f|
        f.puts payload
      end
    else
      File.open(File.join("policy_cvs", "#ERROR_#{family_id}.xml"), 'w') do |f|
        f.puts payload
      end
    end
  end
end

count = 0

family_ids = FinancialAssistance::Application.all.map(&:family_id)

family_ids.each do |fid|
  count += 1
  puts "#{Time.now} - #{count}/#{total_count}" if count % 100 == 0
  family = Family.find(fid)
  if family.nil?
    raise "NO SUCH FAMILY #{fid}"
  end
  begin
    properties_slug = PropertiesSlug.new("", {:family_id => fid})
    controller.resource(ConnectionSlug.new(fid), "", properties_slug, "")
  rescue Exception => e
    puts fid.inspect
    puts e.backtrace.inspect
  end
end
