#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3
#pragma version=2.1
// ModuleName - 

// =============================================================================
// SMI_Intensity.ipf - Intensity Analysis Module
// =============================================================================
// Ripley K
// Version 2.0 - Refactored
// =============================================================================

// -----------------------------------------------------------------------------
// DensityEstimation - 
// Xum_frame, Yum_frame wave
// -----------------------------------------------------------------------------
Function DensityEstimation(XumWaveName, YumWaveName)
	String XumWaveName, YumWaveName
	
	Wave Xum_frame = $XumWaveName
	Wave Yum_frame = $YumWaveName
	
	// 
	String folderPath = ParseFilePath(1, XumWaveName, ":", 1, 0)
	if(strlen(folderPath) == 0)
		folderPath = GetDataFolder(1)  // 
	endif
	
	NVAR RHistBin = root:RHistBin
	NVAR RHistDim = root:RHistDim
	NVAR DSmoothing = root:DSmoothing
	
	Variable MaxPoint = numpnts(Xum_frame)
	Variable i, r
	
	if(MaxPoint < 2)
		// NaN
		Make/O/N=5 $(folderPath + "ParaDensity") = NaN
		Make/O/N=(RHistDim) $(folderPath + "logAvgD_r") = NaN
		Make/O/N=(RHistDim) $(folderPath + "dlogAvgD_r") = NaN
		Make/O/N=(RHistDim) $(folderPath + "logR_r") = NaN
		return 0
	endif
	
	// i
	Make/O/N=(MaxPoint, MaxPoint) $(folderPath + "MatrixDistance") = 0
	Wave MatrixDistance = $(folderPath + "MatrixDistance")
	for(i = 0; i < MaxPoint; i += 1)
		MatrixDistance[][i] = sqrt((Xum_frame[p] - Xum_frame[i])^2 + (Yum_frame[p] - Yum_frame[i])^2)
	endfor
	
	// 
	Make/N=(RHistDim)/O $(folderPath + "MatrixDistance_Hist") = 0
	Wave MatrixDistance_Hist = $(folderPath + "MatrixDistance_Hist")
	Histogram/B={0, RHistBin, RHistDim} MatrixDistance, MatrixDistance_Hist
	
	// wave
	Make/O/N=(RHistDim) $(folderPath + "R_r") = 0
	Make/O/N=(RHistDim) $(folderPath + "AvgN_r") = 0
	Make/O/N=(RHistDim) $(folderPath + "AvgD_r") = 0
	Make/O/N=(RHistDim) $(folderPath + "logAvgD_r") = 0
	Make/O/N=(RHistDim) $(folderPath + "dlogAvgD_r") = 0
	Make/O/N=(RHistDim) $(folderPath + "logR_r") = 0
	Make/O/N=(RHistDim) $(folderPath + "dlogR_r") = 0
	Make/O/N=(RHistDim) $(folderPath + "Area_r") = 0
	
	Wave R_r = $(folderPath + "R_r")
	Wave AvgN_r = $(folderPath + "AvgN_r")
	Wave AvgD_r = $(folderPath + "AvgD_r")
	Wave logAvgD_r = $(folderPath + "logAvgD_r")
	Wave dlogAvgD_r = $(folderPath + "dlogAvgD_r")
	Wave logR_r = $(folderPath + "logR_r")
	Wave dlogR_r = $(folderPath + "dlogR_r")
	Wave Area_r = $(folderPath + "Area_r")
	
	// R_r, logR_r, dlogR_r 
	R_r = RHistBin * (p + 1)
	logR_r = log(R_r)
	dlogR_r[0, RHistDim-2] = logR_r[p+1] - logR_r[p]
	dlogR_r[RHistDim-1] = NaN
	
	// r
	Variable Sum_t0N = 0
	Variable Rum
	for(r = 0; r < RHistDim; r += 1)
		Rum = (r + 1) * RHistBin
		Area_r[r] = pi * Rum^2
		Sum_t0N += MatrixDistance_Hist[r]
		AvgN_r[r] = Sum_t0N / MaxPoint
	endfor
	
	// 
	AvgD_r = AvgN_r / Area_r
	logAvgD_r = log(AvgD_r)
	
	// dlogAvgD_r logAvgD_r 
	dlogAvgD_r[0, RHistDim-2] = (logAvgD_r[p+1] - logAvgD_r[p]) / dlogR_r[p]
	dlogAvgD_r[RHistDim-1] = NaN
	
	// dlogAvgD_r 3i
	for(i = 0; i < DSmoothing; i += 1)
		dlogAvgD_r[1, RHistDim-2] = (dlogAvgD_r[p-1] + dlogAvgD_r[p] + dlogAvgD_r[p+1]) / 3
	endfor
	
	// RmaxD: logAvgD_r  r 
	FindPeak/Q/P/B=10 dlogAvgD_r
	Variable RmaxD = round(V_PeakLoc)
	if(RmaxD < 1 || numtype(RmaxD) != 0)
		RmaxD = 1
	endif
	if(RmaxD >= RHistDim)
		RmaxD = RHistDim - 1
	endif
	
	Variable GlobalAvgD = AvgD_r[RmaxD]
	Variable GlobalArea = MaxPoint / GlobalAvgD
	
	// : NumPoints, Area, Density, RmaxD, RmaxD[um]
	Make/O/N=5 $(folderPath + "ParaDensity") = {MaxPoint, GlobalArea, GlobalAvgD, RmaxD, RmaxD * RHistBin}
	
	return 1
End

// -----------------------------------------------------------------------------
// Density_Gcount - Ripley K
// TotalDensityAnalysis_Gcount
// -----------------------------------------------------------------------------
Function Density_Gcount(SampleName, [basePath, waveSuffix])
	String SampleName
	String basePath, waveSuffix
	
	// 
	if(ParamIsDefault(basePath))
		basePath = "root"
	endif
	if(ParamIsDefault(waveSuffix))
		waveSuffix = ""
	endif
	
	NVAR scale = root:scale
	NVAR framerate = root:framerate
	NVAR RHistBin = root:RHistBin
	NVAR RHistDim = root:RHistDim
	NVAR DSmoothing = root:DSmoothing
	NVAR DensityStartFrame = root:DensityStartFrame
	NVAR DensityEndFrame = root:DensityEndFrame
	Variable StartFrame = DensityStartFrame
	Variable EndFrame = DensityEndFrame

	Variable range = EndFrame - StartFrame + 1

	Variable numFolders
	if(StringMatch(basePath, "root"))
		numFolders = CountDataFolders(SampleName)
	else
		numFolders = CountDataFoldersInPath(basePath, SampleName)
	endif
	
	Variable m, frame, framepoints, totalpoints
	String FolderName, folderPath
	
	// samplePath
	String samplePath
	if(StringMatch(basePath, "root"))
		samplePath = "root:" + SampleName
	else
		samplePath = basePath + ":" + SampleName
	endif
	
	Print "=== Density Analysis (Ripley K-function) ==="
	Printf "Analysis range: %d-%d frames (range=%d)\r", StartFrame, EndFrame, range
	Printf "RHistBin: %.4f um, RHistDim: %d, DSmoothing: %d\r", RHistBin, RHistDim, DSmoothing
	
	// 
	for(m = 0; m < numFolders; m += 1)
		FolderName = SampleName + num2str(m + 1)
		folderPath = samplePath + ":" + FolderName + ":"
		
		if(!DataFolderExists(samplePath + ":" + FolderName))
			continue
		endif
		
		SetDataFolder $(samplePath + ":" + FolderName)
		
		Printf "\n  Processing %s...\r", FolderName
		
		// S0waveSuffix
		String roiName = "ROI_S0" + waveSuffix
		String rtimeName = "Rtime_S0" + waveSuffix
		String rframeName = "Rframe_S0" + waveSuffix
		String xumName = "Xum_S0" + waveSuffix
		String yumName = "Yum_S0" + waveSuffix
		String intName = "Int_S0" + waveSuffix
		
		Wave/Z ROI_S0 = $(folderPath + roiName)
		Wave/Z Rtime_S0 = $(folderPath + rtimeName)
		Wave/Z Rframe_S0 = $(folderPath + rframeName)
		Wave/Z Xum_S0 = $(folderPath + xumName)
		Wave/Z Yum_S0 = $(folderPath + yumName)
		Wave/Z Int_S0 = $(folderPath + intName)
		
		if(!WaveExists(ROI_S0) || !WaveExists(Rtime_S0) || !WaveExists(Xum_S0) || !WaveExists(Yum_S0))
			Printf "    WARNING: Required waves not found, skipping\r"
			continue
		endif
		
		totalpoints = numpnts(Xum_S0)
		
		// Rtime_S0
		WaveStats/Q Rtime_S0
		Printf "    Total points: %d, Rtime_S0 range: %.0f - %.0f\r", totalpoints, V_min, V_max
		
		// frame
		Make/O/N=(5, range) $(folderPath + "MatrixParaDensity") = NaN
		Make/O/N=(RHistDim, range) $(folderPath + "MatrixlogAvgD_r") = NaN
		Make/O/N=(RHistDim, range) $(folderPath + "MatrixdlogAvgD_r") = NaN
		Make/O/N=(totalpoints, range) $(folderPath + "MatrixXum_frame") = NaN
		Make/O/N=(totalpoints, range) $(folderPath + "MatrixYum_frame") = NaN
		
		Wave MatrixParaDensity = $(folderPath + "MatrixParaDensity")
		Wave MatrixlogAvgD_r = $(folderPath + "MatrixlogAvgD_r")
		Wave MatrixdlogAvgD_r = $(folderPath + "MatrixdlogAvgD_r")
		Wave MatrixXum_frame = $(folderPath + "MatrixXum_frame")
		Wave MatrixYum_frame = $(folderPath + "MatrixYum_frame")
		
		// 
		for(frame = StartFrame; frame <= EndFrame; frame += 1)
			// Rtime_S0 == framef
			// Extract
			Extract/O ROI_S0, $(folderPath + "ROI_frame"), Rtime_S0 == frame
			Extract/O Rtime_S0, $(folderPath + "Rtime_frame"), Rtime_S0 == frame
			Extract/O Rframe_S0, $(folderPath + "Rframe_frame"), Rtime_S0 == frame
			Extract/O Xum_S0, $(folderPath + "Xum_frame"), Rtime_S0 == frame
			Extract/O Yum_S0, $(folderPath + "Yum_frame"), Rtime_S0 == frame
			Extract/O Int_S0, $(folderPath + "Int_frame"), Rtime_S0 == frame
			
			Wave Xum_frame = $(folderPath + "Xum_frame")
			Wave Yum_frame = $(folderPath + "Yum_frame")
			
			framepoints = numpnts(Xum_frame)
			
			if(framepoints >= 2)
				// wave
				DensityEstimation(folderPath + "Xum_frame", folderPath + "Yum_frame")
				
				// 
				Wave ParaDensity = $(folderPath + "ParaDensity")
				Wave logAvgD_r = $(folderPath + "logAvgD_r")
				Wave dlogAvgD_r = $(folderPath + "dlogAvgD_r")
				
				MatrixParaDensity[][frame - StartFrame] = ParaDensity[p]
				MatrixlogAvgD_r[][frame - StartFrame] = logAvgD_r[p]
				MatrixdlogAvgD_r[][frame - StartFrame] = dlogAvgD_r[p]
				
				// XY
				MatrixXum_frame[0, framepoints-1][frame - StartFrame] = Xum_frame[p]
				MatrixYum_frame[0, framepoints-1][frame - StartFrame] = Yum_frame[p]
			endif
		endfor
		
		// 
		Make/O/N=(range) $(folderPath + "Wtime")
		Make/O/N=(range) $(folderPath + "MaxPoint_t")
		Make/O/N=(range) $(folderPath + "Density_t")
		Make/O/N=(range) $(folderPath + "Area_t")
		Make/O/N=(range) $(folderPath + "RmaxD_t")
		
		Wave Wtime = $(folderPath + "Wtime")
		Wave MaxPoint_t = $(folderPath + "MaxPoint_t")
		Wave Density_t = $(folderPath + "Density_t")
		Wave Area_t = $(folderPath + "Area_t")
		Wave RmaxD_t = $(folderPath + "RmaxD_t")
		
		Wtime = (StartFrame + p) * framerate
		
		for(frame = StartFrame; frame <= EndFrame; frame += 1)
			MaxPoint_t[frame - StartFrame] = MatrixParaDensity[0][frame - StartFrame]
			Area_t[frame - StartFrame] = MatrixParaDensity[1][frame - StartFrame]
			Density_t[frame - StartFrame] = MatrixParaDensity[2][frame - StartFrame]
			RmaxD_t[frame - StartFrame] = MatrixParaDensity[3][frame - StartFrame]
		endfor
		
		// 
		Variable MeanNumPoints = mean(MaxPoint_t)
		Variable MeanGlobalArea = mean(Area_t)
		Variable MeanGlobalDensity = mean(Density_t)
		Variable MeanRmaxD = mean(RmaxD_t)
		
		Printf "    Mean NumPoints: %.1f\r", MeanNumPoints
		Printf "    Mean Area: %.2f um²\r", MeanGlobalArea
		Printf "    Mean Density: %.4f /um²\r", MeanGlobalDensity
		Printf "    Mean RmaxD: %.1f (%.4f um)\r", MeanRmaxD, MeanRmaxD * RHistBin
		
		// 
		Make/O/T/N=5 $(folderPath + "TxtParaDensity") = {"NumPoints", "Area", "Density", "RmaxD", "um"}
		Make/O/N=5 $(folderPath + "ParaDensityAvg") = {MeanNumPoints, MeanGlobalArea, MeanGlobalDensity, MeanRmaxD, MeanRmaxD * RHistBin}
		
		Wave/T TxtParaDensity = $(folderPath + "TxtParaDensity")
		Wave ParaDensityAvg = $(folderPath + "ParaDensityAvg")
		
		// 
		Edit/K=1 TxtParaDensity, ParaDensityAvg
		DoWindow/T kwTopWin, FolderName + " Density Parameters"
	endfor
	
	// ========================================
	// ParticleDensity_Dstate 
	// ParticleDensity_Dstate[0] = ParticleDensity
	// ParticleDensity_Dstate[s] = ParticleDensity[0] * HMMP[s]/100 (s>=1)
	// ========================================
	CalculateParticleDensityByState(SampleName, basePath=basePath, waveSuffix=waveSuffix)
	
	SetDataFolder root:
	Print "\nDensity analysis complete"
End

// -----------------------------------------------------------------------------
// CalculateParticleDensityByState - HMMPParticle Density
// ParticleDensity_Dstate[s] = ParticleDensity × HMMP[s]/100
// HMMP[0]=100%, HMMP[s]=s(%)
// ΣParticleDensity_Dstate[1:n] = ParticleDensity_Dstate[0]
// -----------------------------------------------------------------------------
Function CalculateParticleDensityByState(SampleName, [basePath, waveSuffix])
	String SampleName
	String basePath, waveSuffix
	
	// 
	if(ParamIsDefault(basePath))
		basePath = "root"
	endif
	if(ParamIsDefault(waveSuffix))
		waveSuffix = ""
	endif
	
	NVAR/Z Dstate = root:Dstate
	NVAR/Z cHMM = root:cHMM
	
	Variable maxState = 0
	if(NVAR_Exists(cHMM) && cHMM == 1 && NVAR_Exists(Dstate))
		maxState = Dstate
	endif
	
	Variable numFolders
	if(StringMatch(basePath, "root"))
		numFolders = CountDataFolders(SampleName)
	else
		numFolders = CountDataFoldersInPath(basePath, SampleName)
	endif
	
	Variable m, s
	String FolderName, folderPath
	
	// samplePath
	String samplePath
	if(StringMatch(basePath, "root"))
		samplePath = "root:" + SampleName
	else
		samplePath = basePath + ":" + SampleName
	endif
	
	Print "  Calculating Particle Density by D-state..."
	
	for(m = 0; m < numFolders; m += 1)
		FolderName = SampleName + num2str(m + 1)
		folderPath = samplePath + ":" + FolderName + ":"
		
		if(!DataFolderExists(samplePath + ":" + FolderName))
			continue
		endif
		
		SetDataFolder $(samplePath + ":" + FolderName)
		
		// ParaDensityAvgParticle Density
		Wave/Z ParaDensityAvg = $(folderPath + "ParaDensityAvg")
		if(!WaveExists(ParaDensityAvg))
			continue
		endif
		Variable totalDensity = ParaDensityAvg[2]  // Particle Density
		
		// ParticleDensity_Dstate
		Make/O/N=(maxState + 1) $(folderPath + "ParticleDensity_Dstate") = 0
		Wave ParticleDensity_Dstate = $(folderPath + "ParticleDensity_Dstate")
		
		// HMMPwaveSuffix
		// HMMP[0]=100% (), HMMP[s]=s(%)
		if(maxState > 0)
			String hmmpName = "HMMP" + waveSuffix
			Wave/Z HMMP = $(folderPath + hmmpName)
			if(WaveExists(HMMP))
				for(s = 0; s <= maxState; s += 1)
					if(s < numpnts(HMMP))
						ParticleDensity_Dstate[s] = totalDensity * HMMP[s] / 100
					endif
				endfor
			else
				// HMMPDstate_S0
				ParticleDensity_Dstate[0] = totalDensity  // S0 = 
				String dstateName = "Dstate_S0" + waveSuffix
				Wave/Z Dstate_S0 = $(folderPath + dstateName)
				if(WaveExists(Dstate_S0))
					Variable totalPts = numpnts(Dstate_S0)
					Variable cnt, i
					for(s = 1; s <= maxState; s += 1)
						cnt = 0
						for(i = 0; i < totalPts; i += 1)
							if(numtype(Dstate_S0[i]) == 0 && Dstate_S0[i] == s)
								cnt += 1
							endif
						endfor
						Variable fraction = cnt / totalPts
						ParticleDensity_Dstate[s] = totalDensity * fraction
					endfor
				endif
			endif
		else
			// HMMS0
			ParticleDensity_Dstate[0] = totalDensity
		endif
		
		Printf "    %s: ", FolderName
		for(s = 0; s <= maxState; s += 1)
			Printf "S%d=%.4f ", s, ParticleDensity_Dstate[s]
		endfor
		Printf "/µm²\r"
	endfor
	
	// Matrix/Results
	CollectParticleDensityToMatrix(SampleName, maxState, basePath=basePath)
	
	SetDataFolder root:
End

// -----------------------------------------------------------------------------
// CollectParticleDensityToMatrix - ParticleDensity_DstateMatrix/Results
// -----------------------------------------------------------------------------
Function CollectParticleDensityToMatrix(SampleName, maxState, [basePath])
	String SampleName
	Variable maxState
	String basePath
	
	// 
	if(ParamIsDefault(basePath))
		basePath = "root"
	endif
	
	Variable numFolders
	if(StringMatch(basePath, "root"))
		numFolders = CountDataFolders(SampleName)
	else
		numFolders = CountDataFoldersInPath(basePath, SampleName)
	endif
	
	Variable m, s
	String FolderName
	
	// samplePath
	String samplePath
	if(StringMatch(basePath, "root"))
		samplePath = "root:" + SampleName
	else
		samplePath = basePath + ":" + SampleName
	endif
	
	// Matrix
	String matrixPath = samplePath + ":Matrix"
	if(!DataFolderExists(matrixPath))
		NewDataFolder $matrixPath
	endif
	
	// ParticleDensity_Dstate_m: [state][cell]
	SetDataFolder $matrixPath
	Make/O/N=(maxState + 1, numFolders) ParticleDensity_Dstate_m = NaN
	Wave densMatrix = ParticleDensity_Dstate_m
	
	// ParticleDensity_Dstate
	for(m = 0; m < numFolders; m += 1)
		FolderName = SampleName + num2str(m + 1)
		String densPath = samplePath + ":" + FolderName + ":ParticleDensity_Dstate"
		Wave/Z cellDens = $densPath
		
		if(WaveExists(cellDens))
			for(s = 0; s <= maxState; s += 1)
				if(s < numpnts(cellDens))
					densMatrix[s][m] = cellDens[s]
				endif
			endfor
		endif
	endfor
	
	// Results
	String resultsPath = samplePath + ":Results"
	if(!DataFolderExists(resultsPath))
		NewDataFolder $resultsPath
	endif
	SetDataFolder $resultsPath
	
	// 
	Make/O/N=(maxState + 1) ParticleDensity_Dstate_m_avg = NaN
	Make/O/N=(maxState + 1) ParticleDensity_Dstate_m_sd = NaN
	Make/O/N=(maxState + 1) ParticleDensity_Dstate_m_sem = NaN
	Make/O/N=(maxState + 1) ParticleDensity_Dstate_m_n = NaN
	
	Wave avgW = ParticleDensity_Dstate_m_avg
	Wave sdW = ParticleDensity_Dstate_m_sd
	Wave semW = ParticleDensity_Dstate_m_sem
	Wave nW = ParticleDensity_Dstate_m_n
	
	for(s = 0; s <= maxState; s += 1)
		Make/FREE/N=(numFolders) tempData
		Variable k, validCount = 0
		for(k = 0; k < numFolders; k += 1)
			Variable val = densMatrix[s][k]
			if(numtype(val) == 0)
				tempData[validCount] = val
				validCount += 1
			endif
		endfor
		
		if(validCount > 0)
			Redimension/N=(validCount) tempData
			WaveStats/Q tempData
			avgW[s] = V_avg
			sdW[s] = V_sdev
			nW[s] = V_npnts
			if(V_npnts > 1)
				semW[s] = V_sdev / sqrt(V_npnts)
			else
				semW[s] = 0
			endif
		endif
	endfor
	
	SetDataFolder root:
	Print "  ParticleDensity_Dstate_m and statistics created in Matrix/Results"
End

