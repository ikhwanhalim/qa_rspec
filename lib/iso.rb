class Iso
  include Transaction
  attr_reader :interface, :iso_id, :data

  def initialize(interface)
    @interface = interface
  end

  def create(data)
    params = {}
    params[:image_template_iso]= data
    response = interface.post("/template_isos", params)

    if response ['image_template_iso']
      @iso_id = response['image_template_iso']['id']
      @data = response['image_template_iso']
      wait_for_downloading(iso_id)
    else
      Log.warn(response['errors'])
      @data = response['errors']

    end
  end

  def edit(data)
    params ={}
    params[:image_template_iso] = data
    response = interface.put("/template_isos/#{@iso_id}", params)
    if response ['image_template_iso']
      @data = response['image_template_iso']
    else
      @data = response['errors']
    end
  end

  def make_public
    interface.post("/template_isos/#{@iso_id}/make_public")
  end

  def find(iso_id)
    response = interface.get("/template_isos/#{iso_id}")
    if response ['image_template_iso']
      @iso_id = response['image_template_iso']['id']
      @data = response['image_template_iso']
    else
      @data = response['errors']
    end
  end

  def remove
     interface.delete("/template_isos/#{@iso_id}")
     Log.error('ISO has not been deleted') if api_response_code != '204'
  end

  def wait_for_downloading (iso_id)
    wait_for_transaction(iso_id, 'ImageTemplateBase', 'download_iso')
  end

  def api_response_code
    interface.conn.page.code
  end

  def min_memory_size
    data['min_memory_size']
  end

end