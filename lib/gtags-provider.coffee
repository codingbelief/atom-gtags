GtagsSymbols = require './gtags-symbols'
{filter} = require 'fuzzaldrin'
module.exports =
class GtagsProvider
  selector: '.source.c'
  disableForSelector: '.comment, .string'
  inclusionPriority: 100
  #suggestionPriority: 2
  #excludeLowerPriority: true
  @prePrefix: ""
  @preSuggestions: []

  getSuggestions: ({scopeDescriptor, prefix}) ->
    return unless atom.config.get('atom-gtags.autoUpdateTagsOnFileSaved')
    #console.log scopeDescriptor
    if prefix?.length < 3
      return []

    if prefix?.length is 3
      if GtagsProvider.prePrefix not in [prefix]
        GtagsProvider.prePrefix = prefix
        GtagsProvider.preSuggestions = @_getSuggestions(prefix)

    return filter(GtagsProvider.preSuggestions, prefix, key: 'text')

  _getSuggestions: (prefix) ->
    suggestions = []
    gtagsSymbols = new GtagsSymbols()
    {symbols, status} = gtagsSymbols.getCompletions(prefix)
    #console.log symbols
    if symbols?.length > 0
      for symbol in symbols[1...]
        suggestions.push
          text: symbol["symbol"]
          rightLabel: "Gtags"
          description: symbol["signature"]

    # console.log "getGtagsSuggestions prefix: #{prefix}"
    # console.log suggestions
    return suggestions
