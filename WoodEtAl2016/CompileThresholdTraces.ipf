#pragma TextEncoding = "MacRoman"		// For details execute DisplayHelpTopic "The TextEncoding Pragma"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#include <Waves Average>

// Colours are taken from Paul Tol SRON stylesheet
// Define colours
StrConstant SRON_1 = "0x4477aa;"
StrConstant SRON_2 = "0x4477aa; 0xcc6677;"
StrConstant SRON_3 = "0x4477aa; 0xddcc77; 0xcc6677;"
StrConstant SRON_4 = "0x4477aa; 0x117733; 0xddcc77; 0xcc6677;"
StrConstant SRON_5 = "0x332288; 0x88ccee; 0x117733; 0xddcc77; 0xcc6677;"
StrConstant SRON_6 = "0x332288; 0x88ccee; 0x117733; 0xddcc77; 0xcc6677; 0xaa4499;"
StrConstant SRON_7 = "0x332288; 0x88ccee; 0x44aa99; 0x117733; 0xddcc77; 0xcc6677; 0xaa4499;"
StrConstant SRON_8 = "0x332288; 0x88ccee; 0x44aa99; 0x117733; 0x999933; 0xddcc77; 0xcc6677; 0xaa4499;"
StrConstant SRON_9 = "0x332288; 0x88ccee; 0x44aa99; 0x117733; 0x999933; 0xddcc77; 0xcc6677; 0x882255; 0xaa4499;"
StrConstant SRON_10 = "0x332288; 0x88ccee; 0x44aa99; 0x117733; 0x999933; 0xddcc77; 0x661100; 0xcc6677; 0x882255; 0xaa4499;"
StrConstant SRON_11 = "0x332288; 0x6699cc; 0x88ccee; 0x44aa99; 0x117733; 0x999933; 0xddcc77; 0x661100; 0xcc6677; 0x882255; 0xaa4499;"
StrConstant SRON_12 = "0x332288; 0x6699cc; 0x88ccee; 0x44aa99; 0x117733; 0x999933; 0xddcc77; 0x661100; 0xcc6677; 0xaa4466; 0x882255; 0xaa4499;"

//// @param hex		variable in hexadecimal
Function hexcolor_red(hex)
	Variable hex
	return byte_value(hex, 2) * 2^8
End

//// @param hex		variable in hexadecimal
Function hexcolor_green(hex)
	Variable hex
	return byte_value(hex, 1) * 2^8
End

//// @param hex		variable in hexadecimal
Function hexcolor_blue(hex)
	Variable hex
	return byte_value(hex, 0) * 2^8
End

//// @param data	variable in hexadecimal
//// @param byte	variable to determine R, G or B value
Static Function byte_value(data, byte)
	Variable data
	Variable byte
	return (data & (0xFF * (2^(8*byte)))) / (2^(8*byte))
End