// -----------------------------------------------------------------------------
// DisplayDensityGcount - Density_Gcount
// -----------------------------------------------------------------------------
Function DisplayDensityGcount(SampleName, [basePath, waveSuffix])
	String SampleName
	String basePath, waveSuffix
	
	// 
	if(ParamIsDefault(basePath))
		basePath = "root"
	endif
	if(ParamIsDefault(waveSuffix))
		waveSuffix = ""
	endif
	
	NVAR scale = root:scale
	NVAR framerate = root:framerate
	NVAR RHistBin = root:RHistBin
	NVAR RHistDim = root:RHistDim
	NVAR DensityStartFrame = root:DensityStartFrame
	NVAR DensityEndFrame = root:DensityEndFrame
	Variable StartFrame = DensityStartFrame
	Variable EndFrame = DensityEndFrame

	Variable range = EndFrame - StartFrame + 1

	Variable numFolders
	if(StringMatch(basePath, "root"))
		numFolders = CountDataFolders(SampleName)
	else
		numFolders = CountDataFoldersInPath(basePath, SampleName)
	endif
	
	Variable m, frame
	String FolderName, folderPath
	
	// samplePath
	String samplePath
	if(StringMatch(basePath, "root"))
		samplePath = "root:" + SampleName
	else
		samplePath = basePath + ":" + SampleName
	endif
	
	for(m = 0; m < numFolders; m += 1)
		FolderName = SampleName + num2str(m + 1)
		folderPath = samplePath + ":" + FolderName + ":"
		
		if(!DataFolderExists(samplePath + ":" + FolderName))
			continue
		endif
		
		SetDataFolder $(samplePath + ":" + FolderName)
		
		// wave
		Wave/Z MatrixlogAvgD_r = $(folderPath + "MatrixlogAvgD_r")
		Wave/Z MatrixdlogAvgD_r = $(folderPath + "MatrixdlogAvgD_r")
		Wave/Z logR_r = $(folderPath + "logR_r")
		Wave/Z MatrixXum_frame = $(folderPath + "MatrixXum_frame")
		Wave/Z MatrixYum_frame = $(folderPath + "MatrixYum_frame")
		Wave/Z Wtime = $(folderPath + "Wtime")
		Wave/Z Density_t = $(folderPath + "Density_t")
		Wave/Z Area_t = $(folderPath + "Area_t")
		Wave/Z RmaxD_t = $(folderPath + "RmaxD_t")
		
		if(!WaveExists(MatrixlogAvgD_r))
			continue
		endif
		
		// === 1. ===
		String winName1 = "DensityLogLog_" + FolderName + waveSuffix
		DoWindow/K $winName1
		
		Display/K=1/N=$winName1 MatrixlogAvgD_r[][0] vs logR_r
		ModifyGraph rgb(MatrixlogAvgD_r)=(0, 0, 0)
		
		String NamelogAvgD_r_frame, NamedlogAvgD_r_frame
		for(frame = 1; frame < range; frame += 1)
			AppendToGraph MatrixlogAvgD_r[][frame] vs logR_r
			NamelogAvgD_r_frame = "MatrixlogAvgD_r#" + num2str(frame)
			ModifyGraph rgb($NamelogAvgD_r_frame)=(round(65535/range)*frame/2, 0, 0)
		endfor
		
		AppendToGraph/R MatrixdlogAvgD_r[][0] vs logR_r
		ModifyGraph rgb(MatrixdlogAvgD_r)=(0, 0, 65535)
		
		for(frame = 1; frame < range; frame += 1)
			AppendToGraph/R MatrixdlogAvgD_r[][frame] vs logR_r
			NamedlogAvgD_r_frame = "MatrixdlogAvgD_r#" + num2str(frame)
			ModifyGraph rgb($NamedlogAvgD_r_frame)=(0, 0, round(65535/range)*frame/2)
		endfor
		
		ModifyGraph tick=2, fStyle=1, fSize=14, font="Arial"
		ModifyGraph mirror(bottom)=1
		Label left "log(local density)"
		Label right "dif. log(local density)"
		ModifyGraph mode=4, marker=19, msize=1
		Label bottom "\\F'Arial'log(r) (μm)"
		ModifyGraph width={Aspect, 1.618}
		
		// Seg
		String graphTitle1 = GetGraphTitleWithSeg(FolderName + " log(density) vs log(r)", waveSuffix)
		DoWindow/T $winName1, graphTitle1
		
		// === 2. XY===
		if(WaveExists(MatrixXum_frame) && WaveExists(MatrixYum_frame) && WaveExists(RmaxD_t))
			String winName2 = "XY_Density_" + FolderName + waveSuffix
			DoWindow/K $winName2
			
			Display/K=1/N=$winName2 MatrixYum_frame[][0] vs MatrixXum_frame[][0]
			ModifyGraph tick=0, mirror=0, lowTrip=0.001
			ModifyGraph axisEnab(left)={0.05, 1}, axisEnab(bottom)={0.05, 1}
			ModifyGraph fStyle=1, fSize=16, font="Arial"
			ModifyGraph width=256, height=256
			
			Variable RmaxD = RmaxD_t[0]
			Variable msize_RmaxD
			// NaN
			if(numtype(RmaxD) == 0)
				msize_RmaxD = RmaxD * (RHistBin / scale) / (512 / 256)
			else
				msize_RmaxD = 1
			endif
			
			ModifyGraph mode(MatrixYum_frame)=3, marker(MatrixYum_frame)=19, mrkThick(MatrixYum_frame)=0
			ModifyGraph rgb(MatrixYum_frame)=(65535, 65535, 65535)
			ModifyGraph msize(MatrixYum_frame)=msize_RmaxD
			
			String NameMatrixYum_frame1, NameMatrixYum_frame2, NameMatrixYum_frame
			for(frame = 1; frame < range; frame += 1)
				AppendToGraph MatrixYum_frame[][frame] vs MatrixXum_frame[][frame]
				RmaxD = RmaxD_t[frame]
				// NaN
				if(numtype(RmaxD) == 0)
					msize_RmaxD = RmaxD * (RHistBin / scale) / (512 / 256)
				else
					msize_RmaxD = 1
				endif
				
				NameMatrixYum_frame1 = "MatrixYum_frame#" + num2str(frame)
				ModifyGraph mode($NameMatrixYum_frame1)=3, marker($NameMatrixYum_frame1)=19, mrkThick($NameMatrixYum_frame1)=0
				ModifyGraph rgb($NameMatrixYum_frame1)=(65535 - round(65535/range)*frame/2, 65535, 65535)
				ModifyGraph msize($NameMatrixYum_frame1)=msize_RmaxD
			endfor
			
			// 
			AppendToGraph MatrixYum_frame[][0] vs MatrixXum_frame[][0]
			NameMatrixYum_frame = "MatrixYum_frame#" + num2str(range)
			RmaxD = RmaxD_t[0]
			
			ModifyGraph mode($NameMatrixYum_frame)=3, marker($NameMatrixYum_frame)=19, mrkThick($NameMatrixYum_frame)=0
			ModifyGraph rgb($NameMatrixYum_frame)=(65535, 0, 0)
			ModifyGraph msize($NameMatrixYum_frame)=1
			
			for(frame = 1; frame < range; frame += 1)
				AppendToGraph MatrixYum_frame[][frame] vs MatrixXum_frame[][frame]
				NameMatrixYum_frame2 = "MatrixYum_frame#" + num2str(range + frame)
				
				ModifyGraph mode($NameMatrixYum_frame2)=3, marker($NameMatrixYum_frame2)=19, mrkThick($NameMatrixYum_frame2)=0
				ModifyGraph rgb($NameMatrixYum_frame2)=(65535 - round(65535/range)*frame/2, 0, 0)
				ModifyGraph msize($NameMatrixYum_frame2)=1
			endfor
			
			Label bottom "X μm"
			Label left "Y μm"
			NVAR PixNum = root:PixNum
			Variable axisMax = scale * PixNum
			SetAxis bottom 0, axisMax
			SetAxis left 0, axisMax
			ModifyGraph gbRGB=(0, 0, 0)
			ModifyGraph tickRGB(bottom)=(65535, 65535, 65535)
			ModifyGraph tickRGB(left)=(65535, 65535, 65535)
			
			// Seg
			String graphTitle2 = GetGraphTitleWithSeg(FolderName + " XY Distribution", waveSuffix)
			DoWindow/T $winName2, graphTitle2
		endif
		
		// === 3. Density-time plot===
		if(WaveExists(Density_t) && WaveExists(Area_t) && WaveExists(Wtime))
			String winName3 = "DensityTime_" + FolderName + waveSuffix
			DoWindow/K $winName3
			
			Display/K=1/N=$winName3 Density_t vs Wtime
			AppendToGraph/R Area_t vs Wtime
			
			ModifyGraph tick=2, fStyle=1, fSize=14, font="Arial"
			ModifyGraph mirror(bottom)=1
			Label left "Density (1/µm\\S2\\M)"
			Label right "Area (µm\\S2\\M)"
			ModifyGraph mode=4, marker=19, msize=1
			ModifyGraph rgb(Density_t)=(0, 0, 0)
			ModifyGraph rgb(Area_t)=(65280, 0, 0)
			Label bottom "time (s)"
			ModifyGraph width={Aspect, 1.618}
			ModifyGraph axRGB(right)=(65280, 0, 0), tlblRGB(right)=(65280, 0, 0), alblRGB(right)=(65280, 0, 0)
			
			// Seg
			String graphTitle3 = GetGraphTitleWithSeg(FolderName + " Density vs Time", waveSuffix)
			DoWindow/T $winName3, graphTitle3
		endif
		
		// === 4. ParticleDensity_Dstate  ===
		DisplayParticleDensityByState(FolderName, folderPath)
	endfor
	
	SetDataFolder root:
End

// -----------------------------------------------------------------------------
// DisplayParticleDensityByState - ParticleDensity_Dstate
// -----------------------------------------------------------------------------
Function DisplayParticleDensityByState(FolderName, folderPath)
	String FolderName, folderPath
	
	NVAR cHMM = root:cHMM
	NVAR Dstate = root:Dstate
	Variable maxState = cHMM ? Dstate : 0
	
	Wave/Z ParticleDensity_Dstate = $(folderPath + "ParticleDensity_Dstate")
	if(!WaveExists(ParticleDensity_Dstate))
		return 0
	endif
	
	// X
	Make/O/T/N=(maxState + 1) $(folderPath + "DstateLabels_PD")
	Wave/T DstateLabels = $(folderPath + "DstateLabels_PD")
	
	Variable s
	for(s = 0; s <= maxState; s += 1)
		DstateLabels[s] = GetDstateName(s, maxState)
	endfor
	
	// Wave
	Make/O/N=(maxState + 1, 3) $(folderPath + "PDBarColors") = 0
	Wave BarColors = $(folderPath + "PDBarColors")
	
	Variable r, g, b
	for(s = 0; s <= maxState; s += 1)
		GetDstateColor(s, r, g, b)
		BarColors[s][0] = r
		BarColors[s][1] = g
		BarColors[s][2] = b
	endfor
	
	// 
	String winName = "ParticleDensity_" + FolderName
	DoWindow/K $winName
	
	Display/K=1/N=$winName ParticleDensity_Dstate vs DstateLabels
	
	ModifyGraph mode=5, hbFill=2
	ModifyGraph zColor(ParticleDensity_Dstate)={BarColors,*,*,directRGB,0}
	ModifyGraph useBarStrokeRGB(ParticleDensity_Dstate)=1, barStrokeRGB(ParticleDensity_Dstate)=(0,0,0)
	
	ModifyGraph tick=2, mirror=0, fStyle=1, fSize=14, font="Arial"
	ModifyGraph tick(bottom)=3
	ModifyGraph catGap(bottom)=0.3
	ModifyGraph width={Aspect, 1.618}
	Label left "\\F'Arial'\\Z14Particle Density [/µm\\S2\\M]"
	SetAxis left 0, *
	DoWindow/T $winName, FolderName + " Particle Density by D-state"
	
	return 0
End

// -----------------------------------------------------------------------------
// 
// -----------------------------------------------------------------------------
Function CreateIntensityHistogram(SampleName, [basePath, useHistBin, useHistDim, waveSuffix])
	String SampleName
	String basePath      // :  "root"
	Variable useHistBin  // : bin
	Variable useHistDim  // : dim
	String waveSuffix    // : wave"_C1E", "_C2E"
	
	NVAR IhistBin = root:IhistBin
	NVAR IhistDim = root:IhistDim
	NVAR/Z Dstate = root:Dstate
	NVAR/Z cHMM = root:cHMM
	NVAR/Z IntNormByS0 = root:IntNormByS0
	
	// 
	if(ParamIsDefault(basePath))
		basePath = "root"
	endif
	if(ParamIsDefault(useHistBin))
		useHistBin = IhistBin
	endif
	if(ParamIsDefault(useHistDim))
		useHistDim = IhistDim
	endif
	if(ParamIsDefault(waveSuffix))
		waveSuffix = ""  // 
	endif
	
	Variable numFolders = CountDataFoldersInPath(basePath, SampleName)
	Variable m, s, maxState
	String FolderName
	
	// HMMDstateS0
	if(NVAR_Exists(cHMM) && cHMM == 1 && NVAR_Exists(Dstate))
		maxState = Dstate
	else
		maxState = 0
	endif
	
	// S0
	Variable useS0Norm = 1
	if(NVAR_Exists(IntNormByS0))
		useS0Norm = IntNormByS0
	endif
	
	Variable total, totalS0
	String folderFullPath
	for(m = 0; m < numFolders; m += 1)
		FolderName = SampleName + num2str(m + 1)
		folderFullPath = basePath + ":" + SampleName + ":" + FolderName
		
		if(!DataFolderExists(folderFullPath))
			break
		endif
		
		SetDataFolder $folderFullPath
		
		// 
		Variable/G LogIntensityScale = 0
		
		// S0S0
		totalS0 = 0
		if(useS0Norm == 1)
			String intS0Name = "Int_S0" + waveSuffix
			Wave/Z Int_S0_ref = $intS0Name
			if(WaveExists(Int_S0_ref))
				Extract/O Int_S0_ref, Int_S0_valid_temp, numtype(Int_S0_ref) == 0 && Int_S0_ref > 0
				totalS0 = numpnts(Int_S0_valid_temp)
				KillWaves/Z Int_S0_valid_temp
			endif
		endif
		
		// 
		if(m == 0)
			Printf "IntHist Normalization Debug (%s):\r", FolderName
			Printf "  totalS0 = %d, suffix = %s\r", totalS0, waveSuffix
		endif
		
		// S0SmaxState
		for(s = 0; s <= maxState; s += 1)
			String intWaveName = "Int_S" + num2str(s) + waveSuffix
			String histWaveName = "Int_S" + num2str(s) + waveSuffix + "_Phist"
			
			Wave/Z IntWave = $intWaveName
			if(!WaveExists(IntWave))
				if(s == 0)
					Printf ": %s %s\r", FolderName, intWaveName
				endif
				continue
			endif
			
			// useHistBin/useHistDim
			Make/O/N=(useHistDim) tempHist, $histWaveName
			Wave HistOut = $histWaveName
			SetScale/P x, useHistBin/2, useHistBin, HistOut
			
			// 
			Extract/O IntWave, Int_valid, numtype(IntWave) == 0 && IntWave > 0
			
			// 
			if(m == 0)
				Printf "  S%d: numpnts(Int_valid) = %d\r", s, numpnts(Int_valid)
			endif
			
			if(numpnts(Int_valid) > 0)
				Histogram/B={0, useHistBin, useHistDim} Int_valid, tempHist
				
				// 
				if(useS0Norm == 1 && totalS0 > 0)
					// S0
					HistOut = tempHist / totalS0
				else
					// 
					total = sum(tempHist)
					if(total > 0)
						HistOut = tempHist / total
					endif
				endif
				
				// 
				if(m == 0)
					Printf "  S%d: sum(HistOut) = %.4f\r", s, sum(HistOut)
				endif
			else
				HistOut = 0
			endif
			
			KillWaves/Z Int_valid, tempHist
		endfor
		
		//  IntHist, IntHist_x 
		String s0PhistName = "Int_S0" + waveSuffix + "_Phist"
		Wave/Z Int_S0_Phist_ref = $s0PhistName
		if(WaveExists(Int_S0_Phist_ref))
			Duplicate/O Int_S0_Phist_ref, IntHist
			Make/O/N=(useHistDim) IntHist_x
			IntHist_x = useHistBin * (p + 0.5)
		endif
		
		ShowProgress(m+1, numFolders, "")
	endfor
	
	EndProgress()
	SetDataFolder root:
End

// -----------------------------------------------------------------------------
// 
// Log10(Intensity) 
// -----------------------------------------------------------------------------
Function CreateIntensityHistogramLog(SampleName)
	String SampleName
	
	NVAR IhistBin = root:IhistBin
	NVAR IhistDim = root:IhistDim
	NVAR/Z Dstate = root:Dstate
	NVAR/Z cHMM = root:cHMM
	NVAR/Z IntNormByS0 = root:IntNormByS0
	
	Variable numFolders = CountDataFolders(SampleName)
	Variable m, s, maxState
	String FolderName
	
	// HMMDstateS0
	if(NVAR_Exists(cHMM) && cHMM == 1 && NVAR_Exists(Dstate))
		maxState = Dstate
	else
		maxState = 0
	endif
	
	// S0
	Variable useS0Norm = 1
	if(NVAR_Exists(IntNormByS0))
		useS0Norm = IntNormByS0
	endif
	
	// GausshistDim
	// X: log10(IhistBin)  log10(IhistBin * IhistDim)
	// : IhistBin=50, IhistDim=200 → log10(50)≈1.7  log10(10000)=4.0
	Variable logMin = log(IhistBin)                    // : log10(50) ≈ 1.7
	Variable logMax = log(IhistBin * IhistDim)         // : log10(10000) = 4.0
	Variable logDim = IhistDim                         // Gauss
	Variable logBin = (logMax - logMin) / logDim       // 
	
	Print "=== Creating Log-Intensity Histogram ==="
	Printf "Log scale: range=[%.3f, %.3f], dim=%d, bin=%.4f (log10 scale)\r", logMin, logMax, logDim, logBin
	Printf "Equivalent linear range: [%.0f, %.0f]\r", 10^logMin, 10^logMax
	if(useS0Norm == 1)
		Print "Normalization: by S0 total count (reflects state ratio)"
	else
		Print "Normalization: per state (probability density)"
	endif
	
	Variable total, totalS0
	for(m = 0; m < numFolders; m += 1)
		FolderName = SampleName + num2str(m + 1)
		SetDataFolder root:$(SampleName):$(FolderName)
		
		// 
		Variable/G LogIntensityScale = 1
		Variable/G LogIntBin = logBin
		Variable/G LogIntMin = logMin
		Variable/G LogIntDim = logDim
		
		// S0S0
		totalS0 = 0
		if(useS0Norm == 1)
			Wave/Z Int_S0
			if(WaveExists(Int_S0))
				Extract/O Int_S0, Int_S0_valid_temp, numtype(Int_S0) == 0 && Int_S0 > 0
				totalS0 = numpnts(Int_S0_valid_temp)
				KillWaves/Z Int_S0_valid_temp
			endif
		endif
		
		// S0SmaxState
		for(s = 0; s <= maxState; s += 1)
			String intWaveName = "Int_S" + num2str(s)
			String histWaveName = "Int_S" + num2str(s) + "_Phist"
			
			Wave/Z IntWave = $intWaveName
			if(!WaveExists(IntWave))
				if(s == 0)
					Printf ": %s %s\r", FolderName, intWaveName
				endif
				continue
			endif
			
			// 
			Make/O/N=(logDim) tempHist, $histWaveName
			Wave HistOut = $histWaveName
			SetScale/P x, logMin + logBin/2, logBin, HistOut
			
			// log10
			Extract/O IntWave, Int_valid, numtype(IntWave) == 0 && IntWave > 0
			
			if(numpnts(Int_valid) > 0)
				// log10
				Make/O/N=(numpnts(Int_valid)) Int_log
				Int_log = log(Int_valid)  // log() (log10)
				
				Histogram/B={logMin, logBin, logDim} Int_log, tempHist
				
				// 
				if(useS0Norm == 1 && totalS0 > 0)
					// S0
					HistOut = tempHist / totalS0
				else
					// 
					total = sum(tempHist)
					if(total > 0)
						HistOut = tempHist / total
					endif
				endif
				
				KillWaves/Z Int_log
			else
				HistOut = 0
			endif
			
			KillWaves/Z Int_valid, tempHist
		endfor
		
		//  IntHist, IntHist_x 
		Wave/Z Int_S0_Phist
		if(WaveExists(Int_S0_Phist))
			Duplicate/O Int_S0_Phist, IntHist
			Make/O/N=(logDim) IntHist_x
			IntHist_x = logMin + logBin * (p + 0.5)
		endif
		
		ShowProgress(m+1, numFolders, "")
	endfor
	
	EndProgress()
	SetDataFolder root:
	Print "Log-intensity histogram created"
End

// -----------------------------------------------------------------------------
// Dstate
// -----------------------------------------------------------------------------
Function DisplayIntensityHistHMM(SampleName, [basePath, waveSuffix])
	String SampleName
	String basePath      // :  "root"
	String waveSuffix    // : wave"_C1E", "_C2E"
	
	NVAR IhistBin = root:IhistBin
	NVAR IhistDim = root:IhistDim
	NVAR/Z Dstate = root:Dstate
	
	// 
	if(ParamIsDefault(basePath))
		basePath = "root"
	endif
	if(ParamIsDefault(waveSuffix))
		waveSuffix = ""
	endif
	
	Variable numFolders = CountDataFoldersInPath(basePath, SampleName)
	Variable m, s, i
	String FolderName
	
	Variable maxState = 0
	if(NVAR_Exists(Dstate))
		maxState = Dstate
	endif
	
	for(m = 0; m < numFolders; m += 1)
		FolderName = SampleName + num2str(m + 1)
		String folderFullPath = basePath + ":" + SampleName + ":" + FolderName
		
		if(!DataFolderExists(folderFullPath))
			break
		endif
		
		SetDataFolder $folderFullPath
		
		// S0
		String s0HistName = "Int_S0" + waveSuffix + "_Phist"
		Wave/Z Int_S0_Phist_ref = $s0HistName
		if(!WaveExists(Int_S0_Phist_ref))
			continue
		endif
		
		// waveSuffix
		String winName = "IntHist_" + FolderName + waveSuffix
		DoWindow/K $winName
		
		// 
		Display/K=1/N=$winName Int_S0_Phist_ref
		
		// Seg
		String graphTitle = GetGraphTitleWithSeg(FolderName + " Intensity Histogram", waveSuffix)
		DoWindow/T $winName, graphTitle
		
		ModifyGraph rgb($s0HistName)=(0,0,0)
		
		// S1
		for(s = 1; s <= maxState; s += 1)
			String histName = "Int_S" + num2str(s) + waveSuffix + "_Phist"
			Wave/Z HistWave = $histName
			if(WaveExists(HistWave))
				AppendToGraph HistWave
				
				// 
				switch(s)
					case 1:
						ModifyGraph rgb($histName)=(0,0,65280)
						break
					case 2:
						ModifyGraph rgb($histName)=(65280,43520,0)
						break
					case 3:
						ModifyGraph rgb($histName)=(0,39168,0)
						break
					case 4:
						ModifyGraph rgb($histName)=(65280,0,0)
						break
					case 5:
						ModifyGraph rgb($histName)=(65280,0,65280)
						break
				endswitch
			endif
			
			// State- 10
			String fitHistName = "fit_Int_S" + num2str(s) + waveSuffix + "_Phist"
			String fitXName = "fit_IntX_S" + num2str(s) + waveSuffix
			Wave/Z FitWave = $fitHistName
			Wave/Z FitXWave = $fitXName
			if(WaveExists(FitWave))
				if(WaveExists(FitXWave))
					AppendToGraph FitWave vs FitXWave
				else
					AppendToGraph FitWave
				endif
				// 
				switch(s)
					case 1:
						ModifyGraph rgb($fitHistName)=(0,0,65280)
						break
					case 2:
						ModifyGraph rgb($fitHistName)=(65280,43520,0)
						break
					case 3:
						ModifyGraph rgb($fitHistName)=(0,39168,0)
						break
					case 4:
						ModifyGraph rgb($fitHistName)=(65280,0,0)
						break
					case 5:
						ModifyGraph rgb($fitHistName)=(65280,0,65280)
						break
				endswitch
			endif
			
			// - 10
			for(i = 1; i <= 16; i += 1)
				String compName = "comp" + num2str(i) + "_S" + num2str(s) + waveSuffix
				Wave/Z CompWave = $compName
				if(WaveExists(CompWave))
					if(WaveExists(FitXWave))
						AppendToGraph CompWave vs FitXWave
					else
						AppendToGraph CompWave
					endif
					// 
					switch(s)
						case 1:
							ModifyGraph rgb($compName)=(0,0,65280)
							break
						case 2:
							ModifyGraph rgb($compName)=(65280,43520,0)
							break
						case 3:
							ModifyGraph rgb($compName)=(0,39168,0)
							break
						case 4:
							ModifyGraph rgb($compName)=(65280,0,0)
							break
						case 5:
							ModifyGraph rgb($compName)=(65280,0,65280)
							break
					endswitch
				endif
			endfor
		endfor
		
		// S010X
		String s0FitHistName = "fit_Int_S0" + waveSuffix + "_Phist"
		String s0FitXName = "fit_IntX_S0" + waveSuffix
		Wave/Z fit_Int_S0_Phist_ref = $s0FitHistName
		Wave/Z fit_IntX_S0_ref = $s0FitXName
		if(WaveExists(fit_Int_S0_Phist_ref))
			if(WaveExists(fit_IntX_S0_ref))
				AppendToGraph fit_Int_S0_Phist_ref vs fit_IntX_S0_ref
			else
				AppendToGraph fit_Int_S0_Phist_ref
			endif
			ModifyGraph rgb($s0FitHistName)=(0,0,0)
		endif
		
		// S0- 10
		for(i = 1; i <= 16; i += 1)
			String compNameS0 = "comp" + num2str(i) + "_S0" + waveSuffix
			Wave/Z CompWaveS0 = $compNameS0
			if(WaveExists(CompWaveS0) && WaveExists(fit_IntX_S0_ref))
				AppendToGraph CompWaveS0 vs fit_IntX_S0_ref
				ModifyGraph rgb($compNameS0)=(0,0,0)
			elseif(WaveExists(CompWaveS0))
				AppendToGraph CompWaveS0
				ModifyGraph rgb($compNameS0)=(0,0,0)
			endif
		endfor
		
		// 
		Wave/Z fit_IntHist, fit_Int_S0_Phist
		if(WaveExists(fit_IntHist) && !WaveExists(fit_Int_S0_Phist))
			AppendToGraph fit_IntHist
			ModifyGraph rgb(fit_IntHist)=(65280,0,0)
		endif
		
		// 
		NVAR/Z LogIntensityScale = LogIntensityScale
		NVAR/Z LogIntBin = LogIntBin
		NVAR/Z LogIntMin = LogIntMin
		NVAR/Z LogIntDim = LogIntDim
		
		Variable isLogScale = 0
		if(NVAR_Exists(LogIntensityScale) && LogIntensityScale == 1)
			isLogScale = 1
		endif
		
		// 
		ModifyGraph tick=0, mirror=0
		ModifyGraph lowTrip(left)=0.0001
		ModifyGraph fStyle=1, fSize=16, font="Arial"
		ModifyGraph width={Aspect,1.618}
		SetAxis left 0, *
		
		if(isLogScale)
			// 
			SetAxis bottom LogIntMin, LogIntMin + LogIntBin * LogIntDim
			Label left "Probability"
			Label bottom "log\\B10\\M(Intensity)"
		else
			// 
			SetAxis bottom 0, *
			Label left "Probability"
			Label bottom "Intensity (a.u.)"
		endif
		
		// 
		ModifyGraph mode($s0HistName)=3, marker($s0HistName)=19
		for(s = 1; s <= maxState; s += 1)
			histName = "Int_S" + num2str(s) + waveSuffix + "_Phist"
			Wave/Z HW = $histName
			if(WaveExists(HW))
				ModifyGraph mode($histName)=3, marker($histName)=19
			endif
		endfor
		
		// 
		if(WaveExists(fit_Int_S0_Phist_ref))
			ModifyGraph mode($s0FitHistName)=0, lsize($s0FitHistName)=1.5
		endif
		for(s = 1; s <= maxState; s += 1)
			fitHistName = "fit_Int_S" + num2str(s) + waveSuffix + "_Phist"
			Wave/Z FW = $fitHistName
			if(WaveExists(FW))
				ModifyGraph mode($fitHistName)=0, lsize($fitHistName)=1.5
			endif
		endfor
		// waveSuffix
		if(strlen(waveSuffix) == 0)
			Wave/Z fit_IntHist_legacy = $"fit_IntHist"
			Wave/Z fit_S0_check = $"fit_Int_S0_Phist"
			if(WaveExists(fit_IntHist_legacy) && !WaveExists(fit_S0_check))
				ModifyGraph mode(fit_IntHist)=0, lsize(fit_IntHist)=1.5
			endif
		endif
		
		// 
		for(s = 0; s <= maxState; s += 1)
			for(i = 1; i <= 16; i += 1)
				String cName = "comp" + num2str(i) + "_S" + num2str(s) + waveSuffix
				Wave/Z CW = $cName
				if(WaveExists(CW))
					ModifyGraph mode($cName)=0, lsize($cName)=0.5, lstyle($cName)=11  // 
				endif
			endfor
		endfor
		
		// GetDstateName
		String legendStr = "\\F'Arial'\\Z12\r\\s(" + s0HistName + ") " + GetDstateName(0, maxState)
		for(s = 1; s <= maxState; s += 1)
			histName = "Int_S" + num2str(s) + waveSuffix + "_Phist"
			legendStr += "\r\\s(" + histName + ") " + GetDstateName(s, maxState)
		endfor
		TextBox/C/N=text0/F=0/B=1/A=RT legendStr
	endfor
	
	SetDataFolder root:
