require 'rubygems'
require 'pathname'

# Support running specs with 'rake spec' and 'spec'
$LOAD_PATH.unshift('lib') unless $LOAD_PATH.include?('lib')

require 'dm-mc-rtr-adapter'
require "savon/mock/spec_helper"
require 'dm-core/spec/shared/adapter_spec'

require 'mocha/api'

#DataMapper::Logger.new(STDOUT, :debug)

ROOT = Pathname(__FILE__).dirname.parent

Pathname.glob((ROOT + 'spec/fixtures/**/*.rb').to_s).each { |file| require file }
Pathname.glob((ROOT + 'spec/**/shared/**/*.rb').to_s).each { |file| require file }

ENV['ADAPTER'] = 'soap'
ENV['ADAPTER_SUPPORTS'] = 'all'
HOST = "localhost"
PORT = 9999
TEST_USERNAME = 'humpty'
TEST_PASSWORD = 'dumpty'

DataMapper.finalize

RSpec.configure do |config|
  config.mock_framework = :mocha
end