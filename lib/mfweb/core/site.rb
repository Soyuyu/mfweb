module Mfweb::Core
class Site
  def self.master
    raise "site not initialized" unless initialized?
    @@master
  end
  def self.init master
    unless initialized?
      @@master = master
    end
  end
  def self.initialized?
    (defined? @@master) && @@master
  end
  def self.method_missing name, *args
    master.send name, *args
  end
  def catalog
    load_catalog
    return @catalog
  end
  def skeleton
    load_skeleton
    return @skeleton
  end
  def author_server
    @author_server ||= load_authors
    return @author_server
  end
  def url
    'http://martinfowler.com'
  end
  def target_to_local_url path
    result = path.pathmap "%{^#{build_path},}d/%f"
    return result.sub('index.html','')
  end
  def target_to_url path
    url + target_to_local_url(path)
  end
  def url_path *args
    File.join([url] + args)
  end
  def twitter_site_id
    nil
    # override to provide twitter metadata
  end

  def build_path *args
    File.join('build', *args)
  end

  # hook methods
  def load_skeleton; end
  def load_catalog; end
  def load_authors; end
end
end
