local addonName = ...
BINDING_HEADER_RADIALEMOTES = "RadialEmotes"
BINDING_NAME_TOGGLEEMOTEWHEEL = "Hold Emote Wheel"
local MAX_PAGE_SIZE = 12
local RADIUS = 190
local CENTER_X, CENTER_Y = 0, 0
local DEFAULTS = {
    scale = 1,
    pageSize = 8,
    showTarget = true,
    closeAfterSelect = false,
    mouseWheelPaging = true,
}

local emoteTokens = {
    "agree", "amaze", "angry", "apologize", "applaud", "bark", "bashful", "beckon",
    "beg", "bite", "bleed", "blink", "blush", "bonk", "bored", "bounce", "bow",
    "brb", "burp", "bye", "cackle", "calm", "cat", "challenge", "charge", "cheer",
    "chew", "chicken", "chuckle", "clap", "cold", "comfort", "commend", "confused",
    "congratulate", "cough", "coverears", "cower", "crack", "cringe", "cry", "cuddle",
    "curious", "curtsey", "dance", "ding", "disagree", "doom", "drink", "drool", "duck",
    "eat", "excited", "eye", "facepalm", "faint", "fart", "fidget", "flee", "flex",
    "flirt", "flop", "followme", "food", "frown", "gasp", "gaze", "giggle", "glad",
    "glare", "gloat", "go", "goodbye", "greet", "grin", "groan", "grovel", "growl",
    "guffaw", "hail", "happy", "hello", "helpme", "hug", "hungry", "insult", "introduce",
    "jealous", "jk", "kiss", "kneel", "laugh", "lavish", "lick", "listen", "lost", "love",
    "massage", "meow", "moan", "mock", "moo", "moon", "mourn", "no", "nod", "nosepick",
    "oom", "openfire", "panic", "pat", "peer", "pity", "plead", "point", "poke", "ponder",
    "pounce", "praise", "proud", "puke", "punch", "pout", "puzzled", "raise", "ready",
    "roar", "rofl", "rolleyes", "rude", "salute", "scared", "scratch", "sexy", "shake",
    "shimmy", "shiver", "shoo", "shrug", "shy", "sigh", "silly", "sing", "slap", "sleep",
    "smell", "smile", "smirk", "snarl", "snicker", "sniff", "snub", "soothe", "sorry",
    "spit", "strong", "strut", "surprised", "surrender", "sweat", "talk", "talkex", "tap",
    "taunt", "tease", "thank", "thirsty", "threaten", "tired", "truce", "twiddle", "veto",
    "victory", "violin", "wait", "wave", "welcome", "whine", "whistle", "work", "yawn", "yes",
    "tickle", "train", "golfclap", "highfive", "mountspecial", "peon",
}

