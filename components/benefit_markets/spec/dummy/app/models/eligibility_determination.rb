# frozen_string_literal: true

class EligibilityDetermination
  include Mongoid::Document
  include Mongoid::Timestamps

  CSR_KINDS = %w[csr_100 csr_94 csr_87 csr_73].freeze

  CSR_KIND_TO_PLAN_VARIANT_MAP = {
    'csr_100' => '01',
    'csr_94' => '06',
    'csr_87' => '05',
    'csr_73' => '04',
    'csr_0' => '02',
    'limited' => '03'
  }.freeze

  CSR_KIND_TO_PLAN_VARIANT_MAP.default = '01'

end
