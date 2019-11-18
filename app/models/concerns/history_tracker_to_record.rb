module HistoryTrackerToRecord
  extend ActiveSupport::Concern

  # trackable_class should be capitalized as string like "Person"
  def history_tracker_to_record(history_tracker)
    # Example: If is a HistoryTracker in person model
    # history_track.trackable will return consumer_role
    # if the consumer_role was modified. trackable_root
    # will return person for both
    self.reload
    # Example structure of modified: {"is_state_resident"=>false}
    tracks_to_reverse = self.history_tracks.sort_by(&:created_at).reject do |ht|
      self.updated_at <= ht.created_at
    end.reverse
    tracks_to_reverse.each do |track|
      track.undo_attr({})
    end
    self
  end
end
