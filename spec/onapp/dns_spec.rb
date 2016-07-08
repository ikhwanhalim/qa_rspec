require 'spec_helper'
require './groups/dns_actions'

describe 'Dns' do
  before(:all) do
    @dnsa = DnsActions.new.precondition
  end

  let(:dns) { @dnsa.dns}

  it 'should be created' do
    expect(dns.name).not_to be nil
  end
end