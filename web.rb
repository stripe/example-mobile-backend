require 'sinatra'
require 'stripe'
require 'dotenv'
require 'json'
require 'encrypted_cookie'

$stdout.sync = true # Get puts to show up in heroku logs

Dotenv.load
Stripe.api_key = ENV['STRIPE_TEST_SECRET_KEY']

use Rack::Session::EncryptedCookie,
  :secret => 'replace_me_with_a_real_secret_key' # Actually use something secret here!

def log_info(message)
  puts "\n" + message + "\n\n"
  return message
end

get '/' do
  status 200
  return log_info("Great, your backend is set up. Now you can configure the Stripe example apps to point here.")
end

post '/ephemeral_keys' do
  authenticate!
  begin
    key = Stripe::EphemeralKey.create(
      {customer: @customer.id},
      {stripe_version: params["api_version"]}
    )
  rescue Stripe::StripeError => e
    status 402
    return log_info("Error creating ephemeral key: #{e.message}")
  end

  content_type :json
  status 200
  key.to_json
end

def authenticate!
  # This code simulates "loading the Stripe customer for your current session".
  # Your own logic will likely look very different.
  return @customer if @customer
  if session.has_key?(:customer_id)
    customer_id = session[:customer_id]
    begin
      @customer = Stripe::Customer.retrieve(customer_id)
    rescue Stripe::InvalidRequestError
    end
  else
    default_cusomer_id = ENV['DEFAULT_CUSTOMER_ID']
    if default_cusomer_id
      @customer = Stripe::Customer.retrieve(default_cusomer_id)
    else
      begin
        @customer = create_customer()

        # Attach some test cards to the customer for testing convenience.
        # See https://stripe.com/docs/payments/3d-secure#three-ds-cards 
        # and https://stripe.com/docs/mobile/android/authentication#testing
        ['4000000000003220', '4000000000003238', '4000000000003246', '4000000000003253', '4242424242424242'].each { |cc_number|
          payment_method = Stripe::PaymentMethod.create({
            type: 'card',
            card: {
              number: cc_number,
              exp_month: 8,
              exp_year: 2022,
              cvc: '123',
            },
          })

          Stripe::PaymentMethod.attach(
            payment_method.id,
            {
              customer: @customer.id,
            }
          )
        }
      rescue Stripe::InvalidRequestError
      end
    end
    session[:customer_id] = @customer.id
  end
  @customer
end

def create_customer
  Stripe::Customer.create(
    :description => 'mobile SDK example customer',
    :metadata => {
      # Add our application's customer id for this Customer, so it'll be easier to look up
      :my_customer_id => '72F8C533-FCD5-47A6-A45B-3956CA8C792D',
    },
  )
end

# This endpoint responds to webhooks sent by Stripe. To use it, you'll need
# to add its URL (https://{your-app-name}.herokuapp.com/stripe-webhook)
# in the webhook settings section of the Dashboard.
# https://dashboard.stripe.com/account/webhooks
# See https://stripe.com/docs/webhooks
post '/stripe-webhook' do
  # Retrieving the event from Stripe guarantees its authenticity
  payload = request.body.read
  event = nil

  begin
      event = Stripe::Event.construct_from(
          JSON.parse(payload, symbolize_names: true)
      )
  rescue JSON::ParserError => e
      # Invalid payload
      status 400
      return
  end

  # Handle the event
  case event.type
  when 'source.chargeable'
    # For sources that require additional user action from your customer
    # (e.g. authorizing the payment with their bank), you should use webhooks
    # to capture a PaymentIntent after the source becomes chargeable.
    # For more information, see https://stripe.com/docs/sources#best-practices
    source = event.data.object # contains a Stripe::Source
    WEBHOOK_CHARGE_CREATION_TYPES = ['bancontact', 'giropay', 'ideal', 'sofort', 'three_d_secure', 'wechat']
    if WEBHOOK_CHARGE_CREATION_TYPES.include?(source.type)
      begin
        payment_intent = create_payment_intent(
          amount: source.amount,
          source_id: source.id,
          customer_id: source.metadata["customer"],
          metadata: source.metadata,
          currency: source.currency,
          payment_method_types: [source.type],
          confirm: true,
        )
      rescue Stripe::StripeError => e
        status 400
        return log_info("Error creating PaymentIntent: #{e.message}")
      end 
      return log_info("Created PaymentIntent for source: #{payment_intent.id}")
    end
  when 'payment_intent.succeeded'
    payment_intent = event.data.object # contains a Stripe::PaymentIntent
    log_info("PaymentIntent succeeded #{payment_intent.id}")
    # Fulfill the customer's purchase, send an email, etc.
    # When creating the PaymentIntent, consider storing any order
    # information (e.g. order number) as metadata so that you can retrieve it
    # here and use it to complete your customer's purchase.
  when 'payment_intent.amount_capturable_updated'
    # Capture the payment, then fulfill the customer's purchase like above.
    payment_intent = event.data.object # contains a Stripe::PaymentIntent
    log_info("PaymentIntent succeeded #{payment_intent.id}")
  else
    # Unexpected event type
    status 400
    return
  end
  status 200
end

def create_payment_intent(amount:, source_id: nil, payment_method_id: nil, customer_id: nil,
                          metadata: {}, currency: nil, shipping: nil, return_url: nil, payment_method_types: nil, confirm: false)
  payment_intent_id = ENV['DEFAULT_PAYMENT_INTENT_ID']
  if payment_intent_id
    return Stripe::PaymentIntent.retrieve(payment_intent_id)
  end

  return Stripe::PaymentIntent.create(
    :amount => amount,
    :currency => currency || 'usd',
    :customer => customer_id,
    :source => source_id,
    :payment_method => payment_method_id,
    :payment_method_types => payment_method_types,
    :description => "Example PaymentIntent",
    :shipping => shipping,
    :return_url => return_url,
    :confirm => confirm,
    :confirmation_method => confirm ? "manual" : "automatic",
    :use_stripe_sdk => confirm ? true : nil,
    :capture_method => ENV['CAPTURE_METHOD'] == "manual" ? "manual" : "automatic",
    :metadata => {
      :order_id => '5278735C-1F40-407D-933A-286E463E72D8',
    }.merge(metadata || {}),
  )
