module Services
  class QleFormService

    attr_accessor :qle, :factory, :qle_form_params

    def initialize(attrs={}, find_or_create)
      @factory = qle_factory(attrs, find_or_create)
      @qle = find_qle_kind(attrs[:_id])
      @qle_form_params = attrs
    end
    
    # TODO: Edit params will probably contain ID, so likely
    # this will be updated to change to ID
    def find_qle_kind(attrs)
      QualifyingLifeEventKind.where(_id: attrs[:_id]).first
    end

    # TODO: Move factory functionality to another file
    def qle_factory(attrs={}, find_or_create)
      binding.pry
      case find_or_create
      when "create"
        create_qle_and_questions(attrs)
      when "edit"
        edit_qle_and_questions(attrs)
      when "update"
        update_qle_and_questions(attrs)
      end
    end

    def edit_qle_and_questions(attrs)
      find_qle_kind(attrs)
    end

    def update_qle_and_questions(attrs)
     attributes = clean_qle_attributes(attrs)
     qle_title = attributes["title"]
     find_qle_kind(qle_title).update_attributes!(attributes)
    end

    def create_qle_and_questions(attrs)
      attributes = clean_qle_attributes(attrs)
      QualifyingLifeEventKind.create!(attributes)
    end

    def clean_qle_attributes(attrs)
      attrs["custom_qle_questions"] = attrs["questions_attributes"]
      attrs.delete("questions_attributes")
      attrs["custom_qle_questions"].each do |key, value|
        value["custom_qle_answer_attributes"] = value["answer_attributes"]
        value.delete("answer_attributes") 
      end
      attrs
    end
  end
end
