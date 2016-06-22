
Path = require 'path'
fs = require 'fs'
PathToGtags = ""
PathToGlobal = ""
PathEnv = ""

BuildCmdByOptions = {}

FilterKeyByOptions =
  "-ax": "path"
  "-axr": "path"
  "-axf": "symbol"
  "-axc": "symbol"


module.exports =
class GtagsSymbols
  constructor: (serializedState) ->
    @cwd = ""
    console.log atom.project.getPaths()
    if PathToGtags is ""
      packageRoot  = @getPackageRoot()
      PathToGtags  = Path.join(packageRoot, 'vendor', "#{process.platform}", "gtags")
      PathToGlobal = Path.join(packageRoot, 'vendor', "#{process.platform}", "global")
      PathEnv = Path.join(packageRoot, 'vendor', "#{process.platform}")
      BuildCmdByOptions["--update"] = PathToGlobal
      BuildCmdByOptions["--sqlite3"] = PathToGtags

  # Public
  getDefinitions: (symbolName, symbolFile="") ->
    return @gtagsCommand("-ax", symbolName)

  getReferences: (symbolName, symbolFile="") ->
    return @_gtagsCommand("-axr", symbolName, Path.dirname(symbolFile))

  getSymbolsOfFile: (path) ->
    return @_gtagsCommand("-axf", path, Path.dirname(path))

  singleFileUpdate: (path) ->
    {symbols, status} = @_gtagsCommand("-p", "", Path.dirname(path))
    if status["error"]?
      console.log "can not get GTAGS path"
      return {'symbols': {}, 'status': {}}

    type = Path.extname(path)
    if type in [".h",".c",".cpp",".java"]
      return @_gtagsCommand("--single-update", path, Path.dirname(path))
    else
      console.log "unsupport file type #{type}"
      return {'symbols': {}, 'status': {}}

  getCompletions: (prefix) ->
    return @gtagsCommand("-axc", prefix)

  buildTags: (path, onCompleted=null) ->
    return @_buildTags("build", path, onCompleted)

  updateTags: (path, onCompleted=null) ->
    return @_buildTags("update", path, onCompleted)

  version: () ->
    return @_version()

  # private
  _gtagsStatus: (options, arg, exec)->
    if exec.status is 0
      if options in ["--single-update"]
        return {'success': {'title': "[Gtags] Update tags successfully", 'detail': "File: #{arg}"}}
      else
        return {'info': {'title': "[Gtags] Symbol Not Found", 'detail': "Symbol Name: #{arg}"}}
    else
      if options in ["--single-update"]
        return {'error': {'title': "[Gtags] Update tags failed", 'detail': "#{exec.stderr}"}}
      else
        return {'error': {'title': "[Gtags] global exec failed", 'detail': "#{exec.stderr}"}}

  hasTagsFile: (path) ->
    gtagsPath = Path.normalize(path+"/GTAGS")
    try
      return fs.statSync(gtagsPath)?.isFile()
    catch error
      return false

  gtagsCommand: (options, arg) ->
    syms = []
    stas = {}
    status = {}
    paths = atom.project.getPaths()
    for path in paths
      if @hasTagsFile(path)
        {symbols, status} = @_gtagsCommand(options, arg, path)
        if symbols?.length > 0
          syms.push(symbols...)
          stas = status
          console.log symbols
          console.log syms
    if syms?.length is 0
      stas = status
    return {'symbols': syms, 'status': stas}

  _gtagsCommand: (options, arg, cwd="") ->
    console.log "gtagsCommand, options: #{options}, arg: #{arg}, cwd: #{cwd}"
    result = []

    spawnSync  = require("child_process").spawnSync
    console.log "execute global, opt: #{options}, arg: #{arg}, cwd: #{cwd}"
    if arg is ""
      opt = [options]
    else
      opt = [options, arg]

    gtagsEnv = process.env
    gtagsEnv['PATH'] = PathEnv
    global = spawnSync(PathToGlobal, opt, {cwd:cwd, env:gtagsEnv})
    # console.log global
    if global.error?
      status = {'error': {'title': "[Gtags] global not found", 'detail': global.error.toString()}}
      return {'symbols': [], 'status': status}

    if global.stdout.length is 0 or arg is ""
      status = @_gtagsStatus(options, arg, global)
      return {'symbols': [], 'status': status}

    symbols = global.stdout.toString().match(/[^\r\n]+/g)
    console.log symbols
    if options is "-axc"
      for s in symbols
        result.push({"symbol":s})
      return {'symbols': result, 'status': {}}

    re = /([^\s]+)\s+([^\s]+)\s+([^\s]+)\s+(.*)/
    for symbol in symbols
      s = re.exec(symbol)
      result.push({"symbol":s[1], "line":s[2], "path":Path.normalize(s[3]), "signature":s[4]})

    result.splice 0,0,
      "options":"#{options}"
      "filterKey":FilterKeyByOptions[options]
      "title":"[#{s[1]}]: #{symbols.length}"
      "project":"#{cwd}"

    return {'symbols': result, 'status': {}}

  _buildTags: (arg, path, onCompleted) ->
    if arg is "update"
      options = "--update"
      cmdOpt = ["--update"]
    else
      options = "--sqlite3"
      cmdOpt = ["--skip-unreadable", "--sqlite3"]
      if not atom.config.get('atom-gtags.useSqlite3Format')
        console.log "Using BSD/DB Format"
        cmdOpt = ["--quiet"]

    console.log "buildtags, arg: #{arg}, path: #{path}"
    cmdPath = BuildCmdByOptions[options]
    spawn = require("child_process").spawn

    gtagsEnv = process.env
    gtagsEnv['PATH'] = PathEnv
    cmd = spawn(cmdPath, cmdOpt, {cwd:path, env:gtagsEnv})

    cmd.stdout.on 'data', (data) ->
      console.log data.toString()

    cmd.stderr.on 'data', (data) ->
      console.log data.toString()

    if onCompleted?
      cmd.on 'exit', onCompleted

    cmd.on 'exit', (code) ->
      #console.log "exit, ret:#{code}"
      if code is 0
        atom.notifications.addInfo "[Gtags] Update Tags Files Completed!",
          # detail: "Status: #{code}"
          dismissable: true
      else
        atom.notifications.addError "[Gtags] Update Tags Files Failed!",
          # detail: "Status: #{code}"
          dismissable: true

  getPackageRoot: ->
    packageRoot = Path.resolve(__dirname, '..')
    {resourcePath} = atom.getLoadSettings()
    if Path.extname(resourcePath) is '.asar'
      if packageRoot.indexOf(resourcePath) is 0
        packageRoot = Path.join("#{resourcePath}.unpacked", 'node_modules', 'gtags')
    packageRoot

  _version: () ->
    options = "--sqlite3"
    cmdOpt = "--version"
    cmdPath = BuildCmdByOptions[options]
    spawn = require("child_process").spawn
    cmd = spawn(cmdPath, [cmdOpt])

    cmd.stdout.on 'data', (data) ->
      console.log data.toString()

    cmd.stderr.on 'data', (data) ->
      console.log data.toString()
