require 'csv'

def compare_addresses(home_address,mailing_address)
	cleaned_home_address = clean_fields(home_address)
	cleaned_mailing_address = clean_fields(mailing_address)
	full_home_address = cleaned_home_address.full_address.downcase
	full_mailing_address = cleaned_mailing_address.full_address.downcase
	if full_home_address == full_mailing_address
		return true
	end
end

def clean_fields(address)
	address.address_1 = address.address_1.try(:strip)
	address.address_2 = address.address_2.try(:strip)
	address.city = address.city.try(:strip)
	address.state = address.state.try(:strip)
	address.zip = address.zip.try(:strip)
	return address
end

count = 0

timestamp = Time.now.strftime('%Y%m%d%H%M')

CSV.open("2016_enrollments_with_multiple_addresses_#{timestamp}_enroll.csv", "w") do |csv|
	csv << ["Enrollment Group ID", "Subscriber", "HBX ID", "Home Address","","","","", "Mailing Address"]
	csv << ["","","","Address 1","Address 2","City","State","Zip","Address 1","Address 2","City","State","Zip"]
	Person.all.each do |person|
		count += 1
		puts count if count % 10000 == 0
		next if person.families.size == 0
		next if person.addresses.size < 2
		person.families.each do |family|
			next if family.households.size == 0
			family.households.each do |household|
				next if household.hbx_enrollments.size == 0
				household.hbx_enrollments.each do |hbx_enrollment|
					next if hbx_enrollment.effective_on.year != 2016
					next if hbx_enrollment.hbx_enrollment_members.size == 0
					next if hbx_enrollment.subscriber == nil
					next if hbx_enrollment.subscriber.person != person
					## Lets get all of the data and put it into the CSV!
					eg_id = hbx_enrollment.hbx_id
					subscriber_name = person.full_name
					subscriber_hbx_id = person.hbx_id
					home_address = person.home_address
					mailing_address = person.mailing_address
					unless mailing_address == nil || home_address == nil
						address_comparison = compare_addresses(home_address,mailing_address)
						if address_comparison == true
							csv << [eg_id,subscriber_name,subscriber_hbx_id,
									home_address.try(:address_1),home_address.try(:address_2),home_address.try(:city),home_address.try(:state),home_address.try(:zip),
									mailing_address.try(:address_1),mailing_address.try(:address_2),mailing_address.try(:city),mailing_address.try(:state),mailing_address.try(:zip)]
						end
					end # making sure they have both home and mailing addresses
				end # each of the hbx_enrollments
			end # Ends households.each
		end # Ends families.each
	end # Ends person.each
end # Closes CSV