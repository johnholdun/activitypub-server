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
    'https://w3id.org/security/v1',
    {
      'manuallyApprovesFollowers' => 'as:manuallyApprovesFollowers',
      'sensitive' => 'as:sensitive',
      'movedTo' => { '@id' => 'as:movedTo', '@type' => '@id' },
      'Hashtag' => 'as:Hashtag',
      'toot' => 'http://joinmastodon.org/ns#',
      'focalPoint' => { '@container' => '@list', '@id' => 'toot:focalPoint' },
      'featured' => { '@id' => 'toot:featured', '@type' => '@id' },
      'schema' => 'http://schema.org#',
      'PropertyValue' => 'schema:PropertyValue',
      'value' => 'schema:value'
    }
  ]
}.freeze

PUBLIC = 'https://www.w3.org/ns/activitystreams#Public'.freeze

STORAGE = Storage.new('./data.json')

Oj.default_options = { mode: :compat, time_format: :ruby, use_to_json: true }
