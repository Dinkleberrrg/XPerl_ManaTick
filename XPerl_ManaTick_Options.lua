--=====================================================================
-- Fenster fuer X-Perl ManaTick. Gleiches Muster wie beim SwingTimer:
-- eigenes Panel im XPerl-Look, plus ein Knopf neben XPerls Optionen.
--=====================================================================

local XMT = XPerl_ManaTick
local panel
local widgets = {}

local function Check(parent, key, label, tip, x, y)
    local name = "XPerlManaOpt_" .. key
    local c = CreateFrame("CheckButton", name, parent, "UICheckButtonTemplate")
    c:SetWidth(22); c:SetHeight(22)
    c:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    getglobal(name .. "Text"):SetText(label)
    c.tooltipText = tip
    c:SetScript("OnClick", function() XMT:Set(this.key, this:GetChecked() and 1 or 0) end)
    c:SetScript("OnEnter", function()
        if this.tooltipText then
            GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
            GameTooltip:SetText(this.tooltipText, nil, nil, nil, nil, 1)
        end
    end)
    c:SetScript("OnLeave", function() GameTooltip:Hide() end)
    c.key = key
    return c
end

local function Slider(parent, key, label, lo, hi, step, x, y)
    local name = "XPerlManaOpt_" .. key
    local s = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
    s:SetWidth(150); s:SetHeight(16)
    s:SetPoint("TOPLEFT", parent, "TOPLEFT", x + 6, y)
    s:SetMinMaxValues(lo, hi); s:SetValueStep(step)
    getglobal(name .. "Low"):SetText(lo)
    getglobal(name .. "High"):SetText(hi)
    s.labelText = label
    s:SetScript("OnValueChanged", function()
        local v = this:GetValue()
        if step >= 1 then v = floor(v + 0.5) else v = floor(v * 100 + 0.5) / 100 end
        getglobal(this:GetName() .. "Text"):SetText(this.labelText .. ": " .. v)
        XMT:Set(this.key, v)
    end)
    s.key = key
    return s
end

local function Swatch(parent, key, label, x, y)
    local b = CreateFrame("Button", "XPerlManaOpt_" .. key, parent)
    b:SetWidth(16); b:SetHeight(16)
    b:SetPoint("TOPLEFT", parent, "TOPLEFT", x + 6, y)
    b:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8",
                    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 8,
                    insets = { left = 2, right = 2, top = 2, bottom = 2 } })
    local t = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    t:SetPoint("LEFT", b, "RIGHT", 6, 0)
    t:SetText(label)
    b.key = key
    b:SetScript("OnClick", function()
        local k = this.key
        local c = XMT:Get(k)
        local function apply()
            local r, g, bl = ColorPickerFrame:GetColorRGB()
            XMT:Set(k, { r, g, bl })
            getglobal("XPerlManaOpt_" .. k):SetBackdropColor(r, g, bl, 1)
        end
        ColorPickerFrame.hasOpacity = nil
        ColorPickerFrame.previousValues = { c[1], c[2], c[3] }
        ColorPickerFrame.func = apply
        ColorPickerFrame.cancelFunc = function()
            local p = ColorPickerFrame.previousValues
            XMT:Set(k, { p[1], p[2], p[3] })
            getglobal("XPerlManaOpt_" .. k):SetBackdropColor(p[1], p[2], p[3], 1)
        end
        ColorPickerFrame:SetColorRGB(c[1], c[2], c[3])
        ColorPickerFrame:Hide(); ColorPickerFrame:Show()
    end)
    return b
end

local function Header(parent, text, x, y)
    local f = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    f:SetText("|cFF40FF40" .. text .. "|r")
    return f
end

