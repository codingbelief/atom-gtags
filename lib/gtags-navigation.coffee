{Point} = require 'atom'

module.exports =
class GtagsNavigation
  @trace: [[],[]]
  @curIndex: [0,0]
  @traceLock: 0
  @decoration: null
  @marker: null
  @lock: ->
    console.log "GtagsNavigation locked"
    GtagsNavigation.traceLock = 1

  @unlock: ->
    console.log "GtagsNavigation unlocked"
    GtagsNavigation.traceLock = 0

  @add: (path, position, symbol) ->
    return unless GtagsNavigation.traceLock is 0

    if position["row"]? and position["column"]?
      id = 0
      console.log "add position"
      if GtagsNavigation.marker?
        GtagsNavigation.marker.destroy()
      GtagsNavigation.curIndex[id] = GtagsNavigation.trace[id].length-1
      console.log "set curIndex: #{GtagsNavigation.curIndex[id]}"
      return @_add(id, path, position, symbol)
    else
      id = 1
      console.log "add line"
      position = {'row': parseInt(position), 'column': 0}
      return @_add(id, path, position, symbol)


  @_add: (id, path, position, symbol) ->
    return unless path? and position?

    if GtagsNavigation.trace[id].length is 0
      index = 0
      console.log "set curIndex: 0"
      GtagsNavigation.curIndex[id] = 0
    else
      index = GtagsNavigation.curIndex[id] + 1

      # we don't add the new trace if it is close to the prev
      console.log position
      cur_row = position["row"]
      pre_row = GtagsNavigation.trace[id][index-1]['position']["row"]
      console.log "index: #{index}, cur_row: #{cur_row}, pre_row: #{pre_row}"
      row_abs = Math.abs(parseInt(cur_row) - parseInt(pre_row))
      if path is GtagsNavigation.trace[id][index-1]['path'] and row_abs < 3.0
        console.log "new trace is close to the prev, position abs: #{row_abs}"
        return

      # we don't add the new trace if it is close to the next
      if index < GtagsNavigation.trace[id].length
        next_row = GtagsNavigation.trace[id][index]['position']["row"]
        console.log "next_row: #{next_row}"
        row_abs = Math.abs(parseInt(cur_row) - parseInt(next_row))
        if path is GtagsNavigation.trace[id][index-1]['path'] and row_abs < 3.0
          console.log "new trace is close to the next, position abs: #{row_abs}"
          #if index < GtagsNavigation.trace[id].length
            #console.log "set curIndex: #{index}"
            #GtagsNavigation.curIndex[id] = index
          return
    console.log "set curIndex: #{index}"
    GtagsNavigation.curIndex[id] = index

    console.log "add trace, #{path}:#{position}:#{symbol}"
    GtagsNavigation.trace[id]?.splice(index,0,{'path':path, 'position':position, 'symbol':symbol})
    console.log "trace length: #{GtagsNavigation.trace[id].length}, index: #{GtagsNavigation.curIndex[id]}"
    console.log GtagsNavigation.trace

  @showTrace: ->
    return GtagsNavigation.trace

  @forward: ->
    @_forward(1)

  @backward: ->
    @_backward(1)

  @prePosition: ->
    @_forward(0)

  @nextPosition: ->
    @_backward(0)


  @_forward: (id) ->
    if GtagsNavigation.curIndex[id] >= (GtagsNavigation.trace[id].length-1)

      atom.notifications.addInfo "[Gtags][Navigation] Reach the end of trace",
        #detail: "info message"
        dismissable: true

      return -1

    if GtagsNavigation.trace[id].length is 0
      return -1
    else if GtagsNavigation.trace[id].length is 1
      index = 0
      return -1
    else
      index = GtagsNavigation.curIndex[id]+1
      console.log "set curIndex: #{index}"
      GtagsNavigation.curIndex[id] = index

      console.log  "forward to index: #{index}"
      path = GtagsNavigation.trace[id][index]['path']
      position = GtagsNavigation.trace[id][index]['position']
      console.log  "forward to file: #{path}:#{position}"
      @openPath(path, position, id)
      return GtagsNavigation.curIndex[id]

  @_backward: (id) ->
    if GtagsNavigation.curIndex[id] is 0

      atom.notifications.addInfo "[Gtags][Navigation] Reach the begin of trace",
        #detail: "info message"
        dismissable: true

      return -1

    if GtagsNavigation.trace[id].length is 0
      return
    else if GtagsNavigation.trace[id].length is 1
      index = 0
    else
      index = GtagsNavigation.curIndex[id]-1
      console.log "set curIndex: #{index}"
      GtagsNavigation.curIndex[id] = index

      console.log  "backward to index: #{index}"
      path = GtagsNavigation.trace[id][index]['path']
      position = GtagsNavigation.trace[id][index]['position']
      console.log  "backward to file: #{path}:#{position}"
      GtagsNavigation.openPath(path, position, id)
      return GtagsNavigation.curIndex[id]

  @openPath: (path, position, id=1) ->
    atom.workspace.open(path).done => GtagsNavigation.moveToLine(position, id)
      #console.log GtagsNavigation.trace

  @moveToLine: (position, id) ->
    if textEditor = atom.workspace.getActiveTextEditor()
      #textEditor.setCursorBufferPosition(position)
      #textEditor.scrollToCursorPosition(center: true)
      textEditor.scrollToBufferPosition(position, {center: true})
      if id is 3
        textEditor.setCursorBufferPosition(position)
      else
        range = textEditor.getBuffer().rangeForRow(position['row'])
        if GtagsNavigation.marker?
          GtagsNavigation.marker.destroy()
        GtagsNavigation.marker = textEditor.markBufferRange(range)
        textEditor.decorateMarker(GtagsNavigation.marker, type: 'line', class: "cursor-line")
