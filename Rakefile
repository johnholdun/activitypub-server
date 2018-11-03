require 'rake'
require 'optparse'
require './environment'

TASKS =
  [
    {
      klass: AccountCreator,
      namespace: 'accounts',
      task: 'create',
      description: 'Create a new local account',
      args: [
        {
          name: :username,
          flag: 'username',
          short_flag: 'u',
          description: 'The username. All lowercase, no spaces.',
          klass: String
        },
        {
          name: :display_name,
          flag: 'display-name',
          short_flag: 'n',
          description: 'The display name. Optional.',
          klass: String
        },
        {
          name: :summary,
          flag: 'summary',
          short_flag: 's',
          description: 'The summary, or bio—a short description of the account. Optional. Some clients allow some HTML here.',
          klass: String
        },
        {
          name: :icon_url,
          flag: 'icon-url',
          short_flag: 'i',
          description: 'The URL of the icon, or avatar, of the account.',
          klass: String
        }
      ]
    },
    {
      klass: FavoriteCreator,
      namespace: 'favorites',
      task: 'create',
      description: 'Fav (or Like) a status on behalf of an account.',
      args: [
        {
          name: :account_uri,
          flag: 'account-uri',
          short_flag: 'a',
          description: 'The URI of the account performing the Favorite. Must be local.',
          klass: String
        },
        {
          name: :status_uri,
          flag: 'status-uri',
          short_flag: 's',
          description: 'The URI of the status to be favorited.',
          klass: String
        }
      ]
    },
    {
      klass: FavoriteDeleter,
      namespace: 'favorites',
      task: 'delete',
      description: 'Un-fave a status on behalf of an account.',
      args: [
        {
          name: :account_uri,
          flag: 'account-uri',
          short_flag: 'a',
          description: 'The URI of the account to remove the Favorite. Must be local.',
          klass: String
        },
        {
          name: :status_uri,
          flag: 'status-uri',
          short_flag: 's',
          description: 'The URI of the favorited status to be unfavorited.',
          klass: String
        }
      ]
    },
    {
      klass: FollowCreator,
      namespace: 'follows',
      task: 'create',
      description: 'Follow an account!',
      args: [
        {
          name: :account_id,
          flag: 'account-id',
          short_flag: 'a',
          description: 'The URI of the account performing the Follow. Must be local.',
          klass: String
        },
        {
          name: :target_account_id,
          flag: 'target-account-id',
          short_flag: 't',
          description: 'The URI of the account to be followed.',
          klass: String
        }
      ]
    },
    {
      klass: FollowDeleter,
      namespace: 'follows',
      task: 'delete',
      description: 'Unfollow an account!',
      args: [
        {
          name: :account_id,
          flag: 'account-id',
          short_flag: 'a',
          description: 'The URI of the account performing the Unfollow. Must be local.',
          klass: String
        },
        {
          name: :target_account_id,
          flag: 'target-account-id',
          short_flag: 't',
          description: 'The URI of the account to be unfollowed.',
          klass: String
        }
      ]
    },
    {
      klass: ReblogCreator,
      namespace: 'reblogs',
      task: 'create',
      description: 'Reblog (or Retweet or Boost) a status on behalf of an account.',
      args: [
        {
          name: :account_uri,
          flag: 'account-uri',
          short_flag: 'a',
          description: 'The URI of the account performing the Reblog. Must be local.',
          klass: String
        },
        {
          name: :status_uri,
          flag: 'status-uri',
          short_flag: 's',
          description: 'The URI of the status to be reblogged.',
          klass: String
        }
      ]
    },
    {
      klass: ReblogDeleter,
      namespace: 'reblogs',
      task: 'delete',
      description: 'Remove a reblog on behalf of an account.',
      args: [
        {
          name: :account_uri,
          flag: 'account-uri',
          short_flag: 'a',
          description: 'The URI of the account removing the Reblog. Must be local.',
          klass: String
        },
        {
          name: :status_uri,
          flag: 'status-uri',
          short_flag: 's',
          description: 'The URI of the status to be un-reblogged.',
          klass: String
        }
      ]
    },
    {
      klass: StatusCreator,
      namespace: 'statuses',
      task: 'create',
      description: 'Create a status AKA toot!',
      args: [
        {
          name: :account_id,
          flag: 'account-id',
          short_flag: 'a',
          description: 'The URI of the account posting the status. Must be local.',
          klass: String
        },
        {
          name: :text,
          flag: 'text',
          short_flag: 't',
          description: 'The body of the status. Some clients allow some HTML.',
          klass: String
        },
        {
          name: :in_reply_to,
          flag: 'in-reply-to',
          short_flag: 'i',
          description: 'If this is a reply, the URI of the original status.',
          klass: String
        },
        {
          name: :sensitive,
          flag: 'sensitive',
          short_flag: 's',
          description: 'A flag indicating that this post is sensitive. Defaults to false.',
          klass: FalseClass
        },
        {
          name: :summary,
          flag: 'summary',
          short_flag: 's',
          description: 'The summary AKA spoiler AKA content warning. Optional.',
          klass: String
        }
      ]
    },
    {
      klass: StatusDeleter,
      namespace: 'statuses',
      task: 'delete',
      description: 'Delete a status!',
      args: [
        {
          name: :account_id,
          flag: 'account-id',
          short_flag: 'a',
          description: 'The URI of the account that posted the status. Must be local.',
          klass: String
        },
        {
          name: :status_uri,
          flag: 'status-uri',
          short_flag: 's',
          description: 'The URI of the status to delete.',
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
              "--#{task_arg[:flag]} #{task_arg[:flag]}",
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
        # rescue => e
        #   puts e
        #   abort
        end
      end
    end
  end
end
