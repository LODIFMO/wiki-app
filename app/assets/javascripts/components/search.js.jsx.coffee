{form, input, div} = React.DOM

class @Search extends React.Component
  constructor: (props) ->
    super props
    @state =
      keyword: ''
  
  handleChange: (e) ->
    @setState(keyword: e.target.value)

  handleSubmit: (e) ->
    e.preventDefault()
    console.log encodeURI(@state.keyword)
    window.location.href = "/pages/show?keyword=#{encodeURI(@state.keyword)}"

  render: ->
    div {},
      form {className: 'navbar-form navbar-right', onSubmit: ((e) => @handleSubmit(e))},
        input {
          className: 'form-control',
          placeholder: 'Search...',
          type: 'text',
          onChange: ((e) => @handleChange(e))},
