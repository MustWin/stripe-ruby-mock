module StripeMock
  module RequestHandlers
    class BankAccountHelper
      def self.token_prefix
        'btok'
      end

      def self.key
        :bank_account
      end

      def self.pluralized_key
        :bank_accounts
      end

      def self.default_source_key
        :default_bank_account
      end

      def self.to_s
        'bank account'
      end
    end
  end
end