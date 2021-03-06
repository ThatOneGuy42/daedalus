/obj/effect/accelerated_particle
	name = "Accelerated Particles"
	desc = "Small things moving very fast."
	icon = 'icons/obj/machines/particle_accelerator.dmi'
	icon_state = "particle"//Need a new icon for this
	anchored = 1
	density = 1
	var
		movement_range = 10
		energy = 10		//energy in eV
		mega_energy = 0	//energy in MeV
		frequency = 1
		ionizing = 0
		particle_type
		additional_particles = 0
		turf/target
		turf/source
		movetotarget = 1
	weak
		movement_range = 8
		energy = 5
	strong
		movement_range = 15
		energy = 15

	New(loc, dir = 2)
		src.loc = loc
		source = usr
		src.dir = dir
		spawn(1)
			move(1)
		return

	Bump(atom/A)
		if (A)
			if(ismob(A))
				toxmob(A)
			if((istype(A,/obj/machinery/the_singularitygen))||(istype(A,/obj/machinery/singularity/)))
				A:energy += energy
//				energy = 0	//This breaks the current singularity
		return

	Bumped(atom/A)
		if(ismob(A))
			Bump(A)
		return

	ex_act(severity)
		del(src)
		return

	proc
		toxmob(var/mob/living/M)
			var/radiation = (energy*2)
			if(istype(M,/mob/living/carbon/human))
				if(M:wear_suit) //TODO: check for radiation protection
					radiation = round(radiation/2,1)
			if(istype(M,/mob/living/carbon/monkey))
				if(M:wear_suit) //TODO: check for radiation protection
					radiation = round(radiation/2,1)
			if(ionizing)
				//give them standard rad damage
				M.radiation += radiation
				M.updatehealth()
			else
				//burn them
				M.take_overall_damage(0, radiation)
			//M << "\red You feel odd."
			return

		move(var/lag)
			if(target)
				if(movetotarget)
					if(!step_towards(src,target))
						src.loc = get_step(src, get_dir(src,target))
					if(get_dist(src,target) < 1)
						movetotarget = 0
				else
					if(!step(src, get_step_away(src,source)))
						src.loc = get_step(src, get_step_away(src,source))
			else
				if(!step(src,dir))
					src.loc = get_step(src,dir)
			movement_range--
			if(movement_range <= 0)
				del(src)
			else
				sleep(lag)
				move(lag)
