var Wave = 0;
var WaveCooldown = 360;
var Stag = getZone(186).owner;
var Bear = getZone(169).owner;
var Wolf = getZone(225).owner;
var Difficulty = 0.0;
var HordePower = 0.0;
var player:Player;

var Fighter = 1;
var Tank = 1;
var Archer = 1;
var Land = 0;
var Horde1 = [];
var Horde2 = [];
var BasePower = 0.5;

var HorseHeros = false;
var WolfDefense = false;
var WolfRevenge = false;
function init () {
	if (isHost()) {
    // me(). gibt den aktuellen Client zurück, so wird für jeden Spieler ein Objective erstellt. Beim Klick auf den Objective-Button wird "action" ausgeführt
		me().objectives.add("Easy", "Set Difficulty to [Stone] \nRecommended for new players", {visible: true}, {name: "[Stone] Difficulty", action: "easy"});
		me().objectives.add("Normal", "Set Difficulty to [Iron] \nRecommended for average players", {visible: true}, {name: "[Iron] Difficulty", action: "normal"});
		me().objectives.add("Hard", "Set Difficulty to [RimeSteel] \nRecommended for advanced players", {visible: true}, {name: "[RimeSteel] Difficulty", action: "hard"});
		me().objectives.add("WaveTimer", "Time until next Wave: ", {visible:false, val:math.floor(WaveCooldown/2), showProgressBar:true, goalVal:180,showOtherPlayers:false});
		me().objectives.add("Fighter", "[Warrior]: Costs 50 Kröwns ", {visible: false}, {name: "Buy [Warrior]", action: "buyFighter"});
		me().objectives.add("Tank", "[ShieldBearer]: Costs 50 Kröwns ", {visible: false}, {name: "Buy [ShieldBearer]", action: "buyTank"});
		me().objectives.add("Archer", "[AxeWielder]: Costs 50 Kröwns ", {visible: false}, {name: "Buy [AxeWielder]", action: "buyArcher"});
		me().objectives.add("UpgradeFighter", "Upgrade [Warrior]: 500/1000 Kröwns ", {visible: false}, {name: "+5 HP | +2 ATK | +1 DEF", action: "upgradeFighter"});
		me().objectives.add("UpgradeTank", "Upgrade [ShieldBearer]: 500/1000 Kröwns ", {visible: false}, {name: "+10 HP | +2 DEF", action: "upgradeTank"});
		me().objectives.add("UpgradeArcher", "Upgrade [AxeWielder]: 500/1000 Kröwns ", {visible: false}, {name: "+5 ATK | +30% Range", action: "upgradeArcher"});
		me().objectives.add("BuyLand", "Unlock [Territory]: 200/500/1000 Kröwns ", {visible: false}, {name: "Unlock [Territory]", action: "buyLand"});
		me().objectives.add("OpenUpgrades", "Open/Close Upgrades", {visible: false}, {name: "Open/Close Upgrades", action: "openUpgrades"});
		}
		if (state.time == 0) { // wenn das Spiel beginnt, dann ist time = 0
			onFirstLaunch();
	}
}


function onFirstLaunch() {
	if (isHost()) {
		state.removeVictory(Victory.Fame); // Einige Siegesbedingungen werden ausgeschaltet
		state.removeVictory(Victory.Lore);
		state.removeVictory(Victory.Money);
		addRule(Rule.ManyResources); // Vordefinierte Behavior-Regeln für die KI
		addRule(Rule.IANeedColonize);
		addRule(Rule.NeedDefense);
		addRule(Rule.NoMaxTerritoryExpand);
		state.difficulty = 1;
		talk("The Enemy is attacking every three months, prepare your defenses and destroy the Wolf Clan!", {name:"Samurai", who:Banner.BannerStag}); // Der Spieler gewarnt, dass geskriptete Gegnerwellen kommen
			getZone(163).allowScouting = false; // Dieses Land wird erst freigeschaltet, wenn der Objective-Button BuyLand geklickt wurde. 
			getZone(157).allowScouting = false;
			getZone(148).allowScouting = false;
			getZone(179).allowScouting = false;

			getZone(162).allowScouting = false;
			getZone(126).allowScouting = false;
			getZone(136).allowScouting = false;
			getZone(146).allowScouting = false;
			getZone(158).allowScouting = false;

			getZone(141).allowScouting = false;
			getZone(127).allowScouting = false;
			getZone(124).allowScouting = false;
			getZone(145).allowScouting = false;
			getZone(160).allowScouting = false;
			getZone(108).allowScouting = false;
			getZone(120).allowScouting = false;
			Stag.addResource(Resource.Money, 200); 
			Bear.addResource(Resource.Money, 200);
			Wolf.addBonus({ id: ConquestBonus.BColonizeCost, isAdvanced: true }); // Bonus wird dem Wolf-Clan hinzugefügt
			Wolf.addBonus({ id: ConquestBonus.BWatchTower, isAdvanced: true });


	}
}


