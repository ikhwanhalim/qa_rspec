require 'spec_helper'
require './groups/cdn_ssl_actions'
require './spec/onapp/cdn/constants_cdn'
# the next needs for creating cdn_resource
require './groups/edge_group_actions'
require './groups/billing_plan_actions'
require './groups/cdn_resource_actions'

describe 'Ssl Certificate' do
  before :all do
    @csa = CdnSslActions.new.precondition
    @cp_version = @csa.version
  end

  let (:ssl_cert) {@csa.ssl_cert}


  context 'Create ->' do
    context 'with name ->' do
      it 'is create' do
        ssl_cert.create_ssl_certificate
        expect(@csa.conn.page.code).to eq '201'
        expect(ssl_cert.id).not_to be nil
        expect(ssl_cert.cdn_reference.class).to eq Fixnum
        ssl_cert.get
        expect(ssl_cert.cdn_resources.empty?).to be true
      end

      it 'is delete' do
        ssl_cert.remove_ssl_certificate
        expect(@csa.conn.page.code).to eq '204'
      end

      it 'make sure ssl cert is deleted' do
        @csa.get(ssl_cert.route_ssl_certificate)
        expect(@csa.conn.page.code).to eq '404'
      end
    end

    context 'without name ->' do
      it 'is create' do
        ssl_cert.create_ssl_certificate(name: '')
        expect(@csa.conn.page.code).to eq '201'
        expect(ssl_cert.id).not_to be nil
        expect(ssl_cert.cdn_reference.class).to eq Fixnum
        expect(ssl_cert.cdn_resources.empty?).to be true
      end

      it 'is delete' do
        ssl_cert.remove_ssl_certificate
        expect(@csa.conn.page.code).to eq '204'
      end

      it 'make sure ssl cert is deleted' do
        @csa.get(ssl_cert.route_ssl_certificate)
        expect(@csa.conn.page.code).to eq '404'
      end
    end

    context 'name contain special characters ->' do
      # https://onappdev.atlassian.net/browse/CORE-8586

      it 'is create' do
        ssl_cert.create_ssl_certificate(name: 'test-%^&%#$')
        expect(@csa.conn.page.code).to eq '201'
        expect(ssl_cert.id).not_to be nil
        expect(ssl_cert.cdn_reference.class).to eq Fixnum
        expect(ssl_cert.cdn_resources.empty?).to be true
      end

      it 'is delete' do
        ssl_cert.remove_ssl_certificate
        expect(@csa.conn.page.code).to eq '204'
      end

      it 'make sure ssl cert is deleted' do
        @csa.get(ssl_cert.route_ssl_certificate)
        expect(@csa.conn.page.code).to eq '404'
      end
    end
  end

  context 'Edit ->' do
    before :all do
      @csa.ssl_cert.create_ssl_certificate
    end

    after :all do
      @csa.ssl_cert.remove_ssl_certificate
    end

    it 'is edit name' do
      ssl_cert.edit({cdn_ssl_certificate: {name: ConstantsCdn::NAME_SSL_EDIT}})
      expect(@csa.conn.page.code).to eq '204'
    end

    it 'make sure name is edited' do
      ssl_cert.get
      expect(ssl_cert.name).to eq ConstantsCdn::NAME_SSL_EDIT
      expect(ssl_cert.cdn_reference.size).to be > 3
      expect(ssl_cert.cdn_reference.class).to eq Fixnum
    end
  end

  context 'Search ->' do
    before :all do
      @csa_1 = CdnSslActions.new.precondition
      @csa_2 = CdnSslActions.new.precondition
    end

    let (:ssl_cert_1) {@csa_1.ssl_cert}
    let (:ssl_cert_2) {@csa_2.ssl_cert}

    it 'create two ssl certs' do
      ssl_cert_1.create_ssl_certificate
      expect(ssl_cert_1.id).not_to be nil
      ssl_cert_2.create_ssl_certificate
      expect(ssl_cert_2.id).not_to be nil
    end

    it 'should find by id' do
      skip('it is not supported on CP < v5.6') if @cp_version < 5.6
      @csa_1.get(ssl_cert_1.route_ssl_certificates, { q: ssl_cert_1.id })
      expect(@csa_1.conn.page.body.count).to eq 1
    end

    it 'should find by name' do
      skip('it is not supported on CP < v5.6') if @cp_version < 5.6
      @csa_1.get(ssl_cert_1.route_ssl_certificates, { q: ssl_cert_1.name })
      expect(@csa_1.conn.page.body.count).to eq 1
    end

    it 'remove first ssl and try to search' do
      skip('it is not supported on CP < v5.6') if @cp_version < 5.6
      ssl_cert_1.remove_ssl_certificate
      @csa_1.get(ssl_cert_1.route_ssl_certificates, { q: ssl_cert_1.name })
      expect(@csa_1.conn.page.body.count).to eq 0
      @csa_1.get(ssl_cert_1.route_ssl_certificates, { q: ssl_cert_1.id })
      expect(@csa_1.conn.page.body.count).to eq 0
    end

    it 'remove second ssl cert' do
      ssl_cert_2.remove_ssl_certificate
      @csa_2.get(ssl_cert_2.route_ssl_certificate)
      expect(@csa_2.conn.page.code).to eq '404'
    end
  end

  context 'Complex' do
    before :all do
      @csa.ssl_cert.create_ssl_certificate
    end

    after :all do
      @csa.ssl_cert.remove_ssl_certificate
    end

    it 'is created' do
      expect(ssl_cert.id).not_to be nil
      expect(ssl_cert.cdn_reference.class).to eq Fixnum
    end

    it 'is edit name' do
      ssl_cert.edit({cdn_ssl_certificate: {name: ConstantsCdn::NAME_SSL_EDIT}})
      expect(@csa.conn.page.code).to eq '204'
    end

    it 'make sure name is edited' do
      ssl_cert.get
      expect(ssl_cert.name).to eq ConstantsCdn::NAME_SSL_EDIT
      expect(ssl_cert.cdn_reference.size).to be > 3
      expect(ssl_cert.cdn_reference.class).to eq Fixnum
    end

    it 'should get list of SSL certificates' do
      @csa.get(ssl_cert.route_ssl_certificates)
      expect(@csa.conn.page.code).to eq '200'
      expect(@csa.conn.page.body.count).to be >= 1
    end
  end

  context 'Get SSL Certificate details which is bound to cdn resource' do
   # it is implemented in resource_pull_spec (create->basic->positive->ssl_certificate)
  end

  context 'negative tests' do
    context 'is not create ->' do
      it 'with name > 255' do
        ssl_cert.create_ssl_certificate({name: ConstantsCdn::NAME_255_SSL })
        expect(@csa.conn.page.body.errors.name).to eq ["is too long (maximum is 255 characters)"]
      end

      it 'with all params are empty' do
        # https://onappdev.atlassian.net/browse/CORE-8589, should be "can't be blank"
        ssl_cert.create_ssl_certificate({name:'', cert: '', key: ''})
        expect(@csa.conn.page.code).to eq '422'
        expect(@csa.conn.page.body.errors.cert).to eq ["is invalid", "can't be blank"]
      end

      it 'with wrong format[key, cert]' do
        ssl_cert.create_ssl_certificate({name:'', cert: Faker::Internet.domain_word, key: Faker::Internet.domain_word})
        expect(@csa.conn.page.code).to eq '422'
        expect(@csa.conn.page.body.errors.base).to eq ["An error occurred managing the resource remotely, please try again later. cert must not be malformed"]
        end

      it 'with wrong format[key]' do
        ssl_cert.create_ssl_certificate({name:'', cert: ConstantsCdn::SSL_CERT, key: Faker::Internet.domain_word})
        expect(@csa.conn.page.code).to eq '422'
        expect(@csa.conn.page.body.errors.base).to eq ["An error occurred managing the resource remotely, please try again later. SSL private key must pkcs8 compatible"]
        end

      it 'with wrong format[cert]' do
        ssl_cert.create_ssl_certificate({name:'', cert: Faker::Internet.domain_word, key: ConstantsCdn::SSL_KEY})
        expect(@csa.conn.page.code).to eq '422'
        expect(@csa.conn.page.body.errors.base).to eq ["An error occurred managing the resource remotely, please try again later. cert must not be malformed"]
      end
    end

    context 'is not edit ->' do
      before :all do
        @csa.ssl_cert.create_ssl_certificate
      end

      after :all do
        @csa.ssl_cert.remove_ssl_certificate
      end

      it 'with incorrect name' do
        ssl_cert.edit({cdn_ssl_certificate: {name: 'тест'}})
        expect(@csa.conn.page.code).to eq '422'
        expect(@csa.conn.page.body.errors.name).to eq ["is invalid"]
      end

      it 'with empty cert' do
        ssl_cert.edit({cdn_ssl_certificate: {cert: ''}})
        expect(@csa.conn.page.code).to eq '422'
        expect(@csa.conn.page.body.errors.cert).to eq ["is invalid", "can't be blank"]
      end

      it 'with incorrect cert' do
        ssl_cert.edit({cdn_ssl_certificate: {cert: Faker::Internet.domain_word}})
        expect(@csa.conn.page.code).to eq '422'
        expect(@csa.conn.page.body.errors.base).to eq ["An error occurred managing the resource remotely, please try again later. cert must not be malformed"]
      end

      it 'with empty key' do
        ssl_cert.edit({cdn_ssl_certificate: {key: Faker::Internet.domain_word}})
        expect(@csa.conn.page.code).to eq '422'
        expect(@csa.conn.page.body.errors.base).to eq ["An error occurred managing the resource remotely, please try again later. SSL private key must pkcs8 compatible"]
      end
    end
  end
end