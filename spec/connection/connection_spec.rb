require 'spec_helper'
describe DataMapper::Adapters::Soap::Connection do
  describe "Using the raw connection" do
    describe "when authenticating without an organization id" do
      describe "with the correct credentials" do
        it "succeeds" do
          
          @adapter = DataMapper.setup(:soap, {:adapter  => 'soap',
                                         :path     => "http://localhost:3000/accounts/wsdl",
                                         :methods => {:create => 'createAccount',
                                                      :read => 'getAccount',
                                                      :update => 'updateAccount',
                                                      :delete => 'deleteAccount',
                                                      :query => 'queryAccounts'}})
          db = ::DataMapper.repository(:soap).adapter.connection
          #DataMapper::Adapters::Soap::Connection.new(TEST_USERNAME, TEST_PASSWORD, db.wsdl_path, db.api_dir)
        end
      end
    end
  end
end