function regularUpdate(dt: Float) { // Alle 0.5s wird diese Funktion ausgeführt
	if (isHost()) {
		me().objectives.setCurrentVal("WaveTimer", math.floor(WaveCooldown/2)); // Der Timer für die nächste Welle wird alle 0.5s aktualisiert
		aiBuffs();
		for (zone in Wolf.zones) {
		// Wenn WolfDefense true ist, eine Zone von Wolf zerstört wird und wenn kein Bär vorhanden ist, soll ein Bär hinzugefügt werden
		if (WolfDefense && zone.colonize < 0.05 && Wolf.getUnits(Unit.BearMaiden).length == 0) {
			getZone(225).addUnit(Unit.BearMaiden, 1, Wolf, true, null, 5);
			Stag.genericNotify("The Wolf gains [BearMaiden] as defense!");
			Bear.genericNotify("The Wolf gains [BearMaiden] as defense!");
		}
		if (WolfRevenge && zone.colonize < 0.05 && BasePower == 0.5) {
			BasePower = (Wave/3)*Difficulty;
			Stag.genericNotify("Wolf will take revenge and the next wave will be stronger!");
			Bear.genericNotify("Wolf will take revenge and the next wave will be stronger!");
		}
	}
	if (Wolf.getMilitaryCount(null, false) == 0) { 	// Der Timer für die nächste Welle startet erst, wenn Wolf keine Truppen mehr übrig hat. 
		WaveCooldown--;
	}

	if (WaveCooldown == 0) { 
			Wave ++;
			shakeCamera(false);
			HordePower = BasePower + (Wave * Difficulty); // Die Stärke der nächsten Welle
			sfx(UiSfx.Horn);
			WaveCooldown = 360;
			BasePower = 0.5;
			if ((Wave % 5 < 0.1) && WaveCooldown == 356) { // Jede fünfte Welle wird ein zufälliger Bonus und Event aktiviert
				getBonus(Stag); getBonus(Bear);
				getEvent();
				sfx(UiSfx.LearnBlessing);
				}
			if (Wave <= 5) { // Solange Wave kleiner als 5 ist, dürfen nur schwache Gegnertypen spawnen
				if (getZone(186).owner == Stag) { Horde1 = spawnT1(225, Stag); }
				if (getZone(169).owner == Bear) { Horde2 = spawnT1(225, Bear); }
			}
			else if (Wave >= 6 && Wave <= 10) { // Falls Wave zwischen 6-10, dürfen entweder schwache oder normale Gegnertypen spawnen
				var Random:Float = math.floor(math.random() * 100);
				if (Random < ((-21 * Wave) + 222)) { // Schwacher Gegnertyp
					if (getZone(186).owner == Stag) { Horde1 = spawnT1(225, Stag); }
					if (getZone(169).owner == Bear) { Horde2 = spawnT1(225, Bear); }
				}
				else { // Normaler Gegnertyp
					if (getZone(186).owner == Stag) { Horde1 = spawnT2(225, Stag); }
					if (getZone(169).owner == Bear) { Horde2 = spawnT2(225, Bear); }
				}
			}
			else if (Wave >= 11 && Wave <= 15) { // Falls Wave zwischen 11-15, dürfen entweder normale oder starke Gegnertypen spawnen
				var Random:Float = math.floor(math.random() * 100);
				if (Random < ((-21 * Wave) + 325)) { // Normal
					if (getZone(186).owner == Stag) { Horde1 = spawnT2(225, Stag); }
					if (getZone(169).owner == Bear) { Horde2 = spawnT2(225, Bear); }
				}
				else { // Stark
					if (getZone(186).owner == Stag) { Horde1 = spawnT3(225, Stag); }
					if (getZone(169).owner == Bear) { Horde2 = spawnT3(225, Bear); }
				}
			}
			else { // Normal
				if (getZone(186).owner == Stag) { Horde1 = spawnT3(225, Stag); }
				if (getZone(169).owner == Bear) { Horde2 = spawnT3(225, Bear); }
			}
		}

		if (getZone(186).owner != null) { // Solange Spieler "Stag" nicht besiegt ist, soll die Gegnerwelle diesen Spieler angreifen
			launchAttackPlayer(Horde1, Stag);
		 } else { // Wenn "Stag" besiegt, dann soll die Gegnerwelle stattdessen "Bear" angreifen
			launchAttackPlayer(Horde1, Bear);
		 }
		if (getZone(169).owner != null) { 
			launchAttackPlayer(Horde2, Bear);
		 } else {
			launchAttackPlayer(Horde2, Stag);
		 }

		if (state.time > 89 && state.time < 91) {
			if (Difficulty == 0.0) {
				normal(); //wenn der Spieler keine Difficulty ausgewählt hat, wird normal ausgewählt
				setup();

			}
		}
	}
}


function setup() { 
	if (isHost()) { 
		me().objectives.setVisible("Easy", false);
		me().objectives.setVisible("Normal", false);
		me().objectives.setVisible("Hard", false);
		me().objectives.setVisible("WaveTimer", true);
		me().objectives.setVisible("Fighter", true);
		me().objectives.setVisible("Tank", true);
		me().objectives.setVisible("Archer", true);
		me().objectives.setVisible("OpenUpgrades", true);
		Wolf.setAILevel(10);
		if (Stag.isAI) { Stag.setAILevel(10); }
		if (Bear.isAI) { Bear.setAILevel(10); }
	}
}

function easy() {
	if (isHost()) {
		me().genericNotify("Difficulty has been set to [Stone]!");
		Difficulty = 0.5;
		state.difficulty = 0;
		setup();
	}
}

function normal() {
	if (isHost()) {
		me().genericNotify("Difficulty has been set to [Iron]!");
		Difficulty = 1.0;
		state.difficulty = 1;
		setup();
	}
}


function hard() {
	if (isHost()) {
		me().genericNotify("Difficulty has been set to [RimeSteel]!");
		Difficulty = 1.5;
		state.difficulty = 2;
		setup();
	}
}

function openUpgrades() { // Da das Display zu klein ist für die hohe Anzahl an Objectives, habe ich alle in zwei Gruppen unterteilt. Wenn die erste Gruppe "Upgrades" bzw. "BuyLand" sichtbar ist, dann soll die andere Gruppe "Timer", "Fighter", "Tank", "Archer" unsichtbar sein.
	if (isHost()) {
		if (me().objectives.isVisible("Fighter") == true) {
			me().objectives.setVisible("WaveTimer", false);
			me().objectives.setVisible("Fighter", false);
			me().objectives.setVisible("Tank", false);
			me().objectives.setVisible("Archer", false);
			if (Fighter != 3) { // Maximales Upgrade noch nicht erreicht, wenn doch bleibt UpgradeFighter für immer unsichtbar
				me().objectives.setVisible("UpgradeFighter", true);
			}
			if (Tank != 3) {
				me().objectives.setVisible("UpgradeTank", true);
			}
			if (Archer != 3) {
				me().objectives.setVisible("UpgradeArcher", true);
			}
			if (Land != 3) {
				me().objectives.setVisible("BuyLand", true);
			}
		} else { // Upgrades aus, rest an
			me().objectives.setVisible("UpgradeFighter", false);
			me().objectives.setVisible("UpgradeTank", false);
			me().objectives.setVisible("UpgradeArcher", false);
			me().objectives.setVisible("BuyLand", false);
			me().objectives.setVisible("WaveTimer", true);
			me().objectives.setVisible("Fighter", true);
			me().objectives.setVisible("Tank", true);
			me().objectives.setVisible("Archer", true);

		}
	}
}


