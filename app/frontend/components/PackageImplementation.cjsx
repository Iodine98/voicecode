React = require 'react'
{ connect } = require 'react-redux'
classNames = require 'classnames'
{implementationSelector} = require '../selectors'

mapStateToProps = (state, props) ->
  implementation: implementationSelector state, props

mapDispatchToProps = {} # maybe add a "reveal command" action

class PackageImplementation extends React.Component
  shouldComponentUpdate: (nextProps, nextState) ->
    false

  render: ->
    {id, scope, originalPackageId, commandId} = @props.implementation.toJS()
    <div className="item">
      <div className="content">
        <div className="header">
          <i className='small grey cubes icon'></i>
          { commandId }
          {' '}
          <div className="ui blue horizontal label small">{ '@' + scope }</div>
        </div>
      </div>
    </div>

module.exports = connect(mapStateToProps)(PackageImplementation)
