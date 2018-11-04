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
