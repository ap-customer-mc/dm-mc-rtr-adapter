require 'dm-soap-adapter/connection/errors'
require 'savon' 

class SoapAdapter
  class Connection
    include Errors

    def initialize(options)
      @client = Savon.client(wsdl: options['path'])
      @options = options
    end

    def make_object(klass_name, values)
      obj = ::Generic.const_get(klass_name).new
      values.each do |property, value|
        field = field_name_for(klass_name, property)
        if value.nil? or value == ""
          obj.fieldsToNull.push(field)
        else
          obj.send("#{field}=", value)
        end
      end
      obj
    end

    def create(objects)
      response = @client.call(@options['methods']['create'].to_sym, message: objects)
      return response.body
    end

    def update(objects)
      response = @client.call(@options['methods']['update'].to_sym, message: objects)
      return response.body
    end

    def delete(keys)
      response = @client.call(@options['methods']['delete'].to_sym, message: keys)
      return response.body
    end
  end
end


