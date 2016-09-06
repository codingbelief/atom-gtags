{Point} = require 'atom'
module.exports =
class GtagsFiles
  @subscription: null
  @events: []
  @paths: []
  @keepOpened: []

  @preview: (path, line, keepOpened=0) ->
    GtagsFiles.subscription = atom.workspace.onDidOpen (event) =>
      if event?['uri'] not in @paths
        # console.log "push"
        # console.log event
        GtagsFiles.events.push event
        GtagsFiles.paths.push event['uri']
      GtagsFiles.subscription.dispose()

    if keepOpened is 1
      # console.log "keep #{path}"
      GtagsFiles.keepOpened.push path

    atom.workspace.open(path,{activatePane:false}).done =>
      GtagsFiles.moveToLine(line)

  @open: (path, line) ->
    GtagsFiles.keepOpened.push path
    #atom.workspace.open(path,{activatePane:true}).done =>
    #  GtagsFiles.moveToLine(line)
    GtagsFiles.clear()

  @clear: ->
    for event in GtagsFiles.events
        if event?['uri'] not in GtagsFiles.keepOpened
          # console.log "close"
          # console.log event
          event?['item']?.destroy()
    GtagsFiles.events = []
    GtagsFiles.paths = []
    GtagsFiles.keepOpened = []

  @moveToLine: (line) ->
    lineNumber = parseInt(line, 10)
    return unless lineNumber > 0

    if textEditor = atom.workspace.getActiveTextEditor()
      position = new Point(lineNumber-1)
      textEditor.setCursorBufferPosition(position)
      textEditor.scrollToBufferPosition(position, center: true)
      #textEditor.scrollToScreenPosition(position, center: true)
      #textEditor.scrollToCursorPosition()
      #textEditor.moveToFirstCharacterOfLine()
