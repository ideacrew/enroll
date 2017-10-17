require 'curl'

module Notifier
  class NoticeKind
    include Mongoid::Document
    include Mongoid::Timestamps
    include AASM
    include Notifier::NoticeBuilder

    RECEIPIENTS = {
      "Employer" => "Notifier::MergeDataModels::EmployerProfile",
      "Employee" => "Notifier::MergeDataModels::EmployeeProfile",
      "Broker" => "Notifier::MergeDataModels::BrokerProfile"
    }

    field :title, type: String
    field :description, type: String
    field :identifier, type: String
    field :notice_number, type: String
    field :receipient, type: String, default: "Notifier::MergeDataModels::EmployerProfile"
    field :aasm_state, type: String, default: :draft
    field :event_name, type: String

    embeds_one :cover_page
    embeds_one :template, class_name: "Notifier::Template"
    embeds_many :workflow_state_transitions, as: :transitional

    validates_presence_of :title, :notice_number, :receipient
    validates_uniqueness_of :notice_number, :event_name

    before_save :set_data_elements

    scope :published,         ->{ any_in(aasm_state: ['published']) }
    scope :archived,          ->{ any_in(aasm_state: ['archived']) }

    attr_accessor :resource

    def set_data_elements
      if template.present?
        tokens = template.raw_body.scan(/\#\{([\w|\.]*)\}/).flatten.reject{|element| element.scan(/Settings/).any?}.uniq
        conditional_tokens = template.raw_body.scan(/\[\[([\s|\w|\.|?]*)/).flatten.map(&:strip).collect{|ele| ele.gsub(/if|else|end|else if|elsif/i, '')}.map(&:strip).reject{|elem| elem.blank?}.uniq
        template.data_elements = tokens + conditional_tokens
      end
    end

    def execute_notice(event_name, payload)
      finder_mapping = Notifier::ApplicationEventMapper.lookup_resource_mapping(event_name)
      if finder_mapping.nil?
        # LOG AN ERROR ABOUT A BOGUS EVENT WHERE YOU CAN'T FIND THINGS
        return
      end

      @resource = finder_mapping.mapped_class.send(finder_mapping.search_method, payload[finder_mapping.identifier_key.to_s])
      generate_pdf_notice
    end

    def receipient_klass_name
      receipient.to_s.split('::').last.underscore.to_sym
    end

    def self.to_csv
      CSV.generate(headers: true) do |csv|
        csv << ['Notice Number', 'Title', 'Description', 'Receipient', 'Notice Template']

        all.each do |notice|
          csv << [notice.notice_number, notice.title, notice.description, notice.receipient, notice.template.try(:raw_body)]
        end
      end
    end

    aasm do
      state :draft, initial: true

      state :published
      state :archived

      event :publish, :after => :record_transition do
        transitions from: :draft,  to: :published,  :guard  => :can_be_published?
      end

      event :archive, :after => :record_transition do
        transitions from: [:published],  to: :archived
      end  
    end

    # Check if notice with same MPI indictor exists
    def can_be_published?
    end

    def record_transition
      self.workflow_state_transitions << WorkflowStateTransition.new(
        from_state: aasm.from_state,
        to_state: aasm.to_state
        )
    end

    # def self.markdown
    #   Redcarpet::Markdown.new(ReplaceTokenRenderer,
    #       no_links: true,
    #       hard_wrap: true,
    #       disable_indented_code_blocks: true,
    #       fenced_code_blocks: false,        
    #     )
    # end

    # # Markdown API: http://www.rubydoc.info/gems/redcarpet/3.3.4
    # def to_html
    #   self.markdown.render(template.body)
    # end
  end
end
