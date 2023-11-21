# 2023 Audit Run Instructions for Maine

1. Deploy the `me_ivl_eligibility_audit_2023` branch to available pods, rebuild database indexes.
2. Execute `bundle exec rails r script/2022_ivl_eligiblity_audits/publish_audited_people.rb`
3. Launch a group of pods running the `script/2022_ivl_eligiblity_audits/person_audit_listener.rb` script - the more the better.  We are waiting for the `me0.<environment_name>.q.enroll.me_ivl_audit_people` queue to finish draining.
4. Once the `me0.<environment_name>.q.enroll.me_ivl_audit_people` queue is empty, run the `bundle exec rails r script/2022_ivl_eligiblity_audits/combine_audit_records.rb` script to create the output file