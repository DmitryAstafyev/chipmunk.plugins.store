require 'octokit'

REPO = "DmitryAstafyev/logviewer"

class Github
      
    def get_assets_names
        puts "Getting list of published assets"
        all = []
        client = Octokit::Client.new(:access_token => ENV['CHIPMUNK_PLUGINS_STORE_GITHUB_TOKEN'])
        releases = client.releases(REPO, {})
        releases.each { |x|
            assets = client.release_assets(x.url, {})
            assets.each { |a|
                all.push(a.name)
            }
        }
        puts "List is gotten: #{all.length} item(s)"
        return all
    end

end