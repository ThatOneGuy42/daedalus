/*CONTENTS
General Computer
Security Computer
Comm Computer
ID Computer
Pod/Blast Doors computer
*/

/obj/machinery/computer/New()
	..()
	spawn(2)
		power_change()

/obj/machinery/computer/emp_act(severity)
	if(prob(20/severity)) set_broken()
	..()

/obj/machinery/computer/ex_act(severity)
	switch(severity)
		if(1.0)
			del(src)
			return
		if(2.0)
			if (prob(25))
				del(src)
				return
			if (prob(50))
				for(var/x in verbs)
					verbs -= x
				set_broken()
		if(3.0)
			if (prob(25))
				for(var/x in verbs)
					verbs -= x
				set_broken()
		else
	return

/obj/machinery/computer/blob_act()
	if (prob(75))
		for(var/x in verbs)
			verbs -= x
		set_broken()
		density = 0

/obj/machinery/computer/power_change()
	if(!istype(src,/obj/machinery/computer/security/telescreen))
		if(stat & BROKEN)
			icon_state = initial(icon_state)
			icon_state += "b"
			if (istype(src,/obj/machinery/computer/aifixer))
				overlays = null

		else if(powered())
			icon_state = initial(icon_state)
			stat &= ~NOPOWER
			if (istype(src,/obj/machinery/computer/aifixer))
				var/obj/machinery/computer/aifixer/O = src
				if (O.occupant)
					switch (O.occupant.stat)
						if (0)
							overlays += image('icons/obj/computer.dmi', "ai-fixer-full")
						if (2)
							overlays += image('icons/obj/computer.dmi', "ai-fixer-404")
				else
					overlays += image('icons/obj/computer.dmi', "ai-fixer-empty")
		else
			spawn(rand(0, 15))
				//icon_state = "c_unpowered"
				icon_state = initial(icon_state)
				icon_state += "0"
				stat |= NOPOWER
				if (istype(src,/obj/machinery/computer/aifixer))
					overlays = null

/obj/machinery/computer/process()
	if(stat & (NOPOWER|BROKEN))
		return
	use_power(250)

/obj/machinery/computer/proc/set_broken()
	icon_state = initial(icon_state)
	icon_state += "b"
	stat |= BROKEN

/obj/machinery/computer/attackby(I as obj, user as mob)
	if(istype(I, /obj/item/weapon/screwdriver) && circuit)
		playsound(src.loc, 'sound/items/Screwdriver.ogg', 50, 1)
		if(do_after(user, 20))
			var/obj/structure/computerframe/A = new /obj/structure/computerframe( src.loc )
			var/obj/item/weapon/circuitboard/M = new circuit( A )
			A.circuit = M
			A.anchored = 1
			for (var/obj/C in src)
				C.loc = src.loc
			if (src.stat & BROKEN)
				user << "\blue The broken glass falls out."
				new /obj/item/weapon/shard( src.loc )
				A.state = 3
				A.icon_state = "3"
			else
				user << "\blue You disconnect the monitor."
				A.state = 4
				A.icon_state = "4"
			del(src)
	else
		src.attack_hand(user)
	return


/obj/machinery/computer/security/New()
	..()
	verbs -= /obj/machinery/computer/security/verb/station_map

/obj/machinery/computer/security/attack_ai(var/mob/user as mob)
	return attack_hand(user)

/obj/machinery/computer/security/attack_paw(var/mob/user as mob)
	return attack_hand(user)

/obj/machinery/computer/security/check_eye(var/mob/user as mob)
	if ((get_dist(user, src) > 1 || !( user.canmove ) || user.blinded || !( current ) || !( current.status )) && (!istype(user, /mob/living/silicon)))
		return null
	user.reset_view(current)
	return 1


/obj/datacore/proc/manifest(var/nosleep = 0)
	spawn()
		if(!nosleep)
			sleep(40)
		for(var/mob/living/carbon/human/H in world)
			if (!isnull(H.mind) && (H.mind.assigned_role != "MODE"))
				var/datum/data/record/G = new()
				var/datum/data/record/M = new()
				var/datum/data/record/S = new()
				var/datum/data/record/L = new()
				var/obj/item/weapon/card/id/C = H.wear_id
				if (C)
					G.fields["rank"] = C.assignment
					G.fields["real_rank"] = H.mind.assigned_role
				else
					if(H.mind && H.mind.assigned_role)
						G.fields["rank"] = H.mind.role_alt_title ? H.mind.role_alt_title : H.mind.assigned_role
						G.fields["real_rank"] = H.mind.assigned_role
					else
						G.fields["rank"] = "Unassigned"
						G.fields["real_rank"] = G.fields["rank"]
				G.fields["name"] = H.real_name
				G.fields["id"] = text("[]", add_zero(num2hex(rand(1, 1.6777215E7)), 6))
				M.fields["name"] = G.fields["name"]
				M.fields["id"] = G.fields["id"]
				S.fields["name"] = G.fields["name"]
				S.fields["id"] = G.fields["id"]
				if (H.gender == FEMALE)
					G.fields["sex"] = "Female"
				else
					G.fields["sex"] = "Male"
				G.fields["age"] = text("[]", H.age)
				G.fields["fingerprint"] = text("[]", md5(H.dna.uni_identity))
				G.fields["p_stat"] = "Active"
				G.fields["m_stat"] = "Stable"
				M.fields["b_type"] = text("[]", H.dna.b_type)
				M.fields["b_dna"] = H.dna.unique_enzymes
				M.fields["mi_dis"] = "None"
				M.fields["mi_dis_d"] = "No minor disabilities have been declared."
				M.fields["ma_dis"] = "None"
				M.fields["ma_dis_d"] = "No major disabilities have been diagnosed."
				M.fields["alg"] = "None"
				M.fields["alg_d"] = "No allergies have been detected in this patient."
				M.fields["cdi"] = "None"
				M.fields["cdi_d"] = "No diseases have been diagnosed at the moment."
				M.fields["notes"] = "No notes."
				S.fields["criminal"] = "None"
				S.fields["mi_crim"] = "None"
				S.fields["mi_crim_d"] = "No minor crime convictions."
				S.fields["ma_crim"] = "None"
				S.fields["ma_crim_d"] = "No major crime convictions."
				S.fields["notes"] = "No notes."

				//Begin locked reporting
				L.fields["name"] = H.real_name
				L.fields["sex"] = H.gender
				L.fields["age"] = H.age
				L.fields["id"] = md5("[H.real_name][H.mind.assigned_role]")
				L.fields["rank"] = H.mind.role_alt_title ? H.mind.role_alt_title : H.mind.assigned_role
				L.fields["real_rank"] = H.mind.assigned_role
				L.fields["b_type"] = H.dna.b_type
				L.fields["b_dna"] = H.dna.unique_enzymes
				L.fields["enzymes"] = H.dna.struc_enzymes
				L.fields["identity"] = H.dna.uni_identity
				L.fields["image"] = getFlatIcon(H,0)
				//End locked reporting

				general += G
				medical += M
				security += S
				locked += L
		return

