// ------------------------------------------------------------
// A 12-gauge shotgun without side saddles
// ------------------------------------------------------------
class HDCombatShotgun:HDShotgun{ //hope you're good at pumping ;)
	default{
		//$Category "Weapons/Hideous Destructor"
		//$Title "Combat Shotgun"
		//$Sprite "CTSGA0"

   +hdweapon.fitsinbackpack
		weapon.selectionorder 31;
		weapon.slotnumber 3;
		weapon.slotpriority 1;
		weapon.bobrangex 0.21;
		weapon.bobrangey 0.9;
		scale 0.6;
		hdweapon.barrelsize 25,0.5,2;//30-5=25, shorter because there's no stock
		hdweapon.refid "CSG";
		tag "$TAG_COMBATSHOTGUN";
		obituary "$OB_COMBATSHOTGUN";
	}

	override string pickupmessage(){
		return Stringtable.Localize("$PICKUP_COMBATSHOTGUN");
	}

	//returns the power of the load just fired
	static double Fire(actor caller,int choke=1){
		double spread=6.;
		double speedfactor=1.;
		let hhh=HDCombatShotgun(caller.findinventory("HDCombatShotgun"));
		if(hhh)choke=hhh.weaponstatus[HUNTS_CHOKE];

		choke=0;//no choke for extra spread
		spread=6.5-0.5*choke;
		speedfactor=1.+0.02857*choke;

		double shotpower=getshotpower();
		spread*=shotpower;
		speedfactor*=shotpower;
		HDBulletActor.FireBullet(caller,"HDB_wad");
		let p=HDBulletActor.FireBullet(caller,"HDB_00",
			spread:spread,speedfactor:speedfactor,amount:10
		);
		distantnoise.make(p,"weapons/csg_firefar");
		caller.A_StartSound("weapons/csg_fire",CHAN_WEAPON);
		return shotpower;
	}
	const HUNTER_MINSHOTPOWER=0.901;
	action void A_FireHunter(){
		double shotpower=invoker.Fire(self);
		A_GunFlash();
		vector2 shotrecoil=(randompick(-1,1),-2.6);
		if(invoker.weaponstatus[HUNTS_FIREMODE]>0)shotrecoil=(randompick(-1,1)*1.4,-3.4);
		shotrecoil*=shotpower;
		A_MuzzleClimb(0,0,shotrecoil.x,shotrecoil.y,randompick(-1,1)*shotpower,-0.3*shotpower);
		invoker.weaponstatus[HUNTS_CHAMBER]=1;
		invoker.shotpower=shotpower;
	}

	override string,double getpickupsprite(bool usespare){return "CTSG"..getpickupframe(usespare).."0",1.;}

	override void DrawHUDStuff(HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl){
		if(sb.hudlevel==1){
			sb.drawimage("SHL1A0",(-47,-10),basestatusbar.DI_SCREEN_CENTER_BOTTOM);
			sb.drawnum(hpl.countinv("HDShellAmmo"),-46,-8,
				basestatusbar.DI_SCREEN_CENTER_BOTTOM
			);
		}
		if(hdw.weaponstatus[HUNTS_CHAMBER]>1){
			sb.drawrect(-24,-14,5,3);
			sb.drawrect(-18,-14,2,3);
		}
		else if(hdw.weaponstatus[HUNTS_CHAMBER]>0){
			sb.drawrect(-18,-14,2,3);
		}
	sb.drawwepnum(hdw.weaponstatus[HUNTS_TUBE],hdw.weaponstatus[HUNTS_TUBESIZE],posy:-7);

	}
	override string gethelptext(){
		return
		WEPHELP_FIRE.."  Shoot\n"//no choke
		..WEPHELP_ALTFIRE.."  Pump\n"
		..WEPHELP_RELOAD.."  Reload\n"
		..WEPHELP_UNLOADUNLOAD
		;//no side saddles
	}
	override void DrawSightPicture(
		HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl,
		bool sightbob,vector2 bob,double fov,bool scopeview,actor hpc
	){
		int cx,cy,cw,ch;
		[cx,cy,cw,ch]=screen.GetClipRect();
		sb.SetClipRect(
			-16+bob.x,-32+bob.y,32,40, 
			sb.DI_SCREEN_CENTER
		);
		vector2 bobb=bob*2.2; //2x more bobbing because there's no stock
		sb.drawimage(
			"frntsite",(0,0)+bobb,sb.DI_SCREEN_CENTER|sb.DI_ITEM_TOP
		);
		sb.SetClipRect(cx,cy,cw,ch);
		sb.drawimage(
			"sgbaksit",(0,0)+bob,sb.DI_SCREEN_CENTER|sb.DI_ITEM_TOP,
			alpha:0.0//there's no back sight on the weapon sprites
		);
	}
	override double gunmass(){
		int tube=weaponstatus[HUNTS_TUBE];
		if(tube>4)tube+=(tube-4)*2;
		return 8+tube*0.3; 
	}
	override double weaponbulk(){
		return 100+(weaponstatus[HUNTS_TUBE])*ENC_SHELLLOADED;//125-25=100
	}//less bulk because there's no stock or side saddles

