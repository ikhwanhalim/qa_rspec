class EdgeGroupActions
  include ApiClient, Log

  attr_reader :edge_group

  def precondition
    @edge_group = EdgeGroup.new(self).create_edge_group

    self
  end
end
