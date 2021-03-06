# SOURCE: http://bl.ocks.org/fabiovalse/d784198bdc1c76221393
$(document).ready ->
  try
    getColor = (type) ->
      switch type
        when 'keyword' then '#ff3300'
        when 'person' then '#0033cc'
        when 'link' then '#9900cc'
        when 'subject' then '#66ffff'
        when 'article' then '#009933'
        when 'project' then '#ff9900'
        when 'university' then '#663300'
        else '#ffffff'

    getParams = ->
      query = window.location.search.substring(1)
      raw_vars = query.split("&")

      params = {}

      for v in raw_vars
        [key, val] = v.split("=")
        params[key] = decodeURIComponent(val)

      params

    margin = 
      top: 20
      right: 120
      bottom: 20
      left: 120
    width = 960 - (margin.right) - (margin.left)
    height = 800 - (margin.top) - (margin.bottom)
    i = 0
    duration = 750
    root = undefined
    tree = d3.layout.tree().size([
      height
      width
    ])
    diagonal = d3.svg.diagonal().projection((d) ->
      [
        d.y
        d.x
      ]
    )
    svg = d3.select('div#datagraph').append('svg').attr('width', width + margin.right + margin.left).attr('height', height + margin.top + margin.bottom).append('g').attr('transform', 'translate(' + margin.left + ',' + margin.top + ')')

    update = (source) ->
      # Compute the new tree layout.
      nodes = tree.nodes(root).reverse()
      links = tree.links(nodes)
      # Normalize for fixed-depth.
      nodes.forEach (d) ->
        d.y = d.depth * 180
        return
      # Update the nodes…
      node = svg.selectAll('g.node').data(nodes, (d) ->
        d.id or (d.id = ++i)
      )
      # Enter any new nodes at the parent's previous position.
      nodeEnter = node.enter().append('g').attr('class', 'node').attr('transform', (d) ->
        'translate(' + source.y0 + ',' + source.x0 + ')'
      ).on('click', click)
      nodeEnter.append('circle').attr('r', 1e-6).style 'fill', (d) ->
        getColor d.type
      nodeEnter.append('text').attr('x', (d) ->
        if d.children or d._children then -10 else 10
      ).attr('dy', '.35em').attr('text-anchor', (d) ->
        if d.children or d._children then 'end' else 'start'
      ).text((d) ->
        d.name
      ).style 'fill-opacity', 1e-6
      # Transition nodes to their new position.
      nodeUpdate = node.transition().duration(duration).attr('transform', (d) ->
        'translate(' + d.y + ',' + d.x + ')'
      )
      nodeUpdate.select('circle').attr('r', 4.5).style 'fill', (d) ->
        getColor d.type
      nodeUpdate.select('text').style 'fill-opacity', 1
      # Transition exiting nodes to the parent's new position.
      nodeExit = node.exit().transition().duration(duration).attr('transform', (d) ->
        'translate(' + source.y + ',' + source.x + ')'
      ).remove()
      nodeExit.select('circle').attr 'r', 1e-6
      nodeExit.select('text').style 'fill-opacity', 1e-6
      # Update the links…
      link = svg.selectAll('path.link').data(links, (d) ->
        d.target.id
      )
      # Enter any new links at the parent's previous position.
      link.enter().insert('path', 'g').attr('class', 'link').attr 'd', (d) ->
        o = 
          x: source.x0
          y: source.y0
        diagonal
          source: o
          target: o
      # Transition links to their new position.
      link.transition().duration(duration).attr 'd', diagonal
      # Transition exiting nodes to the parent's new position.
      link.exit().transition().duration(duration).attr('d', (d) ->
        o = 
          x: source.x
          y: source.y
        diagonal
          source: o
          target: o
      ).remove()
      # Stash the old positions for transition.
      nodes.forEach (d) ->
        d.x0 = d.x
        d.y0 = d.y
        return
      return

    # Toggle children on click.

    click = (d) ->
      if d.children
        d._children = d.children
        d.children = null
      else
        d.children = d._children
        d._children = null
      update d
      return

    d3.json "/#{getParams().keyword.replace /\+/, '_'}_data.json", (error, flare) ->

      collapse = (d) ->
        if d.children
          d._children = d.children
          d._children.forEach collapse
          d.children = null
        return

      root = flare
      root.x0 = height / 2
      root.y0 = 0
      root.children.forEach collapse
      update root
      return
    d3.select(self.frameElement).style 'height', '800px'
  catch _e
    console.log 'some error in d3'
