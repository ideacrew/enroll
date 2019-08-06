ResourceRegistry.configure do 
  {
    application: {
      config: {
        name: "EnrollApp", # reference Rails.app.name
        default_namespace: "options",
        root: '.',
        system_dir: "system",
        auto_register: []
      },
      load_paths: ['system']
    }
    # ,
    # options: {
    #   key: :tenants,
    #   namespaces:[
    #     {
    #       key: :dchbx,
    #       namespaces: [{
    #         key: :persistence,
    #         settings: [
    #           { key: :store, default: 'file_store' },
    #           { key: :serializer, default: 'yaml_serializer' },
    #           { key: :container, default: 'config' }
    #         ]
    #       }]
    #     }
    #   ]
    # }
  }
end

require_relative Rails.root.join('system', 'boot')