local function BuildPanel()
    if panel then return panel end

    panel = CreateFrame("Frame", "XPerlManaTickOptions", UIParent)
    panel:SetWidth(470); panel:SetHeight(500)
    panel:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    panel:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 } })
    panel:SetMovable(true); panel:EnableMouse(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", function() this:StartMoving() end)
    panel:SetScript("OnDragStop",  function() this:StopMovingOrSizing() end)
    panel:SetFrameStrata("DIALOG")
    panel:Hide()
    tinsert(UISpecialFrames, "XPerlManaTickOptions")

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", panel, "TOP", 0, -18)
    title:SetText("X-Perl |cFF40FF40ManaTick|r")

    local L, R = 24, 240

    Header(panel, "Anzeigen", L, -50)
    widgets.enabled  = Check(panel, "enabled",  "Modul aktiv", nil, L, -72)
    widgets.showFSR  = Check(panel, "showFSR",  "Fuenf-Sekunden-Regel",
        "Nach jedem Manaverbrauch pausiert die geistbasierte\nRegeneration. Der Streifen fuellt sich in dieser Zeit.", L, -94)
    widgets.showTick = Check(panel, "showTick", "Zwei-Sekunden-Tick",
        "Laeuft, sobald die Sperre durch ist. Der Takt wird an\ntatsaechlich beobachteten Manazuwaechsen ausgerichtet.", L, -116)
    widgets.combatOnly = Check(panel, "combatOnly", "Nur im Kampf", nil, L, -138)
    widgets.hideIdle   = Check(panel, "hideIdle",   "Bei vollem Mana ausblenden",
        "Ausserhalb des Kampfes und mit vollem Manabalken gibt es\nnichts zu takten.", L, -160)

    Header(panel, "Laenge", L, -192)
    widgets.fsrTime  = Slider(panel, "fsrTime",  "Sperre (Sek.)", 1, 10, 0.5, L, -216)
    widgets.tickTime = Slider(panel, "tickTime", "Takt (Sek.)",   1,  5, 0.5, L, -254)

    Header(panel, "Farben", L, -292)
    widgets.colFSR  = Swatch(panel, "colFSR",  "Sperre", L,     -316)
    widgets.colTick = Swatch(panel, "colTick", "Takt",   L+110, -316)

    Header(panel, "Darstellung", R, -50)
    widgets.spark     = Check(panel, "spark",     "Laufmarke", nil, R, -72)
    widgets.showText  = Check(panel, "showText",  "Beschriftung",
        "Restsekunden waehrend der Sperre, danach der gemessene\nZuwachs pro Tick. Kann sich mit XPerls eigener\nManaanzeige ueberschneiden.", R, -94)
    widgets.protoFont = Check(panel, "protoFont", "Prototype-Schrift", nil, R, -116)

    widgets.fillFSR   = Check(panel, "fillFSR",  "Sperre fuellt statt leert",
        "An = wie in WotLK: der Streifen waechst nach rechts.\nAus = er laeuft von voll auf leer.", R, -138)
    widgets.texture   = Check(panel, "texture",  "XPerl-Textur",
        "An = XPerl_FrameBack wie in WotLK.\nAus = flache Farbflaeche.", R, -160)

    widgets.place    = Slider(panel, "place",    "Lage 0-3", 0, 3, 1, R, -196)
    widgets.height   = Slider(panel, "height",   "Streifenhoehe", 1, 10, 1, R, -234)
    widgets.alpha    = Slider(panel, "alpha",    "Deckkraft", 0.1, 1, 0.05, R, -272)
    widgets.fontSize = Slider(panel, "fontSize", "Schriftgroesse", 6, 18, 1, R, -310)

    local note = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    note:SetPoint("TOPLEFT", panel, "TOPLEFT", R + 6, -346)
    note:SetWidth(210)
    note:SetJustifyH("LEFT")
    note:SetText("Lage 3 ist die WotLK-Vorlage: 2 Pixel unter dem Manabalken. 0 und 1 legen den Streifen innen an den unteren bzw. oberen Rand, 2 ueber die ganze Hoehe - dann die Deckkraft senken.")

    local close = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    close:SetWidth(100); close:SetHeight(22)
    close:SetPoint("BOTTOM", panel, "BOTTOM", 60, 18)
    close:SetText("Schliessen")
    close:SetScript("OnClick", function() panel:Hide() end)

    local reset = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    reset:SetWidth(100); reset:SetHeight(22)
    reset:SetPoint("BOTTOM", panel, "BOTTOM", -60, 18)
    reset:SetText("Standard")
    reset:SetScript("OnClick", function()
        XPerlManaTickConfig = {}
        XMT:ApplyLayout()
        XPerl_ManaTick_RefreshOptions()
    end)

    return panel
end

function XPerl_ManaTick_RefreshOptions()
    if not panel then return end
    for key, w in pairs(widgets) do
        local v = XMT:Get(key)
        if type(v) == "table" then
            w:SetBackdropColor(v[1], v[2], v[3], 1)
        elseif w.GetObjectType and w:GetObjectType() == "Slider" then
            w:SetValue(v)
            getglobal(w:GetName() .. "Text"):SetText(w.labelText .. ": " .. v)
        else
            w:SetChecked(v == 1)
        end
    end
end

function XPerl_ManaTick_ToggleOptions()
    BuildPanel()
    if panel:IsShown() then
        panel:Hide()
    else
        XPerl_ManaTick_RefreshOptions()
        panel:Show()
    end
end

local hook = CreateFrame("Frame")
hook:RegisterEvent("ADDON_LOADED")
hook:SetScript("OnEvent", function()
    if arg1 ~= "XPerl_Options" then return end
    if not XPerl_Options or XPerl_Options.manaTickButton then return end
    local b = CreateFrame("Button", nil, XPerl_Options, "UIPanelButtonTemplate")
    b:SetWidth(110); b:SetHeight(22)
    b:SetPoint("TOPLEFT", XPerl_Options, "TOPRIGHT", 4, -42)
    b:SetText("ManaTick")
    b:SetScript("OnClick", function() XPerl_ManaTick_ToggleOptions() end)
    XPerl_Options.manaTickButton = b
    hook:UnregisterEvent("ADDON_LOADED")
end)
