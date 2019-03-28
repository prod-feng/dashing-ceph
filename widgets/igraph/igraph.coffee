Batman.Filters.bytesNumber = (num) ->
  return num if isNaN(num)
  if num >= 1000000000000000000
    (num / 1000000000000000000).toFixed(1) + 'E'
  else if num >= 1000000000000000
    (num / 1000000000000000).toFixed(1) + 'P'
  else if num >= 1000000000000
    (num / 1000000000000).toFixed(1) + 'T'
  else if num >= 1000000000
    (num / 1000000000).toFixed(1) + 'G'
  else if num >= 1000000
    (num / 1000000).toFixed(1) + 'M'
  else if num >= 1000
    (num / 1000).toFixed(1) + 'K'
  else
    num

class Dashing.Igraph extends Dashing.Widget

  @accessor 'current', ->
    return @get('displayedValue') if @get('displayedValue')
    points = @get('ipoints')
    if points
      Batman.Filters.bytesNumber(points[0][points[0].length - 1].y) + ' / ' + Batman.Filters.bytesNumber(points[1][points[1].length - 1].y) 

  ready: ->
    container = $(@node).parent()
    # Gross hacks. Let's fix this.
    width = (Dashing.widget_base_dimensions[0] * container.data("sizex")) + Dashing.widget_margins[0] * 2 * (container.data("sizex") - 1)
    height = (Dashing.widget_base_dimensions[1] * container.data("sizey"))
    @graph = new Rickshaw.Graph(
      element: @node
      width: width
      height: height
      renderer: 'area'
      stroke: false
      series: [
        {
        color: "#fff",
        data: [{x:0, y:0}]
        },
        {
            color: "#222",
            data: [{x:0, y:0}]
        }
      ]
    )

    @graph.series[0].data = @get('ipoints') if @get('ipoints')

    x_axis = new Rickshaw.Graph.Axis.Time(graph: @graph)
    y_axis = new Rickshaw.Graph.Axis.Y(graph: @graph, tickFormat: Rickshaw.Fixtures.Number.formatKMBT)
    @graph.renderer.unstack = true
    @graph.render()

  onData: (data) ->
    if @graph
      @graph.series[0].data = data.ipoints[0]
      @graph.series[1].data = data.ipoints[1]
      @graph.render()