end

# ==== SetupIntent 
# See https://stripe.com/docs/payments/cards/saving-cards-without-payment

# This endpoint is used by the mobile example apps to create a SetupIntent.
# https://stripe.com/docs/api/setup_intents/create
# A real implementation would include controls to prevent misuse
post '/create_setup_intent' do
  payload = params
  if request.content_type != nil and request.content_type.include? 'application/json' and params.empty?
      payload = Sinatra::IndifferentHash[JSON.parse(request.body.read)]
  end
  begin
    setup_intent = Stripe::SetupIntent.create({
      payment_method: payload[:payment_method],
      return_url: payload[:return_url],
      confirm: payload[:payment_method] != nil,
      customer: payload[:customer_id],
      use_stripe_sdk: payload[:payment_method] != nil ? true : nil,
    })
  rescue Stripe::StripeError => e
    status 402
    return log_info("Error creating SetupIntent: #{e.message}")
  end

  log_info("SetupIntent successfully created: #{setup_intent.id}")
  status 200
  return {
    :intent => setup_intent.id,
    :secret => setup_intent.client_secret,
    :status => setup_intent.status
  }.to_json
end

# ==== PaymentIntent Automatic Confirmation
# See https://stripe.com/docs/payments/payment-intents/ios

# This endpoint is used by the mobile example apps to create a PaymentIntent
# https://stripe.com/docs/api/payment_intents/create
# A real implementation would include controls to prevent misuse
post '/create_payment_intent' do
  authenticate!
  payload = params

  if request.content_type != nil and request.content_type.include? 'application/json' and params.empty?
      payload = Sinatra::IndifferentHash[JSON.parse(request.body.read)]
  end

  begin
    payment_intent = Stripe::PaymentIntent.create(
      :amount => 1099, # A real implementation would calculate the amount based on e.g. an order id
      :currency => payload[:currency] || 'usd',
      :description => "Example PaymentIntent",
      :capture_method => ENV['CAPTURE_METHOD'] == "manual" ? "manual" : "automatic",
      :metadata => {
        :order_id => '5278735C-1F40-407D-933A-286E463E72D8',
      }.merge(payload[:metadata] || {}),
    )
  rescue Stripe::StripeError => e
    status 402
    return log_info("Error creating PaymentIntent: #{e.message}")
  end

  log_info("PaymentIntent successfully created: #{payment_intent.id}")
  status 200
  return {
    :intent => payment_intent.id,
    :secret => payment_intent.client_secret,
    :status => payment_intent.status
  }.to_json
end

# ===== PaymentIntent Manual Confirmation 
# See https://stripe.com/docs/payments/payment-intents/ios-manual

# This endpoint is used by the mobile example apps to create and confirm a PaymentIntent 
# using manual confirmation. 
# https://stripe.com/docs/api/payment_intents/create
# https://stripe.com/docs/api/payment_intents/confirm
# A real implementation would include controls to prevent misuse
post '/confirm_payment_intent' do
  payload = params
  if request.content_type.include? 'application/json' and params.empty?
    payload = Sinatra::IndifferentHash[JSON.parse(request.body.read)]
  end

  begin
    if payload[:payment_intent_id]
      # Confirm the PaymentIntent
      payment_intent = Stripe::PaymentIntent.confirm(payload[:payment_intent_id], {:use_stripe_sdk => true})
    elsif payload[:payment_method]
      authenticate!
      # Create and confirm the PaymentIntent
      payment_intent = Stripe::PaymentIntent.create(
        :amount => 1099, # A real implementation would calculate the amount based on e.g. an order id
        :currency => payload[:currency] || 'usd',
        :customer_id => payload[:customer_id] || @customer.id,
        :source => payload[:source],
        :payment_method => payload[:payment_method],
        :description => "Example PaymentIntent",
        :shipping => payload[:shipping],
        :return_url => payload[:return_url],
        :confirm => true,
        :confirmation_method => "manual",
        :use_stripe_sdk => true, # You must set this for the mobile apps to handle native authentication for SCA
        :capture_method => ENV['CAPTURE_METHOD'] == "manual" ? "manual" : "automatic",
        :metadata => {
          :order_id => '5278735C-1F40-407D-933A-286E463E72D8',
        }.merge(payload[:metadata] || {}),
      )
    else
      status 400
      return log_info("Error: Missing params. Pass payment_intent_id to confirm or payment_method to create")
    end 
  rescue Stripe::StripeError => e
    status 402
    return log_info("Error: #{e.message}")
  end

  return generate_payment_response(payment_intent)
end

def generate_payment_response(payment_intent)
  # Note that if your API version is before 2019-02-11, 'requires_action'
  # appears as 'requires_source_action'.
  if payment_intent.status == 'requires_action'
    # Tell the client to handle the action
    status 200
    return {
      requires_action: true,
      secret: payment_intent.client_secret
    }.to_json
  elsif payment_intent.status == 'succeeded' or 
    (payment_intent.status == 'requires_capture' and ENV['CAPTURE_METHOD'] == "manual")
    # The payment didn’t need any additional actions and is completed!
    # Handle post-payment fulfillment
    status 200
    return {
      :success => true
    }.to_json
  else
    # Invalid status
    status 500
    return "Invalid PaymentIntent status"
  end
end