End

// -----------------------------------------------------------------------------
// Sum Gauss- Dstate
// -----------------------------------------------------------------------------
Function FitIntensityGauss_Safe(SampleName, numOligomers, [fixParams, basePath, useHistBin, useHistDim, waveSuffix])
	String SampleName
	Variable numOligomers  // 1-16
	Variable fixParams
	String basePath        // :  "root"
	Variable useHistBin    // : bin
	Variable useHistDim    // : dim
	String waveSuffix      // : wave"_C1E", "_C2E"
	
	Variable fitResult, i, j, s, meanIdx, peakX, sdIdx, xMax
	String fitFunc, holdStr
	NVAR/Z cSuppressOutput = root:cSuppressOutput
	Variable suppressOutput = NVAR_Exists(cSuppressOutput) ? cSuppressOutput : 0
	
	if(ParamIsDefault(fixParams))
		NVAR/Z cFixIntParameters = root:cFixIntParameters
		if(NVAR_Exists(cFixIntParameters))
			fixParams = cFixIntParameters
		else
			fixParams = 0
		endif
	endif
	
	// 
	if(ParamIsDefault(basePath))
		basePath = "root"
	endif
	if(ParamIsDefault(waveSuffix))
		waveSuffix = ""
	endif
	
	Variable numFolders = CountDataFoldersInPath(basePath, SampleName)
	Variable m
	String FolderName
	
	NVAR IhistBin = root:IhistBin
	NVAR IhistDim = root:IhistDim
	NVAR MeanIntGauss = root:MeanIntGauss
	NVAR SDIntGauss = root:SDIntGauss
	NVAR/Z Dstate = root:Dstate
	NVAR/Z cHMM = root:cHMM
	
	// 
	Variable localHistBin = IhistBin
	Variable localHistDim = IhistDim
	if(!ParamIsDefault(useHistBin))
		localHistBin = useHistBin
	endif
	if(!ParamIsDefault(useHistDim))
		localHistDim = useHistDim
	endif
	
	// HMMDstateS0
	Variable maxState = 0
	if(NVAR_Exists(cHMM) && cHMM == 1 && NVAR_Exists(Dstate))
		maxState = Dstate
	endif
	
	// 
	CreateResultsFolderInPath(basePath, SampleName)
	
	Variable numParams = numOligomers + 2  // A1...An + mean + sd
	
	Variable successCount = 0
	Variable failCount = 0
	
	if(!suppressOutput)
		Print "=== Intensity Distribution Fitting ==="
		Printf "BasePath: %s, Sample: %s, n=%d, States: S0-S%d, suffix=%s\r", basePath, SampleName, numOligomers, maxState, waveSuffix
	endif
	
	for(m = 0; m < numFolders; m += 1)
		FolderName = SampleName + num2str(m + 1)
		String folderFullPath = basePath + ":" + SampleName + ":" + FolderName
		
		if(!DataFolderExists(folderFullPath))
			break
		endif
		
		SetDataFolder $folderFullPath
		
		// Dstate
		for(s = 0; s <= maxState; s += 1)
			String stateSuffix = "_S" + num2str(s)
			// wave: Int_S0_C1E_Phist 
			String histName = "Int" + stateSuffix + waveSuffix + "_Phist"
			
			Wave/Z HistWave = $histName
			if(!WaveExists(HistWave))
				if(s == 0)
					// 
					Wave/Z IntHist
					if(WaveExists(IntHist))
						Duplicate/O IntHist, $histName
						Wave HistWave = $histName
					else
						failCount += 1
						continue
					endif
				else
					continue
				endif
			endif
			
			// Xlocal
			Make/O/N=(localHistDim) IntHist_x_temp
			IntHist_x_temp = localHistBin * (p + 0.5)
			
			// 
			fitFunc = "SumGauss" + num2str(numOligomers)
			
			// 
			Make/O/D/N=(numParams) coef_temp
			
			for(i = 0; i < numOligomers; i += 1)
				coef_temp[i] = 1.0 / numOligomers
			endfor
			
			// meansd
			meanIdx = numOligomers
			sdIdx = numOligomers + 1
			
			if(numOligomers == 1)
				meanIdx = 1
				sdIdx = 2
				Redimension/N=3 coef_temp
			elseif(numOligomers == 2)
				meanIdx = 2
				sdIdx = 3
				Redimension/N=4 coef_temp
			endif
			
			coef_temp[meanIdx] = MeanIntGauss
			coef_temp[sdIdx] = SDIntGauss
			
			// Hold string
			holdStr = ""
			if(fixParams && numOligomers > 1)
				holdStr = PadString("", numOligomers, 48)
				holdStr += "11"
			endif
			
			// 
			fitResult = SafeFitIntensity(HistWave, IntHist_x_temp, coef_temp, fitFunc, holdStr)
			
			if(fitResult == 0)
				// 10
				// wave: fit_Int_S0_C1E_Phist 
				String fitHistName = "fit_Int" + stateSuffix + waveSuffix + "_Phist"
				String fitXName = "fit_IntX" + stateSuffix + waveSuffix
				Variable numFitPts = numpnts(IntHist_x_temp) * 10
				Make/O/N=(numFitPts) $fitHistName, $fitXName
				Wave FitHist = $fitHistName
				Wave FitX = $fitXName
				
				// X
				Variable xStart = IntHist_x_temp[0]
				Variable xEnd = IntHist_x_temp[numpnts(IntHist_x_temp)-1]
				Variable xStep = (xEnd - xStart) / (numFitPts - 1)
				FitX = xStart + p * xStep
				
				// 
				Variable xVal
				for(i = 0; i < numFitPts; i += 1)
					xVal = FitX[i]
					FitHist[i] = EvaluateSumGauss(coef_temp, xVal, numOligomers)
				endfor
				
				// 
				if(numOligomers > 1)
					Variable olig
					Variable m_val, s_val
					
					// mean, sd
					if(numOligomers == 2)
						m_val = coef_temp[2]
						s_val = coef_temp[3]
					else
						m_val = coef_temp[numOligomers]
						s_val = coef_temp[numOligomers + 1]
					endif
					
					for(olig = 1; olig <= numOligomers; olig += 1)
						String compName = "comp" + num2str(olig) + stateSuffix + waveSuffix
						Make/O/N=(numFitPts) $compName
						Wave CompWave = $compName
						
						Variable Aolig
						if(numOligomers == 2)
							Aolig = coef_temp[olig - 1]
						else
							Aolig = coef_temp[olig - 1]
						endif
						
						for(i = 0; i < numFitPts; i += 1)
							xVal = FitX[i]
							// n: mean = n*m, sd = sqrt(n)*s
							CompWave[i] = Aolig * exp(-((xVal - olig*m_val)^2 / (2 * olig*s_val^2)))
						endfor
					endfor
				endif
				
				// 
				String coefName = "coef_Int" + stateSuffix + waveSuffix
				Duplicate/O coef_temp, $coefName
				
				successCount += 1
				Printf "  %s S%d: \r", FolderName, s
			else
				// : wave0
				coefName = "coef_Int" + stateSuffix + waveSuffix
				Make/O/D/N=(numParams) $coefName = 0
				Printf "  %s S%d: wave\r", FolderName, s
				failCount += 1
			endif
			
			KillWaves/Z coef_temp, IntHist_x_temp
		endfor
		
		ShowProgress(m+1, numFolders, "")
	endfor
	
	EndProgress()
	Printf ":  %d,  %d\r", successCount, failCount
	
	SetDataFolder root:
	return successCount
End

// SumGauss
Function EvaluateSumGauss(coef, x, numOligomers)
	Wave coef
	Variable x, numOligomers
	
	Variable result = 0
	Variable i, m, s
	
	// mean, sd
	if(numOligomers == 1)
		m = coef[1]
		s = coef[2]
		result = coef[0] * exp(-((x - m)^2 / (2 * s^2)))
	elseif(numOligomers == 2)
		m = coef[2]
		s = coef[3]
		result += coef[0] * exp(-((x - m)^2 / (2 * s^2)))
		result += coef[1] * exp(-((x - 2*m)^2 / (2 * 2*s^2)))
	else
		// 3: m = coef[numOligomers], s = coef[numOligomers+1]
		m = coef[numOligomers]
		s = coef[numOligomers + 1]
		for(i = 0; i < numOligomers; i += 1)
			Variable n = i + 1  // 
			result += coef[i] * exp(-((x - n*m)^2 / (2 * n*s^2)))
		endfor
	endif
	
	return result
End

Function SafeFitIntensity(histWave, xWave, coefWave, fitFunc, holdStr)
	Wave histWave, xWave, coefWave
	String fitFunc, holdStr
	
	Variable V_FitError = 0
	Variable maxRetries = 3
	Variable retry, hIdx
	
	// 
	if(exists(fitFunc) != 6)
		Printf "ERROR: Fitting function '%s' not found\r", fitFunc
		return -1
	endif
	
	Variable err
	Duplicate/FREE coefWave, originalCoef
	
	// Wave:  > 0
	Variable numParams = numpnts(coefWave)
	Make/T/O/N=(numParams) T_Constraints
	Variable i
	for(i = 0; i < numParams; i += 1)
		T_Constraints[i] = "K" + num2str(i) + " > 0"
	endfor
	
	for(retry = 0; retry < maxRetries; retry += 1)
		V_FitError = 0
		
		try
			AbortOnRTE
			if(strlen(holdStr) > 0)
				FuncFit/Q/N/W=2/H=holdStr $fitFunc, coefWave, histWave /X=xWave /C=T_Constraints; AbortOnRTE
			else
				FuncFit/Q/N/W=2 $fitFunc, coefWave, histWave /X=xWave /C=T_Constraints; AbortOnRTE
			endif
			
			if(V_FitError == 0)
				KillWaves/Z T_Constraints
				return 0  // 
			endif
		catch
			err = GetRTError(1)
			V_FitError = 1
		endtry
		
		// 
		if(retry < maxRetries - 1)
			coefWave = originalCoef * (0.8 + enoise(0.4))
			// holdStr: 
			for(hIdx = 0; hIdx < strlen(holdStr); hIdx += 1)
				if(CmpStr(holdStr[hIdx], "1") == 0)
					coefWave[hIdx] = originalCoef[hIdx]
				endif
			endfor
		endif
	endfor
	
	KillWaves/Z T_Constraints
	return -1  // 
End

static Function CalculateIntensityStats(SampleName, numOligomers)
	String SampleName
	Variable numOligomers
	
	SetDataFolder root:$(SampleName):Results
	
	Wave fit_IntGaussParams, fit_IntGaussSuccess
	
	// 
	Variable numParams = DimSize(fit_IntGaussParams, 1)
	Make/O/N=(numParams, 3) fit_IntGauss_stats
	fit_IntGauss_stats = NaN  // avg, sd, sem
	
	Variable p
	for(p = 0; p < numParams; p += 1)
		Make/FREE/N=(DimSize(fit_IntGaussParams, 0)) tempCol
		tempCol = fit_IntGaussParams[q][p]
		
		// 
		Extract/O tempCol, temp_valid, fit_IntGaussSuccess == 1 && numtype(tempCol) == 0
		
		if(numpnts(temp_valid) > 0)
			WaveStats/Q temp_valid
			fit_IntGauss_stats[p][0] = V_avg
			fit_IntGauss_stats[p][1] = V_sdev
			fit_IntGauss_stats[p][2] = V_sdev / sqrt(V_npnts)
		endif
	endfor
	
	KillWaves/Z temp_valid
	
	// 
	Printf "\r=== Intensity Fitting Results (Sum Gauss %d) ===\r", numOligomers
	
	Variable i
	for(i = 0; i < numOligomers; i += 1)
		Printf "A%d: %.4f ± %.4f\r", i+1, fit_IntGauss_stats[i][0], fit_IntGauss_stats[i][2]
	endfor
	
	Variable meanIdx = numOligomers
	Variable sdIdx = numOligomers + 1
	
	if(numOligomers == 1)
		meanIdx = 1
		sdIdx = 2
	elseif(numOligomers == 2)
		meanIdx = 2
		sdIdx = 3
	endif
	
	Printf "Mean: %.2f ± %.2f\r", fit_IntGauss_stats[meanIdx][0], fit_IntGauss_stats[meanIdx][2]
	Printf "SD: %.2f ± %.2f\r", fit_IntGauss_stats[sdIdx][0], fit_IntGauss_stats[sdIdx][2]
End

// -----------------------------------------------------------------------------
// AIC
// -----------------------------------------------------------------------------
Function AICAnalysis_Intensity(SampleName, minOligomers, maxOligomers)
	String SampleName
	Variable minOligomers, maxOligomers
	
	Variable numFolders = CountDataFolders(SampleName)
	Variable numModels = maxOligomers - minOligomers + 1
	Variable m, n, i
	String FolderName
	
	NVAR MeanIntGauss = root:MeanIntGauss
	NVAR SDIntGauss = root:SDIntGauss
	NVAR/Z cFixIntParameters = root:cFixIntParameters
	Variable fixParams = 0
	if(NVAR_Exists(cFixIntParameters))
		fixParams = cFixIntParameters
	endif
	
	// 
	CreateResultsFolder(SampleName)
	SetDataFolder root:$(SampleName):Results
	Make/O/N=(numModels) AIC_comparison = NaN
	Make/O/N=(numModels) model_oligomers
	for(n = 0; n < numModels; n += 1)
		model_oligomers[n] = minOligomers + n
	endfor
	
	Print "=== AIC Model Selection ==="
	Printf "Testing oligomer sizes from %d to %d\r", minOligomers, maxOligomers
	
	// AIC
	for(n = minOligomers; n <= maxOligomers; n += 1)
		Printf "  Testing %d-mer model...\r", n
		
		Variable totalAIC = 0
		Variable validCount = 0
		
		for(m = 0; m < numFolders; m += 1)
			FolderName = SampleName + num2str(m + 1)
			SetDataFolder root:$(SampleName):$(FolderName)
			
			Wave/Z IntHist, IntHist_x
			if(!WaveExists(IntHist))
				continue
			endif
			
			// 
			Variable numParams = n + 2
			if(n == 1)
				numParams = 3
			elseif(n == 2)
				numParams = 4
			endif
			
			Make/O/D/N=(numParams) coef_temp
			for(i = 0; i < n; i += 1)
				coef_temp[i] = 1.0 / n
			endfor
			
			Variable meanIdx, sdIdx
			if(n == 1)
				meanIdx = 1; sdIdx = 2
			elseif(n == 2)
				meanIdx = 2; sdIdx = 3
			else
				meanIdx = n; sdIdx = n + 1
			endif
			coef_temp[meanIdx] = MeanIntGauss
			coef_temp[sdIdx] = SDIntGauss
			
			String fitFunc = "SumGauss" + num2str(n)
			String holdStr = ""
			if(fixParams && n > 1)
				holdStr = PadString("", n, 48) + "11"
			endif
			
			// 
			Variable fitResult
			fitResult = SafeFitIntensity(IntHist, IntHist_x, coef_temp, fitFunc, holdStr)
			
			if(fitResult == 0)
				// 
				Make/O/N=(numpnts(IntHist_x)) fit_temp
				Variable xVal
				for(i = 0; i < numpnts(IntHist_x); i += 1)
					xVal = IntHist_x[i]
					fit_temp[i] = EvaluateSumGauss(coef_temp, xVal, n)
				endfor
				
				// 
				Make/FREE/N=(numpnts(IntHist)) residuals
				residuals = (IntHist - fit_temp)^2
				Variable RSS = sum(residuals)
				Variable nData = numpnts(IntHist)
				
				// AIC: AIC = n*ln(RSS/n) + 2k
				Variable AIC_val = nData * ln(RSS / nData) + 2 * numParams
				totalAIC += AIC_val
				validCount += 1
				
				KillWaves/Z fit_temp
			endif
			
			KillWaves/Z coef_temp
		endfor
		
		// AIC
		if(validCount > 0)
			SetDataFolder root:$(SampleName):Results
			AIC_comparison[n - minOligomers] = totalAIC / validCount
			Printf "    %d-mer: AIC = %.2f (n=%d cells)\r", n, totalAIC / validCount, validCount
		endif
	endfor
	
	// AIC
	SetDataFolder root:$(SampleName):Results
	WaveStats/Q AIC_comparison
	Variable bestIdx = V_minloc
	Variable bestOligomers = model_oligomers[bestIdx]
	
	Printf "\r=== Best Model: %d-mer (AIC = %.2f) ===\r", bestOligomers, V_min
	
	// 
	Printf "Re-fitting with best model (%d-mer)...\r", bestOligomers
	FitIntensityGauss_Safe(SampleName, bestOligomers)
	
	// AIC
	String winName = "AIC_" + SampleName
	DoWindow/K $winName
	Display/K=1/N=$winName AIC_comparison vs model_oligomers
	ModifyGraph mode=4, marker=19, msize=3
	ModifyGraph tick=2, mirror=1, fStyle=1, fSize=14, font="Arial"
	ModifyGraph rgb=(0,0,0)
	Label left "AIC"
	Label bottom "Number of Oligomers"
	ModifyGraph width={Aspect,1.618}
	
	// AIC
	Make/O/N=1 bestAIC_x, bestAIC_y
	bestAIC_x[0] = bestOligomers
	bestAIC_y[0] = V_min
	AppendToGraph bestAIC_y vs bestAIC_x
	ModifyGraph mode(bestAIC_y)=3, marker(bestAIC_y)=19, msize(bestAIC_y)=5
	ModifyGraph rgb(bestAIC_y)=(65280,0,0)
	
	TextBox/C/N=text0/F=0/B=1/A=RT "Best: " + num2str(bestOligomers) + "-mer"
	
	SetDataFolder root:
	return bestOligomers
End

// -----------------------------------------------------------------------------
// Sum Log-Normal 
// -----------------------------------------------------------------------------
// v5.4.1: LogHistGauss — 対数ヒストグラム + ガウスフィット
// 対数ヒストグラム（既に log10 空間）にガウスフィット
// k-mer: center = m + log10(k), SD = s/sqrt(k)
Function FitIntensityLogNorm_Safe(SampleName, numOligomers)
	String SampleName
	Variable numOligomers
	
	Variable numFolders = CountDataFolders(SampleName)
	Variable m_cell
	String FolderName
	
	Variable fitResult, i, j, meanIdx, sdIdx
	String fitFunc
	CreateResultsFolder(SampleName)
	SetDataFolder root:$(SampleName):Results
	
	Variable numParams = numOligomers + 2
	Make/O/N=(numFolders, numParams) fit_IntLogNormParams
	fit_IntLogNormParams = NaN
	Make/O/N=(numFolders) fit_IntLogNormChiSq, fit_IntLogNormSuccess
	fit_IntLogNormChiSq = NaN
	fit_IntLogNormSuccess = 0
	
	Variable successCount = 0
	Variable failCount = 0
	
	for(m_cell = 0; m_cell < numFolders; m_cell += 1)
		FolderName = SampleName + num2str(m_cell + 1)
		SetDataFolder root:$(SampleName):$(FolderName)
		
		Wave/Z IntHist, IntHist_x
		if(!WaveExists(IntHist))
			failCount += 1
			continue
		endif
		
		// LogHistGauss 関数を使用（SumLogNorm の代替）
		if(numOligomers <= 8)
			fitFunc = "LogHistGauss" + num2str(numOligomers)
		else
			Printf "  Warning: LogHistGauss supports up to 8 oligomers. Using 8.\r"
			fitFunc = "LogHistGauss8"
		endif
		
		Make/O/D/N=(numParams) coef_IntLogNorm
		
		// 振幅初期値
		for(i = 0; i < numOligomers; i += 1)
			coef_IntLogNorm[i] = 1.0 / numOligomers
		endfor
		
		if(numOligomers == 1)
			meanIdx = 1
			sdIdx = 2
		else
			meanIdx = numOligomers
			sdIdx = numOligomers + 1
		endif
		
		// v5.4.1: 対数ヒストグラムから直接初期値推定
		// IntHist_x は既に log10 空間
		Variable nPts = numpnts(IntHist)
		Variable sumW = 0, sumWX = 0, sumWX2 = 0
		Variable xVal_init, wt_init, p_init
		for(p_init = 0; p_init < nPts; p_init += 1)
			xVal_init = IntHist_x[p_init]
			wt_init = IntHist[p_init]
			if(wt_init > 0)
				sumW += wt_init
				sumWX += wt_init * xVal_init
				sumWX2 += wt_init * xVal_init^2
			endif
		endfor
		
		Variable initLogMean, initLogSD, logVar
		if(sumW > 0)
			initLogMean = sumWX / sumW
			logVar = sumWX2 / sumW - initLogMean^2
			initLogSD = logVar > 0 ? sqrt(logVar) : 0.15
			// 妥当な範囲に制限（log10空間）
			if(initLogSD < 0.05)
				initLogSD = 0.05
			endif
			if(initLogSD > 1.0)
				initLogSD = 1.0
			endif
		else
			// フォールバック
			NVAR MeanIntGauss = root:MeanIntGauss
			initLogMean = log(MeanIntGauss)  // log10
			initLogSD = 0.15
		endif
		
		coef_IntLogNorm[meanIdx] = initLogMean
		coef_IntLogNorm[sdIdx] = initLogSD
		
		fitResult = SafeFitIntensityLogNorm(IntHist, IntHist_x, coef_IntLogNorm, fitFunc)
		
		SetDataFolder root:$(SampleName):Results
		
		if(fitResult == 0)
			for(j = 0; j < numParams; j += 1)
				fit_IntLogNormParams[m_cell][j] = coef_IntLogNorm[j]
			endfor
			NVAR V_chisq
			fit_IntLogNormChiSq[m_cell] = V_chisq
			fit_IntLogNormSuccess[m_cell] = 1
			successCount += 1
		else
			failCount += 1
		endif
		
		ShowProgress(m_cell+1, numFolders, "LogHistGauss")
	endfor
	
	EndProgress()
	Printf "LogHistGauss: Success %d, Failed %d\r", successCount, failCount
	
	SetDataFolder root:
	return successCount
