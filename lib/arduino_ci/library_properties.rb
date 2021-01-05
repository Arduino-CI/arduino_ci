module ArduinoCI

  # Information about an Arduino library package, as specified by the library.properties file
  #
  # See https://arduino.github.io/arduino-cli/library-specification/#libraryproperties-file-format
  class LibraryProperties

    # @return [Hash] The properties file parsed as a hash
    attr_reader :fields

    # @param path [Pathname] The path to the library.properties file
    def initialize(path)
      @fields = {}
      File.foreach(path) do |line_with_delim|
        line = line_with_delim.chomp
        parts = line.split("=", 2)
        next if parts[0].nil?
        next if parts[0].empty?
        next if parts[1].nil?

        @fields[parts[0]] = parts[1] unless parts[1].empty?
      end
    end

    # @return [Hash] the properties as a hash, all strings
    def to_h
      Hash[@fields.map { |k, _| [k.to_sym, send(k)] }]
    end

    # @return [String] the string representation
    def to_s
      to_h.to_s
    end

    # Enable a shortcut syntax for library property accessors, in the style of `attr_accessor` metaprogramming.
    # This is used to create a named field pointing to a specific property in the file, optionally applying
    # a specific formatting function.
    #
    #  The formatting function MUST be a static method on this class.  This is a limitation caused by the desire
    #  to both (1) expose the formatters outside this class, and (2) use them for metaprogramming without the
    #  having to name the entire function.  field_reader is a static method, so if not for the fact that
    #  `self.class.methods.include? formatter` fails to work for class methods in this context (unlike
    #  `self.methods.include?`, which properly finds instance methods), I would allow either one and just
    #  conditionally `define_method` the proper definition
    #
    # @param name [String] What the accessor will be called
    # @param field_num [Integer] The name of the key of the property
    # @param formatter [Symbol] The symbol for the formatting function to apply to the field (optional)
    # @return [void]
    # @macro [attach] field_reader
    #   @!attribute [r] $1
    #   @return property $2 of the library.properties file, formatted with the function {$3}
    def self.field_reader(name, formatter = nil)
      key = name.to_s
      if formatter.nil?
        define_method(name) { @fields[key] }
      else
        define_method(name) { @fields.key?(key) ? self.class.send(formatter.to_sym, @fields[key]) : nil }
      end
    end

    # Parse a value as a comma-separated array
    # @param input [String]
    # @return [Array<String>] The individual values
    def self._csv(input)
      input.split(",").map(&:strip)
    end

    # Parse a value as a boolean
    # @param input [String]
    # @return [Array<String>] The individual values
    def self._bool(input)
      input == "true"  # no indication given in the docs that anything but lowercase "true" indicates boolean true.
    end

    field_reader :name
    field_reader :version
    field_reader :author, :_csv
    field_reader :maintainer
    field_reader :sentence
    field_reader :paragraph
    field_reader :category
    field_reader :url
    field_reader :architectures, :_csv
    field_reader :depends, :_csv
    field_reader :dot_a_linkage, :_bool
    field_reader :includes, :_csv
    field_reader :precompiled, :_bool
    field_reader :ldflags, :_csv

    # The value of sentence always will be prepended, so you should start by writing the second sentence here
    #
    # (according to the docs)
    # @return [String] the sentence and paragraph together
    def full_paragraph
      [sentence, paragraph].join(" ")
    end

  end

end
