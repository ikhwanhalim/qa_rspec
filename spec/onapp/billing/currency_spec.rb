require 'spec_helper'
require './groups/billing_plan_actions'


describe 'Billing Plan Tests' do
  before(:all) do
    @bpa = BillingPlanActions.new.precondition
    @currency = @bpa.currency
  end

  after(:all) do
    @currency.remove
  end

  let(:currency) { @currency }

  describe 'Create currency' do
    context 'negative tests' do
      after { expect(currency.api_response_code).to eq '422' }

      it 'Currency with empty name should not be created' do
        currency.create(name: '')
        expect(currency.errors['name']).to eq(["can't be blank"])
      end

      it 'Currency with empty code should not be created' do
        currency.create(code: '')
        expect(currency.errors['code']).to eq(["can't be blank"])
      end

      it 'Currency with empty unit should not be created' do
        currency.create(unit: '')
        expect(currency.errors['unit']).to eq(["can't be blank"])
      end

      it 'Currency with precision more than 5 should not be created' do
        currency.create(precision: '6')
        expect(currency.errors['precision']).to eq(["can only be between 0 and 5."])
      end

      it 'Currency with precision_for_unit more than 8 should not be created' do
        currency.create(precision_for_unit: '9')
        expect(currency.errors['precision_for_unit']).to eq(["can only be between 0 and 8"])
      end

      it 'Currency with empty format should not be created' do
        currency.create(format: '')
        expect(currency.errors['format']).to eq(["can't be blank"])
      end

      it 'Currency with the same delimiter and separator should not be created' do
        currency.create(delimiter: '.', separator: '.')
        expect(currency.errors['separator']).to eq(["Delimiter and separator must be different."])
      end
    end

    context 'positive tests' do
      it 'Currency should be created' do
        @currency.create
        expect(@currency.name).to eq 'Ukrainian Hryvnia'
      end
    end
  end

  describe 'Edit currency' do
    context 'negative tests' do
      after { expect(currency.api_response_code).to eq '422' }

      it 'Edit currency with precision more than 5' do
        currency.edit(precision: 6)
        expect(currency.errors['precision']).to eq(["can only be between 0 and 5."])
      end

      it 'Edit currency with precision_for_unit more than 8' do
        currency.edit(precision_for_unit: 9)
        expect(currency.errors['precision_for_unit']).to eq(["can only be between 0 and 8"])
      end
    end

    context 'positive tests' do
      before (:all) do
        @data = {
            name: 'Poland Zloty',
            code: 'PLN',
            unit: 'zł',
            delimiter: ',',
            separator: '.',
            precision: 4,
            precision_for_unit: 5,
            format: "%u"
        }
        @currency.edit(@data)
      end

      it 'Edit currency name' do
        expect(currency.name).to eq @data[:name]
      end

      it 'Edit currency code' do
        expect(currency.code).to eq @data[:code]
      end

      it 'Edit currency unit' do
        expect(currency.unit).to eq @data[:unit]
      end

      it 'Edit currency delimiter' do
        expect(currency.delimiter).to eq @data[:delimiter]
      end

      it 'Edit currency separator' do
        expect(currency.separator).to eq @data[:separator]
      end

      it 'Edit currency precision' do
        expect(currency.precision).to eq @data[:precision]
      end

      it 'Edit currency precision_for_unit' do
        expect(currency.precision_for_unit).to eq @data[:precision_for_unit]
      end

      it 'Edit currency format' do
        expect(currency.format).to eq @data[:format]
      end
    end
  end
end

