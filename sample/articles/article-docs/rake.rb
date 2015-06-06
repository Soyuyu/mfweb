FileList['articles/article-docs/article-docs.xml'].each do |src|
	target = File.join(BUILD_DIR + 'articles', 'article-docs.html')
	file target => [src] do
    skeleton = Mfweb::Core::Site.skeleton.with_css('doc.css')
    transformer = './articles/article-docs/doc.rb'
    require transformer
		maker = Mfweb::Article::ArticleMaker.new(src, target, skeleton, DocTr)
		maker.code_server = Mfweb::Core::CodeServer.new 'articles/article-docs/code/'
    maker.img_out_dir = 'article-docs'
    maker.run
	end
	task :articles => target
  sassTask 'articles/article-docs/doc.scss', 'articles', :articles
  copyGraphicsTask 'articles/article-docs/img', 'articles/article-docs', :articles
end

