require 'bundler'

Bundler.require

Dir.glob('./lib/*.rb').each { |f| require(f) }
Dir.glob('./routes/*.rb').each { |f| require(f) }

USE_HTTPS = true

LOCAL_DOMAIN = 'johnholdun.localtunnel.me'.freeze

BASE_URL = "http#{'s' if USE_HTTPS}://#{LOCAL_DOMAIN}"

LD_CONTEXT = {
  '@context': [
    'https://www.w3.org/ns/activitystreams',
    'https://w3id.org/security/v1'
  ]
}.freeze

PUBLIC = 'https://www.w3.org/ns/activitystreams#Public'.freeze

DB = Sequel.connect('sqlite://data.db')

Schema.load!

STORAGE = Storage.new('./data.json')

Oj.default_options = { mode: :compat, time_format: :ruby, use_to_json: true }