/obj/datacore/proc/manifest_modify(var/name, var/assignment)
	var/datum/data/record/foundrecord

	for(var/datum/data/record/t in data_core.general)
		if(t.fields["name"] == name)
			foundrecord = t
			break

	if(foundrecord)
		foundrecord.fields["rank"] = assignment
		if(assignment in get_all_jobs())
			foundrecord.fields["real_rank"] = assignment


/obj/datacore/proc/manifest_inject(var/mob/living/carbon/human/H)
	if (!isnull(H.mind) && (H.mind.assigned_role != "MODE"))
		var/datum/data/record/G = new()
		var/datum/data/record/M = new()
		var/datum/data/record/S = new()
		var/datum/data/record/L = new()
		var/obj/item/weapon/card/id/C = H.wear_id
		if (C)
			G.fields["rank"] = C.assignment
			G.fields["real_rank"] = H.job
		else
			if(H.mind && H.mind.assigned_role)
				G.fields["rank"] = H.mind.assigned_role
				G.fields["real_rank"] = H.mind.assigned_role
			else
				G.fields["rank"] = "Unassigned"
				G.fields["real_rank"] = G.fields["rank"]
		G.fields["name"] = H.real_name
		G.fields["id"] = text("[]", add_zero(num2hex(rand(1, 1.6777215E7)), 6))
		M.fields["name"] = G.fields["name"]
		M.fields["id"] = G.fields["id"]
		S.fields["name"] = G.fields["name"]
		S.fields["id"] = G.fields["id"]
		if (H.gender == FEMALE)
			G.fields["sex"] = "Female"
		else
			G.fields["sex"] = "Male"
		G.fields["age"] = text("[]", H.age)
		G.fields["fingerprint"] = text("[]", md5(H.dna.uni_identity))
		G.fields["p_stat"] = "Active"
		G.fields["m_stat"] = "Stable"
		M.fields["b_type"] = text("[]", H.dna.b_type)
		M.fields["b_dna"] = H.dna.unique_enzymes
		M.fields["mi_dis"] = "None"
		M.fields["mi_dis_d"] = "No minor disabilities have been declared."
		M.fields["ma_dis"] = "None"
		M.fields["ma_dis_d"] = "No major disabilities have been diagnosed."
		M.fields["alg"] = "None"
		M.fields["alg_d"] = "No allergies have been detected in this patient."
		M.fields["cdi"] = "None"
		M.fields["cdi_d"] = "No diseases have been diagnosed at the moment."
		M.fields["notes"] = "No notes."
		S.fields["criminal"] = "None"
		S.fields["mi_crim"] = "None"
		S.fields["mi_crim_d"] = "No minor crime convictions."
		S.fields["ma_crim"] = "None"
		S.fields["ma_crim_d"] = "No major crime convictions."
		S.fields["notes"] = "No notes."

		//Begin locked reporting
		L.fields["name"] = H.real_name
		L.fields["sex"] = H.gender
		L.fields["age"] = H.age
		L.fields["id"] = md5("[H.real_name][H.mind.assigned_role]")
		L.fields["rank"] = H.mind.role_alt_title ? H.mind.role_alt_title : H.mind.assigned_role
		L.fields["real_rank"] = H.mind.assigned_role
		L.fields["b_type"] = H.dna.b_type
		L.fields["b_dna"] = H.dna.unique_enzymes
		L.fields["enzymes"] = H.dna.struc_enzymes
		L.fields["identity"] = H.dna.uni_identity
		L.fields["image"] = getFlatIcon(H,0)
		//End locked reporting

		general += G
		medical += M
		security += S
		locked += L








/obj/machinery/mass_driver/proc/drive(amount)
	if(stat & (BROKEN|NOPOWER))
		return
	use_power(500)
	var/O_limit
	var/atom/target = get_edge_target_turf(src, dir)
	for(var/atom/movable/O in loc)
		if(!O.anchored||istype(O, /obj/mecha))//Mechs need their launch platforms.
			O_limit++
			if(O_limit >= 20)
				for(var/mob/M in hearers(src, null))
					M << "\blue The mass driver lets out a screech, it mustn't be able to handle any more items."
				break
			use_power(500)
			spawn( 0 )
				O.throw_at(target, drive_range * power, power)
	flick("mass_driver1", src)
	return



