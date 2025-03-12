require 'faraday'
require 'json'

module Transmission
  class RPC
    class Connector
      class AuthError < StandardError; end
      class ConnectionError < StandardError; end

      attr_accessor :host, :port, :ssl, :credentials, :path, :session_id, :response

      def initialize(options = {})
        @host = options[:host] || 'localhost'
        @port = options[:port] || 9091
        @ssl  = !!options[:ssl]
        @credentials = options[:credentials] || nil
        @path = options[:path] || '/transmission/rpc'
        @session_id = options[:session_id] || ''
      end

      def post(params = {})
        response = connection.post do |req|
          req.url @path
          req.headers['X-Transmission-Session-Id'] = @session_id
          req.headers['Content-Type'] = 'application/json'
          req.body = JSON.generate(params)
        end
        handle_response response, params
      end

      private

      def mangle_json(str)
        str.gsub(/\\u([0-9a-f]{5,6})/i) do
          begin
            $1.to_i(16).chr(Encoding::UTF_8)
          rescue RangeError
            $&
          end
        end
      end

      def json_body(response)
        JSON.parse mangle_json(response.body)
      rescue
        {}
      end

      def handle_response(response, params)
        @response = response
        if response.status == 409
          @session_id = response.headers['x-transmission-session-id']
          return self.post(params)
        end
        body = json_body response
        raise AuthError if response.status == 401
        raise ConnectionError, body['result'] unless response.status == 200 && body['result'] == 'success'
        body['arguments']
      end

      def connection
        @connection ||= begin
          connection = Faraday.new(:url => "#{scheme}://#{@host}:#{@port}", :ssl => {:verify => false}) do |faraday|
            faraday.request  :url_encoded
            faraday.response :logger
            faraday.adapter  Faraday.default_adapter
            faraday.request :authorization, :basic, @credentials[:username], @credentials[:password]
          end
          connection
        end
      end

      def scheme
        @ssl ? 'https' : 'http'
      end
    end
  end
end
