class ParseOutbox
  def self.call
    # TODO: Retry everything in `deliveries` table, delete on success

    activities =
      DB[:activities]
        .where(delivered: false)
        .where(Sequel.like(:actor, "#{BASE_URL}%"))

    puts "activities:\n#{activities.map { |a| "  #{a[:id]}"}.join("\n")}"

    activities.each do |a|
      puts "#{a[:id]}…"
      json = Oj.load(a[:json])
      next unless json['to']

      if json['object'].is_a?(String) && json['object'].start_with?(BASE_URL)
        json['object'] =
          Oj.load(DB[:objects].where(id: json['object']).first[:json])
      end


      account = DB[:actors].where(id: a[:actor]).first
      account_json = Oj.load(account[:json])

      # TODO: This is weird
      DB[:activities].where(id: a[:id]).update(delivered: true)

      inbox_urls =
        %w(to cc bcc).map { |k| json[k] }.flatten.compact

      if inbox_urls.include?(PUBLIC)
        # add followers by shared inbox or inbox
        inbox_urls +=
          DB[:follows]
            .where(object: account[:id], accepted: true)
            .map do |follow|
              account = FetchAccount.call(follow[:actor])
              (account['endpoints'] || {})['sharedInbox'] || account['inbox']
            end
      end

      puts "inbox_urls:\n#{inbox_urls.uniq.sort.map { |d| "  #{d}" }.join("\n")}"

      inbox_urls.uniq.each do |inbox_url|
        next if inbox_url == PUBLIC

        delivery = Deliverer.call(account_json, inbox_url, json)

        puts "#{inbox_url}: #{delivery[:response] > 299}"

        if delivery[:response] > 299
          DB[:deliveries].insert \
            activity: a[:id],
            recipient: inbox_url,
            attempts: 1
        end
      end
    end
  end
end
