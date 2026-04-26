-------------------------------------------------------------------
-- Addon: BloodlustPumpbutBetter
-- Author: Kasper der Pumper
-- Twitch: https://www.twitch.tv/kasper7777
-- Version: 6.7
-------------------------------------------------------------------

local addonName, addonTable = ...
local addonPath = "Interface\\AddOns\\" .. addonName .. "\\"
local soundPath = addonPath .. "Sounds\\"
local imagePath = addonPath .. "Images\\"

-- 1. DATABASE AND VARIABLES
BloodlustpumpDB = BloodlustpumpDB or {}
local isLustActive, isTesting, isMoving = false, false, false
local isLoggingIn = true
local musicHandle, delayTimer, ronnieFrames = nil, nil, {}
local currentFrame, animTimer, scanTimer = 0, 0, 0
local lustDuration = 40
local category
local lastTriggerTime = 0
local PUMP_COOLDOWN = 60
local SPELL_SCAN_INTERVAL = 0.2
local FRESH_SATED_MIN_REMAINING = 560
local MUSIC_RETRY_INTERVAL = 1
local hasFiredThisCombat = false
local hadSatedLastCheck = false
local nextMusicRetryTime = 0

-- Sated-like debuff spell IDs (trigger appears immediately after lust is cast in modern retail)
local SATED_DEBUFFS = {
    57724,   -- Sated
    57723,   -- Exhaustion
    80354,   -- Temporal Displacement
    264689,  -- Fatigued
}

-- PROFILE CONFIGURATION
local pumperProfiles = {
    Ronnie = { 
        tex = "pumping.blp", scream = "lightweightbaby.mp3", music = "lustmusic.mp3",
        frames = 58, cols = 8, rows = 8, signature = "LIGHTWEIGHT BABY!", musicDelay = 10 
    },
    Arnold = { 
        tex = "arnold.blp", scream = "voice_arnold.mp3", music = "arnoldmusic.mp3",
        frames = 64, cols = 8, rows = 8, signature = "STAY HUNGRY!", musicDelay = 7.6
        },
    Zyzz = { 
        tex = "zyzz.blp", scream = "wereallgonnamakeitbrah.mp3", music = "zyzzmusic.mp3",
        frames = 64, cols = 8, rows = 8, signature = "U MIRIN BRO?", musicDelay = 2 
    }
}

-- Available music tracks (chosen independently of the legend)
local musicTrackList = {
    { label = "Ronnie - Pump Music",  file = "lustmusic.mp3"   },
    { label = "Arnold - Pump Music", file = "arnoldmusic.mp3" },
    { label = "Zyzz - Pump Music",   file = "zyzzmusic.mp3"   },
}

local function StopCurrentMusic()
    if musicHandle then
        StopSound(musicHandle)
        musicHandle = nil
    end
    nextMusicRetryTime = 0
end

local function StartProfileMusic()
    if not BloodlustpumpDB or not BloodlustpumpDB.enableMusic then
        musicHandle = nil
        nextMusicRetryTime = 0
        return false
    end

    local profile = pumperProfiles[BloodlustpumpDB.activeProfile]
    local trackFile = BloodlustpumpDB.musicTrack or profile.music
    local willPlay, newHandle = PlaySoundFile(soundPath..trackFile, BloodlustpumpDB.audioChannel)
    musicHandle = newHandle
    nextMusicRetryTime = GetTime() + MUSIC_RETRY_INTERVAL

    return willPlay and newHandle ~= nil
end

local function QueueProfileAudio(profile)
    StopCurrentMusic()

    if BloodlustpumpDB.enableScream then
        PlaySoundFile(soundPath..profile.scream, BloodlustpumpDB.audioChannel)
        delayTimer = BloodlustpumpDB.enableMusic and profile.musicDelay or nil
    elseif BloodlustpumpDB.enableMusic then
        StartProfileMusic()
        delayTimer = nil
    else
        delayTimer = nil
    end
end

local function ShouldHaveMusicPlaying()
    return BloodlustpumpDB and BloodlustpumpDB.enableMusic and not delayTimer and (isLustActive or isTesting)
end

