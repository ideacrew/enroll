# frozen_string_literal: true

# bundle exec rails runner script/renewal_2023_enrollments_fix_for_ai_an_cases.rb
# Script which will cancel the existing auto_renewing 2023 enrollment and will generate a new renewal enrollment for 2022 enrollment for specific set of cases.
# This is because some of the renewals for AI/AN cases are wrong.

enrollment_hbx_ids = [['1384315', '1440852'], ['1384312', '1468182'], ['1298133', '1457565'], ['1409037', '1471859'], ['1366645', '1466160'], ['1366493', '1444120'], ['1252234', '1452087'], ['1366488', '1466133'], ['1330358', '1461899'],
                      ['1278538', '1455123'], ['1291918', '1456776'], ['1422813', '1474277'], ['1310225', '1459135'], ['1355624', '1465016'], ['1381652', '1467840'], ['1346776', '1463999'], ['1429167', '1475489'], ['1429167', '1475489'],
                      ['1267691', '1453841'], ['1387763', '1468561'], ['1384304', '1437503'], ['1279334', '1453794'], ['1330172', '1461867'], ['1254409', '1452341'], ['1303566', '1458262'], ['1230361', '1449663'], ['1323999', '1460986'],
                      ['1323999', '1460986'], ['1290528', '1456613'], ['1384308', '1468181'], ['1290755', '1456639'], ['1384288', '1441831'], ['1384288', '1441831'], ['1384288', '1441831'], ['1363644', '1465814'], ['1294204', '1457045'],
                      ['1308543', '1458917'], ['1293642', '1444114'], ['1293642', '1444114'], ['1356699', '1465116'], ['1359722', '1465386'], ['1345323', '1463876'], ['1384310', '1438139'], ['1278075', '1455086'], ['1407322', '1471577'],
                      ['1427940', '1475236'], ['1296787', '1457364'], ['1296787', '1457364'], ['1292169', '1456807'], ['1327566', '1461439'], ['1327691', '1461480'], ['1329474', '1461767'], ['1401440', '1470650'], ['1361862', '1465635'],
                      ['1372329', '1466747'], ['1387690', '1468549'], ['1377862', '1467387'], ['1393465', '1469380'], ['1393485', '1469382'], ['1397789', '1470035'], ['1408190', '1471705'], ['1427518', '1475158'], ['1206579', '1444233'],
                      ['1312117', '1459368'], ['1216694', '1447759'], ['1381210', '1467762'], ['1183046', '1436034'], ['1198937', '1441249'], ['1417971', '1465747'], ['1302359', '1458099'], ['1302359', '1458099'], ['1205848', '1443930'],
                      ['1205848', '1443930'], ['1205848', '1443930'], ['1215807', '1447518'], ['1392171', '1469193'], ['1223247', '1449161'], ['1384314', '1439773'], ['1390072', '1468878'], ['1204836', '1443541'], ['1319073', '1438919'],
                      ['1385556', '1468315'], ['1385556', '1468315'], ['1385556', '1468315'], ['1385556', '1468315'], ['1190796', '1438629'], ['1218042', '1448124'], ['1213232', '1446805'], ['1401166', '1470607'], ['1374486', '1467005'],
                      ['1420656', '1473926']].uniq

def failure_message(failure)
  if failure.is_a?(String)
    failure
  else
    failure.errors.to_h
  end
end

file_name = "renewal_enrollment_generation_for_ai_an_cases_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.csv"

