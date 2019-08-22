ResourceRegistry.configure do 
  {
    application: {
      config: {
        name: "EnrollApp",
        default_namespace: "options",
        root: Rails.root,
        system_dir: "system",
        auto_register: []
      },
      load_paths: ['system']
    },
    resource_registry: {
      resolver: {
        root: :enterprise,
        tenant: :dchbx,
        site: :primary,
        env: :production,
        application: :enroll
      }
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

ResourceRegistry.create