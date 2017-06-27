#pragma TextEncoding = "MacRoman"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function LoadTIFFs()
	// in a loop, load images
	// do subtraction 1 and 2
	Wave m0
	Wave m1 = ProcessTiff(m0)
	Wave m2 = FindEV(m1)
End

///	@param	m0	matrix, image
Function/WAVE ProcessTiff(m0)
	Wave m0
	
	Variable xSize = dimsize(m0,0)
	Variable ySize = dimsize(m0,1)
	Variable totalSize
	
	Make/O/N=(xSize,ySize) matX,matY
	// Find locations of segmented pixels
	matX[][] = (m0[p][q] == 1) ? p : NaN
	matY[][] = (m0[p][q] == 1) ? q : NaN
	// make 1D
	Redimension/N=(totalSize) matX,matY
	WaveTransform zapnans matX
	WaveTransform zapnans matY
	// overwrite wave
	String mName = NameOfWave(m0)
	KillWaves/Z m0	// I think this needs doing because of precision
	Concatenate/KILL {matX,matY}, $mName
	Wave m1 = $mName
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
//	String wName0 = NameOfWave(w0) + "_r"
//	String wName1 = NameOfWave(w1) + "_r"
//	MatrixOp/O $wName0 = col(M_R,0)
//	MatrixOp/O $wName1 = col(M_R,1)
	String mName = NameOfWave(m0) + "_r"
	Duplicate/O M_R, $mName
	Wave m2 = $mName
	Return m2
End