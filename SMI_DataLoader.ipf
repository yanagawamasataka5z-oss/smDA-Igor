#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3
#pragma version=2.0
// ModuleName - 

// =============================================================================
// SMI_DataLoader.ipf - Data Loading Module
// =============================================================================
// AAS2/AAS4CSVHMM/
// Version 2.0 - Refactored
// =============================================================================

// -----------------------------------------------------------------------------
// AAS4 + HMM
// *.csv*_hmm.csv
// -----------------------------------------------------------------------------
Function LoadAAS4_HMM(SampleName)
	String SampleName
	
	GetFileFolderInfo/D/Q
	String PathName = S_Path
	
	if(strlen(PathName) == 0)
		Print ""
		return 0
	endif
	
	return LoadAAS4_HMM_Path(PathName, SampleName)
End

Function LoadAAS4_HMM_Path(PathName, SampleName)
	String PathName, SampleName
	
	String FileName, FolderName, FileList
	Variable i, FileNum, f, s, RowSize, numCols, dstateCol
	
	NVAR scale = root:scale
	NVAR framerate = root:framerate
	NVAR Dstate = root:Dstate
	NVAR MaxSegment = root:MaxSegment
	NVAR ExCoef = root:ExCoef
	NVAR QE = root:QE
	NVAR ROIsize = root:ROIsize
	NVAR/Z IntensityMode = root:IntensityMode
	Variable intMode = NVAR_Exists(IntensityMode) ? IntensityMode : 1  // Photon number
	NVAR/Z cSuppressOutput = root:cSuppressOutput
	Variable suppressOutput = NVAR_Exists(cSuppressOutput) ? cSuppressOutput : 0
	
	NewPath/O/Q data PathName
	NewDataFolder/O/S root:$(SampleName)
	
	// csv_hmm.csv
	FileList = IndexedFile(data, -1, ".csv")
	String mainFileList = ""
	Variable nFiles = ItemsInList(FileList)
	String fname
	for(i = 0; i < nFiles; i += 1)
		fname = StringFromList(i, FileList)
		if(StringMatch(fname, "*_hmm.csv") == 0)
			mainFileList += fname + ";"
		endif
	endfor
	
	FileNum = ItemsInList(mainFileList)
	if(!suppressOutput)
		Print "Loading " + num2str(FileNum) + " cell(s) from: " + PathName
		Print "File list: " + mainFileList
	endif
	
	for(i = 0; i < FileNum; i += 1)
		FileName = StringFromList(i, mainFileList)
		FolderName = SampleName + num2str(i + 1)
		
		if(!suppressOutput)
			Printf "=== Processing file %d: %s -> Folder: %s ===\r", i+1, FileName, FolderName
		endif
		
		NewDataFolder/O/S root:$(SampleName):$(FolderName)
		
		// CSV
		LoadWave/J/M/D/A=wave/K=0/L={0,1,0,0,0}/Q/P=data FileName
		Wave/Z wave0
		
		if(!WaveExists(wave0))
			Printf "    ERROR: wave0 not loaded for %s\r", FileName
			SetDataFolder root:$(SampleName)
			continue
		endif
		
		RowSize = DimSize(wave0, 0)
		numCols = DimSize(wave0, 1)
		Printf "    wave0 loaded: %d rows x %d cols\r", RowSize, numCols
		
		// 
		if(numCols < 11)
			Printf "    ERROR: insufficient columns (%d < 11), skipping LocPrecision\r", numCols
			SetDataFolder root:$(SampleName)
			continue
		endif
		
		Make/O/N=(RowSize) frame, displacement
		frame = 0; displacement = NaN
		Make/O/N=(RowSize) SignalN, SigmaA, Iback, BackN, VarLP, LocPrecision, Segment
		
		Printf "    LocPrecision wave created: %d points\r", numpnts(LocPrecision)
		
		// 
		SignalN = wave0[p][10] * ExCoef / QE
		SigmaA = sqrt((wave0[p][4] * wave0[p][5] + 1/12)) * scale
		Iback = wave0[p][7]
		BackN = Iback * ExCoef / QE
		VarLP = (SigmaA^2) / SignalN * (16/9 + 8*pi*(SigmaA^2)*BackN / (SignalN*(scale^2)))
		LocPrecision = sqrt(VarLP) * 1000  // nm
		SigmaA = SigmaA * 1000  // nm
		
		// Segmentation
		if(MaxSegment == 0 || numCols < 18)
			Segment = 0
		else
			Segment = wave0[p][17]
		endif
		
		// 
		for(f = 1; f < RowSize; f += 1)
			if(wave0[f][0] == wave0[f-1][0])
				frame[f] = frame[f-1] + 1
			else
				frame[f] = 0
			endif
		endfor
		
		// 
		for(f = 1; f < RowSize; f += 1)
			if(wave0[f][0] == wave0[f-1][0])
				displacement[f] = sqrt((wave0[f][2]*scale - wave0[f-1][2]*scale)^2 + (wave0[f][3]*scale - wave0[f-1][3]*scale)^2)
			else
				displacement[f] = 0
			endif
		endfor
		
		// TraceMatrix
		Make/O/N=(RowSize, 9) TraceMatrix = NaN
		TraceMatrix[][0] = wave0[p][0]             // ROI
		TraceMatrix[][1] = frame[p]                // Rframe
		TraceMatrix[][2] = wave0[p][1] - 1         // Rtime
		TraceMatrix[][3] = wave0[p][2] * scale     // X [um]
		TraceMatrix[][4] = wave0[p][3] * scale     // Y [um]
		// Intensity: IntensityModeRaw IntensityPhoton number
		if(intMode == 0)
			TraceMatrix[][5] = wave0[p][10]            // Raw Intensity [au]
		else
			TraceMatrix[][5] = wave0[p][10] * ExCoef / QE  // Photon number
		endif
		TraceMatrix[][6] = displacement[p]         // Displacement [um]
		TraceMatrix[][8] = Segment[p]              // Segment
		
		// DstateHMM
		// AAS4Dstate
		dstateCol = 11 + Dstate  // Dstate=1→12, Dstate=2→13, etc.
		if(numCols > dstateCol)
			for(f = 1; f < RowSize; f += 1)
				TraceMatrix[f][7] = wave0[f-1][dstateCol]
			endfor
			// 
			if(RowSize > 1)
				TraceMatrix[0][7] = TraceMatrix[1][7]
			endif
		else
			TraceMatrix[][7] = 0
		endif
		
		// NaN
		for(f = 0; f < RowSize; f += 1)
			if(TraceMatrix[f][1] == 0)
				TraceMatrix[f][6] = 0
				if(f + 1 < RowSize)
					TraceMatrix[f][7] = TraceMatrix[f+1][7]
				endif
			endif
		endfor
		
		Duplicate/O TraceMatrix, ROI
		ROI = TraceMatrix[p][0]
		
		KillWaves/Z wave0, frame, displacement
		
		// LocPrecision
		Wave/Z LP = LocPrecision
		Printf "    End of load: LocPrecision exists=%d, points=%d\r", WaveExists(LP), WaveExists(LP) ? numpnts(LP) : 0
		
		// HMM
		// AAS v4: xxx_data.csv → xxx_hmm.csv
		// AAS v2: xxx.csv → xxx_hmm.csv
		String hmmFileName
		if(StringMatch(FileName, "*_data.csv"))
			// v4: _data.csv  _hmm.csv 
			hmmFileName = ReplaceString("_data.csv", FileName, "_hmm.csv")
		else
			// v2: .csv  _hmm.csv 
			hmmFileName = RemoveEnding(FileName, ".csv") + "_hmm.csv"
		endif
		Printf "    Looking for HMM file: %s\r", hmmFileName
		LoadAAS4_HMMParams(hmmFileName, Dstate)
		
		SetDataFolder root:$(SampleName)
	endfor
	
	SetDataFolder root:
	Print "Loaded " + num2str(FileNum) + " cells"
	return FileNum
End

// AAS4HMM
// AAS4.ipf
static Function LoadAAS4_HMMParams(FileName, Dstate)
	String FileName
	Variable Dstate
	
	PathInfo data
	if(V_flag == 0)
		Print "  Error: Path 'data' not defined"
		return -1
	endif
	
	// 
	GetFileFolderInfo/Q/P=data/Z FileName
	if(V_Flag != 0)
		Print "  Warning: HMM file not found: " + FileName
		return -1
	endif
	
	Printf "  Loading HMM parameters from: %s (Dstate=%d)\r", FileName, Dstate
	Printf "  Current folder: %s\r", GetDataFolder(1)
	
	// Wave
	Wave/Z Ctr, TransA, LowerBound
	Make/O/N=(Dstate) Ctr = 0
	Make/O/N=(Dstate, Dstate) TransA = 0
	Make/O/N=5 LowerBound = 0
	
	Variable s
	
	// DstateCtrTransA
	// AAS4.ipf
	Variable ctrLine, transLine
	
	if(Dstate == 1)
		ctrLine = 10; transLine = 12
	elseif(Dstate == 2)
		ctrLine = 25; transLine = 28
	elseif(Dstate == 3)
		ctrLine = 43; transLine = 47
	elseif(Dstate == 4)
		ctrLine = 64; transLine = 69
	elseif(Dstate == 5)
		ctrLine = 88; transLine = 94
	else
		Print "  Warning: Invalid Dstate value: " + num2str(Dstate)
		return -1
	endif
	
	Printf "  Ctr line: %d, TransA line: %d\r", ctrLine, transLine
	
	// Ctr
	LoadWave/J/M/Q/D/A=wave/K=0/V={"\t,"," $",0,1}/L={ctrLine, ctrLine+1, Dstate, 0, 0}/P=data FileName
	Wave/Z wave0
	if(WaveExists(wave0))
		Ctr = wave0[p][1]
		Printf "  Ctr loaded: [%.4f", Ctr[0]
		Variable cc
		for(cc = 1; cc < Dstate; cc += 1)
			Printf ", %.4f", Ctr[cc]
		endfor
		Print "]"
		KillWaves/Z wave0
	else
		Print "  Warning: Ctr not loaded"
	endif
	
	// TransA - 
	LoadWave/J/M/Q/D/A=wave/K=0/V={"\t,"," $",0,1}/L={transLine, transLine+1, Dstate, 0, 0}/P=data FileName
	Wave/Z wave0
	if(WaveExists(wave0))
		for(s = 1; s <= Dstate; s += 1)
			TransA[][s-1] = wave0[p][2*(s-1) + 1]
		endfor
		Print "  TransA loaded"
		KillWaves/Z wave0
	else
		Print "  Warning: TransA not loaded"
	endif
	
	// LowerBoundD
	// AAS4.ipf
	Variable lbLines0 = 2, lbLines1 = 16, lbLines2 = 33, lbLines3 = 53, lbLines4 = 76
	
	LoadWave/J/M/Q/D/A=wave/K=1/V={"\t,"," $",0,1}/L={lbLines0, lbLines0+1, 1, 0, 0}/P=data FileName
	Wave/Z wave0
	if(WaveExists(wave0))
		LowerBound[0] = wave0[0][1]
		KillWaves/Z wave0
	endif
	
	LoadWave/J/M/Q/D/A=wave/K=1/V={"\t,"," $",0,1}/L={lbLines1, lbLines1+1, 1, 0, 0}/P=data FileName
	Wave/Z wave0
	if(WaveExists(wave0))
		LowerBound[1] = wave0[0][1]
		KillWaves/Z wave0
	endif
	
	LoadWave/J/M/Q/D/A=wave/K=1/V={"\t,"," $",0,1}/L={lbLines2, lbLines2+1, 1, 0, 0}/P=data FileName
	Wave/Z wave0
	if(WaveExists(wave0))
		LowerBound[2] = wave0[0][1]
		KillWaves/Z wave0
	endif
	
	LoadWave/J/M/Q/D/A=wave/K=1/V={"\t,"," $",0,1}/L={lbLines3, lbLines3+1, 1, 0, 0}/P=data FileName
	Wave/Z wave0
	if(WaveExists(wave0))
		LowerBound[3] = wave0[0][1]
		KillWaves/Z wave0
	endif
	
	LoadWave/J/M/Q/D/A=wave/K=1/V={"\t,"," $",0,1}/L={lbLines4, lbLines4+1, 1, 0, 0}/P=data FileName
	Wave/Z wave0
	if(WaveExists(wave0))
		LowerBound[4] = wave0[0][1]
		KillWaves/Z wave0
	endif
	
	Printf "  LowerBound loaded: [%.4f, %.4f, %.4f, %.4f, %.4f]\r", LowerBound[0], LowerBound[1], LowerBound[2], LowerBound[3], LowerBound[4]
	
	// nLowerBoundLowerBound - 5
	// nLowerBound[i] = LowerBound[i] / max(LowerBound)
	Wave/Z LB = LowerBound
	WaveStats/Q LB
	Variable maxLB = V_max
	if(maxLB > 0)
		Make/O/N=5 nLowerBound = 0
		Variable lb_i
		for(lb_i = 0; lb_i < 5; lb_i += 1)
			nLowerBound[lb_i] = LowerBound[lb_i] / maxLB
		endfor
		Printf "  nLowerBound created (max=%.4f): [", maxLB
		for(lb_i = 0; lb_i < 5; lb_i += 1)
			if(lb_i > 0)
				Printf ", "
			endif
			Printf "%.4f", nLowerBound[lb_i]
		endfor
		Print "]"
	endif
	
	// Wave
	Wave/Z CtrCheck = Ctr
	Wave/Z TransACheck = TransA
	Wave/Z LowerBoundCheck = LowerBound
	Printf "  Waves created: Ctr=%d, TransA=%d, LowerBound=%d\r", WaveExists(CtrCheck), WaveExists(TransACheck), WaveExists(LowerBoundCheck)
	
	return 0
