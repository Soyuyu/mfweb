module Mfweb::Article

  class RefactoringServer
    def load
      fake_load
    end
    def find key
      return @refactorings[key] || MissingRefactoringEntry.new
    end
    def fake_load
      @refactorings = {}
      add_refactoring(RefactoringEntry.new('replaceNestedConditionalWithGuardClauses', 'Replace Nested Conditional With Guard Clauses'))
      add_refactoring(RefactoringEntry.new('extractMethod', 'Extract Method'))
    end
    def add_refactoring r
      @refactorings[r.key] = r
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
