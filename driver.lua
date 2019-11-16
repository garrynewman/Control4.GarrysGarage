do 
	State = "Closed";
	PartiallyOpen = false;
	FullyOpen = false;
	RelayTimer = -1;
	C4:AddVariable( "State", State, "STRING" )
	UpdateImageState()
end

--
-- TODO - update the state based on external programming
--
function OnVariableChanged( varname )

	if (varname == "State") then
		-- TODO
	end

 end

 --
 -- Try to set the state based on current sensor states
 -- todo: Could we query the sensor state more directly?
 --
function UpdateImageState()

	newState = "Closed";
	if ( PartiallyOpen ) then newState = "Half" end
	if ( FullyOpen ) then newState = "Open" end

	UpdateState( newState );

end

function UpdateState( newState )

	if ( State == newState ) then return end

	State = newState;
	print( "State Changed To " .. State )

	-- Change the button icon
	C4:SendToProxy(5001, "ICON_CHANGED", {icon = State})

	-- Show the state on the driver dashboard
	C4:UpdateProperty( 'Current State', State )

end

function ReceivedFromProxy (idBinding, strCommand, tParams)

	--
	-- Messages from the UI Button
	--
	if ( idBinding == 5001 ) then
		if ( strCommand == "SELECT" ) then

			print( "Closing Door Relay" )

			--
			-- Open the relay again in one second
			--
			RelayTimer = C4:AddTimer( 1, "SECONDS", false )

			--
			-- Close the relay
			--
			C4:SendToProxy (1, "OPEN", '')
			C4:SendToProxy (1, "CLOSE", '')

			--
			-- If we started off closed, show the Opening state to give some immediate feedback
			--
			if ( State == "Closed") then 
				UpdateState( "Opening" )
			end

			--
			-- If we started off open, show the Closing state to give some immediate feedback
			--
			if ( State == "Open") then 
				UpdateState( "Closing" )
			end

			return
		end
	end

	--
	-- Messages from the Relay - Ignored
	--
	if ( idBinding == 1 ) then 
		return;
	end

	--
	-- Messages from Partially Opened sensor
	--
	if ( idBinding == 2 ) then 
		if ( strCommand == "OPENED") then PartiallyOpen = true end
		if ( strCommand == "CLOSED") then PartiallyOpen = false end
		UpdateImageState();
		return;
	end

	--
	-- Messages from Fully Opened sensor
	--
	if ( idBinding == 3 ) then 
		if ( strCommand == "OPENED") then FullyOpen = true end
		if ( strCommand == "CLOSED") then FullyOpen = false end
		UpdateImageState();
		return;
	end

	--
	-- Missed messages, lets just print them out
	--

	print ( idBinding .. ": " .. strCommand  )
	print ( "0 = " .. tParams[1]  )
	print ( "1 = " .. tParams[2]  )
	print ( "2 = " .. tParams[3]  )

end

function OnTimerExpired(idTimer)

	--
	-- I don't know if this is thr right way to "press" relays
	-- but this is what I came up with.
	--
	if ( idTimer == RelayTimer ) then 
		print( "Opening Door Relay" )
		C4:SendToProxy (1, "OPEN", '')
		RelayTimer = -1;
	end

end