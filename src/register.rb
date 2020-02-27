require 'json'

PLUGINS_REGISTER_FILE = "./plugins.json";

class Register

    def initialize()
        if !File.file?(PLUGINS_REGISTER_FILE)
            raise "Fail to find register file: #{PLUGINS_REGISTER_FILE}"
        end
        @register_str = File.read("#{PLUGINS_REGISTER_FILE}")
        @plugins = JSON.parse(@register_str)
        @cursor = 0
        puts "Register file #{PLUGINS_REGISTER_FILE} is read. Found #{@plugins.length} entries"
    end

    def self.validate(entry)
        if !entry.has_key?('name')
            puts "Field \"name\" not found"
            return false
        end
        if !entry.has_key?('repo')
            puts "Field \"repo\" not found"
            return false
        end
        if !entry.has_key?('version')
            puts "Field \"version\" not found"
            return false
        end
        true
    end

    def self.normalize(entry)
        if !entry.has_key?('default')
            entry['default'] = false
        end
        if !entry.has_key?('has_to_be_signed')
            entry['has_to_be_signed'] = false
        end
        return entry
    end

    def next
        if (@cursor >= @plugins.length)
            return nil
        end
        loop do
            if (@cursor >= @plugins.length)
                return nil
            end
            @cursor = @cursor + 1
            if self.class.validate(@plugins[@cursor - 1]) 
               return self.class.normalize(@plugins[@cursor - 1])
            end
        end
    end

    def get_by_name(name)
        result = nil
        @plugins.each { |plugin|
            if plugin['name'] == name
                result = self.class.normalize(plugin)
            end
        }
        return result
    end

end
