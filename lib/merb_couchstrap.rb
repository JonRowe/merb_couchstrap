if defined?(Merb::Plugins)
  class MerbCouchstrap < Merb::BootLoader
    after BeforeAppLoads
      
    class << self
      attr_accessor :host
      attr_accessor :port
      attr_accessor :database
      attr_accessor :couch
      attr_accessor :db
      
      def host
        @host ||= 'http://127.0.0.1'
      end
      
      def port
        @port ||= '5984'
      end
      
      def uri
        self.host + ':' + self.port.to_s
      end
      
      def run
        if File.file?(config_file)
          full_config ||= Erubis.load_yaml_file(config_file)
          environment_config = get_config_for_environment(full_config)
          
          self.host = environment_config[:host]
          self.port = environment_config[:port]
          self.database = environment_config[:database]
          
          unless self.database.nil?
            self.couch = CouchRest.new(self.uri)
            self.couch.default_database = self.database
            self.db = self.couch.database(self.database)
          end
        else
          Merb.logger.info "no couch.yml file found, so I won't work"
        end
      end
    
      def config_file() Merb.dir_for(:config) / "couch.yml" end

      private

      #shamelessly lifted from merb_datamapper
      def symbolize_keys(h)
        config = {}

        h.each do |k, v|
          if k == 'port'
            config[k.to_sym] = v.to_i
          elsif v.is_a?(Hash)
            config[k.to_sym] = symbolize_keys(v)
          else
            config[k.to_sym] = v
          end
        end

        return config
      end

      #shamelessly lifted from merb_datamapper
      def get_config_for_environment(full_config)
        if hash = full_config[Merb.environment]
          return symbolize_keys(hash)
        elsif hash = full_config[Merb.environment.to_sym]
          return hash
        else
          raise ArgumentError, "missing environment '#{Merb.environment}' in config file #{config_file}"
        end
      end 
      
    end
  end
end