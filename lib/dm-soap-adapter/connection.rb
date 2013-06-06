require 'dm-soap-adapter/connection/errors'   
require 'savon' 

class SoapAdapter
  class Connection
    include Errors
    
    Inflector = ::DataMapper::Inflector

    def initialize(options)
      @client = Savon.client(wsdl: options['path'])
      @options = options
    end

    def make_object(klass_name, values)
      obj = ::Class.const_get(klass_name.to_s).new
      response_props = values.flatten[1]
      response_props.each do |property, value|
        field = field_name_for(klass_name.to_s, property)
        if !value.nil? or value != ""
          obj.send("#{field}=", value)
        end
      end
      obj
    end
    
    def field_name_for(klass_name, column)
          klass = ::Class.const_get(klass_name)
          fields = [column, Inflector.camelize(column.to_s), "#{Inflector.camelize(column.to_s)}__c", "#{column}__c".downcase]
          options = /^(#{fields.join("|")})$/i
          matches = klass.type.model.instance_methods.grep(options)
          if matches.any?
            matches.first
          else
            raise FieldNotFound,
                "You specified #{column} as a field, but none of the expected field names exist: #{fields.join(", ")}. " \
                "Either manually specify the field name with :field, or check to make sure you have " \
                "provided a correct field name."
          end
        end

    def create(objects)
      call_service(@options['methods']['create'], message: objects)
    end

    def update(objects)
      call_service(@options['methods']['update'], message: objects)
    end

    def delete(keys)
      call_service(@options['methods']['delete'], message: keys)
    end
    
    def get(id)
      call_service(@options['methods']['read'], message: id)
    end
    
    def call_service(operation, objects)
      response = @client.call(operation.snakecase.to_sym, objects)
      if !response.body.nil? || !response.body.empty?
        make_object(@options[:class], response.body)
      end
    end
    
  end # End Connection
end # End SoapAdapter