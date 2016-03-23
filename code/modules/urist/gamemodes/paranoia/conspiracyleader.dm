//This file contains only the basic mostly non-functional template for various conspiracies defined in conspiracies.dm

var/datum/antagonist/agent/agents

/datum/antagonist/agent
	id = "Agent"
	role_type = BE_AGENT
	role_text = "Conspiracy Leader"
	role_text_plural = "Conspiracy Agents"
	bantype = "agent"
	feedback_tag = "paranoia_objective"
	antag_indicator = "rev_head"
	leader_welcome_text = "You are a leader of a shadowy cabal operating on the station. Lead your faction to supremacy!"
	welcome_text = "Down with the capitalists! Down with the Bourgeoise!"
	victory_text = "The heads of staff were relieved of their posts! The revolutionaries win!"
	loss_text = "The heads of staff managed to stop the revolution!"
	victory_feedback_tag = "win - heads killed"
	loss_feedback_tag = "loss - rev heads killed"
	flags = ANTAG_SUSPICIOUS | ANTAG_VOTABLE
	antaghud_indicator = "hudrevolutionary"
	restricted_jobs = list("AI", "Cyborg")

	hard_cap = 3
	hard_cap_round = 1
	initial_spawn_req = 2
	initial_spawn_target = 3

	//Inround agents.
	faction_role_text = "Conspiracy Agent"
	faction_descriptor = "Conspiracy"
	faction_verb = /mob/living/proc/convert_to_conspiracy
	faction_welcome = "Follow your leader's orders. Cooperate with fellow agents - but trust no-one."
	faction_indicator = null
	faction_invisible = 1

/datum/antagonist/agent/New()
	..()
	agents = src

/mob/living/proc/convert_to_conspiracy(mob/M as mob in oview(src))
	set name = "Recruit as Agent"
	set category = "Abilities"

	if(!M.mind)
		return

	var/datum/antagonist/agent/conspiracy

	switch(src.mind.special_role)
		if(("Buildaborg Agent") || ("Buildaborg Group Leader")) conspiracy = buildaborgs
		if(("Freemeson Agent")  || ("Mesonic Lodge Master")) conspiracy = freemesons
		if(("Men in Grey Agent")|| ("Men in Grey Commander")) conspiracy = MIGs
		if(("Aliuminati Agent") || ("The Aliuminated One")) conspiracy = aliuminatis
		else
			src << "<span class='warning'>Something's wrong. Either you don't belong to a faction or belong to too many!</span>"

	convert_to_faction(M.mind, conspiracy)

/datum/antagonist/agent/get_extra_panel_options(var/datum/mind/player)
	return "<a href='?src=\ref[player];common=crystals'>\[set crystals\]</a><a href='?src=\ref[src];spawn_uplink=\ref[player.current]'>\[spawn uplink\]</a>"

/datum/antagonist/agent/Topic(href, href_list)
	if (..())
		return
	if(href_list["spawn_uplink"]) spawn_uplink(locate(href_list["spawn_uplink"]))

/datum/antagonist/agent/equip(var/mob/living/carbon/human/agent_mob)

	if(!..())
		return 0

	spawn_uplink(agent_mob)

/datum/antagonist/agent/proc/spawn_uplink(var/mob/living/carbon/human/agent_mob)
	if(!istype(agent_mob))
		return

	var/loc = ""
	var/obj/item/R = locate() //Hide the uplink in a PDA if available, otherwise radio

	if(agent_mob.client.prefs.uplinklocation == "Headset")
		R = locate(/obj/item/device/radio) in agent_mob.contents
		if(!R)
			R = locate(/obj/item/device/pda) in agent_mob.contents
			agent_mob << "Could not locate a Radio, installing in PDA instead!"
		if (!R)
			agent_mob << "Unfortunately, neither a radio or a PDA relay could be installed."
	else if(agent_mob.client.prefs.uplinklocation == "PDA")
		R = locate(/obj/item/device/pda) in agent_mob.contents
		if(!R)
			R = locate(/obj/item/device/radio) in agent_mob.contents
			agent_mob << "Could not locate a PDA, installing into a Radio instead!"
		if(!R)
			agent_mob << "Unfortunately, neither a radio or a PDA relay could be installed."
	else if(agent_mob.client.prefs.uplinklocation == "None")
		agent_mob << "You have elected to not have an AntagCorp portable teleportation relay installed!"
		R = null
	else
		agent_mob << "You have not selected a location for your relay in the antagonist options! Defaulting to PDA!"
		R = locate(/obj/item/device/pda) in agent_mob.contents
		if (!R)
			R = locate(/obj/item/device/radio) in agent_mob.contents
			agent_mob << "Could not locate a PDA, installing into a Radio instead!"
		if (!R)
			agent_mob << "Unfortunately, neither a radio or a PDA relay could be installed."

	if(!R)
		return

	if(istype(R,/obj/item/device/radio))
		// generate list of radio freqs
		var/obj/item/device/radio/target_radio = R
		var/freq = 1441
		var/list/freqlist = list()
		while (freq <= 1489)
			if (freq < 1451 || freq > PUB_FREQ)
				freqlist += freq
			freq += 2
			if ((freq % 2) == 0)
				freq += 1
		freq = freqlist[rand(1, freqlist.len)]
		var/obj/item/device/uplink/hidden/T = new(R)
		T.uplink_owner = agent_mob.mind
		target_radio.hidden_uplink = T
		target_radio.traitor_frequency = freq
		agent_mob << "A portable object teleportation relay has been installed in your [R.name] [loc]. Simply dial the frequency [format_frequency(freq)] to unlock its hidden features."
		agent_mob.mind.store_memory("<B>Radio Freq:</B> [format_frequency(freq)] ([R.name] [loc]).")

	else if (istype(R, /obj/item/device/pda))
		// generate a passcode if the uplink is hidden in a PDA
		var/pda_pass = "[rand(100,999)] [pick("Alpha","Bravo","Delta","Omega")]"
		var/obj/item/device/uplink/hidden/T = new(R)
		T.uplink_owner = agent_mob.mind
		R.hidden_uplink = T
		var/obj/item/device/pda/P = R
		P.lock_code = pda_pass
		agent_mob << "A portable object teleportation relay has been installed in your [R.name] [loc]. Simply enter the code \"[pda_pass]\" into the ringtone select to unlock its hidden features."
		agent_mob.mind.store_memory("<B>Uplink Passcode:</B> [pda_pass] ([R.name] [loc]).")