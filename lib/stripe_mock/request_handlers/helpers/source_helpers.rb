module StripeMock
  module RequestHandlers
    module Helpers
      def get_source(object, source_id, class_name='Customer')
        source_type = source_type_from_id(source_id)
        sources = object[source_type.pluralized_key] || object[:sources]
        source = sources[:data].find{|ss| ss[:id] == source_id }
        if source.nil?
          if class_name == 'Recipient'
            msg = "#{class_name} #{object[:id]} does not have a #{source_type.to_s} with ID #{source_id}"
            raise Stripe::InvalidRequestError.new(msg, source_type.key.to_s, 404)
          else
            msg = "There is no source with ID #{source_id}"
            raise Stripe::InvalidRequestError.new(msg, 'id', 404)
          end
        end
        source
      end

      def add_source_to_object(type, source, object, replace_current=false)
        source_type = source_type_from_object(object)
        source[type] = object[:id]
        sources = object[source_type.pluralized_key] || object[:sources]

        is_customer = object.has_key?(:sources)

        if replace_current && sources[:data]
          sources[:data].delete_if {|ss| ss[:id] == object[source_type.default_source_key]}
          object[source_type.default_source_key]   = source[:id] unless is_customer
          object[:default_source] = source[:id] if is_customer
          sources[:data] = [source]
        else
          sources[:total_count] = sources[:total_count] || 0 + 1
          (sources[:data] ||= []) << source
        end

        object[source_type.default_source_key]   = source[:id] if !is_customer && object[source_type.default_source_key].nil?
        object[:default_source] = source[:id] if is_customer  && object[:default_source].nil?

        source
      end

      def retrieve_object_sources(type, type_id, objects)
        resource = assert_existence type, type_id, objects[type_id]

        Data.mock_list_object(resource[:sources][:data])
      end

      def retrieve_object_bank_accounts(type, type_id, objects)
        resource = assert_existence type, type_id, objects[type_id]
        sources = resource[:bank_accounts] || resource[:sources]

        Data.mock_list_object(sources[:data])
      end

      def retrieve_object_cards(type, type_id, objects)
        resource = assert_existence type, type_id, objects[type_id]
        sources = resource[:cards] || resource[:sources]

        Data.mock_list_object(sources[:data])
      end

      def delete_source_from(type, type_id, source_id, objects)
        source_type = source_type_from_id(source_id)
        resource = assert_existence type, type_id, objects[type_id]

        assert_existence source_type.key, source_id, get_source(resource, source_id)

        source = { id: source_id, deleted: true }
        sources = resource[source_type.pluralized_key] || resource[:sources]
        sources[:data].reject!{|ss|
          ss[:id] == source[:id]
        }

        is_customer = resource.has_key?(:sources)
        new_default = sources[:data].count > 0 ? sources[:data].first[:id] : nil
        resource[source_type.default_source_key]   = new_default unless is_customer
        resource[:default_source] = new_default if is_customer
        source
      end

      def add_source_to(type, type_id, params, objects)
        if params[BankAccountHelper.key] || (!params[:source].nil? &&
              params[:source].include?(BankAccountHelper.token_prefix))
          add_bank_account_to(type, type_id, params, objects)
        end

        add_card_to(type, type_id, params, objects)
      end

      def add_bank_account_to(type, type_id, params, objects)
        resource = assert_existence type, type_id, objects[type_id]

        bank_account = bank_account_from_params(params[:bank_account] || params[:source])
        add_source_to_object(type, bank_account, resource)
      end

      def add_card_to(type, type_id, params, objects)
        resource = assert_existence type, type_id, objects[type_id]

        card = card_from_params(params[:card] || params[:source])
        add_source_to_object(type, card, resource)
      end

      private

      def source_type_from_object(object)
        CardHelper
        #object[:object] == 'card' ? CardHelper : BankAccountHelper
      end

      def source_type_from_id(id)
        CardHelper
        #!id.nil? && id.include?('btok') ? BankAccountHelper : CardHelper
      end

      def bank_account_from_params(attrs_or_token)
        if attrs_or_token.is_a? Hash
          attrs_or_token = generate_bank_token(attrs_or_token)
        end
        
        get_bank_account_by_token(attrs_or_token) 
      end

      def validate_card(card)
        [:exp_month, :exp_year].each do |field|
          card[field] = card[field].to_i
        end
        card
      end

      def card_from_params(attrs_or_token)
        if attrs_or_token.is_a? Hash
          attrs_or_token = generate_card_token(attrs_or_token)
        end
        card = get_card_by_token(attrs_or_token)
        validate_card(card)
      end
    end
  end
end
