module Mfweb::Article

  class RefactoringServer
    def initialize *paths
      @paths = paths
      @refactorings = {}
    end
    def load
      @paths.each {|p| load_dir p}
    end
    def find key
      return @refactorings[key] || MissingRefactoringEntry.new
    end
    def fake_load
      add_refactoring(RefactoringEntry.new('replaceNestedConditionalWithGuardClauses', 'Replace Nested Conditional With Guard Clauses'))
      add_refactoring(RefactoringEntry.new('extractMethod', 'Extract Method'))
    end
    def add_refactoring r
      @refactorings[r.key] = r
    end
    def load_dir path
      Dir[File.join(path, '*.xml')].each do |file|
        xml = Nokogiri::XML(File.read(file)).root
        ref = RefactoringEntry.new(File.basename(file, '.xml'), xml.at_css('name').text)
        add_refactoring ref
      end
    end
  end

  class RefactoringEntry
    attr_reader :key, :name
    def initialize key, name, url = nil
      @key = key
      @name = name
      @url = url
    end
    def url
      "http://refactoring.com/catalog/%s.html" % key
    end
    
  end

  class MissingRefactoringEntry
    def name
      "**** Missing Refactoring ****"
    end
    def url; ""; end
  end
end
