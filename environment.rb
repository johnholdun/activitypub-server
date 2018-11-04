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

CORE_TYPES =
  %w(
    Object
    Link
    Activity
    IntransitiveActivity
    Collection
    OrderedCollection
    CollectionPage
    OrderedCollectionPage
  )

ACTIVITY_TYPES =
  %w(
    Accept
    Add
    Announce
    Arrive
    Block
    Create
    Delete
    Dislike
    Flag
    Follow
    Ignore
    Invite
    Join
    Leave
    Like
    Listen
    Move
    Offer
    Question
    Reject
    Read
    Remove
    TentativeReject
    TentativeAccept
    Travel
    Undo
    Update
    View
  ).freeze

ACTOR_TYPES =
  %w(
    Application
    Group
    Organization
    Person
    Service
  ).freeze

OBJECT_TYPES =
  %w(
    Article
    Audio
    Document
    Event
    Image
    Note
    Page
    Place
    Profile
    Relationship
    Tombstone
    Video
  ).freeze

LINK_TYPES = %w(Mention).freeze

TYPES =
  (
    CORE_TYPES &
    ACTIVITY_TYPES &
    ACTOR_TYPES &
    OBJECT_TYPES &
    LINK_TYPES
  ).freeze

DB = Sequel.connect('sqlite://data.db')

Schema.load!

Oj.default_options = { mode: :compat, time_format: :ruby, use_to_json: true }
