module DataMapper
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
                                                      :all => 'allAccounts'}})
          db = ::DataMapper.repository(:soap).adapter.connection
          Connection.new(VALID_USER.username, VALID_USER.password, db.wsdl_path, db.api_dir)
        end
      end
    end
  end
end
