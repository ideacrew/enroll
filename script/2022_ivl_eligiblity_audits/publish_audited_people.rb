AUDIT_START_DATE = Date.new(2021,10,1)
AUDIT_END_DATE = Date.new(2022,10,1)
PASSIVE_RENEWAL_DATE = Time.mktime(2021,11,1,0,0,0)
STDOUT.puts "Standard caching complete."
STDOUT.flush

STDERR.puts "TESTING STANDARD ERROR REDIRECTION"
STDERR.flush

RECORDS_AT_ISSUE = [
  # "5d08fd82cc35a8797f00008b"
]

RECORDS_AT_ISSUE.each do |rec_no|
  puts "Excluding potentially corrupt record: #{rec_no}"
end
STDOUT.flush

h_packages = IvlEligibilityAudits::AuditQueryCache.benefit_packages_for(2022)
puts "Health Benefit Packages located."
STDOUT.flush
ivl_person_ids = IvlEligibilityAudits::AuditQueryCache.person_ids_for_audit_period_starting(AUDIT_START_DATE).sort
STDOUT.puts "Counted #{ivl_person_ids.count} people."
STDOUT.flush

families_of_interest = Family.where(
  {"family_members.person_id" => {"$in" => ivl_person_ids}}
)
STDOUT.puts "Counted #{families_of_interest.count} families."
STDOUT.flush

family_map = {}

# So what we need here is: family_membership * person_record * version_numbers_for_person
person_id_count = ivl_person_ids.length
STDOUT.puts person_id_count.inspect
STDOUT.puts families_of_interest.count
STDOUT.flush

class AuditPeoplePublisher
  def self.audit_queue_name
    config = Rails.application.config.acapi
    "#{config.hbx_id}.#{config.environment_name}.q.#{config.app_id}.dc_ivl_audit_people"
  end

  def self.result_queue_name
    config = Rails.application.config.acapi
    "#{config.hbx_id}.#{config.environment_name}.q.#{config.app_id}.dc_ivl_audit_results"
  end

  def self.create_audit_queue(ch)
    q = ch.queue(audit_queue_name, :durable => true)
  end

  def self.create_result_queue(ch)
    q = ch.queue(result_queue_name, :durable => true)
  end

  def self.publish_person_ids(channel, person_ids)
    d_ex = out_chan.default_exchange
    channel.confirm_select
    person_ids.in_groups_of(100, false) do |group|
      group.each do |person_id|
        d_ex.publish(
          "",
          {
            :routing_key => queue_name,
            :headers => {
              :person_id => person_id
            }
          }
        )
      end
      channel.wait_for_confirms
    end
  end
end

conn = Bunny.new(Rails.application.config.acapi.remote_broker_uri, :heartbeat => 15)
chan = conn.create_channel
AuditPeoplePublisher.create_audit_queue(chan)
AuditPeoplePublisher.create_result_queue(chan)
AuditPeoplePublisher.publish_person_ids(chan, ivl_person_ids)
chan.close
conn.close