End

// -----------------------------------------------------------------------------
// AAS2 + HMM
// -----------------------------------------------------------------------------
Function LoadAAS2_HMM(SampleName)
	String SampleName
	
	GetFileFolderInfo/D/Q
	String PathName = S_Path
	
	if(strlen(PathName) == 0)
		Print ""
		return 0
	endif
	
	return LoadAAS2_HMM_Path(PathName, SampleName)
End

Function LoadAAS2_HMM_Path(PathName, SampleName)
	String PathName, SampleName
	
	String FileName, FolderName, FileList
	Variable i, FileNum, f, s, RowSize, numCols, dstateCol2
	
	NVAR scale = root:scale
	NVAR framerate = root:framerate
	NVAR Dstate = root:Dstate
	NVAR ExCoef = root:ExCoef
	NVAR QE = root:QE
	NVAR/Z IntensityMode2 = root:IntensityMode
	Variable intMode2 = NVAR_Exists(IntensityMode2) ? IntensityMode2 : 1
	
	NewPath/O/Q data PathName
	NewDataFolder/O/S root:$(SampleName)
	
	// csv_hmm.csv
	FileList = IndexedFile(data, -1, ".csv")
	String mainFileList = ""
	Variable nFiles = ItemsInList(FileList)
	String fname
	for(i = 0; i < nFiles; i += 1)
		fname = StringFromList(i, FileList)
		if(StringMatch(fname, "*_hmm.csv") == 0)
			mainFileList += fname + ";"
		endif
	endfor
	
	FileNum = ItemsInList(mainFileList)
	Print "Loading " + num2str(FileNum) + " cell(s) [AAS2+HMM] from: " + PathName
	Print "File list: " + mainFileList
	
	for(i = 0; i < FileNum; i += 1)
		FileName = StringFromList(i, mainFileList)
		FolderName = SampleName + num2str(i + 1)
		
		Printf "=== Processing file %d: %s -> Folder: %s ===\r", i+1, FileName, FolderName
		
		NewDataFolder/O/S root:$(SampleName):$(FolderName)
		
		// CSV
		LoadWave/J/M/D/A=wave/K=0/L={0,1,0,0,0}/Q/P=data FileName
		Wave/Z wave0
		
		if(!WaveExists(wave0))
			Printf "    ERROR: wave0 not loaded for %s\r", FileName
			SetDataFolder root:$(SampleName)
			continue
		endif
		
		RowSize = DimSize(wave0, 0)
		numCols = DimSize(wave0, 1)
		Printf "    wave0 loaded: %d rows x %d cols\r", RowSize, numCols
		
		// 
		if(numCols < 11)
			Printf "    ERROR: insufficient columns (%d < 11), skipping LocPrecision\r", numCols
			SetDataFolder root:$(SampleName)
			continue
		endif
		
		Make/O/N=(RowSize) frame, displacement
		frame = 0; displacement = NaN
		Make/O/N=(RowSize) SignalN, SigmaA, Iback, BackN, VarLP, LocPrecision
		
		Printf "    LocPrecision wave created: %d points\r", numpnts(LocPrecision)
		
		// 
		SignalN = wave0[p][10] * ExCoef / QE
		SigmaA = sqrt((wave0[p][4] * wave0[p][5] + 1/12)) * scale
		Iback = wave0[p][7]
		BackN = Iback * ExCoef / QE
		VarLP = (SigmaA^2) / SignalN * (16/9 + 8*pi*(SigmaA^2)*BackN / (SignalN*(scale^2)))
		LocPrecision = sqrt(VarLP) * 1000
		SigmaA = SigmaA * 1000
		
		// 
		for(f = 1; f < RowSize; f += 1)
			if(wave0[f][0] == wave0[f-1][0])
				frame[f] = frame[f-1] + 1
			else
				frame[f] = 0
			endif
		endfor
		
		// 
		for(f = 1; f < RowSize; f += 1)
			if(wave0[f][0] == wave0[f-1][0])
				displacement[f] = sqrt((wave0[f][2]*scale - wave0[f-1][2]*scale)^2 + (wave0[f][3]*scale - wave0[f-1][3]*scale)^2)
			else
				displacement[f] = 0
			endif
		endfor
		
		// TraceMatrix8
		Make/O/N=(RowSize, 8) TraceMatrix = NaN
		TraceMatrix[][0] = wave0[p][0]
		TraceMatrix[][1] = frame[p]
		TraceMatrix[][2] = wave0[p][1] - 1
		TraceMatrix[][3] = wave0[p][2] * scale
		TraceMatrix[][4] = wave0[p][3] * scale
		if(intMode2 == 0)
			TraceMatrix[][5] = wave0[p][10]
		else
			TraceMatrix[][5] = wave0[p][10] * ExCoef / QE
		endif
		TraceMatrix[][6] = displacement[p]
		
		// DstateAAS2AAS4
		dstateCol2 = 11 + Dstate  // Dstate=1→12, Dstate=2→13, etc.
		if(numCols > dstateCol2)
			for(f = 1; f < RowSize; f += 1)
				TraceMatrix[f][7] = wave0[f-1][dstateCol2]
			endfor
			// 
			if(RowSize > 1)
				TraceMatrix[0][7] = TraceMatrix[1][7]
			endif
		else
			TraceMatrix[][7] = 0
		endif
		
		// NaN
		for(f = 0; f < RowSize; f += 1)
			if(TraceMatrix[f][1] == 0)
				TraceMatrix[f][6] = 0
				if(f + 1 < RowSize)
					TraceMatrix[f][7] = TraceMatrix[f+1][7]
				endif
			endif
		endfor
		
		Duplicate/O TraceMatrix, ROI
		ROI = TraceMatrix[p][0]
		
		KillWaves/Z wave0, frame, displacement
		
		// LocPrecision
		Wave/Z LP = LocPrecision
		Printf "    End of load: LocPrecision exists=%d, points=%d\r", WaveExists(LP), WaveExists(LP) ? numpnts(LP) : 0
		
		// HMM
		// AAS v4: xxx_data.csv → xxx_hmm.csv
		// AAS v2: xxx.csv → xxx_hmm.csv
		String hmmFileName
		if(StringMatch(FileName, "*_data.csv"))
			// v4: _data.csv  _hmm.csv 
			hmmFileName = ReplaceString("_data.csv", FileName, "_hmm.csv")
		else
			// v2: .csv  _hmm.csv 
			hmmFileName = RemoveEnding(FileName, ".csv") + "_hmm.csv"
		endif
		Printf "    Looking for HMM file: %s\r", hmmFileName
		LoadAAS2_HMMParams(hmmFileName, Dstate)
		
		SetDataFolder root:$(SampleName)
	endfor
	
	SetDataFolder root:
	Print "Loaded " + num2str(FileNum) + " cells"
	return FileNum
End

// AAS2HMM
static Function LoadAAS2_HMMParams(FileName, Dstate)
	String FileName
	Variable Dstate
	
	PathInfo data
	if(V_flag == 0)
		return -1
	endif
	
	GetFileFolderInfo/Q/P=data/Z FileName
	if(V_Flag != 0)
		Print "  Warning: HMM file not found: " + FileName
		return -1
	endif
	
	Make/O/N=(Dstate) Ctr = 0
	Make/O/N=(Dstate, Dstate) TransA = 0
	Make/O/N=5 LowerBound = 0
	
	Variable s
	
	// AAS2 HMM.csv
	// Ctr: Dstate=1→13, 2→30, 3→50, 4→73, 5→99
	// TransA: Dstate=1→15, 2→33, 3→54, 4→78, 5→105
	
	if(Dstate == 1)
		// Load Ctr
		LoadWave/J/M/Q/D/A=wave/K=0/V={"\t,"," $",0,1}/L={13,14,Dstate,0,0}/P=data FileName
		Wave/Z wave0
		if(WaveExists(wave0))
			Ctr = wave0[p][1]
			KillWaves/Z wave0
		endif
		
		// Load TransA
		LoadWave/J/M/Q/D/A=wave/K=0/V={"\t,"," $",0,1}/L={15,16,Dstate,0,0}/P=data FileName
		Wave/Z wave0
		if(WaveExists(wave0))
			for(s = 0; s < Dstate; s += 1)
				TransA[][s] = wave0[p][2*s + 1]
			endfor
			KillWaves/Z wave0
		endif
		
	elseif(Dstate == 2)
		// Load Ctr
		LoadWave/J/M/Q/D/A=wave/K=0/V={"\t,"," $",0,1}/L={30,31,Dstate,0,0}/P=data FileName
		Wave/Z wave0
		if(WaveExists(wave0))
			Ctr = wave0[p][1]
			KillWaves/Z wave0
		endif
		
		// Load TransA
		LoadWave/J/M/Q/D/A=wave/K=0/V={"\t,"," $",0,1}/L={33,34,Dstate,0,0}/P=data FileName
		Wave/Z wave0
		if(WaveExists(wave0))
			for(s = 0; s < Dstate; s += 1)
				TransA[][s] = wave0[p][2*s + 1]
			endfor
			KillWaves/Z wave0
		endif
		
	elseif(Dstate == 3)
		// Load Ctr
		LoadWave/J/M/Q/D/A=wave/K=0/V={"\t,"," $",0,1}/L={50,51,Dstate,0,0}/P=data FileName
		Wave/Z wave0
		if(WaveExists(wave0))
			Ctr = wave0[p][1]
			KillWaves/Z wave0
		endif
		
		// Load TransA
		LoadWave/J/M/Q/D/A=wave/K=0/V={"\t,"," $",0,1}/L={54,55,Dstate,0,0}/P=data FileName
		Wave/Z wave0
		if(WaveExists(wave0))
			for(s = 0; s < Dstate; s += 1)
				TransA[][s] = wave0[p][2*s + 1]
			endfor
			KillWaves/Z wave0
		endif
		
	elseif(Dstate == 4)
		// Load Ctr
		LoadWave/J/M/Q/D/A=wave/K=0/V={"\t,"," $",0,1}/L={73,74,Dstate,0,0}/P=data FileName
		Wave/Z wave0
		if(WaveExists(wave0))
			Ctr = wave0[p][1]
			KillWaves/Z wave0
		endif
		
		// Load TransA
		LoadWave/J/M/Q/D/A=wave/K=0/V={"\t,"," $",0,1}/L={78,79,Dstate,0,0}/P=data FileName
		Wave/Z wave0
		if(WaveExists(wave0))
			for(s = 0; s < Dstate; s += 1)
				TransA[][s] = wave0[p][2*s + 1]
			endfor
			KillWaves/Z wave0
		endif
		
	elseif(Dstate == 5)
		// Load Ctr
		LoadWave/J/M/Q/D/A=wave/K=0/V={"\t,"," $",0,1}/L={99,100,Dstate,0,0}/P=data FileName
		Wave/Z wave0
		if(WaveExists(wave0))
			Ctr = wave0[p][1]
			KillWaves/Z wave0
		endif
		
		// Load TransA
		LoadWave/J/M/Q/D/A=wave/K=0/V={"\t,"," $",0,1}/L={105,106,Dstate,0,0}/P=data FileName
		Wave/Z wave0
		if(WaveExists(wave0))
			for(s = 0; s < Dstate; s += 1)
				TransA[][s] = wave0[p][2*s + 1]
			endfor
			KillWaves/Z wave0
		endif
	else
		return -1
	endif
	
	// Load LowerBound (State)
	// State1: line 3-4
	LoadWave/J/M/Q/D/A=wave/K=1/V={"\t,"," $",0,1}/L={3,4,1,0,0}/P=data FileName
	Wave/Z wave0
	if(WaveExists(wave0))
		LowerBound[0] = wave0[0][1]
		KillWaves/Z wave0
	endif
	
	// State2: line 19-20
	LoadWave/J/M/Q/D/A=wave/K=1/V={"\t,"," $",0,1}/L={19,20,1,0,0}/P=data FileName
	Wave/Z wave0
	if(WaveExists(wave0))
		LowerBound[1] = wave0[0][1]
		KillWaves/Z wave0
	endif
	
	// State3: line 38-39
	LoadWave/J/M/Q/D/A=wave/K=1/V={"\t,"," $",0,1}/L={38,39,1,0,0}/P=data FileName
	Wave/Z wave0
	if(WaveExists(wave0))
		LowerBound[2] = wave0[0][1]
		KillWaves/Z wave0
	endif
	
	// State4: line 60-61
	LoadWave/J/M/Q/D/A=wave/K=1/V={"\t,"," $",0,1}/L={60,61,1,0,0}/P=data FileName
	Wave/Z wave0
	if(WaveExists(wave0))
		LowerBound[3] = wave0[0][1]
		KillWaves/Z wave0
	endif
	
	// State5: line 85-86
	LoadWave/J/M/Q/D/A=wave/K=1/V={"\t,"," $",0,1}/L={85,86,1,0,0}/P=data FileName
	Wave/Z wave0
	if(WaveExists(wave0))
		LowerBound[4] = wave0[0][1]
		KillWaves/Z wave0
	endif
	
	// nLowerBoundLowerBound - 5
	Wave/Z LB = LowerBound
	WaveStats/Q LB
	Variable maxLB = V_max
	if(maxLB > 0)
		Make/O/N=5 nLowerBound = 0
		Variable lb_i
		for(lb_i = 0; lb_i < 5; lb_i += 1)
			nLowerBound[lb_i] = LowerBound[lb_i] / maxLB
		endfor
	endif
	
	return 0
