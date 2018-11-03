require 'sinatra/base'

class ActivityPub < Sinatra::Application
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

  @my_routes =
    [
      [:get, '/.well-known/host-meta/?', HostMetaRoute],
      [:get, '/.well-known/webfinger/?', WebfingerRoute],

      [:get, '/users/:username/outbox/?', OutboxRoute],
      [:post, '/users/:username/outbox/?', CreateOutboxRoute],

      [:get, '/users/:username/inbox/?', ReadInboxRoute],
      [:post, '/users/:username/inbox/?', InboxRoute],

      [:get, '/users/:username/?', AccountRoute],

      [:get, '/users/:username/followers/?', FollowersRoute],
      [:get, '/users/:username/following/?', FollowingRoute],
      [:get, '/users/:username/collections/:id/?', CollectionRoute],

      # TODO: Replace with ReadObjectRoute?
      [:get, '/users/:username/statuses/:id/?', StatusRoute],

      [:get, '/users/:username/activities/:id/?', ReadActivityRoute],

      # TODO: More specific types in URL?
      [:get, '/users/:username/objects/:id/?', ReadObjectRoute],
    ]

  @my_routes.each do |meth, path, klass|
    send(meth, path) do
      formatted_request =
        request.tap do |req|
          req.params.merge!(params)
          headers =
            req
            .env
            .keys
            .select { |k| k.start_with?('HTTP_') }
            .each_with_object({}) do |key, hash|
              header_name =
                key
                  .downcase
                  .sub(/^http_./) { |foo| foo[-1].upcase }
                  .gsub(/_./) { |foo| "-#{foo[1].upcase}" }

              hash[header_name] = req.env[key]
            end

          headers['Content-Type'] = req.env['CONTENT_TYPE']

          req['headers'] = headers
        end

      klass.call(formatted_request)
    end
  end
end
