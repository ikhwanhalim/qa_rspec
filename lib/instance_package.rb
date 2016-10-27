class InstancePackage
  include Transaction
  attr_reader :interface, :id, :label, :cpus, :disk_size, :memory, :bandwidth, :billing_plan_ids, :errors

  def initialize(interface)
    @interface = interface
  end

  def build_data
    {
        label: @label || "InstancePackage-#{SecureRandom.hex(1)}",
        cpus: '1',
        disk_size: '6',
        memory: '128',
        bandwidth: '1'
    }
  end

  def create(**params)
    response_handler interface.post("/instance_packages", { instance_package: build_data.merge(params) })
  end

  def find(instance_package_id)
    response_handler interface.get("/instance_packages/#{instance_package_id}")
  end

  def edit(**params)
    response_handler interface.put(route, { instance_package: build_data.merge(params) })
  end

  def remove
    interface.delete(route)
    response_handler response if api_response_code != '204'
  end

  def route
    "/instance_packages/#{id}"
  end

  def api_response_code
    interface.conn.page.code
  end

  def response_handler(response)
    @errors = response['errors']
    instance_package = if response['instance_package']
                           response['instance_package']
                         elsif !@errors
                           interface.get(route)['instance_package']
                         end
    return Log.warn(@errors) if @errors
    instance_package.each { |k, v| instance_variable_set("@#{k}", v)}
  end
end