-- INITIALIZE DATABASE
local function InitDB(force)
    if force then 
        BloodlustpumpDB = {}
    end
    
    BloodlustpumpDB.activeProfile = BloodlustpumpDB.activeProfile or "Ronnie"
    BloodlustpumpDB.layoutMode = BloodlustpumpDB.layoutMode or "Dual"
    BloodlustpumpDB.distFromCenter = BloodlustpumpDB.distFromCenter or 600 
    BloodlustpumpDB.yPos = BloodlustpumpDB.yPos or 278.6
    BloodlustpumpDB.size = BloodlustpumpDB.size or 320
    BloodlustpumpDB.opacity = BloodlustpumpDB.opacity or 1.0
    BloodlustpumpDB.audioChannel = BloodlustpumpDB.audioChannel or "Master"
    BloodlustpumpDB.enableScream = (BloodlustpumpDB.enableScream == nil) and true or BloodlustpumpDB.enableScream
    BloodlustpumpDB.enableMusic = (BloodlustpumpDB.enableMusic == nil) and true or BloodlustpumpDB.enableMusic
    BloodlustpumpDB.musicTrack = BloodlustpumpDB.musicTrack or "lustmusic.mp3"
end

-- 2. VISUAL UPDATES
local function UpdateVisuals()
    local showFrames = isLustActive or isTesting or isMoving
    local profile = pumperProfiles[BloodlustpumpDB.activeProfile]
    local isSingle = (BloodlustpumpDB.layoutMode == "Single")

    for i, f in ipairs(ronnieFrames) do
        if f then
            f:EnableMouse(isMoving)
            local currentAlpha = showFrames and (BloodlustpumpDB.opacity or 1) or 0
            if i == 2 and isSingle then
                f:SetAlpha(0)
            else
                f:SetAlpha(currentAlpha)
            end

            local xOff = BloodlustpumpDB.distFromCenter 
            if not isSingle then
                xOff = (i == 1) and -BloodlustpumpDB.distFromCenter or BloodlustpumpDB.distFromCenter
            end

            f:SetSize(BloodlustpumpDB.size or 400, BloodlustpumpDB.size or 400)
            f:ClearAllPoints(); f:SetPoint("CENTER", UIParent, "CENTER", xOff, BloodlustpumpDB.yPos or 150)
            f.tex:SetTexture(imagePath .. profile.tex)
            f.timerText:ClearAllPoints()
            f.timerText:SetPoint("BOTTOM", f, "BOTTOM", 0, 12)
            
            -- Timer display below image
            if showFrames and not isMoving then
                f.timerText:SetText(string.format("%.1f", lustDuration))
                f.timerText:SetAlpha(1)
            else
                f.timerText:SetAlpha(0)
            end
        end
    end
end

-- 3. TWITCH POPUP
StaticPopupDialogs["BLOODLUSTPUMP_COPY_LINK"] = {
    text = "Kaspers's Twitch Channel:",
    button1 = "Done",
    hasEditBox = 1, editBoxWidth = 260,
    OnShow = function(self)
        local eb = _G[self:GetName().."EditBox"]
        if eb then eb:SetText("www.twitch.tv/kasper7777"); eb:HighlightText(); eb:SetFocus() end
    end,
    timeout = 0, whileDead = true, hideOnEscape = true,
}

-- 4. SATED/EXHAUSTION DETECTION
local function HasSatedDebuff()
    for _, spellID in ipairs(SATED_DEBUFFS) do
        local aura = C_UnitAuras.GetPlayerAuraBySpellID(spellID)
        if aura and (aura.isHarmful == nil or aura.isHarmful) then
            local remaining = 0
            if aura.expirationTime and aura.expirationTime > 0 then
                remaining = aura.expirationTime - GetTime()
            end
            return true, remaining
        end
    end
    return false, 0
end

local function CheckLustStatus()
    if isTesting or isMoving or isLoggingIn or hasFiredThisCombat then 
        return 
    end

    local hasSated, remaining = HasSatedDebuff()
    local currentTime = GetTime()
    
    -- Sated/Exhaustion just appeared (state transition)
    if hasSated and remaining >= FRESH_SATED_MIN_REMAINING and not hadSatedLastCheck and not isLustActive and (currentTime - lastTriggerTime > PUMP_COOLDOWN) then
        lastTriggerTime = currentTime
        isLustActive = true
        
        if UnitAffectingCombat("player") then hasFiredThisCombat = true end
        
        currentFrame = 0
        lustDuration = 40
        UpdateVisuals()

        local profile = pumperProfiles[BloodlustpumpDB.activeProfile]

        QueueProfileAudio(profile)
    end
    
    hadSatedLastCheck = hasSated
