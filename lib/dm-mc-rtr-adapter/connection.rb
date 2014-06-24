require 'savon' 

module DataMapper
  module Adapters
    module Soap
      
      class Connection

        def initialize(options)
          p "these are the options"
          p options
          @wsdl_path = options.fetch(:wsdl_store)
          @ssl_cert = options.fetch(:ssl_cert)
          @ssl_key = options.fetch(:ssl_key)
          @create_method = options.fetch(:create) if options[:create]
          @read_method = options.fetch(:read) if options[:read]# This maps to get a single object
          @update_method = options.fetch(:update) if options[:update]
          @delete_method = options.fetch(:delete) if options[:delete]
          # So... this would be "query" and we stuff everything here and hope the other side knows how to handle it
          p "this is the options fetch of all"
          p options.fetch(:all)
          @query_method = options.fetch(:all)
          
          savon_ops = { wsdl: "#{Rails.root}#{@wsdl_path}", ssl_cert_key_file: "#{Rails.root}/#{@ssl_key}", ssl_cert_file: "#{Rails.root}/#{@ssl_cert}", logger: Rails.logger, log_level: :debug, log: true,  pretty_print_xml: true}
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
    
        def call_query(method, query)
          call_service(method, xml: query)
        end
        
        def call_service(operation, objects)
          DataMapper.logger.debug( "calling client #{operation.to_sym} with #{objects.inspect}")
          response = @client.call(operation.to_sym, objects)
        end
        
      end 
    end
  end
end