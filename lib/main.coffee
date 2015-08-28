Path = require 'path'
GtagsSymbols = require './gtags-symbols'
GtagsNavigation = require './gtags-navigation'
GtagsProvider = require './gtags-provider'
GtagsStatusBarManager = require './gtags-status-bar-manager'
GtagsSymbolsView = require './gtags-symbols-view'
GtagsLookupView = require './gtags-lookup-view'
{CompositeDisposable} = require 'atom'

module.exports = AtomGtags =
  config:
    autoUpdateTagsOnFileSaved:
      type: 'boolean'
      default: true

    useSqlite3Format:
      type: 'boolean'
      default: true

    enableGtagsAutocomplete:
      type: 'boolean'
      default: false

  provider: null
  gtagsListView: null
  modalPanel: null
  subscriptions: null
  scheduleTimeout: null
  gtagsNotifications: null

  activate: (state) ->
    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable()

    # Register commands
    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-gtags:get-definitions': => @getDefinitions()
    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-gtags:get-references': => @getReferences()
    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-gtags:single-file-update': => @singleFileUpdate()
    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-gtags:lookup-definitions': => @lookupDefinitions()
    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-gtags:get-symbols-of-file': => @getSymbolsOfFile()
    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-gtags:nav-forward': => @navForward()
    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-gtags:nav-back': => @navBack()
    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-gtags:build-tags': => @buildTags()
    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-gtags:update-tags': => @updateTags()
    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-gtags:toggle': (event) => @toggle(event)
    @subscriptions.add atom.commands.add '.tree-view .selected', 'atom-gtags:build-tags': (event) => @buildTags(event.currentTarget)
    @subscriptions.add atom.commands.add '.tree-view .selected', 'atom-gtags:update-tags': (event) => @updateTags(event.currentTarget)

    @subscriptions.add atom.workspace.observeTextEditors((editor) => @_editorGiven(editor))
    @gtagsSymbols = new GtagsSymbols()
    @gtagsSymbolsView = new GtagsSymbolsView()
    @gtagsLookupView = new GtagsLookupView()
    @gtagsStatusBarManager = new GtagsStatusBarManager()
    atom.commands.add '.tree-view .file .name[data-name$=\\.json]', 'your-package:open-as-json', ({target}) => @toggle

  _editorGiven: (editor) ->
    @subscriptions.add editor.onDidSave =>
      @autoUpdateTags(editor.getPath())

  provide: ->
    unless @provider?
      @provider = new GtagsProvider()
    return @provider

  consumeStatusBar: (statusBar) ->
    @gtagsStatusBarManager.initialize(statusBar)
    @gtagsStatusBarManager.attach()
    @gtagsStatusBarManager.update("Gtags")

  deactivate: ->
    console.log "gtags deactivate"
    @subscriptions.dispose()
    @gtagsStatusBarManager.detach()
    @gtagsSymbols.destroy()
    @gtagsSymbolsView.destroy()
    @gtagsLookupView.destroy()

  serialize: ->

  getSymbols: (type) ->
    if textEditor = atom.workspace.getActiveTextEditor()
      symbolName = textEditor.getWordUnderCursor()
      symbolFile = textEditor.getPath()
      if type is "Definitions"
        {symbols, status} = @gtagsSymbols.getDefinitions(symbolName, symbolFile)
      else
        {symbols, status} = @gtagsSymbols.getReferences(symbolName, symbolFile)
      @notify(status)
      return if symbols?.length is 0

      if symbols.length is 2
        @gtagsSymbolsView.openPath(symbols[1]["path"], symbols[1]["line"])
      else if symbols.length > 2
        @gtagsSymbolsView.setItems(symbols)
        @gtagsSymbolsView.show()

  getDefinitions: ->
    console.log 'Gtags GetDefinitions!'
    @getSymbols("Definitions")

  getReferences: ->
    console.log 'Gtags GetReferences!'
    @getSymbols("References")

  getSymbolsOfFile: ->
    console.log 'Gtags GetSymbolsOfFile!'
    if textEditor = atom.workspace.getActiveTextEditor()
      path = textEditor.getPath()
      {symbols, status} = @gtagsSymbols.getSymbolsOfFile(path)
      @notify(status)
      return if symbols?.length is 0

      @gtagsSymbolsView.setItems(symbols)
      @gtagsSymbolsView.show()

  singleFileUpdate: ->
    console.log 'Gtags SingleFileUpdate!'
    if textEditor = atom.workspace.getActiveTextEditor()
      path = textEditor.getPath()
      {symbols, status} = @gtagsSymbols.singleFileUpdate(path)
      @notify(status)

  lookupDefinitions: ->
    console.log 'Gtags LookupDefinitions!'
    @gtagsLookupView.setItems('')
    path = ""
    if textEditor = atom.workspace.getActiveTextEditor()
      path = textEditor.getPath()
    @gtagsLookupView.setPath(path)
    @gtagsLookupView.onConfirmed (item) =>
      {symbols, status} = @gtagsSymbols.getDefinitions(item['symbol'], @gtagsLookupView.getPath())
      @gtagsSymbolsView.setItems(symbols)
      @gtagsSymbolsView.show()
      console.log "onConfirmedCallBack"
    @gtagsLookupView.show()

  navForward: ->
    # console.log 'Gtags navForward'
    GtagsNavigation.forward()

  navBack: ->
    # console.log 'Gtags navBack'
    GtagsNavigation.backward()

  buildTags: (target) ->
    console.log 'Gtags buildTags'
    return unless target?
    console.log target
    console.log target?.getPath()
    path = target?.getPath()
    console.log "build tags in path: #{path}"
    buildTagsCallback = =>
      @gtagsStatusBarManager.cancelLoading("Gtags")
    @gtagsSymbols.buildTags(path, buildTagsCallback)
    @gtagsStatusBarManager.setLoading("[Gtags] Building Tags Files ")

  updateTags: (target) ->
    console.log 'Gtags updateTags'
    return unless target?
    console.log target
    console.log target?.getPath()
    path = target?.getPath()
    console.log "update tags in path: #{path}"
    updateTagsCallback = =>
      @gtagsStatusBarManager.cancelLoading("Gtags")
    @gtagsSymbols.updateTags(path, updateTagsCallback)
    @gtagsStatusBarManager.setLoading("[Gtags] Updating Tags Files ")

  autoUpdateTags: (path) ->
    console.log 'Gtags autoUpdateTags'
    return unless atom.config.get('atom-gtags.autoUpdateTagsOnFileSaved')
    date = new Date()
    timestamp0 = date.getTime()
    @gtagsStatusBarManager.update("[Gtags] Updating ...")
    gtags = new GtagsSymbols()
    {symbols, status} = gtags.singleFileUpdate(path, 1)
    # console.log "singleFileUpdate"
    if status["error"]?
      @gtagsStatusBarManager.update("Gtags.")
    else
      timestamp1 = date.getTime()
      @gtagsStatusBarManager.update("[Gtags] Updated in #{timestamp1 - timestamp0} ms")
    clearTimeout(@scheduleTimeout)
    updateTagsCallback = =>
      @gtagsStatusBarManager.update("Gtags")
    @scheduleTimeout = setTimeout(updateTagsCallback,  3000)

  notify: (status, timeOut=2000) ->
    clearTimeout(@scheduleTimeout)
    if status["error"]?
      timeOut = 3000
      @gtagsNotifications = atom.notifications.addError status["error"]["title"],
        detail: status["error"]["detail"]
        dismissable: true
    if status["info"]?
      @gtagsNotifications = atom.notifications.addInfo status["info"]["title"],
        detail: status["info"]["detail"]
        dismissable: true
    if status["success"]?
      @gtagsNotifications = atom.notifications.addSuccess status["success"]["title"],
        detail: status["success"]["detail"]
        dismissable: true

    clearTimeout(@scheduleTimeout)
    notifyCallback = =>
      @gtagsNotifications?.dismiss()
    @scheduleTimeout = setTimeout(notifyCallback, timeOut)

  toggle: (event) ->
    #console.log process.platform
    target = event.currentTarget
    # console.log target
    clearTimeout(@scheduleTimeout)
    @gtagsNotifications = atom.notifications.addSuccess "Gtags toggled",
      detail: "Gtags is working on this project now!"
      dismissable: true
    toggleCallback = =>
      @gtagsNotifications.dismiss()
    @scheduleTimeout = setTimeout(toggleCallback,  1000)
    test = "1234 231"
    test1 = test.replace(/\ /g, "\\ ")
    console.log test1
