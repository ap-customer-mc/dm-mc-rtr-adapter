require 'spec_helper'

describe DataMapper::Adapters::Soap::Adapter do
  include Savon::SpecHelper
  
  before(:all) do
    @adapter = DataMapper.setup(:default, 
      { :adapter  => :soap,
        :path     => "http://#{HOST}:#{PORT}/HeffalumpsWS",
        :create => 'CreateHeffalump',
        :read => 'GetHeffalump',
        :update => 'UpdateHeffalump',
        :delete => 'DeleteHeffalump',
        :all => 'QueryHeffalumps',
        :enable_mock_setters => true
      }
    )
    @client = mock('client')
    @adapter.connection.client = @client
    @response = mock('response')
  end
  
  after(:all) do
  end
  
  describe '#create' do

      it 'should not raise any errors' do
        heffalump = Heffalump.new(:color => 'peach')            
        result = {:id => 1, :color => "peach"}
        @client.expects(:call).with(:CreateHeffalump, {:message => {:color => 'peach'}}).once.returns(@response)
        @response.expects(:body).once.returns(result)
        lambda {
          heffalump.save
        }.should_not raise_error
      end

      it 'should set the identity field for the resource' do
          heffalump = Heffalump.new(:color => 'peach')
          result = {:id => 2, :color => "peach"}
          heffalump.id.should be_nil
          @client.expects(:call).with(:CreateHeffalump, {:message => {:id => nil, :color => 'peach'}}).once.returns(@response)
          @response.expects(:body).once.returns(result)
          heffalump.save.should be_true
          heffalump.id.should_not be_nil
          heffalump.id.should be_a_kind_of(Numeric)
          heffalump.id.should == 2
          heffalump.color.should == 'peach'
      end

    end

    describe '#read' do
      before(:all) do
        @result = {:id => 3, :color => "peach", :num_spots => nil}
        @heffalump = Heffalump.new(:color => 'peach')

      end
        
        it 'should get by ID' do
          @client.expects(:call).with(:CreateHeffalump, {:message => {:color => 'peach'}}).once.returns(@response)
          @response.expects(:body).once.returns(@result)
          #save instance
          @heffalump.save!.should be_true
          @heffalump.id.should_not be_nil
          
          @client.expects(:call).with(:QueryHeffalumps, {:message => {
            :model => 'heffalumps', 
            :fields => [:id, :color, :num_spots, :latitude, :striped, :created, :at_time], 
            :conditions => [{:equal => [:id, 3]}], 
            :limit => 1, 
            :offset => 0}}).once.returns(@response)
          @response.expects(:body).once.returns([@result])
          lump = Heffalump.get(3)
          lump.should == @heffalump
        end
        
        it 'should query' do
          @client.expects(:call).with(:QueryHeffalumps, {:message => {:model => 'heffalumps', :fields => [:id, :color, :num_spots, :latitude, :striped, :created, :at_time], :conditions => [], :order => [{:id => :asc}], :offset => 0}}).once.returns(@response)
          @response.expects(:body).once.returns([@result])
          Heffalump.all().should be_include(@heffalump)
        end
    end

    describe '#update' do
        before do
          @result = {:id => 4, :color => "indigo", :num_spots => nil, :latitude => nil, :striped => nil, :created => nil, :at_time => nil}
          @heffalump = Heffalump.new(:color => 'indigo')
          @client.expects(:call).with(:CreateHeffalump, {:message => {:color => 'indigo'}}).once.returns(@response)
          @response.expects(:body).once.returns(@result)
          @heffalump.save.should be_true
        end

        it 'should not raise any errors' do
          lambda {
            @heffalump.color.should == 'indigo'
            
            @heffalump.color = 'violet'
            
            @client.expects(:call).with(:UpdateHeffalump, {:message => {:id => 4, :color => 'violet', :num_spots => nil, :latitude => nil, :striped => nil, :created => nil, :at => nil}}).once.returns(@response)
            @response.expects(:body).once.returns([{:id => 4, :color => 'violet', :num_spots => nil, :latitude => nil, :striped => nil, :created => nil, :at_time => nil}])
            
            @heffalump.save.should be_true
            @heffalump.color.should == 'violet'
          }.should_not raise_error
        end

        it 'should not alter the identity field' do
          @heffalump.color.should == 'indigo'
          id = @heffalump.id
          @heffalump.color = 'violet'
          @client.expects(:call).with(:UpdateHeffalump, {:message => {:id => 4, :color => 'violet', :num_spots => nil, :latitude => nil, :striped => nil, :created => nil, :at => nil}}).once.returns(@response)
          @response.expects(:body).once.returns([{:id => 4, :color => 'violet', :num_spots => nil, :latitude => nil, :striped => nil, :created => nil, :at_time => nil}])
          
          @heffalump.save.should be_true

          @heffalump.id.should == id
        end

        it 'should update altered fields' do
          @heffalump.color = 'violet'
          @client.expects(:call).with(:UpdateHeffalump, {:message => {:id => 4, :color => 'violet', :num_spots => nil, :latitude => nil, :striped => nil, :created => nil, :at => nil}}).once.returns(@response)
          @response.expects(:body).once.returns([{:id => 4, :color => 'violet', :num_spots => nil, :latitude => nil, :striped => nil, :created => nil, :at_time => nil}])
          @heffalump.save.should be_true
          @client.expects(:call).with(:QueryHeffalumps, {:message => {:model => 'heffalumps', :fields => [:id, :color, :num_spots, :latitude, :striped, :created, :at_time], :conditions => [{:equal => [:id, 4]}], :limit => 1, :offset => 0}}).once.returns(@response)
          @response.expects(:body).once.returns([{:id => 4, :color => 'violet', :num_spots => nil, :latitude => nil, :striped => nil, :created => nil, :at_time => nil}])
          Heffalump.get(*@heffalump.key).color.should == 'violet'
        end

        it 'should not alter other fields' do
          color = @heffalump.color
          @client.expects(:call).with(:UpdateHeffalump, {:message => {:id => 4, :color => 'indigo', :num_spots => 3, :latitude => nil, :striped => nil, :created => nil, :at => nil}}).once.returns(@response)
          @response.expects(:body).once.returns([{:id => 4, :color => 'indigo', :num_spots => 3, :latitude => nil, :striped => nil, :created => nil, :at => nil}])
          @heffalump.num_spots = 3
          @heffalump.save.should be_true
          @client.expects(:call).with(:QueryHeffalumps, {:message => {:model => 'heffalumps', :fields => [:id, :color, :num_spots, :latitude, :striped, :created, :at_time], :conditions => [{:equal => [:id, 4]}], :limit => 1, :offset => 0}}).once.returns(@response)
          @response.expects(:body).once.returns([{:id => 4, :color => 'indigo', :num_spots => 3, :latitude => nil, :striped => nil, :created => nil, :at => nil}])
          Heffalump.get(*@heffalump.key).color.should == color
        end
    end

    describe '#delete' do
        before do
          @result = {:id => 5, :color => 'forest green'}
          @client.expects(:call).with(:CreateHeffalump, {:message => {:color => 'forest green'}}).once.returns(@response)
          @response.expects(:body).once.returns(@result)
          @heffalump = Heffalump.create(:color => 'forest green')
          @heffalump.id.should == 5
        end

        it 'should not raise any errors' do
          @client.expects(:call).with(:DeleteHeffalump, {:message => {:id => '5'}}).once.returns(1)
          lambda {
            @heffalump.destroy
          }.should_not raise_error
        end

        it 'should delete the requested resource' do
          id = @heffalump.id
          @client.expects(:call).with(:DeleteHeffalump, {:message => {:id => '5'}}).once.returns(1)
          @heffalump.destroy
          @client.expects(:call).with(:QueryHeffalumps, {:message => {:model => 'heffalumps', :fields => [:id, :color, :num_spots, :latitude, :striped, :created, :at_time], :conditions => [{:equal => [:id, 5]}], :limit => 1, :offset => 0}}).once.returns(@response)
          @response.expects(:body).once.returns(nil)
          Heffalump.get(id).should be_nil
        end
    end

