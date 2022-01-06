require 'csv'

field_names = %w[
  Index
  Subscriber\ ID
  Member\ ID
  First\ Name
  Last\ Name
  Earliest\ Due\ Date
  Citizenship\ Status
  Citizenship\ Date
  American\ Indian\ Status
  American\ Indian\ Date
  Immigration\ Status
  Immigration\ Date
  Social\ Security\ Status
  Social\ Security\ Date
  APTC\ CSR\ Verified?
  APTC\ CSR\ Document\ Status
  APTC\ CSR\ Date
  Health\ Enrolled?
  Dental\ Enrolled?
]

def individual_market_evidence_items
  EnrollRegistry[:aca_individual_market_eligibility].settings(:evidence_items).item
end

def find_evidence_state(evidence_key)
  if individual_market_evidence_items.include?(evidence_key)
    evidence_states = aca_individual_market_eligibility&.evidence_states
  end

  (evidence_states || []).detect {|evidence| evidence.evidence_item_key == evidence_key }
end

def immigration_evidence
  find_evidence_state(:immigration_status)
end

def citizenship_evidence
  find_evidence_state(:citizenship)
end

def social_security_evidence
  find_evidence_state(:social_security_number)
end

def american_indian_evidence
  find_evidence_state(:american_indian_status)
end

def find_eligibility_state(eligibility_key)
  eligibility_state =
    @eligibility_states.detect do |es|
      es.eligibility_item_key == eligibility_key
    end
  return unless eligibility_state.evidence_states.present?
  eligibility_state
end

def aca_individual_market_eligibility
  find_eligibility_state('aca_individual_market_eligibility')
end

def aptc_csr_credit_eligibility
  find_eligibility_state('aptc_csr_credit')
end

def health_product_enrollment_status_eligibility
  find_eligibility_state('health_product_enrollment_status')
end

def dental_product_enrollment_status_eligibility
  find_eligibility_state('dental_product_enrollment_status')
end

def subject_details(determination, subject, primary, index)
  @eligibility_states = subject.eligibility_states
  return [] unless health_product_enrollment_status_eligibility || dental_product_enrollment_status_eligibility

  if aptc_csr_credit_eligibility&.is_eligible
    aptc_csr_status = aptc_csr_credit_eligibility.is_eligible ? true : false
  end

  [
    index,
    primary.hbx_id,
    subject.hbx_id,
    subject.first_name,
    subject.last_name,
    determination.outstanding_verification_earliest_due_date || '',
    citizenship_evidence&.status || '',
    citizenship_evidence&.due_on || '',
    american_indian_evidence&.status || '',
    american_indian_evidence&.due_on || '',
    immigration_evidence&.status || '',
    immigration_evidence&.due_on || '',
    social_security_evidence&.status || '',
    social_security_evidence&.due_on || '',
    aptc_csr_status || '',
    aptc_csr_credit_eligibility&.document_status || '',
    aptc_csr_credit_eligibility&.earliest_due_date || '',
    health_product_enrollment_status_eligibility.present?,
    dental_product_enrollment_status_eligibility.present?
  ]
end

file_name =
  "#{Rails.root}/outstanding_verifications_#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv"

index = 0
limit = 100
families_processed = 0
skip = 0

CSV.open(file_name, 'w', force_quotes: true) do |csv|
  csv << field_names

  while true
    families =
      Family.eligibility_determination_outstanding_verifications(skip, limit)
    break if families.empty?

    families.no_timeout.each do |family|
      families_processed += 1
      index += 1

      eligibility_determination = family.eligibility_determination

      primary =
        eligibility_determination.subjects.detect do |subject|
          subject.is_primary
        end

      eligibility_determination.subjects.each do |subject|
        data = subject_details(eligibility_determination, subject, primary, index)
        csv << data if data.present?
        @eligibility_states = nil
      end
    end

    skip = families_processed
  end
end
