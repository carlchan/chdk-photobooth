--[[
@title PhotoBooth SX110
@param a num: Shots to take
@default a 3
@param g first: Delay before first shot
@default g 3
@param b delay: Delay before each shot
@default b 2
@param c timeout: Delay before re-arm
@default c 3
@param d modect: MoDect threshold
@default d 2
@param f debug: Debug mode
@default f 0
--]]
--SX110 Face Detection version

-- Carl Chan 2013
-- carl@chanhome.ca

-- How many shots to take for each group
-- if shots is too low, make it 1
if a < 1 then a = 1 end

-- Amount of time to wait before each shot in series
-- If delay is too low, make it 1 second
if b < 1 then b = 1 end

-- Amount of time to wait for group to leave and new group to arrive
-- before re-arming motion detection
-- if delay is too low, make it 1 second
if c < 1 then c = 1 end

-- if sensitivity is out of range, make it sane
--if e < 1 then e = 1 end
--if e > 255 then e = 255 end
-- convert sensitivity to modect numbers
gain=d

----
function cameraready()
--	if( get_flash_mode() == 2 ) then
		if get_shooting() then
			return false
		else
			return true
		end
--	else
--		if get_flash_ready() then
--		if ( 
--			return true
--		else
--			print("Flash charging")
--			return false
--		end
--	end
end

function shootphoto()
-- initial delay
	for i=0,(b*2) do
		set_led(9,0,0)
		play_sound(4)
		sleep(250)
		set_led(9,1,30)
		sleep(250)
	end
--Pre-shoot warning, sound+led
	play_sound(3)
	sleep(1000)

	set_led(9,0,0)
	if( f > 0 ) then
		play_sound(1)
	else
		shoot()
	end
	sleep(500)
	repeat
		print("Waiting for camera to be ready")
		set_led(9,1,30)
		sleep(50)
		cls()
	until cameraready() == true
end

function facedect(timeout,interval)
--	face_count_addr=0x54D9C+6
	face_count_addr=0x54D9C+8
	time=0
	repeat
		time=time+interval
		facecount=peek(face_count_addr,2)
		if ( facecount > 0 ) then
			break
		else
			sleep(interval)
		end
	until time > timeout
	return facecount
end

function photobooth()
	if rec and not vid then
	-- remove all other display stuff
		set_prop_str(105,1)
		repeat
			cls()
			set_led(9,0,0)
			print("Photobooth ready!")
			zones=md_detect_motion(6,6,1,600000,10,gain,1,0,1,2,2,5,5,0,2,500)
			if( zones > 0 ) then
			--Turn on LED when initial motion is detected
				set_led(9,1,30)
				if ( facedect(1000,100) > 0 ) then
					--Start photo process
					print("Get ready!")
					for i=1,g do
						print(g-i+1)
						sleep(800)
						set_led(9,0,0)
						sleep(200)
						set_led(9,1,30)
					end
					print("Smile for the camera!")
					for i=1,a do
						print("Picture #" .. i .. "/" .. a)
						--Detect if faces found in image
						-- If group leaves before complete set is done, abort set
						if ( facedect(b*1000,100) > 0 ) then	
							shootphoto()
						else
							print("Where did you go??")
							break
						end
					end
					print("All done! Next!")
					set_led(9,0,0)
					for j=0,c do
						sleep(1000)
					end
				else
					print("False alarm, resetting")
					set_led(9,0,0)
				end
			end
			set_led(9,0,0)
		until false
	else
		print("Camera must be in photo mode")
		print("Photobooth stopped.")
	end
end

-- Main Loop
rec,vid,mode=get_mode()
if not rec then
	sleep(1000)
	print("Switching to record mode")
	repeat
		press("shoot_half")
		sleep(100)
		release("shoot_half")
		sleep(100)
		rec,vid,mode=get_mode()
	until rec 
end

repeat
	pcall(photobooth())
	sleep(1000)
until false
