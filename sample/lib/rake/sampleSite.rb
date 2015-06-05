require 'mfweb/core'

class SampleSite < Mfweb::Core::Site
  def load_skeleton
    @header = "<div id = 'banner'></div>"
    @footer = "<div id = 'footer'></div>"
    @skeleton = DraftSkeleton.new(@header, @footer, 'global.css')    
  end
  class DraftSkeleton < Mfweb::Core::PageSkeleton
    def with_banner_photo(pick_photo); return self; end
  end

end

Mfweb::Core::Site.init(SampleSite.new)

markdown_task('index.md', '.', :home, "Sample Home Page",  
              Mfweb::Core::Site.skeleton.with_css('/home.css'))

sassTask 'css/home.scss', '.', :home


