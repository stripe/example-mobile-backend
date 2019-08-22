require 'sinatra'
require 'stripe'
require 'dotenv'
require 'json'
require 'encrypted_cookie'

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

post '/capture_payment' do
  authenticate!
  # Get the credit card details submitted
  payload = params
  if request.content_type.include? 'application/json' and params.empty?
    payload = Sinatra::IndifferentHash[JSON.parse(request.body.read)]
  end

  # Create and capture the PaymentIntent via Stripe's API - this will charge the user's card
  begin
    payment_intent_id = ENV['DEFAULT_PAYMENT_INTENT_ID']
    if payment_intent_id
      payment_intent = Stripe::PaymentIntent.retrieve(payment_intent_id)
    else
      payment_intent = create_and_capture_payment_intent(
        payload[:amount],
        payload[:source],
        payload[:payment_method],
        payload[:payment_method_types] || ['card'],
        payload[:customer_id] || @customer.id,
        payload[:metadata],
        payload[:currency] || 'usd',
        payload[:shipping],
        payload[:return_url],
      )
    end
  rescue Stripe::StripeError => e
    status 402
    return log_info("Error: #{e.message}")
  end

  status 200
  return {
      :secret => payment_intent.client_secret
  }.to_json
end

post '/confirm_payment' do
    authenticate!
    payload = params
    if request.content_type.include? 'application/json' and params.empty?
        payload = Sinatra::IndifferentHash[JSON.parse(request.body.read)]
    end
    begin
        payment_intent = Stripe::PaymentIntent.confirm(payload[:payment_intent_id], {:use_stripe_sdk => true})
        rescue Stripe::StripeError => e
        status 402
        return log_info("Error: #{e.message}")
    end

    status 200
    return {
        :secret => payment_intent.client_secret
    }.to_json
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

        payment_methods = ['pm_card_threeDSecure2Required', 'pm_card_visa']

        ['4000000000003220', '4000000000003238', '4000000000003246', '4000000000003253'].each { |cc_number|
          pm = Stripe::PaymentMethod.create({
            type: 'card',
            card: {
              number: cc_number,
              exp_month: 8,
              exp_year: 2022,
              cvc: '123',
            },
          })
          payment_methods.push pm.id
        }

        # Attach some test cards to the customer for testing convenience.
        # See https://stripe.com/docs/testing#cards
        payment_methods.each { |pm_id|
          Stripe::PaymentMethod.attach(
            pm_id,
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

# This endpoint is used by the mobile example apps to create a SetupIntent.
# https://stripe.com/docs/api/setup_intents/create
# Just like the `/capture_payment` endpoint, a real implementation would include controls
# to prevent misuse
post '/create_setup_intent' do
  payload = params
  if request.content_type != nil and request.content_type.include? 'application/json' and params.empty?
      payload = Sinatra::IndifferentHash[JSON.parse(request.body.read)]
  end
  begin
    setup_intent = Stripe::SetupIntent.create({
      payment_method_types: payload[:payment_method_types] || ['card'],
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

# This endpoint is used by the mobile example apps to create a PaymentIntent.
# https://stripe.com/docs/api/payment_intents/create
# Just like the `/capture_payment` endpoint, a real implementation would include controls
# to prevent misuse
post '/create_intent' do
  begin
    payment_intent_id = ENV['DEFAULT_PAYMENT_INTENT_ID']
    if payment_intent_id
      payment_intent = Stripe::PaymentIntent.retrieve(payment_intent_id)
    else
      payment_intent = create_payment_intent(
        params[:amount],
        nil,
        nil,
        params[:payment_method_types] || ['card'],
        nil,
        params[:metadata],
        params[:currency],
        nil,
        nil
      )
    end
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

# This endpoint responds to webhooks sent by Stripe. To use it, you'll need
# to add its URL (https://{your-app-name}.herokuapp.com/stripe-webhook)
# in the webhook settings section of the Dashboard.
# https://dashboard.stripe.com/account/webhooks
post '/stripe-webhook' do
  json = JSON.parse(request.body.read)

  # Retrieving the event from Stripe guarantees its authenticity
  event = Stripe::Event.retrieve(json["id"])
  source = event.data.object

  # For sources that require additional user action from your customer
  # (e.g. authorizing the payment with their bank), you should use webhooks
  # to capture a PaymentIntent after the source becomes chargeable.
  # For more information, see https://stripe.com/docs/sources#best-practices
  WEBHOOK_CHARGE_CREATION_TYPES = ['bancontact', 'giropay', 'ideal', 'sofort', 'three_d_secure']
  if event.type == 'source.chargeable' && WEBHOOK_CHARGE_CREATION_TYPES.include?(source.type)
    begin
      create_and_capture_payment_intent(
        source.amount,
        source.id,
        nil,
        ['card'],
        source.metadata["customer"],
        source.metadata,
        source.currency,
        nil,
        nil
      )
    rescue Stripe::StripeError => e
      return log_info("Error creating PaymentIntent: #{e.message}")
    end
    # After successfully capturing a PaymentIntent, you should complete your customer's
    # order and notify them that their order has been fulfilled (e.g. by sending
    # an email). When creating the source in your app, consider storing any order
    # information (e.g. order number) as metadata so that you can retrieve it
    # here and use it to complete your customer's purchase.
  end
  status 200
end

def create_payment_intent(amount, source_id, payment_method_id, payment_method_types = ['card'], customer_id = nil,
                          metadata = {}, currency = 'usd', shipping = nil, return_url = nil, confirm = false)
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

def create_and_capture_payment_intent(amount, source_id, payment_method_id, payment_method_types = ['card'],
                                      customer_id = nil, metadata = {}, currency = 'usd', shipping = nil,
                                      return_url = nil)
  return create_payment_intent(amount, source_id, payment_method_id, payment_method_types,
                               customer_id, metadata, currency, shipping, return_url, true)
end
