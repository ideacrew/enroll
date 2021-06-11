# frozen_string_literal: true

module MagiMedicaid
  class Student
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :applicant, class_name: "::MagiMedicaid::Applicant", inverse_of: :student

    field :is_student, type: Boolean
    field :student_kind, type: String
    field :student_school_kind, type: String
    field :student_status_end_on, type: String
  end
end