	action void A_SetAltHold(bool which){
		if(which)invoker.weaponstatus[0]|=HUNTF_ALTHOLDING;
		else invoker.weaponstatus[0]&=~HUNTF_ALTHOLDING;
	}

  action bool A_LoadTubeFromHand(){
		int hand=invoker.handshells;
		if(
			!hand
			||(
				invoker.weaponstatus[HUNTS_CHAMBER]>0
				&&invoker.weaponstatus[HUNTS_TUBE]>=invoker.weaponstatus[HUNTS_TUBESIZE]
			)
		){
			EmptyHand();
			return false;
		}
		invoker.weaponstatus[HUNTS_TUBE]++;
		invoker.handshells--;
		A_StartSound("weapons/csg_reload",8,CHANF_OVERLAP);
		return true;
	}

	action void A_Chamber(bool careful=false){
		int chm=invoker.weaponstatus[HUNTS_CHAMBER];
		invoker.weaponstatus[HUNTS_CHAMBER]=0;
		if(invoker.weaponstatus[HUNTS_TUBE]>0){
			invoker.weaponstatus[HUNTS_CHAMBER]=2;
			invoker.weaponstatus[HUNTS_TUBE]--;
		}
		vector3 cockdir;double cp=cos(pitch);
		if(careful)cockdir=(-cp,cp,-5);
		else cockdir=(0,-cp*5,sin(pitch)*frandom(4,6));
		cockdir.xy=rotatevector(cockdir.xy,angle);
		bool pocketed=false;
		if(chm>1){
			if(careful&&!A_JumpIfInventory("HDShellAmmo",0,"null")){
				HDF.Give(self,"HDShellAmmo",1);
				pocketed=true;
			}
		}else if(chm>0){	
			cockdir*=frandom(1.,1.3);
		}

		if(
			!pocketed
			&&chm>=1
		){
			vector3 gunofs=HDMath.RotateVec3D((9,-1,-2),angle,pitch);
			actor rrr=null;

			if(chm>1)rrr=spawn("HDFumblingShell",(pos.xy,pos.z+height*0.85)+gunofs+viewpos.offset);
			else rrr=spawn("HDSpentShell",(pos.xy,pos.z+height*0.85)+gunofs+viewpos.offset);

			rrr.target=self;
			rrr.angle=angle;
			rrr.vel=HDMath.RotateVec3D((1,-2,0.2),angle,pitch);
       //i think this is the ejection angle
       //(1,5,0.2) ejects to the leftt
       //(1,-5,0.2) ejects to the right

			if(chm==1)rrr.vel*=1.3;
			rrr.vel+=vel;
		}
	}

	action bool A_GrabShells(int maxhand=3,bool settics=false,bool alwaysone=false){
		if(maxhand>0)EmptyHand();else maxhand=abs(maxhand);
		bool fromsidesaddles=!(invoker.weaponstatus[0]&HUNTF_FROMPOCKETS);
		int toload=min(
			fromsidesaddles?invoker.weaponstatus[SHOTS_SIDESADDLE]:countinv("HDShellAmmo"),
			alwaysone?1:(invoker.weaponstatus[HUNTS_TUBESIZE]-invoker.weaponstatus[HUNTS_TUBE]),
			maxhand
		);
		if(toload<1)return false;
		invoker.handshells=toload;
		if(fromsidesaddles){
			invoker.weaponstatus[SHOTS_SIDESADDLE]-=toload;
			if(settics)A_SetTics(2);
			A_StartSound("weapons/pocket",8,CHANF_OVERLAP,0.4);
			A_MuzzleClimb(
				frandom(0.1,0.15),frandom(0.05,0.08),
				frandom(0.1,0.15),frandom(0.05,0.08)
			);
		}else{
			A_TakeInventory("HDShellAmmo",toload,TIF_NOTAKEINFINITE);
			if(settics)A_SetTics(7);
			A_StartSound("weapons/pocket",9);
			A_MuzzleClimb(
				frandom(0.1,0.15),frandom(0.2,0.4),
				frandom(0.2,0.25),frandom(0.3,0.4),
				frandom(0.1,0.35),frandom(0.3,0.4),
				frandom(0.1,0.15),frandom(0.2,0.4)
			);
		}
		return true;
	}


clearscope string getpickupframe(bool usespare){
		return "A";
	}

