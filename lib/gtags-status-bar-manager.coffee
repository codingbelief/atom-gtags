
module.exports =
class GtagsStatusBarManager
  constructor: ->
    @element = document.createElement("div")
    @element.id = "status-bar-gtags"

    @container = document.createElement("div")
    @container.className = "inline-block"
    @container.appendChild(@element)
    @loadingAnimations = ["|....", ".|...", "..|..", "...|.", "....|"]
    @loadingText = ""

  initialize: (statusBar) ->
    @statusBar = statusBar

  update: (text) ->
    @element.textContent = text

  setLoading: (text) ->
    clearInterval(@loadingInterval)
    @counter = 0
    @loadingText = text
    loadingCallback = =>
      index = @counter
      @update("#{@loadingText} #{@loadingAnimations[index]}")
      @counter = @counter + 1
      @counter = @counter %% 5
    @loadingInterval = setInterval(loadingCallback,  200)

  cancelLoading: (text) ->
    clearInterval(@loadingInterval)
    @update(text)

  # Private

  attach: ->
    @tile = @statusBar.addRightTile(item: @container, priority: 20)

  detach: ->
    @tile.destroy()
