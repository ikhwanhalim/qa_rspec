require 'spec_helper'
require './groups/dns_actions'

describe 'Dns' do
  before(:all) do
    @dnsa = DnsActions.new.precondition
  end

  let(:dns) { @dnsa.dns }

  it 'should be created' do
   puts expect(dns.name).not_to be nil
    puts dns.user_id
  end


  it 'should be GETable' do
    puts @dnsa.get(dns.route)
    expect(@dnsa.conn.page.code).to eq '200'
  end

  it 'should GET advanced' do
   puts @dnsa.get(dns.route)
    expect(@dnsa.conn.page.code).to eq '200'
  end

  it 'should Get List of Users DNS Zones' do
    puts @dnsa.get("/dns_zones/#{dns.user_id}")
  end

 #  undefined method `each_pair' for "ns1.qaonapp.net":String
 # it 'should Get List of Name Servers' do
  #   @dnsa.get("/dns_zones/name_servers")
  # end

  # it 'should Add DNS Record' do
  #   puts @dnsa.post(@route_edit, name: "test", ttl: "111",  type: "A", ip: "127.0.0.1")
  # end

  it 'should be removed' do
   puts dns.remove
    expect(@dnsa.conn.page.code).to eq '204'
  end
end



# try to create dns_zone with empty name
#add dns record
#get dns record
#edit dns record
# get dns record

#require 'pry';binding.pry
