def databaseFile (id) {
    writeFile(file: 'config/database.yml', text: """
test:
  adapter: postgresql
  database: ${id}-test
  username: foreman
  password: foreman
  host: localhost
  template: template0

development:
  adapter: postgresql
  database: ${id}-development
  username: foreman
  password: foreman
  host: localhost
  template: template0

production:
  adapter: postgresql
  database: ${id}-development
  username: foreman
  password: foreman
  host: localhost
  template: template0
""")

}

def addGem() {
    writeFile(text: "gemspec :path => '../', :development_group => :dev", file: 'bundler.d/Gemfile.local.rb')
}

def addSettings(settings) {
    sh "cp config/settings.yaml.example config/settings.yaml"
}

def configureDatabase(ruby) {
    withRVM(['bundle install --jobs=5 --retry=5'], ruby)
    withRVM(['bundle exec rake db:drop -q || true'], ruby)
    withRVM(['bundle exec rake db:create -q'], ruby)
    withRVM(['bundle exec rake db:migrate -q'], ruby)
}

def cleanup(ruby) {
    try {

        withRVM(['bundle exec rake db:drop DISABLE_DATABASE_ENVIRONMENT_CHECK=true || true'], ruby)

    } finally {

        cleanupRVM(ruby)

    }
}
