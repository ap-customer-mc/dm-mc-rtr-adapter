
module DataMapper
  module Adapters
    module Soap
      class Adapter < DataMapper::Adapters::AbstractAdapter
        include Errors, ParserDelegate, QueryDelegate
        
        def initialize(name, options)
          super
          @options = options
          @expose_connection = @options.fetch(:enable_mock_setters, false)
          initialize_logger
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
        
        # Reads one or many resources from a datastore
        #
        # @example
        #   adapter.read(query)  # => [ { 'name' => 'Dan Kubb' } ]
        #
        # Adapters provide specific implementation of this method
        #
        # @param [Query] query
        #   the query to match resources in the datastore
        #
        # @return [Enumerable<Hash>]
        #   an array of hashes to become resources
        #
        # @api semipublic
        def read(query)
          @log.debug("Read #{query.inspect} and its model is #{query.model.inspect}")
          model = query.model
          soap_query = build_query(query)
          begin
            
            response = connection.call_query(soap_query)
            @log.debug("response was #{response.inspect}")
            body = response.body
            return [] unless body
            return parse_collection(body, model)
          rescue SoapError => e
            handle_server_outage(e)
          end
        end

        # Persists one or many new resources
        #
        # @example
        #   adapter.create(collection)  # => 1
        #
        # Adapters provide specific implementation of this method
        #
        # @param [Enumerable<Resource>] resources
        #   The list of resources (model instances) to create
        #
        # @return [Integer]
        #   The number of records that were actually saved into the data-store
        #
        # @api semipublic  
        def create(resources)
          resources.each do |resource|
            model = resource.model
            @log.debug("About to create #{model} using #{resource.attributes}")
            
            begin
              response = connection.call_create(resource.attributes)
              @log.debug("Result of actual create call is #{response.inspect}")
              result = update_attributes(resource, response.body)
            rescue SoapError => e
              handle_server_outage(e)    
            end
          end
        end
        
        # Updates one or many existing resources
        #
        # @example
        #   adapter.update(attributes, collection)  # => 1
        #
        # Adapters provide specific implementation of this method
        #
        # @param [Hash(Property => Object)] attributes
        #   hash of attribute values to set, keyed by Property
        # @param [Collection] collection
        #   collection of records to be updated
        #
        # @return [Integer]
        #   the number of records updated
        #
        # @api semipublic
        def update(attributes, collection)
          @log.debug("Update called with:\nAttributes #{attributes.inspect} \nCollection: #{collection.inspect}")
          collection.select do |resource|

            attributes.each { |property, value| property.set!(resource, value) }
            @log.debug("About to call update with #{resource.attributes}")
            begin
              response = connection.call_update(resource.attributes)
              body = response.body
              update_attributes(resource, body)
            rescue SoapError => e
              handle_server_outage(e)
            end
          end.size
        end
        
        # Deletes one or many existing resources
        #
        # @example
        #   adapter.delete(collection)  # => 1
        #
        # Adapters provide specific implementation of this method
        #
        # @param [Collection] collection
        #   collection of records to be deleted
        #
        # @return [Integer]
        #   the number of records deleted
        #
        # @api semipublic
        def delete(collection)
          collection.select do |resource|
            model = resource.model
            key = model.key
            id = key.get(resource).join
            begin
              connection.call_delete({ key.first.field.to_sym => id})
            rescue SoapError => e
              handle_server_outage(e)
            end
          end.size
        end

        def update_attributes(resource, body)
          return if DataMapper::Ext.blank?(body)
          fields = {}
          model      = resource.model
          properties = model.properties(model.default_repository_name)
          properties.each do |prop| 
            fields[prop.field.to_sym] = prop.name.to_sym
          end
          @log.debug( "Properties are #{properties.inspect} and body is #{body.inspect}")
          
          parse_record(body, model).each do |key, value|
            if property = properties[fields[key.to_sym]]
              property.set!(resource, value)
            end
          end
        end
        
        def handle_server_outage(error)
          if error.server_unavailable?
            raise ServerUnavailable, "The SOAP server is currently unavailable"
          else
            raise error
          end
        end
        
        def initialize_logger
          level = 'error'

          if @options[:logging_level] && %w[ off fatal error warn info debug ].include?(@options[:logging_level].downcase)
            level = @options[:logging_level].downcase
          end
          DataMapper::Logger.new($stdout,level)
          @log = DataMapper.logger
        end
      end # class Adapter
    end
    
    ::DataMapper::Adapters::SoapAdapter = DataMapper::Adapters::Soap::Adapter
    self.send(:const_added,:SoapAdapter)
  end
end