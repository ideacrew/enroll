class AuditRecordReader
  def initialize(chan, q)
    @channel = chan
    @connection = chan.connection
    @queue = q
  end

  def self.result_queue_name
    config = Rails.application.config.acapi
    "#{config.hbx_id}.#{config.environment_name}.q.#{config.app_id}.dc_ivl_audit_results"
  end

  def self.create_queue(ch)
    ch.queue(result_queue_name, :durable => true)
  end

  def self.run
    conn = Bunny.new(Rails.application.config.acapi.remote_broker_uri, :heartbeat => 15)
    conn.start
    chan = conn.create_channel
    q = create_queue(chan)
    self.new(chan, q).build
  end

  def build
    CSV.open("dc_ivl_audit_results_2023.csv", "wb") do |csv|
      csv << [
        "Family ID",
        "Hbx ID",
        "Last Name",
        "First Name",
        "Full Name",
        "Date of Birth",
        "Gender",
        "Application Date",
        "Primary Applicant",
        "Relationship",
        "Citizenship Status",
        "American Indian",
        "Incarceration",
        "Home Street 1",
        "Home Street 2",
        "Home City",
        "Home State",
        "Home Zip",
        "Mailing Street 1",
        "Mailing Street 2",
        "Mailing City",
        "Mailing State",
        "Mailing Zip",
        "No DC Address",
        "Residency Exemption Reason",
        "Is applying for coverage",
        "Resident Role",
        "Citizenship Status Verified",
        "Immigration Status Verified",
        "SSN Verified",
        "Income Verified",
        "Eligible",
        "Denial Reasons"
      ]
    end
    csv_f = File.open("dc_ivl_audit_results_2023.csv", "ab")
    CSV.open("dc_ivl_audit_errors_2023.csv", "wb") do |e_csv|
      e_csv << ["Person ID", "Code", "Error"]
      run_records(csv_f, e_csv)
    end
    csv_f.close
  end

  def run_records(csv, e_csv)
    di, props, payload = @queue.pop(manual_ack: true)
    while di
      headers = props.headers || {}
      person_id = headers["person_id"]
      return_status = headers["return_status"]
      status = return_status.to_s
      case status
      when "200"
        csv.write(payload)
      when "204"
        e_csv << [person_id, status, "No person versions in window"]
      else
        e_csv << [person_id, status, payload]
      end
      di, props, payload = @queue.pop(manual_ack: true)
    end
  end
end

AuditRecordReader.run