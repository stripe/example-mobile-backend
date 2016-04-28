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
  token = params[:stripe_token]
  customer = params[:customer]

  # Create the charge on Stripe's servers - this will charge the user's card
  begin
    charge = Stripe::Charge.create(
      :amount => params[:amount], # this number should be in cents
      :currency => "usd",
      :customer => customer,
      :source => token,
      :description => "Example Charge"
    )
  rescue Stripe::StripeError => e
    status 402
    return "Error creating charge."
  end

  status 200
  return "Charge successfully created"

end

get '/cards' do

  customer = params[:customer]

  begin
    # Retrieves the customer's cards
    customer = Stripe::Customer.retrieve(customer)
  rescue Stripe::StripeError => e
    status 402
    return "Error retrieving cards."
  end

  status 200
  content_type :json
  cards = customer.sources.all(:object => "card")
  selected_card = cards.find {|c| c.id == customer.default_source}
  return { :cards => cards.data, selected_card: selected_card }.to_json

end

post '/add_token' do

  token = params[:stripe_token]
  customer = params[:customer]

  # Adds the token to the customer's sources
  begin
    customer = Stripe::Customer.retrieve(customer)
    customer.sources.create({:source => token})
  rescue Stripe::StripeError => e
    status 402
    return "Error adding token to customer."
  end

  status 200
  content_type :json
  cards = customer.sources.all(:object => "card")
  selected_card = cards.find {|c| c.id == customer.default_source}
  return { :cards => cards.data, selected_card: selected_card }.to_json

end

post '/select_source' do

  source = params[:source]
  customer = params[:customer]

  # Sets the customer's default source
  begin
    customer = Stripe::Customer.retrieve(customer)
    customer.default_source = source
    customer.save
  rescue Stripe::StripeError => e
    status 402
    return "Error selecting default source."
  end

  status 200
  content_type :json
  cards = customer.sources.all(:object => "card")
  selected_card = cards.find {|c| c.id == customer.default_source}
  return { :cards => cards.data, selected_card: selected_card }.to_json

end