End

// -----------------------------------------------------------------------------
// AASHMM
// -----------------------------------------------------------------------------
Function LoadAAS_NoHMM(SampleName)
	String SampleName
	
	GetFileFolderInfo/D/Q
	String PathName = S_Path
	
	if(strlen(PathName) == 0)
		Print ""
		return 0
	endif
	
	return LoadAAS_NoHMM_Path(PathName, SampleName)
End

Function LoadAAS_NoHMM_Path(PathName, SampleName)
	String PathName, SampleName
	
	String FileName, FolderName, FileList, filteredList, fname_f
	Variable i, FileNum, f, RowSize, ff, numCols, dstateCol
	
	NVAR scale = root:scale
	NVAR framerate = root:framerate
	NVAR ExCoef = root:ExCoef
	NVAR QE = root:QE
	NVAR/Z IntensityMode3 = root:IntensityMode
	Variable intMode3 = NVAR_Exists(IntensityMode3) ? IntensityMode3 : 1
	
	NewPath/O/Q data PathName
	NewDataFolder/O/S root:$(SampleName)
	
	FileList = IndexedFile(data, -1, ".csv")
	
	// Filter out *_hmm.csv files (HMM results should not be loaded as separate cells)
	filteredList = ""

	for(ff = 0; ff < ItemsInList(FileList); ff += 1)
		fname_f = StringFromList(ff, FileList)
		if(StringMatch(fname_f, "*_hmm.csv") == 0)
			filteredList += fname_f + ";"
		endif
	endfor
	FileList = filteredList
	
	FileNum = ItemsInList(FileList)
	
	Print "Loading " + num2str(FileNum) + " cell(s) [AAS] from: " + PathName
	Print "File list: " + FileList
	
	for(i = 0; i < FileNum; i += 1)
		FileName = StringFromList(i, FileList)
		FolderName = SampleName + num2str(i + 1)
		
		Printf "=== Processing file %d: %s -> Folder: %s ===\r", i+1, FileName, FolderName
		
		NewDataFolder/O/S root:$(SampleName):$(FolderName)
		
		LoadWave/J/M/D/A=wave/K=0/L={0,1,0,0,0}/Q/P=data FileName
		Wave/Z wave0
		
		if(!WaveExists(wave0))
			Printf "    ERROR: wave0 not loaded for %s\r", FileName
			SetDataFolder root:$(SampleName)
			continue
		endif
		
		RowSize = DimSize(wave0, 0)
		numCols = DimSize(wave0, 1)
		Printf "    wave0 loaded: %d rows x %d cols\r", RowSize, numCols
		
		// 
		if(numCols < 11)
			Printf "    ERROR: insufficient columns (%d < 11), skipping LocPrecision\r", numCols
			SetDataFolder root:$(SampleName)
			continue
		endif
		
		Make/O/N=(RowSize) frame, displacement
		frame = 0; displacement = NaN
		Make/O/N=(RowSize) SignalN, SigmaA, Iback, BackN, VarLP, LocPrecision
		
		Printf "    LocPrecision wave created: %d points\r", numpnts(LocPrecision)
		
		SignalN = wave0[p][10] * ExCoef / QE
		SigmaA = sqrt((wave0[p][4] * wave0[p][5] + 1/12)) * scale
		Iback = wave0[p][7]
		BackN = Iback * ExCoef / QE
		VarLP = (SigmaA^2) / SignalN * (16/9 + 8*pi*(SigmaA^2)*BackN / (SignalN*(scale^2)))
		LocPrecision = sqrt(VarLP) * 1000
		SigmaA = SigmaA * 1000
		
		// 
		for(f = 1; f < RowSize; f += 1)
			if(wave0[f][0] == wave0[f-1][0])
				frame[f] = frame[f-1] + 1
			else
				frame[f] = 0
			endif
		endfor
		
		// 
		for(f = 1; f < RowSize; f += 1)
			if(wave0[f][0] == wave0[f-1][0])
				displacement[f] = sqrt((wave0[f][2]*scale - wave0[f-1][2]*scale)^2 + (wave0[f][3]*scale - wave0[f-1][3]*scale)^2)
			else
				displacement[f] = 0
			endif
		endfor
		
		// TraceMatrix7HMM
		Make/O/N=(RowSize, 7) TraceMatrix = NaN
		TraceMatrix[][0] = wave0[p][0]
		TraceMatrix[][1] = frame[p]
		TraceMatrix[][2] = wave0[p][1] - 1
		TraceMatrix[][3] = wave0[p][2] * scale
		TraceMatrix[][4] = wave0[p][3] * scale
		if(intMode3 == 0)
			TraceMatrix[][5] = wave0[p][10]
		else
			TraceMatrix[][5] = wave0[p][10] * ExCoef / QE
		endif
		TraceMatrix[][6] = displacement[p]
		
		// 
		for(f = 0; f < RowSize; f += 1)
			if(TraceMatrix[f][1] == 0)
				TraceMatrix[f][6] = 0
			endif
		endfor
		
		Duplicate/O TraceMatrix, ROI
		ROI = TraceMatrix[p][0]
		
		KillWaves/Z wave0, frame, displacement
		
		// LocPrecision
		Wave/Z LP = LocPrecision
		Printf "    End of load: LocPrecision exists=%d, points=%d\r", WaveExists(LP), WaveExists(LP) ? numpnts(LP) : 0
		
		SetDataFolder root:$(SampleName)
	endfor
	
	SetDataFolder root:
	Print "Loaded " + num2str(FileNum) + " cells"
	return FileNum
End

// -----------------------------------------------------------------------------
// TraceMatrixWave
// -----------------------------------------------------------------------------
Function MakeAnalysisWaves(SampleName)
	String SampleName
	
	Variable numFolders = CountDataFolders(SampleName)
	Variable m, f, nPts, numCols, seg, count, segVal, idx, segV
	String FolderName
	
	NVAR/Z MaxSegment = root:MaxSegment
	Variable maxSeg = 0
	if(NVAR_Exists(MaxSegment))
		maxSeg = MaxSegment
	endif
	
	Print "Creating analysis waves for " + num2str(numFolders) + " cells..."
	
	for(m = 0; m < numFolders; m += 1)
		FolderName = SampleName + num2str(m + 1)
		
		if(!DataFolderExists("root:" + SampleName + ":" + FolderName))
			continue
		endif
		
		SetDataFolder root:$(SampleName):$(FolderName)
		
		Wave/Z TraceMatrix
		if(!WaveExists(TraceMatrix))
			continue
		endif
		
		nPts = DimSize(TraceMatrix, 0)
		numCols = DimSize(TraceMatrix, 1)
		seg = 0
		
		// Wave
		for(seg = 0; seg <= maxSeg; seg += 1)
			String suffix = "_S" + num2str(seg)
			
			// 
			count = 0
			segVal = 0
			for(f = 0; f < nPts; f += 1)
				segVal = 0
				if(numCols > 8)
					segVal = TraceMatrix[f][8]
				endif
				if(numtype(segVal) != 0 || segVal == seg)
					count += 1
				endif
			endfor
			
			if(count == 0)
				continue
			endif
			
			// Wave
			Make/O/N=(count) $("Xum" + suffix) = NaN
			Make/O/N=(count) $("Yum" + suffix) = NaN
			Make/O/N=(count) $("Int" + suffix) = NaN
			Make/O/N=(count) $("Time" + suffix) = NaN
			Make/O/N=(count) $("Frame" + suffix) = NaN
			Make/O/N=(count) $("ROI" + suffix) = NaN
			Make/O/N=(count) $("Disp" + suffix) = NaN
			
			Wave Xum = $("Xum" + suffix)
			Wave Yum = $("Yum" + suffix)
			Wave IntW = $("Int" + suffix)
			Wave TimeW = $("Time" + suffix)
			Wave FrameW = $("Frame" + suffix)
			Wave ROIW = $("ROI" + suffix)
			Wave DispW = $("Disp" + suffix)
			
			// HMM Dstate Wave
			if(numCols > 7)
				Make/O/N=(count) $("Dstate" + suffix) = NaN
				Wave DstateW = $("Dstate" + suffix)
			endif
			
			idx = 0
			segV = 0
			for(f = 0; f < nPts; f += 1)
				segV = 0
				if(numCols > 8)
					segV = TraceMatrix[f][8]
				endif
				if(numtype(segV) != 0 || segV == seg)
					ROIW[idx] = TraceMatrix[f][0]
					FrameW[idx] = TraceMatrix[f][1]
					TimeW[idx] = TraceMatrix[f][2]
					Xum[idx] = TraceMatrix[f][3]
					Yum[idx] = TraceMatrix[f][4]
					IntW[idx] = TraceMatrix[f][5]
					DispW[idx] = TraceMatrix[f][6]
					if(numCols > 7)
						DstateW[idx] = TraceMatrix[f][7]
					endif
					idx += 1
				endif
			endfor
		endfor
	endfor
	
	SetDataFolder root:
	Print "Analysis waves created"
End

