# frozen_string_literal: true

module Notifier
  # Template model
  class Template
    include Mongoid::Document
    include Mongoid::Timestamps

    BLOCKED_ELEMENTS = ['<script', '%script', 'iframe', 'file://', 'dict://', 'ftp://', 'gopher://', '%x', 'system', 'exec', 'Kernel.spawn', 'Open3', '`', 'IO'].freeze

    embedded_in :notice_kind

    field :markup_kind, type: String, default: "markdown"
    field :raw_body, type: String
    field :raw_header, type: String
    field :raw_footer, type: String
    field :template_key, type: String
    field :data_elements, type: Array, default: []

    validates_presence_of :raw_body
    validate :check_template_elements

    def to_s
      [raw_header, raw_body, raw_footer].join('\n\n')
    end

    def check_template_elements
      raw_text = to_s.downcase
      errors.add(:base, 'has invalid elements') if BLOCKED_ELEMENTS.any? {|str| raw_text.include?(str)}
    end
  end
end