End

static Function SafeFitIntensityLogNorm(histWave, xWave, coefWave, fitFunc)
	Wave histWave, xWave, coefWave
	String fitFunc
	
	Variable V_FitError = 0
	Variable maxRetries = 3
	Variable retry
	
	Variable err
	Duplicate/FREE coefWave, originalCoef
	
	// v5.4.1: リトライ用変数
	Variable numAmps = numpnts(coefWave) - 2
	Variable meanIdx_r = numAmps
	Variable sdIdx_r = numAmps + 1
	Variable ri
	
	// Wave:  > 0
	Variable numParams = numpnts(coefWave)
	Make/T/O/N=(numParams) T_Constraints
	Variable i
	for(i = 0; i < numParams; i += 1)
		T_Constraints[i] = "K" + num2str(i) + " > 0"
	endfor
	
	for(retry = 0; retry < maxRetries; retry += 1)
		V_FitError = 0
		
		try
			AbortOnRTE
			FuncFit/Q/N/W=2 $fitFunc, coefWave, histWave /X=xWave /C=T_Constraints; AbortOnRTE
			
			if(V_FitError == 0)
				KillWaves/Z T_Constraints
				return 0
			endif
		catch
			err = GetRTError(1)
			V_FitError = 1
		endtry
		
		if(retry < maxRetries - 1)
			// v5.4.1: 振幅のみ摂動、mean/SD は初期値から段階的に変化
			for(ri = 0; ri < numAmps; ri += 1)
				coefWave[ri] = abs(originalCoef[ri] * (0.5 + enoise(0.5)))
			endfor
			// mean は初期値を維持、SD は段階的に変化
			coefWave[meanIdx_r] = originalCoef[meanIdx_r]
			if(retry == 0)
				coefWave[sdIdx_r] = originalCoef[sdIdx_r] * 1.5  // より広い SD
			else
				coefWave[sdIdx_r] = originalCoef[sdIdx_r] * 0.7  // より狭い SD
			endif
		endif
	endfor
	
	KillWaves/Z T_Constraints
	return -1
End

// -----------------------------------------------------------------------------
// 
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
//  
// -----------------------------------------------------------------------------
Function DisplayIntensityHistGraph(SampleName)
	String SampleName
	
	// HMMDstate
	NVAR/Z cHMM = root:cHMM
	if(NVAR_Exists(cHMM) && cHMM == 1)
		DisplayIntensityHistHMM(SampleName)
		return 0
	endif
	
	// HMM: S0
	Variable numFolders = CountDataFolders(SampleName)
	Variable m
	String FolderName
	
	// 
	FolderName = SampleName + "1"
	SetDataFolder root:$(SampleName):$(FolderName)
	
	Wave/Z IntHist, IntHist_x
	if(!WaveExists(IntHist))
		// 
		Wave/Z Int_S0_Phist
		if(WaveExists(Int_S0_Phist))
			NVAR IhistBin = root:IhistBin
			NVAR IhistDim = root:IhistDim
			Duplicate/O Int_S0_Phist, IntHist
			Make/O/N=(IhistDim) IntHist_x
			IntHist_x = IhistBin * (p + 0.5)
		else
			Print "IntHist"
			SetDataFolder root:
			return -1
		endif
	endif
	
	// 
	Display/K=1 IntHist vs IntHist_x
	
	// 
	ModifyGraph tick=2, mirror=1, fStyle=1, fSize=14, font="Arial"
	ModifyGraph mode=5, hbFill=2
	ModifyGraph rgb=(0,0,0)
	Label left "Probability density"
	Label bottom "Intensity (a.u.)"
	ModifyGraph width={Aspect,1.618}
	
	String graphTitle = SampleName + " Intensity Histogram"
	DoWindow/T kwTopWin, graphTitle
	
	// 
	Wave/Z fit_IntHist
	if(WaveExists(fit_IntHist))
		AppendToGraph fit_IntHist vs IntHist_x
		ModifyGraph lsize(fit_IntHist)=1.5, rgb(fit_IntHist)=(65280,0,0)
	endif
	
	SetDataFolder root:
	return 0
End

// -----------------------------------------------------------------------------
// 
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// AICmin-max
// DstateS0Sn
// -----------------------------------------------------------------------------
Function AICModelSelection(SampleName, minOlig, maxOlig, [fixParams])
	String SampleName
	Variable minOlig, maxOlig
	Variable fixParams
	
	if(ParamIsDefault(fixParams))
		NVAR/Z cFixIntParameters = root:cFixIntParameters
		if(NVAR_Exists(cFixIntParameters))
			fixParams = cFixIntParameters
		else
			fixParams = 0
		endif
	endif
	
	Variable numFolders = CountDataFolders(SampleName)
	Variable m, n, s, i, j
	String FolderName
	
	NVAR IhistBin = root:IhistBin
	NVAR IhistDim = root:IhistDim
	NVAR MeanIntGauss = root:MeanIntGauss
	NVAR SDIntGauss = root:SDIntGauss
	NVAR/Z Dstate = root:Dstate
	NVAR/Z cHMM = root:cHMM
	
	// HMMDstateS0
	Variable maxState = 0
	if(NVAR_Exists(cHMM) && cHMM == 1 && NVAR_Exists(Dstate))
		maxState = Dstate
	endif
	
	// 
	CreateResultsFolder(SampleName)
	
	Print "=== AIC Model Selection (All States) ==="
	Printf "Sample: %s, Oligomer range: %d - %d, States: S0-S%d\r", SampleName, minOlig, maxOlig, maxState
	Printf "Fix parameters: %d\r", fixParams
	
	for(m = 0; m < numFolders; m += 1)
		FolderName = SampleName + num2str(m + 1)
		SetDataFolder root:$(SampleName):$(FolderName)
		
		Printf "\n--- %s ---\r", FolderName
		
		// Dstate
		for(s = 0; s <= maxState; s += 1)
			String suffix = "_S" + num2str(s)
			String histName = "Int" + suffix + "_Phist"
			
			Wave/Z HistWave = $histName
			if(!WaveExists(HistWave))
				if(s == 0)
					Printf "  S%d: \r", s
				endif
				continue
			endif
			
			// X
			Make/O/N=(IhistDim) IntHist_x_temp
			IntHist_x_temp = IhistBin * (p + 0.5)
			
			Printf "  State S%d:\r", s
			
			// AICWave
			String aicName = "AIC_comparison" + suffix
			String rssName = "RSS_comparison" + suffix
			String penaltyName = "Penalty_comparison" + suffix
			Make/O/N=(maxOlig + 1) $aicName = NaN
			Make/O/N=(maxOlig + 1) $rssName = NaN
			Make/O/N=(maxOlig + 1) $penaltyName = NaN
			Wave AIC_comp = $aicName
			Wave RSS_comp = $rssName
			Wave Penalty_comp = $penaltyName
			
			Variable nData = numpnts(HistWave)
			
			// 
			for(n = minOlig; n <= maxOlig; n += 1)
				Variable numParams = n + 2
				Make/O/D/N=(numParams) coef_temp
				
				for(i = 0; i < n; i += 1)
					coef_temp[i] = 1.0 / n
				endfor
				
				Variable meanIdx, sdIdx
				if(n == 1)
					meanIdx = 1; sdIdx = 2
				elseif(n == 2)
					meanIdx = 2; sdIdx = 3
				else
					meanIdx = n; sdIdx = n + 1
				endif
				coef_temp[meanIdx] = MeanIntGauss
				coef_temp[sdIdx] = SDIntGauss
				
				String holdStr = ""
				Variable kParams
				if(fixParams && n > 1)
					holdStr = PadString("", n, 48)
					holdStr += "11"
					kParams = n  // mean, sd
				else
					kParams = numParams  // 
				endif
				
				String fitFunc = "SumGauss" + num2str(n)
				Variable fitResult
				fitResult = SafeFitIntensity(HistWave, IntHist_x_temp, coef_temp, fitFunc, holdStr)
				
				if(fitResult == 0)
					Make/O/N=(numpnts(HistWave)) fit_temp
					Variable xVal
					for(j = 0; j < numpnts(IntHist_x_temp); j += 1)
						xVal = IntHist_x_temp[j]
						fit_temp[j] = EvaluateSumGauss(coef_temp, xVal, n)
					endfor
					
					Make/FREE/N=(numpnts(HistWave)) residuals
					residuals = (HistWave - fit_temp)^2
					Variable RSS = sum(residuals)
					
					// AIC: AIC = n*ln(RSS/n) + 2k
					Variable logLikTerm, penaltyTerm, AIC_val
					if(RSS > 0 && nData > 0)
						logLikTerm = nData * ln(RSS / nData)
						penaltyTerm = 2 * kParams
						AIC_val = logLikTerm + penaltyTerm
					else
						logLikTerm = NaN
						penaltyTerm = 2 * kParams
						AIC_val = NaN
					endif
					
					AIC_comp[n] = AIC_val
					RSS_comp[n] = RSS
					Penalty_comp[n] = penaltyTerm
					
					Printf "    n=%d: RSS=%.6f, Penalty=%d, AIC=%.2f\r", n, RSS, penaltyTerm, AIC_val
					
					KillWaves/Z fit_temp
				else
					Printf "    n=%d: \r", n
				endif
				
				KillWaves/Z coef_temp
			endfor
			
			// AIC
			Variable minAIC_val = Inf
			Variable bestN = minOlig
			for(n = minOlig; n <= maxOlig; n += 1)
				if(numtype(AIC_comp[n]) == 0 && AIC_comp[n] < minAIC_val)
					minAIC_val = AIC_comp[n]
					bestN = n
				endif
			endfor
			
			Printf "    >>> Best model: n=%d (AIC=%.2f)\r", bestN, minAIC_val
			
			// 
			Variable numParamsBest = bestN + 2
			Make/O/D/N=(numParamsBest) coef_best
			
			for(i = 0; i < bestN; i += 1)
				coef_best[i] = 1.0 / bestN
			endfor
			
			if(bestN == 1)
				meanIdx = 1; sdIdx = 2
			elseif(bestN == 2)
				meanIdx = 2; sdIdx = 3
			else
				meanIdx = bestN; sdIdx = bestN + 1
			endif
			coef_best[meanIdx] = MeanIntGauss
			coef_best[sdIdx] = SDIntGauss
			
			holdStr = ""
			if(fixParams && bestN > 1)
				holdStr = PadString("", bestN, 48)
				holdStr += "11"
			endif
			
			fitFunc = "SumGauss" + num2str(bestN)
			fitResult = SafeFitIntensity(HistWave, IntHist_x_temp, coef_best, fitFunc, holdStr)
			
			if(fitResult == 0)
				// 
				String fitHistName = "fit_Int" + suffix + "_Phist"
				Make/O/N=(numpnts(IntHist_x_temp)) $fitHistName
				Wave FitHist = $fitHistName
				for(j = 0; j < numpnts(IntHist_x_temp); j += 1)
					xVal = IntHist_x_temp[j]
					FitHist[j] = EvaluateSumGauss(coef_best, xVal, bestN)
				endfor
				SetScale/P x, IntHist_x_temp[0], (IntHist_x_temp[1] - IntHist_x_temp[0]), FitHist
				
				// 
				String coefName = "coef_Int" + suffix
				Duplicate/O coef_best, $coefName
				
				// bestN
				String bestNName = "bestN" + suffix
				Variable/G $bestNName = bestN
			endif
			
			KillWaves/Z coef_best, IntHist_x_temp
		endfor
		
		ShowProgress(m+1, numFolders, "AIC")
	endfor
	
	EndProgress()
	
	// AIC/RSSS0
	DisplayAICComparisonGraph(SampleName, minOlig, maxOlig)
	
	SetDataFolder root:
	Print "AIC model selection complete"
End

// -----------------------------------------------------------------------------
// AIC/RSS1
// -----------------------------------------------------------------------------
Function DisplayAICComparisonGraph(SampleName, minOlig, maxOlig)
	String SampleName
	Variable minOlig, maxOlig
	
	String FolderName = SampleName + "1"
	SetDataFolder root:$(SampleName):$(FolderName)
	
	NVAR/Z Dstate = root:Dstate
	NVAR/Z cHMM = root:cHMM
	
	Variable maxState = 0
	if(NVAR_Exists(cHMM) && cHMM == 1 && NVAR_Exists(Dstate))
		maxState = Dstate
	endif
	
	// AIC + RSS 
	String winNameAIC = "AIC_" + SampleName
	DoWindow/K $winNameAIC
	
	Wave/Z RSS_Global, AIC_Global
	if(WaveExists(AIC_Global) && WaveExists(RSS_Global))
		Display/K=1/N=$winNameAIC AIC_Global
		AppendToGraph/R RSS_Global
		
		ModifyGraph mode=4, marker=19, lsize=1.5
		ModifyGraph rgb(AIC_Global)=(0,0,0)  // : AIC
		ModifyGraph rgb(RSS_Global)=(0,0,65280)  // : RSS
		
		ModifyGraph tick=0, mirror=0
		ModifyGraph fStyle=1, fSize=14, font="Arial"
		Label left "AIC"
		Label right "RSS"
		Label bottom "Oligomer size (n)"
		SetAxis bottom minOlig - 0.5, maxOlig + 0.5
		ModifyGraph width={Aspect,1.618}
		
		// 
		Legend/C/N=text0/F=0/B=1/A=RT "\\s(AIC_Global) AIC\r\\s(RSS_Global) RSS"
		
		// AIC
		WaveStats/Q AIC_Global
		Variable minIdx = V_minloc
		if(numtype(minIdx) == 0)
			Tag/C/N=bestTag/F=0/L=0/X=0/Y=10 AIC_Global, minIdx, "Best: n=" + num2str(minIdx)
		endif
	endif
	
	SetDataFolder root:
End

// -----------------------------------------------------------------------------
// Dstate
// pop_osize_Snmean_osize
// -----------------------------------------------------------------------------
Function DisplayPopulationGraph(SampleName)
	String SampleName
	
	Variable numFolders = CountDataFolders(SampleName)
	Variable m, s, i
	String FolderName
	
	NVAR/Z Dstate = root:Dstate
	NVAR/Z cHMM = root:cHMM
	
	Variable maxState = 0
	if(NVAR_Exists(cHMM) && cHMM == 1 && NVAR_Exists(Dstate))
		maxState = Dstate
	endif
	
	for(m = 0; m < numFolders; m += 1)
		FolderName = SampleName + num2str(m + 1)
		SetDataFolder root:$(SampleName):$(FolderName)
		
		// population_S0
		Wave/Z population_S0
		if(!WaveExists(population_S0))
			continue
		endif
		
		Variable numOligomers = numpnts(population_S0)
		
		// %Wave
		Make/O/N=(numOligomers) pop_pct_S0
		pop_pct_S0 = population_S0 * 100
		SetScale/P x, 1, 1, pop_pct_S0  // x1
		
		for(s = 1; s <= maxState; s += 1)
			String popName = "population_S" + num2str(s)
			Wave/Z PopWave = $popName
			if(WaveExists(PopWave))
				String pctName = "pop_pct_S" + num2str(s)
				Make/O/N=(numOligomers) $pctName
				Wave PctWave = $pctName
				PctWave = PopWave * 100
				SetScale/P x, 1, 1, PctWave
			endif
		endfor
		
		// ========================================
		// pop_osize_Snmean_osize
		// ========================================
		// mean_osize: [0]=S0, [1]=S1, ..., [maxState]=Sn
		Make/O/N=(maxState + 1) mean_osize = NaN
		
		// statepop_osizemean oligomer size
		for(s = 0; s <= maxState; s += 1)
			String pctSrcName = "pop_pct_S" + num2str(s)
			String osizeName = "pop_osize_S" + num2str(s)
			
			Wave/Z PctSrc = $pctSrcName
			if(!WaveExists(PctSrc))
				continue
			endif
			
			// 
			Variable totalPct = sum(PctSrc)
			
			// pop_osize_Sn = pop_pct_Sn / Σpop_pct_Sn=1
			Make/O/N=(numOligomers) $osizeName = 0
			Wave OsizeWave = $osizeName
			SetScale/P x, 1, 1, OsizeWave  // x1oligomer size
			
			if(totalPct > 0)
				OsizeWave = PctSrc / totalPct
			endif
			
			// mean oligomer size = Σ(oligomer_size * pop_osize)
			// oligomer_size = index + 1 (since SetScale starts at 1)
			Variable meanOsize = 0
			for(i = 0; i < numOligomers; i += 1)
				meanOsize += (i + 1) * OsizeWave[i]
			endfor
			mean_osize[s] = meanOsize
		endfor
		
		// 
		String winName = "Population_" + FolderName
		DoWindow/K $winName
		
		Display/K=1/N=$winName pop_pct_S0
		ModifyGraph rgb(pop_pct_S0)=(0,0,0)
		
		for(s = 1; s <= maxState; s += 1)
			String pctNameDisp = "pop_pct_S" + num2str(s)
			Wave/Z PctWaveDisp = $pctNameDisp
			if(WaveExists(PctWaveDisp))
				AppendToGraph PctWaveDisp
				switch(s)
					case 1:
						ModifyGraph rgb($pctNameDisp)=(0,0,65280)
						break
					case 2:
						ModifyGraph rgb($pctNameDisp)=(65280,43520,0)
						break
					case 3:
						ModifyGraph rgb($pctNameDisp)=(0,39168,0)
						break
					case 4:
						ModifyGraph rgb($pctNameDisp)=(65280,0,0)
						break
				endswitch
			endif
		endfor
		
		// 
		ModifyGraph mode=4, marker=19, lsize=1.5  // 
		ModifyGraph tick=0, mirror=0
		ModifyGraph fStyle=1, fSize=14, font="Arial"
		Label left "Population (%)"
		Label bottom "Oligomer size"
		SetAxis left 0, *
		SetAxis bottom 0.5, numOligomers + 0.5
		ModifyGraph width={Aspect,1.618}
		
		// GetDstateName
		String legendStr = "\\F'Arial'\\Z12\r\\s(pop_pct_S0) " + GetDstateName(0, maxState)
		for(s = 1; s <= maxState; s += 1)
			pctNameDisp = "pop_pct_S" + num2str(s)
			Wave/Z PW = $pctNameDisp
			if(WaveExists(PW))
				legendStr += "\r\\s(" + pctNameDisp + ") " + GetDstateName(s, maxState)
			endif
		endfor
		TextBox/C/N=text0/F=0/B=1/A=RT legendStr
		
		// 
		Printf "\n=== Population Distribution (%s) ===\r", FolderName
		Printf "Oligomer\tS0"
		for(s = 1; s <= maxState; s += 1)
			Printf "\tS%d", s
		endfor
		Printf "\r"
		
		for(i = 0; i < numOligomers; i += 1)
			Printf "%d-mer\t%.1f%%", i+1, pop_pct_S0[i]
			for(s = 1; s <= maxState; s += 1)
				String pctNamePrint = "pop_pct_S" + num2str(s)
				Wave/Z PctPrint = $pctNamePrint
				if(WaveExists(PctPrint))
					Printf "\t%.1f%%", PctPrint[i]
				endif
			endfor
			Printf "\r"
		endfor
		
		// Mean Oligomer Size 
		Printf "\n--- Mean Oligomer Size ---\r"
		for(s = 0; s <= maxState; s += 1)
			Printf "S%d: %.2f\r", s, mean_osize[s]
		endfor
	endfor
	
	// ========================================
	// Matrix/Results  mean_osize 
	// ========================================
	CollectMeanOsizeToMatrix(SampleName, maxState)
	
	SetDataFolder root:
End

// -----------------------------------------------------------------------------
// mean_osize  Matrix/Results 
// -----------------------------------------------------------------------------
Function CollectMeanOsizeToMatrix(SampleName, maxState)
	String SampleName
	Variable maxState
	
	Variable numFolders = CountDataFolders(SampleName)
	Variable m, s
	String FolderName
	
	// Matrix
	String matrixPath = "root:" + SampleName + ":Matrix"
	if(!DataFolderExists(matrixPath))
		NewDataFolder $matrixPath
	endif
	
	// mean_osize_m: [state][cell]
	SetDataFolder $matrixPath
	Make/O/N=(maxState + 1, numFolders) mean_osize_m = NaN
	Wave osizeMatrix = mean_osize_m
	
	//  mean_osize 
	for(m = 0; m < numFolders; m += 1)
		FolderName = SampleName + num2str(m + 1)
		String osizePath = "root:" + SampleName + ":" + FolderName + ":mean_osize"
		Wave/Z cellOsize = $osizePath
		
		if(WaveExists(cellOsize))
			for(s = 0; s <= maxState; s += 1)
				if(s < numpnts(cellOsize))
					osizeMatrix[s][m] = cellOsize[s]
				endif
			endfor
		endif
	endfor
	
	// Results
	String resultsPath = "root:" + SampleName + ":Results"
	if(!DataFolderExists(resultsPath))
		NewDataFolder $resultsPath
	endif
	SetDataFolder $resultsPath
	
	// : mean_osize_m_avg, _sd, _sem, _n
	Make/O/N=(maxState + 1) mean_osize_m_avg = NaN
	Make/O/N=(maxState + 1) mean_osize_m_sd = NaN
	Make/O/N=(maxState + 1) mean_osize_m_sem = NaN
	Make/O/N=(maxState + 1) mean_osize_m_n = NaN
	
	Wave avgW = mean_osize_m_avg
	Wave sdW = mean_osize_m_sd
	Wave semW = mean_osize_m_sem
	Wave nW = mean_osize_m_n
	
	for(s = 0; s <= maxState; s += 1)
		// 
		Make/FREE/N=(numFolders) tempData
		Variable k, validCount = 0
		for(k = 0; k < numFolders; k += 1)
			Variable val = osizeMatrix[s][k]
			if(numtype(val) == 0)  // NaN
				tempData[validCount] = val
				validCount += 1
			endif
		endfor
		
		if(validCount > 0)
			Redimension/N=(validCount) tempData
			WaveStats/Q tempData
			avgW[s] = V_avg
			sdW[s] = V_sdev
			nW[s] = V_npnts
			if(V_npnts > 1)
				semW[s] = V_sdev / sqrt(V_npnts)
			else
				semW[s] = 0
			endif
		endif
	endfor
	
	SetDataFolder root:
	Print "  mean_osize_m and statistics created in Matrix/Results"
End

