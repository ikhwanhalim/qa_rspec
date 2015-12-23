module RemoteMethods
  def self.included(klass)
    klass.extend(self)
  end

  def compute
    @compute ||= -> {
      data = YAML::load_file('config/conf.yml')
      params = {provider: 'OnApp', user: data['user'], key: data['pass'],uri: data['url']}
      Fog::Compute.new(params)
    }.call
  end
end