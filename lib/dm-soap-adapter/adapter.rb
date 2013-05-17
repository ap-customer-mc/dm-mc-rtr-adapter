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
    require 'debugger'
    debugger
    attribute_body = resources[0].attributes
    result = connection.create(attribute_body)
    result.body

  end

  def update(attributes, collection)
    query = collection.query
    arr   = collection.map { |obj| make_salesforce_obj(query, attributes) }

    connection.update(arr).size

  rescue Connection::SOAPError => e
    handle_server_outage(e)
  end

  def delete(collection)
    query = collection.query
    keys  = collection.map { |r| r.key }.flatten.uniq

    connection.delete(keys).size

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

  # Reading responses back from SELECTS:
  #   In the typical case, response.size reflects the # of records returned.
  #   In the aggregation case, response.size reflects the count.
  #
  # Interpretation of this field requires knowledge of whether we are expecting
  # an aggregate result, thus the response from execute_select() is processed
  # differently depending on invocation (read vs. aggregate).
  def read(query)
    properties = query.fields
    repository = query.repository

    response = execute_select(query)
    return [] unless response.records

    rows = response.records.inject([]) do |results, record|
      results << properties.inject({}) do |result, property|
        meth = connection.field_name_for(property.model.storage_name(repository.name), property.field)
        result[property] = normalize_id_value(query.model, property, record.send(meth))
        result
      end
    end

    query.model.load(rows, query)
  end

  def aggregate(query)
    query.fields.each do |f|
      unless f.target == :all && f.operator == :count
        raise ArgumentError, %{Aggregate function #{f.operator} not supported in SOQL}
      end
    end

    [ execute_select(query).size ]
  end

  private
  def execute_select(query)
    repository = query.repository
    conditions = query.conditions.map {|c| conditions_statement(c, repository)}.compact.join(") AND (")

    fields = query.fields.map do |f|
      case f
      when DataMapper::Property
        f.field
      when DataMapper::Query::Operator
        %{#{f.operator}()}
      else
        raise ArgumentError, "Unknown query field #{f.class}: #{f.inspect}"
      end
    end.join(", ")

    sql = "SELECT #{fields} from #{query.model.storage_name(repository.name)}"
    sql << " WHERE (#{conditions})" unless conditions.empty?

    DataMapper.logger.debug sql if DataMapper.logger

    connection.query(sql)
  end

  def make_salesforce_obj(from, with_attrs)
    klass_name = from.model.storage_name(from.repository.name)
    values     = {}

    # FIXME: query.conditions is potentially a tree now
    if from.is_a?(::DataMapper::Query)
      key_value    = from.conditions.find { |c| c.subject.key? }.value
      values["id"] = normalize_id_value(from.model, from.model.properties[:id], key_value)
    end

    with_attrs.each do |property, value|
      next if property.serial? || property.key? and value.nil?
      values[property.field] = normalize_id_value(from.model, property, value)
    end

    connection.make_object(klass_name, values)
  end

  def normalize_id_value(klass, property, value)
    return nil unless value
    properties = Array(klass.send(:salesforce_id_properties)).map { |p| p.to_sym } rescue []
    return properties.include?(property.name) ? value[0..17] : value
  end
end
end