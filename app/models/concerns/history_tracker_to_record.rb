module HistoryTrackerToRecord
  extend ActiveSupport::Concern

  # trackable_class should be capitalized as string like "Person"
  def history_tracker_to_record(history_tracker)
    # Example: If is a HistoryTracker in person model
    # history_track.trackable will return consumer_role
    # if the consumer_role was modified. trackable_root
    # will return person for both
    trackable_record = history_tracker.trackable_root
    # Example structure of modified: {"is_state_resident"=>false}
    trackable_record.history_tracks.where(:version.gte => history_tracker.version).each do |track|
      modified_attributes = track.original
      last_association = track.association_chain.last
      modified_attributes.each do |key, value|
        if last_association["name"] == self.class.name
          # Changes bottom level document
          trackable_record[key] = value
        elsif trackable_record.send(last_association["name"]).is_a?(Enumerable) && trackable_record.send(last_association["name"]).length > 0
          # embeds_many or has_many, needs id, hence checking if enumerable type object like array
          last_association_id = last_association["id"].to_s
          if trackable_record.send(last_association["name"]).where(id: last_association_id).first.present?
            trackable_record.send(last_association["name"]).where(id: last_association_id).first[key] = value
          end
        elsif trackable_record.send(last_association["name"]).present?
          # embeds_one type relationship
          trackable_record.send(last_association["name"])[key] = value
        end
      end
    end
    trackable_record
  end
end
