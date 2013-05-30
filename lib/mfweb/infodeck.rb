require 'mfweb/core'

require 'rake/ext/string'
require 'kramdown'
require 'stringio'
require 'sass'
require 'json'

module InfoDeck
  include Mfweb::Core
end

#TODO move codeserver to core
require 'mfweb/article' # TODO break this dependency (move code server to core)

require 'mfweb/infodeck/assetServer'
require 'mfweb/infodeck/maker'
require 'mfweb/infodeck/deckSkeleton'
require 'mfweb/infodeck/deckTransformer'
require 'mfweb/infodeck/svgManipulator'
require 'mfweb/infodeck/svgInstaller'
require 'mfweb/infodeck/regexpHighlighter'
require 'mfweb/infodeck/regexpHighlighterTr'
require 'mfweb/infodeck/javascriptEmitter'
require 'mfweb/infodeck/buildCollector'
require 'mfweb/infodeck/buildTransformer'
require 'mfweb/infodeck/fallbackGenerator'
require 'mfweb/infodeck/indexTransformer'
require 'mfweb/infodeck/highlightSequenceTr'

