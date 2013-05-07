require 'dm-soap-adapter/connection/errors'

class SOAPAdapter
  class Connection
    include Errors

    class HeaderHandler < SOAP::Header::SimpleHandler
      def initialize(tag, value)
        super(XSD::QName.new('urn:enterprise.soap.sforce.com', tag))
        @tag = tag
        @value = value
      end
      def on_simple_outbound
        @value
      end
    end

    def initialize(username, password, wsdl_path, api_dir)
      @wrapper = SoapWrapper.new("GenericAPI", "SOAP", wsdl_path, api_dir)
      @username, @password = URI.unescape(username), password
    end
    attr_reader :user_id, :user_details

    def wsdl_path
      @wrapper.wsdl_path
    end

    def api_dir
      @wrapper.api_dir
    end

    def make_object(klass_name, values)
      obj = ::GenericAPI.const_get(klass_name).new
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

    def field_name_for(klass_name, column)
      klass = Object.const_get(klass_name)
      fields = [column, Inflector.camelize(column.to_s), "#{Inflector.camelize(column.to_s)}__c", "#{column}__c".downcase]
      options = /^(#{fields.join("|")})$/i
      matches = []
      klass.instance_methods.each{ |x| if fields.include? x.to_s then matches << x end }
      if matches.any?
        matches.first
      else
        raise FieldNotFound,
            "You specified #{column} as a field, but none of the expected field names exist: #{fields.join(", ")}. " \
            "Either manually specify the field name with :field, or check to make sure you have " \
            "provided a correct field name."
      end
    end

    def query(string)
      with_reconnection do
        res = driver.query(:queryString => string).result
        records = res.records
        while !res.done
          res = driver.queryMore(:queryLocator => res.queryLocator).result
          records += res.records
        end
        res.records = records 
        res
      end
    rescue SOAP::FaultError => e
      raise QueryError.new(e.message, [])
    end

    def create(objects)
      call_api(:create, CreateError, "creating", objects)
    end

    def update(objects)
      call_api(:update, UpdateError, "updating", objects)
    end

    def delete(keys)
      call_api(:delete, DeleteError, "deleting", keys)
    end

    private

    def driver
      @wrapper.driver
    end

    def call_api(method, exception_class, message, args)
      with_reconnection do
        result = driver.send(method, args)
        if result.all? {|r| r.success}
          result
        else
          # TODO: be smarter about exceptions here
          raise exception_class.new("Got some errors while #{message} Salesforce objects", result)
        end
      end
    end

    def with_reconnection(&block)
      yield
      rescue SOAP::FaultError => error
      retry_count ||= 0

      case error.faultcode.text
      when "sf:INVALID_SESSION_ID" then
        DataMapper.logger.debug "Got a invalid session id; reconnecting" if DataMapper.logger
        @driver = nil
        login
        retry_count += 1
        retry unless retry_count > 5
      else raise error
      end
    end
  end
end