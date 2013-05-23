FileList['articles/flexible/flexible-article.xml'].each do |src|
	target = File.join(BUILD_DIR + 'articles', 'flexible.html')
	file target => [src] do
    skeleton = Mfweb::Core::Site.skeleton.with_css('flexible.css')
    transformer = './articles/flexible/flexible.rb'
    require transformer
		maker = Mfweb::Article::ArticleMaker.new(src, target, skeleton, FlexibleTr)
		maker.code_server = Mfweb::Article::CodeServer.new 'articles/flexible/code/'
    maker.run
	end
	task :articles => target
  sassTask 'articles/flexible/flexible.scss', 'articles', :articles
  copyGraphicsTask 'articles/flexible', 'articles/flexible', :articles
end

