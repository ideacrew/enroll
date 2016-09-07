module AuditTrail

  # Post Journal Entries

  # Configure history tracker based on parent class
  ## journal class
  ## tracked events
  ## included attributes
  ## other options
  # Determine event type and fire

  # attr_writer :history_tracking_scope

  def initialize(*args)
    super
    klass.configure_tracker # (history_tracking_scope)
  end

  def klass
    self.class.name.classify.constantize
  end

  def history_tracking_scope(scoped_model = nil)
    if scoped_model.present?
      scoped_model.to_s.downcase.to_sym
    else
      self.class.name.downcase.to_sym
    end
  end

  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods

    def configure_tracker #(history_tracking_scope)
      options = audit_history_options
      track_history(options)
    end

  private
    # Build the Mongoid::History options
    def audit_history_options(options = {})
      options.present? ? options : default_options
    end

    # Default options: 
    ## Track all fields and relations
    ## Track all action types
    def default_options
      {
        on: self.fields.keys + self.relations.keys,
        except: [:created_at, :updated_at], 
        tracker_class_name: nil,
        modifier_field: :updated_by,
        changes_method: :changes,
        version_field: :version,
        scope: :person,
        track_create: true, 
        track_update: true, 
        track_destroy: true
      }
    end
  end

end
