require 'nokogiri'

module DataMapper
  module Adapters
    module Soap
      module XmlDelegate
        
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
        
      end
    end
  end
end