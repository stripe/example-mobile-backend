Example iOS Backend
====

This is a really simple [Sinatra](http://www.sinatrarb.com/) webapp that you can use to test Stripe's [example iOS apps](https://github.com/stripe/stripe-ios).

It has a single endpoint, `/charge`, which takes 2 parameters (`stripeToken` and `amount`) to create a charge on your Stripe account.

This is intended for example purposes only: you'll likely need something more serious for your production apps.

To deploy this for free on Heroku, click this button:

[![Deploy](https://www.herokucdn.com/deploy/button.png)](https://heroku.com/deploy)

Then set the `backendChargeURLString` variable in our example apps to your Heroku URL (it'll be in the format https://my-example-app.herokuapp.com).

Happy testing!
