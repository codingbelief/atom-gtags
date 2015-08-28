{Point} = require 'atom'

module.exports =
class GtagsNavigation
  @trace: []
  @curIndex: 0

  @add: (path, line, symbol) ->
    return unless path? and line?

    if GtagsNavigation.trace.length is 0
      index = 0
      GtagsNavigation.curIndex = 0
    else
      index = GtagsNavigation.curIndex + 1

      # we don't add the new trace if it is close to the prev
      line_abs = Math.abs(parseInt(line) - parseInt(GtagsNavigation.trace[index-1]['line']))
      if path is GtagsNavigation.trace[index-1]['path'] and line_abs < 3.0
        # console.log "new trace is close to the prev, line abs: #{line_abs}"
        return

      # we don't add the new trace if it is close to the next
      if index < GtagsNavigation.trace.length
        line_abs = Math.abs(parseInt(line) - parseInt(GtagsNavigation.trace[index]['line']))
        if path is GtagsNavigation.trace[index-1]['path'] and line_abs < 3.0
          # console.log "new trace is close to the next, line abs: #{line_abs}"
          if index < GtagsNavigation.trace.length
            GtagsNavigation.curIndex = index
          return

    GtagsNavigation.curIndex = index

    # console.log "add trace, #{path}:#{line}:#{symbol}"
    GtagsNavigation.trace?.splice(index,0,{'path':path, 'line':line, 'symbol':symbol})
    # console.log "trace length: #{GtagsNavigation.trace.length}, index: #{GtagsNavigation.curIndex}"
    # console.log GtagsNavigation.trace

  @showTrace: ->
    return GtagsNavigation.trace

  @forward: ->
    if GtagsNavigation.curIndex >= (GtagsNavigation.trace.length-1)

      atom.notifications.addInfo "[Gtags][Navigation] Reach the end of trace",
        #detail: "info message"
        dismissable: true

      return -1

    if GtagsNavigation.trace.length is 0
      return -1
    else if GtagsNavigation.trace.length is 1
      index = 0
      return -1
    else
      index = GtagsNavigation.curIndex+1
      GtagsNavigation.curIndex = index

      # console.log  "forward to index: #{index}"
      path = GtagsNavigation.trace[index]['path']
      line = GtagsNavigation.trace[index]['line']
      # console.log  "forward to file: #{path}:#{line}"
      @openPath(path, line)
      return GtagsNavigation.curIndex

  @backward: ->
    if GtagsNavigation.curIndex is 0

      atom.notifications.addInfo "[Gtags][Navigation] Reach the begin of trace",
        #detail: "info message"
        dismissable: true

      return -1

    if GtagsNavigation.trace.length is 0
      return
    else if GtagsNavigation.trace.length is 1
      index = 0
    else
      index = GtagsNavigation.curIndex-1
      GtagsNavigation.curIndex = index

      # console.log  "backward to index: #{index}"
      path = GtagsNavigation.trace[index]['path']
      line = GtagsNavigation.trace[index]['line']
      # console.log  "backward to file: #{path}:#{line}"
      GtagsNavigation.openPath(path, line)
      return GtagsNavigation.curIndex

  @openPath: (path, line) ->
    atom.workspace.open(path).done => GtagsNavigation.moveToLine(line)
    #console.log GtagsNavigation.trace

  @moveToLine: (line) ->
    lineNumber = parseInt(line, 10)
    return unless lineNumber > 0

    if textEditor = atom.workspace.getActiveTextEditor()
      position = new Point(lineNumber-1)
      textEditor.scrollToBufferPosition(position, center: true)
      textEditor.moveToFirstCharacterOfLine()
      textEditor.setCursorBufferPosition(position)
