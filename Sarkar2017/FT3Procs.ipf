#pragma TextEncoding = "MacRoman"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Menu "Macros"
	"Mitotic Timing",  MitoticTiming()
End

Function StackEmUp(wList)
	String wList
	
//	StackEmUp(wavelist("si*",";",""))

	Wave/T catWave
	
	Variable nCat = numpnts(catWave)
	Variable nCond = ItemsInList(wList)
	String wName, condName, legendString=""
	Make/O/T/N=(nCond) condWave
	Make/O/N=(4,3) colorWave = {{188,254,253,230},{189,230,174,85},{220,206,107,13}}
	colorWave *=257

	
	DoWindow/K stackPlot
	Display/N=stackPlot
	
	Variable i,j
	
	for (i = 0; i < nCat; i += 1)
		wName = "cat" + num2str(i)
		Make/O/N=(nCond) $wName
		Wave w0 = $wName
		legendString += "\\s(" + wName + ") " + catWave[i]
		if (i < nCat - 1)
			legendString += "\r"	// add carriage return unless it's the last one
		endif
		for (j = 0; j < nCond; j += 1)
			condName = StringFromList(j,wList)
			if (i == 0)
				condWave[j] = condName
			endif
			Wave w1 = $condName
			w0[j] = w1[i]
		endfor
		AppendToGraph/W=stackPlot w0 vs condWave
		ModifyGraph/W=stackPlot rgb($wName)=(colorWave[i][0],colorWave[i][1],colorWave[i][2])
	endfor
	ModifyGraph/W=stackPlot toMode=3
	Label/W=stackPlot left "Proportion (%)"
	Legend/W=stackPlot/C/N=text0/J/B=1/E=2/F=0/X=0.50/Y=0.50 legendString
	ModifyGraph/W=stackPlot margin(right)=113
	ModifyGraph/W=stackPlot hbFill=2
	DoFT3Stats()
	MakeLayoutForStackPlot()
End

Function MakeLayoutForStackPlot()
	ModifyGraph/W=stackPlot swapXY=1
	ModifyGraph/W=stackPlot margin(left)=56,margin(right)=113
	ModifyGraph/W=stackPlot margin(bottom)=34,margin(top)=8
	SetAxis/W=stackPlot/A/R left
	NewLayout/N=stackLayout
	LayoutPageAction size(-1)=(595, 842), margins(-1)=(18, 18, 18, 18)
	AppendLayoutObject/W=stackLayout graph stackPlot
	ModifyLayout units=0
	ModifyLayout frame=0,trans=1
	ModifyLayout/W=stackLayout left(stackPlot)=21,top(stackPlot)=21,width(stackPlot)=292,height(stackPlot)=90
	SavePICT/E=-2 as "stackLayout.pdf"
End

Function DoFT3Stats()
	WAVE/Z cat0	// normal %
	WAVE/Z/T condWave
	Variable nCond = numpnts(cat0)
	Make/O/D/N=(nCond,nCond) resultMat
	Make/O/N=(nCond) labelPos=p
	Variable i, j
	
	for(i = 0; i < nCond; i += 1)
		for(j = 0; j < nCond; j += 1)
			if(i == j)
				resultMat[i][j] = 1
			else
				Make/O/N=(2) data0,data1
				data0[0] = cat0[i]
				data0[1] = 100 - data0[0]
				data1[0] = cat0[j]
				data1[1] = 100 - data1[0]
				StatsChiTest/S/T=1 data1,data0 // in this case data0 is expected
				WAVE/Z W_StatsChiTest
				if (W_StatsChiTest[4] == 0)
					resultMat[i][j] = 1e-23
				else
					resultMat[i][j] = W_StatsChiTest[4]
				endif
				KillWaves data0,data1
			endif
		endfor
	endfor
	KillWindow/Z result
	NewImage/N=result resultMat
	// Each column gives values for each row versus expected
	// i.e. look at 1st column
	ModifyImage/W=result resultMat ctab= {1e-24,0.5,Rainbow,0},minRGB=(52428,52428,52428),maxRGB=(52428,52428,52428)
	ModifyGraph/W=result userticks(left)={labelpos,condWave}
	ModifyGraph/W=result userticks(top)={labelpos,condWave}
	ModifyGraph/W=result tick=3,tkLblRot(left)=0,tkLblRot(top)=90,tlOffset=0
	ModifyGraph/W=result margin(left)=42,margin(top)=42
	ModifyImage/W=result resultMat log=1
	String textName,labelValStr
	Duplicate/O resultMat,labelVal
	Variable matsize = numpnts(resultMat)
	Redimension/N=(matsize) labelVal
	DoWindow/F result
	for(i = 0; i < matsize; i += 1)
		if(labelVal[i] != 1)
			textName = "text" + num2str(i)
			labelValStr = num2str(Rounder(labelVal[i],2))
			Tag/C/N=$textName/F=0/B=1/X=0.00/Y=0.00/L=0 resultMat, i, labelValStr
		endif
	endfor
	ModifyGraph width={Plan,1,top,left}
