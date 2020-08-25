require 'active_support/core_ext/hash'

module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class UltrachargeGateway < Gateway
      self.test_url = 'https://gateway-sandbox.ultracharge.net/process/'
      self.live_url = 'https://gateway.ultracharge.net/process/'

      self.supported_countries = %w[AD AE AF AG AI AL AM AO AR AS AT AU AW AZ BA BB BD BE BF BG BH BI BJ BM BN BO BR BS BT BW BY BZ CA CD CF CG CH CI CK CL CM CN CO CR CU CV CW CY CZ DE DJ DK DM DO DZ EC EE EG EH ER ES ET FI FJ FK FM FO FR GA GB GD GE GF GH GI GL GM GN GP GQ GR GT GU GW GY HK HN HR HT HU ID IE IL IN IQ IR IS IT JM JO JP KE KG KH KI KM KN KP KR KW KY KZ LA LB LC LI LK LR LS LT LU LV LY MA MC MD ME MF MG MH MK ML MM MN MO MP MQ MR MS MT MU MV MW MX MY MZ NA NC NE NF NG NI NL NO NP NR NU NZ OM PA PE PF PG PH PK PL PM PN PR PS PT PW PY QA RE RO RS RU RW SA SB SC SD SE SG SH SI SJ SK SL SM SN SO SR ST SV SY SZ TC TD TG TH TJ TK TL TM TN TO TR TT TV TW TZ UA UG US UY UZ VA VC VE VG VI VN VU WF WS XK YE ZA ZM ZW]
      self.default_currency = 'EUR'
      self.supported_cardtypes = %i[visa master discover american_express diners_club jcb maestro]
      self.money_format = :cents

      self.homepage_url = 'https://www.mikroworx.com/'
      self.display_name = 'ultracharge'

      STANDARD_ERROR_CODE_MAPPING = {
        '100' => STANDARD_ERROR_CODE[:processing_error],
        '101' => STANDARD_ERROR_CODE[:processing_error],
        '110' => STANDARD_ERROR_CODE[:processing_error],
        '120' => STANDARD_ERROR_CODE[:config_error],
        '200' => STANDARD_ERROR_CODE[:processing_error],
        '210' => STANDARD_ERROR_CODE[:processing_error],
        '220' => STANDARD_ERROR_CODE[:config_error],
        '230' => STANDARD_ERROR_CODE[:processing_error],
        '240' => STANDARD_ERROR_CODE[:processing_error],
        '250' => STANDARD_ERROR_CODE[:processing_error],
        '260' => STANDARD_ERROR_CODE[:processing_error],
        '300' => STANDARD_ERROR_CODE[:processing_error],
        '310' => STANDARD_ERROR_CODE[:processing_error],
        '320' => STANDARD_ERROR_CODE[:processing_error],
        '330' => STANDARD_ERROR_CODE[:processing_error],
        '340' => STANDARD_ERROR_CODE[:processing_error],
        '350' => STANDARD_ERROR_CODE[:processing_error],
        '360' => STANDARD_ERROR_CODE[:processing_error],
        '370' => STANDARD_ERROR_CODE[:processing_error],
        '400' => STANDARD_ERROR_CODE[:unsupported_feature],
        '410' => STANDARD_ERROR_CODE[:config_error],
        '420' => STANDARD_ERROR_CODE[:unsupported_feature],
        '430' => STANDARD_ERROR_CODE[:config_error],
        '440' => STANDARD_ERROR_CODE[:config_error],
        '450' => STANDARD_ERROR_CODE[:card_declined],
        '460' => STANDARD_ERROR_CODE[:config_error],
        '500' => STANDARD_ERROR_CODE[:processing_error],
        '510' => STANDARD_ERROR_CODE[:invalid_number],
        '520' => STANDARD_ERROR_CODE[:expired_card],
        '530' => STANDARD_ERROR_CODE[:processing_error],
        '540' => STANDARD_ERROR_CODE[:card_declined],
        '600' => STANDARD_ERROR_CODE[:card_declined],
        '610' => STANDARD_ERROR_CODE[:card_declined],
        '611' => STANDARD_ERROR_CODE[:card_declined],
        '612' => STANDARD_ERROR_CODE[:card_declined],
        '613' => STANDARD_ERROR_CODE[:card_declined],
        '614' => STANDARD_ERROR_CODE[:card_declined],
        '620' => STANDARD_ERROR_CODE[:card_declined],
        '621' => STANDARD_ERROR_CODE[:card_declined],
        '622' => STANDARD_ERROR_CODE[:card_declined],
        '623' => STANDARD_ERROR_CODE[:card_declined],
        '624' => STANDARD_ERROR_CODE[:card_declined],
        '625' => STANDARD_ERROR_CODE[:card_declined],
        '626' => STANDARD_ERROR_CODE[:card_declined],
        '627' => STANDARD_ERROR_CODE[:card_declined],
        '690' => STANDARD_ERROR_CODE[:incorrect_address],
        '900' => STANDARD_ERROR_CODE[:processing_error],
        '910' => STANDARD_ERROR_CODE[:processing_error],
        '920' => STANDARD_ERROR_CODE[:processing_error],
        '930' => STANDARD_ERROR_CODE[:processing_error],
        '940' => STANDARD_ERROR_CODE[:processing_error],
        '950' => STANDARD_ERROR_CODE[:processing_error],
        '960' => STANDARD_ERROR_CODE[:processing_error],
        '970' => STANDARD_ERROR_CODE[:processing_error]
      }

      RESPONSE_STATES = %w[
        new
        in_progress
        approved
        declined
        pending
        pending_async
        error
        voided
        chargebacked
        refunded
        chargeback_reversed
        pre_arbitrated
        rejected
        captured
      ].freeze

      RESPONSE_PENDING_STATES = %w[
        new
        in_progress
        pending
        pending_async
      ].freeze

      RESPONSE_COMPLETED_STATES = (RESPONSE_STATES - RESPONSE_PENDING_STATES).freeze

      RESPONSE_APPROVED_STATES = %w[
        approved
        voided
        chargebacked
        refunded
        chargeback_reversed
        pre_arbitrated
        captured
      ]

      RESPONSE_NOT_APPROVED_STATES = (RESPONSE_STATES - RESPONSE_APPROVED_STATES).freeze

      def initialize(options={})
        requires!(options, :api_login, :api_password, :channel_token)
        super
      end

      def purchase(money, payment, options={})
        requires!(options, :order_id, :currency, :ip)
        post = {}
        post[:transaction_type] = 'sale'
        add_invoice(post, money, options)
        add_payment(post, payment)
        add_address(post, payment, options)
        add_customer_data(post, options)

        commit('sale', post)
      end

      def authorize(money, payment, options={})
        requires!(options, :order_id, :currency, :ip)
        post = {}
        post[:transaction_type] = 'authorize'
        add_invoice(post, money, options)
        add_payment(post, payment)
        add_address(post, payment, options)
        add_customer_data(post, options)

        commit('authonly', post)
      end

      def capture(money, authorization, options={})
        requires!(options, :order_id, :currency)
        post = {}
        post[:transaction_type] = 'capture'
        post[:transaction_id] = options[:order_id]
        post[:reference_id] = authorization
        post[:usage] = options[:description]
        add_invoice(post, money, options)
        commit('capture', post)
      end

      def refund(money, authorization, options={})
        requires!(options, :order_id, :currency)
        post = {}
        post[:transaction_type] = 'refund'
        post[:transaction_id] = options[:order_id]
        post[:reference_id] = authorization
        post[:usage] = options[:description]
        add_invoice(post, money, options)
        commit('refund', post)
      end

      def void(authorization, options={})
        requires!(options, :order_id)
        post = {}
        post[:transaction_type] = 'void'
        post[:transaction_id] = options[:order_id]
        post[:reference_id] = authorization
        post[:usage] = options[:description]
        commit('void', post)
      end

      def verify(credit_card, options={})
        requires!(options, :order_id, :currency)
        MultiResponse.run(:use_first_response) do |r|
          r.process { authorize(100, credit_card, options) }
          r.process(:ignore_result) { void(r.authorization, options) }
        end
      end

      def supports_scrubbing?
        true
      end

      def scrub(transcript)
        transcript.to_s.
          gsub(/Authorization: Basic.*$/, 'Authorization: Basic xxx').
          gsub(/<card_number>([^<]+)/) { "<card_number>#{Regexp.last_match(1)[0..5].to_s + '...' + Regexp.last_match(1)[-4..-1].to_s}" }.gsub(/<cvv>([^<]+)/) { '<cvv>xxx' }.
          gsub(/<card-number>([^<]+)/) { "<card-number>#{Regexp.last_match(1)[0..5].to_s + '...' + Regexp.last_match(1)[-4..-1].to_s}" }.gsub(/<cvv>([^<]+)/) { '<cvv>xxx' }.
          gsub(/card_number=([^&]+)/) { "card_number=#{Regexp.last_match(1)[0..5] + '...' + Regexp.last_match(1)[-4..-1]}" }.gsub(/cvv=[^&]+/) { 'cvv=xxx' }.
          gsub(/"card_number":\s*"([^"]+)"/) { "\"card_number\": \"#{Regexp.last_match(1)[0..5] + '...' + Regexp.last_match(1)[-4..-1]}\"" }.gsub(/"cvv":\s*"[^"]+"/) { '"cvv": "xxx"' }.
          gsub(/"card_number":[^"]*"([^"]+)\\"/) { "\"card_number\": \"#{Regexp.last_match(1)[0..5] + '...' + Regexp.last_match(1)[-4..-1]}\"" }.gsub(/"cvv":\s*"[^"]+"/) { '"cvv": "xxx"' }.
          gsub(/\\"card_number\\":\s*\\"([^"]+)\\"/) { "\\\"card_number\\\":\\\"#{Regexp.last_match(1)[0..5] + '...' + Regexp.last_match(1)[-4..-1]}\\\"" }.
          gsub(/\\"cvv\\":\s*\\"([^"]+)\\"/) { '\\"cvv\\":\\"xxx\\"' }
      end

      private

      def add_customer_data(post, options)
        post[:transaction_id] = options[:order_id]
        post[:remote_ip] = options[:ip]
        post[:usage] = options[:description]
        post[:customer_email] = options[:email]
        post[:company_name] = company_name(options) if company_name(options).present?
      end

      def add_address(post, creditcard, options)
        options[:billing_address] = options[:billing_address] || options[:address] || {}
        options[:shipping_address] = options[:shipping_address] || {}

        if options[:billing_address].present?
          post[:billing_address] ||= {}
          post[:billing_address][:first_name] = options[:billing_address][:name].split(' ')[0..-2].join(' ')
          post[:billing_address][:last_name] = options[:billing_address][:name].split(' ')[-1]
          post[:billing_address][:address1] = options[:billing_address][:address1]
          post[:billing_address][:address2] = options[:billing_address][:address2]
          post[:billing_address][:city] = options[:billing_address][:city]
          post[:billing_address][:zip_code] = options[:billing_address][:zip]
          post[:billing_address][:state] = options[:billing_address][:state]
          post[:billing_address][:country] = options[:billing_address][:country]
        end

        if options[:shipping_address].present?
          post[:shipping_address] ||= {}
          post[:shipping_address][:first_name] = options[:shipping_address][:name].split(' ')[0..-2].join(' ')
          post[:shipping_address][:last_name] = options[:shipping_address][:name].split(' ')[-1]
          post[:shipping_address][:address1] = options[:shipping_address][:address1]
          post[:shipping_address][:address2] = options[:shipping_address][:address2]
          post[:shipping_address][:city] = options[:shipping_address][:city]
          post[:shipping_address][:zip_code] = options[:shipping_address][:zip]
          post[:shipping_address][:state] = options[:shipping_address][:state]
          post[:shipping_address][:country] = options[:shipping_address][:country]
        end
      end

      def add_invoice(post, money, options)
        post[:amount] = amount(money)
        post[:currency] = (options[:currency] || currency(money))
      end

      def add_payment(post, creditcard)
        post[:customer_name] = [creditcard.first_name, creditcard.last_name].join(' ')
        post[:card_number] = creditcard.number
        post[:cvv] = creditcard.verification_value
        post[:expiration_year] = creditcard.year
        post[:expiration_month] = format(creditcard.month, :two_digits)
      end

      def parse(response_xml)
        Hash.from_xml(response_xml)['payment_response']
      end

      def commit(action, parameters)
        url = (test? ? test_url : live_url) + @options[:channel_token]
        response = parse(ssl_post(url, post_data(action, parameters), headers))

        Response.new(
          success_from(response),
          message_from(response),
          response,
          authorization: authorization_from(response),
          test: mode_from(response),
          error_code: error_code_from(response)
        )
      end

      def success_from(response)
        RESPONSE_APPROVED_STATES.include?(response['status'])
      end

      def message_from(response)
        response['message']
      end

      def authorization_from(response)
        response['unique_id']
      end

      def mode_from(response)
        response['mode'] == 'test'
      end

      def post_data(action, parameters = {})
        case headers['Content-Type']
        when 'application/xml', 'text/xml'
          parameters.to_xml(root: :payment_transaction)
        when 'application/json', 'text/json'
          { payment_transaction: parameters }.to_json
        when 'application/x-www-form-urlencoded'
          normalize_post_parameters(parameters)
          parameters.keys.sort_by(&:to_s).compact.map { |key| "#{key}=#{CGI.escape(parameters[key].to_s)}" }.join('&')
        end
      end

      def error_code_from(response)
        STANDARD_ERROR_CODE_MAPPING[response['code']] unless success_from(response)
      end

      def company_name(options)
        @company_name ||= (options[:billing_address] || options[:address] || options[:shipping_address]).try(:[], :company)
      end

      def headers
        {
          'Content-Type' => 'text/xml', # 'application/x-www-form-urlencoded', 'application/json', 'text/xml'
          'Authorization' => 'Basic ' << Base64.strict_encode64([@options[:api_login], @options[:api_password]].join(':')).strip
        }
      end

      def normalize_post_parameters(parameters = {})
        %i[billing_address shipping_address].each do |nested_attribute|
          %i[first_name last_name address1 address2 city zip state country].each do |column|
            next unless parameters.key?(nested_attribute) && parameters[nested_attribute].key?(column)

            value = parameters[nested_attribute].delete(column)
            next if value.blank?

            parameters["#{nested_attribute}_#{column}".to_sym] = value
          end
          parameters.delete(nested_attribute)
        end
      end
    end
  end
end
