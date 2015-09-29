# Get the goodness of the COW GC for shared objects before we fork
Rails.application.eager_load!
Listeners::EmployerResourceListener.run
