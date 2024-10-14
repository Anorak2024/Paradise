
/datum/action/innate/detach
	var/mob/living/carbon/human/master_body = null
	button_icon = 'icons/obj/affiliates.dmi'
	button_icon_state = "brain1"

/datum/action/innate/cult/comm/Activate()
	var/obj/item/implant/marionette/imp = locate(/obj/item/implant/marionette) in target
	imp.detach()
	return

/obj/item/implant/marionette
	name = "Marionette Bio-chip"
	implant_state = "implant-syndicate"
	origin_tech = "programming=5;biotech=5;syndicate=3"
	activated = BIOCHIP_ACTIVATED_PASSIVE
	implant_data = /datum/implant_fluff/marionette
	var/mob/living/captive_brain/host_brain
	var/code
	var/controlling = FALSE
	var/charge = 3 MINUTES
	var/max_charge = 3 MINUTES
	var/mob/living/carbon/human/mar_master = null
	var/obj/item/implant/mar_master/master_imp = null
	var/datum/action/innate/detach/detach_action = new
	var/max_dist = 20

/obj/item/implant/marionette/Initialize(mapload)
	. = ..()
	code = rand(111111, 999999)
	START_PROCESSING(SSprocessing, src)

/obj/item/implant/marionette/implant(mob/living/carbon/human/target, mob/living/carbon/human/user, force = FALSE)
	var/obj/item/implant/marionette/same_imp = locate(type) in target
	if(same_imp && same_imp != src)
		same_imp.charge += charge
		same_imp.max_charge += max_charge
		same_imp.max_dist += max_dist
		qdel(src)
		return TRUE

	log_admin("[key_name_admin(user)] has made [key_name_admin(target)] marionette.")
	return ..()

/obj/item/implant/marionette/removed(mob/living/carbon/human/source)
	detach()
	. = ..()

/obj/item/implant/marionette/Destroy()
	. = ..()
	STOP_PROCESSING(SSprocessing, src)

/obj/item/implant/marionette/process(seconds_per_tick)
	if(QDELETED(imp_in))
		qdel(src)
		return

	if (get_dist(imp_in, mar_master) > max_dist)
		detach()
		mar_master.balloon_alert(mar_master, "марионетка слишком далеко")

	if (controlling)
		if (charge > 0)
			charge--
		else
			detach()

	else if (charge < max_charge)
		charge++

/obj/item/implant/marionette/proc/assume_control(mob/living/carbon/human/mar_master, obj/item/implant/mar_master/master_imp)
	var/mar_master_key = mar_master.key
	add_attack_logs(mar_master, imp_in, "Assumed control (marionette mar_master)")
	var/h2b_id = imp_in.computer_id
	var/h2b_ip= imp_in.lastKnownIP
	imp_in.computer_id = null
	imp_in.lastKnownIP = null

	qdel(host_brain)
	host_brain = new(mar_master)

	host_brain.ckey = imp_in.ckey

	host_brain.name = imp_in.name

	if(!host_brain.computer_id)
		host_brain.computer_id = h2b_id

	if(!host_brain.lastKnownIP)
		host_brain.lastKnownIP = h2b_ip

	var/s2h_id = mar_master.computer_id
	var/s2h_ip= mar_master.lastKnownIP
	mar_master.computer_id = null
	mar_master.lastKnownIP = null

	imp_in.ckey = mar_master.ckey

	if(!imp_in.computer_id)
		imp_in.computer_id = s2h_id

	if(!imp_in.lastKnownIP)
		imp_in.lastKnownIP = s2h_ip

	if(mar_master && !mar_master.key)
		mar_master.key = "@[mar_master_key]"

	controlling = TRUE
	src.mar_master = mar_master
	src.master_imp = master_imp

	detach_action.target = imp_in
	detach_action.master_body = mar_master
	detach_action.Grant(imp_in)

