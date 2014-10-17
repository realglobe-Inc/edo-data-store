module SqlExplainer
  def to_a
    logger.debug explain if defined?(Rails::Console) && !loaded?
    super
  end
end

class ActiveRecord::Relation
  prepend SqlExplainer
end