// Loads the data and performs analysis
//// @param	sel	option of 0 = reapply offsets, or 1 = do offsetting from scratch
Function LoadAndGo(sel)
	Variable sel
	
	LoadFromExcel()
	
	if(sel == 1)
		DoOffset()
	elseif(sel == 0)
		OffsetAgain()
	else
		return 0
	endif
	
	Wave/T PossWave
	Variable cond = numpnts(PossWave)
	NormWaves()
	
	// Pick colours from SRON palettes
	String pal
	if(cond == 1)
		pal = SRON_1
	elseif(cond == 2)
		pal = SRON_2
	elseif(cond == 3)
		pal = SRON_3
	elseif(cond == 4)
		pal = SRON_4
	elseif(cond == 5)
		pal = SRON_5
	elseif(cond == 6)
		pal = SRON_6
	elseif(cond == 7)
		pal = SRON_7
	elseif(cond == 8)
		pal = SRON_8
	elseif(cond == 9)
		pal = SRON_9
	elseif(cond == 10)
		pal = SRON_10
	elseif(cond == 11)
		pal = SRON_11
	else
		pal = SRON_12
	endif

	Make/O/N=(cond,3) colorWave
	
	String pref, expr, readcond, cell, plotName, wName, wList, avName, errName
	Variable color, nWaves
	Variable/G gR,gG,gB
	Variable i,j,k
	
	for(i = 0; i < cond; i += 1)
		// specify colours
		if(cond < 13)
			color = str2num(StringFromList(i,pal))
			gR = hexcolor_red(color)
			gG = hexcolor_green(color)
			gB = hexcolor_blue(color)
		else
			color = str2num(StringFromList(round((i)/12),pal))
			gR = hexcolor_red(color)
			gG = hexcolor_green(color)
			gB = hexcolor_blue(color)
		endif
		colorwave[i][0] = gR
		colorwave[i][1] = gG
		colorwave[i][2] = gB
	endfor
	
	wList = WaveList("*g_n", ";", "")
	nWaves = ItemsInList(wList)
	for(i = 0; i < nWaves; i += 1)
		wName = StringFromList(i,wList)
		plotName = "raw" + wName
		Display/N=$plotName $wName
		ModifyGraph/W=$plotName rgb($wName)=(32767,32767,32767)
		wName = ReplaceString("g_n",wName,"p_n")
		AppendToGraph/W=$plotName /R $wName
		expr = "([[:alpha:]]+)([[:digit:]]+)\\wp\\wn"
		SplitString/E=(expr) wName, readcond, cell
		FindValue/TEXT=readcond PossWave
		j = V_value
		ModifyGraph/W=$plotName rgb($wName)=(colorwave[j][0],colorwave[j][1],colorwave[j][2])
		ModifyGraph/W=$plotName noLabel(left)=2,noLabel(right)=2
		ModifyGraph/W=$plotName margin(left)=14,margin(right)=14
	endfor
	
	String sList = "g_n;p_n;p_a;p_t;"
	
	for(i = 0; i < cond; i += 1)
		pref = PossWave[i]
		for(j = 0; j < itemsinList(sList); j += 1)
			wList = WaveList(pref +"*" + StringFromList(j,sList), ";", "")
			nWaves = ItemsInList(wList)
			plotName = StringFromList(j,sList) + pref
			DoWindow/K $plotName
			Display/N=$plotName
			for(k = 0; k < nWaves; k += 1)
				wName = StringFromList(k,wList)
				AppendToGraph/W=$plotName $wName
			endfor
			ModifyGraph/W=$plotName rgb=(colorwave[i][0],colorwave[i][1],colorwave[i][2])
			// do averages
			avName = "W_Ave_" + StringFromList(j,sList) + "_" + pref
			errName = ReplaceString("Ave", avname, "Err")
			fWaveAverage(wList, "", 3, 1, AvName, ErrName)
			AppendToGraph/W=$plotName $avname
			DoWindow/F $plotName
			ErrorBars $avname Y,wave=($ErrName,$ErrName)
			ModifyGraph rgb($avName)=(0,0,0)
		endfor
	endfor
	
	for(i = 0; i < itemsinList(sList); i += 1)
		plotName = "Sum_" + StringFromList(i,sList) + "plot"
		DoWindow/K $plotName
		Display/N=$plotName
		wList = WaveList("W_Ave_" + StringFromList(i,sList) + "*",";","")
		nWaves = ItemsInList(wList)
		for(j = 0; j < nWaves; j += 1)
			avName = StringFromList(j,wList)
			AppendToGraph/W=$plotName $avName
//			errName = ReplaceString("Ave", avname, "Err")
//			ErrorBars $avname Y,wave=($ErrName,$ErrName)
			for(k = 0; k < cond; k += 1)
				pref = PossWave[k]
				if(StringMatch(avName, "*" + pref ) == 1)
					ModifyGraph/W=$plotName rgb($avName)=(colorwave[k][0],colorwave[k][1],colorwave[k][2])
				endif
			endfor
		endfor
		DoWindow/F $plotName
		SetAxis/A=2 left
		SetAxis bottom -200,500
	endfor

	Execute "TileWindows/O=1"
End
	
