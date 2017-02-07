require File.join(Rails.root, "lib/mongoid_migration_task")

class ExpireConversionEmployers < MongoidMigrationTask

  def prepend_zeros(number, n)
    (n - number.to_s.size).times { number.prepend('0') }
    number
  end

  def migrate
    CSV.open("#{Rails.root}/ConversionERExpiration_Results.csv", "w", force_quotes: true) do |csv|

      csv << ['FEIN', 'Legal Name', 'Plan Year Status(Before)', 'Plan Year Status(After)']

      CSV.foreach("#{Rails.root.to_s}/ConversionERExpiration.csv") do |row|

        fein = prepend_zeros(row[0].to_s, 9)
        start_on = Date.strptime(row[1].to_s, "%m/%d/%Y")
        employer = EmployerProfile.find_by_fein(fein)

        if employer.blank?
          puts "Employer Profile not found with fein #{fein}"
          next
        else
          puts "Processing (#{fein}) - #{employer.legal_name}"
        end

        data = [employer.fein, employer.legal_name]

        if plan_year = employer.plan_years.where(:start_on => start_on).first
          data += [plan_year.aasm_state.camelcase]
          plan_year.cancel_renewal! if plan_year.may_cancel_renewal?
          plan_year.cancel! if plan_year.may_cancel?
          data += [plan_year.aasm_state.camelcase]
        else
          data += [nil, nil]
        end

        if off_exchange_py = employer.plan_years.where(:start_on => start_on.prev_year).first
          data += [off_exchange_py.aasm_state.camelcase]
          off_exchange_py.conversion_expire! if off_exchange_py.may_conversion_expire?
          data += [off_exchange_py.aasm_state.camelcase]
        end

        csv << data 
      end
    end
  end
end