// Segment=0NaN- 
Function MakeAnalysisWavesS0(SampleName)
	String SampleName
	
	Variable numFolders = CountDataFolders(SampleName)
	Variable m, r, nPts, copyPts, numCols, sigSize, ExtDimSize, finalSize, nNaN, dst
	String FolderName, folderPath
	
	NVAR framerate = root:framerate
	NVAR/Z cAAS4 = root:cAAS4
	
	for(m = 0; m < numFolders; m += 1)
		FolderName = SampleName + num2str(m + 1)
		folderPath = "root:" + SampleName + ":" + FolderName + ":"
		
		if(!DataFolderExists("root:" + SampleName + ":" + FolderName))
			continue
		endif
		
		SetDataFolder root:$(SampleName):$(FolderName)
		
		// TraceMatrix
		String tmPath = folderPath + "TraceMatrix"
		Wave/Z TM = $tmPath
		if(!WaveExists(TM))
			continue
		endif
		
		nPts = DimSize(TM, 0)
		numCols = DimSize(TM, 1)
		
		// WaveMake/O
		Make/O/N=(nPts) $(folderPath + "ROI_S0")
		Make/O/N=(nPts) $(folderPath + "Rframe_S0")
		Make/O/N=(nPts) $(folderPath + "Rtime_S0")
		Make/O/N=(nPts) $(folderPath + "Xum_S0")
		Make/O/N=(nPts) $(folderPath + "Yum_S0")
		Make/O/N=(nPts) $(folderPath + "Int_S0")
		Make/O/N=(nPts) $(folderPath + "DF_S0")
		
		Wave ROI_S0 = $(folderPath + "ROI_S0")
		Wave Rframe_S0 = $(folderPath + "Rframe_S0")
		Wave Rtime_S0 = $(folderPath + "Rtime_S0")
		Wave Xum_S0 = $(folderPath + "Xum_S0")
		Wave Yum_S0 = $(folderPath + "Yum_S0")
		Wave Int_S0 = $(folderPath + "Int_S0")
		Wave DF_S0 = $(folderPath + "DF_S0")
		
		ROI_S0 = TM[p][0]
		Rframe_S0 = TM[p][1]
		// TM[p][2]MakeTraceMatrixTimeBaseframerate
		// 
		Rtime_S0 = TM[p][2] / framerate  // 
		Xum_S0 = TM[p][3]
		Yum_S0 = TM[p][4]
		Int_S0 = TM[p][5]
		DF_S0 = TM[p][6]
		
		// Dstate
		if(numCols > 7)
			Make/O/N=(nPts) $(folderPath + "Dstate_S0")
			Wave Dstate_S0 = $(folderPath + "Dstate_S0")
			Dstate_S0 = TM[p][7]
		endif
		
		// SignalN, LocPrecision
		Wave/Z SignalN = $(folderPath + "SignalN")
		Wave/Z SigmaA = $(folderPath + "SigmaA")
		Wave/Z BackN = $(folderPath + "BackN")
		Wave/Z LocPrecision = $(folderPath + "LocPrecision")
		Wave/Z Segment = $(folderPath + "Segment")
		
		Printf "  %s: TraceMatrix=%d pts, LocPrecision exists=%d\r", FolderName, nPts, WaveExists(LocPrecision)
		
		// SignalN_S0
		if(WaveExists(SignalN))
			sigSize = numpnts(SignalN)
			if(sigSize == nPts)
				Duplicate/O SignalN, $(folderPath + "SignalN_S0")
			else
				Make/O/N=(nPts) $(folderPath + "SignalN_S0")
				Wave SN_S0 = $(folderPath + "SignalN_S0")
				SN_S0 = NaN
				copyPts = min(sigSize, nPts)
				SN_S0[0, copyPts-1] = SignalN[p]
			endif
		endif
		
		// SigmaA_S0
		if(WaveExists(SigmaA))
			if(numpnts(SigmaA) == nPts)
				Duplicate/O SigmaA, $(folderPath + "SigmaA_S0")
			else
				Make/O/N=(nPts) $(folderPath + "SigmaA_S0")
				Wave SA_S0 = $(folderPath + "SigmaA_S0")
				SA_S0 = NaN
				copyPts = min(numpnts(SigmaA), nPts)
				SA_S0[0, copyPts-1] = SigmaA[p]
			endif
		endif
		
		// BackN_S0
		if(WaveExists(BackN))
			if(numpnts(BackN) == nPts)
				Duplicate/O BackN, $(folderPath + "BackN_S0")
			else
				Make/O/N=(nPts) $(folderPath + "BackN_S0")
				Wave BN_S0 = $(folderPath + "BackN_S0")
				BN_S0 = NaN
				copyPts = min(numpnts(BackN), nPts)
				BN_S0[0, copyPts-1] = BackN[p]
			endif
		endif
		
		// LocPrecision_S0
		if(WaveExists(LocPrecision))
			if(numpnts(LocPrecision) == nPts)
				Duplicate/O LocPrecision, $(folderPath + "LocPrecision_S0")
			else
				Make/O/N=(nPts) $(folderPath + "LocPrecision_S0")
				Wave LP_S0 = $(folderPath + "LocPrecision_S0")
				LP_S0 = NaN
				copyPts = min(numpnts(LocPrecision), nPts)
				LP_S0[0, copyPts-1] = LocPrecision[p]
			endif
			Wave LP_S0_chk = $(folderPath + "LocPrecision_S0")
			Printf "    LocPrecision_S0 created: %d points\r", numpnts(LP_S0_chk)
		else
			Printf "    Warning: LocPrecision wave not found in %s\r", FolderName
		endif
		
		// Segment_S0
		if(WaveExists(Segment))
			if(numpnts(Segment) == nPts)
				Duplicate/O Segment, $(folderPath + "Segment_S0")
			else
				Make/O/N=(nPts) $(folderPath + "Segment_S0")
				Wave Seg_S0 = $(folderPath + "Segment_S0")
				Seg_S0 = NaN
				copyPts = min(numpnts(Segment), nPts)
				Seg_S0[0, copyPts-1] = Segment[p]
			endif
		endif
		
		// ROI NaN separator insertion
		// Batch method: O(n) instead of O(n²) InsertPoints
		Wave ROI_S0r = $(folderPath + "ROI_S0")
		Wave Rframe_S0r = $(folderPath + "Rframe_S0")
		Wave Rtime_S0r = $(folderPath + "Rtime_S0")
		Wave Xum_S0r = $(folderPath + "Xum_S0")
		Wave Yum_S0r = $(folderPath + "Yum_S0")
		Wave Int_S0r = $(folderPath + "Int_S0")
		Wave DF_S0r = $(folderPath + "DF_S0")
		Wave/Z Dstate_S0r = $(folderPath + "Dstate_S0")
		Wave/Z SignalN_S0r = $(folderPath + "SignalN_S0")
		Wave/Z SigmaA_S0r = $(folderPath + "SigmaA_S0")
		Wave/Z BackN_S0r = $(folderPath + "BackN_S0")
		Wave/Z LocPrecision_S0r = $(folderPath + "LocPrecision_S0")
		Wave/Z Segment_S0r = $(folderPath + "Segment_S0")
		
		// Pass 1: Count ROI transitions
		ExtDimSize = numpnts(ROI_S0r)
		nNaN = 0
		for(r = 1; r < ExtDimSize; r += 1)
			if(ROI_S0r[r] != ROI_S0r[r-1] && numtype(ROI_S0r[r]) == 0 && numtype(ROI_S0r[r-1]) == 0)
				nNaN += 1
			endif
		endfor
		
		if(nNaN > 0)
			// Pass 2: Create new waves and copy with NaN gaps
			finalSize = ExtDimSize + nNaN
			Make/O/N=(finalSize) tmpROI=NaN, tmpRf=NaN, tmpRt=NaN, tmpX=NaN, tmpY=NaN, tmpInt=NaN, tmpDF=NaN
			Make/O/N=(finalSize) tmpDs=NaN, tmpSN=NaN, tmpSA=NaN, tmpBN=NaN, tmpLP=NaN, tmpSeg=NaN
			
			dst = 0
			tmpROI[0] = ROI_S0r[0]
			tmpRf[0] = Rframe_S0r[0]
			tmpRt[0] = Rtime_S0r[0]
			tmpX[0] = Xum_S0r[0]
			tmpY[0] = Yum_S0r[0]
			tmpInt[0] = Int_S0r[0]
			tmpDF[0] = DF_S0r[0]
			if(WaveExists(Dstate_S0r))
				tmpDs[0] = Dstate_S0r[0]
			endif
			if(WaveExists(SignalN_S0r))
				tmpSN[0] = SignalN_S0r[0]
			endif
			if(WaveExists(SigmaA_S0r))
				tmpSA[0] = SigmaA_S0r[0]
			endif
			if(WaveExists(BackN_S0r))
				tmpBN[0] = BackN_S0r[0]
			endif
			if(WaveExists(LocPrecision_S0r))
				tmpLP[0] = LocPrecision_S0r[0]
			endif
			if(WaveExists(Segment_S0r))
				tmpSeg[0] = Segment_S0r[0]
			endif
			dst = 1
			
			for(r = 1; r < ExtDimSize; r += 1)
				if(ROI_S0r[r] != ROI_S0r[r-1] && numtype(ROI_S0r[r]) == 0 && numtype(ROI_S0r[r-1]) == 0)
					// NaN separator (tmpROI[dst] already NaN)
					dst += 1
				endif
				tmpROI[dst] = ROI_S0r[r]
				tmpRf[dst] = Rframe_S0r[r]
				tmpRt[dst] = Rtime_S0r[r]
				tmpX[dst] = Xum_S0r[r]
				tmpY[dst] = Yum_S0r[r]
				tmpInt[dst] = Int_S0r[r]
				tmpDF[dst] = DF_S0r[r]
				if(WaveExists(Dstate_S0r))
					tmpDs[dst] = Dstate_S0r[r]
				endif
				if(WaveExists(SignalN_S0r))
					tmpSN[dst] = SignalN_S0r[r]
				endif
				if(WaveExists(SigmaA_S0r))
					tmpSA[dst] = SigmaA_S0r[r]
				endif
				if(WaveExists(BackN_S0r))
					tmpBN[dst] = BackN_S0r[r]
				endif
				if(WaveExists(LocPrecision_S0r))
					tmpLP[dst] = LocPrecision_S0r[r]
				endif
				if(WaveExists(Segment_S0r))
					tmpSeg[dst] = Segment_S0r[r]
				endif
				dst += 1
			endfor
			
			// Overwrite originals
			Duplicate/O tmpROI, ROI_S0r
			Duplicate/O tmpRf, Rframe_S0r
			Duplicate/O tmpRt, Rtime_S0r
			Duplicate/O tmpX, Xum_S0r
			Duplicate/O tmpY, Yum_S0r
			Duplicate/O tmpInt, Int_S0r
			Duplicate/O tmpDF, DF_S0r
			if(WaveExists(Dstate_S0r))
				Duplicate/O tmpDs, Dstate_S0r
			endif
			if(WaveExists(SignalN_S0r))
				Duplicate/O tmpSN, SignalN_S0r
			endif
			if(WaveExists(SigmaA_S0r))
				Duplicate/O tmpSA, SigmaA_S0r
			endif
			if(WaveExists(BackN_S0r))
				Duplicate/O tmpBN, BackN_S0r
			endif
			if(WaveExists(LocPrecision_S0r))
				Duplicate/O tmpLP, LocPrecision_S0r
			endif
			if(WaveExists(Segment_S0r))
				Duplicate/O tmpSeg, Segment_S0r
			endif
			
			KillWaves/Z tmpROI, tmpRf, tmpRt, tmpX, tmpY, tmpInt, tmpDF
			KillWaves/Z tmpDs, tmpSN, tmpSA, tmpBN, tmpLP, tmpSeg
		endif
		
		Printf "  %s: %d points (%d NaN separators)\r", FolderName, numpnts(ROI_S0r), nNaN
	endfor
	
	SetDataFolder root:
	Print "Analysis waves created with NaN separators"
End

// -----------------------------------------------------------------------------
// 
// -----------------------------------------------------------------------------
Function CreateResultsFolder(SampleName)
	String SampleName
	
	if(!DataFolderExists("root:" + SampleName))
		NewDataFolder/O root:$(SampleName)
	endif
	
	if(!DataFolderExists("root:" + SampleName + ":Results"))
		NewDataFolder/O root:$(SampleName):Results
	endif
End

// basePath
Function CreateResultsFolderInPath(basePath, SampleName)
	String basePath, SampleName
	
	String samplePath = basePath + ":" + SampleName
	if(!DataFolderExists(samplePath))
		return -1
	endif
	
	String resultsPath = samplePath + ":Results"
	if(!DataFolderExists(resultsPath))
		NewDataFolder/O $resultsPath
	endif
	return 0
End

// -----------------------------------------------------------------------------
// 
// -----------------------------------------------------------------------------
Function ValidateLoadedData(SampleName)
	String SampleName
	
	Variable numFolders = CountDataFolders(SampleName)
	Variable errors = 0
	Variable m, nPts
	String FolderName
	
	Print "Validating data for " + SampleName + "..."
	
	for(m = 0; m < numFolders; m += 1)
		FolderName = SampleName + num2str(m + 1)
		
		if(!DataFolderExists("root:" + SampleName + ":" + FolderName))
			Print "  Error: Folder not found: " + FolderName
			errors += 1
			continue
		endif
		
		SetDataFolder root:$(SampleName):$(FolderName)
		
		Wave/Z TraceMatrix
		if(!WaveExists(TraceMatrix))
			Print "  Error: TraceMatrix not found in " + FolderName
			errors += 1
			continue
		endif
		
		nPts = DimSize(TraceMatrix, 0)
		if(nPts == 0)
			Print "  Warning: Empty TraceMatrix in " + FolderName
		endif
		
		// NaN 
		WaveStats/Q/M=1 TraceMatrix
		if(V_numNaNs > nPts * 0.5)
			Print "  Warning: High NaN ratio in " + FolderName
		endif
	endfor
	
	SetDataFolder root:
	
	if(errors == 0)
		Print "Validation passed: " + num2str(numFolders) + " folders OK"
	else
		Print "Validation completed with " + num2str(errors) + " error(s)"
	endif
	
	return errors
End

// -----------------------------------------------------------------------------
// Load
// -----------------------------------------------------------------------------
Function SMI_LoadData(SampleName)
	String SampleName
	
	// 
	NVAR/Z cAAS2 = root:cAAS2
	NVAR/Z cAAS4 = root:cAAS4
	NVAR/Z cHMM = root:cHMM
	
	Variable isAAS2 = NVAR_Exists(cAAS2) ? cAAS2 : 0
	Variable isAAS4 = NVAR_Exists(cAAS4) ? cAAS4 : 1
	Variable isHMM = NVAR_Exists(cHMM) ? cHMM : 1
	
	// v2v4OFFv4
	if(!isAAS2 && !isAAS4)
		isAAS4 = 1
	endif
	
	// v2v4
	if(isAAS2)
		isAAS4 = 0
	endif
	
	Variable numLoaded = 0
	
	if(isAAS4 && isHMM)
		// AAS4 + HMM
		Print "Loading AAS v4 + HMM format..."
		numLoaded = LoadAAS4_HMM(SampleName)
	elseif(isAAS4 && !isHMM)
		// AAS4 without HMM
		Print "Loading AAS v4 (no HMM) format..."
		numLoaded = LoadAAS_NoHMM(SampleName)
	elseif(isAAS2 && isHMM)
		// AAS2 + HMM
		Print "Loading AAS v2 + HMM format..."
		numLoaded = LoadAAS2_HMM(SampleName)
	else
		// AAS2 without HMM
		Print "Loading AAS v2 (no HMM) format..."
		numLoaded = LoadAAS_NoHMM(SampleName)
	endif
	
	return numLoaded
End

