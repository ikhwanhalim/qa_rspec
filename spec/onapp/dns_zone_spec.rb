require 'spec_helper'
require './groups/dns_zone_actions'


describe 'DnsZone' do
  before(:all) do
    @dza = DnsZoneActions.new.precondition
    @ns_record = @dza.dns_zone.create_dns_record(type: "NS",
                                                  hostname: Faker::Internet.domain_name)
  end

  let(:dns_zone) { @dza.dns_zone }

  it 'should be created' do
    expect(dns_zone.name).not_to be nil
  end

  it 'should Get List of Own DNS Zones' do
    @dza.get(dns_zone.route_dns_zones)
    expect(@dza.conn.page.code).to eq '200'
  end

  it 'should Get Domain Zone Details' do
    @dza.get(dns_zone.route_dns_zone)
    expect(@dza.conn.page.code).to eq '200'
  end

  it 'should Get List of Users DNS Zones' do
    @dza.get("/dns_zones/user")
    expect(@dza.conn.page.code).to eq '200'
  end

  it 'is Get dns domain details' do
    @dza.get("/settings/dns_setup")
    expect(@dza.conn.page.code).to eq '200'
  end

  it 'is Get dns domain details' do
    @dza.get("/settings/dns_setup/glue_records")
    expect(@dza.conn.page.code).to eq '200'
  end

 # TODO it 'should Get List of Name Servers' do
 # error: undefined method `each_pair' for "ns1.qaonapp.net":String
 # it 'should Get List of Name Servers' do
 #   @dns_zone_a.get("/dns_zones/name_servers.json")
 #   expect(@dns_zone_a.conn.page.code).to eq '200'
 # end

  describe 'NS record'  do
    before(:all) do
        @ns_record = @dza.dns_zone.create_dns_record(type: "NS",
                                                     hostname: Faker::Internet.domain_name)
    end

    it 'should get the record' do
     @ns_record.get
      expect(@dza.conn.page.code).to eq '200'
    end

    it 'should be editable(name)' do
    @ns_record.edit({:dns_record=>{:name => "1234"}})
      expect(@dza.conn.page.code).to eq '204'
    end

    it 'should be editable(hostname)' do
     @ns_record.edit({:dns_record=>{:hostname => "nskw.net"}})
      expect(@dza.conn.page.code).to eq '204'
    end

    it 'should be editable(ttl)' do
      @ns_record.edit({:dns_record=>{:ttl => 121}})
      expect(@dza.conn.page.code).to eq '204'
    end

    it 'should get after editing' do
      @ns_record.get
      expect(@dza.conn.page.code).to eq '200'
      expect(@dza.conn.page.body.dns_record.ttl).to eq '121'.to_i
      expect(@dza.conn.page.body.dns_record.hostname).to eq "nskw.net"
      expect(@dza.conn.page.body.dns_record.name).to eq '1234'
    end

    it 'should be deleted' do
      @ns_record.delete
      expect(@dza.conn.page.code).to eq '204'
    end
  end

  describe 'A record' do
    before :all do
      @a_record = @dza.dns_zone.create_dns_record(type: "A",
                                                  name: Faker::Internet.domain_name,
                                                  ip: @dza.dns_zone.generate_ipv4)
    end

    it 'should get the record' do
     @a_record.get
      expect(@dza.conn.page.code).to eq '200'
    end

    it 'should be editable(name)' do
      @a_record.edit({:dns_record=>{:name => "test-edit-name"}})
      expect(@dza.conn.page.code).to eq '204'
    end

    it 'should be editable(ip)' do
      @a_record.edit({:dns_record=>{:ip => "35.35.35.35"}})
      expect(@dza.conn.page.code).to eq '204'
    end

    it 'should be editable(ttl)' do
     @a_record.edit({:dns_record=>{:ttl => 8888}})
      expect(@dza.conn.page.code).to eq '204'
    end

    it 'should get record after editing' do
     @a_record.get
      expect(@dza.conn.page.code).to eq '200'
      expect(@dza.conn.page.body.dns_record.name).to eq "test-edit-name"
      expect(@dza.conn.page.body.dns_record.ip).to eq "35.35.35.35"
      expect(@dza.conn.page.body.dns_record.ttl).to eq 8888
    end

    it 'should be deleted' do
      @a_record.delete
      expect(@dza.conn.page.code).to eq '204'
    end
  end

  describe 'AAAA record' do
    before :all do
      @aaaa_record = @dza.dns_zone.create_dns_record(type: "AAAA",
                                                     name: Faker::Internet.domain_name,
                                                     ip: @dza.dns_zone.generate_ipv6)
    end

    it 'should get the record' do
      @aaaa_record.get
      expect(@dza.conn.page.code).to eq '200'
    end

    it 'should be editable(name)' do
     @aaaa_record.edit({:dns_record=>{:name => "aaaa-test"}})
      expect(@dza.conn.page.code).to eq '204'
    end

    it 'should be editable(ip)' do
      @aaaa_record.edit({:dns_record=>{:ip => "2001:0DB8:AA10:0001:0000:0000:0000:00FB"}})
      expect(@dza.conn.page.code).to eq '204'
    end

    it 'should be editable(ttl)' do
      @aaaa_record.edit({:dns_record=>{:ttl => 12311}})
      expect(@dza.conn.page.code).to eq '204'
    end

    it 'should get record after editing' do
      @aaaa_record.get
      expect(@dza.conn.page.code).to eq '200'
      expect(@dza.conn.page.body.dns_record.name).to eq "aaaa-test"
      expect(@dza.conn.page.body.dns_record.ip).to eq "2001:0DB8:AA10:0001:0000:0000:0000:00FB"
      expect(@dza.conn.page.body.dns_record.ttl).to eq 12311
    end

    it 'should be deleted' do
      @aaaa_record.delete
      expect(@dza.conn.page.code).to eq '204'
    end
  end

  describe 'CNAME record' do
    before :all do
      @cname_record = @dza.dns_zone.create_dns_record(type: "CNAME",
                                                      hostname: Faker::Internet.domain_name)
    end

    it 'should get the record' do
      @cname_record.get
      expect(@dza.conn.page.code).to eq '200'
    end

    it 'should be editable(name)' do
     @cname_record.edit({:dns_record=>{:name => "cname"}})
      expect(@dza.conn.page.code).to eq '204'
    end

    it 'should be editable(hostname)' do
      @cname_record.edit({:dns_record=>{:hostname => "cname.hostname.com"}})
      expect(@dza.conn.page.code).to eq '204'
    end

    it 'should be editable(ttl)' do
      @cname_record.edit({:dns_record=>{:ttl => 18822}})
      expect(@dza.conn.page.code).to eq '204'
    end

    it 'should get record after editing' do
      @cname_record.get
      expect(@dza.conn.page.code).to eq '200'
      expect(@dza.conn.page.body.dns_record.name).to eq "cname"
      expect(@dza.conn.page.body.dns_record.hostname).to eq "cname.hostname.com"
      expect(@dza.conn.page.body.dns_record.ttl).to eq 18822
    end

    it 'should be deleted' do
      @cname_record.delete
      expect(@dza.conn.page.code).to eq '204'
    end
  end

  describe 'MX record' do
    before :all do
      @mx_record = @dza.dns_zone.create_dns_record(type: "MX",
                                                   hostname: Faker::Internet.domain_name,
                                                   priority: @dza.dns_zone.generate_number)
    end

    it 'should get the record' do
      @mx_record.get
      expect(@dza.conn.page.code).to eq '200'
    end

    it 'should be editable(priority)' do
      @mx_record.edit({:dns_record=>{:priority => 12}})
      expect(@dza.conn.page.code).to eq '204'
    end

    it 'should be editable(name)' do
      @mx_record.edit({:dns_record=>{:name => "mx-name"}})
      expect(@dza.conn.page.code).to eq '204'
    end

    it 'should be editable(hostname)' do
      @mx_record.edit({:dns_record=>{:hostname => "mx-name.hostname.com"}})
      expect(@dza.conn.page.code).to eq '204'
    end

    it 'should be editable(ttl)' do
      @mx_record.edit({:dns_record=>{:ttl => 98632}})
      expect(@dza.conn.page.code).to eq '204'
    end

    it 'should get record after editing' do
      @mx_record.get
      expect(@dza.conn.page.code).to eq '200'
      expect(@dza.conn.page.body.dns_record.priority).to eq 12
      expect(@dza.conn.page.body.dns_record.name).to eq "mx-name"
      expect(@dza.conn.page.body.dns_record.hostname).to eq "mx-name.hostname.com"
      expect(@dza.conn.page.body.dns_record.ttl).to eq 98632
    end

    it 'should be deleted' do
      @mx_record.delete
      expect(@dza.conn.page.code).to eq '204'
    end
  end

  describe 'TXT record' do
    before :all do
      @txt_record = @dza.dns_zone.create_dns_record(type: "TXT",
                                                    txt: "#{SecureRandom.hex}.#{SecureRandom.hex}")
    end

    it 'should get the record' do
     @txt_record.get
      expect(@dza.conn.page.code).to eq '200'
    end

    it 'should be editable(name)' do
     @txt_record.edit({:dns_record=>{:name => "txt"}})
      expect(@dza.conn.page.code).to eq '204'
    end

    it 'should be editable(txt)' do
      @txt_record.edit({:dns_record=>{:txt => "tets-txt description"}})
      expect(@dza.conn.page.code).to eq '204'
    end

    it 'should be editable(ttl)' do
      @txt_record.edit({:dns_record=>{:ttl => 3241}})
      expect(@dza.conn.page.code).to eq '204'
    end

    it 'should get record after editing' do
      @txt_record.get
      expect(@dza.conn.page.code).to eq '200'
      expect(@dza.conn.page.body.dns_record.name).to eq "txt"
      expect(@dza.conn.page.body.dns_record.txt).to eq "tets-txt description"
      expect(@dza.conn.page.body.dns_record.ttl).to eq 3241
    end

    it 'should be deleted' do
    @txt_record.delete
    expect(@dza.conn.page.code).to eq '204'
    end
  end

  describe 'SRV record' do
    before :all do
      @srv_record = @dza.dns_zone.create_dns_record(type: "SRV",
                                                    name: "_sip._tcp",
                                                    hostname: "#{SecureRandom.hex}.hostname.com",
                                                    priority: @dza.dns_zone.generate_number,
                                                    weight: @dza.dns_zone.generate_number,
                                                    port: @dza.dns_zone.generate_number )
    end

    it 'should get the record' do
      @srv_record.get
      expect(@dza.conn.page.code).to eq '200'
    end

    it 'should be editable(name)' do
      @srv_record.edit(:dns_record=>{:name => "_foobar._tcp"})
      expect(@dza.conn.page.code).to eq '204'
    end

    it 'should be editable(priority)' do
      @srv_record.edit({:dns_record=>{:priority => 8}})
      expect(@dza.conn.page.code).to eq '204'
    end

    it 'should be editable(weight)' do
      @srv_record.edit({:dns_record=>{:weight => 3}})
      expect(@dza.conn.page.code).to eq '204'
    end

    it 'should be editable(port)' do
      @srv_record.edit({:dns_record=>{:port => 9}})
      expect(@dza.conn.page.code).to eq '204'
    end

    it 'should be editable(hostname)' do
      @srv_record.edit({:dns_record=>{:hostname => "hostname.srv.com"}})
      expect(@dza.conn.page.code).to eq '204'
    end

    it 'should be editable(ttl)' do
      @srv_record.edit({:dns_record=>{:ttl => 12}})
      expect(@dza.conn.page.code).to eq '204'
    end

    it 'should get record after editing' do
      @srv_record.get
      expect(@dza.conn.page.code).to eq '200'
      expect(@dza.conn.page.body.dns_record.name).to eq "_foobar._tcp"
      expect(@dza.conn.page.body.dns_record.priority).to eq 8
      expect(@dza.conn.page.body.dns_record.weight).to eq 3
      expect(@dza.conn.page.body.dns_record.port).to eq 9
      expect(@dza.conn.page.body.dns_record.hostname).to eq "hostname.srv.com"
      expect(@dza.conn.page.body.dns_record.ttl).to eq 12
    end

    it 'should be deleted' do
      @srv_record.delete
      expect(@dza.conn.page.code).to eq '204'
    end
  end

  context 'DNS zone' do
    it 'should be removed' do
      dns_zone.remove_dns_zone
      expect(@dza.conn.page.code).to eq '204'
    end
  end
