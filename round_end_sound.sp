#pragma newdecls required
#pragma semicolon 1

#include sdktools
#include cstrike
#include clientprefs

ArrayList hSounds;
Cookie hCookie[2];

bool bSound[MAXPLAYERS + 1];
float fVolume[MAXPLAYERS + 1];

public void OnPluginStart()
{
	hSounds = new ArrayList(512);
	hCookie[0] = new Cookie("Round End Sound", "", CookieAccess_Private);
	hCookie[1] = new Cookie("Volume Sound", "", CookieAccess_Private);

	RegConsoleCmd("sm_res", OnRes);
}

public void OnMapStart()
{
	hSounds.Clear();
	
	File hFile = OpenFile("addons/sourcemod/configs/res.ini", "rt"); 	
	if(hFile)
	{
		char path[PLATFORM_MAX_PATH], file[PLATFORM_MAX_PATH];
		while(!hFile.EndOfFile() && hFile.ReadLine(path, sizeof(path)))
		{
			TrimString(path);
			if(IsCharAlpha(path[0]))
			{
				hSounds.PushString(path);
				PrecacheSound(path, true);
				
				FormatEx(file, sizeof(file), "sound/%s", path);
				AddFileToDownloadsTable(file);
			}
		}
	}
	hFile.Close();
}	

public void OnClientCookiesCached(int client)
{
	if(!IsFakeClient(client))
		loadCookies(client);
}

public void OnClientPutInServer(int client)
{
	if(!IsFakeClient(client) && AreClientCookiesCached(client))
		loadCookies(client);
}

public Action OnRes(int client, int args)
{
	Menu hMenu = new Menu(Sound_Handler);
	hMenu.SetTitle("Round End Sound\n \n");
	char buffer[64];
	FormatEx(buffer, sizeof(buffer), "Музыка в конце раунда[%s]", bSound[client] ? "Вкл" : "Выкл");
	hMenu.AddItem("on", buffer);
	if(bSound[client])
	{		
		hMenu.AddItem("volume", "Громкость музыки");
	}
	hMenu.ExitButton = true;
	hMenu.Display(client, 0);
	return Plugin_Handled;
}	

public int Sound_Handler(Menu menu, MenuAction action, int client, int item)
{
	switch(action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_Select:
		{
			char sInfo[16];
			menu.GetItem(item, sInfo, sizeof(sInfo));
			
			if(!strcmp(sInfo, "on"))
			{
				bSound[client] = !bSound[client] ? true : false;
				
				char buffer[5];
				IntToString(view_as<int>(bSound[client]), buffer, sizeof(buffer));
				hCookie[0].Set(client, buffer);
				OnRes(client, 0);
			}

			else if(!strcmp(sInfo, "volume"))
			{
				VolumeMenu(client);
			}
		}
	}
}

void VolumeMenu(int client)
{
	Menu hMenu = new Menu(Volume_Handler);
	hMenu.SetTitle("Выберите громкость\n Текущая громкость: %d %\n\n", RoundFloat(fVolume[client] * 100));
	hMenu.AddItem("0.1", "10%");
	hMenu.AddItem("0.2", "20%");
	hMenu.AddItem("0.3", "30%");
	hMenu.AddItem("0.4", "40%");
	hMenu.AddItem("0.5", "50%");
	hMenu.AddItem("0.6", "60%");
	hMenu.AddItem("0.7", "70%");
	hMenu.AddItem("0.8", "80%");
	hMenu.AddItem("0.9", "90%");
	hMenu.AddItem("1.0", "100%");
	hMenu.ExitBackButton = true;
	hMenu.ExitButton = true;
	hMenu.Display(client, 0);
}

public int Volume_Handler(Menu menu, MenuAction action, int client, int item)
{
	switch(action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_Select:
		{
			char sInfo[16];
			menu.GetItem(item, sInfo, sizeof(sInfo));
			fVolume[client] = StringToFloat(sInfo);
			PrintToChat(client, "\x04[RES] \x01Установлено новое значение громкости: \x04%d %", RoundFloat(fVolume[client] * 100));
			hCookie[1].Set(client, sInfo);
			VolumeMenu(client);
		}
		case MenuAction_Cancel:
		{
			if(item == MenuCancel_ExitBack)
			{
				OnRes(client, 0);
			}
		}	
	}
}	

public Action CS_OnTerminateRound(float &delay, CSRoundEndReason &reason)
{
	char sound[PLATFORM_MAX_PATH];
	hSounds.GetString(GetRandomInt(0, hSounds.Length - 1), sound, sizeof(sound));

	switch(reason)
	{
		case CSRoundEnd_CTWin, CSRoundEnd_TerroristWin, CSRoundEnd_Draw:
		{
			for(int i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i) && bSound[i])
				{
					StopSound(i, SNDCHAN_STATIC, "radio/ctwin.wav");
					StopSound(i, SNDCHAN_STATIC, "radio/terwin.wav");
					StopSound(i, SNDCHAN_STATIC, "radio/rounddraw.wav");
					EmitSoundToClient(i, sound, _, _, _, _, fVolume[i]);
				}
			}
		}
	}
	return Plugin_Continue;
}	

public void OnClientDisconnect(int client)
{
	bSound[client] = false;
	fVolume[client] = 0.0;
}	

void loadCookies(int client)
{
	char buffer[2][5];
	hCookie[0].Get(client, buffer[0], sizeof(buffer[]));
	bSound[client] = buffer[0][0] ? view_as<bool>(StringToInt(buffer[0])) : true;
	
	hCookie[1].Get(client, buffer[1], sizeof(buffer[]));
	fVolume[client] = buffer[1][0] ? StringToFloat(buffer[1]) : 1.0;
}	