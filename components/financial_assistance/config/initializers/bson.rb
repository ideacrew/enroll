# frozen_string_literal: true

# Solved the canonical query issue. Credit to https://github.com/plataformatec/devise/issues/2949#issuecomment-44520300

module BSON
  #changing ID object to string in schema
  class ObjectId
    def as_json(*)
      to_s
    end
  end
end