function buyFighter() {
	if (isHost()) {
		if (Stag.getResource(Resource.Money) >= 50 && Bear.getResource(Resource.Money) >= 50) {
			Stag.addResource(Resource.Money, -50);
			Bear.addResource(Resource.Money, -50);
			sfx(UiSfx.BuySlaves);
			switch (Fighter) { // Je nachdem welches Upgrade Level die Kämpfer haben, wird eine andere Einheit gespawnt
				case 1: getZone(186).addUnit(Unit.Warrior, 1, Stag, true, null, 5); getZone(169).addUnit(Unit.Warrior, 1, Bear, true, null, 5);
				Stag.genericNotify("You purchased a [Warrior]"); Bear.genericNotify("You purchased a [Warrior]"); break;
				case 2: getZone(186).addUnit(Unit.Warrior02, 1, Stag, true, null, 5); getZone(169).addUnit(Unit.Warrior02, 1, Bear, true, null, 5);
				Stag.genericNotify("You purchased a [Warrior02]"); Bear.genericNotify("You purchased a [Warrior02]"); break;
				case 3: getZone(186).addUnit(Unit.Einherjar, 1, Stag, true, null, 5); getZone(169).addUnit(Unit.Einherjar, 1, Bear, true, null, 5);
				Stag.genericNotify("You purchased a [Einherjar]"); Bear.genericNotify("You purchased a [Einherjar]"); break;

			}
		} else {
			me().genericNotify("Non-AI players need 50 Kröwns!");
		}
	}
}

function buyTank() {
	if (isHost()) {
		if (Stag.getResource(Resource.Money) >= 50 && Bear.getResource(Resource.Money) >= 50) {
			Stag.addResource(Resource.Money, -50);
			Bear.addResource(Resource.Money, -50);
			sfx(UiSfx.BuySlaves);
			switch (Tank) {
				case 1: getZone(186).addUnit(Unit.ShieldBearer, 1, Stag, true, null, 5); getZone(169).addUnit(Unit.ShieldBearer, 1, Bear, true, null, 5);
				Stag.genericNotify("You purchased a [ShieldBearer]"); Bear.genericNotify("You purchased a [ShieldBearer]"); break;
				case 2: getZone(186).addUnit(Unit.ShieldBearer02, 1, Stag, true, null, 5); getZone(169).addUnit(Unit.ShieldBearer02, 1, Bear, true, null, 5);
				Stag.genericNotify("You purchased a [ShieldBearer02]"); Bear.genericNotify("You purchased a [ShieldBearer02]"); break;
				case 3: getZone(186).addUnit(Unit.Paladin, 1, Stag, true, null, 5); getZone(169).addUnit(Unit.Paladin, 1, Bear, true, null, 5);
				Stag.genericNotify("You purchased a [Paladin]"); Bear.genericNotify("You purchased a [Paladin]"); break;
			}
		} else {
			me().genericNotify("Non-AI players need 50 Kröwns!");
		}
	}
}

function buyArcher() {
	if (isHost()) {
		if (Stag.getResource(Resource.Money) >= 50 && Bear.getResource(Resource.Money) >= 50) {
			Stag.addResource(Resource.Money, -50);
			Bear.addResource(Resource.Money, -50);
			sfx(UiSfx.BuySlaves);
			switch (Archer) {
				case 1: getZone(186).addUnit(Unit.AxeWielder, 1, Stag, true, null, 5); getZone(169).addUnit(Unit.AxeWielder, 1, Bear, true, null, 5);
				Stag.genericNotify("You purchased a [AxeWielder]"); Bear.genericNotify("You purchased a [AxeWielder]"); break;
				case 2: getZone(186).addUnit(Unit.Tracker, 1, Stag, true, null, 5); getZone(169).addUnit(Unit.Tracker, 1, Bear, true, null, 5);
				Stag.genericNotify("You purchased a [Tracker]"); Bear.genericNotify("You purchased a [Tracker]"); break;
				case 3: getZone(186).addUnit(Unit.Bowman, 1, Stag, true, null, 5); getZone(169).addUnit(Unit.Bowman, 1, Bear, true, null, 5);
				Stag.genericNotify("You purchased a [Bowman]"); Bear.genericNotify("You purchased a [Bowman]"); break;
			}
		} else {
			me().genericNotify("Non-AI players need 50 Kröwns");
		}
	}
}

function upgradeFighter() {
	if (isHost()) {
		switch (Fighter) {
		case 1:	if (Stag.getResource(Resource.Money) >= 500 && Bear.getResource(Resource.Money) >= 500 && Fighter == 1) {
				sfx(UiSfx.BuyAtMarketplace);
				Fighter = 2;
				Bear.genericNotify("You unlocked [Warrior02]");
				Stag.genericNotify("You unlocked [Warrior02]");
				Bear.addResource(Resource.Money, -500);
				Stag.addResource(Resource.Money, -500);
				break;
			} else { me().genericNotify("Non-AI players need 500 Kröwns to unlock [Warrior02]"); break; }

		case 2:	if (Stag.getResource(Resource.Money) >= 1000 && Bear.getResource(Resource.Money) >= 1000 && Fighter == 2) {
				sfx(UiSfx.BuyAtMarketplace);
				Fighter = 3;
				Bear.genericNotify("You unlocked [Einherjar]");
				Bear.genericNotify("You unlocked [Einherjar]");
				Bear.addResource(Resource.Money, -1000);
				Stag.addResource(Resource.Money, -1000);
				me().objectives.setVisible("UpgradeFighter2", false);
				break;
			} else { me().genericNotify("Non-AI players need 1000 Kröwns to unlock [Einherjar]"); break; }
		}
	}
}



