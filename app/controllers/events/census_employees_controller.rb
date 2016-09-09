module Events
  class CensusEmployeesController < ::ApplicationController
    include Acapi::Amqp::Responder

    def resource(connection, delivery_info, properties, body)
      begin
        reply_to = properties.reply_to
        headers = properties.headers || {}

        ssn = headers[:ssn]
        dob = headers[:dob]
        census_employees = find_census_employee({ssn: ssn, dob: dob})

        return_status = "200"
        if census_employees.empty?
          return_status = "404"
        end

        response_payload = render_to_string "events/census_employee/employer_response", :formats => ["xml"], :locals => {:census_employees => census_employees}
        reply_with(connection, reply_to, return_status, response_payload)
      rescue Exception => e
        reply_with(connection, reply_to, "500", JSON.dump({exception: e.inspect, backtrace: e.backtrace.inspect}))
      end
    end

    private

    def reply_with(connection, reply_to, return_status, body)
      headers = {:return_status => return_status}

      with_response_exchange(connection) do |ex|
        ex.publish(body, {:routing_key => reply_to, :headers => headers})
      end
    end

    def find_census_employee(options)
      CensusEmployee.where(encrypted_ssn: CensusMember.encrypt_ssn(options[:ssn])).and(dob: Date.strptime(options[:dob], "%Y%m%d"))
    end
  end
end