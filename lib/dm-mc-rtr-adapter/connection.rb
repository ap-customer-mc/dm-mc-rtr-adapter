require 'savon' 

module DataMapper
  module Adapters
    module Soap
      
      class Connection

        def initialize(options)
          @wsdl_path = options.fetch(:path)
          @create_method = options.fetch(:create)
          @read_method = options.fetch(:read) # This maps to get a single object
          @update_method = options.fetch(:update)
          @delete_method = options.fetch(:delete)
          # So... this would be "query" and we stuff everything here and hope the other side knows how to handle it
          @query_method = options.fetch(:all)
          
          savon_ops = { wsdl: @wsdl_path }
          
          auth_ops = {}
          if options[:username] && options[:password]
            auth_ops[:wsse_auth] = [options[:username], options[:password]]
            auth_ops[:wsse_auth] << :digest if options[:digest]
          end
          
          savon_ops.merge!(auth_ops)

          if options[:logging_level] && %w[ off fatal error warn info debug ].include?(options[:logging_level].downcase)
            level = options[:logging_level].downcase
            if level == 'off'
              savon_ops.merge!(log: false)
            else
              savon_ops.merge!(log: true, logger: DataMapper.logger, log_level: level.to_sym)
            end
          end
                    
          @client = Savon.client(savon_ops)
          @options = options
          @expose_client = @options.fetch(:enable_mock_setters, false)
        end
        
        def client=(client)
          @client = client if @expose_client
        end

        def call_create(objects)
          call_service(@create_method, message: objects)
        end

        def call_update(objects)
          call_service(@update_method , message: objects)
        end

        def call_delete(keys)
          call_service(@delete_method, message: keys)
        end
    
        def call_get(id)
          call_service(@read_method, message: id)
        end
    
        def call_query(query)
          call_service(@query_method, message: query)
        end
        
        def call_service(operation, objects)
          DataMapper.logger.debug( "calling client #{operation.to_sym} with #{objects.inspect}")
          response = @client.call(operation.to_sym, objects)
        end
        
      end 
    end
  end
end