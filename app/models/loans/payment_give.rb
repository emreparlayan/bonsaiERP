# encoding: utf-8
# class for to make payments for Loans received the money goes out
# author: Boris Barroso
# email: boriscyber@gmail.com
class Loans::PaymentGive < Loans::Payment

  def create_payment
    return false  unless valid?
    res = true

    commit_or_rollback do
      res = ledger.save_ledger
      res = save_expense if account_to_is_expense?
      res = update_loan && res
    end
  end

  def create_interest
    int_ledger.save_ledger
  end

  def loan
    @loan ||= Loans::Give.find_by(id: account_id)
  end

  def ledger
    @ledger ||= begin
      AccountLedger.new(
        account_id: loan.id, account_to_id: account_to_id, currency: currency,
        date: date, reference: reference,
        operation: 'lgpay', amount: amount
      )
    end
  end

  def int_ledger
    @int_ledger ||= begin
      AccountLedger.new(
        account_id: loan.id, account_to_id: account_to_id, currency: currency,
        date: date, reference: reference,
        operation: 'lgint', amount: amount
      )
    end
  end

  private

    def account_to_is_expense?
      account_to.is_a?(Expense)
    end

    def save_expense
      account_to.amount -= amount
      account_to.set_state_by_balance!

      account_to.save
    end

    def update_loan
      loan.amount -= amount_exchange
      loan.state = 'paid'  if loan.amount == 0
      loan.save
    end
end

