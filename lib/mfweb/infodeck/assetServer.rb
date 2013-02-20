module Mfweb::InfoDeck
  class AssetServer
    def initialize *paths
      @paths = paths
    end

    def [] key
      @paths.each do |p|
        file = File.join(p, key)
        return file if File.exists? file
      end
      raise "unable to find #{key} in [#{@paths.join(', ')}]"
    end
  end
end
