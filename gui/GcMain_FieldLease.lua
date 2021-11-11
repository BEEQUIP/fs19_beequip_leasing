--
-- GlobalCompany - AddOn - Gc_Gui_AddOn_FieldLease
--
-- @Interface: --
-- @Author: LS-Modcompany / kevink98
-- @Date: 14.04.2020
-- @Version: 1.0.0.0
--
-- @Support: LS-Modcompany
--
-- Changelog:
--
-- 	v1.0.0.0 (14.04.2020):
-- 		- initial Script Fs19 (kevink98)
--
-- Notes:
--
--
-- ToDo:
-- 
--
--

Gc_Gui_AddOn_FieldLease = {}
local Gc_Gui_AddOn_FieldLease_mt = Class(Gc_Gui_AddOn_FieldLease)
Gc_Gui_AddOn_FieldLease.xmlFilename = g_currentModDirectory .. "gui/GcMain_FieldLease.xml"
Gc_Gui_AddOn_FieldLease.debugIndex = g_company.debug:registerScriptName("Gc_Gui_AddOn_FieldLease")

Gc_Gui_AddOn_FieldLease.MODE_BUY = 1
Gc_Gui_AddOn_FieldLease.MODE_SELL = 2
Gc_Gui_AddOn_FieldLease.MODE_LEASE = 3
Gc_Gui_AddOn_FieldLease.MODE_LEASESTOP = 4

function Gc_Gui_AddOn_FieldLease:new()
	local self = setmetatable({}, Gc_Gui_AddOn_FieldLease_mt)    
	self.name = "AddOnFieldLease"	
	return self
end

function Gc_Gui_AddOn_FieldLease:keyEvent(unicode, sym, modifier, isDown, eventUsed) end
function Gc_Gui_AddOn_FieldLease:onClose() 
	g_company.addOnFieldLease:removeUpdateableList(self)
end
function Gc_Gui_AddOn_FieldLease:onCreate() end
function Gc_Gui_AddOn_FieldLease:update(dt) end

function Gc_Gui_AddOn_FieldLease:onOpen()
	self:loadTable()
	self:setInfo()
	self.gui_btn_buy:setDisabled(true)
	self.gui_btn_sell:setDisabled(true)
	self.gui_btn_lease:setDisabled(true)
	self.gui_btn_leaseStop:setDisabled(true)
	self.currentSelectedEquipment = nil
	g_company.addOnFieldLease:addUpdateableList(self, self.loadTable)
end

function Gc_Gui_AddOn_FieldLease:onClickClose()
    g_company.gui:closeActiveGui()
end

function Gc_Gui_AddOn_FieldLease:loadTable()
	self.gui_fieldList:removeElements()
	for _, vehicle in pairs(g_storeManager:getItems()) do
        if vehicle.allowLeasing then
			self.currentField = vehicle
			local item = self.gui_fieldList:createItem()
			item.vehicle = vehicle
	    end
	end
end

function Gc_Gui_AddOn_FieldLease:onCreateTextField(element)
	if self.currentField ~= nil then
        if self.currentField.brandIndex ~= nil then
	        local brandName = g_brandManager.indexToBrand[self.currentField.brandIndex].name
			element:setText(string.format('%s %s', brandName, self.currentField.name))
		else
			element:setText(string.format(self.currentField.name))
		end
	end
end

function Gc_Gui_AddOn_FieldLease:onCreateTextPrice(element)
	if self.currentField ~= nil then
		element:setText(string.format(self.currentField.price))
	end
end

function Gc_Gui_AddOn_FieldLease:isOwned(vehicleId) 
	for _, item in pairs(g_currentMission.ownedItems) do
		if item.storeItem.id == vehicleId then
			return true	
		end
	end

	return false
end

function Gc_Gui_AddOn_FieldLease:isLeased(vehicleId) 
	for _, item in pairs(g_currentMission.leasedVehicles) do
		if item.storeItem.id == vehicleId then
			return true	
		end
	end

	return false
end

function Gc_Gui_AddOn_FieldLease:getVehicle(storeItemId)
	for _, item in pairs(g_currentMission.leasedVehicles) do
		if item.storeItem.id == storeItemId then
			return item
		end
	end

	return nil
end

function Gc_Gui_AddOn_FieldLease:onCreateTextState(element)
	if self.currentField ~= nil then
		if Gc_Gui_AddOn_FieldLease:isOwned(self.currentField.id) then
			element:setText("Bought")
		else
			if Gc_Gui_AddOn_FieldLease:isLeased(self.currentField.id) then
				element:setText("Leased")
			else
				element:setText('Available')
			end
		end
	end
end

function Gc_Gui_AddOn_FieldLease:onCreateEquipmentImage(element)
	if self.currentField ~= nil then
		element:setImageFilename(self.currentField.imageFilename)
	end
end

function Gc_Gui_AddOn_FieldLease:onSelect(element)
	self.currentSelectedEquipment = element.vehicle

	local isOwned = Gc_Gui_AddOn_FieldLease:isOwned(self.currentSelectedEquipment.id)
	local isLeased = Gc_Gui_AddOn_FieldLease:isLeased(self.currentSelectedEquipment.id)

	self.gui_btn_buy:setDisabled(isOwned == true or isLeased == true)
	self.gui_btn_sell:setDisabled(isOwned == false or isLeased == true)
	self.gui_btn_lease:setDisabled(isLeased == true or isOwned == true)
	self.gui_btn_leaseStop:setDisabled(isLeased == false)
end