=begin
    describe 'query matching' do
        require 'dm-core/core_ext/symbol'

        before :all do
          @red = Heffalump.create(:color => 'red')
          @two = Heffalump.create(:num_spots => 2)
          @five = Heffalump.create(:num_spots => 5)
        end

        describe 'conditions' do
          describe 'eql' do
            it 'should be able to search for objects included in an inclusive range of values' do
              Heffalump.all(:num_spots => 1..5).should be_include(@five)
            end

            it 'should be able to search for objects included in an exclusive range of values' do
              Heffalump.all(:num_spots => 1...6).should be_include(@five)
            end

            it 'should not be able to search for values not included in an inclusive range of values' do
              Heffalump.all(:num_spots => 1..4).should_not be_include(@five)
            end

            it 'should not be able to search for values not included in an exclusive range of values' do
              Heffalump.all(:num_spots => 1...5).should_not be_include(@five)
            end
          end

          describe 'not' do
            it 'should be able to search for objects with not equal value' do
              Heffalump.all(:color.not => 'red').should_not be_include(@red)
            end

            it 'should include objects that are not like the value' do
              Heffalump.all(:color.not => 'black').should be_include(@red)
            end

            it 'should be able to search for objects with not nil value' do
              Heffalump.all(:color.not => nil).should be_include(@red)
            end

            it 'should not include objects with a nil value' do
              Heffalump.all(:color.not => nil).should_not be_include(@two)
            end

            it 'should be able to search for objects not included in an array of values' do
              Heffalump.all(:num_spots.not => [ 1, 3, 5, 7 ]).should be_include(@two)
            end

            it 'should be able to search for objects not included in an array of values' do
              Heffalump.all(:num_spots.not => [ 1, 3, 5, 7 ]).should_not be_include(@five)
            end

            it 'should be able to search for objects not included in an inclusive range of values' do
              Heffalump.all(:num_spots.not => 1..4).should be_include(@five)
            end

            it 'should be able to search for objects not included in an exclusive range of values' do
              Heffalump.all(:num_spots.not => 1...5).should be_include(@five)
            end

            it 'should not be able to search for values not included in an inclusive range of values' do
              Heffalump.all(:num_spots.not => 1..5).should_not be_include(@five)
            end

            it 'should not be able to search for values not included in an exclusive range of values' do
              Heffalump.all(:num_spots.not => 1...6).should_not be_include(@five)
            end
          end

          describe 'like' do
            it 'should be able to search for objects that match value' do
              Heffalump.all(:color.like => '%ed').should be_include(@red)
            end

            it 'should not search for objects that do not match the value' do
              Heffalump.all(:color.like => '%blak%').should_not be_include(@red)
            end
          end

          describe 'gt' do
            it 'should be able to search for objects with value greater than' do
              Heffalump.all(:num_spots.gt => 1).should be_include(@two)
            end

            it 'should not find objects with a value less than' do
              Heffalump.all(:num_spots.gt => 3).should_not be_include(@two)
            end
          end

          describe 'gte' do
            it 'should be able to search for objects with value greater than' do
              Heffalump.all(:num_spots.gte => 1).should be_include(@two)
            end

            it 'should be able to search for objects with values equal to' do
              Heffalump.all(:num_spots.gte => 2).should be_include(@two)
            end

            it 'should not find objects with a value less than' do
              Heffalump.all(:num_spots.gte => 3).should_not be_include(@two)
            end
          end

          describe 'lt' do
            it 'should be able to search for objects with value less than' do
              Heffalump.all(:num_spots.lt => 3).should be_include(@two)
            end

            it 'should not find objects with a value less than' do
              Heffalump.all(:num_spots.gt => 2).should_not be_include(@two)
            end
          end

          describe 'lte' do
            it 'should be able to search for objects with value less than' do
              Heffalump.all(:num_spots.lte => 3).should be_include(@two)
            end

            it 'should be able to search for objects with values equal to' do
              Heffalump.all(:num_spots.lte => 2).should be_include(@two)
            end

            it 'should not find objects with a value less than' do
              Heffalump.all(:num_spots.lte => 1).should_not be_include(@two)
            end
          end
        end

        describe 'limits' do
          it 'should be able to limit the objects' do
            Heffalump.all(:limit => 2).length.should == 2
          end
        end
      end
=end
end