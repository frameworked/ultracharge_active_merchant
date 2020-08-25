require 'test_helper'

class UltrachargeTest < Test::Unit::TestCase
  def setup
    @gateway = UltrachargeGateway.new(api_login: '', api_password: '', channel_token: '')

    @credit_card = credit_card('4200000000000000')
    @declined_card = credit_card('4111111111111111')
    @unsupported_card = credit_card('4200000000000000', brand: :maestro)

    @amount = 100

    @options = {
      order_id: '9f4351c74a930eddbb5cf3ae612bc716',
      billing_address: {
        name: 'John Doe',
        address1: 'Paymentroad 123',
        city: 'Berlin',
        zip: '12345',
        state: 'B',
        country: 'DE'
      },
      shipping_address: {
        name: 'John Doe',
        address1: 'Paymentroad 123',
        city: 'Berlin',
        zip: '12345',
        state: 'B',
        country: 'DE'
      },
      description: 'Store Purchase',
      ip: '127.0.0.1',
      customer: 'John Doe',
      email: 'john.doe@example.com',
      currency: 'EUR'
    }
  end

  def test_successful_purchase
    @gateway.expects(:ssl_post).returns(successful_purchase_response)

    response = @gateway.purchase(@amount, @credit_card, @options)
    assert_success response
    assert response.test?

    assert_equal 'sale', response.params['transaction_type']
    assert_equal 'approved', response.params['status']
    assert_equal '1e232f2f2082a88990590cb28e61eb53', response.authorization
    assert_equal '9f4351c74a930eddbb5cf3ae612bc716', response.params['transaction_id']
    assert_equal 'test', response.params['mode']
    assert_equal '+4912341234/example.org', response.params['descriptor']
    assert_equal '100', response.params['amount']
    assert_equal 'EUR', response.params['currency']
  end

  def test_failed_purchase
    @gateway.expects(:ssl_post).returns(failed_purchase_response)

    response = @gateway.purchase(@amount, @declined_card, @options)
    assert_failure response
    assert_equal Gateway::STANDARD_ERROR_CODE[:card_declined], response.error_code
    assert_equal 'Transaction declined, please contact support!', response.message
    assert response.test?

    assert_equal 'sale', response.params['transaction_type']
    assert_equal 'declined', response.params['status']
    assert_equal '1e232f2f2082a88990590cb28e61eb54', response.authorization
    assert_equal '9f4351c74a930eddbb5cf3ae612bc716', response.params['transaction_id']
    assert_equal 'test', response.params['mode']
    assert_equal '+4912341234/example.org', response.params['descriptor']
    assert_equal '100', response.params['amount']
    assert_equal 'EUR', response.params['currency']
  end

  def test_successful_authorize
    @gateway.expects(:ssl_post).returns(successful_authorize_response)

    response = @gateway.authorize(@amount, @credit_card, @options)
    assert_success response
    assert response.test?

    assert_equal 'authorize', response.params['transaction_type']
    assert_equal 'approved', response.params['status']
    assert_equal '1e232f2f2082a88990590cb28e61eb55', response.authorization
    assert_equal '9f4351c74a930eddbb5cf3ae612bc716', response.params['transaction_id']
    assert_equal 'test', response.params['mode']
    assert_equal '+4912341234/example.org', response.params['descriptor']
    assert_equal '100', response.params['amount']
    assert_equal 'EUR', response.params['currency']
  end

  def test_failed_authorize
    @gateway.expects(:ssl_post).returns(failed_authorize_response)

    response = @gateway.authorize(@amount, @declined_card, @options)
    assert_failure response
    assert_equal Gateway::STANDARD_ERROR_CODE[:card_declined], response.error_code
    assert_equal 'Transaction declined, please contact support!', response.message
    assert response.test?

    assert_equal 'authorize', response.params['transaction_type']
    assert_equal 'declined', response.params['status']
    assert_equal '1e232f2f2082a88990590cb28e61eb56', response.authorization
    assert_equal '9f4351c74a930eddbb5cf3ae612bc716', response.params['transaction_id']
    assert_equal 'test', response.params['mode']
    assert_equal '+4912341234/example.org', response.params['descriptor']
    assert_equal '100', response.params['amount']
    assert_equal 'EUR', response.params['currency']
  end

  def test_successful_capture
    @gateway.expects(:ssl_post).returns(successful_capture_response)

    response = @gateway.capture(@amount, '1e232f2f2082a88990590cb28e61eb55', @options)
    assert_success response
    assert response.test?

    assert_equal 'capture', response.params['transaction_type']
    assert_equal 'approved', response.params['status']
    assert_equal 'b0452ddf07bc69e9f18541b57a4df0a7', response.authorization
    assert_equal '9f4351c74a930eddbb5cf3ae612bc716', response.params['transaction_id']
    assert_equal 'test', response.params['mode']
    assert_equal '+4912341234/example.org', response.params['descriptor']
    assert_equal '100', response.params['amount']
    assert_equal 'EUR', response.params['currency']
    assert_equal '1e232f2f2082a88990590cb28e61eb55', response.params['reference_id']
  end

  def test_failed_capture
    @gateway.expects(:ssl_post).returns(failed_capture_response)

    response = @gateway.capture(@amount, '1e232f2f2082a88990590cb28e61eb55', @options)
    assert_failure response
    assert_equal Gateway::STANDARD_ERROR_CODE[:config_error], response.error_code
    assert_equal 'no approved reference transaction found', response.message
    assert response.test?

    assert_equal 'capture', response.params['transaction_type']
    assert_equal 'error', response.params['status']
    assert_equal 'b0452ddf07bc69e9f18541b57a4df0a8', response.authorization
    assert_equal '9f4351c74a930eddbb5cf3ae612bc716', response.params['transaction_id']
    assert_equal 'test', response.params['mode']
    assert_equal '+4912341234/example.org', response.params['descriptor']
    assert_equal '100', response.params['amount']
    assert_equal 'EUR', response.params['currency']
    assert_equal '1e232f2f2082a88990590cb28e61eb55', response.params['reference_id']
  end

  def test_successful_refund
    @gateway.expects(:ssl_post).returns(successful_refund_response)

    response = @gateway.refund(@amount, '1e232f2f2082a88990590cb28e61eb53', @options)
    assert_success response
    assert response.test?

    assert_equal 'refund', response.params['transaction_type']
    assert_equal 'approved', response.params['status']
    assert_equal 'b0452ddf07bc69e9f18541b57a4df0a9', response.authorization
    assert_equal '9f4351c74a930eddbb5cf3ae612bc716', response.params['transaction_id']
    assert_equal '+4912341234/example.org', response.params['descriptor']
    assert_equal '100', response.params['amount']
    assert_equal 'EUR', response.params['currency']
    assert_equal '1e232f2f2082a88990590cb28e61eb53', response.params['reference_id']
  end

  def test_failed_refund
    @gateway.expects(:ssl_post).returns(failed_refund_response)

    response = @gateway.refund(@amount, '1e232f2f2082a88990590cb28e61eb53', @options)
    assert_failure response
    assert_equal Gateway::STANDARD_ERROR_CODE[:config_error], response.error_code
    assert_equal 'no approved reference transaction found', response.message
    assert response.test?

    assert_equal 'refund', response.params['transaction_type']
    assert_equal 'error', response.params['status']
    assert_equal 'b0452ddf07bc69e9f18541b57a4df0aa', response.authorization
    assert_equal '9f4351c74a930eddbb5cf3ae612bc716', response.params['transaction_id']
    assert_equal 'test', response.params['mode']
    assert_equal '+4912341234/example.org', response.params['descriptor']
    assert_equal '100', response.params['amount']
    assert_equal 'EUR', response.params['currency']
    assert_equal '1e232f2f2082a88990590cb28e61eb53', response.params['reference_id']
  end

  def test_successful_void
    @gateway.expects(:ssl_post).returns(successful_void_response)

    response = @gateway.void('1e232f2f2082a88990590cb28e61eb53', @options)
    assert_success response
    assert response.test?

    assert_equal 'void', response.params['transaction_type']
    assert_equal 'approved', response.params['status']
    assert_equal 'b0452ddf07bc69e9f18541b57a4df0ab', response.authorization
    assert_equal '9f4351c74a930eddbb5cf3ae612bc716', response.params['transaction_id']
    assert_equal 'test', response.params['mode']
    assert_equal '+4912341234/example.org', response.params['descriptor']
    assert_equal '1e232f2f2082a88990590cb28e61eb53', response.params['reference_id']
  end

  def test_failed_void
    @gateway.expects(:ssl_post).returns(failed_void_response)

    response = @gateway.void('1e232f2f2082a88990590cb28e61eb53', @options)
    assert_failure response
    assert_equal Gateway::STANDARD_ERROR_CODE[:config_error], response.error_code
    assert_equal 'no approved reference transaction found', response.message
    assert response.test?

    assert_equal 'void', response.params['transaction_type']
    assert_equal 'error', response.params['status']
    assert_equal 'b0452ddf07bc69e9f18541b57a4df0ac', response.authorization
    assert_equal '9f4351c74a930eddbb5cf3ae612bc716', response.params['transaction_id']
    assert_equal 'test', response.params['mode']
    assert_equal '+4912341234/example.org', response.params['descriptor']
    assert_equal '1e232f2f2082a88990590cb28e61eb53', response.params['reference_id']
  end

  def test_successful_verify
    @gateway.expects(:ssl_post).returns(successful_authorize_response, successful_void_response).twice

    response = @gateway.verify(@credit_card, @options)

    assert_success response
    assert response.test?

    assert_success response.responses[0]
    assert response.responses[0].test?

    assert_success response.responses[1]
    assert response.responses[1].test?

    assert_equal 'authorize', response.responses[0].params['transaction_type']
    assert_equal 'approved', response.responses[0].params['status']
    assert_equal '1e232f2f2082a88990590cb28e61eb55', response.responses[0].authorization
    assert_equal '9f4351c74a930eddbb5cf3ae612bc716', response.responses[0].params['transaction_id']
    assert_equal 'test', response.responses[0].params['mode']
    assert_equal '+4912341234/example.org', response.responses[0].params['descriptor']
    assert_equal '100', response.responses[0].params['amount']
    assert_equal 'EUR', response.responses[0].params['currency']

    assert_equal 'void', response.responses[1].params['transaction_type']
    assert_equal 'approved', response.responses[1].params['status']
    assert_equal 'b0452ddf07bc69e9f18541b57a4df0ab', response.responses[1].authorization
    assert_equal '9f4351c74a930eddbb5cf3ae612bc716', response.responses[1].params['transaction_id']
    assert_equal 'test', response.responses[0].params['mode']
    assert_equal '+4912341234/example.org', response.responses[1].params['descriptor']
    assert_equal '1e232f2f2082a88990590cb28e61eb53', response.responses[1].params['reference_id']
  end

  def test_successful_verify_with_failed_void
    @gateway.expects(:ssl_post).returns(successful_authorize_response, failed_void_response).twice

    response = @gateway.verify(@credit_card, @options)

    assert_success response
    assert response.test?

    assert_success response.responses[0]
    assert response.responses[0].test?

    assert_failure response.responses[1]
    assert_equal Gateway::STANDARD_ERROR_CODE[:config_error], response.responses[1].error_code
    assert_equal 'no approved reference transaction found', response.responses[1].message
    assert response.responses[1].test?

    assert_equal 'authorize', response.responses[0].params['transaction_type']
    assert_equal 'approved', response.responses[0].params['status']
    assert_equal '1e232f2f2082a88990590cb28e61eb55', response.responses[0].authorization
    assert_equal '9f4351c74a930eddbb5cf3ae612bc716', response.responses[0].params['transaction_id']
    assert_equal 'test', response.responses[0].params['mode']
    assert_equal '+4912341234/example.org', response.responses[0].params['descriptor']
    assert_equal '100', response.responses[0].params['amount']
    assert_equal 'EUR', response.responses[0].params['currency']

    assert_equal 'void', response.responses[1].params['transaction_type']
    assert_equal 'error', response.responses[1].params['status']
    assert_equal 'b0452ddf07bc69e9f18541b57a4df0ac', response.responses[1].authorization
    assert_equal '9f4351c74a930eddbb5cf3ae612bc716', response.responses[1].params['transaction_id']
    assert_equal 'test', response.responses[0].params['mode']
    assert_equal '+4912341234/example.org', response.responses[1].params['descriptor']
    assert_equal '1e232f2f2082a88990590cb28e61eb53', response.responses[1].params['reference_id']
  end

  def test_failed_verify
    @gateway.expects(:ssl_post).returns(failed_authorize_response)

    response = @gateway.verify(@credit_card, @options)

    assert_failure response
    assert response.test?
    assert_equal Gateway::STANDARD_ERROR_CODE[:card_declined], response.error_code
    assert_equal 'Transaction declined, please contact support!', response.message
    assert response.test?

    assert_equal 'authorize', response.responses[0].params['transaction_type']
    assert_equal 'declined', response.responses[0].params['status']
    assert_equal '1e232f2f2082a88990590cb28e61eb56', response.responses[0].authorization
    assert_equal '9f4351c74a930eddbb5cf3ae612bc716', response.responses[0].params['transaction_id']
    assert_equal 'test', response.responses[0].params['mode']
    assert_equal '+4912341234/example.org', response.responses[0].params['descriptor']
    assert_equal '100', response.responses[0].params['amount']
    assert_equal 'EUR', response.responses[0].params['currency']
  end

  def test_scrub
    assert @gateway.supports_scrubbing?
    assert_equal @gateway.scrub(pre_scrubbed), post_scrubbed
  end

  private

  def pre_scrubbed
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <payment_transaction>
          <transaction_type>sale</transaction_type>
          <transaction_id>9f4351c74a930eddbb5cf3ae612bc716</transaction_id>
          <usage>Shop order 40208</usage>
          <remote_ip>123.12.21.213</remote_ip>
          <amount>1000</amount>
          <currency>USD</currency>
          <customer_name>John Doe</customer_name>
          <card_number>4200000000000000</card_number>
          <cvv>123</cvv>
          <expiration_month>12</expiration_month>
          <expiration_year>2019</expiration_year>
          <customer_email>john.doe@example.com</customer_email>
          <customer_phone>+49301234567</customer_phone>
          <billing_address>
              <first_name>John</first_name>
              <last_name>Doe</last_name>
              <address1>Paymentroad 123</address1>
              <zip_code>12345</zip_code>
              <city>Berlin</city>
              <state>B</state>
              <country>DE</country>
          </billing_address>
          <shipping_address>
              <first_name>John</first_name>
              <last_name>Doe</last_name>
              <address1>Paymentroad 123</address1>
              <zip_code>12345</zip_code>
              <city>Berlin</city>
              <state>B</state>
              <country>DE</country>
          </shipping_address>
      </payment_transaction>
    XML
  end

  def post_scrubbed
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <payment_transaction>
          <transaction_type>sale</transaction_type>
          <transaction_id>9f4351c74a930eddbb5cf3ae612bc716</transaction_id>
          <usage>Shop order 40208</usage>
          <remote_ip>123.12.21.213</remote_ip>
          <amount>1000</amount>
          <currency>USD</currency>
          <customer_name>John Doe</customer_name>
          <card_number>420000...0000</card_number>
          <cvv>xxx</cvv>
          <expiration_month>12</expiration_month>
          <expiration_year>2019</expiration_year>
          <customer_email>john.doe@example.com</customer_email>
          <customer_phone>+49301234567</customer_phone>
          <billing_address>
              <first_name>John</first_name>
              <last_name>Doe</last_name>
              <address1>Paymentroad 123</address1>
              <zip_code>12345</zip_code>
              <city>Berlin</city>
              <state>B</state>
              <country>DE</country>
          </billing_address>
          <shipping_address>
              <first_name>John</first_name>
              <last_name>Doe</last_name>
              <address1>Paymentroad 123</address1>
              <zip_code>12345</zip_code>
              <city>Berlin</city>
              <state>B</state>
              <country>DE</country>
          </shipping_address>
      </payment_transaction>
    XML
  end

  def successful_purchase_response
    %(
      Easy to capture by setting the DEBUG_ACTIVE_MERCHANT environment variable
      to "true" when running remote tests:

      $ DEBUG_ACTIVE_MERCHANT=true ruby -Itest \
        test/remote/gateways/remote_ultracharge_test.rb \
        -n test_successful_purchase
    )
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <payment_response>
          <transaction_type>sale</transaction_type>
          <status>approved</status>
          <unique_id>1e232f2f2082a88990590cb28e61eb53</unique_id>
          <transaction_id>9f4351c74a930eddbb5cf3ae612bc716</transaction_id>
          <mode>test</mode>
          <timestamp>2019-01-23T17:46:11Z</timestamp>
          <descriptor>+4912341234/example.org</descriptor>
          <amount>100</amount>
          <currency>EUR</currency>
      </payment_response>
    XML
  end

  def failed_purchase_response
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <payment_response>
          <transaction_type>sale</transaction_type>
          <status>declined</status>
          <unique_id>1e232f2f2082a88990590cb28e61eb54</unique_id>
          <transaction_id>9f4351c74a930eddbb5cf3ae612bc716</transaction_id>
          <code>600</code>
          <technical_message>Transaction declined by risk management!</technical_message>
          <message>Transaction declined, please contact support!</message>
          <mode>test</mode>
          <timestamp>2019-01-23T17:46:11Z</timestamp>
          <descriptor>+4912341234/example.org</descriptor>
          <amount>100</amount>
          <currency>EUR</currency>
      </payment_response>
    XML
  end

  def successful_authorize_response
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <payment_response>
          <transaction_type>authorize</transaction_type>
          <status>approved</status>
          <unique_id>1e232f2f2082a88990590cb28e61eb55</unique_id>
          <transaction_id>9f4351c74a930eddbb5cf3ae612bc716</transaction_id>
          <mode>test</mode>
          <timestamp>2019-01-23T17:46:11Z</timestamp>
          <descriptor>+4912341234/example.org</descriptor>
          <amount>100</amount>
          <currency>EUR</currency>
      </payment_response>
    XML
  end

  def failed_authorize_response
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <payment_response>
          <transaction_type>authorize</transaction_type>
          <status>declined</status>
          <unique_id>1e232f2f2082a88990590cb28e61eb56</unique_id>
          <transaction_id>9f4351c74a930eddbb5cf3ae612bc716</transaction_id>
          <code>600</code>
          <technical_message>Transaction declined by risk management!</technical_message>
          <message>Transaction declined, please contact support!</message>
          <mode>test</mode>
          <timestamp>2019-01-23T17:46:11Z</timestamp>
          <descriptor>+4912341234/example.org</descriptor>
          <amount>100</amount>
          <currency>EUR</currency>
      </payment_response>
    XML
  end

  def successful_capture_response
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <payment_response>
          <transaction_type>capture</transaction_type>
          <status>approved</status>
          <unique_id>b0452ddf07bc69e9f18541b57a4df0a7</unique_id>
          <transaction_id>9f4351c74a930eddbb5cf3ae612bc716</transaction_id>
          <mode>test</mode>
          <timestamp>2019-01-23T17:46:11Z</timestamp>
          <descriptor>+4912341234/example.org</descriptor>
          <amount>100</amount>
          <currency>EUR</currency>
          <reference_id>1e232f2f2082a88990590cb28e61eb55</reference_id>
      </payment_response>
    XML
  end

  def failed_capture_response
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <payment_response>
          <transaction_type>capture</transaction_type>
          <status>error</status>
          <unique_id>b0452ddf07bc69e9f18541b57a4df0a8</unique_id>
          <transaction_id>9f4351c74a930eddbb5cf3ae612bc716</transaction_id>
          <code>410</code>
          <technical_message>no approved reference transaction found</technical_message>
          <message>no approved reference transaction found</message>
          <mode>test</mode>
          <timestamp>2019-01-23T17:46:11Z</timestamp>
          <descriptor>+4912341234/example.org</descriptor>
          <amount>100</amount>
          <currency>EUR</currency>
          <reference_id>1e232f2f2082a88990590cb28e61eb55</reference_id>
      </payment_response>
    XML
  end

  def successful_refund_response
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <payment_response>
          <transaction_type>refund</transaction_type>
          <status>approved</status>
          <unique_id>b0452ddf07bc69e9f18541b57a4df0a9</unique_id>
          <transaction_id>9f4351c74a930eddbb5cf3ae612bc716</transaction_id>
          <mode>test</mode>
          <timestamp>2019-01-23T17:46:11Z</timestamp>
          <descriptor>+4912341234/example.org</descriptor>
          <amount>100</amount>
          <currency>EUR</currency>
          <reference_id>1e232f2f2082a88990590cb28e61eb53</reference_id>
      </payment_response>
    XML
  end

  def failed_refund_response
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <payment_response>
          <transaction_type>refund</transaction_type>
          <status>error</status>
          <unique_id>b0452ddf07bc69e9f18541b57a4df0aa</unique_id>
          <transaction_id>9f4351c74a930eddbb5cf3ae612bc716</transaction_id>
          <code>410</code>
          <technical_message>no approved reference transaction found</technical_message>
          <message>no approved reference transaction found</message>
          <mode>test</mode>
          <timestamp>2019-01-23T17:46:11Z</timestamp>
          <descriptor>+4912341234/example.org</descriptor>
          <amount>100</amount>
          <currency>EUR</currency>
          <reference_id>1e232f2f2082a88990590cb28e61eb53</reference_id>
      </payment_response>
    XML
  end

  def successful_void_response
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <payment_response>
          <transaction_type>void</transaction_type>
          <status>approved</status>
          <unique_id>b0452ddf07bc69e9f18541b57a4df0ab</unique_id>
          <transaction_id>9f4351c74a930eddbb5cf3ae612bc716</transaction_id>
          <mode>test</mode>
          <timestamp>2019-01-23T17:46:11Z</timestamp>
          <descriptor>+4912341234/example.org</descriptor>
          <reference_id>1e232f2f2082a88990590cb28e61eb53</reference_id>
      </payment_response>
    XML
  end

  def failed_void_response
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <payment_response>
          <transaction_type>void</transaction_type>
          <status>error</status>
          <unique_id>b0452ddf07bc69e9f18541b57a4df0ac</unique_id>
          <transaction_id>9f4351c74a930eddbb5cf3ae612bc716</transaction_id>
          <code>410</code>
          <technical_message>no approved reference transaction found</technical_message>
          <message>no approved reference transaction found</message>
          <mode>test</mode>
          <timestamp>2019-01-23T17:46:11Z</timestamp>
          <descriptor>+4912341234/example.org</descriptor>
          <reference_id>1e232f2f2082a88990590cb28e61eb53</reference_id>
      </payment_response>
    XML
  end
end
