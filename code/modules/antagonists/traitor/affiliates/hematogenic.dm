#define FREE_INJECT_TIME 10 SECONDS
#define TARGET_INJECT_TIME 3 SECONDS
#define BLOOD_HARVEST_VOLUME 200
#define BLOOD_HARVEST_TIME 10 SECONDS

/datum/affiliate/hematogenic
	name = AFFIL_HEMATOGENIC
	affil_info = list("Фармацевтическая мега корпорация подозревающаяся в связях с вампирами.",
					"Стандартные цели:",
					"Собрать образцы крови полной различной духовной энергии",
					"Украсть передовые медицинские технологии",
					"Сделать одного из членов экипажа вампиром",
					"Украсть что-то ценное или убить кого-то")
	tgui_icon = "hematogenic"
	slogan = "Мы с тобой одной крови."
	hij_desc = "Вы - опытный наёмный агент Hematogenic Industries.\n\
				Основатель Hematogenic Industries высоко оценил ваши прошлые заслуги, а потому, дал вам возможность купить инжектор наполненный его собственной кровью... \n\
				Вас предупредили, что после инъекции вы будете продолжительное время испытывать сильный голод. \n\
				Ваша задача - утолить этот голод.\n\
				Возможны помехи от агентов других корпораций - действуйте на свое усмотрение."
	hij_obj = /datum/objective/blood/ascend
	normal_objectives = 2
	objectives = list(/datum/objective/harvest_blood,
					/datum/objective/steal/hypo_or_defib,
					list(/datum/objective/steal = 60, /datum/objective/steal/hypo_or_defib = 40),
//					/datum/objective/new_mini_vampire,
					/datum/objective/escape
					)

/datum/affiliate/hematogenic/get_weight(mob/living/carbon/human/H)
	return (!ismachineperson(H) && H.mind?.assigned_role != JOB_TITLE_CHAPLAIN) * 2

/obj/item/hemophagus_extract
	name = "Bloody Injector"
	desc = "Инжектор странной формы, с неестественно двигающейся алой жидкостью внутри. На боку едва заметная гравировка \"Hematogenic Industries\". Конкретно на этом инжекторе установлена блокировка, не позволяющая исспользовать его на случайном гуманойде."
	icon = 'icons/obj/affiliates.dmi'
	icon_state = "hemophagus_extract"
	item_state = "inj_ful"
	lefthand_file = 'icons/obj/affiliates_l.dmi'
	righthand_file = 'icons/obj/affiliates_r.dmi'
	w_class = WEIGHT_CLASS_TINY
	var/datum/mind/target = null
	var/free_inject = FALSE
	var/isAdvanced = FALSE
	var/used = FALSE
	var/used_state = "hemophagus_extract_used"
	origin_tech = "biotech=7;syndicate=3"

/obj/item/hemophagus_extract/attack(mob/living/target, mob/living/user, def_zone)
	return

/obj/item/hemophagus_extract/afterattack(atom/target, mob/user, proximity, params)
	if(used)
		return

	if(!ishuman(target))
		return

	var/mob/living/carbon/human/H = target
	if(H.stat == DEAD)
		return

	if((src.target && target != src.target) || !free_inject)
		to_chat(user, span_warning("You can't use [src] to [target]!"))
		return

	if(do_after(user, free_inject ? FREE_INJECT_TIME : TARGET_INJECT_TIME, target = target, max_interact_count = 1))
		inject(user, H)

/obj/item/hemophagus_extract/proc/make_vampire(mob/living/user, mob/living/carbon/human/target)
	var/datum/antagonist/vampire/vamp = new()

	vamp.give_objectives = FALSE
	target.mind.add_antag_datum(vamp)
	var/datum/antagonist/vampire/vampire = target.mind.has_antag_datum(/datum/antagonist/vampire)
	vampire.upgrade_tiers -= /obj/effect/proc_holder/spell/vampire/self/specialize
	if(isAdvanced)
		vamp.add_subclass(SUBCLASS_ADVANCED, TRUE)

	vampire.add_objective((!isAdvanced) ? /datum/objective/blood : /datum/objective/blood/ascend)
	used = TRUE
	item_state = "inj_used"
	update_icon(UPDATE_ICON_STATE)
	var/datum/antagonist/traitor/T = user.mind.has_antag_datum(/datum/antagonist/traitor)
	if(!T)
		return
	for(var/datum/objective/new_mini_vampire/objective in T.objectives)
		if(target.mind == objective.target)
			objective.made = TRUE

