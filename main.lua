local addonName, addonTable = ...

local Heirloom = LibStub('AceAddon-3.0'):NewAddon('Multiboxer_Heirloom', 'AceEvent-3.0')
addonTable[1] = Heirloom
_G[addonName] = Heirloom

local StdUi = LibStub('StdUi')


function Heirloom:OnInitialize()
    return
end

function Heirloom:OnEnable()
    self:RegisterEvent("DELETE_ITEM_CONFIRM")
    self:MainFrame()
end

function Heirloom:DELETE_ITEM_CONFIRM()
    self.hashTable = nil
end

function Heirloom:MainFrame()
    local mainFrame = StdUi:Frame(UIParent, 300, 300)
    mainFrame:SetPoint('TOPRIGHT', UIParent, 'TOPRIGHT', - self.position.left or 0, - self.position.down or 0)
    self.mainFrame = mainFrame

    local setFrames = {}
    mainFrame.setFrames = setFrames
    local i = 0
    for setName, _ in pairs(self.heirloomSets) do
        i = i + 1
        local setFrame = StdUi:Frame(self.mainFrame, 300, 50)

        -- equip looms btn
        local equipBtn = StdUi:Button(setFrame, 60, 30, 'Equip Looms')
        equipBtn:SetPoint('TOPRIGHT', setFrame, 'TOPRIGHT', -15, -15)
        equipBtn:SetScript('OnClick', function()
            self.hashTable = self.hashTable or self:HashTable(setName)
            local equipTable = {} -- hash table for dual equipment slots
            for bag = 0, 4 do
                for slot = 1, GetContainerNumSlots(bag) do
                    local itemID = GetContainerItemID(bag, slot)
                    if self.hashTable[itemID] ~= nil then
                        ClearCursor()
                        PickupContainerItem(bag, slot)
                        
                        local invSlots = self:GetItemInvetorySlot(itemID)
                        if #invSlots > 1 then
                            if equipTable[invSlots[1]] then
                                EquipCursorItem(invSlots[2])
                            else
                                EquipCursorItem(invSlots[1])
                                equipTable[invSlots[1]] = true
                            end
                        else
                            print(invSlots[1])
                            EquipCursorItem(invSlots[1])
                        end
                    end
                end
            end
        end)

        -- create loom btn
        local createBtn = StdUi:Button(setFrame, 60, 30, 'Create Loom')
        createBtn:SetPoint('TOPRIGHT', equipBtn, 'TOPLEFT', -10, 0)
        createBtn:SetScript('OnClick', function()
            self.hashTable = self.hashTable or self:HashTable(setName)
            table.foreach(self.hashTable, print)
            for itemID, createQty in pairs(self.hashTable) do
                if createQty > 0 then 
                    C_Heirloom.CreateHeirloom(itemID)
                    self.hashTable[itemID] = self.hashTable[itemID] - 1
                    break
                end
            end
        end)

        -- setFrame Name
        local name = StdUi:Label(setFrame, setName, 12)
        name:SetPoint('RIGHT', createBtn, 'LEFT', -10, 0)

        -- anchor setFrames
        if i == 1 then
            setFrame:SetPoint('TOPLEFT', mainFrame, 'TOPLEFT', 0, 0)
        else
            setFrame:SetPoint('TOP', setFrames[i-1], 'BOTTOM', 0, -2)
        end
        setFrames[i] = setFrame
    end
end


function Heirloom:HashTable(setName)
    local table = {}
    for _, itemID in ipairs(self.heirloomSets[setName]) do
        -- handle sets with duplicate items (weapons/trinkets)
        table[itemID] = table[itemID] or 0
        table[itemID] = table[itemID] + 1
    end

    for itemID, qty in pairs(table) do
        table[itemID] = table[itemID] - self:QtyInBagsOrEquipped(itemID)
    end

    return table
end

function Heirloom:QtyInBagsOrEquipped(itemID)
    local heirloomCount = 0
    -- in bags
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local id = GetContainerItemID(bag, slot)
            if id == itemID then
                heirloomCount = heirloomCount + 1
            end
        end
    end
    -- equipped
    invSlots = self:GetItemInvetorySlot(itemID)
    for _, invSlot in ipairs(invSlots) do
        if GetInventoryItemID('player', invSlot) == itemID then
            heirloomCount = heirloomCount + 1
        end
    end
    
    return heirloomCount
end

function Heirloom:GetItemInvetorySlot(itemID)
    local invType = select(9, GetItemInfo(itemID))
    local invSlot
    if strfind(invType, '2HWEAPON') then
        invSlot = {16}
    elseif strfind(invType, 'CLOAK') then
        invSlot = {15}
    elseif strfind(invType, 'WEAPON') then
        invSlot = {16, 17}
    elseif strfind(invType, 'FINGER') then
        invSlot = {11, 12}
    elseif strfind(invType, 'TRINKET') then
        invSlot = {13, 14}
    elseif strfind(invType, 'ROBE') then
        invSlot = {5}
    else
        invSlot = {_G[invType:gsub('TYPE', 'SLOT')]}
    end
    return invSlot
end