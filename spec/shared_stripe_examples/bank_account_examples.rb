require 'spec_helper'

shared_examples 'Bank Account API' do

  it 'creates/returns a card when using customer.sources.create given a card token' do
    customer = Stripe::Customer.create(id: 'test_customer_sub')
    bank_token = StripeMock.generate_bank_token(last4: '1123', name: 'Test bank')
    bank_account = customer.sources.create(source: bank_token)

    expect(bank_account.customer).to eq('test_customer_sub')
    expect(bank_account.last4).to eq('1123')
    expect(bank_account.name).to eq('Test bank')
    expect(bank_account.object).to eq('bank_account')

    customer = Stripe::Customer.retrieve('test_customer_sub')
    expect(customer.sources.count).to eq(1)
    bank_account = customer.sources.data.first
    expect(bank_account.customer).to eq('test_customer_sub')
    expect(bank_account.last4).to eq('1123')
    expect(bank_account.name).to eq('Test bank')
    expect(bank_account.object).to eq('bank_account')
  end

end