end

describe 'Negative tests' do
  context 'NS record' do
    before(:all) do
      @dza = DnsZoneActions.new.precondition
    end

    after(:all) do
      @dza.dns_zone.remove_dns_zone
    end

    let(:dns_zone) { @dza.dns_zone }

    it 'should be created' do
      expect(dns_zone.name).not_to be nil
    end

    it 'should not be created with incorrect name(empty)' do
      @dza.dns_zone.create_dns_record(name: "",
                                      type: "NS",
                                      hostname: Faker::Internet.domain_name)
      expect(@dza.conn.page.code).to eq '422'
      expect(@dza.conn.page.body.errors.name).to eq ["Domain Name has incorrect format"]
    end

    it 'should not be created with incorrect name(specific symbols)' do
      @dza.dns_zone.create_dns_record(name: "(*&^%$",
                                      type: "NS",
                                      hostname: Faker::Internet.domain_name)
      expect(@dza.conn.page.code).to eq '422'
      expect(@dza.conn.page.body.errors.name).to eq ["Domain Name has incorrect format"]
    end

    it 'should not be created with incorrect name(the @ symbol only)' do
      @dza.dns_zone.create_dns_record(name: "@",
                                      type: "NS",
                                      hostname: Faker::Internet.domain_name)
      expect(@dza.conn.page.code).to eq '422'
      # don't know why we are getting nil
      expect(@dza.conn.page.body.errors.base).to eq ["NS record for root domain must not be manually created"]
    end

    it 'should not be created with incorrect ttl(less)' do
      @dza.dns_zone.create_dns_record(ttl: Faker::Number.negative.to_i,
                                      type: "NS",
                                      hostname: Faker::Internet.domain_name)
      expect(@dza.conn.page.code).to eq '422'
      expect(@dza.conn.page.body.errors.ttl).to eq ["must be greater than or equal to 0"]
    end

    it 'should not be created with incorrect ttl(more)' do
      big_ttl = Faker::Number.number(11)
      @dza.dns_zone.create_dns_record(ttl: big_ttl,
                                      type: "NS",
                                      hostname: Faker::Internet.domain_name)
      expect(@dza.conn.page.code).to eq '422'
      expect(@dza.conn.page.body.errors.ttl).to eq ["must be less than 2147483648"]
    end

    it 'should not be created with incorrect ttl(text)' do
      @dza.dns_zone.create_dns_record(ttl: Faker::Internet.domain_name,
                                      type: "NS",
                                      hostname: Faker::Internet.domain_name)
      expect(@dza.conn.page.code).to eq '422'
      expect(@dza.conn.page.body.errors.ttl).to eq ["is not a number"]
    end

    it 'should not be created with incorrect ttl(empty)' do
      @dza.dns_zone.create_dns_record(ttl: " ",
                                      type: "NS",
                                      hostname: Faker::Internet.domain_name)
      expect(@dza.conn.page.code).to eq '422'
      expect(@dza.conn.page.body.errors.ttl).to eq ["can't be blank", "is not a number"]
    end

    it 'should not be created with incorrect hostname' do
      @dza.dns_zone.create_dns_record(hostname: Faker::Internet.domain_word,
                                      type: "NS")
      expect(@dza.conn.page.code).to eq '422'
      expect(@dza.conn.page.body.errors.hostname[0]).to eq "Domain Name has incorrect format"
      expect(@dza.conn.page.body.errors.hostname[1]).to eq "Name can not be a top level domain"
    end

    it 'should not be created with incorrect hostname(empty)' do
      @dza.dns_zone.create_dns_record(hostname: " ",
                                      type: "NS")
      expect(@dza.conn.page.code).to eq '422'
      expect(@dza.conn.page.body.errors.hostname).to eq ["can't be blank"]
    end
  end

  context 'A record' do
    before(:all) do
      @dza = DnsZoneActions.new.precondition
    end

    after(:all) do
      @dza.dns_zone.remove_dns_zone
    end

    let(:dns_zone) { @dza.dns_zone }

    it 'should be created' do
      expect(dns_zone.name).not_to be nil
    end

    it 'should not be created with incorrect name(empty)' do
      @dza.dns_zone.create_dns_record(name: " ",
                                      type: "A",
                                      ip: @dza.dns_zone.generate_ipv4)
      expect(@dza.conn.page.code).to eq '422'
      expect(@dza.conn.page.body.errors.name.first).to eq "Domain Name has incorrect format"
    end

    it 'should not be created with incorrect name(specific symbols)' do
      @dza.dns_zone.create_dns_record(name: "(*&^%$",
                                      type: "A",
                                      ip: @dza.dns_zone.generate_ipv4)
      expect(@dza.conn.page.code).to eq '422'
      expect(@dza.conn.page.body.errors.name).to eq ["Domain Name has incorrect format"]
    end

    it 'should not be created with incorrect ttl(less)' do
      @dza.dns_zone.create_dns_record(ttl: Faker::Number.negative.to_i,
                                      type: "A",
                                      name: Faker::Internet.domain_name,
                                      ip: @dza.dns_zone.generate_ipv4)
      expect(@dza.conn.page.code).to eq '422'
      expect(@dza.conn.page.body.errors.ttl).to eq ["must be greater than or equal to 0"]
    end

    it 'should not be created with incorrect ttl(more)' do
      big_ttl = Faker::Number.number(11)
      @dza.dns_zone.create_dns_record(ttl: big_ttl,
                                      type: "A",
                                      name: Faker::Internet.domain_name,
                                      ip: @dza.dns_zone.generate_ipv4)
      expect(@dza.conn.page.code).to eq '422'
      expect(@dza.conn.page.body.errors.ttl).to eq ["must be less than 2147483648"]
    end

    it 'should not be created with incorrect ttl(text)' do
      @dza.dns_zone.create_dns_record(ttl: "#{SecureRandom.hex}",
                                      type: "A",
                                      name: Faker::Internet.domain_name,
                                      ip: @dza.dns_zone.generate_ipv4)
      expect(@dza.conn.page.code).to eq '422'
      expect(@dza.conn.page.body.errors.ttl).to eq ["is not a number"]
    end

    it 'should not be created with incorrect ttl(empty)' do
      @dza.dns_zone.create_dns_record(ttl: " ",
                                      type: "A",
                                      name: Faker::Internet.domain_name,
                                      ip: @dza.dns_zone.generate_ipv4)
      expect(@dza.conn.page.code).to eq '422'
      expect(@dza.conn.page.body.errors.ttl).to eq ["can't be blank", "is not a number"]
    end

    it 'should not be created new dns record type A with incorrect ip' do
      @dza.dns_zone.create_dns_record(ip: "256.1.1.1",
                                      name: Faker::Internet.domain_name,
                                      type: "A")
      expect(@dza.conn.page.code).to eq '422'
      expect(@dza.conn.page.body.errors.ip).to eq ["is invalid IPv4 address"]
    end

    it 'should not be created new dns record type A with incorrect ip(empty)' do
      @dza.dns_zone.create_dns_record(ip: " ",
                                      name: Faker::Internet.domain_name,
                                      type: "A")
      expect(@dza.conn.page.code).to eq '422'
      expect(@dza.conn.page.body.errors.ip).to eq ["can't be blank", "is invalid IPv4 address"]
    end
  end

  context 'AAAA record' do
    before(:all) do
      @dza = DnsZoneActions.new.precondition
    end

    after(:all) do
      @dza.dns_zone.remove_dns_zone
    end

    let(:dns_zone) { @dza.dns_zone }

    it 'should be created' do
      expect(dns_zone.name).not_to be nil
    end

    it 'should not be created new dns record type AAAA with incorrect name(empty)' do
      @dza.dns_zone.create_dns_record(name: " ",
                                      type: "AAAA",
                                      ip: @dza.dns_zone.generate_ipv6)
      expect(@dza.conn.page.code).to eq '422'
      expect(@dza.conn.page.body.errors.name.first).to eq "Domain Name has incorrect format"
    end

    it 'should not be created new dns record type AAAA with incorrect name(specific symbols)' do
      @dza.dns_zone.create_dns_record(name: "(*&^%$",
                                      type: "AAAA",
                                      ip: @dza.dns_zone.generate_ipv6)
      expect(@dza.conn.page.code).to eq '422'
      expect(@dza.conn.page.body.errors.name).to eq ["Domain Name has incorrect format"]
    end

    it 'should not be created new dns record type AAAA with incorrect ttl(less)' do
      @dza.dns_zone.create_dns_record(ttl: Faker::Number.negative.to_i,
                                      type: "AAAA",
                                      name: Faker::Internet.domain_name,
                                      ip: @dza.dns_zone.generate_ipv6)
      expect(@dza.conn.page.code).to eq '422'
      expect(@dza.conn.page.body.errors.ttl).to eq ["must be greater than or equal to 0"]
    end

    it 'should not be created new dns record type AAAA with incorrect ttl(more)' do
      big_ttl = Faker::Number.number(11)
      @dza.dns_zone.create_dns_record(ttl: big_ttl,
                                      type: "AAAA",
                                      name: Faker::Internet.domain_name,
                                      ip: @dza.dns_zone.generate_ipv6)
      expect(@dza.conn.page.code).to eq '422'
      expect(@dza.conn.page.body.errors.ttl).to eq ["must be less than 2147483648"]
    end

    it 'should not be created new dns record type AAAA with incorrect ttl(text)' do
      @dza.dns_zone.create_dns_record(ttl: "#{SecureRandom.hex}",
                                      type: "AAAA",
                                      name: Faker::Internet.domain_name,
                                      ip: @dza.dns_zone.generate_ipv6)
      expect(@dza.conn.page.code).to eq '422'
      expect(@dza.conn.page.body.errors.ttl).to eq ["is not a number"]
    end

    it 'should not be created new dns record type AAAA with incorrect ttl(empty)' do
      @dza.dns_zone.create_dns_record(ttl: " ",
                                      type: "AAAA",
                                      name: Faker::Internet.domain_name,
                                      ip: @dza.dns_zone.generate_ipv6 )
      expect(@dza.conn.page.code).to eq '422'
      expect(@dza.conn.page.body.errors.ttl).to eq ["can't be blank", "is not a number"]
    end

    it 'should not be created new dns record type AAAA with incorrect ip' do
      @dza.dns_zone.create_dns_record(ip: "0:0:0:0:0:0",
                                      type: "AAAA",
                                      name: Faker::Internet.domain_name)
      expect(@dza.conn.page.code).to eq '422'
      expect(@dza.conn.page.body.errors.ip).to eq ["is invalid IPv6 address"]
    end

    it 'should not be created new dns record type AAAA with incorrect ip' do
      @dza.dns_zone.create_dns_record(ip: " ",
                                      type: "AAAA",
                                      name: Faker::Internet.domain_name)
      expect(@dza.conn.page.code).to eq '422'
      expect(@dza.conn.page.body.errors.ip).to eq ["can't be blank", "is invalid IPv6 address"]
    end
  end

  context 'CNAME record' do
    before(:all) do
      @dza = DnsZoneActions.new.precondition
    end

    after(:all) do
      @dza.dns_zone.remove_dns_zone
    end

    let(:dns_zone) { @dza.dns_zone }

    it 'should be created' do
      expect(dns_zone.name).not_to be nil
    end

    it 'should not be created new dns record type CNAME with incorrect name(empty)' do
      @dza.dns_zone.create_dns_record(name: " ",
                                      type: "CNAME",
                                      hostname: Faker::Internet.domain_name)
      expect(@dza.conn.page.code).to eq '422'
      expect(@dza.conn.page.body.errors.name.first).to eq "Domain Name has incorrect format"
    end

    it 'should not be created new dns record type CNAME with incorrect name(specific symbols)' do
      @dza.dns_zone.create_dns_record(name: "(*&^%$",
                                      type: "CNAME",
                                      hostname: Faker::Internet.domain_name)
      expect(@dza.conn.page.code).to eq '422'
      expect(@dza.conn.page.body.errors.name).to eq ["Domain Name has incorrect format"]
    end

    it 'should not be created new dns record type CNAME with incorrect hostname(empty)' do
      @dza.dns_zone.create_dns_record(hostname: " ",
                                      type: "CNAME")
      expect(@dza.conn.page.code).to eq '422'
      expect(@dza.conn.page.body.errors.hostname.first).to eq "can't be blank"
    end

    it 'should not be created new dns record type CNAME with incorrect hostname(specific symbols)' do
      @dza.dns_zone.create_dns_record(hostname: "(*&^%$",
                                      type: "CNAME")
      expect(@dza.conn.page.code).to eq '422'
      expect(@dza.conn.page.body.errors.hostname.first).to eq "Domain Name has incorrect format"
    end

    it 'should not be created new dns record type CNAME with incorrect ttl(less)' do
      @dza.dns_zone.create_dns_record(ttl: Faker::Number.negative.to_i,
                                      type: "CNAME",
                                      hostname: Faker::Internet.domain_name)
      expect(@dza.conn.page.code).to eq '422'
      expect(@dza.conn.page.body.errors.ttl).to eq ["must be greater than or equal to 0"]
    end

    it 'should not be created new dns record type CNAME with incorrect ttl(more)' do
      big_ttl = Faker::Number.number(11)
      @dza.dns_zone.create_dns_record(ttl: big_ttl,
                                      type: "CNAME",
                                      hostname: Faker::Internet.domain_name)
      expect(@dza.conn.page.code).to eq '422'
      expect(@dza.conn.page.body.errors.ttl).to eq ["must be less than 2147483648"]
    end

    it 'should not be created new dns record type CNAME with incorrect ttl(text)' do
      @dza.dns_zone.create_dns_record(ttl: "#{SecureRandom.hex}",
                                      type: "CNAME",
                                      hostname: Faker::Internet.domain_name)
      expect(@dza.conn.page.code).to eq '422'
      expect(@dza.conn.page.body.errors.ttl).to eq ["is not a number"]
    end

    it 'should not be created new dns record type CNAME with incorrect ttl(empty)' do
      @dza.dns_zone.create_dns_record(ttl: " ",
                                      type: "CNAME",
                                      hostname: Faker::Internet.domain_name)
      expect(@dza.conn.page.code).to eq '422'
      expect(@dza.conn.page.body.errors.ttl).to eq ["can't be blank", "is not a number"]
    end
  end

  context 'MX record' do
    before(:all) do
      @dza = DnsZoneActions.new.precondition
    end

    after(:all) do
      @dza.dns_zone.remove_dns_zone
    end

    let(:dns_zone) { @dza.dns_zone }

    it 'should be created' do
      expect(dns_zone.name).not_to be nil
    end

    it 'should not be created new dns record type MX with incorrect name(empty)' do
      @dza.dns_zone.create_dns_record(name: " ",
                                      type: "MX",
                                      hostname: Faker::Internet.domain_name,
                                      priority: @dza.dns_zone.generate_number)
      expect(@dza.conn.page.code).to eq '422'
      expect(@dza.conn.page.body.errors.name.first).to eq "Domain Name has incorrect format"
    end

    it 'should not be created new dns record type MX with incorrect name(specific symbols)' do
      @dza.dns_zone.create_dns_record(name: "(*&^%$",
                                      type: "MX",
                                      hostname: Faker::Internet.domain_name,
                                      priority: @dza.dns_zone.generate_number)
      expect(@dza.conn.page.code).to eq '422'
      expect(@dza.conn.page.body.errors.name).to eq ["Domain Name has incorrect format"]
    end

    it 'should not be created new dns record type MX with incorrect hostname(empty)' do
      @dza.dns_zone.create_dns_record(hostname: " ",
                                      type: "MX",
                                      priority: @dza.dns_zone.generate_number)
      expect(@dza.conn.page.code).to eq '422'
      expect(@dza.conn.page.body.errors.hostname.first).to eq "can't be blank"
    end

    it 'should not be created new dns record type MX with incorrect hostname(specific symbols)' do
      @dza.dns_zone.create_dns_record(hostname: "(*&^%$",
                                      type: "MX",
                                      priority: @dza.dns_zone.generate_number)
      expect(@dza.conn.page.code).to eq '422'
      expect(@dza.conn.page.body.errors.hostname.first).to eq "Domain Name has incorrect format"
    end

    it 'should not be created new dns record type MX with incorrect ttl(less)' do
      @dza.dns_zone.create_dns_record(ttl: Faker::Number.negative.to_i,
                                      type: "MX",
                                      hostname:Faker::Internet.domain_name,
                                      priority: @dza.dns_zone.generate_number)
      expect(@dza.conn.page.code).to eq '422'
      expect(@dza.conn.page.body.errors.ttl).to eq ["must be greater than or equal to 0"]
    end

    it 'should not be created new dns record type MX with incorrect ttl(more)' do
      big_ttl = Faker::Number.number(11)
      @dza.dns_zone.create_dns_record(ttl: big_ttl,
                                      type: "MX",
                                      hostname: Faker::Internet.domain_name,
                                      priority: @dza.dns_zone.generate_number)
      expect(@dza.conn.page.code).to eq '422'
      expect(@dza.conn.page.body.errors.ttl).to eq ["must be less than 2147483648"]
    end

    it 'should not be created new dns record type MX with incorrect ttl(text)' do
      @dza.dns_zone.create_dns_record(ttl: "#{SecureRandom.hex}",
                                      type: "MX",
                                      hostname: Faker::Internet.domain_name,
                                      priority: @dza.dns_zone.generate_number)
      expect(@dza.conn.page.code).to eq '422'
      expect(@dza.conn.page.body.errors.ttl).to eq ["is not a number"]
    end

    it 'should not be created new dns record type MX with incorrect ttl(empty)' do
      @dza.dns_zone.create_dns_record(ttl: "",
                                      type: "MX",
                                      hostname: Faker::Internet.domain_name,
                                      priority: @dza.dns_zone.generate_number)
      expect(@dza.conn.page.code).to eq '422'
      expect(@dza.conn.page.body.errors.ttl).to eq ["can't be blank", "is not a number"]
    end

    it 'should not be created new dns record type MX with incorrect priority(less)' do
      @dza.dns_zone.create_dns_record(priority: "-3",
                                      type: "MX",
                                      hostname: Faker::Internet.domain_name)
      expect(@dza.conn.page.code).to eq '422'
      expect(@dza.conn.page.body.errors.priority).to eq ["must be greater than or equal to 0"]
    end

    it 'should not be created new dns record type MX with incorrect priority(text)' do
      @dza.dns_zone.create_dns_record(priority: "#{SecureRandom.hex}",
                                      type: "MX",
                                      hostname: Faker::Internet.domain_name)
      expect(@dza.conn.page.code).to eq '422'
      expect(@dza.conn.page.body.errors.priority).to eq ["is not a number"]
    end

    it 'should not be created new dns record type MX with incorrect priority(empty)' do
      @dza.dns_zone.create_dns_record(priority: " ",
                                      type: "MX",
                                      hostname: Faker::Internet.domain_name)
      expect(@dza.conn.page.code).to eq '422'
      expect(@dza.conn.page.body.errors.priority).to eq ["is not a number"]
    end
  end

  context 'TXT record' do
    before(:all) do
      @dza = DnsZoneActions.new.precondition
    end

    after(:all) do
      @dza.dns_zone.remove_dns_zone
    end

    let(:dns_zone) { @dza.dns_zone }

    it 'should be created' do
      expect(dns_zone.name).not_to be nil
    end

    it 'should not be created new dns record type TXT with incorrect name(empty)' do
      @dza.dns_zone.create_dns_record(name: " ",
                                      type: "TXT",
                                      txt: "#{SecureRandom.hex}.#{SecureRandom.hex}")
      expect(@dza.conn.page.code).to eq '422'
      expect(@dza.conn.page.body.errors.name.first).to eq "Domain Name has incorrect format"
    end

    it 'should not be created new dns record type TXT with incorrect name(specific symbols)' do
      @dza.dns_zone.create_dns_record(name: "(*&^%$",
                                      type: "TXT",
                                      txt: "#{SecureRandom.hex}.#{SecureRandom.hex}")
      expect(@dza.conn.page.code).to eq '422'
      expect(@dza.conn.page.body.errors.name).to eq ["Domain Name has incorrect format"]
    end

    it 'should not be created new dns record type TXT with incorrect ttl(less)' do
      @dza.dns_zone.create_dns_record(ttl: Faker::Number.negative.to_i,
                                      type: "TXT",
                                      txt: "#{SecureRandom.hex}.#{SecureRandom.hex}")
      expect(@dza.conn.page.code).to eq '422'
      expect(@dza.conn.page.body.errors.ttl).to eq ["must be greater than or equal to 0"]
    end

    it 'should not be created new dns record type TXT with incorrect ttl(more)' do
      big_ttl = Faker::Number.number(11)
      @dza.dns_zone.create_dns_record(ttl: big_ttl,
                                      type: "TXT",
                                      txt: "#{SecureRandom.hex}.#{SecureRandom.hex}")
      expect(@dza.conn.page.code).to eq '422'
      expect(@dza.conn.page.body.errors.ttl).to eq ["must be less than 2147483648"]
    end

    it 'should not be created new dns record type TXT with incorrect ttl(text)' do
      @dza.dns_zone.create_dns_record(ttl: "#{SecureRandom.hex}",
                                      type: "TXT",
                                      txt: "#{SecureRandom.hex}.#{SecureRandom.hex}")
      expect(@dza.conn.page.code).to eq '422'
      expect(@dza.conn.page.body.errors.ttl).to eq ["is not a number"]
    end

    it 'should not be created new dns record type TXT with incorrect ttl(empty)' do
      @dza.dns_zone.create_dns_record(ttl: "",
                                      type: "TXT",
                                      txt: "#{SecureRandom.hex}.#{SecureRandom.hex}")
      expect(@dza.conn.page.code).to eq '422'
      expect(@dza.conn.page.body.errors.ttl).to eq ["can't be blank", "is not a number"]
    end
  end

  context 'SRV record' do
    #ticket?   @body={"errors"=>{"base"=>["Invalid SRV record name format '_<service>._<protocol>.<host>'"]}}
    before(:all) do
      @dza = DnsZoneActions.new.precondition
    end

    after(:all) do
      @dza.dns_zone.remove_dns_zone
    end

    let(:dns_zone) { @dza.dns_zone }

    it 'should be created' do
      expect(dns_zone.name).not_to be nil
    end

    it 'should not be created new dns record type SRV with incorrect name(empty)' do
      @dza.dns_zone.create_dns_record(name: " ",
                                      type: "SRV",
                                      hostname: "#{Faker::Internet.domain_word}.hostname.com",
                                      priority: @dza.dns_zone.generate_number,
                                      weight: @dza.dns_zone.generate_number,
                                      port:@dza.dns_zone.generate_number)
      expect(@dza.conn.page.code).to eq '422'
      expect(@dza.conn.page.body.errors.base).to eq ["Invalid SRV record name format '_<service>._<protocol>.<host>'"]
    end

    it 'should not be created new dns record type SRV with incorrect name(specific symbols)' do
      @dza.dns_zone.create_dns_record(name: "(*&^%$",
                                      type: "SRV",
                                      hostname: "#{Faker::Internet.domain_word}.hostname.com",
                                      priority: @dza.dns_zone.generate_number,
                                      weight: @dza.dns_zone.generate_number,
                                      port:@dza.dns_zone.generate_number)
      expect(@dza.conn.page.code).to eq '422'
      expect(@dza.conn.page.body.errors.base).to eq  ["Invalid SRV record name format '_<service>._<protocol>.<host>'"]
    end

    it 'should not be created new dns record type SRV with incorrect hostname(empty)' do
      @dza.dns_zone.create_dns_record(hostname: " ",
                                      type: "SRV",
                                      name: "_sip._tcp",
                                      priority: @dza.dns_zone.generate_number,
                                      weight: @dza.dns_zone.generate_number,
                                      port:@dza.dns_zone.generate_number)
      expect(@dza.conn.page.code).to eq '422'
      expect(@dza.conn.page.body.errors.hostname.first).to eq "can't be blank"
    end

    it 'should not be created new dns record type SRV with incorrect hostname(specific symbols)' do
      @dza.dns_zone.create_dns_record(hostname: "(*&^%$",
                                      type: "SRV",
                                      name: "_sip._tcp",
                                      priority: @dza.dns_zone.generate_number,
                                      weight: @dza.dns_zone.generate_number,
                                      port:@dza.dns_zone.generate_number)
      expect(@dza.conn.page.code).to eq '422'
      expect(@dza.conn.page.body.errors.hostname.first).to eq "Domain Name has incorrect format"
    end

    it 'should not be created new dns record type SRV with incorrect ttl(less)' do
      @dza.dns_zone.create_dns_record(ttl: Faker::Number.negative.to_i,
                                      type: "SRV",
                                      name: "_sip._tcp",
                                      hostname: "#{Faker::Internet.domain_word}.hostname.com",
                                      priority: @dza.dns_zone.generate_number,
                                      weight: @dza.dns_zone.generate_number,
                                      port:@dza.dns_zone.generate_number)
      expect(@dza.conn.page.code).to eq '422'
      expect(@dza.conn.page.body.errors.ttl).to eq ["must be greater than or equal to 0"]
    end

    it 'should not be created new dns record type SRV with incorrect ttl(more)' do
      big_ttl = Faker::Number.number(11)
      @dza.dns_zone.create_dns_record(ttl: big_ttl,
                                      type: "SRV",
                                      name: "_sip._tcp",
                                      hostname: "#{Faker::Internet.domain_word}.hostname.com",
                                      priority: @dza.dns_zone.generate_number,
                                      weight: @dza.dns_zone.generate_number,
                                      port:@dza.dns_zone.generate_number)
      expect(@dza.conn.page.code).to eq '422'
      expect(@dza.conn.page.body.errors.ttl).to eq ["must be less than 2147483648"]
    end

    it 'should not be created new dns record type SRV with incorrect ttl(text)' do
      @dza.dns_zone.create_dns_record(ttl: "#{SecureRandom.hex}",
                                      type: "SRV",
                                      name: "_sip._tcp",
                                      hostname: "#{SecureRandom.hex}.hostname.com",
                                      priority: @dza.dns_zone.generate_number,
                                      weight: @dza.dns_zone.generate_number,
                                      port:@dza.dns_zone.generate_number)
      expect(@dza.conn.page.code).to eq '422'
      expect(@dza.conn.page.body.errors.ttl).to eq ["is not a number"]
    end

    it 'should not be created new dns record type SRV with incorrect ttl(empty)' do
      @dza.dns_zone.create_dns_record(ttl: "",
                                      type: "SRV",
                                      name: "_sip._tcp",
                                      hostname: "#{Faker::Internet.domain_word}.hostname.com",
                                      priority: @dza.dns_zone.generate_number,
                                      weight: @dza.dns_zone.generate_number,
                                      port:@dza.dns_zone.generate_number)
      expect(@dza.conn.page.code).to eq '422'
      expect(@dza.conn.page.body.errors.ttl).to eq ["can't be blank", "is not a number"]
    end

    it 'should not be created new dns record type SRV with incorrect priority(less)' do
      @dza.dns_zone.create_dns_record(priority: "-3",
                                      type: "SRV",
                                      name: "_sip._tcp",
                                      hostname: "#{Faker::Internet.domain_word}.hostname.com",
                                      weight: @dza.dns_zone.generate_number,
                                      port:@dza.dns_zone.generate_number)
      expect(@dza.conn.page.code).to eq '422'
      expect(@dza.conn.page.body.errors.priority).to eq ["must be greater than or equal to 0"]
    end

    it 'should not be created new dns record type SRV with incorrect priority(text)' do
      @dza.dns_zone.create_dns_record(priority: "#{SecureRandom.hex}",
                                      type: "SRV",
                                      name: "_sip._tcp",
                                      hostname: "#{Faker::Internet.domain_word}.hostname.com",
                                      weight: @dza.dns_zone.generate_number,
                                      port:@dza.dns_zone.generate_number)
      expect(@dza.conn.page.code).to eq '422'
      expect(@dza.conn.page.body.errors.priority).to eq ["is not a number"]
    end

    it 'should not be created new dns record type SRV with incorrect priority(empty)' do
      @dza.dns_zone.create_dns_record(priority: " ",
                                      type: "SRV",
                                      name: "_sip._tcp",
                                      hostname: "#{Faker::Internet.domain_word}.hostname.com",
                                      weight: @dza.dns_zone.generate_number,
                                      port:@dza.dns_zone.generate_number)
      expect(@dza.conn.page.code).to eq '422'
      expect(@dza.conn.page.body.errors.priority).to eq ["can't be blank", "is not a number"]
    end

    it 'should not be created new dns record type SRV with incorrect weight(less)' do
      @dza.dns_zone.create_dns_record(weight: "-3",
                                      type: "SRV",
                                      name: "_sip._tcp",
                                      hostname: "#{Faker::Internet.domain_word}.hostname.com",
                                      priority: @dza.dns_zone.generate_number,
                                      port:@dza.dns_zone.generate_number)
      expect(@dza.conn.page.code).to eq '422'
      expect(@dza.conn.page.body.errors.weight).to eq ["must be greater than or equal to 0"]
    end

    it 'should not be created new dns record type SRV with incorrect weight(more)' do
      @dza.dns_zone.create_dns_record(weight: "65536",
                                      type: "SRV",
                                      name: "_sip._tcp",
                                      hostname: "#{Faker::Internet.domain_word}.hostname.com",
                                      priority: @dza.dns_zone.generate_number,
                                      port:@dza.dns_zone.generate_number)
      expect(@dza.conn.page.code).to eq '422'
      expect(@dza.conn.page.body.errors.weight).to eq ["must be less than or equal to 65535"]
    end

    it 'should not be created new dns record type SRV with incorrect weight(text)' do
      @dza.dns_zone.create_dns_record(weight: "#{SecureRandom.hex}",
                                      type: "SRV",
                                      name: "_sip._tcp",
                                      hostname: "#{Faker::Internet.domain_word}.hostname.com",
                                      priority: @dza.dns_zone.generate_number,
                                      port:@dza.dns_zone.generate_number)
      expect(@dza.conn.page.code).to eq '422'
      expect(@dza.conn.page.body.errors.weight).to eq ["is not a number"]
    end

    it 'should not be created new dns record type SRV with incorrect weight(empty)' do
      @dza.dns_zone.create_dns_record(weight: "",
                                      type: "SRV",
                                      name: "_sip._tcp",
                                      hostname: "#{Faker::Internet.domain_word}.hostname.com",
                                      priority: @dza.dns_zone.generate_number,
                                      port: @dza.dns_zone.generate_number)
      expect(@dza.conn.page.code).to eq '422'
      expect(@dza.conn.page.body.errors.weight).to eq ["can't be blank", "is not a number"]
    end

    it 'should not be created new dns record type SRV with incorrect port(less)' do
      @dza.dns_zone.create_dns_record(port: "-3",
                                      type: "SRV",
                                      name: "_sip._tcp",
                                      hostname: "#{Faker::Internet.domain_word}.hostname.com",
                                      priority: @dza.dns_zone.generate_number,
                                      weight: @dza.dns_zone.generate_number)
      expect(@dza.conn.page.code).to eq '422'
      expect(@dza.conn.page.body.errors.port).to eq ["must be greater than or equal to 0"]
    end

    it 'should not be created new dns record type SRV with incorrect port(more)' do
      @dza.dns_zone.create_dns_record(port: "65536",
                                      type: "SRV",
                                      name: "_sip._tcp",
                                      hostname: "#{Faker::Internet.domain_word}.hostname.com",
                                      priority: @dza.dns_zone.generate_number,
                                      weight: @dza.dns_zone.generate_number)
      expect(@dza.conn.page.code).to eq '422'
      expect(@dza.conn.page.body.errors.port).to eq ["must be less than or equal to 65535"]
    end

    it 'should not be created new dns record type SRV with incorrect port(text)' do
      @dza.dns_zone.create_dns_record(port: "#{SecureRandom.hex}",
                                      type: "SRV",
                                      name: "_sip._tcp",
                                      hostname: "#{Faker::Internet.domain_word}.hostname.com",
                                      priority: @dza.dns_zone.generate_number,
                                      weight: @dza.dns_zone.generate_number)
      expect(@dza.conn.page.code).to eq '422'
      expect(@dza.conn.page.body.errors.port).to eq ["is not a number"]
    end

    it 'should not be created new dns record type SRV with incorrect port(empty)' do
      @dza.dns_zone.create_dns_record(port: " ",
                                      type: "SRV",
                                      name: "_sip._tcp",
                                      hostname: "#{Faker::Internet.domain_word}.hostname.com",
                                      priority: @dza.dns_zone.generate_number,
                                      weight: @dza.dns_zone.generate_number)
      expect(@dza.conn.page.code).to eq '422'
      expect(@dza.conn.page.body.errors.port).to eq ["can't be blank", "is not a number"]
    end
  end

  context 'wrong name for dns zone' do
    before(:all) do
      @dza = DnsZoneActions.new.precondition
    end

    after(:all) do
      @dza.dns_zone.remove_dns_zone
    end

    let(:dns_zone) { @dza.dns_zone }

    it 'should be created' do
      expect(dns_zone.name).not_to be nil
    end

    it 'dns_zone should not be added with empty name' do
      dns_zone.create_dns_zone(name: "")
      expect(@dza.conn.page.code).to eq '422'
      expect(@dza.conn.page.body.errors.name.first).to eq "can't be blank"
    end

    it 'dns_zone should not be added with incorrect(digit) name' do
      skip("https://onappdev.atlassian.net/browse/CORE-7341")
      dns_zone.create_dns_zone(name: "#{SecureRandom.random_number(11)}")
      expect(@dza.conn.page.code).to eq '422'
      # expect(@dns_zone_a.conn.page.body.errors.name).to eq ["is invalid domain name"]
    end

    it 'dns_zone should not be added with incorrect(character) name' do
      dns_zone.create_dns_zone(name: "#{SecureRandom.hex}")
      expect(@dza.conn.page.code).to eq '422'
      # expect(@dns_zone_a.conn.page.body.errors.name).to eq ["is invalid domain name"]
    end

    it 'should not be created with reserver domain name(for example google.com)' do
      dns_zone.create_dns_zone(name: 'google.com')
      expect(@dza.conn.page.code).to eq '422'
      expect(@dza.conn.page.body.errors.name.first).to eq 'DNS zone name must not be a reserved domain'
    end
  end
