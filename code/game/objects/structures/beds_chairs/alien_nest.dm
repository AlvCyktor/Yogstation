//Alium nests. Essentially beds with an unbuckle delay that only aliums can buckle mobs to.

/obj/structure/bed/nest
	name = "alien nest"
	desc = "It's a gruesome pile of thick, sticky resin shaped like a nest."
	icon = 'icons/obj/smooth_structures/alien/nest.dmi'
	icon_state = "nest"
	max_integrity = 120
	smooth = SMOOTH_TRUE
	can_be_unanchored = FALSE
	canSmoothWith = null
	buildstacktype = null
	flags_1 = NODECONSTRUCT_1
	bolts = FALSE
	var/static/mutable_appearance/nest_overlay = mutable_appearance('icons/mob/alien.dmi', "nestoverlay", LYING_MOB_LAYER)

/obj/structure/bed/nest/user_unbuckle_mob(mob/living/buckled_mob, mob/living/user)
	if(has_buckled_mobs())
		for(var/buck in buckled_mobs) //breaking a nest releases all the buckled mobs, because the nest isn't holding them down anymore
			var/mob/living/M = buck

			if(user.getorgan(/obj/item/organ/alien/plasmavessel))
				unbuckle_mob(M)
				add_fingerprint(user)
				return

			if(M != user)
				M.visible_message(\
					"[user.name] pulls [M.name] free from the sticky nest!",\
					span_notice("[user.name] pulls you free from the gelatinous resin."),\
					span_italics("You hear squelching..."))
			else
				M.visible_message(\
					span_warning("[M.name] struggles to break free from the gelatinous resin!"),\
					span_notice("You struggle to break free from the gelatinous resin... (Stay still for two minutes.)"),\
					span_italics("You hear squelching..."))
				if(!do_after(M, 15 SECONDS, src))
					if(M && M.buckled)
						to_chat(M, span_warning("You fail to unbuckle yourself!"))
					return
				if(!M.buckled)
					return
				M.visible_message(\
					span_warning("[M.name] breaks free from the gelatinous resin!"),\
					span_notice("You break free from the gelatinous resin!"),\
					span_italics("You hear squelching..."))

			unbuckle_mob(M)
			add_fingerprint(user)

/obj/structure/bed/nest/user_buckle_mob(mob/living/M, mob/living/user)
	if ( !ismob(M) || (get_dist(src, user) > 1) || (M.loc != src.loc) || user.incapacitated() || M.buckled )
		return

	if(M.getorgan(/obj/item/organ/alien/plasmavessel))
		return
	if(!user.getorgan(/obj/item/organ/alien/plasmavessel))
		return

	if(has_buckled_mobs())
		unbuckle_all_mobs()

	if(buckle_mob(M))
		M.visible_message(\
			"[user.name] secretes a thick vile goo, securing [M.name] into [src]!",\
			span_danger("[user.name] drenches you in a foul-smelling resin, trapping you in [src]!"),\
			span_italics("You hear squelching..."))
		var/obj/item/restraints/handcuffs/xeno/cuffs = new(M)
		cuffs.apply_cuffs(M, user)

/obj/structure/bed/nest/post_buckle_mob(mob/living/M)
	M.pixel_y = 0
	M.pixel_x = initial(M.pixel_x) + 2
	M.layer = BELOW_MOB_LAYER
	add_overlay(nest_overlay)

/obj/structure/bed/nest/post_unbuckle_mob(mob/living/M)
	M.pixel_x = M.get_standard_pixel_x_offset(M.lying)
	M.pixel_y = M.get_standard_pixel_y_offset(M.lying)
	M.layer = initial(M.layer)
	cut_overlay(nest_overlay)

/obj/structure/bed/nest/play_attack_sound(damage_amount, damage_type = BRUTE, damage_flag = 0)
	switch(damage_type)
		if(BRUTE)
			playsound(loc, 'sound/effects/attackblob.ogg', 100, 1)
		if(BURN)
			playsound(loc, 'sound/items/welder.ogg', 100, 1)

/obj/structure/bed/nest/attack_alien(mob/living/carbon/alien/user)
	if(user.a_intent != INTENT_HARM)
		return attack_hand(user)
	else
		return ..()

/obj/item/restraints/handcuffs/xeno
	icon = 'icons/obj/mining.dmi'
	icon_state = "sinewcuff"
	item_flags = DROPDEL
	color = COLOR_MAGENTA