End

///	@param	value				this is the input value that requires rounding
///	@param	numSigDigits		number of significant digits for the rounding procedure
Function Rounder(value, numSigDigits)
	Variable value, numSigDigits
 
	String str
	Sprintf str, "%.*g\r", numSigDigits, value
	return str2num(str)
End

Function MitoticTiming()
	LoadDataFromExcel()
		DoWindow/K summaryLayout
		NewLayout/N=summaryLayout
	FilterQuality()
		DoWindow /F summaryLayout
		LayoutPageAction size(-1)=(595, 842), margins(-1)=(18, 18, 18, 18)
		ModifyLayout units=0
		ModifyLayout frame=0,trans=1
		Execute /Q "Tile/A=(6,3)/W=(18,31,577,826)/O=1" // shift graphs down
		TextBox/C/N=text0/F=0/A=LT/X=0/Y=0 "Prometaphase-Metaphase"
		TextBox/C/N=text1/F=0/A=LT/X=34/Y=0 "Metaphase-Anaphase"
		TextBox/C/N=text2/F=0/A=LT/X=67/Y=0 "Anaphase-Telophase"
		SavePICT/E=-2 as "summaryLayout.pdf"
		//
		DoWindow/K allLayout
		NewLayout/N=allLayout
	MakeMainFigurePlots()
		DoWindow /F allLayout
		LayoutPageAction size(-1)=(595, 842), margins(-1)=(18, 18, 18, 18)
		ModifyLayout units=0
		ModifyLayout frame=0,trans=1
		Execute /Q "Tile/A=(6,3)/W=(18,31,577,826)/O=1" // Make same size as summaryLayout
		TextBox/C/N=text0/F=0/A=LT/X=0/Y=0 "Prometaphase-Metaphase"
		TextBox/C/N=text1/F=0/A=LT/X=34/Y=0 "Metaphase-Anaphase"
		Legend/C/N=text2/F=0/A=RT/X=5.00/Y=5.00
		SavePICT/E=-2 as "allLayout.pdf"
End

Function LoadDataFromExcel()
	// each experimental condition needs to be a separate sheet
	// labelling of waves needs to correspond
	String sheet,wList,wName
	Variable i,j,k
	
	XLLoadWave/J=1
	if(V_Flag)
      			Abort "The user pressed Cancel"
	endif
	Variable nSheets = ItemsInList(S_value)
	NewPath/O/Q path1, S_path
	String colList = "PM_M;M_A;A_T;Q;"
	Make/O/T/N=(nSheets) condWave
	Variable nExp,nCell,Length
	String newName
	
	for(i = 0; i < nSheets; i += 1)
		sheet = StringFromList(i,S_Value)
		condWave[i] = sheet
		// this is for 5 expts with 4 columns = 20 = T Don't have more than 200 rows
		XLLoadWave/S=sheet/R=(A3,T200)/D/W=3/O/K=0/P=path1 S_fileName
		// now check lengths. Any NaNs at end of wave will be truncated. Concatenate will fail
		wList = wavelist(sheet + "*_Q",";","")
		nExp = ItemsInList(wList)
		for(j = 0; j < nExp; j += 1)
			wName = StringFromList(j,wList)
			Wave w0 = $wName
			nCell = numpnts(w0) // all 4 waves for the exp should be this long
			for(k = 0; k < 3; k += 1) // loop through other three to test length
				newName = ReplaceString("_Q",wName,"_" + StringFromList(k,colList))
				Wave w1 = $newName
				length = numpnts(w1)
				if (length < nCell)
					InsertPoints length, (nCell - length), w1 // add NaNs if necessary
				endif
			endfor
		endfor		
		
		for(j = 0; j < 4; j += 1)
			wList = wavelist(sheet + "*" + StringFromList(j,colList),";","")
			wName = "temp" + num2str(j)
			Concatenate/O/NP=0/KILL wList, $wName
		endfor
		// make matrix
		wList = wavelist("temp*",";","")	
		Concatenate/O/NP=1/KILL wlist, $sheet
	endfor
	// Print "***\r The sheet", sheet, "was loaded from", S_path,"\r  ***"
End

Function FilterQuality()
	WAVE/T/Z condWave
	if(!waveExists(condWave))
		Abort "There is no condWave"
		return -1
	endif
	
	String mName
	Variable nCond = numpnts(condWave)
	
	Variable i
	
	for(i = 0; i < nCond; i += 1)
		mName = condWave[i]
		Wave m0 = $mName
		mName += "_0"
		Duplicate/O m0, $mName
		Wave m1 = $mName
		mName = ReplaceString("_0",mName,"_1")
		Duplicate/O m0, $mName
		Wave m2 = $mName
		m1 = (m0[p][3] == 0) ? m1[p][q] : NaN
		m2 = (m0[p][3] == 1) ? m2[p][q] : NaN
		MakeHistos(m0)
	endfor
	
End