end

describe 'rDNS zone' do
  before(:all) do
    @dza = DnsZoneActions.new.precondition
    @dza.dns_zone.remove_dns_zone
  end
  let(:dns_zone) { @dza.dns_zone }

  it 'should be created' do
    expect(dns_zone.name).not_to be nil
  end

  context 'IPv4' do
    context 'create (237.168.69.in-addr.arpa)' do
      it 'should be created' do
        dns_zone.create_dns_zone(name: '237.168.69.in-addr.arpa')
        expect(@dza.conn.page.code).to eq '201'
        expect(dns_zone.name).to eq '237.168.69.in-addr.arpa'
      end

      it 'should be removed' do
        dns_zone.remove_dns_zone
        expect(@dza.conn.page.code).to eq '204'
      end

      it 'make sure rDNS zone is removed' do
        @dza.get(dns_zone.route_dns_zone)
        expect(@dza.conn.page.code).to eq '404'
      end
    end

    context 'create (160-30.237.168.72.in-addr.arpa)' do
      it 'should be created' do
        dns_zone.create_dns_zone(name: '160-30.237.168.72.in-addr.arpa')
        expect(@dza.conn.page.code).to eq '201'
        expect(dns_zone.name).to eq '160-30.237.168.72.in-addr.arpa'
      end

      it 'should be removed' do
        dns_zone.remove_dns_zone
        expect(@dza.conn.page.code).to eq '204'
      end

      it 'make sure rDNS zone is removed' do
        @dza.get(dns_zone.route_dns_zone)
        expect(@dza.conn.page.code).to eq '404'
      end
    end

    context 'create PTR record(digit only)' do
      before(:all) do
        @dza.dns_zone.create_dns_zone(name: '237.168.72.in-addr.arpa')
        @ptr_record = @dza.dns_zone.create_dns_record(name: '123',
                                                      hostname: '72-168-237-123.it.works.ua',
                                                      type: 'PTR',
                                                      ttl: 123)
      end

      it 'GET' do
        @ptr_record.get
        expect(@dza.conn.page.code).to eq '200'
        expect(@dza.conn.page.body.dns_record.name).to eq '123'
        expect(@dza.conn.page.body.dns_record.hostname).to eq '72-168-237-123.it.works.ua'
        expect(@dza.conn.page.body.dns_record.ttl).to eq 123
        expect(@dza.conn.page.body.dns_record.type).to eq 'PTR'
      end

      it 'DELETE' do
        @ptr_record.delete
        expect(@dza.conn.page.code).to eq '204'
      end

      it 'rDNS should be removed' do
        dns_zone.remove_dns_zone
        expect(@dza.conn.page.code).to eq '204'
      end

      it 'make sure rDNS zone is removed' do
        @dza.get(dns_zone.route_dns_zone)
        expect(@dza.conn.page.code).to eq '404'
      end
    end

    context 'create PTR record(chars only)' do
      before(:all) do
        @dza.dns_zone.create_dns_zone(name: '237.168.72.in-addr.arpa')
        @ptr_record = @dza.dns_zone.create_dns_record(name: 'abc',
                                                      hostname: '72-168-237-abc.it.works.ua',
                                                      type: 'PTR',
                                                      ttl: 123)
      end

      it 'GET' do
        @ptr_record.get
        expect(@dza.conn.page.code).to eq '200'
        expect(@dza.conn.page.body.dns_record.name).to eq 'abc'
        expect(@dza.conn.page.body.dns_record.hostname).to eq '72-168-237-abc.it.works.ua'
        expect(@dza.conn.page.body.dns_record.ttl).to eq 123
        expect(@dza.conn.page.body.dns_record.type).to eq 'PTR'
      end

      it 'DELETE' do
        @ptr_record.delete
        expect(@dza.conn.page.code).to eq '204'
      end

      it 'rDNS should be removed' do
        dns_zone.remove_dns_zone
        expect(@dza.conn.page.code).to eq '204'
      end

      it 'make sure rDNS zone is removed' do
        @dza.get(dns_zone.route_dns_zone)
        expect(@dza.conn.page.code).to eq '404'
      end
    end

    context 'edit PTR record' do
      before(:all) do
        @dza.dns_zone.create_dns_zone(name: '237.168.72.in-addr.arpa')
        @ptr_record = @dza.dns_zone.create_dns_record(name: '123',
                                                      hostname: '72-168-237-123.it.works.ua',
                                                      type: 'PTR',
                                                      ttl: 123)
      end

      it 'GET' do
        @ptr_record.get
        expect(@dza.conn.page.code).to eq '200'
        expect(@dza.conn.page.body.dns_record.name).to eq '123'
        expect(@dza.conn.page.body.dns_record.hostname).to eq '72-168-237-123.it.works.ua'
        expect(@dza.conn.page.body.dns_record.ttl).to eq 123
        expect(@dza.conn.page.body.dns_record.type).to eq 'PTR'
      end

      it 'EDIT name' do
        @ptr_record.edit({:dns_record=>{:name => '223'}})
        expect(@dza.conn.page.code).to eq '204'
      end

      it 'EDIT hostname' do
        @ptr_record.edit({:dns_record=>{:hostname => '72-168-237-223.it.works.ua'}})
        expect(@dza.conn.page.code).to eq '204'
      end

      it 'EDIT ttl' do
        @ptr_record.edit({:dns_record=>{:ttl => '223'}})
        expect(@dza.conn.page.code).to eq '204'
      end

      it 'make sure the record is edited' do
        @ptr_record.get
        expect(@dza.conn.page.code).to eq '200'
        expect(@dza.conn.page.body.dns_record.name).to eq '223'
        expect(@dza.conn.page.body.dns_record.hostname).to eq '72-168-237-223.it.works.ua'
        expect(@dza.conn.page.body.dns_record.ttl).to eq 223
        expect(@dza.conn.page.body.dns_record.type).to eq 'PTR'
      end

      it 'DELETE' do
        @ptr_record.delete
        expect(@dza.conn.page.code).to eq '204'
      end

      it 'rDNS should be removed' do
        dns_zone.remove_dns_zone
        expect(@dza.conn.page.code).to eq '204'
      end

      it 'make sure rDNS zone is removed' do
        @dza.get(dns_zone.route_dns_zone)
        expect(@dza.conn.page.code).to eq '404'
      end
    end

    context 'create CNAME record(digit)' do
      before(:all) do
        @dza.dns_zone.create_dns_zone(name: '237.168.72.in-addr.arpa')
        @cname_record = @dza.dns_zone.create_dns_record(name: '123',
                                                      hostname: 'ad-test-digit.it.works.ua',
                                                      type: 'CNAME',
                                                      ttl: 123)
      end

      it 'GET' do
        @cname_record.get
        expect(@dza.conn.page.code).to eq '200'
        expect(@dza.conn.page.body.dns_record.name).to eq '123'
        expect(@dza.conn.page.body.dns_record.hostname).to eq 'ad-test-digit.it.works.ua'
        expect(@dza.conn.page.body.dns_record.ttl).to eq 123
        expect(@dza.conn.page.body.dns_record.type).to eq 'CNAME'
      end

      it 'DELETE' do
        @cname_record.delete
        expect(@dza.conn.page.code).to eq '204'
      end

      it 'rDNS should be removed' do
        dns_zone.remove_dns_zone
        expect(@dza.conn.page.code).to eq '204'
      end

      it 'make sure rDNS zone is removed' do
        @dza.get(dns_zone.route_dns_zone)
        expect(@dza.conn.page.code).to eq '404'
      end
    end

    context 'create CNAME record(chars)' do
      before(:all) do
        @dza.dns_zone.create_dns_zone(name: '237.168.72.in-addr.arpa')
        @cname_record = @dza.dns_zone.create_dns_record(name: 'abc',
                                                        hostname: 'ad-test-chars.it.works.ua',
                                                        type: 'CNAME',
                                                        ttl: 123)
      end

      it 'GET' do
        @cname_record.get
        expect(@dza.conn.page.code).to eq '200'
        expect(@dza.conn.page.body.dns_record.name).to eq 'abc'
        expect(@dza.conn.page.body.dns_record.hostname).to eq 'ad-test-chars.it.works.ua'
        expect(@dza.conn.page.body.dns_record.ttl).to eq 123
        expect(@dza.conn.page.body.dns_record.type).to eq 'CNAME'
      end

      it 'DELETE' do
        @cname_record.delete
        expect(@dza.conn.page.code).to eq '204'
      end

      it 'rDNS should be removed' do
        dns_zone.remove_dns_zone
        expect(@dza.conn.page.code).to eq '204'
      end

      it 'make sure rDNS zone is removed' do
        @dza.get(dns_zone.route_dns_zone)
        expect(@dza.conn.page.code).to eq '404'
      end
    end

    context 'create CNAME record(176.170-78)' do
      before(:all) do
        @dza.dns_zone.create_dns_zone(name: '237.168.72.in-addr.arpa')
        @cname_record = @dza.dns_zone.create_dns_record(name: '176.170-78',
                                                        hostname: 'ad-test-176.170-78.it.works.ua',
                                                        type: 'CNAME',
                                                        ttl: 123)
      end

      it 'GET' do
        @cname_record.get
        expect(@dza.conn.page.code).to eq '200'
        expect(@dza.conn.page.body.dns_record.name).to eq '176.170-78'
        expect(@dza.conn.page.body.dns_record.hostname).to eq 'ad-test-176.170-78.it.works.ua'
        expect(@dza.conn.page.body.dns_record.ttl).to eq 123
        expect(@dza.conn.page.body.dns_record.type).to eq 'CNAME'
      end

      it 'DELETE' do
        @cname_record.delete
        expect(@dza.conn.page.code).to eq '204'
      end

      it 'rDNS should be removed' do
        dns_zone.remove_dns_zone
        expect(@dza.conn.page.code).to eq '204'
      end

      it 'make sure rDNS zone is removed' do
        @dza.get(dns_zone.route_dns_zone)
        expect(@dza.conn.page.code).to eq '404'
      end
    end

    context 'edit CNAME record' do
      before(:all) do
        @dza.dns_zone.create_dns_zone(name: '237.168.72.in-addr.arpa')
        @cname_record = @dza.dns_zone.create_dns_record(name: '123',
                                                        hostname: 'ad-test-digit.it.works.ua',
                                                        type: 'CNAME',
                                                        ttl: 123)
      end

      it 'GET' do
        @cname_record.get
        expect(@dza.conn.page.code).to eq '200'
        expect(@dza.conn.page.body.dns_record.name).to eq '123'
        expect(@dza.conn.page.body.dns_record.hostname).to eq 'ad-test-digit.it.works.ua'
        expect(@dza.conn.page.body.dns_record.ttl).to eq 123
        expect(@dza.conn.page.body.dns_record.type).to eq 'CNAME'
      end

      it 'EDIT name' do
        @cname_record.edit({:dns_record=>{:name => '223'}})
        expect(@dza.conn.page.code).to eq '204'
      end

      it 'EDIT hostname' do
        @cname_record.edit({:dns_record=>{:hostname => 'ad-test-edited.it.works.ua'}})
        expect(@dza.conn.page.code).to eq '204'
      end

      it 'EDIT ttl' do
        @cname_record.edit({:dns_record=>{:ttl => '223'}})
        expect(@dza.conn.page.code).to eq '204'
      end

      it 'make sure the record is edited' do
        @cname_record.get
        expect(@dza.conn.page.code).to eq '200'
        expect(@dza.conn.page.body.dns_record.name).to eq '223'
        expect(@dza.conn.page.body.dns_record.hostname).to eq 'ad-test-edited.it.works.ua'
        expect(@dza.conn.page.body.dns_record.ttl).to eq 223
        expect(@dza.conn.page.body.dns_record.type).to eq 'CNAME'
      end

      it 'DELETE' do
        @cname_record.delete
        expect(@dza.conn.page.code).to eq '204'
      end

      it 'rDNS should be removed' do
        dns_zone.remove_dns_zone
        expect(@dza.conn.page.code).to eq '204'
      end

      it 'make sure rDNS zone is removed' do
        @dza.get(dns_zone.route_dns_zone)
        expect(@dza.conn.page.code).to eq '404'
      end
    end

    context 'create NS record(digit)' do
      before(:all) do
        @dza.dns_zone.create_dns_zone(name: '237.168.72.in-addr.arpa')
        sleep 3
        @ns_record = @dza.dns_zone.create_dns_record(type: 'NS',
                                                     name: '123',
                                                     hostname: 'ns8.ad-test-digit.com',
                                                     ttl: 133)
      end

      it 'GET' do
        @ns_record.get
        expect(@dza.conn.page.code).to eq '200'
        expect(@dza.conn.page.body.dns_record.name).to eq '123'
        expect(@dza.conn.page.body.dns_record.hostname).to eq 'ns8.ad-test-digit.com'
        expect(@dza.conn.page.body.dns_record.ttl).to eq 133
        expect(@dza.conn.page.body.dns_record.type).to eq 'NS'
      end

      it 'DELETE' do
        @ns_record.delete
        expect(@dza.conn.page.code).to eq '204'
      end

      it 'rDNS should be removed' do
        dns_zone.remove_dns_zone
        expect(@dza.conn.page.code).to eq '204'
      end

      it 'make sure rDNS zone is removed' do
        @dza.get(dns_zone.route_dns_zone)
        expect(@dza.conn.page.code).to eq '404'
      end
    end

    context 'create NS record(chars)' do
      before(:all) do
      @dza.dns_zone.create_dns_zone(name: '237.168.72.in-addr.arpa')
      sleep 3
      @ns_record = @dza.dns_zone.create_dns_record(type: 'NS',
                                                   name: 'abc',
                                                   hostname: 'ns8.ad-test-chars.com',
                                                   ttl: 133)
      end

      it 'GET' do
        @ns_record.get
        expect(@dza.conn.page.code).to eq '200'
        expect(@dza.conn.page.body.dns_record.name).to eq 'abc'
        expect(@dza.conn.page.body.dns_record.hostname).to eq 'ns8.ad-test-chars.com'
        expect(@dza.conn.page.body.dns_record.ttl).to eq 133
        expect(@dza.conn.page.body.dns_record.type).to eq 'NS'
      end

      it 'DELETE' do
        @ns_record.delete
        expect(@dza.conn.page.code).to eq '204'
      end

      it 'rDNS should be removed' do
        dns_zone.remove_dns_zone
        expect(@dza.conn.page.code).to eq '204'
      end

      it 'make sure rDNS zone is removed' do
        @dza.get(dns_zone.route_dns_zone)
        expect(@dza.conn.page.code).to eq '404'
      end
    end

    context 'edit NS record' do
      before(:all) do
        @dza.dns_zone.create_dns_zone(name: '237.168.72.in-addr.arpa')
        sleep 3
        @ns_record = @dza.dns_zone.create_dns_record(type: 'NS',
                                                     name: '123',
                                                     hostname: 'ns8.ad-test-digit.com',
                                                     ttl: 133)
      end

      it 'GET' do
        @ns_record.get
        expect(@dza.conn.page.code).to eq '200'
        expect(@dza.conn.page.body.dns_record.name).to eq '123'
        expect(@dza.conn.page.body.dns_record.hostname).to eq 'ns8.ad-test-digit.com'
        expect(@dza.conn.page.body.dns_record.ttl).to eq 133
        expect(@dza.conn.page.body.dns_record.type).to eq 'NS'
      end

      it 'EDIT name' do
        @ns_record.edit({:dns_record=>{:name => '223'}})
        expect(@dza.conn.page.code).to eq '204'
      end

      it 'EDIT hostname' do
        @ns_record.edit({:dns_record=>{:hostname => 'ns8.ad-test-edited.ua'}})
        expect(@dza.conn.page.code).to eq '204'
      end

      it 'EDIT ttl' do
        @ns_record.edit({:dns_record=>{:ttl => '223'}})
        expect(@dza.conn.page.code).to eq '204'
      end

      it 'make sure the record is edited' do
        @ns_record.get
        expect(@dza.conn.page.code).to eq '200'
        expect(@dza.conn.page.body.dns_record.name).to eq '223'
        expect(@dza.conn.page.body.dns_record.hostname).to eq 'ns8.ad-test-edited.ua'
        expect(@dza.conn.page.body.dns_record.ttl).to eq 223
        expect(@dza.conn.page.body.dns_record.type).to eq 'NS'
      end

      it 'DELETE' do
        @ns_record.delete
        expect(@dza.conn.page.code).to eq '204'
      end

      it 'rDNS should be removed' do
        dns_zone.remove_dns_zone
        expect(@dza.conn.page.code).to eq '204'
      end

      it 'make sure rDNS zone is removed' do
        @dza.get(dns_zone.route_dns_zone)
        expect(@dza.conn.page.code).to eq '404'
      end
    end

    context 'negative' do
      it 'should not be created rDNS with invalid name(abc.xyz.test.in-addr.arpa)' do
        dns_zone.create_dns_zone(name: 'abc.xyz.test.in-addr.arpa')
        expect(@dza.conn.page.code).to eq '422'
        expect(@dza.conn.page.body.errors.name).to eq ["rDNS zone name contain invalid format of IP"]
      end

      it 'should not be created rDNS with invalid range(72.94.in-addr.arpa)' do
        dns_zone.create_dns_zone(name: '72.94.in-addr.arpa')
        expect(@dza.conn.page.code).to eq '422'
        expect(@dza.conn.page.body.errors.name).to eq ["DNS zone name must be in valid hostname format"]
      end

      context 'same domain' do
        before(:all) do
          @dz_1 = @dza.dns_zone.create_dns_zone(name: '237.168.69.in-addr.arpa')
        end
        let(:dns_zone_1) { @dza.dns_zone }

        it 'first rDNS should be created' do
          expect(dns_zone_1.name).not_to be nil
        end

        it 'should not be created second the same rDNS' do
          dns_zone.create_dns_zone(name: '237.168.69.in-addr.arpa')
          expect(@dza.conn.page.code).to eq '422'
          expect(@dza.conn.page.body.errors.name).to eq ["domain has already been taken. Please contact support to verify the ownership"]
        end

        it 'should be removed' do
          dns_zone_1.remove_dns_zone
          expect(@dza.conn.page.code).to eq '204'
        end

        it 'make sure rDNS zone is removed' do
          @dza.get(dns_zone_1.route_dns_zone)
          expect(@dza.conn.page.code).to eq '404'
        end
      end

      context 'same record name(ip)' do
        before(:all) do
          @dza.dns_zone.create_dns_zone(name: '237.168.72.in-addr.arpa')
          @ptr_record_1 = @dza.dns_zone.create_dns_record(name: '123',
                                                        hostname: '72-168-237-123.it.works.ua',
                                                        type: 'PTR',
                                                        ttl: 123)
        end
        it 'GET first record' do
          @ptr_record_1.get
          expect(@dza.conn.page.code).to eq '200'
        end

        it 'should not be created the second record' do
          @dza.dns_zone.create_dns_record(name: '123',
                                          hostname: 'test-record.it.works.ua',
                                          type: 'PTR',
                                          ttl: 123)
          expect(@dza.conn.page.code).to eq '422'
          expect(@dza.conn.page.body.errors.base).to eq ["There is a duplicate record that is having the same name"]
        end

        it 'DELETE' do
          @ptr_record_1.delete
          expect(@dza.conn.page.code).to eq '204'
        end

        it 'rDNS should be removed' do
          dns_zone.remove_dns_zone
          expect(@dza.conn.page.code).to eq '204'
        end

        it 'make sure rDNS zone is removed' do
          @dza.get(dns_zone.route_dns_zone)
          expect(@dza.conn.page.code).to eq '404'
        end
      end
    end
  end

  context 'IPv6' do
    context 'create' do
      it 'should be created' do
        dns_zone.create_dns_zone(name: '0.0.0.0.0.0.0.0.8.b.d.0.1.0.0.8.ip6.arpa')
        expect(@dza.conn.page.code).to eq '201'
        expect(dns_zone.name).to eq '0.0.0.0.0.0.0.0.8.b.d.0.1.0.0.8.ip6.arpa'
      end

      it 'should be removed' do
        dns_zone.remove_dns_zone
        expect(@dza.conn.page.code).to eq '204'
      end

      it 'make sure rDNS zone is removed' do
        @dza.get(dns_zone.route_dns_zone)
        expect(@dza.conn.page.code).to eq '404'
      end
    end

    context 'create PRT record(digit)' do
      before(:all) do
        @dza.dns_zone.create_dns_zone(name: '0.0.0.0.0.0.0.0.8.b.d.0.1.0.0.8.ip6.arpa')
        @ptr_record = @dza.dns_zone.create_dns_record(name: 'b.a.9.8.7.6.5.0.0.0.0.0.0.0.0.0',
                                                      hostname: 'ipv6-ptr-digit-it-works-edit.com',
                                                      type: 'PTR',
                                                      ttl: 123)
      end

      it 'GET' do
        @ptr_record.get
        expect(@dza.conn.page.code).to eq '200'
        expect(@dza.conn.page.body.dns_record.name).to eq 'b.a.9.8.7.6.5.0.0.0.0.0.0.0.0.0'
        expect(@dza.conn.page.body.dns_record.hostname).to eq 'ipv6-ptr-digit-it-works-edit.com'
        expect(@dza.conn.page.body.dns_record.ttl).to eq 123
        expect(@dza.conn.page.body.dns_record.type).to eq 'PTR'
      end

      it 'DELETE' do
        @ptr_record.delete
        expect(@dza.conn.page.code).to eq '204'
      end

      it 'rDNS should be removed' do
        dns_zone.remove_dns_zone
        expect(@dza.conn.page.code).to eq '204'
      end

      it 'make sure rDNS zone is removed' do
        @dza.get(dns_zone.route_dns_zone)
        expect(@dza.conn.page.code).to eq '404'
      end
    end

    context 'create PRT record(chars)' do
      before(:all) do
        @dza.dns_zone.create_dns_zone(name: '0.0.0.0.0.0.0.0.8.b.d.0.1.0.0.8.ip6.arpa')
        @ptr_record = @dza.dns_zone.create_dns_record(name: 'abc',
                                                      hostname: 'ipv6-ptr-chars-it-works-edit.com',
                                                      type: 'PTR',
                                                      ttl: 123)
      end

      it 'GET' do
        @ptr_record.get
        expect(@dza.conn.page.code).to eq '200'
        expect(@dza.conn.page.body.dns_record.name).to eq 'abc'
        expect(@dza.conn.page.body.dns_record.hostname).to eq 'ipv6-ptr-chars-it-works-edit.com'
        expect(@dza.conn.page.body.dns_record.ttl).to eq 123
        expect(@dza.conn.page.body.dns_record.type).to eq 'PTR'
      end

      it 'DELETE' do
        @ptr_record.delete
        expect(@dza.conn.page.code).to eq '204'
      end

      it 'rDNS should be removed' do
        dns_zone.remove_dns_zone
        expect(@dza.conn.page.code).to eq '204'
      end

      it 'make sure rDNS zone is removed' do
        @dza.get(dns_zone.route_dns_zone)
        expect(@dza.conn.page.code).to eq '404'
      end
    end

    context 'edit PTR' do
      before(:all) do
        @dza.dns_zone.create_dns_zone(name: '0.0.0.0.0.0.0.0.8.b.d.0.1.0.0.8.ip6.arpa')
        @ptr_record = @dza.dns_zone.create_dns_record(name: 'b.a.9.8.7.6.5.0.0.0.0.0.0.0.0.0',
                                                      hostname: 'ipv6-ptr-digit-it-works-edit.com',
                                                      type: 'PTR',
                                                      ttl: 123)
      end

      it 'GET' do
        @ptr_record.get
        expect(@dza.conn.page.code).to eq '200'
        expect(@dza.conn.page.body.dns_record.name).to eq 'b.a.9.8.7.6.5.0.0.0.0.0.0.0.0.0'
        expect(@dza.conn.page.body.dns_record.hostname).to eq 'ipv6-ptr-digit-it-works-edit.com'
        expect(@dza.conn.page.body.dns_record.ttl).to eq 123
        expect(@dza.conn.page.body.dns_record.type).to eq 'PTR'
      end

      it 'EDIT name' do
        @ptr_record.edit({:dns_record=>{:name => 'b.a.9.9.9.6.5.0.0.0.0.0.0.0.0.0'}})
        expect(@dza.conn.page.code).to eq '204'
      end

      it 'EDIT hostname' do
        @ptr_record.edit({:dns_record=>{:hostname => 'ipv6-ptr-digit-edit-it-works-edit.com'}})
        expect(@dza.conn.page.code).to eq '204'
      end

      it 'EDIT ttl' do
        @ptr_record.edit({:dns_record=>{:ttl => '9600'}})
        expect(@dza.conn.page.code).to eq '204'
      end

      it 'make sure the record is edited' do
        @ptr_record.get
        expect(@dza.conn.page.code).to eq '200'
        expect(@dza.conn.page.body.dns_record.name).to eq 'b.a.9.9.9.6.5.0.0.0.0.0.0.0.0.0'
        expect(@dza.conn.page.body.dns_record.hostname).to eq 'ipv6-ptr-digit-edit-it-works-edit.com'
        expect(@dza.conn.page.body.dns_record.ttl).to eq 9600
        expect(@dza.conn.page.body.dns_record.type).to eq 'PTR'
      end

      it 'DELETE' do
        @ptr_record.delete
        expect(@dza.conn.page.code).to eq '204'
      end

      it 'rDNS should be removed' do
        dns_zone.remove_dns_zone
        expect(@dza.conn.page.code).to eq '204'
      end

      it 'make sure rDNS zone is removed' do
        @dza.get(dns_zone.route_dns_zone)
        expect(@dza.conn.page.code).to eq '404'
      end
    end

    context 'create CNAME record(digit)' do
      before(:all) do
        @dza.dns_zone.create_dns_zone(name: '0.0.0.0.0.0.0.0.8.b.d.0.1.0.0.8.ip6.arpa')
        @cname_record = @dza.dns_zone.create_dns_record(name: 'b.a.9.8.7.6.5.0.0.0.0.0.0.0.0.0',
                                                        hostname: 'ipv6-cname-digit-it-works-edit.com',
                                                        type: 'CNAME',
                                                        ttl: 123)
      end

      it 'GET' do
        @cname_record.get
        expect(@dza.conn.page.code).to eq '200'
        expect(@dza.conn.page.body.dns_record.name).to eq 'b.a.9.8.7.6.5.0.0.0.0.0.0.0.0.0'
        expect(@dza.conn.page.body.dns_record.hostname).to eq 'ipv6-cname-digit-it-works-edit.com'
        expect(@dza.conn.page.body.dns_record.ttl).to eq 123
        expect(@dza.conn.page.body.dns_record.type).to eq 'CNAME'
      end

      it 'DELETE' do
        @cname_record.delete
        expect(@dza.conn.page.code).to eq '204'
      end

      it 'rDNS should be removed' do
        dns_zone.remove_dns_zone
        expect(@dza.conn.page.code).to eq '204'
      end

      it 'make sure rDNS zone is removed' do
        @dza.get(dns_zone.route_dns_zone)
        expect(@dza.conn.page.code).to eq '404'
      end
    end

    context 'create CNAME record(chars)' do
      before(:all) do
        @dza.dns_zone.create_dns_zone(name: '0.0.0.0.0.0.0.0.8.b.d.0.1.0.0.8.ip6.arpa')
        @cname_record = @dza.dns_zone.create_dns_record(name: 'abc',
                                                        hostname: 'ipv6-cname-chars-it-works-edit.com',
                                                        type: 'CNAME',
                                                        ttl: 123)
      end

      it 'GET' do
        @cname_record.get
        expect(@dza.conn.page.code).to eq '200'
        expect(@dza.conn.page.body.dns_record.name).to eq 'abc'
        expect(@dza.conn.page.body.dns_record.hostname).to eq 'ipv6-cname-chars-it-works-edit.com'
        expect(@dza.conn.page.body.dns_record.ttl).to eq 123
        expect(@dza.conn.page.body.dns_record.type).to eq 'CNAME'
      end

      it 'DELETE' do
        @cname_record.delete
        expect(@dza.conn.page.code).to eq '204'
      end

      it 'rDNS should be removed' do
        dns_zone.remove_dns_zone
        expect(@dza.conn.page.code).to eq '204'
      end

      it 'make sure rDNS zone is removed' do
        @dza.get(dns_zone.route_dns_zone)
        expect(@dza.conn.page.code).to eq '404'
      end
    end

    context 'edit CNAME' do
      before(:all) do
        @dza.dns_zone.create_dns_zone(name: '0.0.0.0.0.0.0.0.8.b.d.0.1.0.0.8.ip6.arpa')
        @cname_record = @dza.dns_zone.create_dns_record(name: 'b.a.9.8.7.6.5.0.0.0.0.0.0.0.0.0',
                                                      hostname: 'ipv6-cname-it-works-edit.com',
                                                      type: 'CNAME',
                                                      ttl: 123)
      end

      it 'GET' do
        @cname_record.get
        expect(@dza.conn.page.code).to eq '200'
        expect(@dza.conn.page.body.dns_record.name).to eq 'b.a.9.8.7.6.5.0.0.0.0.0.0.0.0.0'
        expect(@dza.conn.page.body.dns_record.hostname).to eq 'ipv6-cname-it-works-edit.com'
        expect(@dza.conn.page.body.dns_record.ttl).to eq 123
        expect(@dza.conn.page.body.dns_record.type).to eq 'CNAME'
      end

      it 'EDIT name' do
        @cname_record.edit({:dns_record=>{:name => 'b.a.9.9.9.6.5.0.0.0.0.0.0.0.0.0'}})
        expect(@dza.conn.page.code).to eq '204'
      end

      it 'EDIT hostname' do
        @cname_record.edit({:dns_record=>{:hostname => 'ipv6-cname-edit-it-works-edit.com'}})
        expect(@dza.conn.page.code).to eq '204'
      end

      it 'EDIT ttl' do
        @cname_record.edit({:dns_record=>{:ttl => '9600'}})
        expect(@dza.conn.page.code).to eq '204'
      end

      it 'make sure the record is edited' do
        @cname_record.get
        expect(@dza.conn.page.code).to eq '200'
        expect(@dza.conn.page.body.dns_record.name).to eq 'b.a.9.9.9.6.5.0.0.0.0.0.0.0.0.0'
        expect(@dza.conn.page.body.dns_record.hostname).to eq 'ipv6-cname-edit-it-works-edit.com'
        expect(@dza.conn.page.body.dns_record.ttl).to eq 9600
        expect(@dza.conn.page.body.dns_record.type).to eq 'CNAME'
      end

      it 'DELETE' do
        @cname_record.delete
        expect(@dza.conn.page.code).to eq '204'
      end

      it 'rDNS should be removed' do
        dns_zone.remove_dns_zone
        expect(@dza.conn.page.code).to eq '204'
      end

      it 'make sure rDNS zone is removed' do
        @dza.get(dns_zone.route_dns_zone)
        expect(@dza.conn.page.code).to eq '404'
      end
    end

    context 'create NS record(digit)' do
      before(:all) do
        @dza.dns_zone.create_dns_zone(name: '0.0.0.0.0.0.0.0.8.b.d.0.1.0.0.8.ip6.arpa')
        @ns_record = @dza.dns_zone.create_dns_record(name: 'b.b.4.7.5.6.3.0.0.0.0.0.0.0.0.0',
                                                     hostname: 'ns9.rdns-ipv6.pl',
                                                     type: 'NS',
                                                     ttl: 909)
      end

      it 'GET' do
        @ns_record.get
        expect(@dza.conn.page.code).to eq '200'
        expect(@dza.conn.page.body.dns_record.name).to eq 'b.b.4.7.5.6.3.0.0.0.0.0.0.0.0.0'
        expect(@dza.conn.page.body.dns_record.hostname).to eq 'ns9.rdns-ipv6.pl'
        expect(@dza.conn.page.body.dns_record.ttl).to eq 909
        expect(@dza.conn.page.body.dns_record.type).to eq 'NS'
      end

      it 'DELETE' do
        @ns_record.delete
        expect(@dza.conn.page.code).to eq '204'
      end

      it 'rDNS should be removed' do
        dns_zone.remove_dns_zone
        expect(@dza.conn.page.code).to eq '204'
      end

      it 'make sure rDNS zone is removed' do
        @dza.get(dns_zone.route_dns_zone)
        expect(@dza.conn.page.code).to eq '404'
      end
    end

    context 'create NS record(chars)' do
      before(:all) do
        @dza.dns_zone.create_dns_zone(name: '0.0.0.0.0.0.0.0.8.b.d.0.1.0.0.8.ip6.arpa')
        @ns_record = @dza.dns_zone.create_dns_record(name: 'abc',
                                                     hostname: 'ns9.rdns-ipv6.pl',
                                                     type: 'NS',
                                                     ttl: 909)
      end

      it 'GET' do
        @ns_record.get
        expect(@dza.conn.page.code).to eq '200'
        expect(@dza.conn.page.body.dns_record.name).to eq 'abc'
        expect(@dza.conn.page.body.dns_record.hostname).to eq 'ns9.rdns-ipv6.pl'
        expect(@dza.conn.page.body.dns_record.ttl).to eq 909
        expect(@dza.conn.page.body.dns_record.type).to eq 'NS'
      end

      it 'DELETE' do
        @ns_record.delete
        expect(@dza.conn.page.code).to eq '204'
      end

      it 'rDNS should be removed' do
        dns_zone.remove_dns_zone
        expect(@dza.conn.page.code).to eq '204'
      end

      it 'make sure rDNS zone is removed' do
        @dza.get(dns_zone.route_dns_zone)
        expect(@dza.conn.page.code).to eq '404'
      end
    end

    context 'edit NS' do
      before(:all) do
        @dza.dns_zone.create_dns_zone(name: '0.0.0.0.0.0.0.0.8.b.d.0.1.0.0.8.ip6.arpa')
        @ns_record = @dza.dns_zone.create_dns_record(name: 'b.b.4.7.5.6.3.0.0.0.0.0.0.0.0.0',
                                                     hostname: 'ns9.rdns-ipv6.pl',
                                                     type: 'NS',
                                                     ttl: 909)
      end

      it 'GET' do
        @ns_record.get
        expect(@dza.conn.page.code).to eq '200'
        expect(@dza.conn.page.body.dns_record.name).to eq 'b.b.4.7.5.6.3.0.0.0.0.0.0.0.0.0'
        expect(@dza.conn.page.body.dns_record.hostname).to eq 'ns9.rdns-ipv6.pl'
        expect(@dza.conn.page.body.dns_record.ttl).to eq 909
        expect(@dza.conn.page.body.dns_record.type).to eq 'NS'
      end

      it 'EDIT name' do
        @ns_record.edit({:dns_record=>{:name => 'b.b.8.7.3.8.3.0.0.0.0.0.0.0.0.0'}})
        expect(@dza.conn.page.code).to eq '204'
      end

      it 'EDIT hostname' do
        @ns_record.edit({:dns_record=>{:hostname => 'ns9.rdns-ipv6-edit.pl'}})
        expect(@dza.conn.page.code).to eq '204'
      end

      it 'EDIT ttl' do
        @ns_record.edit({:dns_record=>{:ttl => '9604'}})
        expect(@dza.conn.page.code).to eq '204'
      end

      it 'make sure the record is edited' do
        @ns_record.get
        expect(@dza.conn.page.code).to eq '200'
        expect(@dza.conn.page.body.dns_record.name).to eq 'b.b.8.7.3.8.3.0.0.0.0.0.0.0.0.0'
        expect(@dza.conn.page.body.dns_record.hostname).to eq 'ns9.rdns-ipv6-edit.pl'
        expect(@dza.conn.page.body.dns_record.ttl).to eq 9604
        expect(@dza.conn.page.body.dns_record.type).to eq 'NS'
      end

      it 'DELETE' do
        @ns_record.delete
        expect(@dza.conn.page.code).to eq '204'
      end

      it 'rDNS should be removed' do
        dns_zone.remove_dns_zone
        expect(@dza.conn.page.code).to eq '204'
      end

      it 'make sure rDNS zone is removed' do
        @dza.get(dns_zone.route_dns_zone)
        expect(@dza.conn.page.code).to eq '404'
      end
    end

    context 'negative' do

      it 'should not be created rDNS with invalid name(g.3.2.1.a.c.b.d.e.e.f.f.1.c.a.b.ip6.arpa)' do
        dns_zone.create_dns_zone(name: 'g.3.2.1.a.c.b.d.e.e.f.f.1.c.a.b.ip6.arpa')
        expect(@dza.conn.page.code).to eq '422'
      end

      context 'same domain' do
        before(:all) do
          @dz_1 = @dza.dns_zone.create_dns_zone(name: '0.0.0.0.0.0.0.0.8.b.d.0.1.0.0.8.ip6.arpa')
        end
        let(:dns_zone_1) { @dza.dns_zone }

        it 'first rDNS should be created' do
          expect(dns_zone_1.name).not_to be nil
        end

        it 'should not be created second the same rDNS' do
          dns_zone.create_dns_zone(name: '0.0.0.0.0.0.0.0.8.b.d.0.1.0.0.8.ip6.arpa')
          expect(@dza.conn.page.code).to eq '422'
          expect(@dza.conn.page.body.errors.name).to eq ["domain has already been taken. Please contact support to verify the ownership"]
        end

        it 'should be removed' do
          dns_zone_1.remove_dns_zone
          expect(@dza.conn.page.code).to eq '204'
        end

        it 'make sure rDNS zone is removed' do
          @dza.get(dns_zone_1.route_dns_zone)
          expect(@dza.conn.page.code).to eq '404'
        end
      end

      context 'same record name(ip)' do
        before(:all) do
          @dza.dns_zone.create_dns_zone(name: '0.0.0.0.0.0.0.0.8.b.d.0.1.0.0.8.ip6.arpa')
          @ptr_record_1 = @dza.dns_zone.create_dns_record(name: 'b.a.9.8.7.6.5.0.0.0.0.0.0.0.0.0',
                                                          hostname: 'ipv6-ptr-digit-it-works-edit.com',
                                                          type: 'PTR',
                                                          ttl: 123)
        end
        it 'GET first record' do
          @ptr_record_1.get
          expect(@dza.conn.page.code).to eq '200'
        end

        it 'should not be created the second record' do
          @dza.dns_zone.create_dns_record(name: 'b.a.9.8.7.6.5.0.0.0.0.0.0.0.0.0',
                                          hostname: 'ipv6-ptr-digit-it-works-edit.com',
                                          type: 'PTR',
                                          ttl: 123)
          expect(@dza.conn.page.code).to eq '422'
          expect(@dza.conn.page.body.errors.base).to eq ["There is a duplicate record that is having the same name"]
        end

        it 'DELETE' do
          @ptr_record_1.delete
          expect(@dza.conn.page.code).to eq '204'
        end

        it 'rDNS should be removed' do
          dns_zone.remove_dns_zone
          expect(@dza.conn.page.code).to eq '204'
        end

        it 'make sure rDNS zone is removed' do
          @dza.get(dns_zone.route_dns_zone)
          expect(@dza.conn.page.code).to eq '404'
        end
      end
    end
  end
end