end

-- 5. SETTINGS MENU
local function CreateSettingsMenu()
    local panel = CreateFrame("Frame", "BloodlustpumpSettingsPanel", UIParent)
    panel.name = "BloodlustPumpbutBetter"; local refreshFunctions = {}
    
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
    title:SetPoint("TOPLEFT", 20, -25); title:SetText("BloodlustPumpbutBetter"); title:SetScale(1.5)

    local subTitle = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightMedium")
    subTitle:SetPoint("LEFT", title, "RIGHT", 12, -2); subTitle:SetFont("Fonts\\FRIZQT__.TTF", 12)
    subTitle:SetText("- Pump."); subTitle:SetTextColor(0.7, 0.7, 0.7)

    local line = panel:CreateTexture(nil, "ARTWORK")
    line:SetSize(580, 1); line:SetPoint("TOPLEFT", 20, -75); line:SetColorTexture(1, 1, 1, 0.1)

    local btnY = -105
    local moveBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    moveBtn:SetSize(130, 26); moveBtn:SetPoint("TOPLEFT", 20, btnY); moveBtn:SetText("Toggle Layout")
    moveBtn.tooltipText = "Show motivational frames permanently to adjust their position on your screen."
    moveBtn:SetScript("OnClick", function(self) isMoving = not isMoving; self:SetText(isMoving and "Lock Layout" or "Toggle Layout"); UpdateVisuals() end)

    local testBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    testBtn:SetSize(130, 26); testBtn:SetPoint("LEFT", moveBtn, "RIGHT", 10, 0); testBtn:SetText("Test Motivation")
    testBtn.tooltipText = "Simulate the Pump."
    testBtn:SetScript("OnClick", function(self) 
        isTesting = not isTesting
        if isTesting then isMoving, currentFrame, lustDuration = false, 0, 40
            local profile = pumperProfiles[BloodlustpumpDB.activeProfile]
            QueueProfileAudio(profile)
            self:SetText("Stop")
        else self:SetText("Test Motivation"); StopCurrentMusic(); delayTimer = nil end
        UpdateVisuals()
    end)

    local cbScream = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    cbScream:SetSize(24, 24)
    cbScream.label = cbScream:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    cbScream.label:SetPoint("LEFT", cbScream, "RIGHT", 4, 0)
    cbScream.label:SetText("Enable Voice")
    cbScream.tooltipText = "Play legend audio effects."
    cbScream:SetScript("OnClick", function(self) BloodlustpumpDB.enableScream = self:GetChecked() end)
    table.insert(refreshFunctions, function() cbScream:SetChecked(BloodlustpumpDB.enableScream) end)

    local cbMusic = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    cbMusic:SetSize(24, 24)
    cbMusic.label = cbMusic:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    cbMusic.label:SetPoint("LEFT", cbMusic, "RIGHT", 4, 0)
    cbMusic.label:SetText("Enable Music")
    cbMusic.tooltipText = "Play workout music during the pump duration."
    cbMusic:SetScript("OnClick", function(self) BloodlustpumpDB.enableMusic = self:GetChecked() end)
    table.insert(refreshFunctions, function() cbMusic:SetChecked(BloodlustpumpDB.enableMusic) end)

    local rowY = btnY - 70

    -- 1. LEGEND DROPDOWN
    local sectionProfiles = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    sectionProfiles:SetPoint("TOPLEFT", 20, rowY); sectionProfiles:SetText("CHOOSE YOUR LEGEND")

    local profileDD = CreateFrame("DropdownButton", "BLP_ProfileDD", panel, "WowStyle1DropdownTemplate")
    profileDD:SetPoint("TOPLEFT", sectionProfiles, "BOTTOMLEFT", 0, -5)
    profileDD:SetSize(110, 24)
    profileDD:SetupMenu(function(dd, rootDescription)
        for _, name in ipairs({"Ronnie", "Arnold", "Zyzz"}) do
            rootDescription:CreateRadio(name,
                function() return BloodlustpumpDB.activeProfile == name end,
                function() BloodlustpumpDB.activeProfile = name; UpdateVisuals() end)
        end
    end)
    table.insert(refreshFunctions, function() profileDD:Update() end)

    -- 2. AUDIO CHANNEL DROPDOWN
    local sectionAudio = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    sectionAudio:SetPoint("LEFT", sectionProfiles, "LEFT", 135, 0); sectionAudio:SetText("AUDIO CHANNEL")

    local dropdown = CreateFrame("DropdownButton", "BLP_ChanDD", panel, "WowStyle1DropdownTemplate")
    dropdown:SetPoint("TOPLEFT", sectionAudio, "BOTTOMLEFT", 0, -5)
    dropdown:SetSize(110, 24)
    dropdown:SetupMenu(function(dd, rootDescription)
        for _, c in ipairs({"Master", "SFX", "Music", "Ambience", "Dialog"}) do
            rootDescription:CreateRadio(c,
                function() return BloodlustpumpDB.audioChannel == c end,
                function() BloodlustpumpDB.audioChannel = c end)
        end
    end)
    table.insert(refreshFunctions, function() dropdown:Update() end)

    -- 3. LAYOUT MODE DROPDOWN
    local sectionLayout = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    sectionLayout:SetPoint("LEFT", sectionAudio, "LEFT", 135, 0); sectionLayout:SetText("LAYOUT")

    local layoutDD = CreateFrame("DropdownButton", "BLP_LayoutDD", panel, "WowStyle1DropdownTemplate")
    layoutDD:SetPoint("TOPLEFT", sectionLayout, "BOTTOMLEFT", 0, -5)
    layoutDD:SetSize(90, 24)
    layoutDD:SetupMenu(function(dd, rootDescription)
        for _, mode in ipairs({"Single", "Dual"}) do
            rootDescription:CreateRadio(mode,
                function() return BloodlustpumpDB.layoutMode == mode end,
                function() BloodlustpumpDB.layoutMode = mode; for _, f in ipairs(refreshFunctions) do f() end; UpdateVisuals() end)
        end
    end)
    table.insert(refreshFunctions, function() layoutDD:Update() end)

    -- 4. MUSIC TRACK DROPDOWN
    local sectionTrack = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    sectionTrack:SetPoint("TOPLEFT", sectionProfiles, "LEFT", 0, -55); sectionTrack:SetText("MUSIC TRACK")

    local trackDD = CreateFrame("DropdownButton", "BLP_TrackDD", panel, "WowStyle1DropdownTemplate")
    trackDD:SetPoint("TOPLEFT", sectionTrack, "BOTTOMLEFT", 0, -5)
    trackDD:SetSize(160, 24)
    trackDD:SetupMenu(function(dd, rootDescription)
        for _, t in ipairs(musicTrackList) do
            rootDescription:CreateRadio(t.label,
                function() return BloodlustpumpDB.musicTrack == t.file end,
                function() BloodlustpumpDB.musicTrack = t.file end)
        end
    end)
    table.insert(refreshFunctions, function() trackDD:Update() end)

    cbScream:SetPoint("TOPLEFT", trackDD, "BOTTOMLEFT", 20, -10)
    cbMusic:SetPoint("TOPLEFT", cbScream, "TOPLEFT", 140, 0)


    local section2 = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    section2:SetPoint("TOPLEFT", 20, btnY - 275); section2:SetText("VISUAL CALIBRATION")

    local function NewSlider(n, l, min, max, k, x, y, tip)
        local sliderLbl = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        sliderLbl:SetPoint("TOPLEFT", 20 + x, btnY - 297 + y)
        sliderLbl:SetText(l)

        local s = CreateFrame("Slider", n, panel, "OptionsSliderTemplate")
        s:SetPoint("TOPLEFT", 20 + x, btnY - 315 + y); s:SetMinMaxValues(min, max); s:SetObeyStepOnDrag(true); s:SetSize(180, 18); s.tooltipText = tip
        -- Clear the template's own label so our fontstring is the sole source of truth
        local builtinLabel = _G[n .. 'Text']; if builtinLabel then builtinLabel:SetText("") end

        local isPrecision = (k == "opacity")
        s:SetValueStep(isPrecision and 0.1 or 1)
        
        local eb = CreateFrame("EditBox", nil, panel, "InputBoxTemplate"); eb:SetSize(40, 18); eb:SetPoint("LEFT", s, "RIGHT", 10, 0); eb:SetAutoFocus(false)
        eb:SetScript("OnEnterPressed", function(self) local v = tonumber(self:GetText()); if v then BloodlustpumpDB[k] = math.min(max, math.max(min, v)); s:SetValue(v); UpdateVisuals() end; self:ClearFocus() end)
        
        s:SetScript("OnValueChanged", function(_, v) 
            if s:IsMouseOver() then 
                local val = isPrecision and tonumber(string.format("%.1f", v)) or tonumber(string.format("%.0f", v))
                BloodlustpumpDB[k] = val; eb:SetText(val); UpdateVisuals() 
            end 
        end)
        
        table.insert(refreshFunctions, function() 
            s:SetValue(BloodlustpumpDB[k]); eb:SetText(BloodlustpumpDB[k]); 
            local label = l
            if k == "distFromCenter" then
                label = (BloodlustpumpDB.layoutMode == "Single") and "Horizontal Position" or "Frame Spacing"
            end
            sliderLbl:SetText(label)
        end)
    end
    
    NewSlider("BLP_D", "Frame Spacing",  -1200, 1200, "distFromCenter", 0,   0,   "Horizontal movement.")
    NewSlider("BLP_S", "Image Size",      100,  800, "size",           260,  0,   "How big Ronnie/Arnold are.")
    NewSlider("BLP_OP", "Opacity",         0,    1,  "opacity",          0, -45,  "Set transparency.")
    NewSlider("BLP_Y", "Vertical Height", -500,  500, "yPos",           260, -45, "Moves frames up or down.")

    local resetAllBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    resetAllBtn:SetSize(105, 24); resetAllBtn:SetPoint("BOTTOMLEFT", 20, 28); resetAllBtn:SetText("Reset Defaults")
    resetAllBtn.tooltipText = "Reset all configuration to default values. Spacing will return to 600."
    resetAllBtn:SetScript("OnClick", function() InitDB(true); for _, f in ipairs(refreshFunctions) do f() end; UpdateVisuals() end)

    local creditBtn = CreateFrame("Button", nil, panel)
    creditBtn:SetSize(320, 40); creditBtn:SetPoint("BOTTOMRIGHT", -20, 20)
    creditBtn.prefix = creditBtn:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    creditBtn.prefix:SetText("67% Vibecoded by"); creditBtn.prefix:SetTextColor(1, 0.82, 0, 0.7) 
    creditBtn.name = creditBtn:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    creditBtn.name:SetText("Kasper"); creditBtn.name:SetTextColor(0.776, 0.608, 0.427); creditBtn.name:SetAlpha(0.7); creditBtn.name:SetPoint("RIGHT", creditBtn, "RIGHT")
    creditBtn.prefix:SetPoint("RIGHT", creditBtn.name, "LEFT", -5, 0)
    creditBtn:SetScript("OnEnter", function(self) self.name:SetAlpha(1.0); self.name:SetTextColor(1, 1, 1) end)
    creditBtn:SetScript("OnLeave", function(self) self.name:SetAlpha(0.7); self.name:SetTextColor(0.776, 0.608, 0.427) end)
    creditBtn:SetScript("OnClick", function() StaticPopup_Show("BLOODLUSTPUMP_COPY_LINK") end)

    panel:SetScript("OnShow", function() for _, f in ipairs(refreshFunctions) do f() end end)
    category = Settings.RegisterCanvasLayoutCategory(panel, "BloodlustPump")
    Settings.RegisterAddOnCategory(category)
