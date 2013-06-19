require 'savon' 

module DataMapper
  module Adapters
    module Soap
      
      class Connection

        def initialize(options)
          @client = Savon.client(wsdl: options['path'])
          @options = options
        end
        
        def client=(client)
          @client = client if @options.fetch(:enable_mock_setters)
        end

        def call_create(objects)
          
          call_service(@options['methods']['create'], message: objects)
        end

        def call_update(objects)
          call_service(@options['methods']['update'], message: objects)
        end

        def call_delete(keys)
          call_service(@options['methods']['delete'], message: keys)
        end
    
        def call_get(id)
          call_service(@options['methods']['read'], message: id)
        end
    
        def call_service(operation, objects)
          DataMapper.logger.debug( "calling client #{operation} with #{objects.inspect}")
          response = @client.call(operation.snakecase.to_sym, objects)
        end
        
      end 
    end
  end
end