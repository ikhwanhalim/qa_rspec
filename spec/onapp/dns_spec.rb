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

  # it 'should add dns record' do
  # puts  dns.create_dns_record
  # end

  it 'should be removed' do
   puts dns.remove
    expect(@dnsa.conn.page.code).to eq '204'
  end

  # it 'should not added with empty name' do
  #   #dns.create(name: "")
  #   expect(dns.create(name: "")).to eq '422'
  # end
end


# try to create dns_zone with empty/incorrect name
#add/get dns record
#edit/get dns record


#require 'pry';binding.pry