end

-- 7. CORE ENGINE
local core = CreateFrame("Frame")
core:RegisterEvent("PLAYER_LOGIN")
core:RegisterEvent("PLAYER_REGEN_ENABLED")
core:RegisterEvent("PLAYER_ENTERING_WORLD")

core:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then 
        InitDB(); isLoggingIn = true; CreateSettingsMenu()
        hadSatedLastCheck = HasSatedDebuff()
        C_Timer.After(5, function() isLoggingIn = false end)
        for i=1,2 do 
            local f = CreateFrame("Frame", "BLP_F"..i, UIParent); f:SetSize(400, 400); f:SetAlpha(0)
            f:SetMovable(true)
            f:SetClampedToScreen(true)
            f:RegisterForDrag("LeftButton")
            f.timerText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
            f.timerText:SetPoint("BOTTOM", f, "BOTTOM", 0, 12)
            f.timerText:SetScale(2.5)
            f.timerText:SetTextColor(1, 0.2, 0.2)
            f.timerText:SetShadowColor(0, 0, 0, 1)
            f.timerText:SetShadowOffset(2, -2)
            f.tex = f:CreateTexture(nil, "OVERLAY"); f.tex:SetAllPoints()
            f:SetScript("OnDragStart", function(self)
                if not isMoving then
                    return
                end
                self:StartMoving()
            end)
            f:SetScript("OnDragStop", function(self)
                self:StopMovingOrSizing()

                local centerX, centerY = self:GetCenter()
                if not centerX or not centerY then
                    UpdateVisuals()
                    return
                end

                local uiCenterX, uiCenterY = UIParent:GetCenter()
                if not uiCenterX or not uiCenterY then
                    UpdateVisuals()
                    return
                end

                local relativeX = centerX - uiCenterX
                local relativeY = centerY - uiCenterY

                BloodlustpumpDB.yPos = relativeY
                if BloodlustpumpDB.layoutMode == "Single" then
                    BloodlustpumpDB.distFromCenter = relativeX
                else
                    BloodlustpumpDB.distFromCenter = math.abs(relativeX)
                end

                UpdateVisuals()
            end)
            ronnieFrames[i] = f
        end
        UpdateVisuals()
    elseif event == "PLAYER_ENTERING_WORLD" then
        hadSatedLastCheck = HasSatedDebuff()
    elseif event == "PLAYER_REGEN_ENABLED" then
        hasFiredThisCombat = false
    end
