require 'savon'
require 'httpi'

=begin
  Modify HTTPI SSL Handling to use PKCS#12 key stores
=end
module HTTPI
  module Auth
    class SSL
        @pkcs12
        # Returns whether SSL configuration is present.
        def present?
            (verify_mode == :none) || (cert && cert_key)
            rescue TypeError, Errno::ENOENT
            false
        end

        def plcs_file(certFile, certPass)
          @pkcs12 = OpenSSL::PKCS12.new(File.binread(certFile), certPass)
          ca_cert_file = nil
        end

        # Returns an <tt>OpenSSL::X509::Certificate</tt> for the +cert_file+.
        def cert
            @cert = (@pkcs12.certificate if @pkcs12)
        end

        # Returns an <tt>OpenSSL::PKey::RSA</tt> for the +cert_key_file+.
        def cert_key
            @cert_key = (@pkcs12.key if @pkcs12)
        end
    end
  end
end

=begin
  Modify Savon to accept and use key store options
=end

module Savon
  class Options
    def ssl_keystore_file(ssl_pkcs12_file)
      @options[:ssl_keystore_file] = ssl_pkcs12_file
    end

    def ssl_keystore_password (ssl_pkcs12_password)
      @options[:ssl_keystore_password] = ssl_pkcs12_password
    end
  end

  class HTTPRequest
    def configure_ssl
      if @globals.include? :ssl_keystore_file
        @http_request.auth.ssl.plcs_file(@globals[:ssl_keystore_file], @globals[:ssl_keystore_password])
        @http_request.auth.ssl.verify_mode = :none
      else
        raise ArgumentError, "PKCS12 SSL keystore not set"
      end
    end
  end
end

module DataMapper
  module Adapters
    module Soap
      class Connection
        def initialize(options)
          @wsdl_path = options.fetch(:wsdl_store)
          @ssl_keystore_file = options.fetch(:ssl_keystore_file)
          @ssl_keystore_password = options.fetch(:ssl_keystore_password)
          @create_method = options.fetch(:create) if options[:create]
          @read_method = options.fetch(:read) if options[:read]# This maps to get a single object
          @update_method = options.fetch(:update) if options[:update]
          @delete_method = options.fetch(:delete) if options[:delete]
          # So... this would be "query" and we stuff everything here and hope the other side knows how to handle it
          @query_method = options.fetch(:all)

          savon_ops = { wsdl: "#{Rails.root}#{@wsdl_path}", ssl_keystore_file: "#{Rails.root}#{@ssl_keystore_file}", ssl_keystore_password: @ssl_keystore_password, logger: Rails.logger, log_level: :info, log: true,  pretty_print_xml: true}

          auth_ops = {}
          if options[:username] && options[:password]
            auth_ops[:wsse_auth] = [options[:username], options[:password]]
            auth_ops[:wsse_auth] << :digest if options[:digest]
          end

          savon_ops.merge!(auth_ops)

          if options[:logging_level] && %w[ off fatal error warn info debug ].include?(options[:logging_level].downcase)
            level = options[:logging_level].downcase
            if level == 'off'
              savon_ops.merge!(log: false)
            else
              savon_ops.merge!(log: true, logger: DataMapper.logger, log_level: level.to_sym)
            end
          end

          @client = Savon.client(savon_ops)
          @options = options
          @expose_client = @options.fetch(:enable_mock_setters, false)
        end

        def client=(client)
          @client = client if @expose_client
        end

        def call_create(objects)
          call_service(@create_method, message: objects)
        end

        def call_update(objects)
          call_service(@update_method , message: objects)
        end

        def call_delete(keys)
          call_service(@delete_method, message: keys)
        end

        def call_get(id)
          call_service(@read_method, message: id)
        end

        def call_query(method, query)
          call_service(method, xml: query)
        end

        def call_service(operation, objects)
          DataMapper.logger.debug( "calling client #{operation.to_sym} with #{objects.inspect}")
          response = @client.call(operation.to_sym, objects)
        end

      end
    end
  end
end
