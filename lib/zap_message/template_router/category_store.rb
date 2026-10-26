# frozen_string_literal: true

module ZapMessage
  class TemplateRouter
    # Default in-memory, per-process template -> category cache. Meta
    # recommends persistent storage; to share one across processes, pass
    # TemplateRouter any object that responds to #fetch(name, language) and
    # #store(name, language, category), e.g. a Redis or database-backed one.
    class CategoryStore
      def initialize
        @categories = {}
        @mutex = Mutex.new
      end

      def fetch(name, language)
        @mutex.synchronize { @categories[key(name, language)] }
      end

      def store(name, language, category)
        @mutex.synchronize { @categories[key(name, language)] = category }
      end

      private

      # Webhooks spell languages en-US, the Templates API en_US.
      def key(name, language)
        [name.to_s, language.to_s.tr('-', '_')]
      end
    end
  end
end