// -----------------------------------------------------------------------------
// CollectMeanOsizeToMatrixEx - basePath/waveSuffix
// -----------------------------------------------------------------------------
// Seg: root:Seg0:SampleName: 
// Total: mean_osize_m (2D: [state][cell])
Function CollectMeanOsizeToMatrixEx(SampleName, maxState, basePath, waveSuffix)
	String SampleName
	Variable maxState
	String basePath      // "root:Seg0" 
	String waveSuffix    // "_Seg0", "_Seg1" 
	
	String savedDF = GetDataFolder(1)
	
	// 
	if(StringMatch(basePath[strlen(basePath)-1], ":") == 0)
		basePath += ":"
	endif
	
	// 
	Variable numFolders = CountDataFoldersInPath(basePath, SampleName)
	if(numFolders == 0)
		SetDataFolder $savedDF
		return -1
	endif
	
	Variable m, s
	String FolderName
	String samplePath = basePath + SampleName + ":"
	
	// Matrix
	String matrixPath = samplePath + "Matrix"
	if(!DataFolderExists(matrixPath))
		NewDataFolder $matrixPath
	endif
	
	// mean_osize_m: [state][cell] 2D (Total)
	SetDataFolder $matrixPath
	Make/O/N=(maxState + 1, numFolders) mean_osize_m = NaN
	Wave osizeMatrix = mean_osize_m
	
	// mean_osize_waveSuffix
	for(m = 0; m < numFolders; m += 1)
		FolderName = SampleName + num2str(m + 1)
		String cellPath = samplePath + FolderName
		
		if(!DataFolderExists(cellPath))
			continue
		endif
		
		// waveSuffixmean_osize
		String osizeWaveName = "mean_osize" + waveSuffix
		String osizePath = cellPath + ":" + osizeWaveName
		Wave/Z cellOsize = $osizePath
		
		if(WaveExists(cellOsize))
			for(s = 0; s <= maxState; s += 1)
				if(s < numpnts(cellOsize))
					osizeMatrix[s][m] = cellOsize[s]
				endif
			endfor
		endif
	endfor
	
	// Results
	String resultsPath = samplePath + "Results"
	if(!DataFolderExists(resultsPath))
		NewDataFolder $resultsPath
	endif
	SetDataFolder $resultsPath
	
	// : mean_osize_m_avg, _sd, _sem, _n (Total)
	Make/O/N=(maxState + 1) mean_osize_m_avg = NaN
	Make/O/N=(maxState + 1) mean_osize_m_sd = NaN
	Make/O/N=(maxState + 1) mean_osize_m_sem = NaN
	Make/O/N=(maxState + 1) mean_osize_m_n = NaN
	
	Wave avgW = mean_osize_m_avg
	Wave sdW = mean_osize_m_sd
	Wave semW = mean_osize_m_sem
	Wave nW = mean_osize_m_n
	
	for(s = 0; s <= maxState; s += 1)
		// 
		Make/FREE/N=(numFolders) tempData
		Variable k, validCount = 0
		for(k = 0; k < numFolders; k += 1)
			Variable val = osizeMatrix[s][k]
			if(numtype(val) == 0)  // NaN
				tempData[validCount] = val
				validCount += 1
			endif
		endfor
		
		if(validCount > 0)
			Redimension/N=(validCount) tempData
			WaveStats/Q tempData
			avgW[s] = V_avg
			sdW[s] = V_sdev
			nW[s] = V_npnts
			if(V_npnts > 1)
				semW[s] = V_sdev / sqrt(V_npnts)
			else
				semW[s] = 0
			endif
		endif
	endfor
	
	SetDataFolder $savedDF
	Print "  mean_osize_m and statistics created for " + SampleName
	return 0
End

// -----------------------------------------------------------------------------
// CalculateMeanOsizeEx - basePath/waveSuffix
// -----------------------------------------------------------------------------
// population_Snmean_osizeMatrix/Results
Function CalculateMeanOsizeEx(SampleName, basePath, waveSuffix)
	String SampleName
	String basePath      // "root:EC1" 
	String waveSuffix    // "_C1E", "_C2E" 
	
	String savedDF = GetDataFolder(1)
	
	// 
	if(StringMatch(basePath[strlen(basePath)-1], ":") == 0)
		basePath += ":"
	endif
	
	Variable numFolders = CountDataFoldersInPath(basePath, SampleName)
	if(numFolders == 0)
		SetDataFolder $savedDF
		return -1
	endif
	
	Variable m, s, i
	String FolderName
	String samplePath = basePath + SampleName + ":"
	
	NVAR/Z Dstate = root:Dstate
	NVAR/Z cHMM = root:cHMM
	
	Variable maxState = 0
	if(NVAR_Exists(cHMM) && cHMM == 1 && NVAR_Exists(Dstate))
		maxState = Dstate
	endif
	
	// mean_osize
	for(m = 0; m < numFolders; m += 1)
		FolderName = SampleName + num2str(m + 1)
		String cellPath = samplePath + FolderName
		
		if(!DataFolderExists(cellPath))
			continue
		endif
		
		SetDataFolder $cellPath
		
		// population_S0 + waveSuffix 
		String pop0Name = "population_S0" + waveSuffix
		Wave/Z population_S0 = $pop0Name
		if(!WaveExists(population_S0))
			continue
		endif
		
		Variable numOligomers = numpnts(population_S0)
		
		// mean_osize + waveSuffix 
		String osizeWaveName = "mean_osize" + waveSuffix
		Make/O/N=(maxState + 1) $osizeWaveName = NaN
		Wave mean_osize = $osizeWaveName
		
		// statemean oligomer size
		for(s = 0; s <= maxState; s += 1)
			String popName = "population_S" + num2str(s) + waveSuffix
			Wave/Z PopWave = $popName
			
			if(!WaveExists(PopWave))
				continue
			endif
			
			// 
			Variable totalPop = sum(PopWave)
			
			if(totalPop > 0)
				// mean oligomer size = Σ(oligomer_size * pop) / Σ(pop)
				Variable meanOsize = 0
				for(i = 0; i < numOligomers; i += 1)
					meanOsize += (i + 1) * PopWave[i]
				endfor
				meanOsize /= totalPop
				mean_osize[s] = meanOsize
			endif
		endfor
	endfor
	
	// Matrix/Results 
	CollectMeanOsizeToMatrixEx(SampleName, maxState, basePath, waveSuffix)
	
	SetDataFolder $savedDF
	return 0
End

// -----------------------------------------------------------------------------
// CalculatePopulationFromCoefEx - coef_IntpopulationMean Oligomer Size
// -----------------------------------------------------------------------------
// basePath/waveSuffix: Colocalization
Function CalculatePopulationFromCoefEx(SampleName, basePath, waveSuffix)
	String SampleName
	String basePath      // "root:EC1" 
	String waveSuffix    // "_C1E", "_C2E" 
	
	String savedDF = GetDataFolder(1)
	
	Printf "CalculatePopulationFromCoefEx: Sample=%s, basePath=%s, waveSuffix=%s\r", SampleName, basePath, waveSuffix
	
	// 
	if(StringMatch(basePath[strlen(basePath)-1], ":") == 0)
		basePath += ":"
	endif
	
	Variable numFolders = CountDataFoldersInPath(basePath, SampleName)
	Printf "  numFolders=%d\r", numFolders
	if(numFolders == 0)
		Print "CalculatePopulationFromCoefEx: No folders found for " + SampleName
		SetDataFolder $savedDF
		return -1
	endif
	
	Variable m, s, i
	String FolderName
	String samplePath = basePath + SampleName + ":"
	
	NVAR/Z Dstate = root:Dstate
	NVAR/Z cHMM = root:cHMM
	
	Variable maxState = 0
	if(NVAR_Exists(cHMM) && cHMM == 1 && NVAR_Exists(Dstate))
		maxState = Dstate
	endif
	
	// coef_IntpopulationMean Oligomer Size
	Variable cellsProcessed = 0
	for(m = 0; m < numFolders; m += 1)
		FolderName = SampleName + num2str(m + 1)
		String cellPath = samplePath + FolderName
		
		if(!DataFolderExists(cellPath))
			continue
		endif
		
		SetDataFolder $cellPath
		
		// coef_Int_S0 + waveSuffix 
		String coef0Name = "coef_Int_S0" + waveSuffix
		Wave/Z coef_S0 = $coef0Name
		if(!WaveExists(coef_S0))
			continue
		endif
		
		cellsProcessed += 1
		
		// : coef = [A1, A2, ..., An, mean, sd]
		Variable numOligomers = numpnts(coef_S0) - 2
		if(numOligomers < 1)
			continue
		endif
		
		// mean_osize + waveSuffix 
		String osizeWaveName = "mean_osize" + waveSuffix
		Make/O/N=(maxState + 1) $osizeWaveName = NaN
		Wave mean_osize = $osizeWaveName
		
		// statepopulationmean oligomer size
		for(s = 0; s <= maxState; s += 1)
			String coefName = "coef_Int_S" + num2str(s) + waveSuffix
			Wave/Z coefWave = $coefName
			
			if(!WaveExists(coefWave))
				continue
			endif
			
			// population_Sn_waveSuffix 
			String popName = "population_S" + num2str(s) + waveSuffix
			Make/O/N=(numOligomers) $popName = 0
			Wave PopWave = $popName
			
			// 
			Variable ampSum = 0
			for(i = 0; i < numOligomers; i += 1)
				ampSum += coefWave[i]
			endfor
			
			// population
			if(ampSum > 0)
				for(i = 0; i < numOligomers; i += 1)
					PopWave[i] = coefWave[i] / ampSum
				endfor
			endif
			
			// mean oligomer size = Σ(oligomer_size * pop)
			Variable meanOsize = 0
			for(i = 0; i < numOligomers; i += 1)
				meanOsize += (i + 1) * PopWave[i]
			endfor
			mean_osize[s] = meanOsize
		endfor
	endfor
	
	// Matrix/Results 
	CollectMeanOsizeToMatrixEx(SampleName, maxState, basePath, waveSuffix)
	
	SetDataFolder $savedDF
	return 0
End

// =============================================================================
// Global Intensity Fitting with Shared Mean/SD
// =============================================================================

// -----------------------------------------------------------------------------
// Global Intensity Fitting - Global Fit
// Fit
// -----------------------------------------------------------------------------
Function GlobalFitIntensity(SampleName, numOligomers, fixMean, fixSD, [basePath, waveSuffix])
	String SampleName
	Variable numOligomers, fixMean, fixSD
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
	
	NVAR/Z Dstate = root:Dstate
	NVAR/Z cHMM = root:cHMM
	
	// HMMDstateS0
	Variable maxState = 0
	if(NVAR_Exists(cHMM) && cHMM == 1 && NVAR_Exists(Dstate))
		maxState = Dstate
	endif
	
	Print "=== Global Intensity Fitting ==="
	Printf "Sample: %s, n=%d, States: S0-S%d, Fix Mean: %d, Fix SD: %d\r", SampleName, numOligomers, maxState, fixMean, fixSD
	if(strlen(waveSuffix) > 0)
		Printf "basePath: %s, waveSuffix: %s\r", basePath, waveSuffix
	endif
	
	Variable successCount = 0
	Variable failCount = 0
	
	for(m = 0; m < numFolders; m += 1)
		FolderName = SampleName + num2str(m + 1)
		
		Variable globalRSS, globalMean, globalSD
		Variable fitSuccess = GlobalFitIntensityShared(SampleName, FolderName, numOligomers, maxState, fixMean, fixSD, globalRSS, globalMean, globalSD, basePath=basePath, waveSuffix=waveSuffix)
		
		if(fitSuccess)
			successCount += 1
			Printf "  %s: Success (RSS=%.6f, mean=%.1f, sd=%.1f)\r", FolderName, globalRSS, globalMean, globalSD
		else
			failCount += 1
			Printf "  %s: Failed\r", FolderName
		endif
		
		ShowProgress(m+1, numFolders, "Global Intensity Fitting")
	endfor
	
	EndProgress()
	Printf "Global Intensity Fitting complete: Success %d, Failed %d\r", successCount, failCount
	
	SetDataFolder root:
	return successCount
End

// -----------------------------------------------------------------------------
// Global AIC Model Selection - Dstatemean, sd
// -----------------------------------------------------------------------------
Function GlobalAICModelSelection(SampleName, minOlig, maxOlig, [fixMean, fixSD])
	String SampleName
	Variable minOlig, maxOlig
	Variable fixMean, fixSD
	
	if(ParamIsDefault(fixMean))
		NVAR/Z cFixMean = root:cFixMean
		if(NVAR_Exists(cFixMean))
			fixMean = cFixMean
		else
			fixMean = 0
		endif
	endif
	
	if(ParamIsDefault(fixSD))
		NVAR/Z cFixSD = root:cFixSD
		if(NVAR_Exists(cFixSD))
			fixSD = cFixSD
		else
			fixSD = 0
		endif
	endif
	
	Variable numFolders = CountDataFolders(SampleName)
	Variable m, n, s, i, j
	String FolderName
	
	NVAR IhistBin = root:IhistBin
	NVAR IhistDim = root:IhistDim
	NVAR MeanIntGauss = root:MeanIntGauss
	NVAR SDIntGauss = root:SDIntGauss
	NVAR/Z Dstate = root:Dstate
	NVAR/Z cHMM = root:cHMM
	
	// HMMDstateS0
	Variable maxState = 0
	if(NVAR_Exists(cHMM) && cHMM == 1 && NVAR_Exists(Dstate))
		maxState = Dstate
	endif
	
	Variable numStates = maxState + 1
	
	Print "=== Global AIC Model Selection ==="
	Printf "Sample: %s, Oligomer range: %d - %d, States: S0-S%d\r", SampleName, minOlig, maxOlig, maxState
	Printf "Fix Mean: %d, Fix SD: %d\r", fixMean, fixSD
	
	for(m = 0; m < numFolders; m += 1)
		FolderName = SampleName + num2str(m + 1)
		SetDataFolder root:$(SampleName):$(FolderName)
		
		Printf "\n--- %s ---\r", FolderName
		
		// Dstate
		Variable validStates = 0
		for(s = 0; s <= maxState; s += 1)
			String histName = "Int_S" + num2str(s) + "_Phist"
			Wave/Z HW = $histName
			if(WaveExists(HW))
				validStates += 1
			endif
		endfor
		
		if(validStates == 0)
			Printf "  No valid histograms found\r"
			continue
		endif
		
		Printf "  validStates=%d, IhistDim=%d\r", validStates, IhistDim
		
		// Global AIC/RSS/PenaltyWave
		Make/O/N=(maxOlig + 1) AIC_Global = NaN
		Make/O/N=(maxOlig + 1) RSS_Global = NaN
		Make/O/N=(maxOlig + 1) Penalty_Global = NaN
		Make/O/N=(maxOlig + 1) Mean_Global = NaN
		Make/O/N=(maxOlig + 1) SD_Global = NaN
		Make/O/N=(maxOlig + 1) LogLik_Global = NaN
		
		// Global fitting
		for(n = minOlig; n <= maxOlig; n += 1)
			Printf "  n=%d: ", n
			
			Variable globalRSS, globalMean, globalSD
			Variable fitSuccess = GlobalFitIntensityShared(SampleName, FolderName, n, maxState, fixMean, fixSD, globalRSS, globalMean, globalSD)
			
			if(fitSuccess)
				// 
				// Dstatenmean, sd
				Variable kParams = n * validStates
				if(!fixMean)
					kParams += 1  // mean
				endif
				if(!fixSD)
					kParams += 1  // SD
				endif
				
				// 
				NVAR/Z LogIntensityScale = LogIntensityScale
				Variable histDimForAIC = 0
				Variable isLogScaleAIC = 0
				if(NVAR_Exists(LogIntensityScale) && LogIntensityScale == 1)
					isLogScaleAIC = 1
				endif
				
				// 
				Variable ss
				for(ss = 0; ss <= maxState; ss += 1)
					String histCheckName = "Int_S" + num2str(ss) + "_Phist"
					Wave/Z HWC = $histCheckName
					if(WaveExists(HWC))
						histDimForAIC = numpnts(HWC)
						break
					endif
				endfor
				
				if(histDimForAIC == 0)
					histDimForAIC = IhistDim  // 
				endif
				
				Variable totalPoints = histDimForAIC * validStates
				
				// AIC
				// AIC = n * (ln(2π * Vss) + 1) + 2k
				// Vss = RSS / n
				Variable AIC_val, logLikTerm
				if(globalRSS > 0 && totalPoints > 0)
					Variable Vss = globalRSS / totalPoints
					logLikTerm = totalPoints * (ln(2 * pi * Vss) + 1)
					AIC_val = logLikTerm + 2 * kParams
				else
					AIC_val = NaN
					logLikTerm = NaN
				endif
				
				AIC_Global[n] = AIC_val
				RSS_Global[n] = globalRSS
				Penalty_Global[n] = 2 * kParams
				Mean_Global[n] = globalMean
				SD_Global[n] = globalSD
				LogLik_Global[n] = logLikTerm
				
				// 
				String scaleStr = SelectString(isLogScaleAIC, "Linear", "Log10")
				Printf "  [%s] histDim=%d, totalPts=%d, RSS=%.6f, Vss=%.2e, ", scaleStr, histDimForAIC, totalPoints, globalRSS, Vss
				Printf "-2LogLik=%.1f, k=%d, Penalty=%d, AIC=%.2f (mean=%.3f, sd=%.3f)\r", logLikTerm, kParams, 2*kParams, AIC_val, globalMean, globalSD
			else
				Printf "Global fitting failed\r"
			endif
		endfor
		
		// AIC
		Variable minAIC_val = Inf
		Variable bestN = minOlig
		for(n = minOlig; n <= maxOlig; n += 1)
			if(numtype(AIC_Global[n]) == 0 && AIC_Global[n] < minAIC_val)
				minAIC_val = AIC_Global[n]
				bestN = n
			endif
		endfor
		
		Printf "\n  >>> Best model: n=%d (AIC=%.2f)\r", bestN, minAIC_val
		
		// 
		Variable finalRSS, finalMean, finalSD
		GlobalFitIntensityShared(SampleName, FolderName, bestN, maxState, fixMean, fixSD, finalRSS, finalMean, finalSD)
		
		// bestN
		Variable/G bestN_Global = bestN
		Variable/G Mean_Optimal = finalMean
		Variable/G SD_Optimal = finalSD
		
		ShowProgress(m+1, numFolders, "Global AIC")
	endfor
	
	EndProgress()
	
	// 
	DisplayAICComparisonGraph(SampleName, minOlig, maxOlig)
	DisplayIntensityHistGraph(SampleName)
	
	SetDataFolder root:
	Print "Global AIC model selection complete"
End