function upgradeTank() {
	if (isHost()) {
		switch (Tank) {
		case 1:	if (Stag.getResource(Resource.Money) >= 500 && Bear.getResource(Resource.Money) >= 500 ) {
				sfx(UiSfx.BuyAtMarketplace);
				Tank = 2; // Tank-Level wird auf 2 erhöht
				Bear.genericNotify("You unlocked [ShieldBearer02]");
				Stag.genericNotify("You unlocked [ShieldBearer02]");
				Bear.addResource(Resource.Money, -500);
				Stag.addResource(Resource.Money, -500);
				break;
			} else { me().genericNotify("Non-AI players need 500 Kröwns"); break; }

		case 2:	if (Stag.getResource(Resource.Money) >= 1000 && Bear.getResource(Resource.Money) >= 1000) {
				sfx(UiSfx.BuyAtMarketplace);
				Tank = 3; // Tank-Level wird auf 3 erhöht
				Bear.genericNotify("You unlocked [Paladin]");
				Bear.genericNotify("You unlocked [Paladin]");
				Bear.addResource(Resource.Money, -1000);
				Stag.addResource(Resource.Money, -1000);
				me().objectives.setVisible("UpgradeTank2", false);
				break;
			} else { me().genericNotify("Non-AI players need 1000 Kröwns to unlock [Paladin]"); break; }
		}
	}
}

function upgradeArcher() {
	if (isHost()) {
		switch (Archer) {
		case 1:	if (Stag.getResource(Resource.Money) >= 500 && Bear.getResource(Resource.Money) >= 500) {
				sfx(UiSfx.BuyAtMarketplace);
				Archer = 2;
				Bear.genericNotify("You unlocked [Tracker]");
				Stag.genericNotify("You unlocked [Tracker]");
				Bear.addResource(Resource.Money, -500);
				Stag.addResource(Resource.Money, -500);
				break;
			} else { me().genericNotify("Non-AI players need 500 Kröwns to unlock [Tracker]"); break; }
		case 2:	if (Stag.getResource(Resource.Money) >= 1000 && Bear.getResource(Resource.Money) >= 1000) {
				sfx(UiSfx.BuyAtMarketplace);
				Archer = 3;
				Bear.genericNotify("You unlocked [Bowman]");
				Bear.genericNotify("You unlocked [Bowman]");
				Bear.addResource(Resource.Money, -1000);
				Stag.addResource(Resource.Money, -1000);
				me().objectives.setVisible("UpgradeTank2", false);
				break;
			} else { me().genericNotify("Non-AI players need 1000 Kröwns to unlock [Bowman]"); break; }
		}
	}
}


function buyLand() {
	if (isHost()) {
		switch (Land) {
		case 0: if (Stag.getResource(Resource.Money) >= 200 && Bear.getResource(Resource.Money) >= 200) {
			sfx(UiSfx.BuyAtMarketplace);
				getZone(163).allowScouting = true; // Vier Zonen werden dem Spieler freigeschaltet
				getZone(157).allowScouting = true;
				getZone(148).allowScouting = true;
				getZone(179).allowScouting = true;
				Stag.genericNotify("You bought the first Expansion, you can now scout four more tiles");
				Bear.genericNotify("You bought the first Expansion, you can now scout four more tiles");
				Stag.addResource(Resource.Money, -200); Bear.addResource(Resource.Money, -200);
				Land++; break;
			} else { me().genericNotify("Non-AI players need 200 Money to purchase the first Land"); break; }
		case 1: if (Stag.getResource(Resource.Money) >= 500 && Bear.getResource(Resource.Money) >= 500) {
				sfx(UiSfx.BuyAtMarketplace);
				getZone(162).allowScouting = true; // Fünf weitere Zonen werden dem Spieler freigeschaltet
				getZone(126).allowScouting = true;
				getZone(136).allowScouting = true;
				getZone(146).allowScouting = true;
				getZone(158).allowScouting = true;
				Stag.genericNotify("You bought the second Expansion, you can now scout five more tiles");
				Bear.genericNotify("You bought the second Expansion, you can now scout five more tiles");
				Stag.addResource(Resource.Money, -500); Bear.addResource(Resource.Money, -500);
				Land++; break;
			} else { me().genericNotify("Non-AI players need 500 Money to purchase the second Land"); break; }
		case 2:	if (Stag.getResource(Resource.Money) >= 1000 && Bear.getResource(Resource.Money) >= 1000) {
				sfx(UiSfx.BuyAtMarketplace);
				getZone(141).allowScouting = true; // Die restlichen Zonen werden dem Spieler freigeschaltet
				getZone(127).allowScouting = true;
				getZone(124).allowScouting = true;
				getZone(145).allowScouting = true;
				getZone(160).allowScouting = true;
				getZone(108).allowScouting = true;
				getZone(120).allowScouting = true;
				Stag.genericNotify("You bought the third Expansion, you can now scout seven more tiles");
				Bear.genericNotify("You bought the third Expansion, you can now scout seven more tiles");
				Stag.addResource(Resource.Money, -1000); Bear.addResource(Resource.Money, -1000);
				Land++; break;
			} else { me().genericNotify("Non-AI players need 1000 Money to purchase the third Land"); break; }
		}
	}
}



