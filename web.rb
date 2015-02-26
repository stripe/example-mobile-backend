require 'sinatra'
require 'stripe'
require 'dotenv'

Dotenv.load

Stripe.api_key = ENV['STRIPE_API_KEY']

post '/charge' do

  # Get the credit card details submitted by the form
  token = params[:stripeToken]

  # Create the charge on Stripe's servers - this will charge the user's card
  begin
    charge = Stripe::Charge.create(
      :amount => params[:amount], # this number should be in cents
      :currency => "usd",
      :card => token,
      :description => "Example Charge"
    )
  rescue Stripe::CardError => e
    status 402
    return "Error creating charge."
  end

  status 200
  return "Order successfully created"

end
