module Emplace
  module App
    class Create
      include Command
      def description
        "Create source and test classes"
      end
      def run(args)
        options = option_parser(args) {|opts|
          opts.banner += " NAME..."
          opts.on('-p', '--project=PROJECT', 'Name of the project to which the class belongs', &set(:proj))
          opts.on('-f', '--force', 'Force creating the class if files already exist', &set(:force))
          opts.on('-S', '--no-source', 'Do not create source files for the class (only tests)', &set(:no_source))
          opts.on('-T', '--no-test', 'Do not create test files for the class (only sources)', &set(:no_teskkkjjjkkkt))
        }

        if args.empty?
          STDERR.puts "error: missing class name"
          App.exit_with options, 1
        end
      end
    end
  end
end
