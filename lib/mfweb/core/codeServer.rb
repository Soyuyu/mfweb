module Mfweb::Core

class CodeServer

  def find file, fragment
    return fragment ? 
      find_fragment(file, fragment) :
      whole_file(file)
  end

  def whole_file file
    unless @whole_files[file]
      codeFile = File.join(@code_dir, file)
      @whole_files[file] = File.readlines(codeFile).join
    end
    return CodeFragment.new(@whole_files[file], file)
  end

  def find_fragment file, fragment
    unless @files[file]
      codeFile = File.join(@code_dir, file)
      frag = Fragmentor.new(codeFile)
      frag.run
      @files[file] = frag
    end
    return @files[file][fragment]   
  end
  def initialize code_dir = './'
    @code_dir = code_dir
    @files = {}
    @whole_files = {}
  end
  def path
    return @code_dir
  end

  def render_insertCode anElement, html, tr: nil
    frag = find(anElement['file'], anElement['fragment'])
    CodeRenderer.new(html, frag, anElement, tr: tr).call
  rescue MissingFragmentFile
    html.error "missing file: #{anElement['file']} in #{path}"
  rescue MissingFragment
    html.error "missing fragment: #{anElement['fragment']}"
  end

  


end

end
