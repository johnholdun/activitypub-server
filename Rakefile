require 'rake'
require 'optparse'
require './environment'

CREATE_ACCOUNT_TASK_ARGS = [
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
].freeze

namespace(:accounts) do |args|
  desc('Create a new local account')
  task('create') do
    options = {}
    OptionParser.new(args) do |opts|
      opts.banner = 'Usage: rake accounts:create [options]'

      CREATE_ACCOUNT_TASK_ARGS.each do |task_arg|
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
      result = AccountCreator.call(options)
      puts result
      exit
    rescue => e
      puts e
      abort
    end
  end
end

namespace(:inbox) do |args|
  desc('Parse unverified incoming items')
  task('parse') do
    ParseInbox.call
  end
end

namespace(:outbox) do |args|
  desc('Parse outgoing items')
  task('parse') do
    ParseOutbox.call
  end
end
