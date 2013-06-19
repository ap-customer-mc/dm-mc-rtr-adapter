
module DataMapper
  module Adapters
    module Soap
      module ParserDelegate
        
        def parse_collection(array, model)
          DataMapper.logger.debug("parse_collection is about to parse\n #{array.inspect}")
          array.collect do |instance|
            parse_record(instance, model)
          end
        end
        
        def parse_record(hash,model)
          field_to_property = make_field_to_property_hash(model)
          DataMapper.logger.debug("parse_record is converting #{hash.inspect} using #{field_to_property.inspect} for model #{model}")
          record_from_hash(hash, field_to_property)
        end

        def record_from_hash(hash, field_to_property)
          record = {}
          hash.each do |field, value|
            name = field.to_s
            property = field_to_property[name]

            if property.nil?
              property = field_to_property[name.to_sym]
            end
            
            if property.instance_of? DataMapper::Property::Object
              raise "Array properties are not yet supported!"
            else
              next unless property
              record[name] = property.typecast(value)
            end
          end

          record
        end

        def make_field_to_property_hash(model)
          Hash[ model.properties(model.default_repository_name).map { |p| [ p.field, p ] } ]
        end
        
        def resource_name(model)
          model.respond_to?(:storage_name) ? model.storage_name(repository_name) : model
        end

      end
    end
  end
end