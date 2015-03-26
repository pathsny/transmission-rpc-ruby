describe Transmission::RPC::Connector do

  describe '#new' do

    describe 'without parameters' do
      before :each do
        @connector = Transmission::RPC::Connector.new
      end

      it 'should create an RPC object with default values' do
        expect(@connector.host).to eq('localhost')
        expect(@connector.port).to eq(9091)
        expect(@connector.ssl).to eq(false)
        expect(@connector.path).to eq('/transmission/rpc')
        expect(@connector.credentials).to eq(nil)
      end
    end

    describe 'with parameters' do
      before :each do
        @connector = Transmission::RPC::Connector.new host: 'some.host', port: 8888, ssl: true, path: '/path', credentials: {username: 'a', password: 'b'}
      end

      it 'should create an RPC object with given parameters' do
        expect(@connector.host).to eq('some.host')
        expect(@connector.port).to eq(8888)
        expect(@connector.ssl).to eq(true)
        expect(@connector.path).to eq('/path')
        expect(@connector.credentials).to eq({username: 'a', password: 'b'})
      end
    end

  end

  describe '#post' do

    describe 'when session ID has not been acquired yet' do
      before :each do
        @connector = Transmission::RPC::Connector.new
        stub_rpc status: 409, body: {}.to_json, headers: {'x-transmission-session-id' => 'abc'}
      end

      it 'should save the transmission session ID' do
        expect {
          @connector.post
        }.to raise_error(Transmission::RPC::Connector::InvalidSessionError)
        expect(@connector.session_id).to eq('abc')
      end
    end

    describe 'when session ID has been acquired' do
      before :each do
        @connector = Transmission::RPC::Connector.new
        stub_rpc status: 200, body: {result: 'success'}.to_json
      end

      it 'should respond successfully' do
        @connector.post
        expect(@connector.response.status).to eq(200)
      end
    end

    describe 'when basic auth is required but no credentials provided' do
      before :each do
        @connector = Transmission::RPC::Connector.new
        stub_rpc status: 401, body: {}.to_json
      end

      it 'should raise auth error' do
        expect {
          @connector.post
        }.to raise_error(Transmission::RPC::Connector::AuthError)
      end
    end

  end

end