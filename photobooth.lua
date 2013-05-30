--[[
@title PhotoBooth
@param a num: Shots to take
@default a 3
@param b delay: Delay before each shot
@default b 2
@param c timeout: Delay before re-arm
@default c 3
@param d delay: Verify time
@default d 2
@param e modect: MoDect Threshold (1-255)
@default e 3
@param f debug: Debug mode
@default f 0
--]]

-- Carl Chan 2012
-- carl.chan@proudlygeeky.net

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

-- Amount of continuous motion detected before starting shoot series
-- 0 or lower means disable this check
if d < 1 then d = 0 end

-- if sensitivity is out of range, make it sane
if e < 1 then e = 1 end
if e > 255 then e = 255 end
-- convert sensitivity to modect numbers
gain=e

----
function cameraready()
  if( get_flash_mode() == 2 ) then
		if get_shooting() then
			return false
		else
			return true
		end
	else
		if( get_shooting() == false ) and ( get_flash_ready() == true) then
			return true
		else
			return false
		end
	end
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
	sleep(100)
	if( f > 0 ) then
		play_sound(1)
	else
		shoot()
	end
	repeat 
		set_led(9,1,30)
		sleep(50)
	until cameraready() == true
end

--detect continuous motions for TIME seconds
--returns true if there was motion detected more than 50% of the time in the interval specified
function continuousmotion( time )
	if( time == 0 ) then
		return true
	else
		motion=0
		loop=time
		for i=1,loop do
			contmotion=md_detect_motion(6,6,1,1000,10,gain,f,0,1,2,2,5,5,0,2,0)
			if( contmotion > 0 ) then
				sleep(950)
				motion=motion+1
			end
		end
		if( motion == time ) then	
			return true
		else
			return false
		end
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
		--Motion detected, check for d seconds of continuous motion before starting series
		--This prevents accidental triggering of photobooth if someone is just walking by
			if ( continuousmotion(d) ) then	
			--Start photo process
				print("Smile for the camera!")
				for i=1,a do
					-- If group leaves before complete set is done, abort set
					print("Picture #" .. i .. "/" .. a)
					if ( md_detect_motion(7,7,1,b*1000,10,gain,f,0,1,2,2,6,6,0,2,500) == 0 ) then
						print("Where did you go??")
						break
					end
					shootphoto()
				end
				print("All done! Next!")
				set_led(9,0,0)
				for j=0,c do
					sleep(1000)
				end
			end
		end
		set_led(9,0,0)
	until false
else
	print("Camera must be in photo mode")
	print("Photobooth stopped.")
end
