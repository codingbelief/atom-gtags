{$$} = require 'atom-space-pen-views'
GtagsSymbolsView = require './gtags-symbols-view'
GtagsSymbols = require './gtags-symbols'

module.exports =
class GtagsLookupView extends GtagsSymbolsView
  @prePrefix: ""

  getPath: ->
    return @path

  setPath: (path) ->
    @path = path

  viewForItem: (item) ->
    $$ ->
      @li class: 'two-lines', =>
        @div "#{item['symbol']}", class: 'primary-line'

  getFilterKey: ->
    return "symbol"

  schedulePopulateList: ->
    super
    prefix = @getFilterQuery()
    console.log prefix
    if (prefix.length >= 3) and (not (prefix is @prePrefix))
      gtagsSymbols = new GtagsSymbols()
      {symbols, status} = gtagsSymbols.getCompletions(prefix)
      @prePrefix = prefix
      @setItems(symbols)

  confirmed: (item) ->
    @cancel()
    @prePrefix = ""
    if @onConfirmedCallBack?
      @onConfirmedCallBack(item)

  onConfirmed: (callBack) ->
    @onConfirmedCallBack = callBack
