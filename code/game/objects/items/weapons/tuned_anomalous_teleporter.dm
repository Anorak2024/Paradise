/obj/item/tuned_anomalous_teleporter
	name = "tuned anomalous teleporter"
	desc = "A portable item using blue-space technology."
	icon = 'icons/obj/device.dmi'
	icon_state = "hand_tele"
	base_icon_state = "hand_tele"
	item_state = "electronic"
	throwforce = 0
	w_class = WEIGHT_CLASS_SMALL
	throw_speed = 3
	throw_range = 5
	materials = list(MAT_METAL=10000)
	origin_tech = "magnets=3;bluespace=4"
	armor = list("melee" = 0, "bullet" = 0, "laser" = 0, "energy" = 0, "bomb" = 30, "bio" = 0, "rad" = 0, "fire" = 100, "acid" = 100)
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | ACID_PROOF
	var/icon_state_inactive = "hand_tele_inactive"
	var/active_portals = 0
	/// Variable contains next time hand tele can be used to make it not EMP proof
	var/emp_timer = 0
	var/last_use = 0
	var/cooldown = 200
	var/tp_range = 5

/obj/item/tuned_anomalous_teleporter/attack_self(mob/user)
	if(emp_timer > world.time)
		do_sparks(5, FALSE, loc)
		to_chat(user, span_warning("[src] attempts to teleport you, but abruptly shuts off."))
		return FALSE
	if (world.time < last_use + cooldown)
		to_chat(user, span_warning("Wait " + str((world.time - last_use)/20) + " seconds.")
		return FALSE
	last_use = world.time

	var/datum/teleport/TP = new /datum/teleport()
	var/crossdir = angle2dir((dir2angle(user.dir)) % 360)
	var/turf/T1 = get_turf(user)
	for(var/i in 1 to tp_range)
		T1 = get_step(T1, crossdir)
	var/datum/effect_system/smoke_spread/s1 = new
	var/datum/effect_system/smoke_spread/s2 = new
	s1.set_up(5, FALSE, user)
	s2.set_up(5, FALSE, user)
	TP.start(user, T1, FALSE, TRUE, s1, s2, 'sound/effects/phasein.ogg', )
	TP.doTeleport()

/obj/item/tuned_anomalous_teleporter/emp_act(severity)
	make_inactive(severity)
	return ..()


/obj/item/tuned_anomalous_teleporter/proc/make_inactive(severity)
	var/time = rand(10 SECONDS, 15 SECONDS) * (severity == EMP_HEAVY ? 2 : 1)
	emp_timer = world.time + time
	update_icon(UPDATE_ICON_STATE)
	addtimer(CALLBACK(src, PROC_REF(check_inactive), emp_timer), time)


/obj/item/tuned_anomalous_teleporter/proc/check_inactive(current_emp_timer)
	if(emp_timer != current_emp_timer)
		return
	update_icon(UPDATE_ICON_STATE)


/obj/item/tuned_anomalous_teleporter/examine(mob/user)
	. = ..()
	if(emp_timer > world.time)
		. += span_warning("It looks inactive.")


/obj/item/tuned_anomalous_teleporter/update_icon_state()
	icon_state = (emp_timer > world.time) ? icon_state_inactive : base_icon_state

/datum/crafting_recipe/tuned_anomalous_teleporter
	name = "Tuned anomalous teleporter"
	result = /obj/item/tuned_anomalous_teleporter
	tools = list(TOOL_SCREWDRIVER, TOOL_WELDER)
	reqs = list(/obj/item/relict_priduction/strange_teleporter = 1,
				/obj/item/assembly/signaler/anomaly/bluespace = 1,
				/obj/item/gps = 1,
				/obj/item/stack/ore/bluespace_crystal,
				/obj/item/stack/sheet/metal = 2,
				/obj/item/stack/cable_coil = 5)
	time = 300
	category = CAT_MISC
