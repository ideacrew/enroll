module Importers::Transcripts
  
  class FamilyError < StandardError; end

  class FamilyTranscript

    attr_accessor :transcript, :updates, :market

    SOURCE_RULE_MAP = {
      base: {
        add: 'ignore',
        update: 'ignore',
        remove: 'ignore'
      },
      family_members: {
        add: 'edi',
        update: {
          relationship: 'edi'
        },
        remove: 'ignore'
      },
      irs_groups: {
        add: 'edi',
        update: 'edi',
        remove: 'edi'
      }
    }

  end
end