require 'json'
require './src/github'
require './src/tools'

RELEASES_FILE_NAME = "releases"
RELEASE_URL_PATTERN = "https://github.com/DmitryAstafyev/chipmunk.plugins.store/releases/download/${tag}/${file_name}"

class Releases

    def initialize(versions)
        @versions = versions
        @git = Github.new()
        @releases = @git.get_releases_list(self.class.get_name())
        @tag = @git.get_last_tag()
        puts "Last tag detected: #{@tag.name}"
    end

    def exist(file_name)
        result = false
        @releases.each { |release|
            if release['file'] == file_name
                result = true
            end
        }
        return result
    end

    def add(name, file_name, version)
        @releases = @releases.select do |release|
            release['name'] != name
        end
        @releases.push({
            "name" => name,
            "file" => file_name,
            "version" => version,
            "url" => RELEASE_URL_PATTERN.sub("${tag}", @tag.name).sub("${file_name}", file_name)
        });
    end

    def write
        if !File.directory?(PLUGIN_RELEASE_FOLDER)
            Rake.mkdir_p(PLUGIN_RELEASE_FOLDER, verbose: true)
            puts "Creating release folder: #{TMP_FOLDER}"
        end
        File.open("./#{PLUGIN_RELEASE_FOLDER}/#{self.class.get_name()}","w") do |f|
            f.write(@releases.to_json)
        end
    end

    def normalize(register)
        result = []
        @releases.each { |release|
            plugin = register.get_by_name(release['name'])
            if plugin != nil
                result.push({
                    "name" => release['name'],
                    "file" => release['file'],
                    "version" => release['version'],
                    "url" => release['url'],
                    "hash" => @versions.get_hash(),
                    "default" => plugin['default'],
                    "signed" => plugin['has_to_be_signed'],
                })
            end
        }
        @releases = result
    end

    def get_url(file_name)
        return RELEASE_URL_PATTERN.sub("${tag}", @tag.name).sub("${file_name}", file_name)
    end

    def self.get_name()
        return "#{RELEASES_FILE_NAME}-#{get_nodejs_platform()}.json"
    end
    
end
