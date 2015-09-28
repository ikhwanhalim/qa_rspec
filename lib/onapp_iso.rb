require 'yaml'
require 'json'
require 'helpers/onapp_http'
require 'helpers/onapp_log'
require 'helpers/transaction'

class OnappISO

  include OnappHTTP, Transaction
  attr_accessor :iso_id, :data

  def initialize
    auth unless self.conn
  end

  def create_iso (data)
    params = {}
    params[:image_template_iso]= data
    response = post("/template_isos", params)

    if response ['image_template_iso']
      @iso_id = response['image_template_iso']['id']
      @data = response['image_template_iso']
      wait_for_iso_downloading(iso_id)
    else
      @data = response['errors']
    end
  end

  def edit_iso (data)
    params ={}
    params[:image_template_iso] = data
    response = put("/template_isos/#{@iso_id}", params)
    if response ['image_template_iso']
      @data = response['image_template_iso']
    else
      @data = response['errors']
    end
  end

  def make_iso_public
    post("/template_isos/#{@iso_id}/make_public")
  end

  def get_iso (iso_id)
    response = get("/template_isos/#{iso_id}")
     if response ['image_template_iso']
      @data = response['image_template_iso']
    else
      @data = response['errors']
    end
  end

  def delete_iso
    delete("/template_isos/#{@iso_id}")
  end

  def wait_for_iso_downloading (iso_id)
    wait_for_transaction(iso_id, 'ImageTemplateBase', 'download_iso')
  end

  def api_response_code
    @conn.page.code
  end
end