
GtagsFiles = require './gtags-files'
GtagsNavigation = require './gtags-navigation'
{$$, SelectListView} = require 'atom-space-pen-views'
{Point} = require 'atom'
Path = require 'path'

module.exports =
class GtagsSymbolsView extends SelectListView

  initialize: ->
    super
    #@addClass('overlay from-top')
    @panel ?= atom.workspace.addModalPanel(item: this, visible: false)
    @filterKey = null
    @prePath = ""
    @prePosition = null
    @isConfirmed = false

  viewForItem: (item) ->
    GtagsNavigation.lock()
    if item['filterKey']?
      @filterKey = item['filterKey']

    $$ ->
      @li class: 'two-lines', =>
        if item['title']?
          @div "#{item['title']}", class: 'primary-line'
          @div "Project: #{item['project']}", class: 'secondary-line'
        else
          @div "#{item['signature']}", class: 'primary-line'
          @div "#{Path.basename(item['path'])} @ #{item['path']}: #{item['line']}", class: 'secondary-line'

  getFilterKey: ->
    # console.log "getFilterKey: #{@filterKey}"
    return @filterKey

  confirmed: (item) ->

    @isConfirmed = true
    if item['title']?
      console.log "===>>> title selected"
      @cancel()
    else
      console.log("===>>> #{item['path']}:#{item['line']} was selected")
      GtagsNavigation.unlock()
      GtagsNavigation.add(@prePath, @prePosition['row'] + 1, "")
      GtagsNavigation.add(item['path'], item['line'], "")
      GtagsFiles.open(item['path'], item['line'])


  selectItemView: (view) ->
      super

      item = @getSelectedItem()
      if item["path"]?
        # preview files
        GtagsFiles.preview(item["path"], item["line"])

  destroy: ->
    console.log("destroy")
    @cancel()
    @panel?.destroy()

  cancel: ->
    @panel.hide()
    @setItems("")
    if not @isConfirmed
      GtagsFiles.open(@prePath, 0)
    GtagsFiles.clear()
    #console.log("cancel")
    super

  openPath: (path, line) ->
    # console.log path
    if textEditor = atom.workspace.getActiveTextEditor()
      # add pre path
      @prePath = textEditor.getPath()
      @prePosition = textEditor.getCursorBufferPosition()
      GtagsNavigation.add(@prePath, @prePosition['row']+1, "")
    atom.workspace.open(path).then => @moveToLine(line)
    # add new path
    GtagsNavigation.add(path, line, "")

  moveToLine: (line) ->
    lineNumber = parseInt(line, 10)
    return unless lineNumber > 0

    if textEditor = atom.workspace.getActiveTextEditor()
      position = new Point(lineNumber-1)
      textEditor.setCursorBufferPosition(position)
      textEditor.scrollToBufferPosition(position, center: true)
      #textEditor.scrollToCursorPosition(center: true)
      #textEditor.moveToFirstCharacterOfLine()

  show: ->
    @panel.show()
    @isConfirmed = false
    @focusFilterEditor()
    if textEditor = atom.workspace.getActiveTextEditor()
      # add pre path
      @prePath = textEditor.getPath()
      @prePosition = textEditor.getCursorBufferPosition()
      GtagsFiles.preview(@prePath, @prePosition, 1)
      # console.log "prePath: #{@prePath}"

  hide: ->
    @panel.hide()