// This function will load the threshold data from an Excel Workbook
Function LoadFromExcel()
	
	String sheet, wList
	Variable nGWaves,nPWaves,nAWaves
	Variable i
	
	XLLoadWave/J=1
	Variable moviemax = ItemsInList(S_value)
	NewPath/O/Q path1, S_path
	
	Make/T/O/N=(moviemax) PossWave
	Wave/T PossWave
	
	for(i = 0; i < moviemax; i += 1)
		sheet = StringFromList(i,S_Value)
		XLLoadWave/S=sheet/R=(A1,CC1000)/O/K=3/W=1/P=path1 S_fileName
		PossWave[i] = sheet
		wList = WaveList(sheet + "*_G",";","")
		nGWaves = ItemsInList(wList)
		wList = WaveList(sheet + "*_P",";","")
		nPWaves = ItemsInList(wList)
		wList = WaveList(sheet + "*_A",";","")
		nAWaves = ItemsInList(wList)
		Print "Loaded ", sheet, "I've stored", nGWaves, "G waves.", nPWaves, "P waves.", nAWaves, "A waves"
		if((nGWaves*3)!=(nGWaves+nPWaves+nAwaves))
			Print "Check waves!" // indicates problem
		endif
	endfor
End

// This is for marquee control
Function UserCursorAdjust_ContButtonProc(ctrlName) : ButtonControl
	String ctrlName

	DoWindow/K tmp_PauseforCursor				// Kill self
End

// This function presents each wave, user specifies min/max of fluorescence
// igor calculates half point and uses this for X_offset
Function DoOffset()
	
	String wList = wavelist("*_g",";","")
	Variable i, off
	Variable nWaves = ItemsInList(wList)
	String wName, pName, newName
	String graphName = "green"
	
	Make/O/N=(nWaves)/T textwave
	Make/O/N=(nWaves) crsrA, crsrB, offwave, Vwave
	
	for(i = 0;i < nWaves;i += 1)
		wName = StringFromList(i, wList)
		Wave w1 = $wName
		newName = ReplaceString("_g", wName, "_g_n")
		Duplicate/O w1 $newName
		Wave wgn = $newName
		
		pName = ReplaceString("_g", wName, "_p")
		Wave w2 = $pName
		newName = ReplaceString("_g", wName, "_p_n")
		Duplicate/O w2 $newName
		Wave wpn = $newName
		
		Display /N=$graphName w1
		ShowInfo
		DoWindow $graphName
		if (V_Flag == 0) // Verify that graph exists
			Abort "UserCursorAdjust: No such graph."
			return -1
		endif
		NewPanel/K=2 /W=(187,368,437,531) as "Pause for Cursor"
		DoWindow/C tmp_PauseforCursor					// Set to an unlikely name
		AutoPositionWindow/E/M=1/R=$graphName			// Put panel near the graph

		DrawText 21,20,"Adjust the cursors and then"
		DrawText 21,40,"Click Continue."
		Button button0,pos={80,58},size={92,20},title="Continue"
		Button button0,proc=UserCursorAdjust_ContButtonProc
		PauseForUser tmp_PauseforCursor,$graphName
		if (strlen(CsrWave(A))>0 && strlen(CsrWave(B))>0)	// Cursors are on trace?
			off=(w1[pcsr(A)]-((w1[pcsr(A)]-w1[pcsr(B)])/2))
		endif
		textwave[i] = wname
		crsrA[i] = pcsr(A)
		crsrB[i] = pcsr(B)
		FindLevel /q w1, off
		offwave[i] = off
		Vwave[i] = V_levelX
		SetScale/P x -(V_levelX*5),5,"", wgn
		SetScale/P x -(V_levelX*5),5,"", wpn
		DoWindow/K $graphName
	endfor
End


Function OffsetAgain()
	//use this to redo the analysis but without going through DoOffset()
	String wList=wavelist("*_g",";","")
	
	Variable i, off, var
	Variable nWaves = ItemsInList(wList)
	String wName, pName, nName, newName
	
	WAVE/T textwave
	WAVE crsrA,crsrB,Vwave
	
	for(i = 0;i < nWaves;i +=1)
		wName = StringFromList(i, wList)
		Wave w1 = $wName
		newName = ReplaceString("_g", wName, "_g_n")
		Duplicate/O w1 $newName
		Wave wgn = $newName
		
		pName = ReplaceString("_g", wName, "_p")
		Wave w2 = $pName
		newName = ReplaceString("_g", wName, "_p_n")
		Duplicate/O w2 $newName
		Wave wpn = $newName
		
		FindValue/TEXT=wname Textwave
		var=V_Value
		SetScale/P x -(Vwave[var]*5),5,"", wgn
		SetScale/P x -(Vwave[var]*5),5,"", wpn
