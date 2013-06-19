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
        
        def make_object(klass_name, values)
          raise "Don't use me brah!"
          obj = ::Class.const_get(klass_name.to_s).new
          response_props = values.flatten[1]
          response_props.each do |property, value|
            puts "calling field name for #{klass_name.to_s} and #{property}"
            field = field_name_for(klass_name.to_s, property)
            if !value.nil? or value != ""
              puts "setting #{field.inspect} to #{value.inspect}"
              obj.send("#{field}=", value)
            end
          end
          puts "returning #{obj.inspect}"
          obj
        end
    
        def field_name_for(klass_name, column)
          raise "Don't use me brah!"
          klass = ::Class.const_get(klass_name)
          fields = [column, ::DataMapper::Inflector.camelize(column.to_s), "#{::DataMapper::Inflector.camelize(column.to_s)}__c", "#{column}__c".downcase]
          options = /^(#{fields.join("|")})$/i
          matches = klass.instance_methods.grep(options)
          if matches.any?
            matches.first
          else
            raise ::DataMapper::Adapters::Soap::Errors::FieldNotFound,
                "You specified #{column} as a field, but none of the expected field names exist: #{fields.join(", ")}. " \
                "Either manually specify the field name with :field, or check to make sure you have " \
                "provided a correct field name."
          end
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