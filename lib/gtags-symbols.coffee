
Path = require 'path'

PathToGtags = ""
PathToGlobal = ""

BuildCmdByOptions = {}

FilterKeyByOptions =
  "-ax": "path"
  "-axr": "path"
  "-axf": "symbol"
  "-axc": "symbol"


module.exports =
class GtagsSymbols
  constructor: (serializedState) ->
    #@cwd = "/Users/Rock/code/linux/digging"
    @cwd = "/code/m81/m81_tmp/kernel/mediatek/kernel-3.10"
    #@cwd = atom.project.getPaths()[0]
    console.log atom.project.getPaths()
    if PathToGtags is ""
      packageRoot  = @getPackageRoot()
      PathToGtags  = Path.join(packageRoot, 'vendor', "gtags-#{process.platform}-#{process.arch}")
      PathToGlobal = Path.join(packageRoot, 'vendor', "global-#{process.platform}-#{process.arch}")
      BuildCmdByOptions["--update"] = PathToGlobal
      BuildCmdByOptions["--sqlite3"] = PathToGtags
      #PathToGtags = "/usr/local/bin/gtags"
      #PathToGlobal = "/usr/local/bin/global"
  # Public
  getDefinitions: (symbolName, symbolFile="") ->
    return @_gtagsCommand("-ax", symbolName, Path.dirname(symbolFile))

  getReferences: (symbolName, symbolFile="") ->
    return @_gtagsCommand("-axr", symbolName, Path.dirname(symbolFile))

  getSymbolsOfFile: (path) ->
    return @_gtagsCommand("-axf", path, Path.dirname(path))

  singleFileUpdate: (path) ->
    return @_gtagsCommand("--single-update", path, Path.dirname(path))

  getCompletions: (prefix) ->
    return @_gtagsCommand("-axc", prefix)

  buildTags: (path, onCompleted=null) ->
    return @_buildTags("build", path, onCompleted)

  updateTags: (path, onCompleted=null) ->
    return @_buildTags("update", path, onCompleted)

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

  _gtagsCommand: (options, arg, cwd="") ->
    console.log "gtagsCommand, options: #{options}, arg: #{arg}, cwd: #{cwd}"
    result = []

    paths = atom.project.getPaths()
    envLib = ""

    if cwd is ""
      cwd = paths[0]

    for path in paths
      if cwd.indexOf(path) > -1
        cwd = path
      else
        envLib = Path.join(envLib, Path.delimiter, path)
    envLib = envLib.substr(1)

    spawnSync  = require("child_process").spawnSync
    console.log "execute global, opt: #{options}, arg: #{arg}, cwd: #{cwd}, lib: #{envLib}"
    global = spawnSync(PathToGlobal, [options, arg], {cwd:cwd, env:{"GTAGSLIBPATH":envLib}})
    # console.log global
    if global.error?
      status = {'error': {'title': "[Gtags] global not found", 'detail': global.error.toString()}}
      return {'symbols': [], 'status': status}

    if global.stdout.length is 0
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
      result.push({"symbol":s[1], "line":s[2], "path":s[3], "signature":s[4]})

    result.splice 0,0,
      "options":"#{options}"
      "filterKey":FilterKeyByOptions[options]
      "title":"[#{s[1]}]: #{symbols.length}"
      "project":"#{cwd}"

    return {'symbols': result, 'status': {}}

  _buildTags: (arg, path, onCompleted) ->
    if arg is "update"
      options = "--update"
      cmdOpt = "--update"
    else
      options = "--sqlite3"
      cmdOpt = "--sqlite3"
      if not atom.config.get('atom-gtags.useSqlite3Format')
        console.log "Using BSD/DB Format"
        cmdOpt = "--quiet"

    console.log "buildtags, arg: #{arg}, path: #{path}"
    cmdPath = BuildCmdByOptions[options]
    spawn = require("child_process").spawn
    cmd = spawn(cmdPath, [cmdOpt], {cwd:path})

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
