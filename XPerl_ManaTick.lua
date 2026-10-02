--=====================================================================
-- X-Perl ManaTick
--
-- Zwei Uhren, die in Vanilla jeder Manabenutzer im Kopf mitfuehrt, als
-- schmaler Streifen am XPerl-Manabalken.
--
-- Die Standardeinstellung ist die Geometrie von XPerl 3.x aus WotLK,
-- Funktion MakeEnergyTicker in XPerl_Player.lua:
--
--     f:SetPoint("TOPLEFT",     manaBar, "BOTTOMLEFT",  0,  0)
--     f:SetPoint("BOTTOMRIGHT", manaBar, "BOTTOMRIGHT", 0, -2)
--     f:SetStatusBarTexture(".../XPerl_FrameBack")
--     f:SetStatusBarColor(0.4, 0.7, 1)   -- Funke in derselben Farbe
--     f:SetMinMaxValues(0, 5)            -- und er FUELLT sich, laeuft nicht leer
--
--   Fuenf-Sekunden-Regel   Nach jedem Manaverbrauch pausiert die
--                          geistbasierte Regeneration fuenf Sekunden.
--                          Der Streifen fuellt sich in dieser Zeit,
--                          der Funke reitet auf der Vorderkante.
--   Zwei-Sekunden-Tick     Danach kommt Mana im Zweisekundentakt zurueck.
--                          Kennt WotLK nicht - das ist die Zugabe, und
--                          sie laesst sich einzeln abschalten.
--
-- Beide Phasen sind einzeln abschaltbar. Ist nur eine an, laeuft nur die.
--
-- Warum die Erkennung so aussieht, wie sie aussieht: Vanilla hat kein
-- Ereignis fuer "Regenerationstick" und keine API fuer die verbleibende
-- Sperrzeit. Beides muss aus UNIT_MANA abgeleitet werden - Mana runter
-- heisst Sperre neu starten, Mana rauf heisst, gerade war ein Tick.
--=====================================================================

XPerl_ManaTick = {}
local XMT = XPerl_ManaTick

local MANABAR = "XPerl_Player_StatsFrame_ManaBar"
local FLAT    = "Interface\\Buttons\\WHITE8X8"
local BACK    = "Interface\\AddOns\\XPerl\\Images\\XPerl_FrameBack"

XMT.defaults = {
    enabled    = 1,
    showFSR    = 1,   -- Fuenf-Sekunden-Regel anzeigen
    showTick   = 1,   -- Zweisekundentakt anzeigen

    fsrTime    = 5,   -- Laenge der Sperre in Sekunden
    tickTime   = 2,   -- Taktlaenge in Sekunden

    -- 3 = unter dem Manabalken, wie XPerl 3.x es in WotLK macht. Das ist
    -- die Vorlage: MakeEnergyTicker haengt dort einen 2 Pixel hohen
    -- StatusBar an manaBar BOTTOMLEFT/BOTTOMRIGHT mit Versatz -2.
    place      = 3,   -- 0 unten innen, 1 oben innen, 2 ganze Hoehe, 3 darunter
    height     = 2,   -- WotLK: exakt 2
    alpha      = 1,
    spark      = 1,   -- WotLK hat den Funken an
    fillFSR    = 1,   -- WotLK fuellt von links nach rechts, statt zu leeren
    texture    = 1,   -- 1 = XPerl_FrameBack wie WotLK, 0 = flache Farbflaeche
    combatOnly = 0,
    hideIdle   = 1,

    showText   = 0,   -- kleine Beschriftung rechts am Manabalken
    fontSize   = 9,
    protoFont  = 0,

    -- WotLK: f:SetStatusBarColor(0.4, 0.7, 1) fuer die Sperre
    colFSR     = {0.40, 0.70, 1.00},
    colTick    = {0.55, 0.95, 0.55},
}

--------------------------------------------------------------------- Config
function XMT:Get(k)
    if XPerlManaTickConfig and XPerlManaTickConfig[k] ~= nil then
        return XPerlManaTickConfig[k]
    end
    return self.defaults[k]
end

function XMT:Set(k, v)
    if not XPerlManaTickConfig then XPerlManaTickConfig = {} end
    XPerlManaTickConfig[k] = v
    self:ApplyLayout()
end

function XMT:Colour(k)
    local c = self:Get(k)
    return c[1], c[2], c[3]
end

--------------------------------------------------------------------- Zustand
local host                  -- der XPerl-Manabalken
local bar                   -- unser Streifen
local lastMana              -- Manastand beim letzten Ereignis
local fsrEnd    = 0         -- Zeitpunkt, an dem die Sperre ablaeuft
local tickAt    = 0         -- erwarteter naechster Tick
local lastGain  = 0         -- Zeitpunkt des letzten Manazuwachses
local perTick   = 0         -- zuletzt gemessener Zuwachs pro Tick

local function IsManaUser()
    return UnitPowerType("player") == 0
