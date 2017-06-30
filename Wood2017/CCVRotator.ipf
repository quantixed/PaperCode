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

// to run this you need a text wave specifying the filename of the files you are analysing
// and a numeric wave called pixelSize that has the size of the pixels in that image.
// You can put this in yourself or, if it's missing, Igor wants to load a csv with those two things
// as first two columns (in that order).
// Then point Igor to your directory of segmented images. Note that the unsegmented images need
// to be in the directory above.
// Images are segmented with pure white or pure black in approximate ellipses around vesicle and coat
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
	
	// to store data
	Make/O/N=(nFiles)/T root:labelWave
	Make/O/N=(nFiles,2) root:axes0
	Make/O/N=(nFiles,2) root:axes1
	Wave/T labelWave = root:labelWave
	Wave axes0 = root:axes0
	Wave axes1 = root:axes1
	
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
		// reset
		origName = imgName + "_a"
		ImageLoad/O/T=tiff/Q/P=parentExpDiskFolder/N=$origName ThatFile
		Wave origMat = $origName
		SubImages(origMat,segMat,origName,pxSize)
		SubImages(segMat,origMat,imgName,pxSize)
		// store data
		labelWave[fileLoop] = imgName
		WaveStats/Q/RMD=[][0] $(ReplaceString("-",imgName,"_") + "_m_r")
		axes0[fileLoop][0] = V_Max
		WaveStats/Q/RMD=[][1] $(ReplaceString("-",imgName,"_") + "_m_r")
		axes0[fileLoop][1] = V_Max
		WaveStats/Q/RMD=[][0] $(ReplaceString("-",origName,"_") + "_m_r")
		axes1[fileLoop][0] = V_Max
		WaveStats/Q/RMD=[][1] $(ReplaceString("-",origName,"_") + "_m_r")
		axes1[fileLoop][1] = V_Max
		KillWaves/Z segMat,origMat
	endfor
	// Get rid of CMap waves. These are a colorscale that get loaded with 8-bit color TIFFs
	KillCMaps()
	// Get rid of other junk
	KillWaves/Z w0,w1
	KillWaves/Z M_C,M_R,W_CumulativeVAR,W_Eigen,W_IE,W_IND,W_PSL,W_RMS,W_RSD
	PlotThemOut()
End

// This function looks up the pixelsize for the image from the FileName and PixelSize waves
///	@param	txtName	accepts the string ThisFile
Function CheckScale(txtName)
	String txtName
	
	Wave/T/Z FileName = root:FileName
	Wave/Z PixelSize = root:PixelSize
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

///	@param	matA	1st image
///	@param	matB	2nd image. Subtraction of 2nd image from 1st image.
///	@param	picName	Image name
///	@param	pxSize	the pixelsize in nm
Function SubImages(matA,matB,picName,pxSize)
	Wave matA,matB
	String picName
	Variable pxSize
	
	String mName = ReplaceString("-",picName,"_") + "_m" // do this to make legal names
	MatrixOp/O $mName = matA - matB
	Wave m0 = $mName
	Wave m1 = ProcessTiff(m0,pxSize)
	Wave m2 = FindEV(m1)
	KillWaves/Z m1
End

// Find location of segmented pixels
///	@param	m0	matrix, image
///	@param	pxSize	size of pixels in nm (1D)
Function/WAVE ProcessTiff(m0,pxSize)
	Wave m0
	Variable pxSize
	
	Variable xSize = dimsize(m0,0)
	Variable ySize = dimsize(m0,1)
	Variable totalSize = xSize * ySize
	
	Make/O/D/N=(xSize,ySize) matX,matY
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

// This function finds the eigenvectors and rotates the point set
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
	// now thread it so the segment is contiguous
	Threader(m2)
	Return m2
End

// Make the plot to show the vesicle in black and coat in purple 0.25 alpha
Function PlotThemOut()
	SetDataFolder root:data:
	String wList0 = WaveList("*_m_r",";","")
	String wList1 = WaveList("*a_m_r",";","")
	wList0 = RemoveFromList(wList1, wList0)
	String wName0,wName1
	
	KillWindow/Z ccvPlot
	Display/N=ccvPlot
	
	Variable nWaves = ItemsInList(wList0)
	
	Variable i
	
	for(i = 0; i < nWaves; i += 1)
		wName0 = StringFromList(i, wList0)
		wName1 = StringFromList(i, wList1)
		Wave w0 = $wName0
		Wave w1 = $wName1
		AppendToGraph/W=ccvPlot w0[][1] vs w0[][0]
		ModifyGraph/W=ccvPlot rgb($wName0)=(0,0,0,16384)	//0.25 alpha
		AppendToGraph/W=ccvPlot w1[][1] vs w1[][0]
		ModifyGraph/W=ccvPlot rgb($wName1)=(65535,0,65535,16384)	//0.25 alpha
	endfor
	
	SetAxis/W=ccvPlot/A/N=1/E=2 left
	SetAxis/W=ccvPlot/A/N=1/E=2 bottom
	ModifyGraph width={Plan,1,bottom,left}
End

// This sorts the ellipse pixels so that they are in the correct order
///	@param	m1	2D wave with 1st two columns as XY coords
Function Threader(m1)
	Wave m1
	
	String mName = NameOfWave(m1)
	MatrixOp/O c0 = col(m1,0)
	MatrixOp/O c1 = col(m1,1)
	Variable nRows = DimSize(m1,0)
	Make/O/FREE/N=(nRows) threadW=0
	// measure angles, store in threadW
	Variable theta
	
	Variable i
	
	for(i = 0; i < nRows; i += 1)
		theta = atan2(c1[i],c0[i])
		threadW[i] = theta
	endfor
	
	// sort x coords and ycoords based on theta
	Sort threadW, c0, c1
	// add last point equal to first to complete the shape
	InsertPoints nRows,1, c0,c1
	c0[nRows] = c0[0]
	c1[nRows] = c1[0]
	// put back together and overwrite original
	Concatenate/O/KILL {c0,c1}, $mName
End


//------------------//
// Helper Functions //
//------------------//

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

// load csv with fileName and pxelSize
Function GetPixelData()
	LoadWave/A/W/J/D/O/K=1/L={0,1,0,1,1}
	LoadWave/A/W/J/D/O/K=2/L={0,1,0,0,1} S_Path + S_fileName
End
