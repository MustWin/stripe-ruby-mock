module StripeMock
  module RequestHandlers
    class CardHelper
      def self.token_prefix
        'tok'
      end

      def self.key
        :card
      end

      def self.pluralized_key
        :cards
      end

      def self.default_source_key
        :default_card
      end

      def self.to_s
        'card'
      end
    end
  end
end