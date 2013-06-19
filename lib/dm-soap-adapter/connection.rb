require 'savon' 

module DataMapper
  module Adapters
    module Soap
      
      class Connection

        def initialize(options)
          @wsdl_path = options.fetch(:path)
          @methods = options.fetch(:methods)
          raise "Methods must be specified!" if @methods.empty?
          @create_method = @methods.fetch(:create)
          @read_method = @methods.fetch(:read)
          @update_method = @methods.fetch(:update)
          @delete_method = @methods.fetch(:delete)
          @all_method = @methods.fetch(:all) # What exactly is this supposed to do?
          
          @client = Savon.client(wsdl: @wsdl_path)
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
    
        def call_service(operation, objects)
          DataMapper.logger.debug( "calling client #{operation} with #{objects.inspect}")
          response = @client.call(operation.snakecase.to_sym, objects)
        end
        
      end 
    end
  end
end