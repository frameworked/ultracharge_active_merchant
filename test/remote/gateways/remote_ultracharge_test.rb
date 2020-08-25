require 'test_helper'

class RemoteUltrachargeTest < Test::Unit::TestCase
  def setup
    @gateway = UltrachargeGateway.new(fixtures(:ultracharge))
    @gateway.test_url = 'https://gateway-demo.ultracharge.net/process/'

    @amount = 100

    @credit_card = credit_card('4200000000000000')
    @declined_card = credit_card('4111111111111111')

    @transaction_id = DateTime.now.strftime('%Q')
    @currency = 'EUR'
    @description = 'Store Purchase'
    @customer = 'John Doe'
    @email = 'john.doe@example.com'
    @ip = '127.0.0.1'

    @billing_address = {
      name: 'John Doe',
      address1: 'Paymentroad 321',
      city: 'Berlin',
      zip: '15432',
      state: 'B',
      country: 'DE'
    }

    @shipping_address = {
      name: 'John Doe',
      address1: 'Paymentroad 321',
      city: 'Berlin',
      zip: '15432',
      state: 'B',
      country: 'DE'
    }

    @options = {
      billing_address: @billing_address,
      shipping_address: @shipping_address,
      description: @description,
      customer: @customer,
      email: @email,
      order_id: @transaction_id,
      currency: @currency,
      ip: @ip
    }
  end

  def test_successful_purchase
    response = @gateway.purchase(@amount, @credit_card, @options)
    assert_success response
    assert_equal 'TESTMODE: No real money will be transferred!', response.message
  end

  def test_failed_purchase
    response = @gateway.purchase(@amount, @declined_card, @options)
    assert_failure response
    assert_equal 'Credit card number is invalid.', response.message
  end

  def test_successful_authorize_and_capture
    auth = @gateway.authorize(@amount, @credit_card, @options)
    assert_success auth

    @options[:order_id] = DateTime.now.strftime('%Q')

    assert capture = @gateway.capture(@amount, auth.authorization, @options)
    assert_success capture
    assert_equal 'TESTMODE: No real money will be transferred!', capture.message
  end

  def test_failed_authorize
    response = @gateway.authorize(@amount, @declined_card, @options)
    assert_failure response
    assert_equal 'Credit card number is invalid.', response.message
  end

  def test_partial_capture
    auth = @gateway.authorize(@amount, @credit_card, @options)
    assert_success auth

    @options[:order_id] = DateTime.now.strftime('%Q')

    assert capture = @gateway.capture(@amount - 1, auth.authorization, @options)
    assert_success capture
  end

  def test_failed_capture
    response = @gateway.capture(@amount, '', @options)
    assert_failure response
    assert_equal 'Transaction failed, please contact support!', response.message
  end

  def test_successful_refund
    purchase = @gateway.purchase(@amount, @credit_card, @options)
    assert_success purchase

    @options[:order_id] = DateTime.now.strftime('%Q')

    assert refund = @gateway.refund(@amount, purchase.authorization, @options)
    assert_success refund
    assert_equal 'TESTMODE: No real money will be transferred!', refund.message
  end

  def test_partial_refund
    purchase = @gateway.purchase(@amount, @credit_card, @options)
    assert_success purchase

    @options[:order_id] = DateTime.now.strftime('%Q')

    assert refund = @gateway.refund(@amount - 1, purchase.authorization, @options)
    assert_success refund
  end

  def test_failed_refund
    response = @gateway.refund(@amount, '', @options)
    assert_failure response
    assert_equal 'Transaction failed, please contact support!', response.message
  end

  def test_successful_void
    auth = @gateway.authorize(@amount, @credit_card, @options)
    assert_success auth

    @options[:order_id] = DateTime.now.strftime('%Q')

    assert void = @gateway.void(auth.authorization, @options)
    assert_success void
    assert_equal 'TESTMODE: No real money will be transferred!', void.message
  end

  def test_failed_void
    response = @gateway.void('', @options)
    assert_failure response
    assert_equal 'Transaction failed, please contact support!', response.message
  end

  def test_successful_verify
    response = @gateway.verify(@credit_card, @options)
    assert_success response
    assert_match %r{TESTMODE: No real money will be transferred!}, response.message
  end

  def test_failed_verify
    response = @gateway.verify(@declined_card, @options)
    assert_failure response
    assert_match %r{Credit card number is invalid.}, response.message
  end

  def test_invalid_login
    gateway = UltrachargeGateway.new(api_login: '', api_password: '', channel_token: '')

    assert_raises ActiveMerchant::ConnectionError do
      response = gateway.purchase(@amount, @credit_card, @options)
      assert_failure response
      assert_match %r{REPLACE WITH FAILED LOGIN MESSAGE}, response.message
    end
  end

  def test_transcript_scrubbing
    transcript = capture_transcript(@gateway) do
      @gateway.purchase(@amount, @credit_card, @options)
    end
    transcript = @gateway.scrub(transcript)

    assert_scrubbed(@credit_card.number, transcript)
    assert_scrubbed(@credit_card.verification_value, transcript)
    assert_scrubbed(@gateway.options[:api_password], transcript)
  end
end