// -----------------------------------------------------------------------------
// 
// -----------------------------------------------------------------------------
Function SMI_LoadDataPath(PathName, SampleName)
	String PathName, SampleName
	
	// 
	NVAR/Z cAAS2 = root:cAAS2
	NVAR/Z cAAS4 = root:cAAS4
	NVAR/Z cHMM = root:cHMM
	
	Variable isAAS2 = NVAR_Exists(cAAS2) ? cAAS2 : 0
	Variable isAAS4 = NVAR_Exists(cAAS4) ? cAAS4 : 1
	Variable isHMM = NVAR_Exists(cHMM) ? cHMM : 1
	
	// v2v4OFFv4
	if(!isAAS2 && !isAAS4)
		isAAS4 = 1
	endif
	
	// v2v4
	if(isAAS2)
		isAAS4 = 0
	endif
	
	Variable numLoaded = 0
	
	if(isAAS4 && isHMM)
		// AAS4 + HMM
		Print "Loading AAS v4 + HMM format..."
		numLoaded = LoadAAS4_HMM_Path(PathName, SampleName)
	elseif(isAAS4 && !isHMM)
		// AAS4 without HMM
		Print "Loading AAS v4 (no HMM) format..."
		numLoaded = LoadAAS_NoHMM_Path(PathName, SampleName)
	elseif(isAAS2 && isHMM)
		// AAS2 + HMM
		Print "Loading AAS v2 + HMM format..."
		numLoaded = LoadAAS2_HMM_Path(PathName, SampleName)
	else
		// AAS2 without HMM
		Print "Loading AAS v2 (no HMM) format..."
		numLoaded = LoadAAS_NoHMM_Path(PathName, SampleName)
	endif
	
	return numLoaded
End

// -----------------------------------------------------------------------------
// TraceMatrix
// -----------------------------------------------------------------------------
Function MakeTraceMatrixTimeBase(SampleName)
	String SampleName
	
	Variable numFolders = CountDataFolders(SampleName)
	Variable m, f, nPts
	String FolderName
	
	NVAR framerate = root:framerate
	
	Print "Converting time base for " + num2str(numFolders) + " cells..."
	
	for(m = 0; m < numFolders; m += 1)
		FolderName = SampleName + num2str(m + 1)
		
		if(!DataFolderExists("root:" + SampleName + ":" + FolderName))
			continue
		endif
		
		SetDataFolder root:$(SampleName):$(FolderName)
		
		Wave/Z TraceMatrix
		if(!WaveExists(TraceMatrix))
			continue
		endif
		
		nPts = DimSize(TraceMatrix, 0)
		
		// 2
		for(f = 0; f < nPts; f += 1)
			TraceMatrix[f][2] = TraceMatrix[f][2] * framerate
		endfor
	endfor
	
	SetDataFolder root:
	Print "Time base conversion complete"
End

// -----------------------------------------------------------------------------
// HMM Dstate - Dstate
// -----------------------------------------------------------------------------
Function MakeAnalysisWavesHMM(SampleName)
	String SampleName
	
	Variable numFolders = CountDataFolders(SampleName)
	Variable m, s, r, RowSize
	String FolderName, folderPath, suffix
	
	NVAR Dstate = root:Dstate
	NVAR/Z cAAS4 = root:cAAS4
	
	Print "=== Dstate Separation ==="
	Print "Sample: " + SampleName
	Print "Dstate count: " + num2str(Dstate)
	
	for(m = 0; m < numFolders; m += 1)
		FolderName = SampleName + num2str(m + 1)
		folderPath = "root:" + SampleName + ":" + FolderName + ":"
		SetDataFolder root:$(SampleName):$(FolderName)
		
		// Wave
		Wave/Z ROI_S0 = $(folderPath + "ROI_S0")
		Wave/Z Dstate_S0 = $(folderPath + "Dstate_S0")
		Wave/Z LocPrecision_S0 = $(folderPath + "LocPrecision_S0")
		
		// 
		Printf "  %s: LocPrecision_S0 exists = %d", FolderName, WaveExists(LocPrecision_S0)
		if(WaveExists(LocPrecision_S0))
			Printf ", size = %d", numpnts(LocPrecision_S0)
		endif
		Printf "\r"
		
		if(!WaveExists(ROI_S0) || !WaveExists(Dstate_S0))
			Printf ": %s Wave\r", FolderName
			continue
		endif
		
		RowSize = numpnts(ROI_S0)
		Printf "    ROI_S0 size = %d\r", RowSize
		
		// Dstate
		for(s = 1; s <= Dstate; s += 1)
			suffix = "_S" + num2str(s)
			
			// 
			Duplicate/O $(folderPath + "ROI_S0"), $(folderPath + "ROI" + suffix)
			Duplicate/O $(folderPath + "Rframe_S0"), $(folderPath + "Rframe" + suffix)
			Duplicate/O $(folderPath + "Rtime_S0"), $(folderPath + "Rtime" + suffix)
			Duplicate/O $(folderPath + "Xum_S0"), $(folderPath + "Xum" + suffix)
			Duplicate/O $(folderPath + "Yum_S0"), $(folderPath + "Yum" + suffix)
			Duplicate/O $(folderPath + "Int_S0"), $(folderPath + "Int" + suffix)
			Duplicate/O $(folderPath + "DF_S0"), $(folderPath + "DF" + suffix)
			Duplicate/O $(folderPath + "Dstate_S0"), $(folderPath + "Dstate" + suffix)
			
			// Wave
			Wave ROI_Sn = $(folderPath + "ROI" + suffix)
			Wave Rframe_Sn = $(folderPath + "Rframe" + suffix)
			Wave Rtime_Sn = $(folderPath + "Rtime" + suffix)
			Wave Xum_Sn = $(folderPath + "Xum" + suffix)
			Wave Yum_Sn = $(folderPath + "Yum" + suffix)
			Wave Int_Sn = $(folderPath + "Int" + suffix)
			Wave DF_Sn = $(folderPath + "DF" + suffix)
			Wave Dstate_Sn = $(folderPath + "Dstate" + suffix)
			
			// Wave - 
			Wave/Z LP_S0 = $(folderPath + "LocPrecision_S0")
			if(WaveExists(LP_S0))
				Duplicate/O LP_S0, $(folderPath + "LocPrecision" + suffix)
				Printf "    Created LocPrecision%s\r", suffix
			endif
			
			Wave/Z SN_S0 = $(folderPath + "SignalN_S0")
			if(WaveExists(SN_S0))
				Duplicate/O SN_S0, $(folderPath + "SignalN" + suffix)
			endif
			
			Wave/Z SA_S0 = $(folderPath + "SigmaA_S0")
			if(WaveExists(SA_S0))
				Duplicate/O SA_S0, $(folderPath + "SigmaA" + suffix)
			endif
			
			Wave/Z BN_S0 = $(folderPath + "BackN_S0")
			if(WaveExists(BN_S0))
				Duplicate/O BN_S0, $(folderPath + "BackN" + suffix)
			endif
			
			Wave/Z Seg_S0 = $(folderPath + "Segment_S0")
			if(WaveExists(Seg_S0) && NVAR_Exists(cAAS4) && cAAS4 == 1)
				Duplicate/O Seg_S0, $(folderPath + "Segment" + suffix)
			endif
			
			// Wave
			Wave/Z LocP_Sn = $(folderPath + "LocPrecision" + suffix)
			Wave/Z SigN_Sn = $(folderPath + "SignalN" + suffix)
			Wave/Z SigA_Sn = $(folderPath + "SigmaA" + suffix)
			Wave/Z BackN_Sn = $(folderPath + "BackN" + suffix)
			Wave/Z Seg_Sn = $(folderPath + "Segment" + suffix)
			
			// Dstate_S0
			Wave DS0 = $(folderPath + "Dstate_S0")
			
			// DstateNaN
			for(r = 0; r < RowSize; r += 1)
				if(DS0[r] != s)
					ROI_Sn[r] = NaN
					Rframe_Sn[r] = NaN
					Rtime_Sn[r] = NaN
					Xum_Sn[r] = NaN
					Yum_Sn[r] = NaN
					Int_Sn[r] = NaN
					DF_Sn[r] = NaN
					Dstate_Sn[r] = NaN
					
					if(WaveExists(LocP_Sn))
						LocP_Sn[r] = NaN
					endif
					if(WaveExists(SigN_Sn))
						SigN_Sn[r] = NaN
					endif
					if(WaveExists(SigA_Sn))
						SigA_Sn[r] = NaN
					endif
					if(WaveExists(BackN_Sn))
						BackN_Sn[r] = NaN
					endif
					if(WaveExists(Seg_Sn))
						Seg_Sn[r] = NaN
					endif
				endif
			endfor
		endfor
		
		Printf "  %s: Dstate\r", FolderName
	endfor
	
	SetDataFolder root:
	Print "Dstate separation complete"
End

// -----------------------------------------------------------------------------
// TraceHMM DstateXY
// -----------------------------------------------------------------------------
Function Trace_HMM(SampleName, [basePath, waveSuffix])
	String SampleName
	String basePath, waveSuffix
	
	// 
	if(ParamIsDefault(basePath))
		basePath = "root"
	endif
	if(ParamIsDefault(waveSuffix))
		waveSuffix = ""
	endif
	
	Variable numFolders
	if(StringMatch(basePath, "root"))
		numFolders = CountDataFolders(SampleName)
	else
		numFolders = CountDataFoldersInPath(basePath, SampleName)
	endif
	
	Variable m
	String FolderName
	
	NVAR Dstate = root:Dstate
	NVAR scale = root:scale
	NVAR PixNum = root:PixNum
	
	Variable ImageSize = scale * PixNum
	
	// Dstate
	Make/FREE/T/N=(5, 5) StateNames
	StateNames[0][0] = "Slow"; StateNames[0][1] = "Fast"
	StateNames[1][0] = "Immobile"; StateNames[1][1] = "Slow"; StateNames[1][2] = "Fast"
	StateNames[2][0] = "Immobile"; StateNames[2][1] = "Slow"; StateNames[2][2] = "Medium"; StateNames[2][3] = "Fast"
	StateNames[3][0] = "Immobile"; StateNames[3][1] = "Slow"; StateNames[3][2] = "Medium"; StateNames[3][3] = "Fast"; StateNames[3][4] = "Ultra Fast"
	
	Variable nameIdx = Dstate - 2
	if(nameIdx < 0)
		nameIdx = 0
	endif
	if(nameIdx > 3)
		nameIdx = 3
	endif
	
	String Txtbox, stateName
	String samplePath
	if(StringMatch(basePath, "root"))
		samplePath = "root:" + SampleName
	else
		samplePath = basePath + ":" + SampleName
	endif
	
	for(m = 0; m < numFolders; m += 1)
		FolderName = SampleName + num2str(m + 1)
		String cellPath = samplePath + ":" + FolderName
		
		if(!DataFolderExists(cellPath))
			continue
		endif
		
		SetDataFolder $cellPath
		
		// S0waveSuffix
		String xS0Name = "Xum_S0" + waveSuffix
		String yS0Name = "Yum_S0" + waveSuffix
		Wave/Z Xum_S0 = $xS0Name
		Wave/Z Yum_S0 = $yS0Name
		if(!WaveExists(Xum_S0))
			Printf ": %s Xum_S0\r", FolderName
			continue
		endif
		
		// 
		String winName = FolderName + "_Trajectory" + waveSuffix
		String graphTitle = GetGraphTitleWithSeg(FolderName + " Trajectory", waveSuffix)
		
		// 
		DoWindow/K $winName
		
		// 
		Display/K=1/N=$winName Yum_S0 vs Xum_S0
		DoWindow/T $winName, graphTitle
		ModifyGraph rgb($yS0Name)=(65535,65535,65535)
		ModifyGraph mode=0, msize=1
		ModifyGraph lsize($yS0Name)=0.25
		
		Txtbox = ""
		
		// S1
		String xS1Name = "Xum_S1" + waveSuffix
		String yS1Name = "Yum_S1" + waveSuffix
		Wave/Z Xum_S1 = $xS1Name
		Wave/Z Yum_S1 = $yS1Name
		if(WaveExists(Xum_S1) && WaveExists(Yum_S1))
			AppendToGraph Yum_S1 vs Xum_S1
			ModifyGraph rgb($yS1Name)=(32768,40704,65280)
			ModifyGraph lsize($yS1Name)=0.25
			stateName = StateNames[nameIdx][0]
			Txtbox = "\\F'Arial'\\Z16\r\\K(32768,40704,65280)" + stateName
		endif
		
		// S2
		if(Dstate > 1)
			String xS2Name = "Xum_S2" + waveSuffix
			String yS2Name = "Yum_S2" + waveSuffix
			Wave/Z Xum_S2 = $xS2Name
			Wave/Z Yum_S2 = $yS2Name
			if(WaveExists(Xum_S2) && WaveExists(Yum_S2))
				AppendToGraph Yum_S2 vs Xum_S2
				ModifyGraph rgb($yS2Name)=(65280,65280,0)
				ModifyGraph lsize($yS2Name)=0.25
				stateName = StateNames[nameIdx][1]
				Txtbox += "\\F'Arial'\\Z16\r\\K(65280,65280,0)" + stateName
				ReorderTraces $yS1Name, {$yS2Name}
			endif
		endif
		
		// S3
		if(Dstate > 2)
			String xS3Name = "Xum_S3" + waveSuffix
			String yS3Name = "Yum_S3" + waveSuffix
			Wave/Z Xum_S3 = $xS3Name
			Wave/Z Yum_S3 = $yS3Name
			if(WaveExists(Xum_S3) && WaveExists(Yum_S3))
				AppendToGraph Yum_S3 vs Xum_S3
				ModifyGraph rgb($yS3Name)=(0,65280,0)
				ModifyGraph lsize($yS3Name)=0.25
				stateName = StateNames[nameIdx][2]
				Txtbox += "\\F'Arial'\\Z16\r\\K(0,65280,0)" + stateName
				ReorderTraces $yS1Name, {$yS3Name, $yS2Name}
			endif
		endif
		
		// S4
		if(Dstate > 3)
			String xS4Name = "Xum_S4" + waveSuffix
			String yS4Name = "Yum_S4" + waveSuffix
			Wave/Z Xum_S4 = $xS4Name
			Wave/Z Yum_S4 = $yS4Name
			if(WaveExists(Xum_S4) && WaveExists(Yum_S4))
				AppendToGraph Yum_S4 vs Xum_S4
				ModifyGraph rgb($yS4Name)=(65280,0,0)
				ModifyGraph lsize($yS4Name)=0.25
				stateName = StateNames[nameIdx][3]
				Txtbox += "\\F'Arial'\\Z16\r\\K(65280,0,0)" + stateName
				ReorderTraces $yS1Name, {$yS4Name, $yS3Name, $yS2Name}
			endif
		endif
		
		// S5
		if(Dstate > 4)
			String xS5Name = "Xum_S5" + waveSuffix
			String yS5Name = "Yum_S5" + waveSuffix
			Wave/Z Xum_S5 = $xS5Name
			Wave/Z Yum_S5 = $yS5Name
			if(WaveExists(Xum_S5) && WaveExists(Yum_S5))
				AppendToGraph Yum_S5 vs Xum_S5
				ModifyGraph rgb($yS5Name)=(65280,40704,32768)
				ModifyGraph lsize($yS5Name)=0.25
				stateName = StateNames[nameIdx][4]
				Txtbox += "\\F'Arial'\\Z16\r\\K(65280,40704,32768)" + stateName
				ReorderTraces $yS1Name, {$yS5Name, $yS4Name, $yS3Name, $yS2Name}
			endif
		endif
		
		// 
		if(strlen(Txtbox) > 0)
			TextBox/C/N=text0/F=0/B=1/A=RB Txtbox
		endif
		
		// 
		ModifyGraph width={Aspect,1}, height={Aspect,1}
		ModifyGraph tick=0, mirror=0, fStyle=1, fSize=16, font="Arial"
		Label bottom "X µm"
		Label left "Y µm"
		SetAxis bottom 0, ImageSize
		SetAxis left 0, ImageSize
		ModifyGraph gbRGB=(0,0,0)
		ModifyGraph tickRGB(bottom)=(65535,65535,65535)
		ModifyGraph tickRGB(left)=(65535,65535,65535)
	endfor
	
	SetDataFolder root:
