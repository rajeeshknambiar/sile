local breakFrameVertical = function(after)
  local cFrame = SILE.typesetter.frame
  if after then
    totalHeight = after
  else
    totalHeight = 0
    SILE.typesetter:leaveHmode(1)    
    local q = SILE.typesetter.state.outputQueue
    for i=1,#q do
      totalHeight = totalHeight + q[i].height + q[i].depth
    end
    SILE.typesetter:chuck()
  end

  if type(totalHeight) == "table" then totalHeight= totalHeight.length end

  local newFrame = SILE.newFrame({ 
    bottom = cFrame:bottom(), 
    left = cFrame:left(), 
    right = cFrame:right(),
    next = cFrame.next,
    previous = cFrame,
    id = cFrame.id .. "'"
  })

  cFrame._height = totalHeight
  cFrame.next = newFrame.id
  SILE.documentState.thisPageTemplate.frames[newFrame.id] = newFrame

  newFrame._top = cFrame:top() + totalHeight
  if (after) then
    SILE.typesetter:initFrame(cFrame)
  else
    SILE.typesetter:initFrame(newFrame)
  end
  -- SILE.outputter:debugFrame(cFrame)
  -- SILE.outputter:debugFrame(newFrame)
end

local breakFrameHorizontalAt = function (offset)
  local cFrame = SILE.typesetter.frame
  local newFrame = SILE.newFrame({ 
    bottom = cFrame:bottom(),
    top = cFrame:top(),
    left = cFrame:left() + offset,
    right = cFrame:right(),
    next = cFrame.next,
    previous = cFrame,
    id = cFrame.id .. "'"
  })
  local oldLeft = cFrame:left()
  cFrame.left = (function() return oldLeft end)
  cFrame.right = (function() return oldLeft + offset end)
  -- SILE.outputter:debugFrame(cFrame)
  -- SILE.outputter:debugFrame(newFrame)
  SILE.typesetter:initFrame(newFrame)
end

local shiftframeedge = function(frame, options)
  if options.left then 
    local oldLeft = frame.left
    frame.left = function()
      return oldLeft(frame) + SILE.length.parse(options.left).length
    end
  end
  if options.right then 
    local oldRight = frame.right
    frame.right = function()
      return oldRight(frame) + SILE.length.parse(options.right).length
    end
  end
end

SILE.registerCommand("shiftframeedge", function(options, content)
  local cFrame = SILE.typesetter.frame
  shiftframeedge(cFrame, options)
  SILE.typesetter:initFrame(cFrame)
  --SILE.outputter:debugFrame(cFrame)
end)

SILE.registerCommand("breakframevertical", function ( options, content )
  breakFrameVertical()
end)

SILE.registerCommand("breakframehorizontal", function ( options, content )
  breakFrameHorizontalAt(SILE.length.parse(options.offset).length)
end)

SILE.registerCommand("dropcap", function(options, content)
  SILE.settings.set("current.parindent", SILE.nodefactory.zeroGlue)
  local hbox = SILE.Commands["hbox"]({}, content)
  table.remove(SILE.typesetter.state.nodes) -- steal it back
  local t = {}
  t[1] = hbox
  local boundary = hbox.width.length + SILE.length.parse(options.rightboundary).length
  breakFrameHorizontalAt(boundary)
  SILE.typesetNaturally(SILE.typesetter.frame.previous, t)
  local undoSkip = SILE.length.new({}) - SILE.settings.get("document.baselineskip").height.length + SILE.length.parse("1ex")
  undoSkip.stretch = hbox.height
  SILE.typesetter:pushHbox({value = {}})
  SILE.typesetter:pushVglue({height = undoSkip })
  breakFrameVertical(hbox.height + SILE.length.parse(options.bottomboundary).length)
  shiftframeedge(SILE.getFrame(SILE.typesetter.frame.next), {left = ""..(SILE.length.new() - boundary)})
  --SILE.outputter:debugFrame(SILE.typesetter.frame)
  SILE.settings.set("current.parindent", SILE.settings.get("document.parindent"))
end)

return {
  init = function () end,
  exports = {
    breakFrameVertical = breakFrameVertical
  }
}