// -----------------------------------------------------------------------------
// Global Fitting with Shared Mean/SD - 
// Dstate1FuncFit
// -----------------------------------------------------------------------------
Function GlobalFitIntensityShared(SampleName, FolderName, numOligomers, maxState, fixMean, fixSD, outRSS, outMean, outSD, [basePath, waveSuffix])
	String SampleName, FolderName
	Variable numOligomers, maxState, fixMean, fixSD
	Variable &outRSS, &outMean, &outSD
	String basePath, waveSuffix
	
	// 
	if(ParamIsDefault(basePath))
		basePath = "root"
	endif
	if(ParamIsDefault(waveSuffix))
		waveSuffix = ""
	endif
	
	// 
	String cellPath
	if(StringMatch(basePath, "root"))
		cellPath = "root:" + SampleName + ":" + FolderName
	else
		cellPath = basePath + ":" + SampleName + ":" + FolderName
	endif
	
	if(!DataFolderExists(cellPath))
		outRSS = NaN
		outMean = NaN
		outSD = NaN
		return 0
	endif
	
	SetDataFolder $cellPath
	
	NVAR IhistBin = root:IhistBin
	NVAR IhistDim = root:IhistDim
	NVAR MeanIntGauss = root:MeanIntGauss
	NVAR SDIntGauss = root:SDIntGauss
	NVAR SDIntLognorm = root:SDIntLognorm
	
	// 
	NVAR/Z LogIntensityScale = LogIntensityScale
	NVAR/Z LogIntBin = LogIntBin
	NVAR/Z LogIntMin = LogIntMin
	NVAR/Z LogIntDim = LogIntDim
	
	Variable isLogScale = 0
	Variable histBin, histDim, histMin, initMean, initSD
	Variable si2, areaSum, normArea, totalAreaSum, ai  // v5.4.1: population calculation variables
	Variable adaptSumW, adaptSumWX, adaptSumWX2, adaptXval, adaptWt  // v5.4.3: adaptive init
	Variable adaptMean, adaptVar, adaptSD, pi_init, peakHeight  // v5.4.3
	
	if(NVAR_Exists(LogIntensityScale) && LogIntensityScale == 1)
		isLogScale = 1
		histBin = LogIntBin
		histMin = LogIntMin
		// v5.4.3: 初期値はヒストグラムデータから推定（後で計算）
		initMean = log(MeanIntGauss)  // フォールバック値
		initSD = SDIntLognorm
		Printf "  [v5.4.4] LogScale=ON, histBin=%.4f, histMin=%.4f\r", histBin, histMin
	else
		histBin = IhistBin
		histMin = 0
		initMean = MeanIntGauss
		initSD = SDIntGauss
	endif
	
	Variable s, i, j
	
	// Dstate
	// Wave
	Variable validStates = 0
	histDim = 0
	for(s = 0; s <= maxState; s += 1)
		String histNameCheck = "Int_S" + num2str(s) + waveSuffix + "_Phist"
		Wave/Z HWCheck = $histNameCheck
		if(WaveExists(HWCheck))
			validStates += 1
			if(histDim == 0)
				histDim = numpnts(HWCheck)  // Wave
			endif
		endif
	endfor
	
	if(validStates == 0 || histDim == 0)
		outRSS = NaN
		outMean = NaN
		outSD = NaN
		return 0
	endif
	
	// Wave
	Variable totalPoints = histDim * validStates
	Make/O/D/N=(totalPoints) ConcatHist, ConcatX
	
	// 
	Variable/G root:gNumSegments = validStates
	Variable/G root:gSegmentSize = histDim
	Variable/G root:gNumOligomers = numOligomers
	Variable/G root:gLogScale = isLogScale  // 
	
	Variable offset = 0
	Variable segIdx = 0
	for(s = 0; s <= maxState; s += 1)
		String histName = "Int_S" + num2str(s) + waveSuffix + "_Phist"
		Wave/Z HistWave = $histName
		if(!WaveExists(HistWave))
			continue
		endif
		
		// 
		for(i = 0; i < histDim; i += 1)
			ConcatHist[offset + i] = HistWave[i]
			// X: x + segIdx * 1000000
			// 
			ConcatX[offset + i] = histMin + histBin * (i + 0.5) + segIdx * 1e7
		endfor
		
		offset += histDim
		segIdx += 1
	endfor
	
	// Wave
	// : [A1_S0, A2_S0, ..., An_S0, A1_S1, ..., An_Sn, mean, sd]
	Variable numAmplitudes = numOligomers * validStates
	Variable numParams = numAmplitudes + 2
	Make/O/D/N=(numParams) GlobalCoef
	
	// 初期値
	for(i = 0; i < numAmplitudes; i += 1)
		GlobalCoef[i] = 0.01
	endfor
	GlobalCoef[numAmplitudes] = initMean
	GlobalCoef[numAmplitudes + 1] = initSD
	
	// v5.4.3: LogScale 時、ヒストグラムデータから適応的に初期値推定
	if(isLogScale)
		adaptSumW = 0
		adaptSumWX = 0
		adaptSumWX2 = 0
		// S0 のデータのみ使用（最初の histDim 点）
		for(pi_init = 0; pi_init < histDim; pi_init += 1)
			adaptXval = ConcatX[pi_init]  // segIdx=0 なので offset なし
			adaptWt = ConcatHist[pi_init]
			if(adaptWt > 0)
				adaptSumW += adaptWt
				adaptSumWX += adaptWt * adaptXval
				adaptSumWX2 += adaptWt * adaptXval^2
			endif
		endfor
		
		if(adaptSumW > 0)
			adaptMean = adaptSumWX / adaptSumW
			adaptVar = adaptSumWX2 / adaptSumW - adaptMean^2
			adaptSD = adaptVar > 0 ? sqrt(adaptVar) : 0.15
			// 妥当な範囲に制限（log10 空間）
			if(adaptSD < 0.05)
				adaptSD = 0.05
			endif
			if(adaptSD > 1.0)
				adaptSD = 1.0
			endif
			
			GlobalCoef[numAmplitudes] = adaptMean
			GlobalCoef[numAmplitudes + 1] = adaptSD
			Printf "  Adaptive init (log10): mean=%.4f, SD=%.4f\r", adaptMean, adaptSD
		endif
		
		// 振幅初期値: S0 ヒストグラムのピーク高さから推定
		peakHeight = 0
		for(pi_init = 0; pi_init < histDim; pi_init += 1)
			if(ConcatHist[pi_init] > peakHeight)
				peakHeight = ConcatHist[pi_init]
			endif
		endfor
		if(peakHeight > 0)
			for(i = 0; i < numAmplitudes; i += 1)
				GlobalCoef[i] = peakHeight / numOligomers * 0.5
			endfor
		endif
	endif
	
	// 
	Variable numConstraints = numAmplitudes + 2  //  > 0 + mean/sd ()
	if(fixMean)
		numConstraints += 2  // 
	endif
	if(fixSD)
		numConstraints += 2  // 
	endif
	
	Make/T/O/N=(numConstraints) GlobalConstraints
	
	Variable c = 0
	//  > 0
	for(i = 0; i < numAmplitudes; i += 1)
		GlobalConstraints[c] = "K" + num2str(i) + " > 0.0000001"
		c += 1
	endfor
	
	// mean 
	if(fixMean)
		GlobalConstraints[c] = "K" + num2str(numAmplitudes) + " > " + num2str(initMean - 0.001)
		c += 1
		GlobalConstraints[c] = "K" + num2str(numAmplitudes) + " < " + num2str(initMean + 0.001)
		c += 1
	else
		GlobalConstraints[c] = "K" + num2str(numAmplitudes) + " > 0.0000001"
		c += 1
	endif
	
	// SD 
	if(fixSD)
		GlobalConstraints[c] = "K" + num2str(numAmplitudes + 1) + " > " + num2str(initSD - 0.001)
		c += 1
		GlobalConstraints[c] = "K" + num2str(numAmplitudes + 1) + " < " + num2str(initSD + 0.001)
		c += 1
	else
		GlobalConstraints[c] = "K" + num2str(numAmplitudes + 1) + " > 0.0000001"
		c += 1
	endif
	
	Redimension/N=(c) GlobalConstraints
	
	// 
	Variable V_FitError = 0
	Variable fitSuccess = 0
	
	try
		AbortOnRTE
		FuncFit/Q/N/W=2 GlobalSumGaussFit, GlobalCoef, ConcatHist /X=ConcatX /C=GlobalConstraints; AbortOnRTE
		
		if(V_FitError == 0)
			fitSuccess = 1
		endif
	catch
		Variable err = GetRTError(1)
		V_FitError = 1
	endtry
	
	if(!fitSuccess)
		// v5.4.3: リトライ — 振幅のみ摂動、mean/SD は適応初期値を維持
		if(isLogScale && adaptSumW > 0)
			// LogScale: adaptive 初期値ベースでリトライ
			for(i = 0; i < numAmplitudes; i += 1)
				GlobalCoef[i] = abs(peakHeight / numOligomers * (0.3 + enoise(0.3)))
			endfor
			GlobalCoef[numAmplitudes] = adaptMean
			GlobalCoef[numAmplitudes + 1] = adaptSD * 1.3  // やや広めの SD
		else
			for(i = 0; i < numAmplitudes; i += 1)
				GlobalCoef[i] = 0.005 + enoise(0.01)
			endfor
			GlobalCoef[numAmplitudes] = initMean
			GlobalCoef[numAmplitudes + 1] = initSD
		endif
		
		try
			AbortOnRTE
			FuncFit/Q/N/W=2 GlobalSumGaussFit, GlobalCoef, ConcatHist /X=ConcatX /C=GlobalConstraints; AbortOnRTE
			
			if(V_FitError == 0)
				fitSuccess = 1
			endif
		catch
			err = GetRTError(1)
			V_FitError = 1
		endtry
	endif
	
	// 
	Variable finalMean = GlobalCoef[numAmplitudes]
	Variable finalSD = GlobalCoef[numAmplitudes + 1]
	
	// Norm by total number 
	NVAR/Z IntNormByS0 = root:IntNormByS0
	Variable useNormByTotal = 1
	if(NVAR_Exists(IntNormByS0))
		useNormByTotal = IntNormByS0
	endif
	
	// Norm by total number
	Variable totalAmpSum = 0
	if(useNormByTotal == 1)
		for(i = 0; i < numAmplitudes; i += 1)
			totalAmpSum += GlobalCoef[i]
		endfor
	endif
	
	// 
	Variable totalRSS = 0
	offset = 0
	segIdx = 0
	
	for(s = 0; s <= maxState; s += 1)
		String suffix = "_S" + num2str(s) + waveSuffix
		histName = "Int_S" + num2str(s) + waveSuffix + "_Phist"
		
		Wave/Z HistWave = $histName
		if(!WaveExists(HistWave))
			continue
		endif
		
		// 10
		Variable numFitPts = (histDim - 1) * 10 + 1
		String fitHistName = "fit_Int" + suffix + "_Phist"
		String fitXName = "fit_IntX" + suffix
		Make/O/N=(numFitPts) $fitHistName, $fitXName
		Wave FitHist = $fitHistName
		Wave FitX = $fitXName
		
		Variable xMin = histMin + histBin * 0.5
		Variable xMax = histMin + histBin * (histDim - 0.5)
		Variable dx_fit = (xMax - xMin) / (numFitPts - 1)
		
		// Wave10
		for(i = 0; i < numOligomers; i += 1)
			String compName = "comp" + num2str(i + 1) + suffix
			Make/O/N=(numFitPts) $compName
		endfor
		
		// 10
		Variable xVal, fitVal
		for(j = 0; j < numFitPts; j += 1)
			xVal = xMin + j * dx_fit
			FitX[j] = xVal
			fitVal = 0
			for(i = 0; i < numOligomers; i += 1)
				Variable ampIdx = segIdx * numOligomers + i
				Variable oligSize = i + 1
				Variable meanVal, sdVal
				
				if(isLogScale)
					// LogHist+Gauss: center = mean + log10(n), SD = sd/sqrt(n) (v5.4.4)
					meanVal = finalMean + log(oligSize)
					sdVal = finalSD / sqrt(oligSize)
				else
					// :  = n×mean, SD = sqrt(n)×sd
					meanVal = oligSize * finalMean
					sdVal = sqrt(oligSize) * finalSD
				endif
				
				Variable compVal = GlobalCoef[ampIdx] * exp(-((xVal - meanVal)^2 / (2 * sdVal^2)))
				fitVal += compVal
				
				// 
				String cName = "comp" + num2str(i + 1) + suffix
				Wave CompWave = $cName
				CompWave[j] = compVal
			endfor
			FitHist[j] = fitVal
		endfor
		
		// RSS
		Variable stateRSS = 0
		for(j = 0; j < histDim; j += 1)
			Variable xData = histMin + histBin * (j + 0.5)
			Variable fitValData = 0
			for(i = 0; i < numOligomers; i += 1)
				Variable ampIdxRSS = segIdx * numOligomers + i
				Variable oligSizeRSS = i + 1
				Variable meanValRSS, sdValRSS
				
				if(isLogScale)
					meanValRSS = finalMean + log(oligSizeRSS)
					sdValRSS = finalSD / sqrt(oligSizeRSS)  // v5.4.1: LogHistGauss SD
				else
					meanValRSS = oligSizeRSS * finalMean
					sdValRSS = sqrt(oligSizeRSS) * finalSD
				endif
				
				fitValData += GlobalCoef[ampIdxRSS] * exp(-((xData - meanValRSS)^2 / (2 * sdValRSS^2)))
			endfor
			stateRSS += (HistWave[j] - fitValData)^2
		endfor
		
		totalRSS += stateRSS
		
		// WaveDstate
		String coefName = "coef_Int" + suffix
		Make/O/D/N=(numOligomers + 2) $coefName
		Wave CoefWave = $coefName
		
		Variable ampSum = 0
		areaSum = 0  // v5.4.1: area-based for LogHistGauss
		for(i = 0; i < numOligomers; i += 1)
			CoefWave[i] = GlobalCoef[segIdx * numOligomers + i]
			ampSum += CoefWave[i]
			if(isLogScale)
				areaSum += CoefWave[i] / sqrt(i + 1)  // area ∝ A_k × (s/√k)
			else
				areaSum += CoefWave[i] * sqrt(i + 1)  // area ∝ A_k × (√k × σ)
			endif
		endfor
		CoefWave[numOligomers] = finalMean
		CoefWave[numOligomers + 1] = finalSD
		
		// 
		String popName = "population" + suffix
		Make/O/D/N=(numOligomers) $popName
		Wave PopWave = $popName
		
		// v5.4.1: Area-based population fraction
		// LogHistGauss: area_k = A_k × (s/√k) → fraction = (A_k/√k) / Σ(A_j/√j)
		// SumGauss: area_k = A_k × (√k × σ) → fraction = (A_k×√k) / Σ(A_j×√j)
		totalAreaSum = 0
		if(useNormByTotal == 1 && totalAmpSum > 0)
			// S0total
			for(si2 = 0; si2 < validStates; si2 += 1)
				for(i = 0; i < numOligomers; i += 1)
					ai = GlobalCoef[si2 * numOligomers + i]
					if(isLogScale)
						totalAreaSum += ai / sqrt(i + 1)
					else
						totalAreaSum += ai * sqrt(i + 1)
					endif
				endfor
			endfor
			normArea = totalAreaSum
		else
			normArea = areaSum
		endif
		
		if(normArea > 0)
			for(i = 0; i < numOligomers; i += 1)
				if(isLogScale)
					PopWave[i] = (CoefWave[i] / sqrt(i + 1)) / normArea
				else
					PopWave[i] = (CoefWave[i] * sqrt(i + 1)) / normArea
				endif
			endfor
		endif
		
		// 
		Printf "  S%d populations: ", s
		for(i = 0; i < numOligomers; i += 1)
			Printf "%.1f%% ", PopWave[i] * 100
		endfor
		Printf "(state sum=%.3f, total sum=%.3f)\r", ampSum, totalAmpSum
		
		segIdx += 1
	endfor
	
	// 
	KillWaves/Z ConcatHist, ConcatX, GlobalCoef, GlobalConstraints
	
	outRSS = totalRSS
	outMean = finalMean
	outSD = finalSD
	
	return fitSuccess
End

// -----------------------------------------------------------------------------
// Global Sum Gaussian 
// x
// -----------------------------------------------------------------------------
Function GlobalSumGaussFit(w, x) : FitFunc
	Wave w
	Variable x
	
	// 
	NVAR/Z gNumSegments = root:gNumSegments
	NVAR/Z gSegmentSize = root:gSegmentSize
	NVAR/Z gNumOligomers = root:gNumOligomers
	NVAR/Z gLogScale = root:gLogScale  // 
	
	if(!NVAR_Exists(gNumSegments) || !NVAR_Exists(gNumOligomers))
		return NaN
	endif
	
	Variable numOligomers = gNumOligomers
	Variable numAmplitudes = numOligomers * gNumSegments
	
	// xx
	Variable segIdx = floor(x / 1e7)
	Variable realX = x - segIdx * 1e7
	
	// 
	if(segIdx < 0 || segIdx >= gNumSegments)
		segIdx = 0
	endif
	
	// mean, sd2
	Variable mean = w[numAmplitudes]
	Variable sd = w[numAmplitudes + 1]
	
	// 
	Variable ampStart = segIdx * numOligomers
	
	// 
	Variable isLogScale = 0
	if(NVAR_Exists(gLogScale) && gLogScale == 1)
		isLogScale = 1
	endif
	
	// Sum of Gaussians 
	Variable result = 0
	Variable i
	for(i = 0; i < numOligomers; i += 1)
		Variable oligSize = i + 1
		Variable m, s
		
		if(isLogScale)
			// LogHist+Gauss: center = mean + log10(n), SD = sd/sqrt(n) (v5.4.1)
			m = mean + log(oligSize)  // log() in Igor is log10
			s = sd / sqrt(oligSize)
		else
			// :  = n×mean, SD = sqrt(n)×sd
			m = oligSize * mean
			s = sqrt(oligSize) * sd
		endif
		
		result += w[ampStart + i] * exp(-((realX - m)^2 / (2 * s^2)))
	endfor
	
	return result
End

// -----------------------------------------------------------------------------
// Localization Precision Histogram - HMM
// LocPrecision
// -----------------------------------------------------------------------------
Function CalculateLPHistogram(SampleName, [basePath, waveSuffix])
	String SampleName
	String basePath, waveSuffix
	
	// 
	if(ParamIsDefault(basePath))
		basePath = "root"
	endif
	if(ParamIsDefault(waveSuffix))
		waveSuffix = ""
	endif
	
	NVAR LPhistBin = root:LPhistBin
	NVAR LPhistDim = root:LPhistDim
	NVAR/Z Dstate = root:Dstate
	NVAR/Z cHMM = root:cHMM
	
	Variable numFolders
	if(StringMatch(basePath, "root"))
		numFolders = CountDataFolders(SampleName)
	else
		numFolders = CountDataFoldersInPath(basePath, SampleName)
	endif
	
	Variable m, s, i, maxState
	String FolderName
	
	// samplePath
	String samplePath
	if(StringMatch(basePath, "root"))
		samplePath = "root:" + SampleName
	else
		samplePath = basePath + ":" + SampleName
	endif
	
	// HMMDstateS0
	if(NVAR_Exists(cHMM) && cHMM == 1 && NVAR_Exists(Dstate))
		maxState = Dstate
	else
		maxState = 0
	endif
	
	Print "=== Calculating Localization Precision Histogram ==="
	Printf "Bin: %.1f nm, Dim: %d, States: S0-S%d, Folders: %d\r", LPhistBin, LPhistDim, maxState, numFolders
	
	// 
	for(m = 0; m < numFolders; m += 1)
		FolderName = SampleName + num2str(m + 1)
		String cellPath = samplePath + ":" + FolderName
		
		// 
		if(!DataFolderExists(cellPath))
			Printf "  %s: Folder not found\r", FolderName
			continue
		endif
		
		SetDataFolder $cellPath
		
		// S0
		String lpS0Name = "LocPrecision_S0" + waveSuffix
		Wave/Z LP_S0 = $lpS0Name
		Variable totalS0 = 0
		if(WaveExists(LP_S0))
			// NaN
			for(i = 0; i < numpnts(LP_S0); i += 1)
				if(numtype(LP_S0[i]) == 0 && LP_S0[i] > 0)
					totalS0 += 1
				endif
			endfor
		else
			Printf "  %s: LocPrecision_S0 not found\r", FolderName
			continue
		endif
		
		Printf "  %s: S0 valid points = %d\r", FolderName, totalS0
		
		// Dstate
		for(s = 0; s <= maxState; s += 1)
			String lpName = "LocPrecision_S" + num2str(s) + waveSuffix
			Wave/Z LPwave = $lpName
			
			if(!WaveExists(LPwave))
				Printf "    S%d: LocPrecision wave not found\r", s
				continue
			endif
			
			// nm
			Variable n = numpnts(LPwave)
			Make/FREE/N=(n) LPvalid = NaN
			Variable validCount = 0
			
			for(i = 0; i < n; i += 1)
				if(numtype(LPwave[i]) == 0 && LPwave[i] > 0)
					LPvalid[validCount] = LPwave[i]  // nm
					validCount += 1
				endif
			endfor
			
			// 1
			if(validCount < 1)
				Printf "    S%d: no valid data\r", s
				continue
			endif
			
			Redimension/N=(validCount) LPvalid
			
			// 
			String lpHistName = "LP_S" + num2str(s) + "_Hist"
			String lpPhistName = "LP_S" + num2str(s) + "_Phist"
			String lpXName = "LP_S" + num2str(s) + "_X"
			
			Make/O/N=(LPhistDim) $lpHistName = 0, $lpPhistName = 0, $lpXName = 0
			Wave LPHist = $lpHistName
			Wave LPPhist = $lpPhistName
			Wave LPX = $lpXName
			
			// X
			LPX = LPhistBin * (p + 0.5)
			
			Histogram/B={0, LPhistBin, LPhistDim} LPvalid, LPHist
			
			// 
			if(totalS0 > 0)
				LPPhist = LPHist / (totalS0 * LPhistBin)
			endif
			
			Printf "    S%d: %d valid points, max LP = %.1f nm\r", s, validCount, WaveMax(LPvalid)
		endfor
		
		ShowProgress(m+1, numFolders, "LP Hist")
	endfor
	
	EndProgress()
	SetDataFolder root:
	Print "Localization precision histogram calculation complete"
End

// -----------------------------------------------------------------------------
// Localization Precision Histogram Display - HMM
// 
// LP_Sn_NormPhistmean_LPLP
// -----------------------------------------------------------------------------
Function DisplayLPHistogram(SampleName, [basePath, waveSuffix])
	String SampleName
	String basePath, waveSuffix
	
	// 
	if(ParamIsDefault(basePath))
		basePath = "root"
	endif
	if(ParamIsDefault(waveSuffix))
		waveSuffix = ""
	endif
	
	NVAR/Z Dstate = root:Dstate
	NVAR/Z cHMM = root:cHMM
	NVAR LPhistBin = root:LPhistBin
	
	Variable maxState = 0
	if(NVAR_Exists(cHMM) && cHMM == 1 && NVAR_Exists(Dstate))
		maxState = Dstate
	endif
	
	Variable numFolders
	if(StringMatch(basePath, "root"))
		numFolders = CountDataFolders(SampleName)
	else
		numFolders = CountDataFoldersInPath(basePath, SampleName)
	endif
	
	Variable m, s, i
	String FolderName
	
	// samplePath
	String samplePath
	if(StringMatch(basePath, "root"))
		samplePath = "root:" + SampleName
	else
		samplePath = basePath + ":" + SampleName
	endif
	
	// Intensity/Step Histogram
	Make/FREE/N=(6,3) stateColors
	stateColors[0][0] = 45000;   stateColors[0][1] = 45000;   stateColors[0][2] = 45000    // S0: 
	stateColors[1][0] = 0;       stateColors[1][1] = 0;       stateColors[1][2] = 65280    // S1: 
	stateColors[2][0] = 65280;   stateColors[2][1] = 43520;   stateColors[2][2] = 0        // S2: 
	stateColors[3][0] = 0;       stateColors[3][1] = 39168;   stateColors[3][2] = 0        // S3: 
	stateColors[4][0] = 65280;   stateColors[4][1] = 0;       stateColors[4][2] = 0        // S4: 
	stateColors[5][0] = 65280;   stateColors[5][1] = 0;       stateColors[5][2] = 65280    // S5: 
	
	// 
	for(m = 0; m < numFolders; m += 1)
		FolderName = SampleName + num2str(m + 1)
		String cellPath = samplePath + ":" + FolderName
		
		if(!DataFolderExists(cellPath))
			continue
		endif
		
		SetDataFolder $cellPath
		
		// S0
		Wave/Z LP_S0_Phist, LP_S0_X
		if(!WaveExists(LP_S0_Phist) || !WaveExists(LP_S0_X))
			Printf "  %s: LP histogram not found\r", FolderName
			continue
		endif
		
		String winName = "LP_" + FolderName + waveSuffix
		DoWindow/K $winName
		
		// S0
		Display/K=1/N=$winName LP_S0_Phist vs LP_S0_X
		
		// Seg
		String graphTitle = GetGraphTitleWithSeg(FolderName + " Localization Precision", waveSuffix)
		DoWindow/T $winName, graphTitle
		ModifyGraph mode(LP_S0_Phist)=5, hbFill(LP_S0_Phist)=4
		ModifyGraph rgb(LP_S0_Phist)=(stateColors[0][0], stateColors[0][1], stateColors[0][2])
		
		// S1
		for(s = 1; s <= maxState; s += 1)
			String phistName = "LP_S" + num2str(s) + "_Phist"
			String xName = "LP_S" + num2str(s) + "_X"
			Wave/Z PhistWave = $phistName
			Wave/Z XWave = $xName
			if(WaveExists(PhistWave) && WaveExists(XWave))
				AppendToGraph PhistWave vs XWave
				ModifyGraph mode($phistName)=4, marker($phistName)=19, msize($phistName)=3
				ModifyGraph rgb($phistName)=(stateColors[s][0], stateColors[s][1], stateColors[s][2])
			endif
		endfor
		
		// 
		ModifyGraph tick=0, mirror=0, fStyle=1, fSize=14, font="Arial"
		ModifyGraph lowTrip(left)=0.0001
		SetAxis left 0, *
		SetAxis bottom 0, *
		Label left "Probability Density"
		Label bottom "Localization Precision (nm)"
		ModifyGraph width={Aspect,1.618}
		
		// GetDstateName
		String legendStr = "\\F'Arial'\\Z12\\s(LP_S0_Phist) " + GetDstateName(0, maxState)
		for(s = 1; s <= maxState; s += 1)
			phistName = "LP_S" + num2str(s) + "_Phist"
			Wave/Z PW = $phistName
			if(WaveExists(PW))
				legendStr += "\r\\s(" + phistName + ") " + GetDstateName(s, maxState)
			endif
		endfor
		TextBox/C/N=text0/F=0/B=1/A=RT legendStr
		
		// ========================================
		// LP_Sn_NormPhistmean_LP
		// ========================================
		Make/O/N=(maxState + 1) mean_LP = NaN
		
		for(s = 0; s <= maxState; s += 1)
			String phistSrcName = "LP_S" + num2str(s) + "_Phist"
			String normPhistName = "LP_S" + num2str(s) + "_NormPhist"
			String lpXname = "LP_S" + num2str(s) + "_X"
			
			Wave/Z PhistSrc = $phistSrcName
			Wave/Z LPXwave = $lpXname
			if(!WaveExists(PhistSrc) || !WaveExists(LPXwave))
				continue
			endif
			
			Variable nBins = numpnts(PhistSrc)
			
			// 
			Variable totalPhist = sum(PhistSrc)
			
			// LP_Sn_NormPhist = LP_Sn_Phist / ΣLP_Sn_Phist=1
			Make/O/N=(nBins) $normPhistName = 0
			Wave NormPhist = $normPhistName
			SetScale/P x, DimOffset(PhistSrc, 0), DimDelta(PhistSrc, 0), NormPhist
			
			if(totalPhist > 0)
				NormPhist = PhistSrc / totalPhist
			endif
			
			// mean LP = Σ(LP_value * NormPhist)
			// LP_value = LPXwave[i] = bin center
			Variable meanLP = 0
			for(i = 0; i < nBins; i += 1)
				meanLP += LPXwave[i] * NormPhist[i]
			endfor
			mean_LP[s] = meanLP
		endfor
		
		// Mean LP 
		Printf "\n--- Mean LP (%s) ---\r", FolderName
		for(s = 0; s <= maxState; s += 1)
			Printf "S%d: %.2f nm\r", s, mean_LP[s]
		endfor
	endfor
	
	// ========================================
	// Matrix/Results  mean_LP 
	// ========================================
	CollectMeanLPToMatrix(SampleName, maxState)
	
	SetDataFolder root:
	return 0
End

// -----------------------------------------------------------------------------
// mean_LP  Matrix/Results 
// -----------------------------------------------------------------------------
Function CollectMeanLPToMatrix(SampleName, maxState)
	String SampleName
	Variable maxState
	
	Variable numFolders = CountDataFolders(SampleName)
	Variable m, s
	String FolderName
	
	// Matrix
	String matrixPath = "root:" + SampleName + ":Matrix"
	if(!DataFolderExists(matrixPath))
		NewDataFolder $matrixPath
	endif
	
	// mean_LP_m: [state][cell]
	SetDataFolder $matrixPath
	Make/O/N=(maxState + 1, numFolders) mean_LP_m = NaN
	Wave lpMatrix = mean_LP_m
	
	//  mean_LP 
	for(m = 0; m < numFolders; m += 1)
		FolderName = SampleName + num2str(m + 1)
		String lpPath = "root:" + SampleName + ":" + FolderName + ":mean_LP"
		Wave/Z cellLP = $lpPath
		
		if(WaveExists(cellLP))
			for(s = 0; s <= maxState; s += 1)
				if(s < numpnts(cellLP))
					lpMatrix[s][m] = cellLP[s]
				endif
			endfor
		endif
	endfor
	
	// Results
	String resultsPath = "root:" + SampleName + ":Results"
	if(!DataFolderExists(resultsPath))
		NewDataFolder $resultsPath
	endif
	SetDataFolder $resultsPath
	
	// : mean_LP_m_avg, _sd, _sem, _n
	Make/O/N=(maxState + 1) mean_LP_m_avg = NaN
	Make/O/N=(maxState + 1) mean_LP_m_sd = NaN
	Make/O/N=(maxState + 1) mean_LP_m_sem = NaN
	Make/O/N=(maxState + 1) mean_LP_m_n = NaN
	
	Wave avgW = mean_LP_m_avg
	Wave sdW = mean_LP_m_sd
	Wave semW = mean_LP_m_sem
	Wave nW = mean_LP_m_n
	
	for(s = 0; s <= maxState; s += 1)
		// 
		Make/FREE/N=(numFolders) tempData
		Variable k, validCount = 0
		for(k = 0; k < numFolders; k += 1)
			Variable val = lpMatrix[s][k]
			if(numtype(val) == 0)  // NaN
				tempData[validCount] = val
				validCount += 1
			endif
		endfor
		
		if(validCount > 0)
			Redimension/N=(validCount) tempData
			WaveStats/Q tempData
			avgW[s] = V_avg
			sdW[s] = V_sdev
			nW[s] = V_npnts
			if(V_npnts > 1)
				semW[s] = V_sdev / sqrt(V_npnts)
			else
				semW[s] = 0
			endif
		endif
	endfor
	
	SetDataFolder root:
	Print "  mean_LP_m and statistics created in Matrix/Results"
