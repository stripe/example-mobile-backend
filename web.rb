# server.rb
#
# Use this sample code to handle webhook events in your integration.
#
# 1) Paste this code into a new file (server.rb)
#
# 2) Install dependencies
#   gem install sinatra
#   gem install stripe
#
# 3) Run the server on http://localhost:4242
#   ruby server.rb

require 'json'
require 'sinatra'
require 'stripe'

# This is your Stripe CLI webhook secret for testing your endpoint locally.
endpoint_secret = 'whsec_48912a4b5e88a0592369c5bfbdeb0da054f4c83c8693cdd2ffe747f08f484aeb'

set :port, 4242

post '/webhook' do
    payload = request.body.read
    sig_header = request.env['HTTP_STRIPE_SIGNATURE']
    event = nil

    begin
        event = Stripe::Webhook.construct_event(
            payload, sig_header, endpoint_secret
        )
    rescue JSON::ParserError => e
        # Invalid payload
        status 400
        return
    rescue Stripe::SignatureVerificationError => e
        # Invalid signature
        status 400
        return
    end

    # Handle the event
    case event.type
    when 'account.updated'
        account = event.data.object
    when 'account.external_account.created'
        external_account = event.data.object
    when 'account.external_account.deleted'
        external_account = event.data.object
    when 'account.external_account.updated'
        external_account = event.data.object
    when 'balance.available'
        balance = event.data.object
    when 'billing_portal.configuration.created'
        configuration = event.data.object
    when 'billing_portal.configuration.updated'
        configuration = event.data.object
    when 'capability.updated'
        capability = event.data.object
    when 'charge.captured'
        charge = event.data.object
    when 'charge.expired'
        charge = event.data.object
    when 'charge.failed'
        charge = event.data.object
    when 'charge.pending'
        charge = event.data.object
    when 'charge.refunded'
        charge = event.data.object
    when 'charge.succeeded'
        charge = event.data.object
    when 'charge.updated'
        charge = event.data.object
    when 'charge.dispute.closed'
        dispute = event.data.object
    when 'charge.dispute.created'
        dispute = event.data.object
    when 'charge.dispute.funds_reinstated'
        dispute = event.data.object
    when 'charge.dispute.funds_withdrawn'
        dispute = event.data.object
    when 'charge.dispute.updated'
        dispute = event.data.object
    when 'charge.refund.updated'
        refund = event.data.object
    when 'checkout.session.async_payment_failed'
        session = event.data.object
    when 'checkout.session.async_payment_succeeded'
        session = event.data.object
    when 'checkout.session.completed'
        session = event.data.object
    when 'checkout.session.expired'
        session = event.data.object
    when 'coupon.created'
        coupon = event.data.object
    when 'coupon.deleted'
        coupon = event.data.object
    when 'coupon.updated'
        coupon = event.data.object
    when 'credit_note.created'
        credit_note = event.data.object
    when 'credit_note.updated'
        credit_note = event.data.object
    when 'credit_note.voided'
        credit_note = event.data.object
    when 'customer.created'
        customer = event.data.object
    when 'customer.deleted'
        customer = event.data.object
    when 'customer.updated'
        customer = event.data.object
    when 'customer.discount.created'
        discount = event.data.object
    when 'customer.discount.deleted'
        discount = event.data.object
    when 'customer.discount.updated'
        discount = event.data.object
    when 'customer.source.created'
        source = event.data.object
    when 'customer.source.deleted'
        source = event.data.object
    when 'customer.source.expiring'
        source = event.data.object
    when 'customer.source.updated'
        source = event.data.object
    when 'customer.subscription.created'
        subscription = event.data.object
    when 'customer.subscription.deleted'
        subscription = event.data.object
    when 'customer.subscription.pending_update_applied'
        subscription = event.data.object
    when 'customer.subscription.pending_update_expired'
        subscription = event.data.object
    when 'customer.subscription.trial_will_end'
        subscription = event.data.object
    when 'customer.subscription.updated'
        subscription = event.data.object
    when 'customer.tax_id.created'
        tax_id = event.data.object
    when 'customer.tax_id.deleted'
        tax_id = event.data.object
    when 'customer.tax_id.updated'
        tax_id = event.data.object
    when 'file.created'
        file = event.data.object
    when 'identity.verification_session.canceled'
        verification_session = event.data.object
    when 'identity.verification_session.created'
        verification_session = event.data.object
    when 'identity.verification_session.processing'
        verification_session = event.data.object
    when 'identity.verification_session.requires_input'
        verification_session = event.data.object
    when 'identity.verification_session.verified'
        verification_session = event.data.object
    when 'invoice.created'
        invoice = event.data.object
    when 'invoice.deleted'
        invoice = event.data.object
    when 'invoice.finalization_failed'
        invoice = event.data.object
    when 'invoice.finalized'
        invoice = event.data.object
    when 'invoice.marked_uncollectible'
        invoice = event.data.object
    when 'invoice.paid'
        invoice = event.data.object
    when 'invoice.payment_action_required'
        invoice = event.data.object
    when 'invoice.payment_failed'
        invoice = event.data.object
    when 'invoice.payment_succeeded'
        invoice = event.data.object
    when 'invoice.sent'
        invoice = event.data.object
    when 'invoice.upcoming'
        invoice = event.data.object
    when 'invoice.updated'
        invoice = event.data.object
    when 'invoice.voided'
        invoice = event.data.object
    when 'invoiceitem.created'
        invoiceitem = event.data.object
    when 'invoiceitem.deleted'
        invoiceitem = event.data.object
    when 'invoiceitem.updated'
        invoiceitem = event.data.object
    when 'issuing_authorization.created'
        issuing_authorization = event.data.object
    when 'issuing_authorization.updated'
        issuing_authorization = event.data.object
    when 'issuing_card.created'
        issuing_card = event.data.object
    when 'issuing_card.updated'
        issuing_card = event.data.object
    when 'issuing_cardholder.created'
        issuing_cardholder = event.data.object
    when 'issuing_cardholder.updated'
        issuing_cardholder = event.data.object
    when 'issuing_dispute.closed'
        issuing_dispute = event.data.object
    when 'issuing_dispute.created'
        issuing_dispute = event.data.object
    when 'issuing_dispute.funds_reinstated'
        issuing_dispute = event.data.object
    when 'issuing_dispute.submitted'
        issuing_dispute = event.data.object
    when 'issuing_dispute.updated'
        issuing_dispute = event.data.object
    when 'issuing_transaction.created'
        issuing_transaction = event.data.object
    when 'issuing_transaction.updated'
        issuing_transaction = event.data.object
    when 'mandate.updated'
        mandate = event.data.object
    when 'order.created'
        order = event.data.object
    when 'order.payment_failed'
        order = event.data.object
    when 'order.payment_succeeded'
        order = event.data.object
    when 'order.updated'
        order = event.data.object
    when 'order_return.created'
        order_return = event.data.object
    when 'payment_intent.amount_capturable_updated'
        payment_intent = event.data.object
    when 'payment_intent.canceled'
        payment_intent = event.data.object
    when 'payment_intent.created'
        payment_intent = event.data.object
    when 'payment_intent.partially_funded'
        payment_intent = event.data.object
    when 'payment_intent.payment_failed'
        payment_intent = event.data.object
    when 'payment_intent.processing'
        payment_intent = event.data.object
    when 'payment_intent.requires_action'
        payment_intent = event.data.object
    when 'payment_intent.succeeded'
        payment_intent = event.data.object
    when 'payment_link.created'
        payment_link = event.data.object
    when 'payment_link.updated'
        payment_link = event.data.object
    when 'payment_method.attached'
        payment_method = event.data.object
    when 'payment_method.automatically_updated'
        payment_method = event.data.object
    when 'payment_method.detached'
        payment_method = event.data.object
    when 'payment_method.updated'
        payment_method = event.data.object
    when 'payout.canceled'
        payout = event.data.object
    when 'payout.created'
        payout = event.data.object
    when 'payout.failed'
        payout = event.data.object
    when 'payout.paid'
        payout = event.data.object
    when 'payout.updated'
        payout = event.data.object
    when 'person.created'
        person = event.data.object
    when 'person.deleted'
        person = event.data.object
    when 'person.updated'
        person = event.data.object
    when 'plan.created'
        plan = event.data.object
    when 'plan.deleted'
        plan = event.data.object
    when 'plan.updated'
        plan = event.data.object
    when 'price.created'
        price = event.data.object
    when 'price.deleted'
        price = event.data.object
    when 'price.updated'
        price = event.data.object
    when 'product.created'
        product = event.data.object
    when 'product.deleted'
        product = event.data.object
    when 'product.updated'
        product = event.data.object
    when 'promotion_code.created'
        promotion_code = event.data.object
    when 'promotion_code.updated'
        promotion_code = event.data.object
    when 'quote.accepted'
        quote = event.data.object
    when 'quote.canceled'
        quote = event.data.object
    when 'quote.created'
        quote = event.data.object
    when 'quote.finalized'
        quote = event.data.object
    when 'radar.early_fraud_warning.created'
        early_fraud_warning = event.data.object
    when 'radar.early_fraud_warning.updated'
        early_fraud_warning = event.data.object
    when 'recipient.created'
        recipient = event.data.object
    when 'recipient.deleted'
        recipient = event.data.object
    when 'recipient.updated'
        recipient = event.data.object
    when 'reporting.report_run.failed'
        report_run = event.data.object
    when 'reporting.report_run.succeeded'
        report_run = event.data.object
    when 'review.closed'
        review = event.data.object
    when 'review.opened'
        review = event.data.object
    when 'setup_intent.canceled'
        setup_intent = event.data.object
    when 'setup_intent.created'
        setup_intent = event.data.object
    when 'setup_intent.requires_action'
        setup_intent = event.data.object
    when 'setup_intent.setup_failed'
        setup_intent = event.data.object
    when 'setup_intent.succeeded'
        setup_intent = event.data.object
    when 'sigma.scheduled_query_run.created'
        scheduled_query_run = event.data.object
    when 'sku.created'
        sku = event.data.object
    when 'sku.deleted'
        sku = event.data.object
    when 'sku.updated'
        sku = event.data.object
    when 'source.canceled'
        source = event.data.object
    when 'source.chargeable'
        source = event.data.object
    when 'source.failed'
        source = event.data.object
    when 'source.mandate_notification'
        source = event.data.object
    when 'source.refund_attributes_required'
        source = event.data.object
    when 'source.transaction.created'
        transaction = event.data.object
    when 'source.transaction.updated'
        transaction = event.data.object
    when 'subscription_schedule.aborted'
        subscription_schedule = event.data.object
    when 'subscription_schedule.canceled'
        subscription_schedule = event.data.object
    when 'subscription_schedule.completed'
        subscription_schedule = event.data.object
    when 'subscription_schedule.created'
        subscription_schedule = event.data.object
    when 'subscription_schedule.expiring'
        subscription_schedule = event.data.object
    when 'subscription_schedule.released'
        subscription_schedule = event.data.object
    when 'subscription_schedule.updated'
        subscription_schedule = event.data.object
    when 'tax_rate.created'
        tax_rate = event.data.object
    when 'tax_rate.updated'
        tax_rate = event.data.object
    when 'terminal.reader.action_failed'
        reader = event.data.object
    when 'terminal.reader.action_succeeded'
        reader = event.data.object
    when 'test_helpers.test_clock.advancing'
        test_clock = event.data.object
    when 'test_helpers.test_clock.created'
        test_clock = event.data.object
    when 'test_helpers.test_clock.deleted'
        test_clock = event.data.object
    when 'test_helpers.test_clock.internal_failure'
        test_clock = event.data.object
    when 'test_helpers.test_clock.ready'
        test_clock = event.data.object
    when 'topup.canceled'
        topup = event.data.object
    when 'topup.created'
        topup = event.data.object
    when 'topup.failed'
        topup = event.data.object
    when 'topup.reversed'
        topup = event.data.object
    when 'topup.succeeded'
        topup = event.data.object
    when 'transfer.created'
        transfer = event.data.object
    when 'transfer.failed'
        transfer = event.data.object
    when 'transfer.paid'
        transfer = event.data.object
    when 'transfer.reversed'
        transfer = event.data.object
    when 'transfer.updated'
        transfer = event.data.object
    # ... handle other event types
    else
        puts "Unhandled event type: #{event.type}"
    end

    status 200
end