/obj/item/implant/marionette/proc/detach()
	controlling = FALSE
	detach_action.target = null
	detach_action.master_body = null
	detach_action.Remove(imp_in)

	if(!imp_in)
		return

	mar_master.reset_perspective(null)

	if(host_brain)
		add_attack_logs(imp_in, src, "Took control back (marionette)")
		var/h2s_id = imp_in.computer_id
		var/h2s_ip = imp_in.lastKnownIP
		imp_in.computer_id = null
		imp_in.lastKnownIP = null

		mar_master.ckey = imp_in.ckey

		if(!mar_master.computer_id)
			mar_master.computer_id = h2s_id

		if(!host_brain.lastKnownIP)
			mar_master.lastKnownIP = h2s_ip

		var/b2h_id = host_brain.computer_id
		var/b2h_ip = host_brain.lastKnownIP
		host_brain.computer_id = null
		host_brain.lastKnownIP = null

		imp_in.ckey = host_brain.ckey

		if(!imp_in.computer_id)
			imp_in.computer_id = b2h_id

		if(!imp_in.lastKnownIP)
			imp_in.lastKnownIP = b2h_ip

	qdel(host_brain)

	mar_master.Knockdown(1)
	mar_master = null
	master_imp = null
	return

/obj/item/implanter/marionette
	name = "bio-chip implanter (marionette)"
	imp = /obj/item/implant/marionette

/obj/item/implantcase/marionette
	name = "bio-chip case - 'Marionette'"
	desc = "Стеклянный футляр с био-чипом \"Марионетка\"."
	imp = /obj/item/implant/marionette


/obj/item/implant/mar_master
	name = "marionette master bio-chip"
	desc = "Позволяет временно контролировать существ с имплантами \"Марионетка\"."
	icon = 'icons/obj/affiliates.dmi'
	icon_state = "brain2"
	implant_state = "implant-syndicate"
	origin_tech = "materials=2;biotech=4;syndicate=2"
	activated = BIOCHIP_ACTIVATED_ACTIVE
	implant_data = /datum/implant_fluff/mar_master
	var/list/obj/item/implant/marionette/connected_imps
	var/obj/item/implant/marionette/cur_connection = null

/obj/item/implant/mar_master/removed(mob/living/carbon/human/source)
	. = ..()
	cur_connection?.detach()

/obj/item/implant/mar_master/Destroy()
	. = ..()
	cur_connection?.detach()

/obj/item/implant/mar_master/activate()
	var/op = tgui_alert(imp_in, "Выберите операцию.", "Выбор операции", list("Подключение импланта", "Контроль"))
	if(!op)
		return

	if(op == "Подключение импланта")
		var/code = tgui_input_number(imp_in, "Укажите код подключаемого импланта.", "Подключение импланта")
		if(!code)
			return

		var/found = FALSE
		for (var/mob/M in GLOB.mob_list)
			var/obj/item/implant/marionette/imp = locate(/obj/item/implant/marionette) in M
			if(imp.code == code)
				connected_imps += imp
				imp_in.balloon_alert(imp_in, "имплант подключен")
				found = TRUE

		if(!found)
			imp_in.balloon_alert(imp_in, "неверный код")

		return

	else
		var/list/marionettes = list()
		for (var/obj/item/implant/marionette/imp in connected_imps)
			var/mob/M = imp.imp_in
			if (M)
				marionettes[M.real_name] = imp

		var/choosen = input(imp_in, "Выберите к кому вы хотите подключиться.", "Подключение", null) as null|anything in marionettes
		if(!choosen)
			return

		var/obj/item/implant/marionette/imp = marionettes[choosen]

		if(QDELETED(imp))
			return

		if(!imp.imp_in || !imp_in)
			return

		if (imp.controlling)
			imp_in.balloon_alert(imp_in, "целевой имплант занят")
			return

		cur_connection = imp
		imp.assume_control(imp_in, src)

/obj/item/implanter/mar_master
	name = "bio-chip implanter (marionette master)"
	imp = /obj/item/implant/mar_master

/obj/item/implantcase/mar_master
	name = "bio-chip case - 'Marionette master'"
	desc = "Стеклянный футляр с био-чипом \"Марионеточник\"."
	imp = /obj/item/implant/mar_master

/obj/item/storage/box/syndie_kit/marionette

/obj/item/storage/box/syndie_kit/marionette/populate_contents()
	var/obj/item/implanter/marionette/implanter = new /obj/item/implanter/marionette(src)
	var/obj/item/implant/marionette/imp = implanter.imp
	var/obj/item/paper/P = new /obj/item/paper(src)
	P.info = "Код импланта: [imp.code]<br>\
				Необходим для подключения импланта к импланту \"Мастер марионеток\""
