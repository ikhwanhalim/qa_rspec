class Currency
  attr_reader :interface, :id, :errors, :name, :code, :unit, :delimiter, :separator, :precision, :precision_for_unit, :format

  def initialize(interface)
    @interface = interface
  end

  def build_data
    {
        name: 'Ukrainian Hryvnia',
        code: 'UAH',
        unit: '₴',
        delimiter: '.',
        separator: ',',
        precision: '2',
        precision_for_unit: '4',
        format: "%u%n"
    }
  end

  def create(**params)
    response_handler interface.post('/settings/currencies', { currency: build_data.merge(params) })
    self
  end

  def find(currency_id)
    response_handler interface.get("/settings/currencies/#{currency_id}")
  end

  def edit(**params)
    response_handler interface.put(route, { currency: build_data.merge(params) })
  end

  def remove
    interface.delete(route)
  end

  def route
    "/settings/currencies/#{id}"
  end

  def api_response_code
    interface.conn.page.code
  end

  def response_handler(response)
    @errors = response['errors']
    currency = if response['currency']
                         response['currency']
                       elsif !@errors
                         interface.get(route)['currency']
                       end
    return Log.warn(@errors) if @errors
    currency.each { |k, v| instance_variable_set("@#{k}", v)}
  end
end