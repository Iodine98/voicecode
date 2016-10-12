React = require 'react'
ReactDOM = require 'react-dom'
window.Remote = require('electron').remote
_events = Remote.getGlobal 'Events'
window.emit = _events._emit
window.Events = {on: _events.frontendOn}
{Provider} = require 'react-redux'
{Router, hashHistory} = require 'react-router'
{syncHistoryWithStore} = require 'react-router-redux'
routes = require './routes/main'
Main = require './containers/Main'
window.store = require './stores/main'
history = syncHistoryWithStore hashHistory, store,
  selectLocationState: do ->
    previousRouterState = null
    previousRouterStateJS = null
    (state) ->
      routerState = state.get 'router'
      if previousRouterState isnt routerState
        previousRouterState = routerState
        previousRouterStateJS = routerState.toJS()
      previousRouterStateJS


subscribeToRemoteEvents = ->
  events =
    'apiCreated': 'createApi'
    'packageCreated': 'createPackage'
    'packageUpdated': 'updatePackage'
    'packageRemoved': 'removePackage'
    'commandCreated': 'createCommand'
    'commandEnabled': 'enableCommand'
    'commandDisabled': 'disableCommand'
    'implementationCreated': 'createImplementation'
    'startupComplete': 'appStart'
    'setPackageFilter': 'setPackageFilter'
    'setCommandFilter': 'setCommandFilter'
    'setCurrentFilter': 'setCurrentFilter'
    'changePage': 'changePage'
    'logger': 'createLogEntry'
    'toggleStickyWindow': 'setStickyWindow'
    'logEvents': 'setLogEvents'
    'radioSilence': 'setRadioSilence'
    'commandSpokenChanged': 'changeSpoken'
    'updateDownloaded': 'setUpdateAvailable'
    'restartNeeded': 'setRestartNeeded'
  _.each events, (handler, event) ->
    Events.on event, _.partial _.invoke, store, "actions.#{handler}"

subscribeToRemoteEvents()


ReactDOM.render(
  <Provider store={store}>
    <Router history={history} routes={routes}/>
  </Provider>
, document.getElementById('root'))
