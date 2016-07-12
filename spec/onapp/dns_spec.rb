require 'spec_helper'
require './groups/dns_actions'

describe 'Dns' do
  before(:all) do
    @dnsa = DnsActions.new.precondition
  end

  let(:dns) { @dnsa.dns }

  it 'should be created' do
   expect(dns.name).not_to be nil
    puts dns.user_id
  end

  it 'should be GETable' do
   @dnsa.get(dns.route)
    expect(@dnsa.conn.page.code).to eq '200'
  end

  it 'should GET advanced' do
   @dnsa.get(dns.route)
    expect(@dnsa.conn.page.code).to eq '200'
  end

  it 'should Get List of Users DNS Zones' do
   @dnsa.get("/dns_zones/#{dns.user_id}")
  end

 #  undefined method `each_pair' for "ns1.qaonapp.net":String
 # it 'should Get List of Name Servers' do
  #   @dnsa.get("/dns_zones/name_servers")
  # end

  # it 'should add dns record' do
  # puts  dns.create_dns_record
  # end

  it 'should be removed' do
   dns.remove
    expect(@dnsa.conn.page.code).to eq '204'
  end

  it 'dns_zone should not be added with empty name' do
   dns.create(name: "")
    expect(@dnsa.conn.page.code).to eq '422'
  end

  it 'dns_zone should not be added with incorrect(digit) name' do
   # dns.create(name: "#{rand.to_s[2..11]}")
    dns.create(name: "#{SecureRandom.random_number(100)}")
    expect(@dnsa.conn.page.code).to eq '422'
  end

  it 'dns_zone should not be added with incorrect() name' do
    #dns.create(name: "#{(0...10).map { ('a'..'z').to_a[rand(5)] }.join}")
    dns.create(name: "#{SecureRandom.hex}")
    expect(@dnsa.conn.page.code).to eq '422'
  end
end


# try to create dns_zone with empty/incorrect name
#add/get dns record
#edit/get dns record


#require 'pry';binding.pry
