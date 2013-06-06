require 'data_objects'
require 'dm-core'
require 'dm-validations'

require 'dm-soap-adapter/resource'
require 'dm-soap-adapter/connection'
require 'dm-soap-adapter/connection/errors'
require 'dm-soap-adapter/version'
require 'dm-soap-adapter/adapter'

::DataMapper::Adapters::SoapAdapter = DataMapperSoap::Adapter
::DataMapper::Adapters.const_added(:soap)