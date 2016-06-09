require 'sinatra'
require 'stripe'
require 'dotenv'
require 'json'

Dotenv.load

Stripe.api_key = ENV['STRIPE_TEST_SECRET_KEY']

get '/' do
  status 200
  return "Great, your backend is set up. Now you can configure the Stripe example iOS apps to point here."
end

post '/charge' do

  # Get the credit card details submitted by the form
  source = params[:source] || params[:stripe_token] || params[:stripeToken]
  customer = params[:customer]

  # Create the charge on Stripe's servers - this will charge the user's card
  begin
    charge = Stripe::Charge.create(
      :amount => params[:amount], # this number should be in cents
      :currency => "usd",
      :customer => customer,
      :source => source,
      :description => "Example Charge"
    )
  rescue Stripe::StripeError => e
    status 402
    return "Error creating charge: #{e.message}"
  end

  status 200
  return "Charge successfully created"

end

get '/customers/:customer' do

  customer = params[:customer]

  begin
    # Retrieves the customer's cards
    customer = Stripe::Customer.retrieve(customer)
  rescue Stripe::StripeError => e
    status 402
    return "Error retrieving customer: #{e.message}"
  end

  status 200
  content_type :json
  customer.to_json

end

post '/customers/:customer/sources' do

  source = params[:source]
  customer = params[:customer]

  # Adds the token to the customer's sources
  begin
    customer = Stripe::Customer.retrieve(customer)
    customer.sources.create({:source => source})
  rescue Stripe::StripeError => e
    status 402
    return "Error adding token to customer: #{e.message}"
  end

  status 200
  return "Successfully added source."

end

post '/customers/:customer/select_source' do

  source = params[:source]
  customer = params[:customer]

  # Sets the customer's default source
  begin
    customer = Stripe::Customer.retrieve(customer)
    customer.default_source = source
    customer.save
  rescue Stripe::StripeError => e
    status 402
    return "Error selecting default source: #{e.message}"
  end

  status 200
  return "Successfully selected default source."

end

delete '/customers/:customer/cards/:card' do

  card = params[:card]
  customer = params[:customer]

  # Deletes the source from the customer
  begin
    customer = Stripe::Customer.retrieve(customer)
    customer.sources.retrieve(card).delete()
  rescue Stripe::StripeError => e
    status 402
    return "Error deleting card"
  end

  status 200
  return "Successfully deleted card."

end

