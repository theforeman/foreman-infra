def databaseFile(id) {
    text = postgresqlTemplate(id)
    writeFile(file: 'config/database.yml', text: text)
}

def addGem() {
    writeFile(text: "gemspec :path => '../', :development_group => :dev", file: 'bundler.d/Gemfile.local.rb')
}

def addSettings(settings) {
    sh "cp config/settings.yaml.example config/settings.yaml"
}

def configureDatabase(ruby, name = '') {
    withRVM(['bundle install --without=development --jobs=5 --retry=5'], ruby, name)
    archiveArtifacts(artifacts: 'Gemfile.lock')
    withRVM(['bundle exec rake db:drop || true'], ruby, name)
    withRVM(['bundle exec rake db:create --trace'], ruby, name)
    withRVM(['RAILS_ENV=production bundle exec rake db:create --trace'], ruby, name)
    withRVM(['bundle exec rake db:migrate --trace'], ruby, name)
}

def cleanup(ruby, name = '') {
    try {

        withRVM(['bundle exec rake db:drop DISABLE_DATABASE_ENVIRONMENT_CHECK=true || true'], ruby, name)

    } finally {

        cleanupRVM(ruby, name)

    }
}

def postgresqlTemplate(id) {
  if ("test-${id}-test".size() > 63) {
    error "${id} cannot be used to generate a PostgreSQL DB name, the resulting name would be longer than 63 chars."
  }
  return """
test:
  adapter: postgresql
  database: test-${id}-test
  username: foreman
  password: foreman
  host: localhost
  template: template0

development:
  adapter: postgresql
  database: test-${id}-dev
  username: foreman
  password: foreman
  host: localhost
  template: template0

production:
  adapter: postgresql
  database: test-${id}-prod
  username: foreman
  password: foreman
  host: localhost
  template: template0
"""
}
