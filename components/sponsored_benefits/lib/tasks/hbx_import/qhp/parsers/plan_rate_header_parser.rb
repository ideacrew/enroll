require Rails.root.join('lib', 'tasks', 'hbx_import', 'qhp', 'parsers', 'plan_rate_header_parser')

module Parser
  class PlanRateHeaderParser
    include HappyMapper

    tag 'header'

    element :application_id, String, tag: 'applicationId'
    element :last_modified_date, String, tag: 'lastModifiedDate'
    element :last_modified_by, String, tag: 'lastModifiedBy'
    element :documents, String, tag: 'documents'
    element :statements, String, tag: 'statements'
    element :status, String, tag: 'status'
    element :attestation_indicator, String, tag: 'attestationIndicator'
    element :tin, String, tag: 'tin'
    element :issuer_id, String, tag: 'issuerId'
    element :submission_type, String, tag: 'submissionType'
    element :market_type, String, tag: 'marketType'
    element :market_division_type, String, tag: 'marketDivisionType'
    element :market_coverage_type, String, tag: 'marketCoverageType'
    element :template_version, String, tag: 'templateVersion'



    def to_hash
      {
        application_id: application_id.present? ? application_id.gsub(/\n/,'').strip : "",
        last_modified_date: last_modified_date.present? ? last_modified_date.gsub(/\n/,'').strip : "",
        last_modified_by: last_modified_by.present? ? last_modified_by.gsub(/\n/,'').strip : "",
        statements: statements.present? ? statements.gsub(/\n/,'').strip : "",
        status: status.present? ? status.gsub(/\n/,'').strip : "",
        attestation_indicator: attestation_indicator.present? ? attestation_indicator.gsub(/\n/,'').strip : "",
        tin: tin.present? ? tin.gsub(/\n/,'').strip : "",
        issuer_id: issuer_id.present? ? issuer_id.gsub(/\n/,'').strip : "",
        submission_type: submission_type.present? ? submission_type.gsub(/\n/,'').strip : "",
        market_type: market_type.present? ? market_type.gsub(/\n/,'').strip : "",
        market_division_type: market_division_type.present? ? market_division_type.gsub(/\n/,'').strip : "",
        market_coverage_type: market_coverage_type.present? ? market_coverage_type.gsub(/\n/,'').strip : "",
        template_version: template_version.present? ? template_version.gsub(/\n/,'').strip : "",
      }
    end
  end
end