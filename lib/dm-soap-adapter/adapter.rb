
module DataMapper
  module Adapters
    module Soap
      class Adapter < DataMapper::Adapters::AbstractAdapter
        include Errors
        
        attr_accessor :repository_name
        
        def initialize(name, options)
          super
          @repository_name = options.fetch(:repository_name, :default)
        end

        def connection=(connection)
          @connection = connection if @options.fetch(:enable_mock_setters)
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
          puts 'Not Yet Implemented.'
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
        
        def parse_collection(xml, model)
          xml_doc = Nokogiri::XML(xml)

          field_to_property = Hash[ model.properties(repository_name).map { |p| [ p.field, p ] } ]      

          xml_doc.xpath("//#{element_name_plural(model)}/#{element_name(model)}") do |entity_element|
            record_from_xml(entity_element, field_to_property)
          end
        end
              
        def parse_record(xml,model)
          xml_doc = Nokogiri::XML(xml)
          field_to_property = Hash[ model.properties(model.default_repository_name).map { |p| [ p.field, p ] } ]
          DataMapper.logger.debug("xml is #{xml.inspect}")
          entity_element = xml_doc.xpath("/#{element_name(model)}").first
          record_from_xml(entity_element, field_to_property)
        end
        
        def record_from_xml(entity_element, field_to_property)
          record = {}
          
          entity_element.elements.map do |element|
            field = element.name.to_s.tr('-', '_')
            property = field_to_property[field]
            if property.nil?
              field = snake_case(field)
              property = field_to_property[field]
            end
            
            if property.instance_of? DataMapper::Property::Object
              raise "Array properties are not yet supported!"
              record[field] = parse_array(element.to_s,element.name.to_s.tr('-', '_'))
            else
              next unless property
              record[field] = property.typecast(element.text)
            end
          end

          record
        end
        
        def resource_name(model)
          model.respond_to?(:storage_name) ? model.storage_name(repository_name) : model
        end
           
        def element_name(model)
          DataMapper::Inflector.singularize(resource_name(model))
        end

        def element_name_plural(model)
          DataMapper::Inflector.pluralize(resource_name(model))
        end
                 
        def snake_case(camel) 
          if camel == "ID"
            "id"
          else
            camel.gsub(/(.)([A-Z])/,'\1_\2').downcase
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