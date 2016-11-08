React = require 'react'
{IndexLink, Link} = require 'react-router'
PackageList = require '../components/PackageList'
StickyButton = require '../components/StickyButton'
Footer = require '../components/Footer'

class Main extends React.Component
  componentDidMount: ->
  render: ->
    <div>
      <div className="ui top fixed inverted menu">
          <div className="header item" style={WebkitAppRegion: "drag"}>
            VoiceCode
          </div>
          <div className="right menu">
            <IndexLink to="/" className="item" activeClassName="active">Log</IndexLink>
            <Link to="/commands" className="item" activeClassName="active">Commands</Link>
            <Link to="/packages" className="item" activeClassName="active">Packages</Link>
            <StickyButton/>
          </div>
      </div>
      <div className='mainBody'>
        {@props.children}
      </div>
      <Footer/>
    </div>

module.exports = Main
