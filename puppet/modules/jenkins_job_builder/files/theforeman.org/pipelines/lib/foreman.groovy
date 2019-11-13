def databaseFile(id, database = 'postgresql') {
    if (database == 'sqlite3') {
        text = sqliteTemplate()
    } else if (database == 'postgresql') {
        text = postgresqlTemplate(id)
    }
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

def sqliteTemplate() {
  return """
test:
  adapter: sqlite3
  database: db/test.sqlite3
  pool: 5
  timeout: 5000

development:
  adapter: sqlite3
  database: db/development.sqlite3
  pool: 5
  timeout: 5000

production:
  adapter: sqlite3
  database: db/production.sqlite3
  pool: 5
  timeout: 5000
"""
}