function spawnT1(z:Int<Zone>, player:Player) { //schwache Gegnertypen
	var AmountEnemyTypes; // Speichert die Anzahl der Gegnervarianten (Tank, Archer, Fighter)
	var EnemyType = math.floor(math.random()*3); // Speichert den exakten Gegnertypen (Tank, Archer und Fighter haben jeweils eine eindeutige ID 1, 2 oder 3) 
	var TempArray1=[]; var TempArray2=[]; var TempArray3=[]; var TempArray4=[]; // Temporäres Array um verschiedenen Einheiten später zu einer Welle zu kombinieren
	if (HordePower/3 > 1) { // Nur wenn Wellen Stärke größer als 3 ist, dürfen auch 3 Gegnervarianten spawnen dürfen. Wenn Wellen Stärke 1 ist, können nicht zwei Gegnervarianten spawnen, da es keine halben Einheiten gibt. 
		AmountEnemyTypes = math.floor(math.random()*3);
	} else if (HordePower/2 > 1) {
		AmountEnemyTypes = math.floor(math.random()*2);
	} else {
		AmountEnemyTypes = 0;
	}
	if (AmountEnemyTypes == 0) { // Nur eine Gegnervariante darf spawnen
		if (EnemyType == 0) { // Gegnertyp wird "Fighter" ausgewählt
			TempArray1 = getZone(z).addUnit(Unit.Warrior, math.floor(HordePower)); // Der Zone wird "Fighter" hinzugefügt und diese Einheit wird temporär gespeichert
			player.genericNotify("Wave " + math.floor(Wave) + ": [ Tier I ]\n" + math.floor(HordePower) + "x [Warrior]");
			}
		else if (EnemyType == 1) { // Gegnertyp wird "Tank" ausgewählt
			TempArray1 = getZone(z).addUnit(Unit.ShieldBearer, math.floor(HordePower));
			player.genericNotify("Wave " + math.floor(Wave) + ": [ Tier I ]\n" + math.floor(HordePower) + "x [ShieldBearer]");
			}
		else { // Gegnertyp wird "Archer" ausgewählt
			TempArray1 = getZone(z).addUnit(Unit.AxeWielder, math.floor(HordePower));
			player.genericNotify("Wave " + math.floor(Wave) + ": [ Tier I ]\n" + math.floor(HordePower) + "x [AxeWielder]");
			}
		}
	else if (AmountEnemyTypes == 1) { // Zwei Gegnervarianten dürfen spawnen
		if (EnemyType == 0) { // Gegnertyp wird "Fighter" und "Tank" ausgewählt
			TempArray1 = getZone(z).addUnit(Unit.Warrior, math.floor(HordePower/2));
			TempArray2 = getZone(z).addUnit(Unit.ShieldBearer, math.floor(HordePower/2));
			player.genericNotify("Wave " + math.floor(Wave) + ": [ Tier I ]\n" + math.floor(HordePower/2) + "x [Warrior] \n" + math.floor(HordePower/2) + "x [ShieldBearer]");
			}
		else if (EnemyType == 1) {
			TempArray1 = getZone(z).addUnit(Unit.ShieldBearer, math.floor(HordePower/2));
			TempArray2 = getZone(z).addUnit(Unit.AxeWielder, math.floor(HordePower/2));
			player.genericNotify("Wave " + math.floor(Wave) + ": [ Tier I ]\n" + math.floor(HordePower/2) + "x [ShieldBearer] \n" + math.floor(HordePower/2) + "x [AxeWielder]");
			}
		else {
			TempArray1 = getZone(z).addUnit(Unit.AxeWielder, math.floor(HordePower/2));
			TempArray2 = getZone(z).addUnit(Unit.Warrior, math.floor(HordePower/2));
			player.genericNotify("Wave " + math.floor(Wave) + ": [ Tier I ]\n" + math.floor(HordePower/2) + "x [Warrior] \n" + math.floor(HordePower/2) + "x [AxeWielder]");
			}
		}
	else {
		TempArray1 = getZone(z).addUnit(Unit.Warrior, math.floor(HordePower/3));
		TempArray2 = getZone(z).addUnit(Unit.ShieldBearer, math.floor(HordePower/3));
		TempArray3 = getZone(z).addUnit(Unit.AxeWielder, math.floor(HordePower/3));
		player.genericNotify("Wave " + math.floor(Wave) + ": [ Tier I ]\n" + math.floor(HordePower/3) + "x [Warrior] \n" + math.floor(HordePower/3) + "x [ShieldBearer] \n" + math.floor(HordePower/3) + "x [AxeWielder]");
		}
		if (Wave == 5) { // Boss-Welle, zufälliger Boss wird ausgewählt
			switch (math.floor(math.random()*3)) {
				case 0: TempArray4 = getZone(z).addUnit(Unit.Golem, 1, Wolf, true, null, 5); player.genericNotify("The [Golem] is incoming, beware of his burn attacks!");
				case 1: TempArray4 = getZone(z).addUnit(Unit.GayantHero, 1, Wolf, true, null, 5); player.genericNotify("The [GayantHero] is incoming, beware of his mighty armor!");
				case 2: TempArray4 = getZone(z).addUnit(Unit.UndeadGiantDragon, 1, Wolf, true, null, 5); player.genericNotify("The [UndeadGiantDragon] is incoming, beware of his incredible damage!");
			}
		}
	return TempArray1.concat(TempArray2.concat(TempArray3.concat(TempArray4))); // Die temporären Arrays für die einzelnen Einheiten werden zusammengeführt und zurückgegeben. 
}