end

--------------------------------------------------------------------- Aufbau
function XMT:Build()
    if bar then return true end

    host = getglobal(MANABAR)
    if not host then return false end

    bar = CreateFrame("StatusBar", "XPerlManaTickBar", host)
    bar:SetStatusBarTexture(BACK)
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(0)
    bar:SetFrameLevel(host:GetFrameLevel() + 2)
    bar:Hide()

    bar.spark = bar:CreateTexture(nil, "OVERLAY")
    bar.spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
    bar.spark:SetBlendMode("ADD")
    bar.spark:SetWidth(12)   -- WotLK: 12 x 12
    bar.spark:Hide()

    -- Beschriftung haengt am Manabalken, nicht am Streifen: auf drei Pixeln
    -- Hoehe ist keine Schrift lesbar.
    bar.text = host:CreateFontString(nil, "OVERLAY")
    bar.text:SetJustifyH("RIGHT")
    bar.text:Hide()

    -- Der Takt laeuft NICHT auf dem Streifen selbst. Ein verstecktes Frame
    -- bekommt in WoW kein OnUpdate mehr - der Streifen koennte sich nach dem
    -- ersten Ausblenden nie wieder einblenden. Deshalb treibt das Ereignis-
    -- frame die Anzeige, das ist immer sichtbar.
    return true
end

--------------------------------------------------------------------- Layout
function XMT:ApplyLayout()
    if not bar and not self:Build() then return end

    local place = self:Get("place")
    local h     = self:Get("height")

    bar:SetStatusBarTexture(self:Get("texture") == 1 and BACK or FLAT)

    bar:ClearAllPoints()
    if place == 3 then
        -- WotLK-Geometrie: unter dem Manabalken, volle Breite, h Pixel hoch
        bar:SetPoint("TOPLEFT",     host, "BOTTOMLEFT",  0, 0)
        bar:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", 0, -h)
    elseif place == 2 then
        bar:SetPoint("TOPLEFT", host, "TOPLEFT", 0, 0)
        bar:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", 0, 0)
    elseif place == 1 then
        bar:SetPoint("TOPLEFT", host, "TOPLEFT", 0, 0)
        bar:SetPoint("TOPRIGHT", host, "TOPRIGHT", 0, 0)
        bar:SetHeight(h)
    else
        bar:SetPoint("BOTTOMLEFT", host, "BOTTOMLEFT", 0, 0)
        bar:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", 0, 0)
        bar:SetHeight(h)
    end

    bar:SetAlpha(self:Get("alpha"))

    -- Beim ersten Aufruf kann der Manabalken noch keine Hoehe haben.
    -- SetHeight(0) waere eine Fehlermeldung statt einer Laufmarke.
    local sparkH = (place == 2) and (host:GetHeight() * 2) or 12
    if not sparkH or sparkH < 4 then sparkH = 12 end
    bar.spark:SetHeight(sparkH)

    -- Die Prototype-Schrift liegt in ShaguPlates. Ist das nicht installiert,
    -- wuerde SetFont fehlschlagen und der naechste SetText-Aufruf mit
    -- "Font not set" abbrechen - deshalb nur nehmen, wenn wirklich da.
    local proto = (self:Get("protoFont") == 1) and IsAddOnLoaded("ShaguPlates")
    local fp = proto and "Interface\\AddOns\\ShaguPlates\\fonts\\Prototype.ttf"
                     or  "Fonts\\FRIZQT__.TTF"
    local fl = proto and "OUTLINE, MONOCHROME" or "OUTLINE"
    bar.text:SetFont(fp, self:Get("fontSize"), fl)
    bar.text:ClearAllPoints()
    bar.text:SetPoint("RIGHT", host, "RIGHT", -3, 0)

    if self:Get("enabled") == 0 then
        bar:Hide()
        bar.text:Hide()
    end
end

--------------------------------------------------------------------- Ablauf
function XMT:Reset()
    fsrEnd, tickAt, lastGain, perTick = 0, 0, 0, 0
    lastMana = UnitMana("player")
    if bar then bar:Hide(); bar.text:Hide() end
end

function XMT:ManaChanged()
    local cur = UnitMana("player")
    if not cur then return end

    if lastMana then
        local d = cur - lastMana
        local now = GetTime()

        if d < 0 then
            -- Verbrauch: Sperre laeuft ab jetzt neu
            fsrEnd = now + self:Get("fsrTime")

        elseif d > 0 then
            -- Zuwachs. Traenke und Manaproccs kommen ebenfalls hier an,
            -- deshalb wird nur dann neu synchronisiert, wenn der Abstand
            -- zum letzten Zuwachs plausibel nach einem Tick aussieht.
            -- Ein Trank kurz nach einem Tick verschiebt den Takt sonst.
            local gap  = now - lastGain
            local tick = self:Get("tickTime")

            if lastGain == 0 or gap > tick * 1.4 or abs(gap - tick) < 0.35 then
                perTick  = d
                lastGain = now
                tickAt   = now + tick
            end
        end
    end

    lastMana = cur
