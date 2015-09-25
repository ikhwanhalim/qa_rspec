require 'onapp_iso'

describe 'ISO functionality tests' do

  before(:all) do
    @iso=OnappISO.new
    data = {'label' => 'iso_api_test',
            'make_public' => '0',
            'min_memory_size' => '256',
            'version' => '1.0',
            'operating_system' => 'Linux',
            'operating_system_distro' => 'Fedora',
            'virtualization' => ["xen", "kvm"],
            'file_url' => 'http://download.fedoraproject.org/pub/fedora/linux/releases/21/Server/x86_64/iso/Fedora-Server-netinst-x86_64-21.iso'}
    @iso.create_iso(data)
  end

  after(:all) do
    @iso.delete_iso
    Log.error('ISO has not been deleted') if @iso.api_response_code != '204'
  end

  describe 'Create ISO negative tests' do

    it 'Create ISO with empty label' do
      data = {'label' => '',
              'make_public' => '0',
              'min_memory_size' => '256',
              'version' => '1.0',
              'operating_system' => 'Linux',
              'operating_system_distro' => 'Fedora',
              'virtualization' => ["xen", "kvm"],
              'file_url' => 'http://download.fedoraproject.org/pub/fedora/linux/releases/21/Server/x86_64/iso/Fedora-Server-netinst-x86_64-21.iso'}
      response = @iso.create_iso(data)
      expect(response['label']).to eq(["can't be blank"])
      expect(@iso.api_response_code).to eq '422'
    end

    it 'Create ISO test with incorrect min_memory_size' do
      data = {'label' => 'iso_api_test',
              'make_public' => '0',
              'min_memory_size' => '0',
              'version' => '1.0',
              'operating_system' => 'Linux',
              'operating_system_distro' => 'Fedora',
              'virtualization' => ["xen", "kvm"],
              'file_url' => 'http://download.fedoraproject.org/pub/fedora/linux/releases/21/Server/x86_64/iso/Fedora-Server-netinst-x86_64-21.iso'}
      response = @iso.create_iso(data)
      expect(response['min_memory_size']).to eq(["must be greater than or equal to 128"])
      expect(@iso.api_response_code).to eq '422'
    end

    it 'Create ISO test with empty version' do
      data = {'label' => 'iso_api_test',
              'make_public' => '0',
              'min_memory_size' => '0',
              'version' => '',
              'operating_system' => 'Linux',
              'operating_system_distro' => 'Fedora',
              'virtualization' => ["xen", "kvm"],
              'file_url' => 'http://download.fedoraproject.org/pub/fedora/linux/releases/21/Server/x86_64/iso/Fedora-Server-netinst-x86_64-21.iso'}
      response = @iso.create_iso(data)
      expect(response['version']).to eq(["can't be blank"])
      expect(@iso.api_response_code).to eq '422'
    end

    it 'Create ISO test with empty operating_system' do
      data = {'label' => 'iso_api_test',
              'make_public' => '0',
              'min_memory_size' => '128',
              'version' => '1.0',
              'operating_system' => '',
              'operating_system_distro' => 'Fedora',
              'virtualization' => ["xen", "kvm"],
              'file_url' => 'http://download.fedoraproject.org/pub/fedora/linux/releases/21/Server/x86_64/iso/Fedora-Server-netinst-x86_64-21.iso'}
      response = @iso.create_iso(data)
      expect(response['operating_system']).to eq(["can't be blank"])
      expect(@iso.api_response_code).to eq '422'
    end

    it 'Create ISO test with empty virtualization' do
      data = {'label' => 'iso_api_test',
              'make_public' => '0',
              'min_memory_size' => '128',
              'version' => '1.0',
              'operating_system' => 'Linux',
              'operating_system_distro' => 'Fedora',
              'virtualization' => [],
              'file_url' => 'http://download.fedoraproject.org/pub/fedora/linux/releases/21/Server/x86_64/iso/Fedora-Server-netinst-x86_64-21.iso'}
      response = @iso.create_iso(data)
      expect(response['virtualization']).to eq(["can't be blank"])
      expect(@iso.api_response_code).to eq '422'
    end

    it 'Create ISO test with empty file_url' do
      data = {'label' => 'iso_api_test',
              'make_public' => '0',
              'min_memory_size' => '128',
              'version' => '1.0',
              'operating_system' => 'Linux',
              'operating_system_distro' => 'Fedora',
              'virtualization' => ["xen", "kvm"],
              'file_url' => ''}
      response = @iso.create_iso(data)
      expect(response['file_url']).to eq(["can't be blank"])
      expect(@iso.api_response_code).to eq '422'
    end

  end

  describe 'Edit ISO positive tests' do
    before (:all) do

      @data = {'label' => 'EditedISO',
                'min_memory_size' => '128',
                'version' => '2.0',
                'operating_system' => 'Freebsd',
                'operating_system_distro' => 'Debian',
                'virtualization' => ["kvm", "kvm_virtio"]}
      @iso.edit_iso(@data)
      Log.error('ISO has not been updated') if @iso.api_response_code != '204'
      @response = @iso.get_iso(@iso.iso_id)
      expect(@iso.api_response_code).to eq '200'
    end

    it 'Edit ISO label' do
      expect(@response['label']).to eq(@data['label'])
    end

    it 'Edit ISO min memory size' do
      expect(@response['min_memory_size']).to eq 128
    end

    it 'Edit ISO version' do
      expect(@response['version']).to eq '2.0'
    end

    it 'Edit ISO operating system' do
      expect(@response['operating_system']).to eq 'Freebsd'
    end

    it 'Edit ISO operating system distro' do
      expect(@response['operating_system_distro']).to eq 'Debian'
    end

    it 'Edit ISO virtualization type' do
      expect(@response['virtualization']).to eq ["kvm", "kvm_virtio"]
    end
  end

    it 'Make ISO public' do
    response = @iso.make_iso_public
    expect(@iso.api_response_code).to eq '201'
    response = @iso.get_iso(@iso.iso_id)
    expect(response['user_id']).to be_nil
  end

end