function spawnT2(z:Int<Zone>, player:Player) { // normale Gegnertypen
	var AmountEnemyTypes = math.floor(math.random()*3);
	var EnemyType = math.floor(math.random()*3);
	var TempArray1=[]; var TempArray2=[]; var TempArray3=[]; var TempArray4=[]; var TempArray5;
	if (AmountEnemyTypes == 0) {
		if (EnemyType == 0) {
			TempArray1 = getZone(z).addUnit(Unit.Warrior02, math.floor(HordePower));
			player.genericNotify("Wave " + math.floor(Wave) + ": [ Tier II ]\n" + math.floor(HordePower) + "x [Warrior02]");
			}
		else if (EnemyType == 1) {
			TempArray1 = getZone(z).addUnit(Unit.ShieldBearer02, math.floor(HordePower));
			player.genericNotify("Wave " + math.floor(Wave) + ": [ Tier II ]\n" + math.floor(HordePower) + "x [ShieldBearer02]");
			}
		else {
			TempArray1 = getZone(z).addUnit(Unit.Tracker, math.floor(HordePower));
			player.genericNotify("Wave " + math.floor(Wave) + ": [ Tier II ]\n" + math.floor(HordePower) + "x [Tracker]");
			}
		}
	else if (AmountEnemyTypes == 1) {
		if (EnemyType == 0) {
			TempArray1 = getZone(z).addUnit(Unit.Warrior02, math.floor(HordePower/2));
			TempArray2 = getZone(z).addUnit(Unit.ShieldBearer02, math.floor(HordePower/2));
			player.genericNotify("Wave " + math.floor(Wave) + ": [ Tier II ]\n" + math.floor(HordePower/2) + "x [Warrior02] \n" + math.floor(HordePower/2) + "x [ShieldBearer02]");
			}
		else if (EnemyType == 1) {
			TempArray1 = getZone(z).addUnit(Unit.ShieldBearer02, math.floor(HordePower/2));
			TempArray2 = getZone(z).addUnit(Unit.Tracker, math.floor(HordePower/2));
			player.genericNotify("Wave " + math.floor(Wave) + ": [ Tier II ]\n" + math.floor(HordePower/2) + "x [ShieldBearer02] \n" + math.floor(HordePower/2) + "x [Tracker]");
			}
		else {
			TempArray1 = getZone(z).addUnit(Unit.Tracker, math.floor(HordePower/2));
			TempArray2 = getZone(z).addUnit(Unit.Warrior02, math.floor(HordePower/2));
			player.genericNotify("Wave " + math.floor(Wave) + ": [ Tier II ]\n" + math.floor(HordePower/2) + "x [Warrior02] \n" + math.floor(HordePower/2) + "x [Tracker]");
			}
		}
	else {
		TempArray1 = getZone(z).addUnit(Unit.Warrior02, math.floor(HordePower/3));
		TempArray2 = getZone(z).addUnit(Unit.ShieldBearer02, math.floor(HordePower/3));
		TempArray3 = getZone(z).addUnit(Unit.Tracker, math.floor(HordePower/3));
		player.genericNotify("Wave " + math.floor(Wave) + ": [ Tier II ]\n" + math.floor(HordePower/3) + "x [Warrior02] \n" + math.floor(HordePower/3) + "x [ShieldBearer02] \n" + math.floor(HordePower/3) + "x [Tracker]");
		}
	if (Wave == 10) {
		switch (math.floor(math.random()*3)) {
			case 0: TempArray4 = getZone(z).addUnit(Unit.Golem, 1, Wolf, true, null, 5); TempArray5 = getZone(z).addUnit(Unit.GayantHero, 1, Wolf, true, null, 5); player.genericNotify("The [Golem] and [GayantHero] are incoming!");
			case 1: TempArray4 = getZone(z).addUnit(Unit.GayantHero, 1, Wolf, true, null, 5); TempArray5 = getZone(z).addUnit(Unit.UndeadGiantDragon, 1, Wolf, true, null, 5); player.genericNotify("The [GayantHero] and [UndeadGiantDragon] are incoming!");
			case 2: TempArray4 = getZone(z).addUnit(Unit.UndeadGiantDragon, 1, Wolf, true, null, 5); TempArray5 = getZone(z).addUnit(Unit.Golem, 1, Wolf, true, null, 5); player.genericNotify("The [Golem] and [UndeadGiantDragon] are incoming!");
		}
	}
	return TempArray1.concat(TempArray2.concat(TempArray3.concat(TempArray4.concat(TempArray5))));
}



function spawnT3(z:Int<Zone>, player:Player) { //starke Gegnertypen
	var AmountEnemyTypes = math.floor(math.random()*3);
	var EnemyType = math.floor(math.random()*3);
	var TempArray1=[]; var TempArray2=[]; var TempArray3=[]; var TempArray4=[]; var TempArray5=[];
	if (AmountEnemyTypes == 0) {
		if (EnemyType == 0) {
			TempArray1 = getZone(z).addUnit(Unit.Einherjar, math.floor(HordePower));
			player.genericNotify("Wave " + math.floor(Wave) + ": [ Tier III ]\n" + math.floor(HordePower) + "x [Einherjar]");
			}
		else if (EnemyType == 1) {
			TempArray1 = getZone(z).addUnit(Unit.Paladin, math.floor(HordePower));
			player.genericNotify("Wave " + math.floor(Wave) + ": [ Tier III ]\n" + math.floor(HordePower) + "x [Paladin]");
			}
		else {
			TempArray1 = getZone(z).addUnit(Unit.Bowman, math.floor(HordePower));
			player.genericNotify("Wave " + math.floor(Wave) + ": [ Tier III ]\n" + math.floor(HordePower) + "x [Bowman]");
			}
		}
	else if (AmountEnemyTypes == 1) {
		if (EnemyType == 0) {
			TempArray1 = getZone(z).addUnit(Unit.Einherjar, math.floor(HordePower/2));
			TempArray2 = getZone(z).addUnit(Unit.Paladin, math.floor(HordePower/2));
			player.genericNotify("Wave " + math.floor(Wave) + ": [ Tier III ]\n" + math.floor(HordePower/2) + "x [Einherjar] \n" + math.floor(HordePower/2) + "x [Paladin]");
			}
		else if (EnemyType == 1) {
			TempArray1 = getZone(z).addUnit(Unit.Paladin, math.floor(HordePower/2));
			TempArray2 = getZone(z).addUnit(Unit.Bowman, math.floor(HordePower/2));
			player.genericNotify("Wave " + math.floor(Wave) + ": [ Tier III ]\n" + math.floor(HordePower/2) + "x [Paladin] \n" + math.floor(HordePower/2) + "x [Bowman]");
			}
		else {
			TempArray1 = getZone(z).addUnit(Unit.Bowman, math.floor(HordePower/2));
			TempArray2 = getZone(z).addUnit(Unit.Einherjar, math.floor(HordePower/2));
			player.genericNotify("Wave " + math.floor(Wave) + ": [ Tier III ]\n" + math.floor(HordePower/2) + "x [Einherjar] \n" + math.floor(HordePower/2) + "x [Bowman]");
			}
		}
	else {
		TempArray1 = getZone(z).addUnit(Unit.Einherjar, math.floor(HordePower/3));
		TempArray2 = getZone(z).addUnit(Unit.Paladin, math.floor(HordePower/3));
		TempArray3 = getZone(z).addUnit(Unit.Bowman, math.floor(HordePower/3));
		player.genericNotify("Wave " + math.floor(Wave) + ": [ Tier III ]\n" + math.floor(HordePower/3) + "x [Einherjar] \n" + math.floor(HordePower/3) + "x [Paladin] \n" + math.floor(HordePower/3) + "x [Bowman]");
		}
	if (Wave == 15 || Wave >= 18) {

		switch (math.floor(math.random()*2)) {
			case 0: TempArray4 = getZone(z).addUnit(Unit.LichKing, 1, Wolf, true, null, 5); TempArray5 = getZone(z).addUnit(Unit.IceGolem, Wave-13, Wolf, true, null, 5); player.genericNotify("The [LichKing] along his servants are approaching!");
			case 1: TempArray4 = getZone(z).addUnit(Unit.IronGolem, 1, Wolf, true, null, 5); player.genericNotify("The [IronGolem] is marching towards you!");
		}
	}

	return TempArray1.concat(TempArray2.concat(TempArray3.concat(TempArray4.concat(TempArray5))));
}


