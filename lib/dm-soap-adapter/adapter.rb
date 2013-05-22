module DataMapperSoap
  class Adapter < DataMapper::Adapters::AbstractAdapter
    Inflector = ::DataMapper::Inflector
  
    def initialize(name, options)
      super
      @resource_naming_convention = proc do |value|
        klass = Inflector.constantize(value)
        value.split("::").last
      end
      @field_naming_convention = proc do |property|
        connection.field_name_for(property.model.storage_name(name), property.name.to_s)
      end
    end

    def connection
      @connection ||= SoapAdapter::Connection.new(@options)
    end

  
    def create(resources)
      attribute_body = resources[0].attributes
      result = connection.create(attribute_body)
    
      rescue Connection::SOAPError => e
        handle_server_outage(e)
      end

    def update(attributes, collection)
      connection.update(collection)
      rescue Connection::SOAPError => e
        handle_server_outage(e)
    end

    def delete(collection)
      connection.delete(collection).size

      rescue Connection::SOAPError => e
        handle_server_outage(e)
    end

    def handle_server_outage(error)
      if error.server_unavailable?
        raise Connection::ServerUnavailable, "The SOAP server is currently unavailable"
      else
        raise error
      end
    end
  end
end