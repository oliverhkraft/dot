-- Window management hotkeys (Rectangle-style)

local hyper = {"ctrl", "alt"}
local hyperShift = {"ctrl", "alt", "shift"}

local function focused()
  return hs.window.focusedWindow()
end

local function screenFrame(win)
  return win:screen():frame()
end

local function setFrame(win, f)
  -- Round to whole numbers to avoid blurry edges
  f.x = math.floor(f.x)
  f.y = math.floor(f.y)
  f.w = math.floor(f.w)
  f.h = math.floor(f.h)
  win:setFrame(f)
end

local function leftHalf()
  local win = focused() if not win then return end
  local f = screenFrame(win)
  setFrame(win, {x = f.x, y = f.y, w = f.w / 2, h = f.h})
end

local function rightHalf()
  local win = focused() if not win then return end
  local f = screenFrame(win)
  setFrame(win, {x = f.x + f.w / 2, y = f.y, w = f.w / 2, h = f.h})
end

local function centerHalf()
  local win = focused() if not win then return end
  local f = screenFrame(win)
  local w = f.w / 2
  setFrame(win, {x = f.x + (f.w - w) / 2, y = f.y, w = w, h = f.h})
end

local function topHalf()
  local win = focused() if not win then return end
  local f = screenFrame(win)
  setFrame(win, {x = f.x, y = f.y, w = f.w, h = f.h / 2})
end

local function bottomHalf()
  local win = focused() if not win then return end
  local f = screenFrame(win)
  setFrame(win, {x = f.x, y = f.y + f.h / 2, w = f.w, h = f.h / 2})
end

local function topLeft()
  local win = focused() if not win then return end
  local f = screenFrame(win)
  setFrame(win, {x = f.x, y = f.y, w = f.w / 2, h = f.h / 2})
end

local function topRight()
  local win = focused() if not win then return end
  local f = screenFrame(win)
  setFrame(win, {x = f.x + f.w / 2, y = f.y, w = f.w / 2, h = f.h / 2})
end

local function bottomLeft()
  local win = focused() if not win then return end
  local f = screenFrame(win)
  setFrame(win, {x = f.x, y = f.y + f.h / 2, w = f.w / 2, h = f.h / 2})
end

local function bottomRight()
  local win = focused() if not win then return end
  local f = screenFrame(win)
  setFrame(win, {x = f.x + f.w / 2, y = f.y + f.h / 2, w = f.w / 2, h = f.h / 2})
end

local function firstThird()
  local win = focused() if not win then return end
  local f = screenFrame(win)
  local w = f.w / 3
  setFrame(win, {x = f.x, y = f.y, w = w, h = f.h})
end

local function centerThird()
  local win = focused() if not win then return end
  local f = screenFrame(win)
  local w = f.w / 3
  setFrame(win, {x = f.x + w, y = f.y, w = w, h = f.h})
end

local function lastThird()
  local win = focused() if not win then return end
  local f = screenFrame(win)
  local w = f.w / 3
  setFrame(win, {x = f.x + 2 * w, y = f.y, w = w, h = f.h})
end

local function firstTwoThirds()
  local win = focused() if not win then return end
  local f = screenFrame(win)
  local w = (f.w / 3) * 2
  setFrame(win, {x = f.x, y = f.y, w = w, h = f.h})
end

local function centerTwoThirds()
  local win = focused() if not win then return end
  local f = screenFrame(win)
  local w = (f.w / 3) * 2
  setFrame(win, {x = f.x + (f.w - w) / 2, y = f.y, w = w, h = f.h})
end

local function lastTwoThirds()
  local win = focused() if not win then return end
  local f = screenFrame(win)
  local w = (f.w / 3) * 2
  setFrame(win, {x = f.x + f.w / 3, y = f.y, w = w, h = f.h})
end

local function maximize()
  local win = focused() if not win then return end
  setFrame(win, screenFrame(win))
end

local function almostMaximize()
  local win = focused() if not win then return end
  local f = screenFrame(win)
  local scale = 0.9
  local w = f.w * scale
  local h = f.h * scale
  setFrame(win, {x = f.x + (f.w - w) / 2, y = f.y + (f.h - h) / 2, w = w, h = h})
end

local function maximizeHeight()
  local win = focused() if not win then return end
  local f = screenFrame(win)
  local wf = win:frame()
  local w = math.min(wf.w, f.w)
  local x = math.max(f.x, math.min(wf.x, f.x + f.w - w))
  setFrame(win, {x = x, y = f.y, w = w, h = f.h})
end

-- Bindings (match the screenshot)
hs.hotkey.bind(hyper, "Left", leftHalf)
hs.hotkey.bind(hyper, "Right", rightHalf)
hs.hotkey.bind(hyper, "C", centerHalf)
hs.hotkey.bind(hyper, "Up", topHalf)
hs.hotkey.bind(hyper, "Down", bottomHalf)

hs.hotkey.bind(hyper, "U", topLeft)
hs.hotkey.bind(hyper, "I", topRight)
hs.hotkey.bind(hyper, "J", bottomLeft)
hs.hotkey.bind(hyper, "K", bottomRight)

hs.hotkey.bind(hyper, "D", firstThird)
hs.hotkey.bind(hyper, "F", centerThird)
hs.hotkey.bind(hyper, "G", lastThird)

hs.hotkey.bind(hyper, "E", firstTwoThirds)
hs.hotkey.bind(hyper, "T", centerTwoThirds)
hs.hotkey.bind(hyper, "Y", lastTwoThirds)

hs.hotkey.bind(hyper, "return", maximize)
hs.hotkey.bind(hyper, "'", almostMaximize)
hs.hotkey.bind(hyperShift, "Up", maximizeHeight)

-- Auto-reload config
hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon", hs.reload):start()
hs.alert.show("Hammerspoon loaded")
