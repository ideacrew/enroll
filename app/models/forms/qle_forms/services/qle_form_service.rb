module Forms
  module QleForms
    class QleFormService

      attr_accessor :qle, :factory

      def initialize(attrs={}, find_or_create)
        @factory = qle_factory(attrs, find_or_create)
        @qle = find_qle_kind(attrs[:title])
      end

      def find_qle_kind(qle_title)
        QualifyingLifeEventKind.where(title: qle_title).first
      end

      def qle_factory(attrs={}, find_or_create)
        case find_or_create
        when "create"
          create_qle_and_questions(attrs)
        when "edit"
          edit_qle_and_questions(attrs)
        end
      end

      def edit_qle_and_questions(attrs)
       find_qle_kind(qle_title).update_attributes(attrs)
      end

      def create_qle_and_questions(attrs)
        QualifyingLifeEventKind.create!(attrs)
      end
    end
  end
end
