source 'https://rubygems.org'

# Specify your gem's dependencies in dm-mc-rtr-adapter.gemspec
gemspec

group :test do
  gem 'rspec',          '~> 2.13.0',    :require => %w(spec)

  gem 'ParseTree',                  :require => 'parse_tree'
  gem 'dm-sweatshop'
  gem 'dm-sqlite-adapter'
  
  
  DM_VERSION = '~> 1.2.0'
  gem 'dm-types', DM_VERSION
  gem "dm-core",  DM_VERSION

  gem 'savon', '~> 2.2.0'
  gem "mocha", '~> 0.13', :require => false
  gem "soap4r", "~> 1.5.8"
end