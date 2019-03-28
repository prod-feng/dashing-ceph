Batman.Filters.bytesNumber = (num) ->
  return num if isNaN(num)
  if num >= (1099511627800*1024*1024)
    (num / (1099511627800*1024*1024)).toFixed(1) + 'E'
  else if num >= (1099511627800*1024)
    (num /(1099511627800*1024)).toFixed(1) + 'P'
  else if num >= 1099511627800
    (num / 1099511627800).toFixed(1) + 'T'
  else if num >= 1073741824
    (num / 1073741824).toFixed(1) + 'G'
  else if num >= 1048576
    (num / 1048576).toFixed(1) + 'M'
  else if num >= 1024
    (num / 1024).toFixed(1) + 'K'
  else
    num

class Dashing.Meter extends Dashing.Widget

  @accessor 'value', Dashing.AnimatedValue

  constructor: ->
    super
    @observe 'value', (value) ->
      $(@node).find(".meter").val(value).trigger('change')

  ready: ->
    meter = $(@node).find(".meter")
    meter.attr("data-bgcolor", meter.css("background-color"))
    meter.attr("data-fgcolor", meter.css("color"))
    meter.knob()