End

// =============================================================================
// Molecular Density Calculation
// =============================================================================
// 
// : AnalyzeIntHistogramSs_HMMfractionxDensity_Sample
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// CalculateMolecularDensityHMM - Dstate
// Int_Phist × StateFraction × Density Dstate
// -----------------------------------------------------------------------------
Function CalculateMolecularDensityHMM(SampleName, [basePath, waveSuffix])
	String SampleName
	String basePath, waveSuffix
	
	// 
	if(ParamIsDefault(basePath))
		basePath = "root"
	endif
	if(ParamIsDefault(waveSuffix))
		waveSuffix = ""
	endif
	
	NVAR/Z cHMM = root:cHMM
	NVAR/Z Dstate = root:Dstate
	NVAR IHistBin = root:IHistBin
	NVAR IHistDim = root:IHistDim
	
	Variable numFolders
	if(StringMatch(basePath, "root"))
		numFolders = CountDataFolders(SampleName)
	else
		numFolders = CountDataFoldersInPath(basePath, SampleName)
	endif
	
	Variable m, s, L
	String FolderName, folderPath, resultsPath
	Variable maxState = 0
	
	// samplePath
	String samplePath
	if(StringMatch(basePath, "root"))
		samplePath = "root:" + SampleName
	else
		samplePath = basePath + ":" + SampleName
	endif
	
	// HMMDstate
	if(NVAR_Exists(cHMM) && cHMM == 1 && NVAR_Exists(Dstate))
		maxState = Dstate
	endif
	
	Print "=== Molecular Density Calculation (HMM) ==="
	Printf "Dstates: %d, IHistBin: %.1f, IHistDim: %d\r", maxState, IHistBin, IHistDim
	
	// 
	for(m = 0; m < numFolders; m += 1)
		FolderName = SampleName + num2str(m + 1)
		folderPath = samplePath + ":" + FolderName + ":"
		
		if(!DataFolderExists(samplePath + ":" + FolderName))
			continue
		endif
		
		SetDataFolder $(samplePath + ":" + FolderName)
		
		Printf "\n  Processing %s...\r", FolderName
		
		// Density
		Wave/Z ParaDensityAvg = $(folderPath + "ParaDensityAvg")
		if(!WaveExists(ParaDensityAvg))
			Printf "    WARNING: ParaDensityAvg not found. Run Density analysis first.\r"
			continue
		endif
		Variable Density = ParaDensityAvg[2]  //  [/um²]
		Printf "    Density: %.4f /um²\r", Density
		
		// Dstate
		// SegDstate_S0_Seg0suffix
		String dstateWaveName = "Dstate_S0" + waveSuffix
		Wave/Z Dstate_S0 = $(folderPath + dstateWaveName)
		Make/O/N=(maxState+1) $(folderPath + "StateFraction" + waveSuffix) = 0
		Wave StateFraction = $(folderPath + "StateFraction" + waveSuffix)
		
		if(WaveExists(Dstate_S0) && maxState > 0)
			Variable totalPts = numpnts(Dstate_S0)
			Variable i, cnt
			
			// 1NaN
			Variable validPts = 0
			for(i = 0; i < totalPts; i += 1)
				if(numtype(Dstate_S0[i]) == 0 && Dstate_S0[i] >= 1)
					validPts += 1
				endif
			endfor
			
			//  → ΣSn=100%
			for(s = 1; s <= maxState; s += 1)
				cnt = 0
				for(i = 0; i < totalPts; i += 1)
					if(numtype(Dstate_S0[i]) == 0 && Dstate_S0[i] == s)
						cnt += 1
					endif
				endfor
				if(validPts > 0)
					StateFraction[s] = (cnt / validPts) * 100  // 
				else
					StateFraction[s] = 0
				endif
			endfor
			// S0100%
			StateFraction[0] = 100
			Printf "    State fractions (validPts=%d): ", validPts
			for(s = 0; s <= maxState; s += 1)
				Printf "S%d=%.1f%% ", s, StateFraction[s]
			endfor
			Printf "\r"
		else
			StateFraction[0] = 100
		endif
		
		// Dstate
		for(s = 0; s <= maxState; s += 1)
			String suffix = "_S" + num2str(s) + waveSuffix
			String histName = "Int" + suffix + "_Phist"  // Int_S0_Seg0_Phist, etc.
			String densHistName = "Int" + suffix + "_Phist_xDensity"
			
			// 
			Wave/Z IntHist = $(folderPath + histName)
			if(!WaveExists(IntHist))
				Printf "    WARNING: %s not found for S%d\r", histName, s
				continue
			endif
			
			// 
			// Int_Phist × (StateFraction/100) × Density
			Variable stateFrac = StateFraction[s] / 100
			
			Duplicate/O IntHist, $(folderPath + densHistName)
			Wave DensHist = $(folderPath + densHistName)
			
			// =1
			Variable histSum = sum(IntHist)
			if(histSum > 0)
				DensHist = (IntHist / histSum) * stateFrac * Density
			else
				DensHist = 0
			endif
			
			// X
			SetScale/P x, IHistBin/2, IHistBin, DensHist
			
			Printf "    S%d: Created %s (sum=%.4f)\r", s, densHistName, sum(DensHist)
		endfor
	endfor
	
	// Matrix/Results
	CollectIntDensHistToMatrix(SampleName, maxState, basePath=basePath)
	
	SetDataFolder root:
	Print "\nMolecular density calculation complete"
End

// -----------------------------------------------------------------------------
// CollectIntDensHistToMatrix - Int_S*_Phist_xDensityMatrix/Results
// -----------------------------------------------------------------------------
Function CollectIntDensHistToMatrix(SampleName, maxState, [basePath])
	String SampleName
	Variable maxState
	String basePath
	
	// 
	if(ParamIsDefault(basePath))
		basePath = "root"
	endif
	
	NVAR IHistDim = root:IhistDim
	NVAR IHistBin = root:IhistBin
	Variable histDim = IHistDim
	Variable histBin = IHistBin
	
	Variable numFolders
	if(StringMatch(basePath, "root"))
		numFolders = CountDataFolders(SampleName)
	else
		numFolders = CountDataFoldersInPath(basePath, SampleName)
	endif
	
	Variable m, s, bin, validCount, npts
	Variable val
	String FolderName, stateStr, matrixName
	String densHistPath, avgName, semName
	
	// samplePath
	String samplePath
	if(StringMatch(basePath, "root"))
		samplePath = "root:" + SampleName
	else
		samplePath = basePath + ":" + SampleName
	endif
	
	// Matrix
	String matrixPath = samplePath + ":Matrix"
	if(!DataFolderExists(matrixPath))
		NewDataFolder $matrixPath
	endif
	SetDataFolder $matrixPath
	
	// Matrix: {WaveName}_m
	for(s = 0; s <= maxState; s += 1)
		stateStr = "S" + num2str(s)
		matrixName = "Int_" + stateStr + "_Phist_xDensity_m"
		
		// Matrix: [bin][cell]
		Make/O/D/N=(histDim, numFolders) $matrixName = NaN
		Wave histMatrix = $matrixName
		
		// Int_S*_Phist_xDensity
		for(m = 0; m < numFolders; m += 1)
			FolderName = SampleName + num2str(m + 1)
			densHistPath = samplePath + ":" + FolderName + ":Int_" + stateStr + "_Phist_xDensity"
			Wave/Z cellHist = $densHistPath
			
			if(WaveExists(cellHist))
				npts = min(numpnts(cellHist), histDim)
				histMatrix[0, npts-1][m] = cellHist[p]
			endif
		endfor
	endfor
	
	// Results
	String resultsPath = samplePath + ":Results"
	if(!DataFolderExists(resultsPath))
		NewDataFolder $resultsPath
	endif
	SetDataFolder $resultsPath
	
	// 
	for(s = 0; s <= maxState; s += 1)
		stateStr = "S" + num2str(s)
		matrixName = "Int_" + stateStr + "_Phist_xDensity_m"
		Wave/Z histMatrix = $(matrixPath + ":" + matrixName)
		
		if(!WaveExists(histMatrix))
			continue
		endif
		
		avgName = "Int_" + stateStr + "_Phist_xDensity_m_avg"
		semName = "Int_" + stateStr + "_Phist_xDensity_m_sem"
		
		Make/O/D/N=(histDim) $avgName = 0
		Make/O/D/N=(histDim) $semName = 0
		Wave avgW = $avgName
		Wave semW = $semName
		
		// X
		SetScale/P x, histBin/2, histBin, avgW
		SetScale/P x, histBin/2, histBin, semW
		
		// binSEM
		for(bin = 0; bin < histDim; bin += 1)
			Make/FREE/N=(numFolders) tempData
			validCount = 0
			for(m = 0; m < numFolders; m += 1)
				val = histMatrix[bin][m]
				if(numtype(val) == 0)
					tempData[validCount] = val
					validCount += 1
				endif
			endfor
			
			if(validCount > 0)
				Redimension/N=(validCount) tempData
				WaveStats/Q tempData
				avgW[bin] = V_avg
				if(V_npnts > 1)
					semW[bin] = V_sdev / sqrt(V_npnts)
				else
					semW[bin] = 0
				endif
			endif
		endfor
	endfor
	
	SetDataFolder root:
	Print "  Int_Phist_xDensity collected to Matrix/Results"
End

// -----------------------------------------------------------------------------
// DisplayMolecularDensityHMM - Dstate
// -----------------------------------------------------------------------------
Function DisplayMolecularDensityHMM(SampleName, [basePath, waveSuffix])
	String SampleName
	String basePath, waveSuffix
	
	// 
	if(ParamIsDefault(basePath))
		basePath = "root"
	endif
	if(ParamIsDefault(waveSuffix))
		waveSuffix = ""
	endif
	
	NVAR/Z Dstate = root:Dstate
	NVAR IHistBin = root:IHistBin
	NVAR IHistDim = root:IHistDim
	
	Variable numFolders
	if(StringMatch(basePath, "root"))
		numFolders = CountDataFolders(SampleName)
	else
		numFolders = CountDataFoldersInPath(basePath, SampleName)
	endif
	
	Variable m, s
	String FolderName, folderPath, resultsPath
	Variable maxState = 0
	
	// samplePath
	String samplePath
	if(StringMatch(basePath, "root"))
		samplePath = "root:" + SampleName
	else
		samplePath = basePath + ":" + SampleName
	endif
	
	if(NVAR_Exists(Dstate))
		maxState = Dstate
	endif
	
	// 
	// S0=, S1=, S2=, S3=, S4=, S5=
	Make/FREE/N=(6, 3) DstateColors
	DstateColors[0][] = {{0}, {0}, {0}}           // S0: 
	DstateColors[1][] = {{0}, {0}, {65280}}       // S1: 
	DstateColors[2][] = {{65280}, {43520}, {0}}   // S2: 
	DstateColors[3][] = {{0}, {39168}, {0}}       // S3: 
	DstateColors[4][] = {{65280}, {0}, {0}}       // S4: 
	DstateColors[5][] = {{52428}, {1}, {41942}}   // S5: 
	
	// 
	for(m = 0; m < numFolders; m += 1)
		FolderName = SampleName + num2str(m + 1)
		folderPath = samplePath + ":" + FolderName + ":"
		
		if(!DataFolderExists(samplePath + ":" + FolderName))
			continue
		endif
		
		SetDataFolder $(samplePath + ":" + FolderName)
		
		// Dstate
		String winName = "MolDensityHMM_" + FolderName + waveSuffix
		DoWindow/K $winName
		
		Variable firstPlot = 1
		for(s = maxState; s >= 0; s -= 1)
			String densHistName = "Int_S" + num2str(s) + "_Phist_xDensity"
			Wave/Z DensHist = $(folderPath + densHistName)
			
			if(!WaveExists(DensHist))
				continue
			endif
			
			if(firstPlot)
				Display/K=1/N=$winName DensHist
				firstPlot = 0
			else
				AppendToGraph DensHist
			endif
			
			// 
			Variable r = DstateColors[min(s, 5)][0]
			Variable g = DstateColors[min(s, 5)][1]
			Variable b = DstateColors[min(s, 5)][2]
			
			ModifyGraph rgb($densHistName)=(r, g, b)
			ModifyGraph mode($densHistName)=0  // 
			ModifyGraph lsize($densHistName)=1.5
		endfor
		
		if(!firstPlot)
			ModifyGraph tick=0, mirror=0
			ModifyGraph lowTrip(left)=0.0001
			ModifyGraph axisEnab(left)={0.05, 1}, axisEnab(bottom)={0.05, 1}
			ModifyGraph fStyle=1, fSize=16, font="Arial"
			Label left "Density (1/µm\\S2\\M)"
			Label bottom "Intensity (a.u.)"
			SetAxis left 0, *
			SetAxis bottom 0, *
			ModifyGraph width={Aspect, 1.618}
			
			// Seg
			String graphTitle = GetGraphTitleWithSeg(FolderName + " Molecular Density by Dstate", waveSuffix)
			DoWindow/T $winName, graphTitle
			
			// 
			String legendStr = ""
			Variable legendIdx
			for(legendIdx = 0; legendIdx <= maxState; legendIdx += 1)
				if(legendIdx > 0)
					legendStr += "\r"
				endif
				String densHistTraceName = "Int_S" + num2str(legendIdx) + "_Phist_xDensity"
				legendStr += "\\s(" + densHistTraceName + ") " + GetDstateName(legendIdx, maxState)
			endfor
			Legend/C/N=legend1/J/F=0/B=1/A=RT legendStr
		endif
	endfor
	
	SetDataFolder root:
End

// -----------------------------------------------------------------------------
// CalculateOligomerDensity - Dstate
// Particle-based fraction  Molecular density-based distribution 
// ParticleDensity_DstateHMMP
// pop_osize_S*
// -----------------------------------------------------------------------------
Function CalculateOligomerDensity(SampleName, [basePath, waveSuffix])
	String SampleName
	String basePath, waveSuffix
	
	// 
	if(ParamIsDefault(basePath))
		basePath = "root"
	endif
	if(ParamIsDefault(waveSuffix))
		waveSuffix = ""
	endif
	
	NVAR/Z Dstate = root:Dstate
	NVAR IHistBin = root:IHistBin
	NVAR IHistDim = root:IHistDim
	NVAR MinOligomerSize = root:MinOligomerSize
	NVAR MaxOligomerSize = root:MaxOligomerSize
	
	Variable numFolders
	if(StringMatch(basePath, "root"))
		numFolders = CountDataFolders(SampleName)
	else
		numFolders = CountDataFoldersInPath(basePath, SampleName)
	endif
	
	Variable m, n, s, i
	String FolderName, folderPath
	Variable maxState = 0
	// Oligomer sizes are always 1, 2, ..., MaxOligomerSize (monomer, dimer, ...)
	// MinOligomerSize/MaxOligomerSize define the AIC model selection range,
	// but the output array spans 1 to MaxOligomerSize
	Variable numOligomers = MaxOligomerSize

	// samplePath
	String samplePath
	if(StringMatch(basePath, "root"))
		samplePath = "root:" + SampleName
	else
		samplePath = basePath + ":" + SampleName
	endif
	
	if(NVAR_Exists(Dstate))
		maxState = Dstate
	endif
	
	Print "=== Oligomer Density Calculation ==="
	Printf "Oligomer range: 1-%d (AIC test: %d-%d), Dstates: %d\r", MaxOligomerSize, MinOligomerSize, MaxOligomerSize, maxState
	
	// ========================================
	// Step 1: ParticleDensity_Dstate
	// ========================================
	// ParticleDensity_Dstate
	String firstFolder = SampleName + "1"
	String checkPath = samplePath + ":" + firstFolder + ":ParticleDensity_Dstate"
	Wave/Z checkWave = $checkPath
	if(!WaveExists(checkWave))
		Print "  ParticleDensity_Dstate not found. Running Particle Density calculation..."
		Density_Gcount(SampleName, basePath=basePath, waveSuffix=waveSuffix)
	endif
	
	// ========================================
	// Step 2: HMMP
	// ========================================
	checkPath = samplePath + ":" + firstFolder + ":HMMP"
	Wave/Z checkHMMP = $checkPath
	if(!WaveExists(checkHMMP) && maxState > 0)
		Print "  HMMP not found. Running Step Size Histogram calculation..."
		CalculateStepSizeHistogramHMM(SampleName, basePath=basePath, waveSuffix=waveSuffix)
	endif
	
	// 
	for(m = 0; m < numFolders; m += 1)
		FolderName = SampleName + num2str(m + 1)
		folderPath = samplePath + ":" + FolderName + ":"
		
		if(!DataFolderExists(samplePath + ":" + FolderName))
			continue
		endif
		
		SetDataFolder $(samplePath + ":" + FolderName)
		
		Printf "\n  Processing %s...\r", FolderName
		
		// Density
		Wave/Z ParaDensityAvg = $(folderPath + "ParaDensityAvg")
		if(!WaveExists(ParaDensityAvg))
			Printf "    WARNING: ParaDensityAvg not found.\r"
			continue
		endif
		Variable spotDensityTotal = ParaDensityAvg[2]
		Variable cellArea = ParaDensityAvg[1]  // 
		Printf "    Total spot density: %.4f /um², Cell area: %.2f um²\r", spotDensityTotal, cellArea
		
		// ParticleDensity_Dstate
		Wave/Z ParticleDensity_Dstate = $(folderPath + "ParticleDensity_Dstate")
		if(!WaveExists(ParticleDensity_Dstate))
			Printf "    WARNING: ParticleDensity_Dstate not found.\r"
			continue
		endif
		
		// HMMPPrint
		Wave/Z HMMP = $(folderPath + "HMMP")
		if(WaveExists(HMMP))
			Printf "    HMMP: "
			for(s = 0; s <= maxState; s += 1)
				if(s < numpnts(HMMP))
					Printf "S%d=%.1f%% ", s, HMMP[s]
				endif
			endfor
			Printf "\r"
		endif
		
		// MolDensity_Dstate
		Make/O/N=(maxState+1) $(folderPath + "MolDensity_Dstate" + waveSuffix) = 0
		Wave MolDensity_Dstate = $(folderPath + "MolDensity_Dstate" + waveSuffix)
		
		// Oligomer size wave: 1, 2, 3, ..., MaxOligomerSize (monomer, dimer, ...)
		Make/O/N=(numOligomers) $(folderPath + "OligomerSize") = 0
		Wave OligomerSize = $(folderPath + "OligomerSize")
		for(n = 0; n < numOligomers; n += 1)
			OligomerSize[n] = n + 1
		endfor
		
		// Dstate
		for(s = 0; s <= maxState; s += 1)
			String suffix = "_S" + num2str(s) + waveSuffix
			
			// Particle Density for this state
			Variable particleDens = ParticleDensity_Dstate[s]
			
			// ========================================
			// Step 4: pop_osize_S*
			// ========================================
			String osizeName = "pop_osize" + suffix
			Wave/Z OsizeWave = $(folderPath + osizeName)
			
			if(!WaveExists(OsizeWave))
				// pop_osize_S*pop_pct_S*
				String pctName = "pop_pct" + suffix
				Wave/Z PctWave = $(folderPath + pctName)
				
				if(WaveExists(PctWave))
					Variable totalPct = sum(PctWave)
					Make/O/N=(numOligomers) $(folderPath + osizeName) = 0
					Wave OsizeWave = $(folderPath + osizeName)
					SetScale/P x, 1, 1, OsizeWave
					
					if(totalPct > 0)
						Variable numPctPts = numpnts(PctWave)
						for(n = 0; n < numOligomers; n += 1)
							if(n < numPctPts)
								OsizeWave[n] = PctWave[n] / totalPct
							endif
						endfor
					endif
				else
					// pop_pct_S*coef_Int_S*
					String coefName = "coef_Int" + suffix
					Wave/Z CoefWave = $(folderPath + coefName)
					if(WaveExists(CoefWave))
						Variable numCoef = numpnts(CoefWave)
						Variable numPop = numCoef - 2  // mean, sd
						if(numPop > 0)
							Make/O/N=(numOligomers) $(folderPath + osizeName) = 0
							Wave OsizeWave = $(folderPath + osizeName)
							SetScale/P x, 1, 1, OsizeWave
							
							Variable ampSum = 0
							for(n = 0; n < numPop; n += 1)
								ampSum += CoefWave[n]
							endfor
							if(ampSum > 0)
								for(n = 0; n < numPop && n < numOligomers; n += 1)
									OsizeWave[n] = CoefWave[n] / ampSum
								endfor
							endif
						endif
					else
						// No pop_pct or coef_Int data — skip oligomer density for this state
						Printf "WARNING: No oligomer data (pop_pct/coef_Int) for state S%d in %s. Skipping oligomer density.\r", s, FolderName
						continue
					endif
				endif
			endif
			
			// Molecular density distribution
			Make/O/N=(numOligomers) $(folderPath + "MolDensDist" + suffix) = 0
			Wave MolDensDist = $(folderPath + "MolDensDist" + suffix)
			
			Variable totalMolDens = 0
			Variable avgOligSize = 1.0
			
			if(WaveExists(OsizeWave))
				Variable osizePoints = numpnts(OsizeWave)
				Variable maxIdx = min(numOligomers, osizePoints)
				for(n = 0; n < maxIdx; n += 1)
					Variable oligSize = n + 1  // 1=monomer, 2=dimer, ...
					// Molecular density distribution = particleDensity × pop_osize × oligomerSize
					MolDensDist[n] = particleDens * OsizeWave[n] * oligSize
					totalMolDens += MolDensDist[n]
				endfor
				
				if(particleDens > 0)
					avgOligSize = totalMolDens / particleDens
				endif
			endif
			
			MolDensity_Dstate[s] = totalMolDens
			
			Printf "    S%d: Particle=%.4f, Molecular=%.4f /um² (avg size=%.2f)\r", s, particleDens, totalMolDens, avgOligSize
		endfor
		
		// 
		Make/O/N=4 $(folderPath + "MolDensitySummary" + waveSuffix) = {spotDensityTotal, sum(MolDensity_Dstate), cellArea, sum(MolDensity_Dstate) * cellArea}
		Make/O/T/N=4 $(folderPath + "TxtMolDensitySummary" + waveSuffix) = {"SpotDensity[/um2]", "TotalMolDensity[/um2]", "CellArea[um2]", "TotalMolecules"}
		
		// Seg - 
		if(strlen(waveSuffix) == 0)
			Edit/K=1 $(folderPath + "ParticleDensity_Dstate"), $(folderPath + "MolDensity_Dstate" + waveSuffix)
			DoWindow/T kwTopWin, FolderName + " Density by Dstate"
		endif
	endfor
	
	// ========================================
	// Matrix/Results
	// ========================================
	if(StringMatch(basePath, "root") && strlen(waveSuffix) == 0)
		CollectMolDensityToMatrix(SampleName, maxState)
	else
		Printf "Calling CollectMolDensityToMatrixEx: basePath=%s, waveSuffix=%s\r", basePath, waveSuffix
		CollectMolDensityToMatrixEx(SampleName, maxState, basePath, waveSuffix)
	endif
	
	SetDataFolder root:
	Print "\nOligomer density calculation complete"
