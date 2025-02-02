local W, F, E, L = unpack(select(2, ...))
local S = W.Modules.Skins

local _G = _G
local pairs = pairs

function S:BugSack_InterfaceOptionOnShow(frame)
    if frame.__windSkin then
        return
    end

    if _G.BugSackFontSize then
        local dropdown = _G.BugSackFontSize
        self:ESProxy("HandleDropDownBox", dropdown)

        local point, relativeTo, relativePoint, xOffset, yOffset = dropdown:GetPoint(1)
        dropdown:ClearAllPoints()
        dropdown:SetPoint(point, relativeTo, relativePoint, xOffset - 1, yOffset)

        dropdown.__windSkinMarked = true
    end

    if _G.BugSackSoundDropdown then
        local dropdown = _G.BugSackSoundDropdown
        self:ESProxy("HandleDropDownBox", dropdown)

        local point, relativeTo, relativePoint = dropdown:GetPoint(1)
        dropdown:ClearAllPoints()
        dropdown:SetPoint(point, relativeTo, relativePoint)

        dropdown.__windSkinMarked = true
    end

    for _, child in pairs {frame:GetChildren()} do
        if child.__windSkinMarked then
            child.__windSkinMarked = nil
        else
            local objectType = child:GetObjectType()
            if objectType == "Button" then
                self:ESProxy("HandleButton", child)
            elseif objectType == "CheckButton" then
                self:ESProxy("HandleCheckBox", child)

                -- fix master channel checkbox position
                local point, relativeTo, relativePoint = child:GetPoint(1)
                if point == "LEFT" and relativeTo == _G.BugSackSoundDropdown then
                    child:ClearAllPoints()
                    child:SetPoint(point, relativeTo, relativePoint, 0, 3)
                end
            end
        end
    end

    frame.__windSkin = true
end

function S:BugSack_OpenSack()
    if _G.BugSackFrame.__windSkin then
        return
    end

    local bugSackFrame = _G.BugSackFrame

    bugSackFrame:StripTextures()
    bugSackFrame:SetTemplate("Transparent")
    self:CreateShadow(bugSackFrame)

    for _, child in pairs {bugSackFrame:GetChildren()} do
        local numRegions = child:GetNumRegions()

        if numRegions == 1 then
            local text = child:GetRegions()
            if text and text:GetObjectType() == "FontString" then
                F.SetFontOutline(text)
            end
        elseif numRegions == 4 then
            self:ESProxy("HandleCloseButton", child)
        end
    end

    self:ESProxy("HandleScrollBar", _G.BugSackScrollScrollBar)

    for _, region in pairs {_G.BugSackScrollText:GetRegions()} do
        if region and region:GetObjectType() == "FontString" then
            F.SetFontOutline(region)
        end
    end

    self:ESProxy("HandleButton", _G.BugSackNextButton)
    self:ESProxy("HandleButton", _G.BugSackPrevButton)
    self:ESProxy("HandleButton", _G.BugSackSendButton)

    local tabs = {
        _G.BugSackTabAll,
        _G.BugSackTabLast,
        _G.BugSackTabSession
    }

    for _, tab in pairs(tabs) do
        self:ESProxy("HandleTab", tab)
        self:CreateBackdropShadow(tab)

        local point, relativeTo, relativePoint, xOffset, yOffset = tab:GetPoint(1)

        tab:ClearAllPoints()

        if yOffset ~= 0 then
            yOffset = -2
        end

        tab:SetPoint(point, relativeTo, relativePoint, xOffset, yOffset)
    end

    bugSackFrame.__windSkin = true
end

function S:BugSack()
    if not E.private.WT.skins.enable or not E.private.WT.skins.addons.bugSack then
        return
    end

    if not _G.BugSack then
        return
    end

    self:SecureHookScript(_G.BugSack.frame, "OnShow", "BugSack_InterfaceOptionOnShow")
    self:SecureHook(_G.BugSack, "OpenSack", "BugSack_OpenSack")
    self:DisableAddOnSkin("BugSack")
end

S:AddCallbackForAddon("BugSack")
