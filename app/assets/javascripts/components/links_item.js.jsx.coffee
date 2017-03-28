{li, a} = React.DOM

class @LinksItem extends React.Component
  constructor: (props) ->
    super props

  render: ->
    li {},
      a {href: @props.link.url}, @props.link.title