End

// -----------------------------------------------------------------------------
// CollectMolDensityToMatrix - MolDensity_DstateMatrix/Results
// -----------------------------------------------------------------------------
Function CollectMolDensityToMatrix(SampleName, maxState)
	String SampleName
	Variable maxState
	
	Variable numFolders = CountDataFolders(SampleName)
	Variable m, s
	String FolderName
	
	// Matrix
	String matrixPath = "root:" + SampleName + ":Matrix"
	if(!DataFolderExists(matrixPath))
		NewDataFolder $matrixPath
	endif
	
	// MolDensity_Dstate_m: [state][cell]
	SetDataFolder $matrixPath
	Make/O/N=(maxState + 1, numFolders) MolDensity_Dstate_m = NaN
	Wave molMatrix = MolDensity_Dstate_m
	
	// MolDensity_Dstate
	for(m = 0; m < numFolders; m += 1)
		FolderName = SampleName + num2str(m + 1)
		String molPath = "root:" + SampleName + ":" + FolderName + ":MolDensity_Dstate"
		Wave/Z cellMol = $molPath
		
		if(WaveExists(cellMol))
			for(s = 0; s <= maxState; s += 1)
				if(s < numpnts(cellMol))
					molMatrix[s][m] = cellMol[s]
				endif
			endfor
		endif
	endfor
	
	// Results
	String resultsPath = "root:" + SampleName + ":Results"
	if(!DataFolderExists(resultsPath))
		NewDataFolder $resultsPath
	endif
	SetDataFolder $resultsPath
	
	// 
	Make/O/N=(maxState + 1) MolDensity_Dstate_m_avg = NaN
	Make/O/N=(maxState + 1) MolDensity_Dstate_m_sd = NaN
	Make/O/N=(maxState + 1) MolDensity_Dstate_m_sem = NaN
	Make/O/N=(maxState + 1) MolDensity_Dstate_m_n = NaN
	
	Wave avgW = MolDensity_Dstate_m_avg
	Wave sdW = MolDensity_Dstate_m_sd
	Wave semW = MolDensity_Dstate_m_sem
	Wave nW = MolDensity_Dstate_m_n
	
	for(s = 0; s <= maxState; s += 1)
		Make/FREE/N=(numFolders) tempData
		Variable k, validCount = 0
		for(k = 0; k < numFolders; k += 1)
			Variable val = molMatrix[s][k]
			if(numtype(val) == 0)
				tempData[validCount] = val
				validCount += 1
			endif
		endfor
		
		if(validCount > 0)
			Redimension/N=(validCount) tempData
			WaveStats/Q tempData
			avgW[s] = V_avg
			sdW[s] = V_sdev
			nW[s] = V_npnts
			if(V_npnts > 1)
				semW[s] = V_sdev / sqrt(V_npnts)
			else
				semW[s] = 0
			endif
		endif
	endfor
	
	SetDataFolder root:
	Print "  MolDensity_Dstate_m and statistics created in Matrix/Results"
End

// -----------------------------------------------------------------------------
// CollectMolDensityToMatrixEx - basePath/waveSuffix
// -----------------------------------------------------------------------------
// Seg: Matrix wavesuffix
Function CollectMolDensityToMatrixEx(SampleName, maxState, basePath, waveSuffix)
	String SampleName
	Variable maxState
	String basePath, waveSuffix
	
	String savedDF = GetDataFolder(1)
	
	// 
	if(StringMatch(basePath[strlen(basePath)-1], ":") == 0)
		basePath += ":"
	endif
	
	Variable numFolders = CountDataFoldersInPath(basePath, SampleName)
	if(numFolders == 0)
		SetDataFolder $savedDF
		return -1
	endif
	
	Variable m, s, n
	String FolderName
	String samplePath = basePath + SampleName + ":"
	
	// Matrix
	String matrixPath = samplePath + "Matrix"
	if(!DataFolderExists(matrixPath))
		NewDataFolder $matrixPath
	endif
	
	// Results
	String resultsPath = samplePath + "Results"
	if(!DataFolderExists(resultsPath))
		NewDataFolder $resultsPath
	endif
	
	NVAR NumOligomers = root:MaxOligomerSize
	Variable numOlig = NumOligomers
	
	// === MolDensity_Dstate ===
	// Matrix wavesuffix- Total
	SetDataFolder $matrixPath
	String molMatrixName = "MolDensity_Dstate_m"
	Make/O/N=(maxState + 1, numFolders) $molMatrixName = NaN
	Wave molMatrix = $molMatrixName
	
	for(m = 0; m < numFolders; m += 1)
		FolderName = SampleName + num2str(m + 1)
		String cellPath = samplePath + FolderName
		
		if(!DataFolderExists(cellPath))
			continue
		endif
		
		// wavesuffix
		String molWaveName = "MolDensity_Dstate" + waveSuffix
		String molPath = cellPath + ":" + molWaveName
		Wave/Z cellMol = $molPath
		
		if(WaveExists(cellMol))
			for(s = 0; s <= maxState; s += 1)
				if(s < numpnts(cellMol))
					molMatrix[s][m] = cellMol[s]
				endif
			endfor
		endif
	endfor
	
	// MolDensity_Dstate
	SetDataFolder $resultsPath
	String avgName = molMatrixName + "_avg"
	String semName = molMatrixName + "_sem"
	Make/O/N=(maxState + 1) $avgName = NaN
	Make/O/N=(maxState + 1) $semName = NaN
	Wave avgW = $avgName
	Wave semW = $semName
	
	Variable validCount, val
	for(s = 0; s <= maxState; s += 1)
		Make/FREE/N=(numFolders) tempData
		validCount = 0
		for(m = 0; m < numFolders; m += 1)
			val = molMatrix[s][m]
			if(numtype(val) == 0)
				tempData[validCount] = val
				validCount += 1
			endif
		endfor
		
		if(validCount > 0)
			Redimension/N=(validCount) tempData
			WaveStats/Q tempData
			avgW[s] = V_avg
			if(V_npnts > 1)
				semW[s] = V_sdev / sqrt(V_npnts)
			else
				semW[s] = 0
			endif
		endif
	endfor
	
	// === MolDensDist_S{n} (state) ===
	// Matrix wavesuffix
	for(s = 0; s <= maxState; s += 1)
		SetDataFolder $matrixPath
		String distMatrixName = "MolDensDist_S" + num2str(s) + "_m"
		Make/O/N=(numOlig, numFolders) $distMatrixName = NaN
		Wave distMatrix = $distMatrixName
		
		for(m = 0; m < numFolders; m += 1)
			FolderName = SampleName + num2str(m + 1)
			cellPath = samplePath + FolderName
			
			if(!DataFolderExists(cellPath))
				continue
			endif
			
			// wavesuffix
			String distWaveName = "MolDensDist_S" + num2str(s) + waveSuffix
			String distPath = cellPath + ":" + distWaveName
			Wave/Z cellDist = $distPath
			
			if(WaveExists(cellDist))
				Variable numPts = min(numpnts(cellDist), numOlig)
				for(n = 0; n < numPts; n += 1)
					distMatrix[n][m] = cellDist[n]
				endfor
			endif
		endfor
		
		// MolDensDist
		SetDataFolder $resultsPath
		avgName = distMatrixName + "_avg"
		semName = distMatrixName + "_sem"
		Make/O/N=(numOlig) $avgName = NaN
		Make/O/N=(numOlig) $semName = NaN
		Wave distAvgW = $avgName
		Wave distSemW = $semName
		
		for(n = 0; n < numOlig; n += 1)
			Make/FREE/N=(numFolders) tempData2
			validCount = 0
			for(m = 0; m < numFolders; m += 1)
				val = distMatrix[n][m]
				if(numtype(val) == 0)
					tempData2[validCount] = val
					validCount += 1
				endif
			endfor
			
			if(validCount > 0)
				Redimension/N=(validCount) tempData2
				WaveStats/Q tempData2
				distAvgW[n] = V_avg
				if(V_npnts > 1)
					distSemW[n] = V_sdev / sqrt(V_npnts)
				else
					distSemW[n] = 0
				endif
			endif
		endfor
	endfor
	
	// === StateFraction ===
	// Matrix wavesuffix
	SetDataFolder $matrixPath
	String fracMatrixName = "StateFraction_m"
	Make/O/N=(maxState + 1, numFolders) $fracMatrixName = NaN
	Wave fracMatrix = $fracMatrixName
	
	for(m = 0; m < numFolders; m += 1)
		FolderName = SampleName + num2str(m + 1)
		cellPath = samplePath + FolderName
		
		if(!DataFolderExists(cellPath))
			continue
		endif
		
		// wavesuffix
		String fracWaveName = "StateFraction" + waveSuffix
		String fracPath = cellPath + ":" + fracWaveName
		Wave/Z cellFrac = $fracPath
		
		if(WaveExists(cellFrac))
			for(s = 0; s <= maxState; s += 1)
				if(s < numpnts(cellFrac))
					fracMatrix[s][m] = cellFrac[s]
				endif
			endfor
		endif
	endfor
	
	// StateFraction
	SetDataFolder $resultsPath
	avgName = fracMatrixName + "_avg"
	semName = fracMatrixName + "_sem"
	Make/O/N=(maxState + 1) $avgName = NaN
	Make/O/N=(maxState + 1) $semName = NaN
	Wave fracAvgW = $avgName
	Wave fracSemW = $semName
	
	for(s = 0; s <= maxState; s += 1)
		Make/FREE/N=(numFolders) tempData3
		validCount = 0
		for(m = 0; m < numFolders; m += 1)
			val = fracMatrix[s][m]
			if(numtype(val) == 0)
				tempData3[validCount] = val
				validCount += 1
			endif
		endfor
		
		if(validCount > 0)
			Redimension/N=(validCount) tempData3
			WaveStats/Q tempData3
			fracAvgW[s] = V_avg
			if(V_npnts > 1)
				fracSemW[s] = V_sdev / sqrt(V_npnts)
			else
				fracSemW[s] = 0
			endif
		endif
	endfor
	
	SetDataFolder $savedDF
	Print "  MolDensity_m and statistics created for " + SampleName
	return 0
End

// -----------------------------------------------------------------------------
// DisplayOligomerDensity - DstateDensity
// -----------------------------------------------------------------------------
Function DisplayOligomerDensity(SampleName, [basePath, waveSuffix])
	String SampleName
	String basePath, waveSuffix
	
	// 
	if(ParamIsDefault(basePath))
		basePath = "root"
	endif
	if(ParamIsDefault(waveSuffix))
		waveSuffix = ""
	endif
	
	NVAR/Z Dstate = root:Dstate
	NVAR MinOligomerSize = root:MinOligomerSize
	NVAR MaxOligomerSize = root:MaxOligomerSize
	
	Variable numFolders
	if(StringMatch(basePath, "root"))
		numFolders = CountDataFolders(SampleName)
	else
		numFolders = CountDataFoldersInPath(basePath, SampleName)
	endif
	
	Variable m, n, s
	String FolderName, folderPath, resultsPath
	Variable numOligomers = MaxOligomerSize  // 1 to MaxOligomerSize
	Variable maxState = 0
	
	// samplePath
	String samplePath
	if(StringMatch(basePath, "root"))
		samplePath = "root:" + SampleName
	else
		samplePath = basePath + ":" + SampleName
	endif
	
	if(NVAR_Exists(Dstate))
		maxState = Dstate
	endif
	
	// S0=, S1=, S2=, S3=, S4=, S5=
	Make/FREE/N=(6, 3) DstateColors
	DstateColors[0][0] = 0;       DstateColors[0][1] = 0;       DstateColors[0][2] = 0       // S0: 
	DstateColors[1][0] = 0;       DstateColors[1][1] = 0;       DstateColors[1][2] = 65280   // S1: 
	DstateColors[2][0] = 65280;   DstateColors[2][1] = 43520;   DstateColors[2][2] = 0       // S2: 
	DstateColors[3][0] = 0;       DstateColors[3][1] = 39168;   DstateColors[3][2] = 0       // S3: 
	DstateColors[4][0] = 65280;   DstateColors[4][1] = 0;       DstateColors[4][2] = 0       // S4: 
	DstateColors[5][0] = 52428;   DstateColors[5][1] = 1;       DstateColors[5][2] = 41942   // S5: 
	
	// 
	for(m = 0; m < numFolders; m += 1)
		FolderName = SampleName + num2str(m + 1)
		folderPath = samplePath + ":" + FolderName + ":"
		
		if(!DataFolderExists(samplePath + ":" + FolderName))
			continue
		endif
		
		SetDataFolder $(samplePath + ":" + FolderName)
		
		Wave/Z OligomerSize = $(folderPath + "OligomerSize")
		Wave/Z ParticleDensity_Dstate = $(folderPath + "ParticleDensity_Dstate")
		Wave/Z MolDensity_Dstate = $(folderPath + "MolDensity_Dstate")
		
		if(!WaveExists(OligomerSize))
			continue
		endif
		
		// === 1: Particle-based Oligomer Fraction (Dstate) ===
		String winName1 = "ParticleFrac_" + FolderName + waveSuffix
		DoWindow/K $winName1
		
		Variable firstPlot = 1
		for(s = maxState; s >= 0; s -= 1)
			String suffix = "_S" + num2str(s)
			String fracName = "ParticleFrac" + suffix
			Wave/Z FracWave = $(folderPath + fracName)
			
			if(!WaveExists(FracWave))
				continue
			endif
			
			if(firstPlot)
				Display/K=1/N=$winName1 FracWave vs OligomerSize
				firstPlot = 0
			else
				AppendToGraph FracWave vs OligomerSize
			endif
			
			Variable r = DstateColors[min(s, 5)][0]
			Variable g = DstateColors[min(s, 5)][1]
			Variable b = DstateColors[min(s, 5)][2]
			
			ModifyGraph rgb($fracName)=(r, g, b)
			ModifyGraph mode($fracName)=4, marker($fracName)=19, msize($fracName)=3
			ModifyGraph lsize($fracName)=1.5
		endfor
		
		if(!firstPlot)
			ModifyGraph tick=2, fStyle=1, fSize=14, font="Arial"
			Label left "Particle Fraction"
			Label bottom "Oligomer Size"
			SetAxis left 0, *
			SetAxis bottom 0.5, MaxOligomerSize + 0.5
			ModifyGraph width={Aspect, 1.618}
			
			// Seg
			String graphTitle1 = GetGraphTitleWithSeg(FolderName + " Particle Fraction by Dstate", waveSuffix)
			DoWindow/T $winName1, graphTitle1
			
			// 
			String legendStr = ""
			for(s = 0; s <= maxState; s += 1)
				if(s > 0)
					legendStr += "\r"
				endif
				legendStr += "\\s(ParticleFrac_S" + num2str(s) + ") " + GetDstateName(s, maxState)
			endfor
			Legend/C/N=legend1/J/F=0/B=1/A=RT legendStr
		endif
		
		// === 2: Molecular Density Distribution (Dstate) ===
		String winName2 = "MolDensDist_" + FolderName + waveSuffix
		DoWindow/K $winName2
		
		firstPlot = 1
		for(s = maxState; s >= 0; s -= 1)
			suffix = "_S" + num2str(s)
			String densName = "MolDensDist" + suffix
			Wave/Z DensWave = $(folderPath + densName)
			
			if(!WaveExists(DensWave))
				continue
			endif
			
			if(firstPlot)
				Display/K=1/N=$winName2 DensWave vs OligomerSize
				firstPlot = 0
			else
				AppendToGraph DensWave vs OligomerSize
			endif
			
			r = DstateColors[min(s, 5)][0]
			g = DstateColors[min(s, 5)][1]
			b = DstateColors[min(s, 5)][2]
			
			ModifyGraph rgb($densName)=(r, g, b)
			ModifyGraph mode($densName)=4, marker($densName)=19, msize($densName)=3
			ModifyGraph lsize($densName)=1.5
		endfor
		
		if(!firstPlot)
			ModifyGraph tick=2, fStyle=1, fSize=14, font="Arial"
			Label left "Molecular Density (/µm\\S2\\M)"
			Label bottom "Oligomer Size"
			SetAxis left 0, *
			SetAxis bottom 0.5, MaxOligomerSize + 0.5
			ModifyGraph width={Aspect, 1.618}
			
			// Seg
			String graphTitle2 = GetGraphTitleWithSeg(FolderName + " Molecular Density Distribution by Dstate", waveSuffix)
			DoWindow/T $winName2, graphTitle2
			
			// 
			legendStr = ""
			for(s = 0; s <= maxState; s += 1)
				if(s > 0)
					legendStr += "\r"
				endif
				legendStr += "\\s(MolDensDist_S" + num2str(s) + ") " + GetDstateName(s, maxState)
			endfor
			Legend/C/N=legend1/J/F=0/B=1/A=RT legendStr
		endif
		
		// === 3: Dstate (Category plot) ===
		if(WaveExists(ParticleDensity_Dstate) && WaveExists(MolDensity_Dstate))
			String winName3 = "DstateDensity_" + FolderName + waveSuffix
			DoWindow/K $winName3
			
			// text wave
			Make/O/T/N=(maxState+1) $(folderPath + "DstateLabels")
			Wave/T DstateLabels = $(folderPath + "DstateLabels")
			for(s = 0; s <= maxState; s += 1)
				DstateLabels[s] = GetDstateName(s, maxState)
			endfor
			
			Display/K=1/N=$winName3 ParticleDensity_Dstate vs DstateLabels
			AppendToGraph MolDensity_Dstate vs DstateLabels
			
			// 
			ModifyGraph mode=5, hbFill=2
			ModifyGraph catGap(bottom)=0.3
			ModifyGraph tick(bottom)=3, barGap(bottom)=0
			
			// Dstate - zColor
			Make/O/N=(maxState+1, 3) $(folderPath + "ParticleBarColors") = 0
			Make/O/N=(maxState+1, 3) $(folderPath + "MolBarColors") = 0
			Wave ParticleBarColors = $(folderPath + "ParticleBarColors")
			Wave MolBarColors = $(folderPath + "MolBarColors")
			
			for(s = 0; s <= maxState; s += 1)
				// Particle: 
				ParticleBarColors[s][0] = min(DstateColors[min(s, 5)][0] + 25000, 65535)
				ParticleBarColors[s][1] = min(DstateColors[min(s, 5)][1] + 25000, 65535)
				ParticleBarColors[s][2] = min(DstateColors[min(s, 5)][2] + 25000, 65535)
				// Molecular: 
				MolBarColors[s][0] = DstateColors[min(s, 5)][0]
				MolBarColors[s][1] = DstateColors[min(s, 5)][1]
				MolBarColors[s][2] = DstateColors[min(s, 5)][2]
			endfor
			
			ModifyGraph zColor(ParticleDensity_Dstate)={ParticleBarColors,*,*,directRGB,0}
			ModifyGraph zColor(MolDensity_Dstate)={MolBarColors,*,*,directRGB,0}
			ModifyGraph useBarStrokeRGB(ParticleDensity_Dstate)=1, barStrokeRGB(ParticleDensity_Dstate)=(30000,30000,30000)
			ModifyGraph useBarStrokeRGB(MolDensity_Dstate)=1, barStrokeRGB(MolDensity_Dstate)=(0,0,0)
			
			ModifyGraph tick=2, fStyle=1, fSize=14, font="Arial"
			Label left "Density (/µm\\S2\\M)"
			Label bottom "Diffusion State"
			SetAxis left 0, *
			ModifyGraph width={Aspect, 1.618}
			
			TextBox/C/N=text0/A=RT/F=0 "Light: Particle\rDark: Molecular"
			
			// Seg
			String graphTitle3 = GetGraphTitleWithSeg(FolderName + " Particle vs Molecular Density", waveSuffix)
			DoWindow/T $winName3, graphTitle3
		endif
	endfor
	
	SetDataFolder root:
End

// -----------------------------------------------------------------------------
// CheckPrerequisitesForMolDensity - Mol Density
// : 0=OK, 1=Density, 2=Intensity, 3=
// -----------------------------------------------------------------------------
Function CheckPrerequisitesForMolDensity(SampleName)
	String SampleName
	
	Variable numFolders = CountDataFolders(SampleName)
	if(numFolders == 0)
		return 3
	endif
	
	// 
	String FolderName = SampleName + "1"
	String folderPath = "root:" + SampleName + ":" + FolderName + ":"
	
	Variable densityOK = 0
	Variable intensityOK = 0
	
	// Density: ParaDensityAvg
	Wave/Z ParaDensityAvg = $(folderPath + "ParaDensityAvg")
	if(WaveExists(ParaDensityAvg))
		densityOK = 1
	endif
	
	// Intensity: population_S0  coef_Int_S0 
	Wave/Z population_S0 = $(folderPath + "population_S0")
	Wave/Z coef_Int_S0 = $(folderPath + "coef_Int_S0")
	if(WaveExists(population_S0) || WaveExists(coef_Int_S0))
		intensityOK = 1
	endif
	
	if(densityOK && intensityOK)
		return 0  // OK
	elseif(!densityOK && intensityOK)
		return 1  // Density
	elseif(densityOK && !intensityOK)
		return 2  // Intensity
	else
		return 3  // 
	endif
End

// -----------------------------------------------------------------------------
// CalculateMolecularDensity - 
// : 1=, 0=
// -----------------------------------------------------------------------------
Function CalculateMolecularDensity(SampleName, [basePath, waveSuffix])
	String SampleName
	String basePath, waveSuffix
	
	// 
	if(ParamIsDefault(basePath))
		basePath = "root"
	endif
	if(ParamIsDefault(waveSuffix))
		waveSuffix = ""
	endif
	
	// basePathroot
	if(StringMatch(basePath, "root"))
		Variable checkResult
		checkResult = CheckPrerequisitesForMolDensity(SampleName)
		
		if(checkResult != 0)
			Print "=== Molecular Density Calculation ABORTED ==="
			Print "  Reason: Required prerequisite analysis not completed."
			if(checkResult == 1 || checkResult == 3)
				Print "  - Density analysis: NOT DONE"
			else
				Print "  - Density analysis: OK"
			endif
			if(checkResult == 2 || checkResult == 3)
				Print "  - Intensity fitting: NOT DONE"
			else
				Print "  - Intensity fitting: OK"
			endif
			return 0  // 
		endif
	endif
	
	// HMMHMM
	NVAR/Z cHMM = root:cHMM
	if(NVAR_Exists(cHMM) && cHMM == 1)
		CalculateMolecularDensityHMM(SampleName, basePath=basePath, waveSuffix=waveSuffix)
	endif
	
	// 
	CalculateOligomerDensity(SampleName, basePath=basePath, waveSuffix=waveSuffix)
	
	return 1  // 
End

// -----------------------------------------------------------------------------
// DisplayMolecularDensity - 
// -----------------------------------------------------------------------------
Function DisplayMolecularDensity(SampleName, [basePath, waveSuffix])
	String SampleName
	String basePath, waveSuffix
	
	// 
	if(ParamIsDefault(basePath))
		basePath = "root"
	endif
	if(ParamIsDefault(waveSuffix))
		waveSuffix = ""
	endif
	
	//  - Calculate
	Variable numFolders
	if(StringMatch(basePath, "root"))
		numFolders = CountDataFolders(SampleName)
	else
		numFolders = CountDataFoldersInPath(basePath, SampleName)
	endif
	
	if(numFolders == 0)
		return 0
	endif
	
	// samplePath
	String samplePath
	if(StringMatch(basePath, "root"))
		samplePath = "root:" + SampleName
	else
		samplePath = basePath + ":" + SampleName
	endif
	
	String FolderName = SampleName + "1"
	String folderPath = samplePath + ":" + FolderName + ":"
	
	// 
	Wave/Z OligomerSize = $(folderPath + "OligomerSize")
	if(!WaveExists(OligomerSize))
		return 0
	endif
	
	// HMMHMM
	NVAR/Z cHMM = root:cHMM
	if(NVAR_Exists(cHMM) && cHMM == 1)
		DisplayMolecularDensityHMM(SampleName, basePath=basePath, waveSuffix=waveSuffix)
	endif
	
	// 
	DisplayOligomerDensity(SampleName, basePath=basePath, waveSuffix=waveSuffix)
End