End

// -----------------------------------------------------------------------------
// DstateNaN
// -----------------------------------------------------------------------------

// =============================================================================
// 
// =============================================================================

// -----------------------------------------------------------------------------
// AutoLoadFromFolder - SampleName
// -----------------------------------------------------------------------------
// : SampleName
// -----------------------------------------------------------------------------
Function/S AutoLoadFromFolder()
	// 
	GetFileFolderInfo/D/Q
	String fullPath = S_Path
	
	If(strlen(fullPath) == 0)
		Print ""
		return ""
	EndIf
	
	// 
	String sampleName
	sampleName = ExtractFolderName(fullPath)
	
	If(strlen(sampleName) == 0)
		Print ""
		return ""
	EndIf
	
	Printf ": %s\r", fullPath
	Printf "SampleName: %s\r", sampleName
	
	return sampleName
End

// -----------------------------------------------------------------------------
// CleanSampleName - Igor Pro
// -----------------------------------------------------------------------------
Function/S CleanSampleName(name)
	String name
	
	// 
	name = ReplaceString(" ", name, "_")
	// 
	name = ReplaceString("-", name, "_")
	// 
	name = ReplaceString(".", name, "_")
	// 
	name = ReplaceString("(", name, "")
	name = ReplaceString(")", name, "")
	name = ReplaceString("[", name, "")
	name = ReplaceString("]", name, "")
	
	// "S"
	String firstChar = name[0]
	If(char2num(firstChar) >= 48 && char2num(firstChar) <= 57)
		name = "S" + name
	EndIf
	
	// 31
	If(strlen(name) > 31)
		name = name[0, 30]
	EndIf
	
	return name
End

// -----------------------------------------------------------------------------
// CreateFileNameTable - CSV
// -----------------------------------------------------------------------------
// SampleNameFileNameTable
// -----------------------------------------------------------------------------
Function CreateFileNameTable(SampleName, PathName)
	String SampleName, PathName
	
	String FileList, mainFileList, fname
	Variable i, nFiles, FileNum
	
	NewPath/O/Q data PathName
	
	// csv_hmm.csv
	FileList = IndexedFile(data, -1, ".csv")
	mainFileList = ""
	nFiles = ItemsInList(FileList)
	
	For(i = 0; i < nFiles; i += 1)
		fname = StringFromList(i, FileList)
		If(StringMatch(fname, "*_hmm.csv") == 0)
			mainFileList += fname + ";"
		EndIf
	EndFor
	
	FileNum = ItemsInList(mainFileList)
	
	If(FileNum == 0)
		Print ": CSV"
		return -1
	EndIf
	
	// SampleName
	SetDataFolder root:$(SampleName)
	
	// Wave: 
	Make/O/T/N=(FileNum) FileNameList
	// Wave: 
	Make/O/N=(FileNum) FolderNumberList
	
	For(i = 0; i < FileNum; i += 1)
		fname = StringFromList(i, mainFileList)
		FileNameList[i] = fname
		FolderNumberList[i] = i + 1
	EndFor
	
	// 
	String tableName = SampleName + "_FileTable"
	DoWindow/K $tableName
	Edit/K=1/N=$tableName FolderNumberList, FileNameList as SampleName + " File Mapping"
	ModifyTable/W=$tableName width(FolderNumberList)=80, width(FileNameList)=300
	ModifyTable/W=$tableName title(FolderNumberList)="Folder#", title(FileNameList)="CSV File Name"
	
	Printf ": %d files\r", FileNum
	
	SetDataFolder root:
	return FileNum
End

