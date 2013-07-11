## Installation

Add this line to your application's Gemfile:

    gem 'dm-soap-adapter'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install dm-soap-adapter

## Usage

To test the dm-soap-adapter:

    $ rspec spec
  
    @adapter = DataMapper.setup(:soap, {:adapter  => 'soap',
                                   :username => 'api-user@example.org',
                                   :password => 'PASSWORD',
                                   :path     => "http://localhost:3000/accounts/wsdl",
                                   :methods => {:create => 'createAccount',
                                                :read => 'getAccount',
                                                :update => 'updateAccount',
                                                :delete => 'deleteAccount',
                                                :query => 'queryAccounts'}})