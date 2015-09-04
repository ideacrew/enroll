module PdfTemplates
  class Individual
    include Virtus.model

    attribute :active_members, Array[String]
    attribute :inconsistent_members, Array[String]
    attribute :eligible_immigration_status_members, Array[String]
    attribute :members_with_more_plans, Array[String]
    attribute :indian_tribe_members, Array[String]
    attribute :unverfied_resident_members, Array[String]
    attribute :unverfied_citizenship_members, Array[String]
    attribute :unverfied_ssn_members, Array[String]
  end
end
