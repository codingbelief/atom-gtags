GtagsSymbols = require './gtags-symbols'
{filter} = require 'fuzzaldrin'
module.exports =
class GtagsProvider
  selector: '.source.c, .source.cpp, .source.java'
  disableForSelector: '.comment, .string'
  inclusionPriority: 100
  #suggestionPriority: 2
  #excludeLowerPriority: true
  @prePrefix: ""
  @preSuggestions: []

  getSuggestions: ({scopeDescriptor, prefix}) ->
    return unless atom.config.get('atom-gtags.enableGtagsAutocomplete')
    #console.log scopeDescriptor
    return new Promise (resolve) =>
      suggestion = []
      if prefix?.length >= 3
        suggestion = @_getSuggestions(prefix)
      resolve(suggestion)

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
