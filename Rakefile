require 'rake'
require 'optparse'
require './environment'

TASKS =
  [
    {
      klass: AccountCreator,
      namespace: 'accounts',
      task: 'create',
      description: 'TODO',
      args: [
        {
          name: :username,
          flag: 'username',
          short_flag: 'u',
          description: 'TODO',
          klass: String
        },
        {
          name: :display_name,
          flag: 'display-name',
          short_flag: 'n',
          description: 'TODO',
          klass: String
        },
        {
          name: :summary,
          flag: 'summary',
          short_flag: 's',
          description: 'TODO',
          klass: String
        },
        {
          name: :icon_url,
          flag: 'icon-url',
          short_flag: 'i',
          description: 'TODO',
          klass: String
        }
      ]
    },
    {
      klass: FavoriteCreator,
      namespace: 'favorites',
      task: 'create',
      description: 'TODO',
      args: [
        {
          name: :account_uri,
          flag: 'account-uri',
          short_flag: 'a',
          description: 'TODO',
          klass: String
        },
        {
          name: :status_uri,
          flag: 'status-uri',
          short_flag: 's',
          description: 'TODO',
          klass: String
        }
      ]
    },
    {
      klass: FavoriteDeleter,
      namespace: 'favorites',
      task: 'delete',
      description: 'TODO',
      args: [
        {
          name: :account_uri,
          flag: 'account-uri',
          short_flag: 'a',
          description: 'TODO',
          klass: String
        },
        {
          name: :status_uri,
          flag: 'status-uri',
          short_flag: 's',
          description: 'TODO',
          klass: String
        }
      ]
    },
    {
      klass: FollowCreator,
      namespace: 'follows',
      task: 'create',
      description: 'TODO',
      args: [
        {
          name: :account_id,
          flag: 'account-id',
          short_flag: 'a',
          description: 'TODO',
          klass: String
        },
        {
          name: :target_account_id,
          flag: 'target-account-id',
          short_flag: 't',
          description: 'TODO',
          klass: String
        }
      ]
    },
    {
      klass: FollowDeleter,
      namespace: 'follows',
      task: 'delete',
      description: 'TODO',
      args: [
        {
          name: :account_id,
          flag: 'account-id',
          short_flag: 'a',
          description: 'TODO',
          klass: String
        },
        {
          name: :target_account_id,
          flag: 'target-account-id',
          short_flag: 't',
          description: 'TODO',
          klass: String
        }
      ]
    },
    {
      klass: ReblogCreator,
      namespace: 'reblogs',
      task: 'create',
      description: 'TODO',
      args: [
        {
          name: :account_uri,
          flag: 'account-uri',
          short_flag: 'a',
          description: 'TODO',
          klass: String
        },
        {
          name: :status_uri,
          flag: 'status-uri',
          short_flag: 's',
          description: 'TODO',
          klass: String
        }
      ]
    },
    {
      klass: ReblogDeleter,
      namespace: 'reblogs',
      task: 'delete',
      description: 'TODO',
      args: [
        {
          name: :account_uri,
          flag: 'account-uri',
          short_flag: 'a',
          description: 'TODO',
          klass: String
        },
        {
          name: :status_uri,
          flag: 'status-uri',
          short_flag: 's',
          description: 'TODO',
          klass: String
        }
      ]
    },
    {
      klass: StatusCreator,
      namespace: 'statuses',
      task: 'create',
      description: 'TODO',
      args: [
        {
          name: :account_id,
          flag: 'account-id',
          short_flag: 'a',
          description: 'TODO',
          klass: String
        },
        {
          name: :text,
          flag: 'text',
          short_flag: 't',
          description: 'TODO',
          klass: String
        },
        {
          name: :in_reply_to,
          flag: 'in-reply-to',
          short_flag: 'i',
          description: 'TODO',
          klass: String
        },
        {
          name: :sensitive,
          flag: 'sensitive',
          short_flag: 's',
          description: 'TODO',
          klass: FalseClass
        },
        {
          name: :summary,
          flag: 'summary',
          short_flag: 's',
          description: 'TODO',
          klass: String
        }
      ]
    },
    {
      klass: StatusDeleter,
      namespace: 'statuses',
      task: 'delete',
      description: 'TODO',
      args: [
        {
          name: :account_uri,
          flag: 'account-uri',
          short_flag: 'a',
          description: 'TODO',
          klass: String
        },
        {
          name: :status_uri,
          flag: 'status-uri',
          short_flag: 's',
          description: 'TODO',
          klass: String
        }
      ]
    }
  ]

TASKS.map { |t| t[:namespace] }.uniq.each do |tasks_namespace|
  namespace(tasks_namespace) do |args|
    TASKS.select { |t| t[:namespace] == tasks_namespace }.each do |task_opts|
      desc(task_opts[:description])
      task(task_opts[:task]) do
        options = {}
        OptionParser.new(args) do |opts|
          opts.banner = "Usage: rake #{tasks_namespace}:#{task_opts[:task]} [options]"

          task_opts[:args].each do |task_arg|
            opts.on(
              "-#{task_arg[:short_flag]}",
              "--#{task_arg[:flag]} {task_arg[:flag]}",
              task_arg[:description],
              task_arg[:klass]
            ) do |value|
              options[task_arg[:name]] = value
            end
          end
        end.parse!(ARGV[2..-1])

        begin
          result = task_opts[:klass].call(options)
          puts result
          exit
        rescue => e
          puts e
          abort
        end
      end
    end
  end
end
