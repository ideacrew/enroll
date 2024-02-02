# This script is for the demo environment
# It removes any of our clients email addresses from the admin user accounts

not_ic_users = User.all.not.where(email: /ideacrew.com/i)

accts_updated = 0
accts_borked = 0
not_ic_users.each.with_index do |usr, index|
    begin
        old_e = usr.email

        new_e = "anon#{index}@ic.com"
        usr.email = new_e
        usr.oim_id = new_e

        accts_updated += 1 if usr.save
        puts("user changed from #{old_e} to #{usr.email}")
    rescue
        accts_borked += 1
    end
end

puts "Successfully sanitized #{accts_updated} user accounts, #{accts_borked} did not update."