((root, factory) ->
  if typeof define is 'function' and define.amd
    define [], factory
  else if typeof module is 'object'
    module.exports = factory()
  else
    root.commify = factory()
) this, -> (something) ->
  # https://stackoverflow.com/a/2901298/2926055
  num = something.toString().trim()
  if m = num.match /^([+\-])?(\d+)(\.(\d+))?$/
    whole = m[2].replace /\B(?=(\d{3})+(?!\d))/g, "," 
    decimals = m[4]?.replace(/(\d{3})(?=\d)/g, (a,b) -> "#{b},") or ''
    decimals = ".#{decimals}" if decimals
    return [m[1] or '', whole, decimals].join('')
  else
    return num