//		off=(w1[crsrA[var]]-((w1[crsrA[var]]-w1[crsrB[var]])/3))
//		FindLevel /q w1, off
//		SetScale/P x -(V_levelX*5),5,"", wgn
//		SetScale/P x -(V_levelX*5),5,"", wpn
	endfor
End

// Normalise waves. Takes g_n and p_n waves (normalised for time)
// creates g_n which is scaled 1->0
// creates p_a which is p_n normalised to cell size
// creates p_t which is baseline subtracted
// g waves are green fluorescence waves i.e. cytoplasmic ROI
// p waves are puncta waves i.e. thresholded output
Function NormWaves()
	String wList = WaveList("*_g_n", ";", "")
	String wName, newName
	Variable wmin, wmax, var
	Variable i
	
	for(i = 0; i < ItemsInList(wList); i += 1)
		wName = StringFromList(i,wList)
		Wave w1 = $wName
		wmin=wavemin(w1)
		w1 -=wmin
		if(x2pnt(w1, -200) < 0)
			wmax = wavemax(w1)
		else
			wmax = w1(-200)
		endif
		w1 /= wmax
		// now do p_n norm
		newName = ReplaceString("_g_n",wName,"_p_n")
		Wave w1 = $newName
		wName = ReplaceString("_p_n",newName,"_p_a")
		Duplicate /O w1 $wName
		Wave w1 = $wName
		wName = ReplaceString("_p_a",wName,"_A")
		Wave w2 = $wName
		w1 /= w2[0]
		// and the other one
		newName = ReplaceString("_A",wName,"_p_n")
		Wave w1 = $newName
		wName = ReplaceString("_p_n",newName,"_p_t")
		Duplicate /O w1 $wName
		Wave w1 = $wName
		w1 /= w2[0]
		wmin = mean(w1,-60,-40)
		w1 -= wmin
		//n ormalise p_n to give 0->1
//		wName = ReplaceString("_p_n",newName,"_p_t")
//		Duplicate /O w1 $wName
//		Wave w1 = $wName
//		wmin = mean(w1,-30,-20)
//		w1 -= wmin
//		wmax = mean(w1,165,180)
//		w1 /= wmax
	endfor
End

// Utility to kill all graphs
Function KillAllGraphs()

	String fullList = WinList("*", ";","WIN:1")
	String name, cmd
	Variable i
 
	for(i=0; i<itemsinlist(fullList); i +=1)
		name = stringfromlist(i, fullList)
		Dowindow/K $name		
	endfor
end

// simplifies busy experiments
// example: ShowMe("img*") //looks at heatmaps only
// ShowMe("map*") //looks at maps only
// ShowMe("*") //resets to see show all windows
// ShowMe("*GFP*") //shows all GFP windows
////	@param	key		string to specify windows to show
Function ShowMe(key)
	String key
	
	String fulllist = WinList("*", ";","WIN:1")
	String name
	variable i
 
	for(i = 0; i < itemsinlist(fulllist); i += 1)
		name = stringfromlist(i, fulllist)
		if(StringMatch(name, key ) == 1)
			DoWindow/HIDE=0 $name //show window
		else
			DoWindow/HIDE=1 $name //hide window
		endif
	endfor
	Execute "TileWindows/O=1/C"
End

Function SpotMax()

	Wave /T posswave
	Variable cond = numpnts(posswave)
	
	String pref, wList, wName, newName
	Variable nWaves
	Variable i, j
	
	for (i = 0; i < cond; i += 1)
		pref = posswave[i]
		wList = WaveList(pref + "*_p_t", ";", "")
		nWaves = ItemsInList(wList)
		newName = "spots_" + pref
		Make/O/N=(nWaves) $newName
		Wave w0 = $newName
		for(j = 0; j < nWaves; j += 1)
			wName = StringFromList(j,wList)
			Wave w1 = $wName
			w0[j] = mean(w1,300,350)
		endfor
	endfor
End