// -----------------------------------------------------------------------------
// SingleSampleAnalysis - SampleName
// -----------------------------------------------------------------------------
Function SingleSampleAnalysis(fullPath, SampleName)
	String fullPath, SampleName
	
	Print "=========================================="
	Printf "Single Sample Analysis: %s\r", SampleName
	Print "=========================================="
	Printf "Path: %s\r", fullPath
	
	// 
	NVAR/Z cAAS2 = root:cAAS2
	NVAR/Z cAAS4 = root:cAAS4
	NVAR/Z cHMM = root:cHMM
	NVAR Dstate = root:Dstate
	NVAR maxOlig = root:MaxOligomerSize
	NVAR fitType = root:FitType  // MSD (0:free, 1:confined, 2:confined+err)
	NVAR maxExp = root:ExpMax_off

	Variable isAAS2 = NVAR_Exists(cAAS2) ? cAAS2 : 0
	Variable isAAS4 = NVAR_Exists(cAAS4) ? cAAS4 : 1
	Variable isHMM = NVAR_Exists(cHMM) ? cHMM : 1
	Variable dstateVal = Dstate
	Variable maxOligVal = maxOlig
	Variable fitTypeVal = fitType  // : +
	Variable maxExpVal = maxExp
	
	// Image integration variables (used in Step 0.1 and Step 3.5)
	Variable imgImportMode, fi, nTrCells, trCell
	Variable fixMeanVal, fixSDVal
	String csvFileListStr, trCellFolder, trGraphName
	
	// v2v4OFFv4
	if(!isAAS2 && !isAAS4)
		isAAS4 = 1
	endif
	
	// v2v4
	if(isAAS2)
		isAAS4 = 0
	endif
	
	String formatStr = ""
	If(isAAS4)
		formatStr = "AAS v4"
	ElseIf(isAAS2)
		formatStr = "AAS v2"
	Else
		formatStr = "AAS"
	EndIf
	If(isHMM)
		formatStr += " + HMM (n=" + num2str(dstateVal) + ")"
	EndIf
	
	// ========================================
	// Step 0: Load Data
	// ========================================
	Print "\r--- Step 0: Load Data ---"
	Printf "Format: %s\r", formatStr
	
	Variable numLoaded = 0
	If(isAAS4 && isHMM)
		numLoaded = LoadAAS4_HMM_Path(fullPath, SampleName)
	ElseIf(isAAS4 && !isHMM)
		numLoaded = LoadAAS_NoHMM_Path(fullPath, SampleName)
	ElseIf(isAAS2 && isHMM)
		numLoaded = LoadAAS2_HMM_Path(fullPath, SampleName)
	Else
		numLoaded = LoadAAS_NoHMM_Path(fullPath, SampleName)
	EndIf
	
	If(numLoaded == 0)
		Print ": "
		return -1
	EndIf
	
	Printf ": %d cells\r", numLoaded
	
	// 
	CreateFileNameTable(SampleName, fullPath)
	
	// TraceMatrix time base
	Print "Converting time base..."
	MakeTraceMatrixTimeBase(SampleName)
	
	// Analysis Waves
	Print "Creating analysis waves..."
	MakeAnalysisWavesS0(SampleName)
	
	// HMMDstate
	If(isHMM && dstateVal > 0)
		Print "Separating by Dstate..."
		MakeAnalysisWavesHMM(SampleName)
	EndIf
	
	// ========================================
	// Step 0.05: Compare Lower Bound (HMM only)
	// ========================================
	if(isHMM && dstateVal > 0)
		Print "\r--- Step 0.05: Compare Lower Bound ---"
		CompareLowerBound(SampleName)
	endif
	
	// ========================================
	// Step 0.1: Image Loading (if cImage=1)
	// ========================================
	NVAR/Z cImageFlag = root:cImage
	Variable doImage = NVAR_Exists(cImageFlag) ? cImageFlag : 0
	Variable nTifLoaded = 0
	if(doImage)
		Print "\r--- Step 0.1: Load Matching TIF Images ---"
		// Read import mode from tab0 popup
		ControlInfo/W=SMI_MainPanel tab0_importmode
		imgImportMode = V_Value
		if(imgImportMode < 1 || imgImportMode > 2)
			imgImportMode = 1
		endif
		// Use symbolic path "data" created during CSV loading
		NewPath/O/Q data fullPath
		// Get file list from FileNameList wave
		SetDataFolder $("root:" + SampleName)
		Wave/T/Z fnList = FileNameList
		if(WaveExists(fnList))
			csvFileListStr = ""
			for(fi = 0; fi < numpnts(fnList); fi += 1)
				csvFileListStr += fnList[fi] + ";"
			endfor
			// SMLM_LoadMatchingTIF removed (SMI_SMLM.ipf excluded from public release)
		endif
		SetDataFolder root:
		
		// Pixel value extraction removed (SMI_SMLM.ipf excluded from public release)
	endif
	
	// Results
	CreateResultsFolder(SampleName)
	
	// ========================================
	// Step 0.5: Segmentation Split (Seg≥1)
	// ========================================
	NVAR/Z MaxSegment = root:MaxSegment
	Variable doSeg = NVAR_Exists(MaxSegment) && MaxSegment >= 1
	if(doSeg && isAAS2)
		Print "  WARNING: Segmentation requires AAS v4 format (Segment column)."
		Print "  AAS v2 does not contain Segment data. Please set Seg=0 and re-run."
		DoAlert 0, "Segmentation is not available with AAS v2.\rPlease set Seg=0 in the Common tab."
		doSeg = 0
	endif
	if(doSeg)
		Print "\r--- Step 0.5: Segmentation Split ---"
		RunSegmentationSplit(SampleName)
	endif
	
	// 
	// Diffusion
	NVAR/Z cRunMSD = root:cRunMSD
	NVAR/Z cRunStepSize = root:cRunStepSize
	// Intensity
	NVAR/Z cRunIntensity = root:cRunIntensity
	NVAR/Z cRunLP = root:cRunLP
	NVAR/Z cRunDensity = root:cRunDensity
	NVAR/Z cRunMolDensity = root:cRunMolDensity
	// Kinetics
	NVAR/Z cRunOffrate = root:cRunOffrate
	NVAR/Z cRunOnrate = root:cRunOnrate
	NVAR/Z cRunStateTransition = root:cRunStateTransition
	
	Variable doMSD = NVAR_Exists(cRunMSD) ? cRunMSD : 1
	Variable doStepSize = NVAR_Exists(cRunStepSize) ? cRunStepSize : 1
	Variable doIntensity = NVAR_Exists(cRunIntensity) ? cRunIntensity : 1
	Variable doLP = NVAR_Exists(cRunLP) ? cRunLP : 1
	Variable doDensity = NVAR_Exists(cRunDensity) ? cRunDensity : 1
	Variable doMolDensity = NVAR_Exists(cRunMolDensity) ? cRunMolDensity : 1
	Variable doOffrate = NVAR_Exists(cRunOffrate) ? cRunOffrate : 1
	Variable doOnrate = NVAR_Exists(cRunOnrate) ? cRunOnrate : 1
	Variable doStateTransition = NVAR_Exists(cRunStateTransition) ? cRunStateTransition : 1
	
	// ========================================
	// Step 1: Diffusion
	// ========================================
	Print "\r--- Step 1: Diffusion Analysis ---"
	If(doMSD)
		Print "  MSD Analysis..."
		SMI_AnalyzeMSD(SampleName, fitTypeVal)
		// Seg
		if(doSeg)
			Variable segIdx
			for(segIdx = 0; segIdx <= MaxSegment; segIdx += 1)
				String segBase = GetSegmentFolderPath(segIdx)
				String segSuf = GetSegmentSuffix(segIdx)
				Printf "  MSD Analysis (Seg%d)...\r", segIdx
				CalculateMSD(SampleName, basePath=segBase, waveSuffix=segSuf)
				FitMSD_Safe(SampleName, fitTypeVal, basePath=segBase, waveSuffix=segSuf)
				DisplayMSDGraphHMM(SampleName, basePath=segBase, waveSuffix=segSuf)
			endfor
		endif
	Else
		Print "  MSD Analysis [SKIPPED]"
	EndIf
	
	If(doStepSize)
		Print "  Step Size Analysis..."
		SMI_AnalyzeStepSize(SampleName)
		// Seg
		if(doSeg)
			for(segIdx = 0; segIdx <= MaxSegment; segIdx += 1)
				segBase = GetSegmentFolderPath(segIdx)
				segSuf = GetSegmentSuffix(segIdx)
				Printf "  Step Size Analysis (Seg%d)...\r", segIdx
				CalculateStepSizeHistogramHMM(SampleName, basePath=segBase, waveSuffix=segSuf)
				FitStepSizeDistributionHMM(SampleName, 1, basePath=segBase, waveSuffix=segSuf)
				DisplayStepSizeHistogramHMM(SampleName, basePath=segBase, waveSuffix=segSuf)
			endfor
		endif
	Else
		Print "  Step Size Analysis [SKIPPED]"
	EndIf
	
	// ========================================
	// Step 2: Intensity
	// ========================================
	Print "\r--- Step 2: Intensity Analysis ---"
	If(doIntensity)
		Print "  Intensity Histogram..."
		SMI_AnalyzeIntensity(SampleName, maxOligVal)
		// Seg
		if(doSeg)
			// Fix Mean/SD
			NVAR/Z cFixMean = root:cFixMean
			NVAR/Z cFixSD = root:cFixSD
			fixMeanVal = 0
			fixSDVal = 0
			if(NVAR_Exists(cFixMean))
				fixMeanVal = cFixMean
			endif
			if(NVAR_Exists(cFixSD))
				fixSDVal = cFixSD
			endif
			
			for(segIdx = 0; segIdx <= MaxSegment; segIdx += 1)
				segBase = GetSegmentFolderPath(segIdx)
				segSuf = GetSegmentSuffix(segIdx)
				Printf "  Intensity Histogram (Seg%d)...\r", segIdx
				CreateIntensityHistogram(SampleName, basePath=segBase, waveSuffix=segSuf)
				GlobalFitIntensity(SampleName, maxOligVal, fixMeanVal, fixSDVal, basePath=segBase, waveSuffix=segSuf)
				DisplayIntensityHistHMM(SampleName, basePath=segBase, waveSuffix=segSuf)
				// PopulationMean Oligomer SizeCompare
				CalculatePopulationFromCoefEx(SampleName, segBase, segSuf)
			endfor
		endif
	Else
		Print "  Intensity Histogram [SKIPPED]"
	EndIf
	
	If(doLP)
		Print "  Localization Precision..."
		SMI_AnalyzeLP(SampleName)
		// Seg
		if(doSeg)
			for(segIdx = 0; segIdx <= MaxSegment; segIdx += 1)
				segBase = GetSegmentFolderPath(segIdx)
				segSuf = GetSegmentSuffix(segIdx)
				Printf "  Localization Precision (Seg%d)...\r", segIdx
				CalculateLPHistogram(SampleName, basePath=segBase, waveSuffix=segSuf)
				DisplayLPHistogram(SampleName, basePath=segBase, waveSuffix=segSuf)
			endfor
		endif
	Else
		Print "  Localization Precision [SKIPPED]"
	EndIf
	
	If(doDensity)
		Print "  Density Analysis..."
		SMI_AnalyzeDensity(SampleName)
		// Seg
		if(doSeg)
			for(segIdx = 0; segIdx <= MaxSegment; segIdx += 1)
				segBase = GetSegmentFolderPath(segIdx)
				segSuf = GetSegmentSuffix(segIdx)
				Printf "  Density Analysis (Seg%d)...\r", segIdx
				Density_Gcount(SampleName, basePath=segBase, waveSuffix=segSuf)
				DisplayDensityGcount(SampleName, basePath=segBase, waveSuffix=segSuf)
			endfor
		endif
	Else
		Print "  Density Analysis [SKIPPED]"
	EndIf
	
	If(doMolDensity)
		Print "  Molecular Density..."
		SMI_AnalyzeMolDensity(SampleName)
		// Seg
		if(doSeg)
			for(segIdx = 0; segIdx <= MaxSegment; segIdx += 1)
				segBase = GetSegmentFolderPath(segIdx)
				segSuf = GetSegmentSuffix(segIdx)
				Printf "  Molecular Density (Seg%d)...\r", segIdx
				CalculateMolecularDensity(SampleName, basePath=segBase, waveSuffix=segSuf)
				DisplayMolecularDensity(SampleName, basePath=segBase, waveSuffix=segSuf)
			endfor
		endif
	Else
		Print "  Molecular Density [SKIPPED]"
	EndIf
	
	// ========================================
	// Step 3: Kinetics
	// ========================================
	Print "\r--- Step 3: Kinetics Analysis ---"
	If(doOffrate)
		Print "  Off-rate (Duration)..."
		Duration_Gcount(SampleName)
		// Seg
		if(doSeg)
			for(segIdx = 0; segIdx <= MaxSegment; segIdx += 1)
				segBase = GetSegmentFolderPath(segIdx)
				segSuf = GetSegmentSuffix(segIdx)
				Printf "  Off-rate (Duration) (Seg%d)...\r", segIdx
				Duration_Gcount(SampleName, basePath=segBase, waveSuffix=segSuf)
			endfor
		endif
	Else
		Print "  Off-rate (Duration) [SKIPPED]"
	EndIf
	
	If(doOnrate)
		Print "  On-rate..."
		OnrateAnalysisWithOption(SampleName)
		// Seg
		if(doSeg)
			for(segIdx = 0; segIdx <= MaxSegment; segIdx += 1)
				segBase = GetSegmentFolderPath(segIdx)
				segSuf = GetSegmentSuffix(segIdx)
				Printf "  On-rate (Seg%d)...\r", segIdx
				OnrateAnalysisWithOption(SampleName, basePath=segBase, waveSuffix=segSuf)
			endfor
		endif
	Else
		Print "  On-rate [SKIPPED]"
	EndIf
	
	// ========================================
	// Step 3.5: TrajectoryState Transition
	// ========================================
	NVAR/Z cRunTrajectory = root:cRunTrajectory
	Variable doTrajectory = NVAR_Exists(cRunTrajectory) ? cRunTrajectory : 0
	If(doTrajectory)
		Print "\r--- Step 3.5: Trajectory ---"
		Print "  Trajectory (XY Plot)..."
		Trace_HMM(SampleName)
		
		// TIF background overlay removed (SMI_SMLM.ipf excluded from public release)
		
		Print "  Origin-Aligned Trajectory..."
		CreateOriginAlignedTrajectory(SampleName)
		// Seg
		if(doSeg)
			for(segIdx = 0; segIdx <= MaxSegment; segIdx += 1)
				segBase = GetSegmentFolderPath(segIdx)
				segSuf = GetSegmentSuffix(segIdx)
				Printf "  Trajectory (Seg%d)...\r", segIdx
				Trace_HMM(SampleName, basePath=segBase, waveSuffix=segSuf)
				CreateOriginAlignedTrajectory(SampleName, basePath=segBase, waveSuffix=segSuf)
			endfor
		endif
	EndIf
	
	// HMMState Transition
	NVAR/Z cHMM = root:cHMM
	If(NVAR_Exists(cHMM) && cHMM == 1 && doStateTransition)
		Print "\r--- Step 3.6: State Transition Analysis ---"
		RunStateTransitionAnalysis(SampleName)
	Else
		If(NVAR_Exists(cHMM) && cHMM == 1)
			Print "  State Transition Analysis [SKIPPED]"
		EndIf
	EndIf
	
	// ========================================
	// Step 4: Matrix & 
	// ========================================
	Print "\r--- Step 4: Matrix Creation & Statistics ---"
	StatsResultsMatrix("root", SampleName, "")
	// Seg
	if(doSeg)
		for(segIdx = 0; segIdx <= MaxSegment; segIdx += 1)
			segBase = GetSegmentFolderPath(segIdx)
			Printf "  Statistics (Seg%d)...\r", segIdx
			StatsResultsMatrix(segBase, SampleName, "")
		endfor
	endif
	
	Print "\r=========================================="
	Printf ": %s\r", SampleName
	Print "=========================================="
	Printf ": %d\r", numLoaded
	Print "Diffusion: MSD=%s, StepSize=%s", SelectString(doMSD, "OFF", "ON"), SelectString(doStepSize, "OFF", "ON")
	Print "Intensity: Hist=%s, LP=%s, Density=%s, MolDens=%s", SelectString(doIntensity, "OFF", "ON"), SelectString(doLP, "OFF", "ON"), SelectString(doDensity, "OFF", "ON"), SelectString(doMolDensity, "OFF", "ON")
	Print "Kinetics: Off-rate=%s, On-rate=%s", SelectString(doOffrate, "OFF", "ON"), SelectString(doOnrate, "OFF", "ON")
	Print "Trajectory: %s", SelectString(doTrajectory, "OFF", "ON")
	Print ":"
	Printf "  Matrix: root:%s:Matrix\r", SampleName
	Printf "  : root:%s:Results\r", SampleName
	Print "==========================================\r"
	
	// SampleName
	String/G root:gCurrentSampleName = SampleName
	
	return numLoaded
End

