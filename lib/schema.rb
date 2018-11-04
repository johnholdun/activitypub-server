class Schema
  def self.load!
    DB.create_table?(:actors) do
      column :id, :string, unique: true
      column :type, :string
      column :private_key, :string
      column :auth_token, :string
      column :fetched_at, :datetime
      column :json, :json
    end

    DB.create_table?(:activities) do
      column :id, :string, unique: true
      column :type, :string
      column :actor, :string
      column :object, :string
      column :target, :string
      column :published, :datetime
      column :delivered, :boolean, default: false
      column :json, :json
    end

    DB.create_table?(:objects) do
      column :id, :string, unique: true
      column :type, :string
      column :published, :datetime
      column :json, :json
    end

    DB.create_table?(:inbox) do
      primary_key :id
      column :actor, :string
      column :activity, :string
    end

    DB.create_table?(:deliveries) do
      primary_key :id
      column :activity, :string
      column :recipient, :string
      column :attempts, :integer
    end

    DB.create_table?(:follows) do
      column :actor, :string
      column :object, :string
      column :accepted, :boolean
    end

    DB.create_table?(:unverified_inbox) do
      primary_key :id
      column :body, :text
      column :headers, :json
      column :path, :string
      column :request_method, :string
      column :username, :string
      column :errors, :json
    end
  end
end
