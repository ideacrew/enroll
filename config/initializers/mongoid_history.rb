# Set default history tracker class name

Mongoid::History.tracker_class_name  = :action_journal
Mongoid::History.current_user_method = :current_user