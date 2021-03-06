/datum/game_mode/epidemic
	name = "epidemic"
	config_tag = "epidemic"
	required_players = 6

	var/const/waittime_l = 300 //lower bound on time before intercept arrives (in tenths of seconds)
	var/const/waittime_h = 600 //upper bound on time before intercept arrives (in tenths of seconds)
	var/checkwin_counter =0
	var/finished = 0

	var/cruiser_arrival

	var/virus_name = ""

	var/stage = 0

///////////////////////////
//Announces the game type//
///////////////////////////
/datum/game_mode/epidemic/announce()
	world << "<B>The current game mode is - Epidemic!</B>"
	world << "<B>A deadly epidemic is spreading on the station. Find a cure as fast as possible, and keep your distance to anyone who speaks in a hoarse voice!</B>"


///////////////////////////////////////////////////////////////////////////////
//Gets the round setup, cancelling if there's not enough players at the start//
///////////////////////////////////////////////////////////////////////////////
/datum/game_mode/epidemic/pre_setup()
	var/doctors = 0
	for(var/mob/new_player/player in world)
		if(player.mind.assigned_role in list("Chief Medical Officer","Medical Doctor"))
			doctors++
			break

	if(doctors < 1)
		return 0

	return 1

/datum/game_mode/epidemic/proc/cruiser_seconds()
	return (cruiser_arrival - world.time) / 10

////////////////////// INTERCEPT ////////////////////////
/// OVERWRITE THE INTERCEPT WITH A QUARANTINE WARNING ///
/////////////////////////////////////////////////////////

/datum/game_mode/epidemic/send_intercept()
	var/intercepttext = "<FONT size = 3 color='red'><B>CONFIDENTIAL REPORT</FONT><HR>"
	virus_name = "X-[rand(1,99)]&trade;"
	intercepttext += "<B>Warning: Pathogen [virus_name] has been detected on [station_name()].</B><BR><BR>"
	intercepttext += "<B>Code violet quarantine of [station_name()] put under immediate effect.</B><BR>"
	intercepttext += "<B>Class [rand(2,5)] cruiser has been dispatched. ETA: [round(cruiser_seconds() / 60)] minutes.</B><BR>"
	intercepttext += "<BR><B><FONT size = 2 color='blue'>Instructions</FONT></B><BR>"
	intercepttext += "<B>* ELIMINATE THREAT WITH EXTREME PREJUDICE. [virus_name] IS HIGHLY CONTAGIOUS. INFECTED CREW MEMBERS MUST BE QUARANTINED IMMEDIATELY.</B><BR>"
	intercepttext += "<B>* [station_name()] is under QUARANTINE. Any vessels outbound from [station_name()] will be tracked down and destroyed.</B><BR>"
	intercepttext += "<B>* The existence of [virus_name] is highly confidential. To prevent a panic, only high-ranking staff members are authorized to know of its existence. Crew members that illegally obtained knowledge of [virus_name] are to be neutralized.</B><BR>"
	intercepttext += "<B>* A cure is to be researched immediately, but NanoTrasen intellectual property must be respected. To prevent knowledge of [virus_name] from falling into unauthorized hands, all medical staff that work with the pathogen must be enhanced with a NanoTrasen loyality implant.</B><BR>"


	for (var/obj/machinery/computer/communications/comm in world)
		if (!(comm.stat & (BROKEN | NOPOWER)) && comm.prints_intercept)
			var/obj/item/weapon/paper/intercept = new /obj/item/weapon/paper( comm.loc )
			intercept.name = "paper"
			intercept.info = intercepttext

			comm.messagetitle.Add("Cent. Com. CONFIDENTIAL REPORT")
			comm.messagetext.Add(intercepttext)
	world << sound('sound/announcer/commandreport.ogg')