function Gc_Gui_AddOn_FieldLease:onClickBuy()
	self.currentMode = self.MODE_BUY

	local text = string.format("You can buy the equipment for %s", g_i18n:formatMoney(self.currentSelectedEquipment.price))
	g_company.gui:closeGui("gc_main")
	g_gui:showYesNoDialog({text = text, title = "", callback = self.onConfirm, target = self})
end

function Gc_Gui_AddOn_FieldLease:onClickSell()
	self.currentMode = self.MODE_SELL
	local text = string.format("You can sell this equipment")
	g_company.gui:closeGui("gc_main")
	g_gui:showYesNoDialog({text = text, title = "Are you sure?", callback = self.onConfirm, target = self})
end

function Gc_Gui_AddOn_FieldLease:onClickLease()
	self.currentMode = self.MODE_LEASE

	local annuityCalculation = Gc_Gui_AddOn_FieldLease:calcAnnuity(self.currentSelectedEquipment)

	local text = string.format("You can lease the equipment for %s per day. \n You will lease for %s days. \n The downpayment upfront is %s. \n At the end you'll have to pay %s balloon payment. \n Do you accept these terms?", g_i18n:formatMoney(annuityCalculation.annuity), annuityCalculation.tenor, g_i18n:formatMoney(annuityCalculation.downPayment), g_i18n:formatMoney(annuityCalculation.balloonPayment))
	g_company.gui:closeGui("gc_main")
	g_gui:showYesNoDialog({text = text, title = "Are you sure?", callback = self.onConfirm, target = self})
end

function Gc_Gui_AddOn_FieldLease:onClickLeaseStop()
	self.currentMode = self.MODE_LEASESTOP
	local text = string.format("You can stop leasing this equipment")
end

function Gc_Gui_AddOn_FieldLease:onConfirm(confirm)
    print("confirm")

	if confirm then
		if self.currentMode == self.MODE_BUY then
			g_storeManager.addVehicle(g_currentMission, self.currentSelectedEquipment)
		elseif self.currentMode == self.MODE_SELL then
			g_currentMission.removeVehicle(Gc_Gui_AddOn_FieldLease:getVehicle(self.currentSelectedEquipment.id))
		elseif self.currentMode == self.MODE_LEASE then
			FSBaseMission.addLeasedItem(g_currentMission, self.currentSelectedEquipment)
		elseif self.currentMode == self.MODE_LEASESTOP then
			g_currentMission.removeVehicle(Gc_Gui_AddOn_FieldLease:getVehicle(self.currentSelectedEquipment.id)) 
		end
	end
	g_company.gui:openGui("gc_main")
	self.currentMode = nil
	self:loadTable()
	self:setInfo()
end

function Gc_Gui_AddOn_FieldLease:setInfo()
	local bought = 0
	local leased = 0

	for _, leasedVehicle in pairs(g_currentMission.leasedVehicles) do
		leased = leased + Gc_Gui_AddOn_FieldLease:calcAnnuity(leasedVehicle.storeItem).annuity
	end

	-- for _, boughtVehicle in pairs(g_currentMission.ownedItems) do
	-- 	bought = bought + boughtVehicle.storeItem.price
	-- end

	-- self.gui_info_1:setText(string.format("Amount of equipment bought %s", g_i18n:formatMoney(bought)))
	self.gui_info_2:setText(string.format("Total lease amount per day %s", g_i18n:formatMoney(g_company.addOnFieldLease:calcPrice(leased))))
end

function Gc_Gui_AddOn_FieldLease:calcMonthlyInterest(yearlyInterest)
  return yearlyInterest / 12
end


-- # Pmt = Payment per month
-- # PV = Present value
-- # FV = Balloon payment
-- # i = Monthly interest
-- # n = Months
-- # a = Advanced payment
-- #
-- #                  FV
-- #         PV - -----------
-- #               (1 + i)^n
-- # Pmt = ----------------------
-- #        |          1        |
-- #        |  1 - -----------  |
-- #        |       (1 + i)^n-a |
-- #        | ----------------- |
-- #        |         i         |
function Gc_Gui_AddOn_FieldLease:monthlyPayment(principal, months, balloonPayment, yearlyInterest)
	local interest = Gc_Gui_AddOn_FieldLease:calcMonthlyInterest(yearlyInterest)

	return (principal - (balloonPayment / (1 + interest)^months)) / ((1 - (1 / (1 + interest)^(months))) / interest)
end


function Gc_Gui_AddOn_FieldLease:calcAnnuity(vehicle)
	local tenor = 60
	local purchasePrice = vehicle.price
	local downpaymentPercentage = 0.10
	local downPayment = purchasePrice * downpaymentPercentage
	local principal = purchasePrice - downPayment
	local balloonPayment = 1000
	local annuity = Gc_Gui_AddOn_FieldLease:monthlyPayment(principal, tenor, balloonPayment, 0.06)

	return {
		annuity = annuity,
		downPayment = downPayment,
		tenor = tenor,
		balloonPayment = balloonPayment
	}
end


function table_print (tt, indent, done)
	done = done or {}
	indent = indent or 0
	if type(tt) == "table" then
	  for key, value in pairs (tt) do
		io.write(string.rep (" ", indent)) -- indent it
		if type (value) == "table" and not done [value] then
		  done [value] = true
		  io.write(string.format("[%s] => table\n", tostring (key)));
		  io.write(string.rep (" ", indent+4)) -- indent it
		  io.write("(\n");
		  table_print (value, indent + 7, done)
		  io.write(string.rep (" ", indent+4)) -- indent it
		  io.write(")\n");
		else
		  io.write(string.format("[%s] => %s\n",
			  tostring (key), tostring(value)))
		end
	  end
	else
	  io.write(tt .. "\n")
	end
  end