Function MakeHistos(mWave)
	Wave mWave
	
	String wName = NameofWave(mWave) // call this wName not mName
	String mName
	String mList = wavelist(wName + "*",";","")
	// NOTE: gives an error if nth sheet name starts with same name as earlier sheet
	// we want to plot cond, cond_0, cond_1
	// for PM_M,M_A,A_T
	String colList = "PM_M;M_A;A_T;Q;"
	String plotName
	String histName
	Variable denominator,hSize
	Make/O/N=3 hSizeWave={100,50,40}
	Make/O/FREE/N=(3,3) colorWave = {{128,188,253},{128,189,174},{128,220,107}}
	colorWave *=257
	
	Variable i,j
	
	for (i = 0; i < 3; i += 1)
		plotName = wName + "_" + StringFromList(i,colList) + "_" + "Plot"
		DoWindow/K $plotName
		Display/N=$plotName
		TextBox/C/N=text0/F=0/A=RB/X=0.00/Y=0.00 wName
		hSize = hSizeWave[i]
		for (j = 0; j < 3; j += 1)
			mName = StringFromList(j,mList)
			Wave m0 = $mName
			histName = mName + "_" + StringFromList(i,colList) + "_hist"
			MatrixOp/O/FREE mCol = col(m0,i)
			Make/N=(hSize)/O $histName
			Histogram/CUM/B={0,2,hSize} mCol,$histName
			AppendToGraph/W=$plotName $histName
			ModifyGraph/W=$plotName rgb($histName)=(colorWave[j][0],colorWave[j][1],colorWave[j][2])
			// get denominator for normalisation
			// this is the total number of cells (0 or 1) in Q wave
			// or the number of 0s or 1s in the case of _0 or _1 waves
			MatrixOp/O/FREE mCol = col(m0,3)
			WaveStats/Q mCol
			Denominator = V_npnts
			Wave w0 = $histName
			w0 /= denominator
		endfor
		Label left "Cumulative probability"
		SetAxis left 0,1
		Label bottom "Time (min)"
		SetAxis/A/N=1/E=1 bottom
		AppendLayoutObject/W=summaryLayout graph $plotName
	endfor
End

Function MakeMainFigurePlots()
	MakeFT3ColorWave()
	WAVE/Z FT3ColorWave,RootNames,RootCatWave
	
	DoWindow/K AllPMM
	Display/N=AllPMM
	String wList = WaveList("*_PM_M_hist",";","")
	String wName, prefix
	Variable nWaves = ItemsInList(wList)
	Variable i,j
	
	for(i = 0; i < nWaves; i += 1)
		wName = StringFromList(i,wList)
		prefix = ReplaceString("_PM_M_hist",wName,"") // not robust
		FindValue/TEXT=prefix RootNames
			if (V_Value != -1)
				j = RootCatWave[V_Value]
				AppendToGraph/W=AllPMM $wName
				ModifyGraph/W=AllPMM rgb($wName)=(FT3ColorWave[j][0],FT3ColorWave[j][1],FT3ColorWave[j][2])
			endif
	endfor
	
	DoWindow/K AllMA
	Display/N=AllMA
	wList = WaveList("*_M_A_hist",";","")
	nWaves = ItemsInList(wList)
	
	for(i = 0; i < nWaves; i += 1)
		wName = StringFromList(i,wList)
		prefix = ReplaceString("_M_A_hist",wName,"") // not robust
		FindValue/TEXT=prefix RootNames
			if (V_Value != -1)
				j = RootCatWave[V_Value]
				AppendToGraph/W=AllMA $wName
				ModifyGraph/W=AllMA rgb($wName)=(FT3ColorWave[j][0],FT3ColorWave[j][1],FT3ColorWave[j][2])
			endif
	endfor
	
	DoWindow/F allPMM
	Label left "Cumulative probability"
	SetAxis left 0,1
	SetAxis bottom 0,120
	Label bottom "Time (min)"
	AppendLayoutObject/W=allLayout graph allPMM
	
	DoWindow/F allMA
	Label left "Cumulative probability"
	SetAxis left 0,1
	SetAxis bottom 0,90
	Label bottom "Time (min)"
	AppendLayoutObject/W=allLayout graph allMA
End

Function MakeFT3ColorWave()
//	51,34,136
//	(136,204,238)
//	68,170,153
//	17,119,51
//	221,204,119
//	204,102,119
//	(170,68,153)
	Make/O/N=(5,3) FT3ColorWave = {{51,68,17,221,204},{34,170,119,204,102},{136,153,51,119,119}}
	FT3ColorWave *=257 // convert to 16-bit
	Make/O/T/N=(16) RootNames = {"GFP","FT3GFP549","FT3GFP649","siGL2","siFT3","CD8ctrl","CD8TACC3","FGFR3TACC3","siGL2","siFT3","siFGFR3","siTACC3","GFP","TACC3","PD0nM","PD500nM"}
	Make/O/N=(16) RootCatWave = {0,1,2,0,1,0,1,2,0,1,3,4,0,1,0,1}
End