// -----------------------------------------------------------------------------
// ReanalyzeSingleSample - Same as SingleSampleAnalysis but skips Load (Step 0)
// Uses existing data in Igor data folders (TraceMatrix + analysis waves).
// Called by ReanalyzeAllProc for _rand folders and other pre-loaded data.
// -----------------------------------------------------------------------------
Function ReanalyzeSingleSample(SampleName)
	String SampleName

	Print "=========================================="
	Printf "Reanalyze Sample: %s\r", SampleName
	Print "=========================================="

	// Verify sample folder exists and has cell subfolders
	if(!DataFolderExists("root:" + SampleName))
		Printf "ReanalyzeSingleSample: folder not found - %s\r", SampleName
		return -1
	endif

	Variable numLoaded = CountDataFolders(SampleName)
	if(numLoaded <= 0)
		Printf "ReanalyzeSingleSample: no cell subfolders in %s\r", SampleName
		return -1
	endif
	Printf "Found %d cells in %s\r", numLoaded, SampleName

	// Read checkbox settings (same as SingleSampleAnalysis)
	NVAR/Z cHMM = root:cHMM
	NVAR Dstate = root:Dstate
	NVAR maxOlig = root:MaxOligomerSize
	NVAR fitType = root:FitType
	NVAR maxExp = root:ExpMax_off

	Variable isHMM = NVAR_Exists(cHMM) ? cHMM : 1
	Variable dstateVal = Dstate
	Variable maxOligVal = maxOlig
	Variable fitTypeVal = fitType
	Variable maxExpVal = maxExp
	Variable fixMeanVal, fixSDVal

	SetCurrentSampleName(SampleName)

	// Create Results folder if missing
	CreateResultsFolder(SampleName)

	// ========================================
	// Step 0.5: Segmentation Split
	// ========================================
	NVAR/Z MaxSegment = root:MaxSegment
	Variable doSeg = NVAR_Exists(MaxSegment) && MaxSegment >= 1
	if(doSeg)
		Print "\r--- Step 0.5: Segmentation Split ---"
		RunSegmentationSplit(SampleName)
	endif

	// Read analysis checkboxes
	NVAR/Z cRunMSD = root:cRunMSD
	NVAR/Z cRunStepSize = root:cRunStepSize
	NVAR/Z cRunIntensity = root:cRunIntensity
	NVAR/Z cRunLP = root:cRunLP
	NVAR/Z cRunDensity = root:cRunDensity
	NVAR/Z cRunMolDensity = root:cRunMolDensity
	NVAR/Z cRunOffrate = root:cRunOffrate
	NVAR/Z cRunOnrate = root:cRunOnrate
	NVAR/Z cRunStateTransition = root:cRunStateTransition

	Variable doMSD = NVAR_Exists(cRunMSD) ? cRunMSD : 1
	Variable doStepSize = NVAR_Exists(cRunStepSize) ? cRunStepSize : 1
	Variable doIntensity = NVAR_Exists(cRunIntensity) ? cRunIntensity : 1
	Variable doLP = NVAR_Exists(cRunLP) ? cRunLP : 1
	Variable doDensity = NVAR_Exists(cRunDensity) ? cRunDensity : 1
	Variable doMolDensity = NVAR_Exists(cRunMolDensity) ? cRunMolDensity : 1
	Variable doOffrate = NVAR_Exists(cRunOffrate) ? cRunOffrate : 1
	Variable doOnrate = NVAR_Exists(cRunOnrate) ? cRunOnrate : 1
	Variable doStateTransition = NVAR_Exists(cRunStateTransition) ? cRunStateTransition : 1

	// ========================================
	// Step 1: Diffusion
	// ========================================
	Print "\r--- Step 1: Diffusion Analysis ---"
	Variable segIdx
	String segBase, segSuf
	If(doMSD)
		Print "  MSD Analysis..."
		SMI_AnalyzeMSD(SampleName, fitTypeVal)
		if(doSeg)
			for(segIdx = 0; segIdx <= MaxSegment; segIdx += 1)
				segBase = GetSegmentFolderPath(segIdx)
				segSuf = GetSegmentSuffix(segIdx)
				Printf "  MSD Analysis (Seg%d)...\r", segIdx
				CalculateMSD(SampleName, basePath=segBase, waveSuffix=segSuf)
				FitMSD_Safe(SampleName, fitTypeVal, basePath=segBase, waveSuffix=segSuf)
				DisplayMSDGraphHMM(SampleName, basePath=segBase, waveSuffix=segSuf)
			endfor
		endif
	Else
		Print "  MSD Analysis [SKIPPED]"
	EndIf

	If(doStepSize)
		Print "  Step Size Analysis..."
		SMI_AnalyzeStepSize(SampleName)
		if(doSeg)
			for(segIdx = 0; segIdx <= MaxSegment; segIdx += 1)
				segBase = GetSegmentFolderPath(segIdx)
				segSuf = GetSegmentSuffix(segIdx)
				Printf "  Step Size Analysis (Seg%d)...\r", segIdx
				CalculateStepSizeHistogramHMM(SampleName, basePath=segBase, waveSuffix=segSuf)
				FitStepSizeDistributionHMM(SampleName, 1, basePath=segBase, waveSuffix=segSuf)
				DisplayStepSizeHistogramHMM(SampleName, basePath=segBase, waveSuffix=segSuf)
			endfor
		endif
	Else
		Print "  Step Size Analysis [SKIPPED]"
	EndIf

	// ========================================
	// Step 2: Intensity
	// ========================================
	Print "\r--- Step 2: Intensity Analysis ---"
	If(doIntensity)
		Print "  Intensity Histogram..."
		SMI_AnalyzeIntensity(SampleName, maxOligVal)
		if(doSeg)
			NVAR/Z cFixMean = root:cFixMean
			NVAR/Z cFixSD = root:cFixSD
			fixMeanVal = 0
			fixSDVal = 0
			if(NVAR_Exists(cFixMean))
				fixMeanVal = cFixMean
			endif
			if(NVAR_Exists(cFixSD))
				fixSDVal = cFixSD
			endif
			for(segIdx = 0; segIdx <= MaxSegment; segIdx += 1)
				segBase = GetSegmentFolderPath(segIdx)
				segSuf = GetSegmentSuffix(segIdx)
				Printf "  Intensity Histogram (Seg%d)...\r", segIdx
				CreateIntensityHistogram(SampleName, basePath=segBase, waveSuffix=segSuf)
				GlobalFitIntensity(SampleName, maxOligVal, fixMeanVal, fixSDVal, basePath=segBase, waveSuffix=segSuf)
				DisplayIntensityHistHMM(SampleName, basePath=segBase, waveSuffix=segSuf)
				CalculatePopulationFromCoefEx(SampleName, segBase, segSuf)
			endfor
		endif
	Else
		Print "  Intensity Histogram [SKIPPED]"
	EndIf

	If(doLP)
		Print "  Localization Precision..."
		SMI_AnalyzeLP(SampleName)
		if(doSeg)
			for(segIdx = 0; segIdx <= MaxSegment; segIdx += 1)
				segBase = GetSegmentFolderPath(segIdx)
				segSuf = GetSegmentSuffix(segIdx)
				Printf "  Localization Precision (Seg%d)...\r", segIdx
				CalculateLPHistogram(SampleName, basePath=segBase, waveSuffix=segSuf)
				DisplayLPHistogram(SampleName, basePath=segBase, waveSuffix=segSuf)
			endfor
		endif
	Else
		Print "  Localization Precision [SKIPPED]"
	EndIf

	If(doDensity)
		Print "  Density Analysis..."
		SMI_AnalyzeDensity(SampleName)
		if(doSeg)
			for(segIdx = 0; segIdx <= MaxSegment; segIdx += 1)
				segBase = GetSegmentFolderPath(segIdx)
				segSuf = GetSegmentSuffix(segIdx)
				Printf "  Density Analysis (Seg%d)...\r", segIdx
				Density_Gcount(SampleName, basePath=segBase, waveSuffix=segSuf)
				DisplayDensityGcount(SampleName, basePath=segBase, waveSuffix=segSuf)
			endfor
		endif
	Else
		Print "  Density Analysis [SKIPPED]"
	EndIf

	If(doMolDensity)
		Print "  Molecular Density..."
		SMI_AnalyzeMolDensity(SampleName)
		if(doSeg)
			for(segIdx = 0; segIdx <= MaxSegment; segIdx += 1)
				segBase = GetSegmentFolderPath(segIdx)
				segSuf = GetSegmentSuffix(segIdx)
				Printf "  Molecular Density (Seg%d)...\r", segIdx
				CalculateMolecularDensity(SampleName, basePath=segBase, waveSuffix=segSuf)
				DisplayMolecularDensity(SampleName, basePath=segBase, waveSuffix=segSuf)
			endfor
		endif
	Else
		Print "  Molecular Density [SKIPPED]"
	EndIf

	// ========================================
	// Step 3: Kinetics
	// ========================================
	Print "\r--- Step 3: Kinetics Analysis ---"
	If(doOffrate)
		Print "  Off-rate (Duration)..."
		Duration_Gcount(SampleName)
		if(doSeg)
			for(segIdx = 0; segIdx <= MaxSegment; segIdx += 1)
				segBase = GetSegmentFolderPath(segIdx)
				segSuf = GetSegmentSuffix(segIdx)
				Printf "  Off-rate (Duration) (Seg%d)...\r", segIdx
				Duration_Gcount(SampleName, basePath=segBase, waveSuffix=segSuf)
			endfor
		endif
	Else
		Print "  Off-rate (Duration) [SKIPPED]"
	EndIf

	If(doOnrate)
		Print "  On-rate..."
		OnrateAnalysisWithOption(SampleName)
		if(doSeg)
			for(segIdx = 0; segIdx <= MaxSegment; segIdx += 1)
				segBase = GetSegmentFolderPath(segIdx)
				segSuf = GetSegmentSuffix(segIdx)
				Printf "  On-rate (Seg%d)...\r", segIdx
				OnrateAnalysisWithOption(SampleName, basePath=segBase, waveSuffix=segSuf)
			endfor
		endif
	Else
		Print "  On-rate [SKIPPED]"
	EndIf

	// ========================================
	// Step 3.5: Trajectory & State Transition
	// ========================================
	NVAR/Z cRunTrajectory = root:cRunTrajectory
	Variable doTrajectory = NVAR_Exists(cRunTrajectory) ? cRunTrajectory : 0
	If(doTrajectory)
		Print "\r--- Step 3.5: Trajectory ---"
		Trace_HMM(SampleName)
		CreateOriginAlignedTrajectory(SampleName)
		if(doSeg)
			for(segIdx = 0; segIdx <= MaxSegment; segIdx += 1)
				segBase = GetSegmentFolderPath(segIdx)
				segSuf = GetSegmentSuffix(segIdx)
				Printf "  Trajectory (Seg%d)...\r", segIdx
				Trace_HMM(SampleName, basePath=segBase, waveSuffix=segSuf)
				CreateOriginAlignedTrajectory(SampleName, basePath=segBase, waveSuffix=segSuf)
			endfor
		endif
	EndIf

	If(NVAR_Exists(cHMM) && cHMM == 1 && doStateTransition)
		Print "\r--- Step 3.6: State Transition Analysis ---"
		RunStateTransitionAnalysis(SampleName)
	EndIf

	// ========================================
	// Step 4: Matrix & Statistics
	// ========================================
	Print "\r--- Step 4: Matrix Creation & Statistics ---"
	StatsResultsMatrix("root", SampleName, "")
	if(doSeg)
		for(segIdx = 0; segIdx <= MaxSegment; segIdx += 1)
			segBase = GetSegmentFolderPath(segIdx)
			Printf "  Statistics (Seg%d)...\r", segIdx
			StatsResultsMatrix(segBase, SampleName, "")
		endfor
	endif

	Print "\r=========================================="
	Printf "Reanalyze Complete: %s (%d cells)\r", SampleName, numLoaded
	Print "=========================================="

	String/G root:gCurrentSampleName = SampleName
	return numLoaded
End

// -----------------------------------------------------------------------------
// BatchAutoAnalysis - 
// -----------------------------------------------------------------------------
// SingleSampleAnalysis
// -----------------------------------------------------------------------------
Function BatchAutoAnalysis(parentPath)
	String parentPath
	
	// 
	Variable len = strlen(parentPath)
	If(len > 0)
		String lastChar = parentPath[len-1]
		If(!StringMatch(lastChar, ":") && !StringMatch(lastChar, "/") && !StringMatch(lastChar, "\\"))
			// Mac/Unix
			If(StringMatch(parentPath, "*/*"))
				parentPath += "/"
			// Windows
			ElseIf(StringMatch(parentPath, "*\\*"))
				parentPath += "\\"
			// Igor
			Else
				parentPath += ":"
			EndIf
		EndIf
	EndIf
	
	// 
	NewPath/O/Q parentFolder parentPath
	
	// 
	String folderList = IndexedDir(parentFolder, -1, 0)
	Variable numFolders = ItemsInList(folderList)
	
	If(numFolders == 0)
		Printf ": : %s\r", parentPath
		return -1
	EndIf
	
	Printf ": %d\r", numFolders
	
	// 
	Make/O/T/N=(numFolders) root:BatchSampleList
	Wave/T BatchSampleList = root:BatchSampleList
	
	Variable i
	String folderName, subFolderPath, sampleName
	Variable successCount = 0
	
	For(i = 0; i < numFolders; i += 1)
		folderName = StringFromList(i, folderList)
		
		// CSV
		// Mac/Unix
		If(StringMatch(parentPath, "*/*"))
			subFolderPath = parentPath + folderName + "/"
		// Windows
		ElseIf(StringMatch(parentPath, "*\\*"))
			subFolderPath = parentPath + folderName + "\\"
		// Igor
		Else
			subFolderPath = parentPath + folderName + ":"
		EndIf
		
		NewPath/O/Q tempPath subFolderPath
		String csvList = IndexedFile(tempPath, -1, ".csv")
		
		If(ItemsInList(csvList) == 0)
			Printf "  : %s (CSV)\r", folderName
			BatchSampleList[i] = folderName + " (skipped)"
			continue
		EndIf
		
		// SampleName
		sampleName = CleanSampleName(folderName)
		BatchSampleList[i] = sampleName
		
		Printf "\r========== [%d/%d] %s ==========\r", i+1, numFolders, sampleName
		
		// SingleSampleAnalysis
		Variable result
		result = SingleSampleAnalysis(subFolderPath, sampleName)
		
		If(result > 0)
			successCount += 1
		EndIf
	EndFor
	
	// 
	DoWindow/K BatchResultTable
	Edit/K=1/N=BatchResultTable BatchSampleList as "Batch Analysis Results"
	ModifyTable/W=BatchResultTable width(BatchSampleList)=200
	ModifyTable/W=BatchResultTable title(BatchSampleList)="Sample Name"
	
	Printf "\r==========================================\r"
	Printf "Batch Analysis\r"
	Printf ": %d / %d \r", successCount, numFolders
	Printf "==========================================\r"
	
	return successCount
End

// AutoAnalysisSingleSampleAnalysis
