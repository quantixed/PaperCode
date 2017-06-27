#pragma TextEncoding = "MacRoman"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Menu "Macros"
	"CCV Rotator",  CCVRotator()
End

Function CCVRotator()
	CoastClear()
	GetPixelData()
	LoadTIFFs()
End

Function LoadTIFFs()
	// Check we have FileName wave and PixelSize
	Wave/T/Z FileName = root:FileName
	Wave/Z PixelSize = root:PixelSize
	if (!waveexists(FileName))
		Abort "Missing FileName textwave"
	endif
	if(!WaveExists(PixelSize))
		Abort "Missing PixelWave numeric wave"
	endif
	
	NewDataFolder/O/S root:data
	
	String expDiskFolderName, ParentExpDiskFolderName
	String FileList, ThisFile, Thatfile, imgName, origName
	Variable FileLoop, pxSize
	
	NewPath/O/Q/M="Please find disk folder" ExpDiskFolder
	if (V_flag!=0)
		DoAlert 0, "Disk folder error"
		Return -1
	endif
	PathInfo /S ExpDiskFolder
	ExpDiskFolderName=S_path
	FileList=IndexedFile(expDiskFolder,-1,".tif")
	Variable nFiles=ItemsInList(FileList)
	
	// last element of disk folder name is stored in snip
	String snip = ":" + ParseFilePath(0, ExpDiskFolderName, ":", 1, 0) + ":"
	ParentExpDiskFolderName = RemoveEnding(ExpDiskFolderName,snip)
	// This is now the folder above segmented images
	NewPath/O/Q ParentExpDiskFolder, ParentExpDiskFolderName
	
	for (FileLoop = 0; FileLoop < nFiles; FileLoop += 1)
		ThisFile = StringFromList(FileLoop, FileList)
		imgName = ReplaceString(".tif",ThisFile,"")
		ImageLoad/O/T=tiff/Q/P=expDiskFolder/N=$imgName ThisFile
		Wave segMat = $imgName
		pxSize = CheckScale(imgName)
		// now load original TIFF
		// name might need correcting
		if(stringmatch(imgName,"*_1") == 1 || stringmatch(imgName,"*_2") == 1)
			origName = RemoveEnding(RemoveEnding(imgName)) // delete last two characters
		else
			origName = imgName
		endif
		ThatFile = origName + ".tif"
		origName += "a"
		ImageLoad/O/T=tiff/Q/P=parentExpDiskFolder/N=$origName ThatFile
		Wave origMat = $origName
		SubImages(origMat,segMat,origName,pxSize)
		// store
		SubImages(segMat,origMat,imgName,pxSize)
		// store
		KillWaves/Z segMat,origMat
	endfor
	// Get rid of CMap waves. These are a colorscale that get loaded with 8-bit color TIFFs
	KillCMaps()
	KillWaves/Z w0,w1
	KillWaves/Z M_C,M_R,W_CumulativeVAR,W_Eigen,W_IE,W_IND,W_PSL,W_RMS,W_RSD
End

///	@param	txtName	accepts the string ThisFile
Function CheckScale(txtName)
	String txtName
	
	Wave/T/Z FileName
	Wave/Z PixelSize
	Wave/Z matA
	Variable pxSize
	
	if (!WaveExists(FileName) || !WaveExists(PixelSize))
		Abort "I need two waves: FileName and PixelSize"
	endif
	FindValue/TEXT=txtName FileName
	if (V_Value == -1)
		Print txtName, "didn't scale"
	endif
	
	pxSize = PixelSize[V_Value]
	return pxSize
End

Function SubImages(matA,matB,picName,pxSize)
	Wave matA,matB
	String picName
	Variable pxSize
	
	String mName = ReplaceString("-",picName,"_") + "_m" // do this to make legal names
	MatrixOp/O $mName = matA - matB
	Wave m0 = $mName
	Wave m1 = ProcessTiff(m0,pxSize)
	Wave m2 = FindEV(m1)
End

///	@param	m0	matrix, image
Function/WAVE ProcessTiff(m0,pxSize)
	Wave m0
	Variable pxSize
	
	Variable xSize = dimsize(m0,0)
	Variable ySize = dimsize(m0,1)
	Variable totalSize = xSize * ySize
	
	Make/O/N=(xSize,ySize) matX,matY
	// Find locations of segmented pixels
	matX[][] = (m0[p][q] > 0) ? p : NaN
	matY[][] = (m0[p][q] > 0) ? q : NaN
	// make 1D
	Redimension/N=(totalSize) matX,matY
	WaveTransform zapnans matX
	WaveTransform zapnans matY
	// overwrite wave
	String mName = NameOfWave(m0)
	KillWaves/Z m0	// I think this needs doing because of precision
	Concatenate/KILL {matX,matY}, $mName
	Wave m1 = $mName
	// scale to nm
	m1 *= pxSize
	
	Return m1
End

///	@param	m1	2D wave of xy coords
Function/WAVE FindEV(m1)
	Wave m1
	MatrixOp/O w0 = col(m1,0)
	MatrixOp/O w1 = col(m1,1)
	
	// translate to origin
	Variable offX = mean(w0)
	Variable offY = mean(w1)
	w0[] -= offX
	w1[] -= offY
	// do PCA. Rotated point are in M_R
	PCA/ALL/SEVC/SRMT/SCMT w0,w1
	WAVE M_R
	String mName = NameOfWave(m1) + "_r"
	Duplicate/O M_R, $mName
	Wave m2 = $mName
	Return m2
End

// Kill CMap wave if it has been loaded
Function KillCMaps()
	String wList = WaveList("CMap*",";","")
	Variable nWaves = ItemsInList(wList)
	String wName
	
	Variable i
	
	for(i = 0; i < nWaves; i += 1)
		wName = StringFromList(i,wList)
		KillWaves/Z $wName
	endfor
End

// Destructive function that will get rid of everything
Function CoastClear()
	SetDataFolder root:
	String fullList = WinList("*", ";","WIN:3")
	Variable allItems = ItemsInList(fullList)
	String name
	Variable i
 
	for(i = 0; i < allItems; i += 1)
		name = StringFromList(i, fullList)
		DoWindow/K $name		
	endfor
	
	// Look for data folders
	DFREF dfr = GetDataFolderDFR()
	allItems = CountObjectsDFR(dfr, 4)
	for(i = 0; i < allItems; i += 1)
		name = GetIndexedObjNameDFR(dfr, 4, i)
		KillDataFolder $name		
	endfor
	
	KillWaves/A/Z
	KillStrings/A/Z
	KillVariables/A/Z
End

Function GetPixelData()
	LoadWave/A/W/J/D/O/K=1/L={0,1,0,1,1}
	LoadWave/A/W/J/D/O/K=2/L={0,1,0,0,1} S_Path + S_fileName
End