/obj/item/hemophagus_extract/proc/inject(mob/living/user, mob/living/carbon/human/target)
	if(!target.mind)
		to_chat(user, span_notice("[target] body rejects [src]"))
		return

	playsound(src, 'sound/goonstation/items/hypo.ogg', 80)
	make_vampire(user, target)
	to_chat(user, span_notice("You inject [target] with [src]"))

/obj/item/hemophagus_extract/examine(mob/user)
	. = ..()
	if(target)
		. += span_info("It is intended for [target]")

/obj/item/hemophagus_extract/self
 	name = "Hemophagus Essence Auto Injector"
 	free_inject = TRUE

/obj/item/hemophagus_extract/self/advanced
	name = "Advances Hemophagus Essence Auto Injector"
	isAdvanced = TRUE

/obj/item/hemophagus_extract/update_icon_state()
 	icon_state = used ? used_state : initial(icon_state)

/obj/item/blood_harvester
	name = "Blood harvester"
	desc = "Большой шприц для быстрого сбора больших объемов крови. На боку едва заметная гравировка \"Hematogenic Industries\""
	icon = 'icons/obj/affiliates.dmi'
	icon_state = "blood_harvester"
	item_state = "blood1_used"
	lefthand_file = 'icons/obj/affiliates_l.dmi'
	righthand_file = 'icons/obj/affiliates_r.dmi'
	var/used = FALSE
	var/used_state = "blood_harvester_used"
	var/datum/mind/target
	w_class = WEIGHT_CLASS_TINY
	origin_tech = "biotech=5;syndicate=1"

/obj/item/blood_harvester/attack(mob/living/target, mob/living/user, def_zone)
	return

/obj/item/blood_harvester/proc/can_harvest(mob/living/carbon/human/target, mob/user)
	. = FALSE
	if(!istype(target))
		user.balloon_alert(src, "Не подходящая цель")
		return

	if(used)
		to_chat(user, span_warning("[src] is already full!"))
		return

	if(HAS_TRAIT(target, TRAIT_NO_BLOOD) || HAS_TRAIT(target, TRAIT_EXOTIC_BLOOD))
		user.balloon_alert(target, "Кровь не обнаружена!")
		return

	if(target.blood_volume < BLOOD_HARVEST_VOLUME)
		user.balloon_alert(target, "Недостаточно крови!")
		return

	if(!target.mind)
		user.balloon_alert(target, "Разум не обнаружен!")
		return

	return TRUE

/obj/item/blood_harvester/afterattack(atom/target, mob/user, proximity, params)
	if(!can_harvest(target, user))
		return

	var/mob/living/carbon/human/H = target

	target.visible_message(span_warning("[user] started collecting [target]'s blood using [src]!"), span_danger("[user] started collecting your blood using [src]!"))
	if(do_after(user, BLOOD_HARVEST_TIME, target = target, max_interact_count = 1))
		harvest(user, H)