/datum/game_mode/epidemic/proc/announce_to_kill_crew()
	var/intercepttext = "<FONT size = 3 color='red'><B>CONFIDENTIAL REPORT</FONT><HR>"
	intercepttext += "<FONT size = 2;color='red'><B>PATHOGEN [virus_name] IS STILL PRESENT ON [station_name()]. IN COMPLIANCE WITH NANOTRASEN LAWS FOR INTERSTELLAR SAFETY, EMERGENCY SAFETY MEASURES HAVE BEEN AUTHORIZED. ALL INFECTED CREW MEMBERS ON [station_name()] ARE TO BE NEUTRALIZED AND DISPOSED OF IN A MANNER THAT WILL DESTROY ALL TRACES OF THE PATHOGEN. FAILURE TO COMPLY WILL RESULT IN IMMEDIATE DESTRUCTION OF [station_name].</B></FONT><BR>"
	intercepttext += "<B>CRUISER WILL ARRIVE IN [round(cruiser_seconds()/60)] MINUTES</B><BR>"

	for (var/obj/machinery/computer/communications/comm in world)
		if (!(comm.stat & (BROKEN | NOPOWER)) && comm.prints_intercept)
			var/obj/item/weapon/paper/intercept = new /obj/item/weapon/paper( comm.loc )
			intercept.name = "paper"
			intercept.info = intercepttext

			comm.messagetitle.Add("Cent. Com. CONFIDENTIAL REPORT")
			comm.messagetext.Add(intercepttext)
	world << sound('sound/announcer/commandreport.ogg')


/datum/game_mode/epidemic/post_setup()
	var/list/crew = list()
	for(var/mob/living/carbon/human/H in world) if(H.client)
		crew += H

	if(crew.len < 2)
		world << "\red There aren't enough players for this mode!"

	var/datum/disease2/disease/lethal = new
	lethal.makerandom(1)
	lethal.infectionchance = 5

	var/datum/disease2/disease/nonlethal = new
	nonlethal.makerandom(0)
	nonlethal.infectionchance = 0

	for(var/i = 0, i < crew.len / 3, i++)
		var/mob/living/carbon/human/H = pick(crew)
		if(H.virus2)
			i--
			continue
		H.virus2 = lethal.getcopy()

	for(var/i = 0, i < crew.len / 3, i++)
		var/mob/living/carbon/human/H = pick(crew)
		if(H.virus2)
			continue
		H.virus2 = nonlethal.getcopy()

	cruiser_arrival = world.time + (10 * 90 * 60)
	stage = 1

	spawn (rand(waittime_l, waittime_h))
		send_intercept()


	..()


/datum/game_mode/epidemic/process()
	if(stage == 1 && cruiser_seconds() < 60 * 30)
		announce_to_kill_crew()
		stage = 2
	else if(stage == 2 && cruiser_seconds() <= 0)
		crew_lose()
		stage = 3

	checkwin_counter++
	if(checkwin_counter >= 20)
		if(!finished)
			ticker.mode.check_win()
		checkwin_counter = 0
	return 0

//////////////////////////////////////
//Checks if the revs have won or not//
//////////////////////////////////////
/datum/game_mode/epidemic/check_win()
	var/alive = 0
	var/sick = 0
	for(var/mob/living/carbon/human/H in world)
		if(H.key && H.stat != 2) alive++
		if(H.virus2 && H.stat != 2) sick++

	if(alive == 0)
		finished = 2
	if(sick == 0)
		finished = 1
	return

///////////////////////////////
//Checks if the round is over//
///////////////////////////////
/datum/game_mode/epidemic/check_finished()
	if(finished != 0)
		return 1
	else
		return 0

///////////////////////////////////////////
///Handle crew failure(station explodes)///
///////////////////////////////////////////
/datum/game_mode/epidemic/proc/crew_lose()
	ticker.mode:explosion_in_progress = 1
	for(var/mob/M in world)
		if(M.client)
			M << 'sound/machines/Alarm.ogg'
	world << "\blue<b>Incoming missile detected.. Impact in 10..</b>"
	for (var/i=9 to 1 step -1)
		sleep(10)
		world << "\blue<b>[i]..</b>"
	sleep(10)
	enter_allowed = 0
	for(var/mob/M in world)
		if(M.client)
			spawn(0)
				M.client.station_explosion_cinematic()
	sleep(110)
	ticker.mode:station_was_nuked = 1
	ticker.mode:explosion_in_progress = 0
	return


//////////////////////////////////////////////////////////////////////
//Announces the end of the game with all relavent information stated//
//////////////////////////////////////////////////////////////////////
/datum/game_mode/epidemic/declare_completion()
	if(finished == 1)
		feedback_set_details("round_end_result","win - epidemic cured")
		world << "\red <FONT size = 3><B> The virus outbreak was contained! The crew wins!</B></FONT>"
	else if(finished == 2)
		feedback_set_details("round_end_result","loss - rev heads killed")
		world << "\red <FONT size = 3><B> The crew succumbed to the epidemic!</B></FONT>"
	..()
	return 1