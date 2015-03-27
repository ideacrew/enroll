require "tasks/hbx_employer_monkeypatch"

class HbxCensusImport
  attr_reader :file_name

  def initialize(file_name)
    @file_name = file_name
  end

  def run
    ees = []
    CSV.foreach(file_name, headers: true) do |row|
      ees << CensusRecord.from_row(row)
    end

    ees.reject!(&:nil?).sort!.uniq!

    puts "Found #{ees.size} unique census records in #{ees.collect(&:fein).uniq.size} employers."

    objects_to_save = []
    ees.each do |ee|
      er = EmployerProfile.find_by_fein(ee.fein)
      if er.present?
        py = er.plan_years.last
        bg = py.benefit_groups.last
        eefs = EmployerProfile.find_census_families_by_person(ee)
        # TODO: make sure first is the right one
        eef = eefs.first
        eef = er.employee_families.build if eef.nil?
        cee = eef.census_employee
        if cee.nil?
          cee = eef.build_census_employee
          cee.first_name = ee.first_name
          cee.last_name = ee.last_name
          cee.ssn = ee.ssn
          cee.dob = ee.dob
          cee.hired_on = ee.doh
          cee.build_email(kind: "work", address: ee.work_email)
          cee.terminated_on = ee.dot
          objects_to_save << cee
        end
        bg.try(:employee)
      end
    end

    puts "Built #{objects_to_save.size} new census records."

    objects_not_saved = objects_to_save.reject(&:save)

    puts "Successfully saved #{objects_to_save.size - objects_not_saved.size} new census records."
  end
end

CensusRecord = Struct.new(
  :dba, :fein, :first_name, :last_name, :ssn, :dob, :doh, :work_email,
  :person_email, :dot, :individual_external_id, :employee_external_id,
  :record_start_date, :record_end_date
)

CensusRecord.class_eval do
  include Comparable

  def self.set_last_order(recipient, another)
    @recipient = recipient
    @another = another
  end

  def self.last_order
    return @recipient, @another
  end

  def self.from_row(row)
    ee = CensusRecord.new
    %w[itself to_digits itself itself to_digits to_date_safe to_date_safe itself
       itself to_date_safe itself itself itself itself].each_with_index do |conversion, index|
      ee.send("#{ee.members[index]}=", row[index].send(conversion))
    end
    ee = nil if ee.fein.nil? || ee.ssn.nil? || ee.dob.nil? || ee.doh.nil?
    ee
  end

  def self.attribute_sort_order
    %w[fein ssn dob doh]
  end

  def sort_attributes
    self.class.attribute_sort_order.collect do |attribute|
      sort_attribute = self.send(attribute)
    end
  end

  def <=>(another)
    self.class.set_last_order(self, another)
    sort_attributes <=> another.sort_attributes
  end
end