	states{
	select0:
		IM37 A 0;
		goto select0big;
	deselect0:
		IM37 A 0;
		goto deselect0big;

	ready:
		
		IM37 A 0 A_JumpIf(pressingaltfire(),2);
		IM37 A 0{
			if(!pressingaltfire()){
				if(!pressingfire())A_ClearRefire();
				A_SetAltHold(false);
			}
		}
		IM37 A 1 A_WeaponReady(WRF_ALL);
		goto readyend;

	hold:
		IM37 A 0{
			bool paf=pressingaltfire();
			if(
				paf&&!(invoker.weaponstatus[0]&HUNTF_ALTHOLDING)
			)setweaponstate("chamber");
			else if(!paf)invoker.weaponstatus[0]&=~HUNTF_ALTHOLDING;
		}
		IM37 A 1 A_WeaponReady(WRF_NONE);
		IM37 A 0 A_Refire();
		goto ready;
	fire:
		IM37 A 0 A_JumpIf(invoker.weaponstatus[HUNTS_CHAMBER]==2,"shoot");
		IM37 A 1 A_WeaponReady(WRF_NONE);
		IM37 A 0 A_Refire();
		goto ready;
	shoot:
		IM37 A 2;
		IM37 A 1 offset(0,36) A_FireHunter();
		IM37 A 1;
		IM37 A 0{
			if(
				invoker.weaponstatus[HUNTS_FIREMODE]>0
				&&invoker.shotpower>HUNTER_MINSHOTPOWER
			)setweaponstate("chamberauto");
		}goto ready;
	altfire:  //uses the classic Doom shotgun reload frames :)
	chamber:
		IM37 A 0 A_JumpIf(invoker.weaponstatus[0]&HUNTF_ALTHOLDING,"nope");
		IM37 A 0 A_SetAltHold(true);
		IM37 A 1 A_Overlay(120,"playsgco");
		IM37 AB 3 A_MuzzleClimb(0,frandom(0.6,1.));
		IM37 C 2 A_JumpIf(pressingaltfire(),"longstroke");
		IM37 CB 3 A_MuzzleClimb(0,-frandom(0.6,1.));
		IM37 B 0 A_StartSound("weapons/csg_short",8);
		IM37 A 0 A_Refire("ready");
		goto ready;
	longstroke:
		IM37 D 2 A_MuzzleClimb(frandom(1.,2.));
		IM37 D 0{
			A_Chamber();
			A_MuzzleClimb(-frandom(1.,2.));
		}
	racked:
		IM37 D 1 A_WeaponReady(WRF_NOFIRE);
		IM37 D 0 A_JumpIf(!pressingaltfire(),"unrack");
		IM37 D 0 A_JumpIf(pressingunload(),"racked");
		IM37 D 0 A_JumpIf(invoker.weaponstatus[HUNTS_CHAMBER],"racked");
		loop;

	rackreload:
		IM37 D 1 offset(-1,35) A_WeaponBusy(true);
		IM37 D 2 offset(-2,37);
		IM37 D 4 offset(-3,40);
		IM37 D 1 offset(-4,42) A_GrabShells(1,true,true);
		IM37 D 0 A_JumpIf(!(invoker.weaponstatus[0]&HUNTF_FROMPOCKETS),"rackloadone");
		IM37 D 6 offset(-5,43);
		IM37 D 6 offset(-4,41) A_StartSound("weapons/pocket",9);
	rackloadone:
		goto rackreloadend;
	rackreloadend:
		IM37 D 1 offset(-3,39);
		IM37 D 1 offset(-2,37);
		IM37 D 1 offset(-1,34);
		IM37 D 0 A_WeaponBusy(false);
		goto racked;


	unrack: 
		IM37 D 0 A_Overlay(120,"playsgco2");
		IM37 C 3 A_JumpIf(!pressingfire(),1);
		IM37 BA 3{
			if(pressingfire())A_SetTics(1);
			A_MuzzleClimb(0,-frandom(0.6,1.));
		}
		IM37 A 0 A_ClearRefire();
		goto ready;

	playsgco:
		TNT1 A 8 A_StartSound("weapons/csg_rackup",8);
		TNT1 A 0 A_StopSound(8);
		stop;
	playsgco2:
		TNT1 A 8 A_StartSound("weapons/csg_rackdown",8);
		TNT1 A 0 A_StopSound(8);
		stop;

	chamberauto:
		IM37 A 1 A_Chamber();
		IM37 A 1 A_JumpIf(invoker.weaponstatus[0]&HUNTF_CANFULLAUTO&&invoker.weaponstatus[HUNTS_FIREMODE]==2,"ready");
		IM37 A 0 A_Refire();
		goto ready;

	flash:
		IM3F A 1 bright{
			A_Light2();
			HDFlashAlpha(-32);
		}
		TNT1 A 1 A_ZoomRecoil(0.9);
		TNT1 A 0 A_Light0();
		TNT1 A 0 A_AlertMonsters();
		stop;

 reload:
	altreload:
	reloadfrompockets:
		IM37 A 0{
			if(!countinv("HDShellAmmo"))setweaponstate("nope");
			else invoker.weaponstatus[0]|=HUNTF_FROMPOCKETS;
		}goto startreload;

	startreload:
		IM37 A 1{
			if(//if the tube is full but you still have ammo, then do nothing
				invoker.weaponstatus[HUNTS_TUBE]>=invoker.weaponstatus[HUNTS_TUBESIZE]
			  ){
				  if(countinv("HDShellAmmo"))setweaponstate("nope");
	      }	
      }
		IM37 AB 4 A_MuzzleClimb(frandom(.6,.7),-frandom(.6,.7));
  //this is where the reload loop starts
	reloadstarthand://getting ready to reload
		IM37 C 1 offset(0,36);
		IM37 C 1 offset(0,38);
		IM37 C 2 offset(0,36);
		IM37 C 2 offset(0,34);
		IM37 C 3 offset(0,36);
		IM37 C 3 offset(0,40);

	reloadpocket://fishing for shells
		IM37 C 3 offset(0,39) A_GrabShells(3,false);
		IM37 C 5 offset(0,42) A_StartSound("weapons/pocket",9);
		IM37 C 6 offset(0,41) A_StartSound("weapons/pocket",9);
		IM37 C 4 offset(0,40);
		goto reloadashell;

	reloadashell://time to put the shells in the tube
		IM37 C 2 offset(0,36);
		IM37 C 4 offset(0,34)A_LoadTubeFromHand();//put a shell in the tube
		IM37 CCCCCC 1 offset(0,33){
			if(
				PressingReload()
				||PressingAltReload()
				||PressingUnload()
				||PressingFire()
				||PressingAltfire()
				||PressingZoom()
				||PressingFiremode()
			)invoker.weaponstatus[0]|=HUNTF_HOLDING;
			else invoker.weaponstatus[0]&=~HUNTF_HOLDING;

			if(//if you run out of shells and have none in your hand, stop reloading
				invoker.weaponstatus[HUNTS_TUBE]>=invoker.weaponstatus[HUNTS_TUBESIZE]
				||(
					invoker.handshells<1&&(
						invoker.weaponstatus[0]&HUNTF_FROMPOCKETS
					)&&
					!countinv("HDShellAmmo")
				)
			)setweaponstate("reloadend");

			else if(//if you let go of either reload button, stop reloading
				!pressingaltreload()
				&&!pressingreload()
			)setweaponstate("reloadend");
			else if(invoker.handshells<1)setweaponstate("reloadstarthand");
		}goto reloadashell;
  //if you're still reloading but have no shells in hand, try to grab 3 more
  //this is where the reload loop ends

	reloadend:
		IM37 C 4 offset(0,34) A_StartSound("weapons/csg_open",8);
		IM37 C 1 offset(0,36) EmptyHand(careful:true);
		IM37 C 1 offset(0,34);
		IM37 CBA 3;
		IM37 A 0 A_JumpIf(invoker.weaponstatus[0]&HUNTF_HOLDING,"nope");
		goto ready;

	unloadSS:
		goto nope;

	unload:
		IM37 A 1{
    if(
				invoker.weaponstatus[HUNTS_CHAMBER]<1
				&&invoker.weaponstatus[HUNTS_TUBE]<1
			)setweaponstate("nope");
		}
		IM37 BC 4 A_MuzzleClimb(frandom(1.2,2.4),-frandom(1.2,2.4));
		IM37 C 1 offset(0,34);
		IM37 C 1 offset(0,36) A_StartSound("weapons/csg_open",8);
		IM37 C 1 offset(0,38);
		IM37 C 4 offset(0,36){
			A_MuzzleClimb(-frandom(1.2,2.4),frandom(1.2,2.4));
			//if(invoker.weaponstatus[HUNTS_CHAMBER]<1){
				setweaponstate("unloadtube");
				}
			/*
}else A_StartSound("weapons/huntrack",8,CHANF_OVERLAP);
		}
		IM37 D 8 offset(0,34){
			A_MuzzleClimb(-frandom(1.2,2.4),frandom(1.2,2.4));
			int chm=invoker.weaponstatus[HUNTS_CHAMBER];
			invoker.weaponstatus[HUNTS_CHAMBER]=0;
			if(chm>1){
				A_StartSound("weapons/huntreload",8);
				if(A_JumpIfInventory("HDShellAmmo",0,"null"))A_SpawnItemEx("HDFumblingShell",
					cos(pitch)*8,0,height-7-sin(pitch)*8,
					vel.x+cos(pitch)*cos(angle-random(86,90))*5,
					vel.y+cos(pitch)*sin(angle-random(86,90))*5,
					vel.z+sin(pitch)*random(4,6),
					0,SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION|SXF_TRANSFERPITCH
				);else{
					HDF.Give(self,"HDShellAmmo",1);
					A_StartSound("weapons/pocket",9);
					A_SetTics(5);
				}
			}else if(chm>0)A_SpawnItemEx("HDSpentShell",
				cos(pitch)*8,0,height-7-sin(pitch)*8,
				vel.x+cos(pitch)*cos(angle-random(86,90))*5,
				vel.y+cos(pitch)*sin(angle-random(86,90))*5,
				vel.z+sin(pitch)*random(4,6),
				0,SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION|SXF_TRANSFERPITCH
			);
		}
	*/
		IM37 C 0 A_JumpIf(!pressingunload(),"reloadend");
		IM37 C 4 offset(0,40);
	unloadtube:
		IM37 C 6 offset(0,40) EmptyHand(careful:true);
	unloadloop:
		IM37 C 8 offset(1,41){
			if(invoker.weaponstatus[HUNTS_TUBE]<1)setweaponstate("reloadend");
			else if(invoker.handshells>=3)setweaponstate("unloadloopend");
			else{
				invoker.handshells++;
				invoker.weaponstatus[HUNTS_TUBE]--;
			}
		}
		IM37 C 4 offset(0,40) A_StartSound("weapons/csg_reload",8);
		loop;
	unloadloopend:
		IM37 C 6 offset(1,41);
		IM37 C 3 offset(1,42){
			int rmm=HDPickup.MaxGive(self,"HDShellAmmo",ENC_SHELL);
			if(rmm>0){
				A_StartSound("weapons/pocket",9);
				A_SetTics(8);
				HDF.Give(self,"HDShellAmmo",min(rmm,invoker.handshells));
				invoker.handshells=max(invoker.handshells-rmm,0);
			}
		}
		IM37 C 0 EmptyHand(careful:true);
		IM37 C 6 A_Jumpif(!pressingunload(),"reloadend");
		goto unloadloop;
	spawn:
	 CTSG A -1;
	}

