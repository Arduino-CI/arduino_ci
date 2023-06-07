require 'io/console'

module ArduinoCI

  # Provide all text processing functions to aid readability of the test log
  class Logger

    TAB_WIDTH   = 4
    INDENT_CHAR = " ".freeze

    # @return [Integer] the cardinal number of indents
    attr_reader :tab

    # @return [Integer] The number of failures reported through the logging mechanism
    attr_reader :failure_count

    # @param width [int] The desired console width
    def initialize(width = nil)
      @tab           = 0
      @width         = width.nil? ? 80 : width
      @failure_count = 0
      @passfail      = proc { |result| result ? "✓" : "✗" }
    end

    # create a logger that's automatically sized to the console, between 80 and 132 characters
    def self.auto_width
      width = begin
        [132, [80, IO::console.winsize[1] - 2].max].min
      rescue NoMethodError
        80
      end

      self.new(width)
    end

    # print a nice banner for this project
    def banner
      art = [
        "         .                  __  ___",
        " _, ,_  _| , . * ._   _    /  `  | ",
        "(_| [ `(_] (_| | [ ) (_)   \\__. _|_   v#{ArduinoCI::VERSION}",
      ]

      pad = " " * ((@width - art[2].length) / 2)
      art.each { |l| puts "#{pad}#{l}" }
      puts
    end

    # @return [String] the current line indentation
    def indentation
      (INDENT_CHAR * TAB_WIDTH * @tab)
    end

    # put an indented string
    #
    # @param str [String] the string to puts
    # @return [void]
    def iputs(str = "")
      print(indentation)

      # split the lines and interleave with a newline character, then render
      stream_lines = str.to_s.split("\n")
      marked_stream_lines = stream_lines.flat_map { |s| [s, :nl] }.tap(&:pop)
      marked_stream_lines.each { |l| print(l == :nl ? "\n#{indentation}" : l) }
      puts
    end

    # print an indented string
    #
    # @param str [String] the string to print
    # @return [void]
    def iprint(str)
      print(indentation)
      print(str)
    end

    # increment an indentation level for the duration of a block's execution
    #
    # @param amount [Integer] the number of tabs to indent
    # @yield [] The code to execute while indented
    # @return [void]
    def indent(amount = 1, &block)
      @tab += amount
      block.call
    ensure
      @tab -= amount
    end

    # make a nice status line for an action and react to the action
    #
    # TODO / note to self: inform_multiline is tougher to write
    #   without altering the signature because it only leaves space
    #   for the checkmark _after_ the multiline, it doesn't know how
    #   to make that conditionally the body
    #
    # @param message String the text of the progress indicator
    # @param multiline boolean whether multiline output is expected
    # @param mark_fn block (string) -> string that says how to describe the result
    # @param on_fail_msg String custom message for failure
    # @param tally_on_fail boolean whether to increment @failure_count
    # @param abort_on_fail boolean whether to abort immediately on failure (i.e. if this is a fatal error)
    # @yield [] The action being performed
    # @yieldreturn [Object] whether the action was successful, can be any type but it is evaluated as a boolean
    # @return [Object] The return value of the block
    def perform_action(message, multiline, mark_fn, on_fail_msg, tally_on_fail, abort_on_fail)
      line = "#{indentation}#{message}... "
      endline = "#{indentation}...#{message} "
      if multiline
        puts line
        @tab += 1
      else
        print line
      end
      $stdout.flush

      # handle the block and any errors it raises
      caught_error = nil
      begin
        result = yield
      rescue StandardError => e
        caught_error = e
        result = false
      ensure
        @tab -= 1 if multiline
      end

      # put the trailing mark
      mark = mark_fn.nil? ? "" : mark_fn.call(result)
      # if multiline, put checkmark at full width
      print endline if multiline
      puts mark.to_s.rjust(@width - line.length, " ")
      unless result
        iputs on_fail_msg unless on_fail_msg.nil?
        raise caught_error unless caught_error.nil?

        @failure_count += 1 if tally_on_fail
        terminate if abort_on_fail
      end
      result
    end

    # Make a nice status (with checkmark) for something that defers any failure code until script exit
    #
    # @param message the message to print
    # @yield [] The action being performed
    # @yieldreturn [boolean] whether the action was successful
    # @return [Object] The return value of the block
    def attempt(message, &block)
      perform_action(message, false, @passfail, nil, true, false, &block)
    end

    # Make a nice multiline status (with checkmark) for something that defers any failure code until script exit
    #
    # @param message the message to print
    # @yield [] The action being performed
    # @yieldreturn [boolean] whether the action was successful
    # @return [Object] The return value of the block
    def attempt_multiline(message, &block)
      perform_action(message, true, @passfail, nil, true, false, &block)
    end

    FAILED_ASSURANCE_MESSAGE = "This may indicate a problem with your configuration; halting here".freeze
    # Make a nice status (with checkmark) for something that kills the script immediately on failure
    #
    # @param message the message to print
    # @yield [] The action being performed
    # @yieldreturn [boolean] whether the action was successful
    # @return [Object] The return value of the block
    def assure(message, &block)
      perform_action(message, false, @passfail, FAILED_ASSURANCE_MESSAGE, true, true, &block)
    end

    # Make a nice multiline status (with checkmark) for something that kills the script immediately on failure
    #
    # @param message the message to print
    # @yield [] The action being performed
    # @yieldreturn [boolean] whether the action was successful
    # @return [Object] The return value of the block
    def assure_multiline(message, &block)
      perform_action(message, true, @passfail, FAILED_ASSURANCE_MESSAGE, true, true, &block)
    end

    # print a failure message (with checkmark) but do not tally a failure
    # @param message the message to print
    # @return [Object] The return value of the block
    def warn(message)
      inform("WARNING") { message }
    end

    # print a failure message (with checkmark) but do not exit
    # @param message the message to print
    # @return [Object] The return value of the block
    def fail(message)
      attempt(message) { false }
    end

    # print a failure message (with checkmark) and exit immediately afterward
    # @param message the message to print
    # @return [Object] The return value of the block
    def halt(message)
      assure(message) { false }
    end

    # Print a value as a status line "message...      retval"
    #
    # @param message the message to print
    # @yield [] The action being performed
    # @yieldreturn [String] The value to print at the end of the line
    # @return [Object] The return value of the block
    def inform(message, &block)
      perform_action(message, false, proc { |x| x }, nil, false, false, &block)
    end

    # Print section beginning and end
    #
    # @param message the message to print
    # @yield [] The action being performed
    # @return [Object] The return value of the block
    def inform_multiline(message, &block)
      perform_action(message, true, nil, nil, false, false, &block)
    end

    # Print a horizontal rule across the console
    # @param char [String] the character to use
    # @return [void]
    def rule(char)
      puts char[0] * @width
    end

    # Print a section heading to the console to break up the text output
    #
    # @param name [String] the section name
    # @return [void]
    def phase(name)
      puts
      rule("=")
      puts("|  #{name}")
      puts("====")
    end

  end

end
