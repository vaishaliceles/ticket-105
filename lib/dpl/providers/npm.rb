module Dpl
  module Providers
    class Npm < Provider
      status :beta

      full_name 'npm'

      description sq(<<-str)
        tbd
      str

      gem 'json'

      env :npm

      opt '--email EMAIL', 'npm account email'
      opt '--api_token TOKEN', 'npm api token', alias: :api_key, required: true, secret: true, note: 'can be retrieved from your local ~/.npmrc file', see: 'https://docs.npmjs.com/creating-and-viewing-authentication-tokens'
      opt '--access ACCESS', 'Access level', enum: %w(public private)
      opt '--registry URL', 'npm registry url'
      opt '--src SRC', 'directory or tarball to publish', default: '.'
      opt '--tag TAGS', 'distribution tags to add'
      opt '--auth_method METHOD', 'Authentication method', enum: %w(auth)

      REGISTRY = 'https://registry.npmjs.org'
      NPMRC = '~/.npmrc'

      msgs version:  'npm version: %{npm_version}',
           login:    'Authenticated with API token %{api_token}'

      cmds registry: 'npm config set registry "%{registry}"',
           deploy:   'npm publish %{src} %{publish_opts}'

      errs registry: 'Failed to set registry config',
           deploy:    'Failed pushing to npm'

      def login
        info :version
        info :login
        write_npmrc
        shell :registry
      end

      def deploy
        shell :deploy
      end

      def finish
        remove_npmrc
      end

      private

        def publish_opts
          opts_for(%i(access tag))
        end

        def write_npmrc
          write_file(npmrc_path, npmrc)
          info "#{NPMRC} size: #{file_size(npmrc_path)}"
        end

        def remove_npmrc
          rm_f npmrc_path
        end

        def npmrc_path
          expand(NPMRC)
        end

        def npmrc
          if npm_version =~ /^1/ || auth_method == 'auth'
            "_auth = #{api_token}\nemail = #{email}"
          else
            "//#{auth_endpoint}/:_authToken=#{api_token}"
          end
        end

        def auth_endpoint
          str = registry
          str = strip_path(str) if str.include?('npm.pkg.github.com')
          str = strip_protocol(str).sub(%r(/$), '')
          str
        end

        def registry
          super || registry_from_package_json || REGISTRY
        end

        def registry_from_package_json
          return unless data = package_json
          data && data.fetch('publishConfig', {})['registry']
        end

        def strip_path(url)
          url.sub(URI(url).path, '')
        end

        def strip_protocol(url)
          url.sub("#{URI(url).scheme}://", '')
        end

        def host(url)
          URI(url).host
        end

        def package_json
          File.exists?('package.json') ? JSON.parse(File.read('package.json')) : {}
        end
    end
  end
end
