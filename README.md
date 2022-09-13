Example App Backend
====

This is a really simple [Sinatra](http://www.sinatrarb.com/) webapp that you can use to test Stripe's [example iOS apps](https://github.com/stripe/stripe-ios) and
[example Android apps](https://github.com/stripe/stripe-android).

This is intended for example purposes only: you'll likely need something more serious for your production apps.

To deploy this for free on Glitch, click [here](https://glitch.com/edit/#!/remix/clone-from-repo?&REPO_URL=https://github.com/stripe/example-mobile-backend).

In your `.env` file in Glitch, set `STRIPE_TEST_SECRET_KEY` to your secret key. Find this at https://dashboard.stripe.com/account/apikeys (it'll look like `sk_test_****`).

Then, set the `backendBaseURL` variable in our example apps to your Glitch URL (it'll be in the format https://my-example-app.glitch.me).

Happy testing!