function getBonus(p:Player) {
	if (isHost() && p.clan != Clan.Wolf) { // Wolf darf keine Bonusse bekommen
			var RandomNum = math.floor(math.random() * 16); // Eine Zahl zwischen 0-15 wird gewürfelt, je nachdem wird dann ein Bonus dem Spieler hinzugefügt
				if (RandomNum <= 2 && p.hasBonus(ConquestBonus.BResBonus, null, null, Resource.Food) == false) {
					p.addBonus({ id: ConquestBonus.BResBonus, resId:Resource.Food, isAdvanced: false });
					p.genericNotify("You gain common Bonus:\n+20 [Food]");
				} else if ( RandomNum == 0 && p.hasBonus(ConquestBonus.BResBonus, null, null, Resource.Food) == true) { getBonus(p);} // Wenn der Spieler den jeweiligen Bonus bereits erhalten hat, dann wird erneut gewürfelt. 

				if (RandomNum <= 4 && RandomNum > 2 && p.hasBonus(ConquestBonus.BJobProd, Unit.Woodcutter) == false) {
					p.addBonus({ id: ConquestBonus.BJobProd, unitId:Unit.Woodcutter, isAdvanced: false });
					p.genericNotify("You gain common Bonus:\n+50% [Woodcutter]");
				} else if ( RandomNum == 1 && p.hasBonus(ConquestBonus.BJobProd, Unit.Woodcutter) == true) { getBonus(p);}

				if (RandomNum <= 6 && RandomNum > 4 && p.hasBonus(ConquestBonus.BPopGrowth) == false) {
					p.addBonus({ id: ConquestBonus.BPopGrowth, isAdvanced: false });
					p.genericNotify("You gain common Bonus:\n+100% [Population] Growth");
				} else if ( RandomNum == 4 && p.hasBonus(ConquestBonus.BPopGrowth) == true) { getBonus(p);}

				if (RandomNum <= 8 && RandomNum > 6 && p.hasBonus(ConquestBonus.BMineral, null, null, Resource.Stone) == false) {
					p.addBonus({ id: ConquestBonus.BMineral, resId:Resource.Iron, isAdvanced: false });
					p.genericNotify("You gain common Bonus:\n+1 [Stone] every month");
				} else if ( RandomNum == 5 && p.hasBonus(ConquestBonus.BMineral, null, null, Resource.Iron) == true) { getBonus(p);}

				if (RandomNum <= 10 && RandomNum > 8 && p.hasBonus(ConquestBonus.BSilo) == false) {
					p.addBonus({ id: ConquestBonus.BSilo, isAdvanced: false });
					p.genericNotify("You gain common Bonus:\nBetter [Silo]");
				} else if ( RandomNum == 6 && p.hasBonus(ConquestBonus.BSilo) == true) { getBonus(p);}

				if (RandomNum == 11 && p.hasBonus(ConquestBonus.BAltar) == false) {
					p.addBonus({ id: ConquestBonus.BAltar, isAdvanced: false });
					p.genericNotify("You gain rare Bonus:\nBetter [Altar]");
				} else if ( RandomNum == 8 && p.hasBonus(ConquestBonus.BAltar) == true) { getBonus(p); }

				if (p.clan == Clan.Bear) {
					if (RandomNum == 12 && p.hasBonus(ConquestBonus.BHeartyLife) == false) {
						p.addBonus({ id: ConquestBonus.BHeartyLife, isAdvanced: false });
						p.genericNotify("You gain rare Bonus:\n+10 HP on all Units");
					} else if ( RandomNum == 9 && p.hasBonus(ConquestBonus.BHeartyLife) == true) { getBonus(p); }

					if (RandomNum == 13 && p.hasBonus(ConquestBonus.BSiloImproved) == false) {
						p.addBonus({ id: ConquestBonus.BSiloImproved, isAdvanced: false });
						p.genericNotify("You gain rare Bonus:\nOverpowered Silo");
					} else if ( RandomNum == 10 && p.hasBonus(ConquestBonus.BSiloImproved) == true) { getBonus(p); }

				} else {
					if (RandomNum == 14 && p.hasBonus(ConquestBonus.BSkalds) == false) {
						p.addBonus({ id: ConquestBonus.BSkalds, isAdvanced: false });
						p.genericNotify("You gain rare Bonus:\n+200% [Skald]");
					} else if ( RandomNum == 9 && p.hasBonus(ConquestBonus.BSkalds) == true) { getBonus(p); }

					if (RandomNum == 15 && p.hasBonus(ConquestBonus.BStagFame2) == false) {
						p.addBonus({ id: ConquestBonus.BStagFame2, isAdvanced: false });
						p.genericNotify("You gain rare Bonus:\n1000 [Fame] Bonus");
					} else if ( RandomNum == 10 && p.hasBonus(ConquestBonus.BStagFame2) == true) { getBonus(p); }
				}
			}
		}

