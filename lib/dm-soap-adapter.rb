require 'data_objects'
require 'dm-core'
require 'dm-types'
require 'dm-validations'

require 'soap/wsdlDriver'
require 'soap/header/simplehandler'
require 'rexml/element'

class SOAPAdapter < ::DataMapper::Adapters::AbstractAdapter
  Inflector = ::DataMapper::Inflector
end

require 'dm-soap-adapter/resource'
require 'dm-soap-adapter/connection'
require 'dm-soap-adapter/connection/errors'
require 'dm-soap-adapter/soap_wrapper'
require 'dm-soap-adapter/version'
require 'dm-soap-adapter/adapter'
require 'dm-soap-adapter/property'

module DataMapper::SOAP
    Resource = SOAPAdapter::Resource
end

::DataMapper::Adapters::SOAPAdapter = SOAPAdapter
::DataMapper::Adapters.const_added(:SOAPAdapter)