puts "*"*80
puts "::: Generating Japanese Translations :::"

Translation.find_or_initialize_by(key: "ja.header.call_customer_service", value: '"お客様サービスへ電話する"').save
Translation.find_or_initialize_by(key: "ja.header.help", value: '"ヘルプ"').save
Translation.find_or_initialize_by(key: "ja.header.logout", value: '"ログアウト"').save
Translation.find_or_initialize_by(key: "ja.header.my_id", value: '"私のID"').save
Translation.find_or_initialize_by(key: "ja.header.my_insured_portal", value: '"保険契約者用ポータル"').save
Translation.find_or_initialize_by(key: "ja.welcome.assisted_consumer_family_portal", value: '"要支援顧客/家族用ポータル"').save
Translation.find_or_initialize_by(key: "ja.welcome.broker_agency_portal", value: '"ブローカーエージェンシー用ポータル"').save
Translation.find_or_initialize_by(key: "ja.welcome.broker_registration", value: '"ブローカー登録"').save
Translation.find_or_initialize_by(key: "ja.welcome.byline", value: '"あなたにとってベストなプランが見つかる場所"').save
Translation.find_or_initialize_by(key: "ja.welcome.consumer_family_portal", value: '"顧客/家族用ポータル"').save
Translation.find_or_initialize_by(key: "ja.welcome.employee_portal", value: '"社員用ポータル"').save
Translation.find_or_initialize_by(key: "ja.welcome.employer_portal", value: '"雇用者用ポータル"').save
Translation.find_or_initialize_by(key: "ja.welcome.general_agency_portal", value: '"一般エージェンシー用ポータル"').save
Translation.find_or_initialize_by(key: "ja.welcome.general_agency_registration", value: '"一般エージェンシー登録"').save
Translation.find_or_initialize_by(key: "ja.welcome.hbx_portal", value: '"HBXポータル"').save
Translation.find_or_initialize_by(key: "ja.welcome.logout", value: '"ログアウト"').save
Translation.find_or_initialize_by(key: "ja.welcome.returning_user", value: '"復帰ユーザ"').save
Translation.find_or_initialize_by(key: "ja.welcome.sign_out", value: '"サインアウト"').save
Translation.find_or_initialize_by(key: "ja.welcome.signed_in_as", value: '"%{current_user} のアカウントでサインインしています"').save
Translation.find_or_initialize_by(key: "ja.welcome.welcome_email", value: '"%{current_user} へようこそ"').save
Translation.find_or_initialize_by(key: "ja.welcome.welcome_to_site_name", value: '"%{short_name} へようこそ"').save

puts "::: Japanese Translations Complete :::"
puts "*"*80

