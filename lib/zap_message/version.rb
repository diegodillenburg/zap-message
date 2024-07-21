module ZapMessage
  class Version
    MAJOR = 0
    MINOR = 0
    PATCH = 2

    class << self
      def version
        [
          MAJOR,
          MINOR,
          PATCH
        ].join('.')
      end
    end
  end
end