end)

core:SetScript("OnUpdate", function(self, elapsed)
    scanTimer = scanTimer + elapsed
    if scanTimer >= SPELL_SCAN_INTERVAL then
        CheckLustStatus()
        scanTimer = scanTimer - SPELL_SCAN_INTERVAL
    end
    
    if isLustActive or isTesting or isMoving then

        animTimer = animTimer + elapsed
        local profile = pumperProfiles[BloodlustpumpDB.activeProfile]
        local frameRate = (1 / 30) 

        if BloodlustpumpDB.activeProfile == "Arnold" then 
            frameRate = (5 / 64) 
        elseif BloodlustpumpDB.activeProfile == "Zyzz" then 
            frameRate = (0.775 / 64) 
        end
        
        if animTimer > frameRate then
            local r = math.floor(currentFrame / profile.cols)
            local c = currentFrame % profile.cols
            local x1, x2 = c * (1 / profile.cols), (c + 1) * (1 / profile.cols)
            local y1, y2 = r * (1 / profile.rows), (r + 1) * (1 / profile.rows)
            for _, f in ipairs(ronnieFrames) do if f then f.tex:SetTexCoord(x1, x2, y1, y2) end end
            currentFrame = (currentFrame + 1) % profile.frames
            animTimer = animTimer - frameRate
        end

        if not isMoving then
            lustDuration = math.max(0, lustDuration - elapsed)
            for _, f in ipairs(ronnieFrames) do if f then f.timerText:SetText(string.format("%.1f", lustDuration)) end end
            if lustDuration <= 0 and not isTesting then 
                isLustActive = false
                StopCurrentMusic()
                UpdateVisuals()
            end
        end
    end

    if delayTimer then
        delayTimer = delayTimer - elapsed
        if delayTimer <= 0 then 
            if (isLustActive or isTesting) and BloodlustpumpDB.enableMusic then 
                StartProfileMusic()
            end
            delayTimer = nil 
        end
    end

    if ShouldHaveMusicPlaying() then
        -- C_Sound.IsPlaying does not exist in the WoW API; musicHandle being set is
        -- the only available proxy for "music is currently playing". If it is nil,
        -- the sound either failed to start or was stopped externally — retry after
        -- MUSIC_RETRY_INTERVAL to handle transient audio engine failures.
        if not musicHandle and GetTime() >= nextMusicRetryTime then
            StartProfileMusic()
        end
    end
end)

SLASH_BLOODLUSTPUMP1 = "/blp"
SlashCmdList["BLOODLUSTPUMP"] = function() if category and category:GetID() then Settings.OpenToCategory(category:GetID()) end end