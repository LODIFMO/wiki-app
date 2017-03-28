{div, ul} = React.DOM

class @Links extends React.Component
  constructor: (props) ->
    super props
  
  render: ->
    LinksItem = React.createFactory(window.LinksItem)
    temp = ''
    div className: 'panel panel-default',
      div className: 'panel-heading',
        div {className: 'panel-title'}, 'Links'
      div className: 'panel-body',
        ul {},
          @props.links.map((item, index) =>
            if temp != item.title
              temp = item.title
              LinksItem link: item, key: index
          )