CSV.open(file_name, 'w+', headers: true) do |csv|
  csv << ['Person HBX ID', '2022 Enrollment HbxID', '2022 Enrollment AasmState', '2022 Enrollment HiosID', '2023 Old Enrollment HbxID', '2023 Old Enrollment AasmState', '2023 Old Enrollment HiosID', '2023 New Enrollment HbxID', '2023 New Enrollment AasmState', '2023 New Enrollment HiosID', 'Errors']
  current_bs = HbxProfile.current_hbx.benefit_sponsorship
  renewal_bcp = current_bs.renewal_benefit_coverage_period

  enrollment_hbx_ids.each do |enrollment_2022_hbx_id, enrollment_2023_hbx_id|
    enrollment_2022 = HbxEnrollment.by_hbx_id(enrollment_2022_hbx_id).first
    enrollment_2023 = HbxEnrollment.by_hbx_id(enrollment_2023_hbx_id).first

    family = enrollment_2022.family
    input_params = { family_member_ids: enrollment_2023.hbx_enrollment_members.map(&:applicant_id), family: family, year: enrollment_2023.effective_on.year }
    csr_kind_result = Operations::PremiumCredits::FindCsrValue.new.call(input_params)

    if csr_kind_result.failure?
      csv << [family.primary_person.hbx_id, enrollment_2022_hbx_id, 'N/A', enrollment_2023_hbx_id, 'N/A', 'N/A', 'N/A', "FindCsrValue Result: #{failure_message(csr_kind_result.failure)}"]
      next
    end

    if ['coverage_terminated', 'coverage_expired', 'coverage_canceled'].include?(enrollment_2023.aasm_state)
      enrs_2023 = family.hbx_enrollments.by_year(2023).where(aasm_state: 'auto_renewing')
      if enrs_2023.present? && enrs_2023.count == 1
        enrollment_2023 = enrs_2023.first
      else
        csv << [family.primary_person.hbx_id, enrollment_2022_hbx_id, enrollment_2022.aasm_state, enrollment_2022.product.hios_id,
                enrollment_2023_hbx_id, enrollment_2023.aasm_state, enrollment_2023.product.hios_id, 'N/A', 'N/A', 'N/A',
                "There are #{enrs_2023.count} 2023 Enrollments in #{enrs_2023.pluck(:hbx_id, :aasm_state)}"]
        next
      end
    end

    csr_kind = csr_kind_result.success
    csr_variant = EligibilityDetermination::CSR_KIND_TO_PLAN_VARIANT_MAP[csr_kind]
    csr_variant_id = enrollment_2023.product.csr_variant_id
    if csr_variant_id == csr_variant
      csv << [family.primary_person.hbx_id, enrollment_2022_hbx_id, enrollment_2022.aasm_state, enrollment_2022.product.hios_id,
              enrollment_2023_hbx_id, enrollment_2023.aasm_state, enrollment_2023.product.hios_id, 'N/A', 'N/A', 'N/A',
              "Eligibile csr_kind: #{csr_kind}, Eligible csr_variant: #{csr_variant}, 2023 Enrollment csr_variant_id: #{csr_variant_id}"]
      next
    end

    if enrollment_2023.may_cancel_coverage?
      enrollment_2023.cancel_coverage
      enrollment_2023.save!
      result = ::Operations::Individual::RenewEnrollment.new.call(hbx_enrollment: enrollment_2022, effective_on: renewal_bcp.start_on)
      if result.success?
        new_2023_enr = result.success
        csv << [enrollment_2022.family.primary_person.hbx_id, enrollment_2022.hbx_id, enrollment_2022.aasm_state, enrollment_2022.product.hios_id,
                enrollment_2023.hbx_id, enrollment_2023.aasm_state, enrollment_2023.product.hios_id, new_2023_enr.hbx_id, new_2023_enr.aasm_state,
                new_2023_enr.product.hios_id, 'N/A']
      else
        csv << [enrollment_2022.family.primary_person.hbx_id, enrollment_2022.hbx_id, enrollment_2022.aasm_state, enrollment_2022.product.hios_id,
                enrollment_2023.hbx_id, enrollment_2023.aasm_state, enrollment_2023.product.hios_id, 'N/A', 'N/A',
                'N/A', "RenewEnrollment Result: #{failure_message(result.failure)}"]
      end
    else
      csv << [enrollment_2022.family.primary_person.hbx_id, enrollment_2022.hbx_id, enrollment_2022.aasm_state, enrollment_2022.product.hios_id,
              enrollment_2023.hbx_id, enrollment_2023.aasm_state, enrollment_2023.product.hios_id, 'N/A', 'N/A', 'N/A',
              "Unable to cancel current 2023 renewal enrollment: #{enrollment_2023_hbx_id}"]
    end
  rescue StandardError => e
    puts "enrollment_2022_hbx_id: #{enrollment_2022_hbx_id}, enrollment_2023_hbx_id: #{enrollment_2023_hbx_id} message: #{e} backtrace: #{e.backtrace.join('\n')}"
    csv << ['N/A', enrollment_2022_hbx_id, 'N/A', enrollment_2023_hbx_id, 'N/A', 'N/A', 'N/A', e]
  end
end
