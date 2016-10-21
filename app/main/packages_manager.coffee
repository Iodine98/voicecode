http = require 'http'
git = require 'gitty'
fs = require 'fs-extra'
npm = require 'npm'

class PackagesManager
  constructor: ->
    @packagePath = AssetsController.assetsPath + "/packages/"
    @getPackageRegistry()
    Events.on 'installPackage', @installPackage.bind(@)
    Events.on 'updatePackage', @updatePackage.bind(@)
    Events.on 'removePackage', @removePackage.bind(@)
    Events.on 'packageRepoUpdated', ({pack}) => @fetch pack
    Events.on 'willCreatePackage', (options) =>
      # attaching repository to soon-to-register-itself package
      options.repo = @registry?.all[options.name]
      options
    Events.once 'packageAssetsLoaded', =>
      # register all non-installed packages
      _.each @registry.all, ({repo, description}, name) ->
        pack = Packages.get name
        pack ?= Packages.register {
          name,
          description,
          installed: false,
        }
        true
    Events.once 'userAssetsLoaded', @fetchAll.bind(@)

  installPackage: (name, callback) ->
    callback ?= ->
    repo = @registry.all[name].repo
    safeName = _.snakeCase name
    destination = AssetsController.assetsPath + "/packages/#{safeName}"
    temporary = "/tmp/voicecode/packages/#{Date.now()}/#{safeName}"
    # skip it if it exists
    if fs.existsSync(destination)
      emit 'packageDestinationFolderExists', destination
      return callback null, true
    emit 'installingPackageFolder', name, destination
    Packages.remove name
    callback = _.wrap callback, (callback, err) ->
      callback.apply @, _.toArray(arguments)[1..]
      if err
        return error 'packageRepoInstallError', err, err.message
      emit 'packageRepoInstalled', {repo: destination, pack: name}
    git.clone temporary, repo, (err) ->
      if err
        return callback err
      npmCommand = '/usr/local/bin/node ' +
       projectRoot + '/node_modules/npm/bin/npm-cli.js'
      npmSettings = [
        "npm_config_target=#{process.versions.electron}"
        'npm_config_arch=x64'
        'npm_config_disturl=https://atom.io/download/atom-shell'
        'npm_config_runtime=electron'
        'npm_config_build_from_source=true'
        'HOME=~/.electron-gyp'
      ].join ' '
      Execute "#{npmSettings} mkdir -p #{temporary}/node_modules " +
       "&& #{npmCommand} install --silent --prefix " +
      temporary + " && mv #{temporary} #{destination}"
      , (err) ->
        if err
          return callback err
        callback null, true

  getPackageRegistry: (callback) ->
    callback ?= (err) ->
      if err
        return error 'packagesManagerRegistryError'
        , err, "Failed retrieving package registry: #{err.message}"
    return callback(null, @registry) if @registry?
    http.get(
      host: 'updates.voicecode.io'
      path: '/packages/registry/raw/master/packages.json'
    , (response) =>
      data = ''
      response.setEncoding 'utf8'
      response.on 'data', (chunk) ->
        data += chunk
      response.on 'end', =>
        registry = JSON.parse data
        if _.isObject registry
          @registry = registry
          callback null, @registry
        else
          callback
            message: 'malformed response'
            data: data
      response.resume()
    ).on('error', (e) ->
      callback e
    )

  downloadBasePackages: (callback) ->
    @downloadPackageGroup 'base', callback
  downloadRecommendedPackages: (callback) ->
    @downloadPackageGroup 'recommended', callback

  downloadPackageGroup: (group, callback) ->
    @getPackageRegistry (err, registry) =>
      return callback(err) if err?
      funk = asyncblock.nostack
      if developmentMode
        funk = asyncblock
      funk (cloneFlow) =>
        _.every registry[group], (name) =>
          @installPackage name, cloneFlow.add()
          true
        cloneFlow.wait()
        callback null, true

  installAllPackages: ->
    _.every @registry.all, (info, name) ->
      emit 'installPackage', name
      true

  getInstalled: ->
    return @installed if @installed?
    @installed = fs.readdirSync @packagePath
    @installed = _.reject @installed, (repo) -> repo.match /\..*/

  updatePackage: (name) ->
    git("#{@packagePath}#{name}").pull 'origin', 'master', (err) =>
      if err
        error 'packageRepoUpdateError'
        , {repo: "#{@packagePath}#{name}", pack: name, err}
        , "Failed to update package: #{name}"
      else
        emit 'packageRepoUpdated'
        , {repo: "#{@packagePath}#{name}", pack: name}

  removePackage: (name) ->
    if name in @registry.base
      return emit 'packageRequired', {name}
    fs.remove AssetsController.assetsPath + "/packages/#{name}/"
    , (err) ->
      if err
        return error 'removePackageFailed', err, err.message
      else
        log 'packageRemoved', name, "Package removed: #{name}"

  fetch: (repoName) ->
    repo = git("#{@packagePath}#{repoName}")
    repo.fetch 'origin'
    , (err, result) =>
      if err
        return error 'packagesManagerFetchError'
        , repo, "Failed to fetch #{repoName} repository8"
      repo.status (err, status) =>
        emit 'packageRepoStatusUpdated'
        , {repoName, status}
        if status.behind
          @log repoName

  log: (repoName) ->
    repo = git("#{@packagePath}#{repoName}")
    repo.log 'origin/master...'
    , (err, log) ->
      if err
        return error 'packagesManagerLogError'
        , repo, "Failed to Log #{repoName} repository8"
      emit 'packageRepoLogUpdated'
      , {repoName, log}

  fetchAll: ->
    installed = @getInstalled()
    _.each installed, (repoName) =>
      @fetch repoName


module.exports = new PackagesManager
