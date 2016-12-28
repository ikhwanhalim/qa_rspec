require 'spec_helper'
require './groups/cdn_ssl_actions'
require './spec/onapp/cdn/constants_cdn'

describe 'Ssl Cerificate' do

  context 'Create' do
    before(:all) do
      @csa = CdnSslActions.new.precondition
    end

    let (:ssl_cert) {@csa.ssl_cert}

    it 'should be created' do
      expect(ssl_cert.id).not_to be nil
    end

    it 'should be deleted' do
      ssl_cert.remove_ssl_certificate
      expect(@csa.conn.page.code).to eq '204'
    end

    it 'should make sure CDN Edge Group is deleted' do
      @csa.get(ssl_cert.route_ssl_certificate)
      expect(@csa.conn.page.code).to eq '404'
    end
  end

  context 'Edit' do
    before(:all) do
      @csa = CdnSslActions.new.precondition
    end

    let (:ssl_cert) {@csa.ssl_cert}

    it 'should be created' do
      expect(ssl_cert.id).not_to be nil
    end

    it 'should be editable Edge Group' do
      ssl_cert.edit({cdn_ssl_certificate: {name: ConstantsCdn::NAME_SSL_EDIT}})
      expect(@csa.conn.page.code).to eq '204'
    end

    it 'make sure CDN SSL cert is edited' do
      @csa.get(ssl_cert.route_ssl_certificate)
      expect(@csa.conn.page.body.cdn_ssl_certificate.name).to eq ConstantsCdn::NAME_SSL_EDIT
      expect(@csa.conn.page.body.cdn_ssl_certificate.cdn_reference.size).to be > 3
      #TODO expect(@csa.conn.page.body.cdn_ssl_certificate.cdn_reference).not_to be_nil
    end

    it 'should be deleted' do
      ssl_cert.remove_ssl_certificate
      expect(@csa.conn.page.code).to eq '204'
    end

    it 'should make sure CDN Edge Group is deleted' do
      @csa.get(ssl_cert.route_ssl_certificate)
      expect(@csa.conn.page.code).to eq '404'
    end
  end

  context 'Complex' do
    before(:all) do
      @csa = CdnSslActions.new.precondition
    end

    let (:ssl_cert) {@csa.ssl_cert}

    it 'should be created' do
      expect(ssl_cert.id).not_to be nil
    end

    it 'should be editable Edge Group' do
      ssl_cert.edit({cdn_ssl_certificate: {name: ConstantsCdn::NAME_SSL_EDIT}})
      expect(@csa.conn.page.code).to eq '204'
    end

    it 'make sure CDN SSL cert is edited' do
      @csa.get(ssl_cert.route_ssl_certificate)
      expect(@csa.conn.page.body.cdn_ssl_certificate.name).to eq ConstantsCdn::NAME_SSL_EDIT
      expect(@csa.conn.page.body.cdn_ssl_certificate.cdn_reference.size).to be > 3
      #TODO expect(@csa.conn.page.body.cdn_ssl_certificate.cdn_reference).not_to be_nil
    end

    it 'should get list of SSL certificates' do
      @csa.get(ssl_cert.route_ssl_certificates)
      expect(@csa.conn.page.code).to eq '200'
      expect(@csa.conn.page.body.count).to be >= 1
    end

    it 'should be deleted' do
      ssl_cert.remove_ssl_certificate
      expect(@csa.conn.page.code).to eq '204'
    end

    it 'should make sure CDN Edge Group is deleted' do
      @csa.get(ssl_cert.route_ssl_certificate)
      expect(@csa.conn.page.code).to eq '404'
    end
  end

  context 'negative tests' do
    before(:all) do
      @csa = CdnSslActions.new.precondition
    end

    let (:ssl_cert) {@csa.ssl_cert}

    it 'should not be created with empty name' do
      skip("https://onappdev.atlassian.net/browse/CORE-8586")
      ssl_cert.create_ssl_certificate({name: ''})
    end

    it 'should not be created with name[special characters]' do
      skip("https://onappdev.atlassian.net/browse/CORE-8586")
    end

    it 'should not be created with name > 255' do
      ssl_cert.create_ssl_certificate({name: ConstantsCdn::NAME_255_SSL })
      expect(@csa.conn.page.body.errors.name.first).to eq 'is too long (maximum is 255 characters)'
    end

    it 'should not be created with all params are empty' do
      # https://onappdev.atlassian.net/browse/CORE-8589, should be "can't be blank"
      ssl_cert.create_ssl_certificate({name:'', cert: '', key: ''})
      expect(@csa.conn.page.body.errors.cert.first).to eq 'is invalid'
      expect(@csa.conn.page.body.errors.to_a[1][1].first).to eq 'is invalid'
    end

    it 'should not be created with wrong format[key, cert]' do
      ssl_cert.create_ssl_certificate({name:'', cert: 'asdasd', key: 'asdqwe'})
      expect(@csa.conn.page.body.errors.base.first).to eq 'An error occurred managing the resource remotely, please try again later. cert must not be malformed'
      end

    it 'should not be created with wrong format[key]' do
      ssl_cert.create_ssl_certificate({name:'', cert: ConstantsCdn::SSL_CERT, key: 'asdqwe'})
      expect(@csa.conn.page.body.errors.base.first).to eq 'An error occurred managing the resource remotely, please try again later. SSL private key must pkcs8 compatible'
      end

    it 'should not be created with wrong format[cert]' do
      ssl_cert.create_ssl_certificate({name:'', cert: 'asdasd', key: ConstantsCdn::SSL_KEY})
      expect(@csa.conn.page.body.errors.base.first).to eq 'An error occurred managing the resource remotely, please try again later. cert must not be malformed'
    end

    it 'should be deleted' do
      ssl_cert.remove_ssl_certificate
      expect(@csa.conn.page.code).to eq '204'
    end

    it 'should make sure CDN Edge Group is deleted' do
      @csa.get(ssl_cert.route_ssl_certificate)
      expect(@csa.conn.page.code).to eq '404'
    end
  end

  #TODO 'Add Custom SNI SSL Certificate to CDN Resource'
end