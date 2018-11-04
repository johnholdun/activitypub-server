class ActivityDeliverer
  def self.call
    # TODO: Retry everything in `deliveries` table, delete on success

    activities =
      DB[:activities]
        .where(delivered: false)
        .where(Sequel.like(:actor, "#{BASE_URL}%"))

    activities.each do |a|
      json = Oj.load(a[:json])
      # TODO: Support multiple audiences
      next unless json['to']
      account = DB[:actors].where(id: a[:actor]).first
      delivery =
        Deliverer.call \
          Oj.load(account[:json]),
          [json['to']],
          json

      if delivery[0][:response] > 299
        DB[:deliveries].insert \
          activity: a[:id],
          recipient: json['to'],
          attempts: 1
      end
    end
  end
end