function getEvent() {
	if (isHost()) {
		var RandomNum = (math.floor(math.random()*7)); // 1 von 7 Ereignissen wird gewürfelt
		if ((HorseHeros == false) && RandomNum == 5 && Difficulty <= 0.5) {
			getZone(186).addUnit(Unit.HorseMaiden, 1, Stag, true, null, 5);
			getZone(169).addUnit(Unit.HorseHero, 1, Bear, true, null, 5);
			Bear.genericNotify("Good Event: You gain [HorseHero], he can mine and forge");
			Stag.genericNotify("Good Event: You gain [HorseMaiden], she can mine and forge");
			break;
		} else { RandomNum = getEvent(); }
		if ((hasRule(Rule.MarketLowPrice) == false) && RandomNum == 0 && Difficulty <= 1.0) {
			addRule(Rule.MarketLowPrice);
			addRule(Rule.TradeRouteBonus);
			Stag.genericNotify("Good Rule: Cheaper Market + Better Trade Routes");
			Bear.genericNotify("Good Rule: Cheaper Market + Better Trade Routes");
			break;
		} else { RandomNum = getEvent(); }

		if ((hasRule(Rule.TreasureRespawn) == false) && RandomNum == 1) {
			addRule(Rule.TreasureRespawn);
			addRule(Rule.LethalRuins);
			Stag.genericNotify("Good Event: Treasures respawn but scouts die");
			Bear.genericNotify("Good Event: Treasures respawn but scouts die");
			break;
		} else { RandomNum = getEvent(); }

		if ((hasRule(Rule.HealerAccess) == false) && RandomNum == 2) {
			addRule(Rule.HealerAccess);
			Bear.genericNotify("Good Event: You can now build field healers");
			Stag.genericNotify("Good Event: You can now build field healers");
			break;
		} else { RandomNum = getEvent(); }

		if ((hasRule(Rule.ZombieDraugr) == false) && RandomNum == 3) {
			addRule(Rule.ZombieDraugr);
			Bear.genericNotify("Bad Event: Humans turn into Draugr upon Death");
			Stag.genericNotify("Bad Event: Humans turn into Draugr upon Death");
			break;
		} else { RandomNum = getEvent(); }
		if ((WolfDefense == false) && RandomNum == 6) {
			WolfDefense = true;
			Bear.genericNotify("Bad Event: If you decolonize Wolf Tiles, he gains [Bear] as protection");
			Stag.genericNotify("Bad Event: If you decolonize Wolf Tiles, he gains [Bear] as protection");
			break;
		} else { RandomNum = getEvent(); }
		if ((WolfRevenge == false) && RandomNum == 5) {
			WolfRevenge = true;
			Bear.genericNotify("Bad Event: If you decolonize Wolf Tiles, the next Wave will be stronger");
			Stag.genericNotify("Bad Event: If you decolonize Wolf Tiles, the next Wave will be stronger");
			break;
		} else { RandomNum = getEvent(); }
		if ((Wolf.hasBonus(ConquestBonus.BCoastalHurt) == true) && RandomNum == 4 && Difficulty == 1.5) {
			Wolf.addBonus({ id: ConquestBonus.BCoastalHurt, isAdvanced: false });
			Bear.genericNotify("Bad Event: Entering Wolf Territory damages your units");
			Stag.genericNotify("Bad Event: Entering Wolf Territory damages your units");
			break;
		} else { RandomNum = getEvent(); }

	}
}


function aiBuffs() { // Hier wird die KI gebufft, da die KI vom Spiel leider nicht sehr gut ist
	if (isHost()) {
		if (Wolf.getResource(Resource.Food) < 300) { Wolf.addResource(Resource.Food, 300); }
		if (Stag.isAI) {
			if (Stag.getResource(Resource.Money) < 1000) { Stag.addResource(Resource.Money, 1000); } 
			if (Stag.getResource(Resource.Food) < 250) { Stag.addResource(Resource.Food, 250); }
		}
		if (Bear.isAI) {
			if (Bear.getResource(Resource.Money) < 1000) { Bear.addResource(Resource.Money, 1000); }
			if (Bear.getResource(Resource.Food) < 250) { Bear.addResource(Resource.Food, 250); }
		}
		for (p in state.players) {
			for (zone in p.zones) {
				if (zone.colonize < 0.95 && p.isAI && p.clan != Clan.Wolf) { // Wenn die KI angegriffen wird, werden alle Einheiten der KI gesammelt und gezwungen sich zu verteidigen
					launchAttack(p.getUnits(Unit.Warrior), [zone.id]);
					launchAttack(p.getUnits(Unit.ShieldBearer), [zone.id]);
					launchAttack(p.getUnits(Unit.AxeWielder), [zone.id]);
					launchAttack(p.getUnits(Unit.Warrior02), [zone.id]);
					launchAttack(p.getUnits(Unit.ShieldBearer02), [zone.id]);
					launchAttack(p.getUnits(Unit.Tracker), [zone.id]);
					launchAttack(p.getUnits(Unit.Einherjar), [zone.id]);
					launchAttack(p.getUnits(Unit.Paladin), [zone.id]);
					launchAttack(p.getUnits(Unit.Bowman), [zone.id]);
					launchAttack(p.getWarchiefs(), [zone.id]);
				}
			}

			if (p.isAI && p.clan != Clan.Wolf && state.time % 60 < 0.1 && (p.getMilitaryCount(null, true) < (Wave*Difficulty))) { // Hier werden alle 60 Sekunden drei Einheiten der KI hinzugefügt, falls die KI zu wenige Einheiten hat. 
				switch (Fighter) {
					case 1: getZone(p.getBuilding(Building.TownHall).zone.id).addUnit(Unit.Warrior, 1, p, true, null, 5);
					case 2: getZone(p.getBuilding(Building.TownHall).zone.id).addUnit(Unit.Warrior02, 1, p, true, null, 5);
					case 3: getZone(p.getBuilding(Building.TownHall).zone.id).addUnit(Unit.Einherjar, 1, p, true, null, 5);
				}
				switch (Tank) {
					case 1: getZone(p.getBuilding(Building.TownHall).zone.id).addUnit(Unit.ShieldBearer, 1, p, true, null, 5);
					case 2: getZone(p.getBuilding(Building.TownHall).zone.id).addUnit(Unit.ShieldBearer02, 1, p, true, null, 5);
					case 3: getZone(p.getBuilding(Building.TownHall).zone.id).addUnit(Unit.Paladin, 1, p, true, null, 5);
				}
				switch (Archer) {
					case 1: getZone(p.getBuilding(Building.TownHall).zone.id).addUnit(Unit.AxeWielder, 1, p, true, null, 5);
					case 2: getZone(p.getBuilding(Building.TownHall).zone.id).addUnit(Unit.Tracker, 1, p, true, null, 5);
					case 3: getZone(p.getBuilding(Building.TownHall).zone.id).addUnit(Unit.Bowman, 1, p, true, null, 5);
				}
				break;
			}
		}
	}
}
