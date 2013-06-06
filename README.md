## Installation

Add this line to your application's Gemfile:

    gem 'dm-soap-adapter'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install dm-soap-adapter

## Usage

To test the dm-soap-adapter:

CD into WebServiceTime (the mock SOAP webservice) and run:

    rails s -p 3000

Then from the dm-soap-adapter project run:

    ruby example.rb

  This will test the methods on the SOAP adapter. All configuration is in the example.rb file.
  
  All of the configuration for the adapter is in example.rb.
  
    @adapter = DataMapper.setup(:soap, {:adapter  => 'soap',
                                   :username => 'api-user@example.org',
                                   :password => 'PASSWORD',
                                   :path     => "http://localhost:3000/accounts/wsdl",
                                   :methods => {:create => 'createAccount',
                                                :read => 'getAccount',
                                                :update => 'updateAccount',
                                                :delete => 'deleteAccount',
                                                :all => 'allAccounts'}})