-- Some client builds expose the complete localized emote token table. Include it
-- when available so the wheel follows Forever's own emote set automatically.
for i = 1, 500 do
    local token = _G["EMOTE" .. i .. "_TOKEN"]
    if type(token) == "string" and token ~= "" then
        emoteTokens[#emoteTokens + 1] = token
    end
end

-- Remove accidental leading/trailing whitespace and duplicates while preserving order.
local emotes, seen = {}, {}
for _, token in ipairs(emoteTokens) do
    token = token:match("^%s*(.-)%s*$"):lower()
    if token ~= "" and not seen[token] then
        seen[token] = true
        emotes[#emotes + 1] = token
    end
end

local wheel, page = nil, 1
local combatCloseController
local buttons = {}
local wheelKeyHeld = false
local settingsCategory
local settingsPending

local function EnsureDB()
    if type(EmoteWheelForeverDB) ~= "table" then EmoteWheelForeverDB = {} end
    for key, value in pairs(DEFAULTS) do
        if EmoteWheelForeverDB[key] == nil then
            EmoteWheelForeverDB[key] = value
        end
    end
end

local function PageSize()
    return math.max(6, math.min(MAX_PAGE_SIZE, tonumber(EmoteWheelForeverDB.pageSize) or DEFAULTS.pageSize))
end

local function makeLabel(token)
    return token:gsub("^%l", string.upper):gsub("(%l)(%u)", "%1 %2")
end

local function updatePage()
    -- Secure action attributes and protected button visibility are locked in combat.
    if InCombatLockdown and InCombatLockdown() then return end
    local perPage = PageSize()
    local pages = math.max(1, math.ceil(#emotes / perPage))
    page = math.max(1, math.min(page, pages))
    wheel.selectionText:SetText("CLICK AN EMOTE  ·  SCROLL TO BROWSE")
    for i, button in ipairs(buttons) do
        local index = (page - 1) * perPage + i
        local token = i <= perPage and emotes[index] or nil
        if token then
            local angle = math.rad(90 - (i - 1) * (360 / perPage))
            button:ClearAllPoints()
            button:SetPoint("CENTER", wheel, "CENTER", CENTER_X + math.cos(angle) * RADIUS, CENTER_Y + math.sin(angle) * RADIUS)
            local width = perPage > 8 and 82 or 100
            button:SetSize(width, 46)
            button.label:SetText(makeLabel(token))
            button.label:SetWidth(width - 10)
            button.token = token
            button:SetAttribute("type", "macro")
            button:SetAttribute("macrotext", "/" .. token)
            button:SetAttribute("type1", "macro")
            button:SetAttribute("macrotext1", "/" .. token)
            button:Show()
        else
            button:Hide()
        end
    end
    wheel.pageText:SetText((page .. " / " .. pages))
    wheel.prev:SetEnabled(page > 1)
    wheel.next:SetEnabled(page < pages)
end

local function createWheel()
    wheel = CreateFrame("Frame", "RadialEmotesFrame", UIParent, "BackdropTemplate")
    wheel:SetSize(540, 540)
    wheel:SetPoint("CENTER")
    wheel:SetFrameStrata("DIALOG")
    wheel:SetFrameLevel(100)
    wheel:EnableMouse(true)
    wheel:EnableMouseWheel(true)
    wheel:SetClampedToScreen(true)

    wheel.backdropTexture = wheel:CreateTexture(nil, "BACKGROUND")
    wheel.backdropTexture:SetTexture("Interface\\AddOns\\RadialEmotes\\WheelBackdrop")
    wheel.backdropTexture:SetSize(540, 540)
    wheel.backdropTexture:SetPoint("CENTER")

    wheel:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then self:Hide() end
    end)
    wheel:SetScript("OnMouseWheel", function(_, delta)
        if not EmoteWheelForeverDB.mouseWheelPaging then return end
        if InCombatLockdown and InCombatLockdown() then return end
        page = page + (delta > 0 and -1 or 1)
        updatePage()
    end)
    wheel:EnableKeyboard(true)

    wheel.title = wheel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    wheel.title:SetPoint("TOP", 0, -12)
    wheel.title:SetText("RADIALEMOTES")
    wheel.title:SetTextColor(0.78, 0.92, 1)

    wheel.subtitle = wheel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    wheel.subtitle:SetPoint("TOP", wheel.title, "BOTTOM", 0, -3)
    wheel.subtitle:SetText("HOLD YOUR KEY  ·  SCROLL TO BROWSE")

    -- Center target medallion, echoing the focal point of WoW's ping wheel.
    wheel.targetPanel = CreateFrame("Frame", nil, wheel, "BackdropTemplate")
    wheel.targetPanel:SetSize(160, 160)
    wheel.targetPanel:SetPoint("CENTER")
    wheel.targetPanel:SetFrameLevel(wheel:GetFrameLevel() + 1)
    wheel.targetPanel.backdropTexture = wheel.targetPanel:CreateTexture(nil, "BACKGROUND")
    wheel.targetPanel.backdropTexture:SetTexture("Interface\\AddOns\\RadialEmotes\\TargetMedallion")
    wheel.targetPanel.backdropTexture:SetAllPoints()

    wheel.targetPortrait = wheel.targetPanel:CreateTexture(nil, "ARTWORK")
    wheel.targetPortrait:SetSize(56, 56)
    wheel.targetPortrait:SetPoint("TOP", 0, -22)

    wheel.targetCaption = wheel.targetPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    wheel.targetCaption:SetPoint("TOP", wheel.targetPortrait, "BOTTOM", 0, -5)
    wheel.targetCaption:SetText("TARGET")
    wheel.targetCaption:SetTextColor(0.45, 0.78, 0.9)

    wheel.targetName = wheel.targetPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    wheel.targetName:SetPoint("TOP", wheel.targetCaption, "BOTTOM", 0, -4)
    wheel.targetName:SetWidth(136)
    wheel.targetName:SetHeight(34)
    wheel.targetName:SetWordWrap(true)
    wheel.targetName:SetJustifyH("CENTER")

    wheel.targetHint = wheel.targetPanel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    wheel.targetHint:SetPoint("BOTTOM", 0, 13)
    wheel.targetHint:SetText("CURRENT TARGET")

    local function refreshTarget()
        if UnitExists and UnitExists("target") then
            if SetPortraitTexture then SetPortraitTexture(wheel.targetPortrait, "target") end
            local name, realm = UnitName("target")
            if name and realm and realm ~= "" then name = name .. "-" .. realm end
            wheel.targetName:SetText(name or "Unknown")
            wheel.targetName:SetTextColor(1, 1, 1)
        else
            wheel.targetPortrait:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            wheel.targetName:SetText("No target")
            wheel.targetName:SetTextColor(0.65, 0.72, 0.78)
        end
    end
    wheel:SetScript("OnShow", refreshTarget)
    wheel:RegisterEvent("PLAYER_TARGET_CHANGED")
    wheel:SetScript("OnEvent", refreshTarget)

    wheel.pageText = wheel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    wheel.pageText:SetPoint("BOTTOM", 0, 31)
    wheel.pageText:SetTextColor(0.45, 0.75, 0.88)

    wheel.selectionText = wheel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    wheel.selectionText:SetPoint("TOP", wheel.targetPanel, "BOTTOM", 0, -13)
    wheel.selectionText:SetTextColor(0.55, 0.85, 0.95)
    wheel.selectionText:SetText("CLICK AN EMOTE  ·  SCROLL TO BROWSE")

    wheel.prev = CreateFrame("Button", nil, wheel, "UIPanelButtonTemplate")
    wheel.prev:SetSize(88, 26)
    wheel.prev:SetPoint("BOTTOM", -56, 28)
    wheel.prev:SetText("‹ PREV")
    wheel.prev:SetScript("OnClick", function()
        if InCombatLockdown and InCombatLockdown() then return end
        page = page - 1
        updatePage()
    end)

    wheel.next = CreateFrame("Button", nil, wheel, "UIPanelButtonTemplate")
    wheel.next:SetSize(88, 26)
    wheel.next:SetPoint("BOTTOM", 56, 28)
    wheel.next:SetText("NEXT ›")
    wheel.next:SetScript("OnClick", function()
        if InCombatLockdown and InCombatLockdown() then return end
        page = page + 1
        updatePage()
    end)

    for i = 1, MAX_PAGE_SIZE do
        local button = CreateFrame("Button", nil, wheel, "SecureActionButtonTemplate,BackdropTemplate")
        button:SetSize(100, 48)
        button:SetFrameLevel(wheel:GetFrameLevel() + 2)
        button:EnableMouse(true)
        button:RegisterForClicks("LeftButtonDown", "LeftButtonUp")
        -- Fire as soon as the emote is pressed, so selecting does not require
        -- holding the mouse button and dragging the camera.
        button:SetAttribute("useOnKeyDown", true)
        button:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
        button:SetBackdropColor(0.045, 0.075, 0.1, 0.96)
        button:SetBackdropBorderColor(0.25, 0.42, 0.52, 0.9)
        button.label = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        button.label:SetPoint("CENTER")
        button.label:SetWidth(92)
        button.label:SetWordWrap(false)
        button:SetScript("OnEnter", function(self)
            self:SetBackdropColor(0.08, 0.35, 0.46, 1)
            self:SetBackdropBorderColor(0.35, 0.85, 1, 1)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText("/" .. self.token, 1, 0.82, 0.25)
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", function(self)
            self:SetBackdropColor(0.045, 0.075, 0.1, 0.96)
            self:SetBackdropBorderColor(0.25, 0.42, 0.52, 0.9)
            GameTooltip:Hide()
        end)
        button:SetScript("PostClick", function(_, _, down)
            if down and EmoteWheelForeverDB.closeAfterSelect and not (InCombatLockdown and InCombatLockdown()) then
                wheel:Hide()
            end
        end)
        buttons[i] = button
    end

    wheel:Hide()
    updatePage()

    -- A protected emote button makes the wheel's parent protected too. A
    -- normal key-up callback cannot hide it after combat starts, so close it
    -- from a secure state driver as soon as the client enters combat.
    if not combatCloseController and RegisterStateDriver and SecureHandlerSetFrameRef then
        combatCloseController = CreateFrame("Frame", "RadialEmotesCombatController", UIParent, "SecureHandlerStateTemplate")
        SecureHandlerSetFrameRef(combatCloseController, "wheel", wheel)
        combatCloseController:SetAttribute("_onstate-combat", [[
            if newstate == "1" then
                local wheel = self:GetFrameRef("wheel")
                if wheel then wheel:Hide() end
            end
        ]])
        RegisterStateDriver(combatCloseController, "combat", "[combat] 1; 0")
    end
end

function RadialEmotes_Toggle()
    if not wheel then createWheel() end
    if wheel:IsShown() then
        wheel:Hide()
    else
        page = 1
        updatePage()
        wheel:Show()
    end
end

local function ApplySettings()
    if not wheel then return end
    if InCombatLockdown and InCombatLockdown() then
        settingsPending = true
        return
    end
    settingsPending = false
    wheel:SetScale(EmoteWheelForeverDB.scale)
    wheel.targetPanel:SetShown(EmoteWheelForeverDB.showTarget)
    updatePage()
end

local function BuildSettings()
    if not (Settings and Settings.RegisterVerticalLayoutCategory and Settings.RegisterAddOnSetting) then
        return
    end

    local category, layout = Settings.RegisterVerticalLayoutCategory("RadialEmotes")
    local varTypes = Settings.VarType or {}

    local function Header(text)
        if layout and layout.AddInitializer then
            layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(text))
        end
    end

    local function AddSetting(key, label, kind, default, onChange)
        local setting = Settings.RegisterAddOnSetting(
            category,
            "RadialEmotes_" .. key,
            key,
            EmoteWheelForeverDB,
            kind,
            label,
            default
        )
        setting:SetValueChangedCallback(function()
            if onChange then onChange() end
        end)
        return setting
    end

    Header("Wheel")
    local scaleSetting = AddSetting("scale", "Wheel size", varTypes.Number or "number", DEFAULTS.scale, ApplySettings)
    local scaleOptions = Settings.CreateSliderOptions(0.75, 1.35, 0.05)
    if scaleOptions.SetLabelFormatter and MinimalSliderWithSteppersMixin then
        scaleOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
            return string.format("%.0f%%", value * 100)
        end)
    end
    Settings.CreateSlider(category, scaleSetting, scaleOptions, "Adjust the wheel's overall size.")

    local pageSetting = AddSetting("pageSize", "Emotes per page", varTypes.Number or "number", DEFAULTS.pageSize, ApplySettings)
    local pageOptions = Settings.CreateSliderOptions(6, MAX_PAGE_SIZE, 2)
    if pageOptions.SetLabelFormatter and MinimalSliderWithSteppersMixin then
        pageOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
            return string.format("%d", value)
        end)
    end
    Settings.CreateSlider(category, pageSetting, pageOptions, "Choose how many emotes appear around the wheel at once.")

    Header("Display")
    local targetSetting = AddSetting("showTarget", "Show target in the center", varTypes.Boolean or "boolean", DEFAULTS.showTarget, ApplySettings)
    Settings.CreateCheckbox(category, targetSetting, "Show your current target's portrait and name in the center of the wheel.")

    Header("Selection")
    local closeSetting = AddSetting("closeAfterSelect", "Close after choosing an emote", varTypes.Boolean or "boolean", DEFAULTS.closeAfterSelect, ApplySettings)
    Settings.CreateCheckbox(category, closeSetting, "Leave this off to keep the wheel open for repeated emotes.")

    local scrollSetting = AddSetting("mouseWheelPaging", "Scroll to change pages", varTypes.Boolean or "boolean", DEFAULTS.mouseWheelPaging, ApplySettings)
    Settings.CreateCheckbox(category, scrollSetting, "Use the mouse wheel while the emote wheel is open to browse pages.")

    Settings.RegisterAddOnCategory(category)
    settingsCategory = category