end

function XMT:OnUpdate()
    if not bar then return end

    if self:Get("enabled") == 0 or not IsManaUser() then
        bar:Hide(); bar.text:Hide()
        return
    end

    if self:Get("combatOnly") == 1 and not UnitAffectingCombat("player") then
        bar:Hide(); bar.text:Hide()
        return
    end

    local now  = GetTime()
    local fsr  = (self:Get("showFSR") == 1) and (fsrEnd > now)
    local tick = (self:Get("showTick") == 1)

    if fsr then
        -- Sperre laeuft: der Streifen leert sich von voll auf null
        local total = self:Get("fsrTime")
        local left  = fsrEnd - now
        local r, g, b = self:Colour("colFSR")
        bar:SetMinMaxValues(0, total)
        -- WotLK zaehlt hoch: val = val + elapsed, Balken waechst nach rechts
        bar:SetValue(self:Get("fillFSR") == 1 and (total - left) or left)
        bar:SetStatusBarColor(r, g, b)
        bar.spark:SetVertexColor(r, g, b)
        bar:Show()

        if self:Get("showText") == 1 then
            bar.text:SetText(format("%.1f", left))
            bar.text:SetTextColor(self:Colour("colFSR"))
            bar.text:Show()
        else
            bar.text:Hide()
        end

    elseif tick then
        -- Sperre vorbei: Takt anzeigen. Ohne beobachteten Tick laeuft die
        -- Uhr trotzdem, sonst haette man bei vollem Mana nie eine Anzeige.
        local total = self:Get("tickTime")
        if tickAt <= now then
            tickAt = now + total - math.mod(now - tickAt, total)
        end

        if self:Get("hideIdle") == 1
           and UnitMana("player") >= UnitManaMax("player")
           and not UnitAffectingCombat("player") then
            bar:Hide(); bar.text:Hide()
            return
        end

        local r, g, b = self:Colour("colTick")
        bar:SetMinMaxValues(0, total)
        bar:SetValue(total - (tickAt - now))
        bar:SetStatusBarColor(r, g, b)
        bar.spark:SetVertexColor(r, g, b)
        bar:Show()

        if self:Get("showText") == 1 and perTick > 0 then
            bar.text:SetText("+" .. perTick)
            bar.text:SetTextColor(self:Colour("colTick"))
            bar.text:Show()
        else
            bar.text:Hide()
        end

    else
        bar:Hide(); bar.text:Hide()
        return
    end

    if self:Get("spark") == 1 then
        local lo, hi = bar:GetMinMaxValues()
        local pct = (bar:GetValue() - lo) / (hi - lo)
        bar.spark:ClearAllPoints()
        bar.spark:SetPoint("CENTER", bar, "LEFT", pct * bar:GetWidth(), 0)
        bar.spark:Show()
    else
        bar.spark:Hide()
    end
end

--------------------------------------------------------------------- Events
local ev = CreateFrame("Frame")
ev:RegisterEvent("VARIABLES_LOADED")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:RegisterEvent("PLAYER_ALIVE")
ev:RegisterEvent("UNIT_MANA")
ev:RegisterEvent("UNIT_MAXMANA")
ev:RegisterEvent("UNIT_DISPLAYPOWER")

ev:SetScript("OnEvent", function()
    if event == "VARIABLES_LOADED" then
        if not XPerlManaTickConfig then XPerlManaTickConfig = {} end

        -- Die Standardwerte haben sich auf die WotLK-Geometrie geaendert.
        -- Ein gespeicherter Stand aus der ersten Fassung wuerde sie
        -- ueberstimmen, deshalb einmalig zuruecksetzen.
        if XPerlManaTickConfig.configVersion ~= 2 then
            XPerlManaTickConfig = { configVersion = 2 }
        end
        if XMT:Build() then
            XMT:ApplyLayout()
        else
            DEFAULT_CHAT_FRAME:AddMessage(
                "|cFF40FF40X-Perl ManaTick|r - Manabalken " .. MANABAR ..
                " nicht gefunden. Ist XPerl_Player aktiv?")
        end
        XMT:Reset()

    elseif event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_ALIVE" then
        XMT:ApplyLayout()
        XMT:Reset()

    elseif event == "UNIT_DISPLAYPOWER" then
        if arg1 == "player" then XMT:Reset() end

    elseif event == "UNIT_MANA" or event == "UNIT_MAXMANA" then
        if arg1 == "player" then XMT:ManaChanged() end
    end
end)

ev:SetScript("OnUpdate", function() XMT:OnUpdate() end)

SLASH_XPERLMANATICK1 = "/xpm"
SLASH_XPERLMANATICK2 = "/xperlmana"
SlashCmdList["XPERLMANATICK"] = function() XPerl_ManaTick_ToggleOptions() end
