
module DataMapper
  module Adapters
    module Soap
      class Adapter < DataMapper::Adapters::AbstractAdapter
        include Errors, ParserDelegate, QueryDelegate
        
        def initialize(name, options)
          super
          @expose_connection = @options.fetch(:enable_mock_setters, false)
        end

        def connection=(connection)
          @connection = connection if @expose_connection
        end
        
        def connection
          @connection ||= Connection.new(@options)
        end
    
        def get(keys)
      
          response = connection.call_get(keys)

          rescue SoapError => e
            handle_server_outage(e)
        
        end

        def read(query)
          DataMapper.logger.debug("Read #{query.inspect} and its model is #{query.model.inspect}")
          model = query.model
          soap_query = build_query(query)
          begin
            
            response = connection.call_query(soap_query)
            DataMapper.logger.debug("response was #{response.inspect}")
            body = response.body
            return [] unless body
            return parse_collection(body, model)
          rescue SoapError => e
            handle_server_outage(e)
          end
        end
  
        def create(resources)
          resources.each do |resource|
            model = resource.model
            DataMapper.logger.debug("About to create #{model} using #{resource.attributes}")
            
            begin
              response = connection.call_create(resource.attributes)
              DataMapper.logger.debug("Result of actual create call is #{response.inspect}")
              result = update_attributes(resource, response.body)
            rescue SoapError => e
              handle_server_outage(e)    
            end
          end
        end

        def update_attributes(resource, body)
          return if DataMapper::Ext.blank?(body)
          fields = {}
          model      = resource.model
          properties = model.properties(model.default_repository_name)
          properties.each do |prop| 
            fields[prop.field.to_sym] = prop.name.to_sym
          end
          DataMapper.logger.debug( "Properties are #{properties.inspect} and body is #{body.inspect}")
          
          parse_record(body, model).each do |key, value|
            if property = properties[fields[key.to_sym]]
              property.set!(resource, value)
            end
          end
        end
                            
        def update(updated_model, collection)
          response = connection.call_update(updated_model.attributes)
      
        rescue SoapError => e
          handle_server_outage(e)
        end

        def delete(collection)
          connection.call_delete(collection)

        rescue SoapError => e
          handle_server_outage(e)
        end

        def handle_server_outage(error)
          if error.server_unavailable?
            raise ServerUnavailable, "The SOAP server is currently unavailable"
          else
            raise error
          end
        end
      end
    end
  end
end