end

function RadialEmotes_OpenSettings()
    if not settingsCategory then
        print("RadialEmotes: settings are unavailable in this client.")
        return
    end
    if InCombatLockdown and InCombatLockdown() then
        print("RadialEmotes: open settings after combat.")
        return
    end
    local id = settingsCategory.GetID and settingsCategory:GetID()
    if C_SettingsUtil and C_SettingsUtil.OpenSettingsPanel and id then
        local ok = pcall(C_SettingsUtil.OpenSettingsPanel, id)
        if not ok and Settings and Settings.OpenToCategory then
            pcall(Settings.OpenToCategory, id)
        end
    elseif Settings and Settings.OpenToCategory and id then
        pcall(Settings.OpenToCategory, id)
    end
end

function RadialEmotes_Binding(keystate)
    if keystate == "down" then
        -- Ignore key-repeat so one held press keeps the wheel steadily open.
        if wheelKeyHeld then return end
        wheelKeyHeld = true
        if not wheel then createWheel() end
        page = 1
        updatePage()
        wheel:Show()
    elseif keystate == "up" then
        wheelKeyHeld = false
        if wheel and wheel:IsShown() then wheel:Hide() end
    end
end

SLASH_RADIALEMOTES1 = "/radialemotes"
SLASH_RADIALEMOTES2 = "/re"
SLASH_RADIALEMOTES3 = "/emotewheel"
SLASH_RADIALEMOTES4 = "/ew"
SlashCmdList.RADIALEMOTES = function(message)
    message = (message or ""):lower():match("^%s*(.-)%s*$")
    if message == "options" or message == "config" or message == "settings" then
        RadialEmotes_OpenSettings()
    else
        RadialEmotes_Toggle()
    end
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:RegisterEvent("PLAYER_REGEN_ENABLED")
loader:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_REGEN_ENABLED" then
        if settingsPending then ApplySettings() end
        return
    end
    EnsureDB()
    createWheel() -- Prepare secure macro buttons before the player can enter combat.
    BuildSettings()
    ApplySettings()
    print("RadialEmotes loaded. Type /re, /re options, or use the wheel keybind.")
end)
