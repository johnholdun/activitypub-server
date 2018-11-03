require './lib/service'

class StatusCreator < Service
  USERNAME_RE = /[a-z0-9_]+([a-z0-9_\.]+[a-z0-9_]+)?/i.freeze

  MENTION_RE =
    /(?<=^|[^\/[:word:]])@((#{USERNAME_RE})(?:@[a-z0-9\.\-]+[a-z0-9]+)?)/i
    .freeze

  attribute :account_id
  attribute :text
  attribute :in_reply_to
  attribute :sensitive
  attribute :summary

  def call
    raise 'could not generate id' unless id

    tags =
      mentions.map do |mention_account|
        username = mention_account['preferredUsername']
        domain = Addressable::URI.parse(mention_account['id']).normalized_host

        {
          type: 'Mention',
          href: mention_account['id'],
          name: "@#{username}@#{domain}"
        }
      end

    summary = summary.to_s.strip
    summary = nil if summary.size.zero?

    status =
      {
        id: id,
        type: 'Note',
        summary: summary,
        inReplyTo: in_reply_to,
        published: Time.now.iso8601,
        url: id,
        attributedTo: account['id'],
        to: [PUBLIC],
        cc: [account['followers']] + mentions.map { |m| m['id'] },
        sensitive: sensitive || summary,
        content: text.to_s.strip,
        attachment: [], # TODO
        tag: tags
      }

    STORAGE.write(:statuses, id, status)

    Deliverer.call \
      account,
      inbox_urls,
      id: status[:id],
      type: 'Create',
      actor: account['id'],
      published: status[:published],
      to: status[:to],
      cc: status[:cc],
      object: status
  end

  private

  def account
    @account ||= Oj.load(DB[:actors].where(id: account_id).first[:json])
  end

  def mentions
    @mentions ||=
      text.scan(MENTION_RE).map do |match|
        FetchAccount.call("acct:#{Regexp.last_match(1)}")
      end
  end

  def id
    @id ||=
      5.times do
        # TODO: Make the number of bytes in this hex configurable
        key = SecureRandom.hex(2)
        potential_id = "#{account['id']}/statuses/#{key}"
        break potential_id unless STORAGE.read(:statuses, potential_id)
      end
  end

  def inbox_urls
    return @inbox_urls if defined?(@inbox_urls)

    @inbox_urls =
      mentions.map { |m| (m['endpoints'] || {})['sharedInbox'] || m['inbox'] }

    @inbox_urls +=
      DB[:follows].where(object: account['id']).map(:actor).map do |id|
        follower = DB[:actors].where(id: id).first
        follower = Oj.load(follower[:json]) if follower
        (follower['endpoints'] || {})['sharedInbox'] || follower['inbox']
      end

    @inbox_urls.uniq!

    @inbox_urls
  end
end
