# frozen_string_literal: true

module OrderManagement
  module Subscriptions
    class StripePaymentSetup
      def initialize(order)
        @order = order
        @payment = @order.pending_payments.last
      end

      def call!
        return if @payment.blank?

        ensure_payment_source
        @payment
      end

      private

      def ensure_payment_source
        return if !card_required? || card_set?

        if saved_credit_card.present? && allow_charges?
          use_saved_credit_card
        else
          @order.errors.add(:base, :no_card)
        end
      end

      def card_required?
        [Spree::Gateway::StripeConnect,
         Spree::Gateway::StripeSCA].include? @payment.payment_method.class
      end

      def card_set?
        @payment.source is_a? Spree::CreditCard
      end

      def use_saved_credit_card
        @payment.update_attributes(source: saved_credit_card)
      end

      def saved_credit_card
        @order.user.default_card
      end

      def allow_charges?
        @order.customer.allow_charges?
      end
    end
  end
end