/obj/item/blood_harvester/proc/harvest(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(!can_harvest(target, user))
		return

	playsound(src, 'sound/goonstation/items/hypo.ogg', 80)
	target.visible_message(span_warning("[user] collected [target]'s blood using [src]!"), span_danger("[user] collected your blood using [src]!"))
	target.emote("scream")
	for (var/i = 0; i < 3; ++i)
		if(prob(60))
			continue

		var/obj/item/organ/external/bodypart = pick(target.bodyparts)
		bodypart.internal_bleeding() // no blood collection from metafriends.

	target.blood_volume -= BLOOD_HARVEST_VOLUME
	src.target = target.mind
	used = TRUE
	item_state = "blood1_ful"
	update_icon(UPDATE_ICON_STATE)

/obj/item/blood_harvester/update_icon_state()
 	icon_state = used ? used_state : initial(icon_state)

/obj/item/blood_harvester/attack_self(mob/user)
	. = ..()
	if(!used)
		user.balloon_alert(src, "уже пусто")
		return

	var/new_gender = tgui_alert(user, "Очистить сборщик крови?", "Подтверждение", list("Продолжить", "Отмена"))
	if(new_gender == "Продолжить")
		target = null
		used = FALSE
		item_state = "blood1_used"
		update_icon(UPDATE_ICON_STATE)

	playsound(src, 'sound/goonstation/items/hypo.ogg', 80)
	user.visible_message(span_info("[user] cleared blood at [src]."), span_info("You cleared blood at [src]."))

/obj/item/blood_harvester/examine(mob/user)
	. = ..()

	if(!used)
		. += span_info("Кровь не собрана.")
		return

	if(user?.mind.has_antag_datum(/datum/antagonist/traitor))
		. += span_info("Собрана кровь с отпечатком души [target.name].")
	else
		. += span_info("Кровь собрана.")

/datum/reagent/hemat_blue_lagoon
	name = "Blue Lagoon"
	id = "hemat_blue_lagoon"
	description = "Вещество разработанное Hematogenic Industries, на основе криоксадона из тел Драсков обладающих душой, \
					сильно охлаждающее тело и замедляющее многие биологические процессы, не вредя организму."
	color = "#1edddd"
	drink_icon = "blue_lagoon"
	drink_name = "Blue Lagoon"
	drink_desc = "Что может быть лучше, чем расслабиться на пляже с хорошим напитком?"
	taste_description = "beach relaxation"
	reagent_state = LIQUID

/datum/reagent/hemat_blue_lagoon/on_mob_add(mob/living/carbon/human/H)
	ADD_TRAIT(H, TRAIT_IGNORECOLDSLOWDOWN, CHEM_TRAIT(src))
	ADD_TRAIT(H, TRAIT_IGNORECOLDDAMAGE, CHEM_TRAIT(src))
	H.physiology.metabolism_mod /= 8
	H.bodytemperature = T0C - 100
	. = ..()

/datum/reagent/hemat_blue_lagoon/on_mob_delete(mob/living/carbon/human/H)
	REMOVE_TRAIT(H, TRAIT_IGNORECOLDSLOWDOWN, CHEM_TRAIT(src))
	REMOVE_TRAIT(H, TRAIT_IGNORECOLDDAMAGE, CHEM_TRAIT(src))
	H.physiology.metabolism_mod *= 8
	var/turf/T = get_turf(H)
	var/datum/gas_mixture/environment = T.return_air()
	H.bodytemperature = H.get_temperature(environment)
	. = ..()

/datum/reagent/hemat_blue_lagoon/on_mob_life(mob/living/carbon/human/H)
	H.bodytemperature = T0C - 100
	return ..()


/datum/reagent/hemat_bloody_mary
	name = "Bloody Mary"
	id = "hemat_bloody_mary"
	description = "Вещество разработанное Hematogenic Industries, на основе крови воксов обладающих душой, \
					быстро восстанавливающее объем крови и количество кислорода в ней."
	reagent_state = LIQUID
	color = "#664300" // rgb: 102, 67, 0
	drink_icon = "bloodymaryglass"
	drink_name = "Bloody Mary"
	drink_desc = "Томатный сок, смешанный с водкой и небольшим количеством лайма. На вкус как жидкое убийство."
	taste_description = "tomatoes with booze"

/datum/reagent/hemat_bloody_mary/on_mob_life(mob/living/carbon/human/H)
	if (H.blood_volume + 5 < BLOOD_VOLUME_NORMAL)
		H.blood_volume += 5

	H.adjustOxyLoss(-10)
	return ..()


/datum/reagent/hemat_demons_blood
	name = "Demons Blood"
	id = "hemat_demons_blood"
	description = "Вещество разработанное Hematogenic Industries, на основе крови вампиров подкласса \"hemomancer\", \
					быстро лечащае, в зависимости от суммарных повреждений."
	reagent_state = LIQUID
	color = "#664300" // rgb: 102, 67, 0
	drink_icon = "demonsblood"
	drink_name = "Demons Blood"
	drink_desc = "Just looking at this thing makes the hair at the back of your neck stand up."
	taste_description = span_warning("evil")

/datum/reagent/hemat_demons_blood/on_mob_life(mob/living/carbon/human/H)
	var/heal = clamp((100 - H.health) / 25, 1, 4)
	H.heal_overall_damage(heal, heal)
	return ..()


/datum/reagent/hemat_white_russian
	name = "White Russian"
	id = "hemat_white_russian"
	description = "Вещество разработанное Hematogenic Industries, на основе крови вампиров подкласса \"gargantua\", \
					временно повышающее скорость бега."
	reagent_state = LIQUID
	color = "#A68340" // rgb: 166, 131, 64
	drink_icon = "whiterussianglass"
	drink_name = "White Russian"
	drink_desc = "A very nice looking drink. But that's just, like, your opinion, man."
	taste_description = "very creamy alcohol"

/datum/reagent/hemat_white_russian/on_mob_add(mob/living/carbon/human/H)
	if(H.dna && (H.dna.species.reagent_tag & PROCESS_ORG))
		H.add_movespeed_modifier(/datum/movespeed_modifier/reagent/hemat_white_russian)
	. = ..()

/datum/reagent/hemat_white_russian/on_mob_delete(mob/living/carbon/human/H)
	H.remove_movespeed_modifier(/datum/movespeed_modifier/reagent/hemat_white_russian)
	. = ..()

/datum/reagent/hemat_white_russian/on_mob_life(mob/living/carbon/human/H)
	if(!(H.dna && (H.dna.species.reagent_tag & PROCESS_ORG)))
		H.remove_movespeed_modifier(/datum/movespeed_modifier/reagent/hemat_white_russian)
	return ..()


/obj/item/reagent_containers/hypospray/autoinjector/hemat
	icon = 'icons/obj/affiliates.dmi'
	volume = 15
	amount_per_transfer_from_this = 15

/obj/item/reagent_containers/hypospray/autoinjector/hemat/blue_lagoon
	name = "Blue Lagoon autoinjector"
	desc = "Вещество разработанное Hematogenic Industries, на основе криоксадона из тел Драсков обладающих душой, \
			сильно охлаждающее тело и замедляющее многие биологические процессы, не вредя организму."
	icon_state = ""
	list_reagents = list("hemat_blue_lagoon" = 15)

/obj/item/reagent_containers/hypospray/autoinjector/hemat/bloody_mary
	name = "Bloody Mary autoinjector"
	desc = "Вещество разработанное Hematogenic Industries, на основе крови воксов обладающих душой, быстро восстанавливающее \
			объем крови и количество кислорода в ней."
	icon_state = ""
	list_reagents = list("hemat_bloody_mary" = 15)


/obj/item/reagent_containers/hypospray/autoinjector/hemat/demons_blood
	name = "Demons Blood autoinjector"
	desc = "Вещество разработанное Hematogenic Industries, на основе крови вампиров подкласса \"hemomancer\", быстро \
			лечащае, в зависимости от суммарных повреждений."
	icon_state = ""
	list_reagents = list("hemat_demons_blood" = 15)

/obj/item/reagent_containers/hypospray/autoinjector/hemat/white_russian
	name = "White Russian autoinjector"
	desc = "Вещество разработанное Hematogenic Industries, на основе крови вампиров подкласса \"gargantua\", временно \
			повышающее скорость бега."
	icon_state = ""
	list_reagents = list("hemat_white_russian" = 15)

/obj/item/storage/box/syndie_kit/stimulants
	name = "Boxed set of stimulants"

/obj/item/storage/box/syndie_kit/stimulants/populate_contents()
	new /obj/item/reagent_containers/hypospray/autoinjector/hemat/blue_lagoon(src)
	new /obj/item/reagent_containers/hypospray/autoinjector/hemat/bloody_mary(src)
	new /obj/item/reagent_containers/hypospray/autoinjector/hemat/demons_blood(src)
	new /obj/item/reagent_containers/hypospray/autoinjector/hemat/white_russian(src)

#undef FREE_INJECT_TIME
#undef TARGET_INJECT_TIME
#undef BLOOD_HARVEST_VOLUME