	override void InitializeWepStats(bool idfa){
		weaponstatus[HUNTS_CHAMBER]=2;
		if(!idfa){
			weaponstatus[HUNTS_TUBESIZE]=5;
			weaponstatus[HUNTS_CHOKE]=0;
		}
		weaponstatus[HUNTS_TUBE]=weaponstatus[HUNTS_TUBESIZE];
		weaponstatus[SHOTS_SIDESADDLE]=0;//no shells because there are no side saddles to put them in
		handshells=0;
	}
}

class HDCombatShotgunRandom:IdleDummy{
	states{
	spawn:
		TNT1 A 0 nodelay{
			let ggg=HDCombatShotgun(spawn("HDCombatShotgun",pos,ALLOW_REPLACE));
			if(!ggg)return;
			HDF.TransferSpecials(self,ggg,HDF.TS_ALL);

				ggg.weaponstatus[0]|=HUNTF_EXPORT;//no semi-auto, 5-shell tube
				ggg.weaponstatus[0]&=~HUNTF_CANFULLAUTO;
			
			int tubesize=((ggg.weaponstatus[0]&HUNTF_EXPORT)?5:5);
			if(ggg.weaponstatus[HUNTS_TUBE]>tubesize)ggg.weaponstatus[HUNTS_TUBE]=tubesize;
			ggg.weaponstatus[HUNTS_TUBESIZE]=tubesize;
		}stop;
	}
}

