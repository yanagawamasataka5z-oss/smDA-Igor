#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3
#pragma version=2.0
// ModuleName - 

#include <Global Fit 2>

// =============================================================================
// SMI_Diffusion.ipf - Diffusion Analysis Module
// =============================================================================
// MSD
// Global Fit
// Version 2.0 - Refactored
// =============================================================================

// -----------------------------------------------------------------------------
// MSDCalcMSD_HMM
// -----------------------------------------------------------------------------
Function CalculateMSD(SampleName, [maxLag, basePath, waveSuffix])
	String SampleName
	Variable maxLag
	String basePath, waveSuffix
	
	// 
	if(ParamIsDefault(maxLag))
		NVAR AreaRangeMSD = root:AreaRangeMSD
		maxLag = AreaRangeMSD
	endif
	if(ParamIsDefault(basePath))
		basePath = "root"
	endif
	if(ParamIsDefault(waveSuffix))
		waveSuffix = ""
	endif
	
	NVAR framerate = root:framerate
	NVAR/Z Dstate = root:Dstate
	NVAR/Z cHMM = root:cHMM
	NVAR cMoveAve = root:cMoveAve
	NVAR ThresholdMSD = root:ThresholdMSD

	//
	Variable useMoveAve = cMoveAve
	Variable threshold = ThresholdMSD
	
	Variable numFolders
	if(StringMatch(basePath, "root"))
		numFolders = CountDataFolders(SampleName)
	else
		numFolders = CountDataFoldersInPath(basePath, SampleName)
	endif
	
	Variable m, s, i, j
	String FolderName
	
	// samplePath
	String samplePath
	if(StringMatch(basePath, "root"))
		samplePath = "root:" + SampleName
	else
		samplePath = basePath + ":" + SampleName
	endif
	
	// HMMDstateS0
	Variable maxState = 0
	if(NVAR_Exists(cHMM) && cHMM == 1 && NVAR_Exists(Dstate))
		maxState = Dstate
	endif
	
	// 
	CreateResultsFolderInPath(basePath, SampleName)
	
	for(m = 0; m < numFolders; m += 1)
		FolderName = SampleName + num2str(m + 1)
		String cellPath = samplePath + ":" + FolderName
		
		if(!DataFolderExists(cellPath))
			continue
		endif
		
		SetDataFolder $cellPath
		
		// Dstate
		for(s = 0; s <= maxState; s += 1)
			String suffix = "_S" + num2str(s)
			
			// WaveSegmentationwaveSuffix
			String WName0 = "ROI" + suffix + waveSuffix
			String WName3 = "Xum" + suffix + waveSuffix
			String WName4 = "Yum" + suffix + waveSuffix
			
			Wave/Z Wave0 = $WName0
			Wave/Z Wave3 = $WName3
			Wave/Z Wave4 = $WName4
			
			if(!WaveExists(Wave0) || !WaveExists(Wave3) || !WaveExists(Wave4))
				continue
			endif
			
			Variable RowSize = numpnts(Wave0)
			
			// Wavesuffix - StatsResultsMatrix
			String name_MSD_avg = "MSD_avg" + suffix
			String name_MSD_sd = "MSD_sd" + suffix
			String name_MSD_sem = "MSD_sem" + suffix
			String name_MSD_n = "MSD_n" + suffix
			String name_MSD_time = "MSD_time" + suffix
			
			Make/O/N=(maxLag+1) $name_MSD_avg = 0, $name_MSD_time = 0
			Make/O/N=(maxLag+1) $name_MSD_sd = 0, $name_MSD_sem = 0, $name_MSD_n = 0
			Wave MSD_avg = $name_MSD_avg
			Wave MSD_sd = $name_MSD_sd
			Wave MSD_sem = $name_MSD_sem
			Wave MSD_n = $name_MSD_n
			Wave MSD_time = $name_MSD_time
			
			Variable T_threshold = 0  // n=1
			
			// j
			for(j = 1; j <= maxLag; j += 1)
				// numframej: ROI
				Make/O/N=(RowSize) numframej = 1, MSDj = NaN
				
				// numframej
				i = 0
				do
					if(numtype(Wave0[i]) == 0 && Wave0[i] > 0)  // ROI
						numframej[i+1] = numframej[i] + 1
					else
						numframej[i] = NaN
					endif
					i += 1
				while(i < RowSize - j)
				
				// NaN
				for(i = RowSize - j; i < RowSize; i += 1)
					numframej[i] = NaN
				endfor
				
				// MSDj
				i = 0
				if(useMoveAve == 0)
					// 
					do
						Variable SameROI = Wave0[i+j] - Wave0[i]  // 0ROI
						Variable del_frame = numframej[i+j] - numframej[i]
						if(numtype(SameROI) == 0 && SameROI == 0 && numtype(del_frame) == 0 && del_frame == j && numframej[i] == 1)
							MSDj[i] = (Wave3[i+j] - Wave3[i])^2 + (Wave4[i+j] - Wave4[i])^2
						else
							MSDj[i] = NaN
						endif
						i += 1
					while(i < RowSize - j)
				else
					// 
					do
						SameROI = Wave0[i+j] - Wave0[i]
						del_frame = numframej[i+j] - numframej[i]
						if(numtype(SameROI) == 0 && SameROI == 0 && numtype(del_frame) == 0 && del_frame == j)
							MSDj[i] = (Wave3[i+j] - Wave3[i])^2 + (Wave4[i+j] - Wave4[i])^2
						else
							MSDj[i] = NaN
						endif
						i += 1
					while(i < RowSize - j)
				endif
				
				// 
				WaveStats/Q MSDj
				
				if(j == 1)
					MSD_time[j] = j * framerate
					MSD_avg[j] = V_avg
					MSD_sd[j] = V_sdev
					MSD_sem[j] = V_sem
					MSD_n[j] = V_npnts
					T_threshold = V_npnts * threshold / 100
				elseif(V_npnts > T_threshold)
					MSD_time[j] = j * framerate
					MSD_avg[j] = V_avg
					MSD_sd[j] = V_sdev
					MSD_sem[j] = V_sem
					MSD_n[j] = V_npnts
				else
					MSD_time[j] = j * framerate
					MSD_avg[j] = NaN
					MSD_sd[j] = NaN
					MSD_sem[j] = NaN
					MSD_n[j] = NaN
				endif
				
				KillWaves/Z numframej, MSDj
			endfor
			
			// lag=0
			MSD_time[0] = 0
			MSD_avg[0] = 0
			MSD_sd[0] = 0.0001
			MSD_sem[0] = 0.0001
			MSD_n[0] = MSD_n[1]
		endfor
		
		ShowProgress(m+1, numFolders, "MSD")
	endfor
	
	EndProgress()
	SetDataFolder root:
End

// -----------------------------------------------------------------------------
// MSDDstate
// -----------------------------------------------------------------------------
Function DisplayMSDGraphHMM(SampleName, [basePath, waveSuffix])
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
	NVAR framerate = root:framerate
	NVAR AreaRangeMSD = root:AreaRangeMSD
	
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
	
	Variable maxState = 0
	if(NVAR_Exists(Dstate))
		maxState = Dstate
	endif
	
	// S0:, S1:, S2:, S3:, S4:, S5:
	Make/FREE/N=(6,3) stateColors
	stateColors[0][0] = 0;       stateColors[0][1] = 0;       stateColors[0][2] = 0        // S0: 
	stateColors[1][0] = 0;       stateColors[1][1] = 0;       stateColors[1][2] = 65280    // S1: 
	stateColors[2][0] = 65280;   stateColors[2][1] = 43520;   stateColors[2][2] = 0        // S2: 
	stateColors[3][0] = 0;       stateColors[3][1] = 39168;   stateColors[3][2] = 0        // S3: 
	stateColors[4][0] = 65280;   stateColors[4][1] = 0;       stateColors[4][2] = 0        // S4: 
	stateColors[5][0] = 65280;   stateColors[5][1] = 0;       stateColors[5][2] = 65280    // S5: 
	
	for(m = 0; m < numFolders; m += 1)
		FolderName = SampleName + num2str(m + 1)
		String cellPath = samplePath + ":" + FolderName
		
		if(!DataFolderExists(cellPath))
			continue
		endif
		
		SetDataFolder $cellPath
		
		Wave/Z MSD_avg_S0, MSD_time_S0
		if(!WaveExists(MSD_avg_S0))
			continue
		endif
		
		// 
		String winName = "MSD_" + FolderName + waveSuffix
		DoWindow/K $winName
		
		// S0
		Display/K=1/N=$winName MSD_avg_S0 vs MSD_time_S0
		
		// Seg
		String graphTitle = GetGraphTitleWithSeg(FolderName + " MSD", waveSuffix)
		DoWindow/T $winName, graphTitle
		
		ModifyGraph rgb(MSD_avg_S0)=(0,0,0)
		ModifyGraph mode(MSD_avg_S0)=3, marker(MSD_avg_S0)=19, msize(MSD_avg_S0)=3
		
		// S1
		for(s = 1; s <= maxState; s += 1)
			String msdName = "MSD_avg_S" + num2str(s)
			String timeName = "MSD_time_S" + num2str(s)
			Wave/Z MSDWave = $msdName
			Wave/Z TimeWave = $timeName
			if(WaveExists(MSDWave) && WaveExists(TimeWave))
				AppendToGraph MSDWave vs TimeWave
				ModifyGraph mode($msdName)=3, marker($msdName)=19, msize($msdName)=3
				ModifyGraph rgb($msdName)=(stateColors[s][0], stateColors[s][1], stateColors[s][2])
			endif
		endfor
		
		// Dstate
		for(s = 0; s <= maxState; s += 1)
			String fitCurveName = "fit_MSD_S" + num2str(s)
			String fitTimeName = "fit_MSD_time_S" + num2str(s)
			Wave/Z fitCurve = $fitCurveName
			Wave/Z fitTime = $fitTimeName
			if(WaveExists(fitCurve) && WaveExists(fitTime))
				AppendToGraph fitCurve vs fitTime
				ModifyGraph mode($fitCurveName)=0, lsize($fitCurveName)=2
				ModifyGraph rgb($fitCurveName)=(stateColors[s][0], stateColors[s][1], stateColors[s][2])
			endif
		endfor
		
		// 
		ModifyGraph tick=0, mirror=0
		ModifyGraph lowTrip(left)=0.0001
		ModifyGraph fStyle=1, fSize=16, font="Arial"
		ModifyGraph width={Aspect,1.618}
		SetAxis left 0, *
		SetAxis bottom 0, AreaRangeMSD * framerate
		Label left "MSD [μm²]"
		Label bottom "Δt [s]"
		
		// 
		String stateName = GetDstateName(0, maxState)
		String legendStr = "\\F'Arial'\\Z12\r\\s(MSD_avg_S0) " + stateName
		for(s = 1; s <= maxState; s += 1)
			msdName = "MSD_avg_S" + num2str(s)
			Wave/Z MW = $msdName
			if(WaveExists(MW))
				stateName = GetDstateName(s, maxState)
				legendStr += "\r\\s(" + msdName + ") " + stateName
			endif
		endfor
		TextBox/C/N=text0/F=0/B=1/A=LT legendStr
	endfor
	
	SetDataFolder root:
End

// -----------------------------------------------------------------------------
// MSDHMMDstate
// -----------------------------------------------------------------------------
Function FitMSD_Safe(SampleName, fitType, [basePath, waveSuffix])
	String SampleName
	Variable fitType  // 0: , 1: , 2: +, 3: , 4: +
	String basePath, waveSuffix
	
	// 
	if(ParamIsDefault(basePath))
		basePath = "root"
	endif
	if(ParamIsDefault(waveSuffix))
		waveSuffix = ""
	endif
	
	NVAR framerate = root:framerate
	NVAR AreaRangeMSD = root:AreaRangeMSD
	NVAR Efix = root:Efix
	NVAR AlphaFix = root:AlphaFix
	NVAR/Z Dstate = root:Dstate
	NVAR/Z cHMM = root:cHMM
	NVAR/Z cSuppressOutput = root:cSuppressOutput
	Variable suppressOutput = NVAR_Exists(cSuppressOutput) ? cSuppressOutput : 0
	
	// 
	NVAR InitialD0 = root:InitialD0
	NVAR InitialL = root:InitialL
	NVAR InitialEpsilon = root:InitialEpsilon
	NVAR InitialAlpha = root:InitialAlpha
	
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
	
	// HMMDstateS0
	Variable maxState = 0
	if(NVAR_Exists(cHMM) && cHMM == 1 && NVAR_Exists(Dstate))
		maxState = Dstate
	endif
	
	if(!suppressOutput)
		Print "=== MSD Fitting (HMM) ==="
		Printf "Fit type: %d, States: S0-S%d\r", fitType, maxState
	endif
	
	Variable fitEnd, fitResult, fitStart
	String fitFunc, holdStr
	
	Variable successCount = 0
	Variable failCount = 0
	
	for(m = 0; m < numFolders; m += 1)
		FolderName = SampleName + num2str(m + 1)
		String cellPath = samplePath + ":" + FolderName
		
		if(!DataFolderExists(cellPath))
			continue
		endif
		
		SetDataFolder $cellPath
		
		if(!suppressOutput)
			Printf "  %s:\r", FolderName
		endif
		
		// Dstate
		for(s = 0; s <= maxState; s += 1)
			String msdName = "MSD_avg_S" + num2str(s)
			String timeName = "MSD_time_S" + num2str(s)
			String fitCurveName = "fit_MSD_S" + num2str(s)
			String fitTimeName = "fit_MSD_time_S" + num2str(s)
			String coefName = "coef_MSD_S" + num2str(s)
			
			Wave/Z MSD_avg = $msdName
			Wave/Z MSD_time = $timeName
			
			if(!WaveExists(MSD_avg) || !WaveExists(MSD_time))
				continue
			endif
			
			// 
			fitStart = 1
			fitEnd = min(AreaRangeMSD, numpnts(MSD_avg) - 1)
			
			// 
			Make/O/D/N=3 $coefName
			Wave coef_MSD = $coefName
			holdStr = ""
			fitFunc = ""
			
			switch(fitType)
				case 0:  //  MSD = 4Dt
					coef_MSD[0] = InitialD0
					fitFunc = "FreeDiffusion"
					Redimension/N=1 coef_MSD
					break
				case 1:  // 
					coef_MSD[0] = InitialD0
					coef_MSD[1] = InitialL
					fitFunc = "MSD_dt"
					Redimension/N=2 coef_MSD
					break
				case 2:  //  + 
					coef_MSD[0] = InitialD0
					coef_MSD[1] = InitialL
					coef_MSD[2] = InitialEpsilon
					fitFunc = "MSD_dt_epsilon"
					if(Efix)
						holdStr = "001"
					endif
					break
				case 3:  //  MSD = 4D*t^alpha
					coef_MSD[0] = InitialD0
					coef_MSD[1] = InitialAlpha
					fitFunc = "AnomalousDiffusion"
					Redimension/N=2 coef_MSD
					if(AlphaFix)
						holdStr = "01"
					endif
					break
				case 4:  //  + 
					coef_MSD[0] = InitialD0
					coef_MSD[1] = InitialAlpha
					coef_MSD[2] = InitialEpsilon
					fitFunc = "MSD_dt_Alpha_epsilon"
					if(Efix && AlphaFix)
						holdStr = "011"
					elseif(Efix)
						holdStr = "001"
					elseif(AlphaFix)
						holdStr = "010"
					endif
					break
			endswitch
			
			// 
			fitResult = SafeFitMSD(MSD_avg, MSD_time, coef_MSD, fitFunc, fitStart, fitEnd, holdStr)
			
			if(fitResult == 0)
				successCount += 1
				
				// 10
				Variable numDataPts = numpnts(MSD_time)
				Variable numFitPts = (numDataPts - 1) * 10 + 1  // 10
				Variable tMax = MSD_time[numDataPts - 1]
				Variable tMin = MSD_time[0]
				Variable dt_fit = (tMax - tMin) / (numFitPts - 1)
				
				Make/O/N=(numFitPts) $fitCurveName, $fitTimeName
				Wave fitCurve = $fitCurveName
				Wave fitTime = $fitTimeName
				
				Variable i
				for(i = 0; i < numFitPts; i += 1)
					Variable t = tMin + i * dt_fit
					fitTime[i] = t
					switch(fitType)
						case 0:  // 
							fitCurve[i] = 4 * coef_MSD[0] * t
							break
						case 1:  // 
							Variable L2_1 = coef_MSD[1]^2
							fitCurve[i] = (L2_1/3) * (1 - exp(-12 * coef_MSD[0] * t / L2_1))
							break
						case 2:  //  + 
							Variable L2_2 = coef_MSD[1]^2
							fitCurve[i] = (L2_2/3) * (1 - exp(-12 * coef_MSD[0] * t / L2_2)) + 4 * coef_MSD[2]^2
							break
						case 3:  // 
							fitCurve[i] = 4 * coef_MSD[0] * t^coef_MSD[1]
							break
						case 4:  //  + 
							fitCurve[i] = 4 * coef_MSD[0] * t^coef_MSD[1] + 4 * coef_MSD[2]^2
							break
					endswitch
				endfor
				
				Printf "    S%d: D=%.4f", s, coef_MSD[0]
				if(fitType == 1 || fitType == 2)
					Printf ", L=%.4f", coef_MSD[1]
				endif
				if(fitType == 3 || fitType == 4)
					Printf ", alpha=%.3f", coef_MSD[1]
				endif
				if(fitType == 2 || fitType == 4)
					Printf ", epsilon=%.4f", coef_MSD[2]
				endif
				Printf "\r"
			else
				// : 0
				Make/O/N=2 $fitCurveName = 0, $fitTimeName = 0
				Wave fitCurve = $fitCurveName
				Wave fitTime = $fitTimeName
				fitTime[0] = 0
				fitTime[1] = 1
				// wave0
				coef_MSD = 0
				Printf "    S%d: wave\r", s
				failCount += 1
			endif
		endfor
		
		ShowProgress(m+1, numFolders, "MSD")
	endfor
	
	EndProgress()
	
	// 
	Printf "MSD:  %d,  %d\r", successCount, failCount
	
	SetDataFolder root:
	return successCount
End

static Function SafeFitMSD(msdWave, timeWave, coefWave, fitFunc, startP, endP, holdStr)
	Wave msdWave, timeWave, coefWave
	String fitFunc
	Variable startP, endP
	String holdStr
	
	Variable V_FitError = 0
	Variable V_FitQuitReason = 0
	Variable maxRetries = 3
	Variable retry, hIdx
	
	// 
	Duplicate/FREE coefWave, originalCoef
	
	// 
	Variable numPts = endP - startP + 1
	Make/FREE/D/N=(numPts) msd_fit, time_fit
	msd_fit = msdWave[startP + p]
	time_fit = timeWave[startP + p]
	
	for(retry = 0; retry < maxRetries; retry += 1)
		V_FitError = 0
		
		try
			AbortOnRTE
			if(strlen(holdStr) > 0)
				FuncFit/Q/N/W=2/H=holdStr $fitFunc, coefWave, msd_fit /X=time_fit; AbortOnRTE
			else
				FuncFit/Q/N/W=2 $fitFunc, coefWave, msd_fit /X=time_fit; AbortOnRTE
			endif
			
			if(V_FitError == 0)
				// 
				if(coefWave[0] > 0 && coefWave[0] < 100)  // D > 0 
					return 0  // 
				endif
			endif
		catch
			Variable err = GetRTError(1)  // 
			V_FitError = 1
		endtry
		
		// 
		if(retry < maxRetries - 1)
			coefWave = originalCoef * (1 + 0.5 * (retry + 1))  // 
			// holdStr: 
			for(hIdx = 0; hIdx < strlen(holdStr); hIdx += 1)
				if(CmpStr(holdStr[hIdx], "1") == 0)
					coefWave[hIdx] = originalCoef[hIdx]
				endif
			endfor
		endif
	endfor
	
	return -1  // 
End

static Function CalculateMSDStats(SampleName)
	String SampleName
	
	SetDataFolder root:$(SampleName):Results
	
	Wave fit_D, fit_L, fit_epsilon, fit_Success
	
	// 
	Extract/O fit_D, fit_D_valid, fit_Success == 1 && numtype(fit_D) == 0
	Extract/O fit_L, fit_L_valid, fit_Success == 1 && numtype(fit_L) == 0
	Extract/O fit_epsilon, fit_eps_valid, fit_Success == 1 && numtype(fit_epsilon) == 0
	
	// 
	Make/O/N=3 fit_D_stats = NaN  // avg, sd, sem
	Make/O/N=3 fit_L_stats = NaN
	Make/O/N=3 fit_eps_stats = NaN
	
	if(numpnts(fit_D_valid) > 0)
		WaveStats/Q fit_D_valid
		fit_D_stats[0] = V_avg
		fit_D_stats[1] = V_sdev
		fit_D_stats[2] = V_sdev / sqrt(V_npnts)
	endif
	
	if(numpnts(fit_L_valid) > 0)
		WaveStats/Q fit_L_valid
		fit_L_stats[0] = V_avg
		fit_L_stats[1] = V_sdev
		fit_L_stats[2] = V_sdev / sqrt(V_npnts)
	endif
	
	if(numpnts(fit_eps_valid) > 0)
		WaveStats/Q fit_eps_valid
		fit_eps_stats[0] = V_avg
		fit_eps_stats[1] = V_sdev
		fit_eps_stats[2] = V_sdev / sqrt(V_npnts)
	endif
	
	// 
	Printf "\r=== MSD Fitting Results ===\r"
	Printf "D [um²/s]: %.4f ± %.4f (SEM: %.4f)\r", fit_D_stats[0], fit_D_stats[1], fit_D_stats[2]
	Printf "L [um]: %.4f ± %.4f (SEM: %.4f)\r", fit_L_stats[0], fit_L_stats[1], fit_L_stats[2]
	Printf "ε [um]: %.4f ± %.4f (SEM: %.4f)\r", fit_eps_stats[0], fit_eps_stats[1], fit_eps_stats[2]
End

// -----------------------------------------------------------------------------
// 
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// Global Fit
// -----------------------------------------------------------------------------



// -----------------------------------------------------------------------------
// Global Fit
// -----------------------------------------------------------------------------


// -----------------------------------------------------------------------------
// MSD
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// MSD-dt 
// -----------------------------------------------------------------------------
Function DisplayMSDGraph(SampleName)
	String SampleName
	
	// HMMDstate
	NVAR/Z cHMM = root:cHMM
	if(NVAR_Exists(cHMM) && cHMM == 1)
		DisplayMSDGraphHMM(SampleName)
		return 0
	endif
	
	// HMM: S0
	Variable numFolders = CountDataFolders(SampleName)
	Variable m
	String FolderName, traceName
	
	// 
	FolderName = SampleName + "1"
	SetDataFolder root:$(SampleName):$(FolderName)
	
	Wave/Z MSD_avg, MSD_time
	if(!WaveExists(MSD_avg))
		// 
		Wave/Z MSD_avg_S0, MSD_time_S0
		if(WaveExists(MSD_avg_S0))
			Duplicate/O MSD_avg_S0, MSD_avg
			Duplicate/O MSD_time_S0, MSD_time
		else
			Print "MSD_avg"
			SetDataFolder root:
			return -1
		endif
	endif
	
	// 
	Display/K=1 MSD_avg vs MSD_time
	
	// 
	ModifyGraph tick=2, mirror=1, fStyle=1, fSize=14, font="Arial"
	ModifyGraph mode=3, marker=19, msize=2, lsize=1
	ModifyGraph rgb=(0,0,0)
	Label left "MSD (µm\\S2\\M)"
	Label bottom "Δt (s)"
	ModifyGraph width={Aspect,1.618}
	
	String graphTitle = SampleName + " MSD-dt plot"
	DoWindow/T kwTopWin, graphTitle
	
	// 
	for(m = 1; m < numFolders; m += 1)
		FolderName = SampleName + num2str(m + 1)
		SetDataFolder root:$(SampleName):$(FolderName)
		
		Wave/Z MSD_avg_m = MSD_avg
		Wave/Z MSD_time_m = MSD_time
		if(WaveExists(MSD_avg_m))
			traceName = "MSD_avg#" + num2str(m)
			AppendToGraph MSD_avg_m vs MSD_time_m
			ModifyGraph mode($traceName)=3, marker($traceName)=19, msize($traceName)=2
		endif
	endfor
	
	// 
	SetDataFolder root:$(SampleName):$(SampleName + "1")
	Wave/Z fit_MSD_avg
	Wave/Z MSD_time_S0
	Wave/Z MSD_time_old = MSD_time
	if(WaveExists(fit_MSD_avg))
		if(WaveExists(MSD_time_S0))
			AppendToGraph fit_MSD_avg vs MSD_time_S0
		elseif(WaveExists(MSD_time_old))
			AppendToGraph fit_MSD_avg vs MSD_time_old
		endif
		ModifyGraph lsize(fit_MSD_avg)=1.5, rgb(fit_MSD_avg)=(65280,0,0)
	endif
	
	SetDataFolder root:
	return 0
End

// -----------------------------------------------------------------------------
//  
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// 
// -----------------------------------------------------------------------------
Function DisplayDiffusionResultsGraph(SampleName)
	String SampleName
	
	SetDataFolder root:$(SampleName):Results
	
	Wave/Z fit_D, fit_L, fit_epsilon, fit_Success
	if(!WaveExists(fit_D))
		Print "fit_D"
		SetDataFolder root:
		return -1
	endif
	
	// 
	Extract/O fit_D, fit_D_valid, fit_Success == 1 && numtype(fit_D) == 0
	
	if(numpnts(fit_D_valid) == 0)
		Print ""
		SetDataFolder root:
		return -1
	endif
	
	// 
	WaveStats/Q fit_D_valid
	Printf "=== %s Diffusion Results ===\r", SampleName
	Printf "D = %.4f ± %.4f µm²/s (n=%d)\r", V_avg, V_sdev, V_npnts
	
	//
	NVAR DhistBin = root:DhistBin
	NVAR DhistDim = root:DhistDim
	Make/O/N=(DhistDim) D_Hist
	Histogram/B={0, DhistBin, DhistDim} fit_D_valid, D_Hist

	Make/O/N=(DhistDim) D_Hist_x
	D_Hist_x = DhistBin * (p + 0.5)
	
	// 
	Display/K=1 D_Hist vs D_Hist_x
	ModifyGraph tick=2, mirror=1, fStyle=1, fSize=14, font="Arial"
	ModifyGraph mode=5, hbFill=2
	ModifyGraph rgb=(0,0,0)
	Label left "Count"
	Label bottom "D (µm²/s)"
	ModifyGraph width={Aspect,1.618}
	
	String graphTitle = SampleName + " D Distribution"
	DoWindow/T kwTopWin, graphTitle
	
	SetDataFolder root:
	return 0
End

// -----------------------------------------------------------------------------
// Step Size (Displacement) Histogram - Δt min/max
// step size
// MSD
// -----------------------------------------------------------------------------
Function CalculateStepSizeHistogramHMM(SampleName, [basePath, useDeltaTMin, useDeltaTMax, waveSuffix])
	String SampleName
	String basePath         // :  "root"
	Variable useDeltaTMin   // : ΔtMin
	Variable useDeltaTMax   // : ΔtMax
	String waveSuffix       // : wave"_C1E", "_C2E"
	
	NVAR StepHistBin = root:StepHistBin
	NVAR StepHistDim = root:StepHistDim
	NVAR framerate = root:framerate
	NVAR/Z Dstate = root:Dstate
	NVAR/Z cHMM = root:cHMM
	NVAR StepDeltaTMin = root:StepDeltaTMin
	NVAR StepDeltaTMax = root:StepDeltaTMax
	NVAR cMoveAve = root:cMoveAve
	NVAR/Z cSuppressOutput = root:cSuppressOutput
	Variable suppressOutput = NVAR_Exists(cSuppressOutput) ? cSuppressOutput : 0

	//
	if(ParamIsDefault(basePath))
		basePath = "root"
	endif
	if(ParamIsDefault(waveSuffix))
		waveSuffix = ""
	endif

	//
	Variable deltaTMin, deltaTMax
	if(ParamIsDefault(useDeltaTMin))
		deltaTMin = StepDeltaTMin
	else
		deltaTMin = useDeltaTMin
	endif
	if(ParamIsDefault(useDeltaTMax))
		deltaTMax = StepDeltaTMax
	else
		deltaTMax = useDeltaTMax
	endif
	Variable useMoveAve = cMoveAve
	
	Variable numFolders = CountDataFoldersInPath(basePath, SampleName)
	Variable m, s, i, maxState, deltaT
	String FolderName
	
	// HMMDstateS0
	Variable isHMM = 0
	if(NVAR_Exists(cHMM) && cHMM == 1 && NVAR_Exists(Dstate))
		isHMM = 1
		maxState = Dstate
	else
		maxState = 0
	endif
	
	if(!suppressOutput)
		Print "=== Calculating Step Size Histogram ==="
		Printf "BasePath: %s, Δt range: %d-%d frames, Bin: %.4f um, States: S0-S%d, suffix=%s\r", basePath, deltaTMin, deltaTMax, StepHistBin, maxState, waveSuffix
		Printf "Processing %d folders...\r", numFolders
	endif
	
	// 
	for(m = 0; m < numFolders; m += 1)
		FolderName = SampleName + num2str(m + 1)
		String folderFullPath = basePath + ":" + SampleName + ":" + FolderName
		
		if(!DataFolderExists(folderFullPath))
			break
		endif
		
		SetDataFolder $folderFullPath
		
		Printf "  Folder %s:\r", FolderName
		
		// Δt
		for(deltaT = deltaTMin; deltaT <= deltaTMax; deltaT += 1)
			
			// DstateWave
			for(s = 0; s <= maxState; s += 1)
				String stepAllName = "StepAll_dt" + num2str(deltaT) + "_S" + num2str(s) + waveSuffix
				Make/O/N=0 $stepAllName
			endfor
			
			// Dstate
			for(s = 0; s <= maxState; s += 1)
				String stateSuffix = "_S" + num2str(s)
				
				// WavestateSuffix + waveSuffix
				String WName0 = "ROI" + stateSuffix + waveSuffix
				String WName3 = "Xum" + stateSuffix + waveSuffix
				String WName4 = "Yum" + stateSuffix + waveSuffix
				
				Wave/Z Wave0 = $WName0
				Wave/Z Wave3 = $WName3
				Wave/Z Wave4 = $WName4
				
				if(!WaveExists(Wave0) || !WaveExists(Wave3) || !WaveExists(Wave4))
					// wave
					if(deltaT == deltaTMin)  // Δt
						String missingWaves = ""
						if(!WaveExists(Wave0))
							missingWaves += WName0 + " "
						endif
						if(!WaveExists(Wave3))
							missingWaves += WName3 + " "
						endif
						if(!WaveExists(Wave4))
							missingWaves += WName4 + " "
						endif
						Printf "    S%d: Missing waves - %s\r", s, missingWaves
					endif
					continue
				endif
				
				Variable RowSize = numpnts(Wave0)
				Variable j = deltaT
				
				if(RowSize <= j)
					continue
				endif
				
				// numframej: ROI
				Make/O/N=(RowSize) numframej = 1, StepSizej = NaN
				
				// numframej
				i = 0
				do
					if(numtype(Wave0[i]) == 0 && Wave0[i] > 0)
						numframej[i+1] = numframej[i] + 1
					else
						numframej[i] = NaN
					endif
					i += 1
				while(i < RowSize - j)
				
				// NaN
				for(i = RowSize - j; i < RowSize; i += 1)
					numframej[i] = NaN
				endfor
				
				// Step sizeMSDj
				i = 0
				if(useMoveAve == 0)
					// 
					do
						Variable SameROI = Wave0[i+j] - Wave0[i]
						Variable del_frame = numframej[i+j] - numframej[i]
						if(numtype(SameROI) == 0 && SameROI == 0 && numtype(del_frame) == 0 && del_frame == j && numframej[i] == 1)
							Variable dx = Wave3[i+j] - Wave3[i]
							Variable dy = Wave4[i+j] - Wave4[i]
							StepSizej[i] = sqrt(dx^2 + dy^2)
						else
							StepSizej[i] = NaN
						endif
						i += 1
					while(i < RowSize - j)
				else
					// 
					do
						SameROI = Wave0[i+j] - Wave0[i]
						del_frame = numframej[i+j] - numframej[i]
						if(numtype(SameROI) == 0 && SameROI == 0 && numtype(del_frame) == 0 && del_frame == j)
							dx = Wave3[i+j] - Wave3[i]
							dy = Wave4[i+j] - Wave4[i]
							StepSizej[i] = sqrt(dx^2 + dy^2)
						else
							StepSizej[i] = NaN
						endif
						i += 1
					while(i < RowSize - j)
				endif
				
				// step sizeStepAll
				stepAllName = "StepAll_dt" + num2str(deltaT) + "_S" + num2str(s) + waveSuffix
				Wave StepAll = $stepAllName
				Variable currentSize = numpnts(StepAll)
				
				for(i = 0; i < RowSize; i += 1)
					if(numtype(StepSizej[i]) == 0)
						InsertPoints currentSize, 1, StepAll
						StepAll[currentSize] = StepSizej[i]
						currentSize += 1
					endif
				endfor
				
				KillWaves/Z numframej, StepSizej
			endfor
			
			// 
			// Δt=1
			if(deltaT == deltaTMin)
				Variable totalDt1 = 0
				for(s = 0; s <= maxState; s += 1)
					stepAllName = "StepAll_dt" + num2str(deltaT) + "_S" + num2str(s) + waveSuffix
					Wave/Z StepAllS = $stepAllName
					if(WaveExists(StepAllS))
						// 
						String countName = "StepCount_dt1_S" + num2str(s) + waveSuffix
						Variable/G $countName = numpnts(StepAllS)
						if(s == 0)
							totalDt1 = numpnts(StepAllS)
						endif
					endif
				endfor
				// 
				for(s = 1; s <= maxState; s += 1)
					String fracName = "StepFrac_dt1_S" + num2str(s) + waveSuffix
					String cntName = "StepCount_dt1_S" + num2str(s) + waveSuffix
					NVAR/Z cnt = $cntName
					if(NVAR_Exists(cnt) && totalDt1 > 0)
						Variable/G $fracName = cnt / totalDt1
					endif
				endfor
			endif
			
			// Δt
			if(deltaT == deltaTMin)
				Printf "StepHist Normalization Debug (%s):\r", FolderName
			endif
			
			for(s = 0; s <= maxState; s += 1)
				stepAllName = "StepAll_dt" + num2str(deltaT) + "_S" + num2str(s) + waveSuffix
				Wave/Z StepAll = $stepAllName
				
				String stepHistName = "StepHist_dt" + num2str(deltaT) + "_S" + num2str(s) + waveSuffix
				String stepXName = "StepHist_x_dt" + num2str(deltaT) + "_S" + num2str(s) + waveSuffix
				
				Make/O/N=(StepHistDim) $stepHistName = 0, $stepXName = 0
				Wave StepHist = $stepHistName
				Wave StepX = $stepXName
				
				StepX = StepHistBin * (p + 0.5)
				
				// StepAllHistogram
				if(WaveExists(StepAll) && numpnts(StepAll) > 0)
					Histogram/B={0, StepHistBin, StepHistDim} StepAll, StepHist
				endif
				// StepHist = 0
				
				// S0/S0
				//  All = ΣSn 
				stepAllName = "StepAll_dt" + num2str(deltaT) + "_S0" + waveSuffix
				Wave/Z StepAll_S0 = $stepAllName
				Variable totalS0 = 0
				if(WaveExists(StepAll_S0))
					totalS0 = numpnts(StepAll_S0)
				endif
				if(totalS0 > 0)
					StepHist /= totalS0
				endif
				
				// Δt
				if(deltaT == deltaTMin)
					Variable stepCount = 0
					if(WaveExists(StepAll))
						stepCount = numpnts(StepAll)
					endif
					Printf "  S%d: numpnts(StepAll) = %d, totalS0 = %d, sum(StepHist) = %.4f\r", s, stepCount, totalS0, sum(StepHist)
				endif
			endfor
		endfor
		
		Printf "    Processed Δt=%d-%d\r", deltaTMin, deltaTMax
		
		// HMMP waveRtime_Sn
		if(isHMM && maxState > 0)
			String hmmpName = "HMMP" + waveSuffix
			Make/O/N=(maxState + 1) $hmmpName = 0  // S0, S1, ..., Sn
			Wave HMMP_ref = $hmmpName
			
			// Rtime_Sn
			Variable totalPoints = 0
			for(s = 0; s <= maxState; s += 1)
				String rtimeSnN = "Rtime_S" + num2str(s) + waveSuffix
				Wave/Z RtimeSnW = $rtimeSnN
				if(WaveExists(RtimeSnW))
					// NaN
					Extract/FREE/O RtimeSnW, tempRtime, numtype(RtimeSnW) != 2
					Variable pointCount = numpnts(tempRtime)
					if(s == 0)
						HMMP_ref[0] = pointCount  // S0
						totalPoints = pointCount
					else
						HMMP_ref[s] = pointCount
					endif
				endif
			endfor
			
			// S0=100%, S1-Sn100%
			if(totalPoints > 0)
				HMMP_ref[0] = 100  // S0100%
				Variable sumS1Sn = 0
				for(s = 1; s <= maxState; s += 1)
					sumS1Sn += HMMP_ref[s]
				endfor
				if(sumS1Sn > 0)
					for(s = 1; s <= maxState; s += 1)
						HMMP_ref[s] = HMMP_ref[s] / sumS1Sn * 100
					endfor
				endif
			endif
			Printf "    HMMP%s created: ", waveSuffix
			for(s = 0; s <= maxState; s += 1)
				Printf "S%d=%.1f%% ", s, HMMP_ref[s]
			endfor
			Printf "\r"
		endif
		
		ShowProgress(m+1, numFolders, "Step Hist")
	endfor
	
	EndProgress()
	SetDataFolder root:
	Print "Step size histogram calculation complete"
End

// -----------------------------------------------------------------------------
// Step Size Histogram Display - HMM
// ΔtGraph
// S0: S1-Sn: : 
// -----------------------------------------------------------------------------
Function DisplayStepSizeHistogramHMM(SampleName, [basePath, useDeltaTMin, useDeltaTMax, waveSuffix])
	String SampleName
	String basePath         // :  "root"
	Variable useDeltaTMin   // : ΔtMin
	Variable useDeltaTMax   // : ΔtMax
	String waveSuffix       // : wave"_C1E", "_C2E"
	
	NVAR/Z Dstate = root:Dstate
	NVAR/Z cHMM = root:cHMM
	NVAR StepDeltaTMin = root:StepDeltaTMin
	NVAR StepDeltaTMax = root:StepDeltaTMax

	//
	if(ParamIsDefault(basePath))
		basePath = "root"
	endif
	if(ParamIsDefault(waveSuffix))
		waveSuffix = ""
	endif

	// HMM
	Variable isHMM = 0
	Variable maxState = 0
	if(NVAR_Exists(cHMM) && cHMM == 1 && NVAR_Exists(Dstate))
		isHMM = 1
		maxState = Dstate
	endif

	// Δt
	Variable deltaTMin, deltaTMax
	if(ParamIsDefault(useDeltaTMin))
		deltaTMin = StepDeltaTMin
	else
		deltaTMin = useDeltaTMin
	endif
	if(ParamIsDefault(useDeltaTMax))
		deltaTMax = StepDeltaTMax
	else
		deltaTMax = useDeltaTMax
	endif
	
	Variable numFolders = CountDataFoldersInPath(basePath, SampleName)
	Variable m, deltaT, s, i
	String FolderName
	
	// S0:/, S1:, S2:, S3:, S4:, S5:
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
		String folderFullPath = basePath + ":" + SampleName + ":" + FolderName
		
		if(!DataFolderExists(folderFullPath))
			break
		endif
		
		SetDataFolder $folderFullPath
		
		// HMMcoef_Step_2D_S0
		Variable numFitStates = 1
		if(isHMM == 0)
			String coef2DName = "coef_Step_2D_S0" + waveSuffix
			Wave/Z Coef2D_S0 = $coef2DName
			if(WaveExists(Coef2D_S0))
				Variable nCols = DimSize(Coef2D_S0, 1)
				numFitStates = (nCols - 2) / 2  // [deltaT, dt, A1...An, sigma1...sigman]
			endif
		endif
		
		// Δt
		for(deltaT = deltaTMin; deltaT <= deltaTMax; deltaT += 1)
			String winName = "StepHist_dt" + num2str(deltaT) + "_" + FolderName + waveSuffix
			DoWindow/K $winName
			
			// S0
			String histName0 = "StepHist_dt" + num2str(deltaT) + "_S0" + waveSuffix
			String xName0 = "StepHist_x_dt" + num2str(deltaT) + "_S0" + waveSuffix
			
			Wave/Z StepHist_S0 = $histName0
			Wave/Z StepHist_x_S0 = $xName0
			
			if(!WaveExists(StepHist_S0) || !WaveExists(StepHist_x_S0))
				continue
			endif
			
			// S0
			Display/K=1/N=$winName StepHist_S0 vs StepHist_x_S0
			
			// Seg
			String graphTitle = GetGraphTitleWithSeg(FolderName + " Step size (dt=" + num2str(deltaT) + ")", waveSuffix)
			DoWindow/T $winName, graphTitle
			
			ModifyGraph mode($histName0)=5, hbFill($histName0)=4
			ModifyGraph rgb($histName0)=(stateColors[0][0], stateColors[0][1], stateColors[0][2])
			
			if(isHMM)
				// ===== HMM: S1 =====
				
				// S1
				for(s = 1; s <= maxState; s += 1)
					String histName = "StepHist_dt" + num2str(deltaT) + "_S" + num2str(s) + waveSuffix
					String xName = "StepHist_x_dt" + num2str(deltaT) + "_S" + num2str(s) + waveSuffix
					Wave/Z HistWave = $histName
					Wave/Z XWave = $xName
					if(WaveExists(HistWave) && WaveExists(XWave))
						AppendToGraph HistWave vs XWave
						ModifyGraph mode($histName)=3, marker($histName)=19, msize($histName)=3
						ModifyGraph rgb($histName)=(stateColors[s][0], stateColors[s][1], stateColors[s][2])
					endif
				endfor
				
				// S1
				for(s = 1; s <= maxState; s += 1)
					String fitName = "fit_StepHist_dt" + num2str(deltaT) + "_S" + num2str(s) + waveSuffix
					String fitXName = "fit_StepX_dt" + num2str(deltaT) + "_S" + num2str(s) + waveSuffix
					Wave/Z FitWave = $fitName
					Wave/Z FitXWave = $fitXName
					if(WaveExists(FitWave) && WaveExists(FitXWave))
						AppendToGraph FitWave vs FitXWave
						ModifyGraph mode($fitName)=0, lsize($fitName)=2
						ModifyGraph rgb($fitName)=(stateColors[s][0], stateColors[s][1], stateColors[s][2])
					endif
				endfor
			else
				// ===== HMM: S0 =====
				
				// S0
				String fitName0 = "fit_StepHist_dt" + num2str(deltaT) + "_S0" + waveSuffix
				String fitXName0 = "fit_StepX_dt" + num2str(deltaT) + "_S0" + waveSuffix
				Wave/Z fit_StepHist = $fitName0
				Wave/Z fit_StepX = $fitXName0
				if(WaveExists(fit_StepHist) && WaveExists(fit_StepX))
					AppendToGraph fit_StepHist vs fit_StepX
					ModifyGraph mode($fitName0)=0, lsize($fitName0)=2
					ModifyGraph rgb($fitName0)=(0, 0, 0)
					
					// 
					for(i = 0; i < numFitStates; i += 1)
						String compName = "comp" + num2str(i+1) + "_Step_dt" + num2str(deltaT) + "_S0" + waveSuffix
						Wave/Z CompWave = $compName
						if(WaveExists(CompWave))
							AppendToGraph CompWave vs fit_StepX
							ModifyGraph mode($compName)=0, lsize($compName)=1, lstyle($compName)=11
							Variable colorIdx = mod(i, 5) + 1
							ModifyGraph rgb($compName)=(stateColors[colorIdx][0], stateColors[colorIdx][1], stateColors[colorIdx][2])
						endif
					endfor
				endif
			endif
			
			// 
			ModifyGraph tick=0, mirror=0, fStyle=1, fSize=14, font="Arial"
			ModifyGraph lowTrip(left)=0.0001
			SetAxis left 0, *
			SetAxis bottom 0, *
			Label left "Probability Density"
			Label bottom "Step size (µm)"
			ModifyGraph width={Aspect,1.618}
			
			// 
			String stateName = GetDstateName(0, maxState)
			String legendStr = "\\F'Arial'\\Z12\\s(" + histName0 + ") " + stateName
			if(isHMM)
				for(s = 1; s <= maxState; s += 1)
					histName = "StepHist_dt" + num2str(deltaT) + "_S" + num2str(s) + waveSuffix
					Wave/Z HW = $histName
					if(WaveExists(HW))
						stateName = GetDstateName(s, maxState)
						legendStr += "\r\\s(" + histName + ") " + stateName
					endif
				endfor
			else
				Wave/Z fSH = $fitName0
				if(WaveExists(fSH))
					legendStr += "\r\\s(" + fitName0 + ") Fit"
					for(i = 0; i < numFitStates; i += 1)
						compName = "comp" + num2str(i+1) + "_Step_dt" + num2str(deltaT) + "_S0" + waveSuffix
						Wave/Z CW = $compName
						if(WaveExists(CW))
							legendStr += "\r\\s(" + compName + ") C" + num2str(i+1)
						endif
					endfor
				endif
			endif
			TextBox/C/N=text0/F=0/B=1/A=RT legendStr
		endfor
	endfor
	
	SetDataFolder root:
	return 0
End

// -----------------------------------------------------------------------------
// Step Size Distribution Fitting - HMM
// Δt
// f(r) = sum_i A_i * (r/sigma_i^2) * exp(-r^2/(2*sigma_i^2))
// sigma_i = sqrt(4*D_i*dt)  D_i 
// -----------------------------------------------------------------------------
Function FitStepSizeDistributionHMM(SampleName, numStates, [basePath, useDeltaTMin, useDeltaTMax, waveSuffix])
	String SampleName
	Variable numStates  //  (1-5)
	String basePath         // :  "root"
	Variable useDeltaTMin   // : ΔtMin
	Variable useDeltaTMax   // : ΔtMax
	String waveSuffix       // : wave"_C1E", "_C2E"
	
	NVAR framerate = root:framerate
	NVAR/Z Dstate = root:Dstate
	NVAR/Z cHMM = root:cHMM
	NVAR StepDeltaTMin = root:StepDeltaTMin
	NVAR StepDeltaTMax = root:StepDeltaTMax
	NVAR StepFitD1 = root:StepFitD1
	NVAR StepFitScale = root:StepFitScale

	//
	if(ParamIsDefault(basePath))
		basePath = "root"
	endif
	if(ParamIsDefault(waveSuffix))
		waveSuffix = ""
	endif

	// Δt
	Variable deltaTMin, deltaTMax
	if(ParamIsDefault(useDeltaTMin))
		deltaTMin = StepDeltaTMin
	else
		deltaTMin = useDeltaTMin
	endif
	if(ParamIsDefault(useDeltaTMax))
		deltaTMax = StepDeltaTMax
	else
		deltaTMax = useDeltaTMax
	endif
	
	// 
	Variable initD1 = StepFitD1
	Variable initScale = StepFitScale
	
	// HMM
	Variable isHMM = 0
	Variable maxState = 0
	if(NVAR_Exists(cHMM) && cHMM == 1 && NVAR_Exists(Dstate))
		isHMM = 1
		maxState = Dstate
	endif
	
	Variable numFolders = CountDataFoldersInPath(basePath, SampleName)
	Variable m, s, i, j, deltaT
	String FolderName
	Variable numDeltaT = deltaTMax - deltaTMin + 1
	Variable numCoefs = numStates * 2  // [A1,...,An, σ1,...,σn]
	
	Print "=== Fitting Step Size Distribution ==="
	Printf "BasePath: %s, Number of fit components: %d, Δt range: %d-%d frames, suffix=%s\r", basePath, numStates, deltaTMin, deltaTMax, waveSuffix
	Printf "Initial values: D1=%.4f um2/s, Scale=%.1f\r", initD1, initScale
	Printf "Processing %d folders...\r", numFolders
	
	// 
	Variable stateStart = 0, stateEnd = maxState
	if(isHMM)
		stateStart = 1  // HMMS1
	endif
	
	// 
	for(m = 0; m < numFolders; m += 1)
		FolderName = SampleName + num2str(m + 1)
		String folderFullPath = basePath + ":" + SampleName + ":" + FolderName
		
		if(!DataFolderExists(folderFullPath))
			break
		endif
		
		SetDataFolder $folderFullPath
		
		Printf "\n  Folder %s:\r", FolderName
		
		for(s = stateStart; s <= stateEnd; s += 1)
			// 2Coef wave: coef_Step_2D_Sn[Δt][coef_index]
			String coef2DName = "coef_Step_2D_S" + num2str(s) + waveSuffix
			Make/O/D/N=(numDeltaT, numCoefs + 2) $coef2DName = NaN  // +2 for deltaT and dt
			Wave Coef2D = $coef2DName
			SetDimLabel 1, 0, deltaT, Coef2D
			SetDimLabel 1, 1, dt_s, Coef2D
			for(i = 0; i < numStates; i += 1)
				SetDimLabel 1, 2+i, $("A" + num2str(i+1)), Coef2D
				SetDimLabel 1, 2+numStates+i, $("sigma" + num2str(i+1)), Coef2D
			endfor
			
			Printf "    S%d: ", s
			
			for(deltaT = deltaTMin; deltaT <= deltaTMax; deltaT += 1)
				Variable dt = deltaT * framerate  // Δt [s]
				Variable dtIdx = deltaT - deltaTMin
				
				// 
				String histName = "StepHist_dt" + num2str(deltaT) + "_S" + num2str(s) + waveSuffix
				String xName = "StepHist_x_dt" + num2str(deltaT) + "_S" + num2str(s) + waveSuffix
				
				Wave/Z StepHist = $histName
				Wave/Z StepX = $xName
				
				if(!WaveExists(StepHist) || !WaveExists(StepX))
					continue
				endif
				
				// 
				String fitFunc = "DisplacementDist" + num2str(numStates)
				
				// Wave 
				Make/O/D/N=(numCoefs) coef_Step
				
				// : An = 1/numStates, Dn+1 = Dn * scale
				for(i = 0; i < numStates; i += 1)
					coef_Step[i] = 1.0 / numStates  // A
					Variable Di = initD1 * (initScale ^ i)
					coef_Step[numStates + i] = sqrt(4 * Di * dt)  // sigma = sqrt(4*D*dt)
				endfor
				
				// 
				Variable V_FitError = 0
				try
					AbortOnRTE
					FuncFit/Q/N/W=2 $fitFunc, coef_Step, StepHist /X=StepX; AbortOnRTE
				catch
					Variable err = GetRTError(1)
					V_FitError = 1
					Printf "[Δt=%d fail] ", deltaT
					continue
				endtry
				
				// 2wave
				Coef2D[dtIdx][0] = deltaT
				Coef2D[dtIdx][1] = dt
				for(i = 0; i < numCoefs; i += 1)
					Coef2D[dtIdx][2+i] = coef_Step[i]
				endfor
				
				// ΔtALL
				Variable createComp = (!isHMM && s == 0) ? 1 : 0
				CreateStepFitCurveForDt(s, deltaT, coef_Step, StepX, numStates, dt, createComp, waveSuffix=waveSuffix)
				
				// 
				Printf "Δt%d:", deltaT
				for(i = 0; i < numStates; i += 1)
					Variable sigmai = coef_Step[numStates + i]
					Di = sigmai^2 / (4 * dt)
					Printf "D%d=%.3f ", i+1, Di
				endfor
			endfor
			Printf "\r"
		endfor
		
		ShowProgress(m+1, numFolders, "Step Fit")
	endfor
	
	EndProgress()
	KillWaves/Z coef_Step
	SetDataFolder root:
	Print "\nStep size fitting complete"
	return 0
End

// Δt
static Function CreateStepFitCurveForDt(stateNum, deltaT, coefWave, xWave, numStates, dt, createComponents, [waveSuffix])
	Variable stateNum, deltaT
	Wave coefWave, xWave
	Variable numStates, dt, createComponents
	String waveSuffix  // : wave
	
	if(ParamIsDefault(waveSuffix))
		waveSuffix = ""
	endif
	
	Variable numDataPts = numpnts(xWave)
	Variable numFitPts = (numDataPts - 1) * 10 + 1
	Variable xMax = xWave[numDataPts - 1]
	Variable xMin = xWave[0]
	Variable dx_fit = (xMax - xMin) / (numFitPts - 1)
	
	String fitWaveName = "fit_StepHist_dt" + num2str(deltaT) + "_S" + num2str(stateNum) + waveSuffix
	String fitXName = "fit_StepX_dt" + num2str(deltaT) + "_S" + num2str(stateNum) + waveSuffix
	Make/O/N=(numFitPts) $fitWaveName = 0, $fitXName = 0
	Wave FitWave = $fitWaveName
	Wave FitX = $fitXName
	
	Variable i, j
	for(j = 0; j < numFitPts; j += 1)
		Variable r = xMin + j * dx_fit
		FitX[j] = r
		Variable val = 0
		for(i = 0; i < numStates; i += 1)
			Variable A = coefWave[i]
			Variable sigma = coefWave[numStates + i]
			val += A * (r / sigma^2) * exp(-r^2 / (2 * sigma^2))
		endfor
		FitWave[j] = val
	endfor
	
	// HMM
	if(createComponents && numStates > 1)
		for(i = 0; i < numStates; i += 1)
			String compName = "comp" + num2str(i+1) + "_Step_dt" + num2str(deltaT) + "_S" + num2str(stateNum) + waveSuffix
			Make/O/N=(numFitPts) $compName = 0
			Wave CompWave = $compName
			
			Variable Ai = coefWave[i]
			Variable sigmai = coefWave[numStates + i]
			
			for(j = 0; j < numFitPts; j += 1)
				r = FitX[j]
				CompWave[j] = Ai * (r / sigmai^2) * exp(-r^2 / (2 * sigmai^2))
			endfor
		endfor
	endif
End

// 
static Function PrintStepFitResults(stateNum, coefWave, numStates, dt)
	Variable stateNum
	Wave coefWave
	Variable numStates, dt
	
	Printf "  S%d: Fit results\r", stateNum
	
	// 
	Variable Asum = 0
	Variable i
	for(i = 0; i < numStates; i += 1)
		Asum += coefWave[i]
	endfor
	
	for(i = 0; i < numStates; i += 1)
		Variable Ai = coefWave[i]
		Variable sigmai = coefWave[numStates + i]
		Variable Di = sigmai^2 / (4 * dt)
		Variable fracti = Ai / Asum * 100
		Printf "    Component %d: A=%.3f (%.1f%%), sigma=%.4f um, D=%.4f um²/s\r", i+1, Ai, fracti, sigmai, Di
	endfor
End

// -----------------------------------------------------------------------------
// Step Size Distribution Fitting with AIC selection (Non-HMM)
// S0minmaxAIC
// FitStepSizeDistributionHMM
// -----------------------------------------------------------------------------
Function FitStepSizeWithAIC_NonHMM(SampleName, minStates, maxStates)
	String SampleName
	Variable minStates, maxStates
	
	// 
	if(minStates < 1)
		minStates = 1
	endif
	if(maxStates > 5)
		maxStates = 5
	endif
	if(minStates > maxStates)
		Variable temp = minStates
		minStates = maxStates
		maxStates = temp
	endif
	
	NVAR framerate = root:framerate
	NVAR StepDeltaTMin = root:StepDeltaTMin
	NVAR StepDeltaTMax = root:StepDeltaTMax
	NVAR StepFitD1 = root:StepFitD1
	NVAR StepFitScale = root:StepFitScale

	// Δt
	Variable deltaTMin = StepDeltaTMin
	Variable deltaTMax = StepDeltaTMax
	
	// 
	Variable initD1 = StepFitD1
	Variable initScale = StepFitScale
	
	Variable numFolders = CountDataFolders(SampleName)
	Variable m, n, i, j, deltaT
	String FolderName
	Variable numDeltaT = deltaTMax - deltaTMin + 1
	Variable numRange = maxStates - minStates + 1
	
	// 
	Variable nIdx, numCoefs, totalRSS, totalN, successCount
	Variable dt, Di, V_FitError, err, rss, validPts, r, fitVal
	Variable Ai, sigmai, numparams, AIC_val
	Variable bestN, bestAIC
	
	Print "=== Step Size Fitting with AIC Selection (Non-HMM) ==="
	Printf "Sample: %s, Model range: %d-%d states, Δt range: %d-%d frames\r", SampleName, minStates, maxStates, deltaTMin, deltaTMax
	Printf "Initial values: D1=%.4f um2/s, Scale=%.1f\r", initD1, initScale
	
	// min = max
	if(minStates == maxStates)
		Printf "Single model: fitting with %d states\r", minStates
		FitStepSizeNonHMM_SingleModel(SampleName, minStates, deltaTMin, deltaTMax, initD1, initScale)
		return 0
	endif
	
	// 
	for(m = 0; m < numFolders; m += 1)
		FolderName = SampleName + num2str(m + 1)
		SetDataFolder root:$(SampleName):$(FolderName)
		
		Printf "\n  === %s ===\r", FolderName
		
		// AIC
		Make/O/D/N=(numRange) AIC_Step_S0 = NaN
		Make/O/D/N=(numRange) RSS_Step_S0 = NaN
		
		bestN = minStates
		bestAIC = Inf
		
		// AIC
		for(n = minStates; n <= maxStates; n += 1)
			nIdx = n - minStates
			numCoefs = n * 2
			
			// ΔtRSS
			totalRSS = 0
			totalN = 0
			successCount = 0
			
			for(deltaT = deltaTMin; deltaT <= deltaTMax; deltaT += 1)
				String histName = "StepHist_dt" + num2str(deltaT) + "_S0"
				String xName = "StepHist_x_dt" + num2str(deltaT) + "_S0"
				
				Wave/Z StepHist = $histName
				Wave/Z StepX = $xName
				
				if(!WaveExists(StepHist) || !WaveExists(StepX))
					continue
				endif
				
				dt = deltaT * framerate  // Δt [sec]
				
				// WaveFuncFitwave
				Make/O/D/N=(numCoefs) coef_temp_AIC
				Wave coef_temp = coef_temp_AIC
				for(i = 0; i < n; i += 1)
					coef_temp[i] = 1.0 / n
					Di = initD1 * (initScale ^ i)
					coef_temp[n + i] = sqrt(4 * Di * dt)
				endfor
				
				// 
				String fitFunc = "DisplacementDist" + num2str(n)
				V_FitError = 0
				try
					AbortOnRTE
					FuncFit/Q/N/W=2 $fitFunc, coef_temp, StepHist /X=StepX; AbortOnRTE
				catch
					err = GetRTError(1)
					V_FitError = 1
					continue
				endtry
				
				if(V_FitError != 0)
					continue
				endif
				
				// RSS
				rss = 0
				validPts = 0
				for(j = 0; j < numpnts(StepHist); j += 1)
					if(numtype(StepHist[j]) != 0)
						continue
					endif
					r = StepX[j]
					fitVal = 0
					for(i = 0; i < n; i += 1)
						Ai = coef_temp[i]
						sigmai = coef_temp[n + i]
						if(sigmai > 0)
							fitVal += Ai * (r / (sigmai^2)) * exp(-(r^2) / (2 * sigmai^2))
						endif
					endfor
					rss += (StepHist[j] - fitVal)^2
					validPts += 1
				endfor
				
				totalRSS += rss
				totalN += validPts
				successCount += 1
			endfor
			
			if(totalN == 0 || successCount == 0)
				Printf "    n=%d: Fit failed for all Δt\r", n
				continue
			endif
			
			// ΔtAIC
			if(successCount < numDeltaT)
				Printf "    n=%d: RSS=%.4f (N=%d, %d/%d Δt) - SKIPPED (not all Δt succeeded)\r", n, totalRSS, totalN, successCount, numDeltaT
				continue
			endif
			
			RSS_Step_S0[nIdx] = totalRSS
			
			// AIC
			numparams = 2 * n
			AIC_val = totalN * ln(totalRSS / totalN) + 2 * numparams
			AIC_Step_S0[nIdx] = AIC_val
			
			Printf "    n=%d: RSS=%.4f, AIC=%.2f (N=%d, K=%d, %d/%d Δt)\r", n, totalRSS, AIC_val, totalN, numparams, successCount, numDeltaT
			
			if(AIC_val < bestAIC)
				bestAIC = AIC_val
				bestN = n
			endif
		endfor
		
		// Δt
		if(bestAIC == Inf)
			Printf "    WARNING: No model succeeded for all Δt. Using minStates=%d as fallback.\r", minStates
			bestN = minStates
		else
			Printf "    → Best model: n=%d (AIC=%.2f)\r", bestN, bestAIC
		endif
		
		// ΔtWave
		FitStepSizeNonHMM_FinalFit(FolderName, bestN, deltaTMin, deltaTMax, initD1, initScale)
		
		ShowProgress(m+1, numFolders, "Step AIC")
	endfor
	
	EndProgress()
	KillWaves/Z coef_temp_AIC
	SetDataFolder root:
	Print "\nStep size fitting with AIC selection complete"
End

// -----------------------------------------------------------------------------
// HMM: min=max
// -----------------------------------------------------------------------------
static Function FitStepSizeNonHMM_SingleModel(SampleName, numStates, deltaTMin, deltaTMax, initD1, initScale)
	String SampleName
	Variable numStates, deltaTMin, deltaTMax, initD1, initScale
	
	NVAR framerate = root:framerate
	Variable numFolders = CountDataFolders(SampleName)
	Variable m
	String FolderName
	
	for(m = 0; m < numFolders; m += 1)
		FolderName = SampleName + num2str(m + 1)
		SetDataFolder root:$(SampleName):$(FolderName)
		
		Printf "\n  %s:\r", FolderName
		FitStepSizeNonHMM_FinalFit(FolderName, numStates, deltaTMin, deltaTMax, initD1, initScale)
		
		ShowProgress(m+1, numFolders, "Step Fit")
	endfor
	
	EndProgress()
	SetDataFolder root:
End

// -----------------------------------------------------------------------------
// HMM: ΔtWave
// -----------------------------------------------------------------------------
static Function FitStepSizeNonHMM_FinalFit(FolderName, numStates, deltaTMin, deltaTMax, initD1, initScale)
	String FolderName
	Variable numStates, deltaTMin, deltaTMax, initD1, initScale
	
	NVAR framerate = root:framerate
	Variable numDeltaT = deltaTMax - deltaTMin + 1
	Variable numCoefs = numStates * 2
	Variable i, j, deltaT, dtIdx
	Variable dt, Di, V_FitError, err
	Variable dt1, Asum, Ai, sigmai, fracti
	
	// 2DWave: coef_Step_2D_S0
	Make/O/D/N=(numDeltaT, numCoefs + 2) coef_Step_2D_S0 = NaN
	Wave Coef2D = coef_Step_2D_S0
	
	// 
	SetDimLabel 1, 0, deltaT, Coef2D
	SetDimLabel 1, 1, dt_s, Coef2D
	for(i = 0; i < numStates; i += 1)
		SetDimLabel 1, 2+i, $("A" + num2str(i+1)), Coef2D
		SetDimLabel 1, 2+numStates+i, $("sigma" + num2str(i+1)), Coef2D
	endfor
	
	// Δt
	for(deltaT = deltaTMin; deltaT <= deltaTMax; deltaT += 1)
		dtIdx = deltaT - deltaTMin
		
		String histName = "StepHist_dt" + num2str(deltaT) + "_S0"
		String xName = "StepHist_x_dt" + num2str(deltaT) + "_S0"
		
		Wave/Z StepHist = $histName
		Wave/Z StepX = $xName
		
		if(!WaveExists(StepHist) || !WaveExists(StepX))
			Printf "    Δt=%d: Histogram not found\r", deltaT
			continue
		endif
		
		dt = deltaT * framerate  // Δt [sec]
		
		// Wave
		Make/O/D/N=(numCoefs) coef_Step_temp
		for(i = 0; i < numStates; i += 1)
			coef_Step_temp[i] = 1.0 / numStates
			Di = initD1 * (initScale ^ i)
			coef_Step_temp[numStates + i] = sqrt(4 * Di * dt)
		endfor
		
		// 
		String fitFunc = "DisplacementDist" + num2str(numStates)
		V_FitError = 0
		try
			AbortOnRTE
			FuncFit/Q/N/W=2 $fitFunc, coef_Step_temp, StepHist /X=StepX; AbortOnRTE
		catch
			err = GetRTError(1)
			V_FitError = 1
			Printf "    Δt=%d: Fit error\r", deltaT
			continue
		endtry
		
		if(V_FitError != 0)
			Printf "    Δt=%d: Fit failed\r", deltaT
			continue
		endif
		
		// 2D wave
		Coef2D[dtIdx][0] = deltaT
		Coef2D[dtIdx][1] = dt
		for(i = 0; i < numStates; i += 1)
			Coef2D[dtIdx][2+i] = coef_Step_temp[i]
			Coef2D[dtIdx][2+numStates+i] = coef_Step_temp[numStates+i]
		endfor
		
		// 
		CreateStepFitCurveForDt(0, deltaT, coef_Step_temp, StepX, numStates, dt, 1)
	endfor
	
	KillWaves/Z coef_Step_temp
	
	// Δt=deltaTMin
	if(numtype(Coef2D[0][2]) == 0)
		dt1 = Coef2D[0][1]
		Printf "    Fit results (n=%d) at Δt=%d:\r", numStates, deltaTMin
		Asum = 0
		for(i = 0; i < numStates; i += 1)
			Asum += Coef2D[0][2+i]
		endfor
		for(i = 0; i < numStates; i += 1)
			Ai = Coef2D[0][2+i]
			sigmai = Coef2D[0][2+numStates+i]
			Di = sigmai^2 / (4 * dt1)
			fracti = Ai / Asum * 100
			Printf "      C%d: A=%.3f (%.1f%%), D=%.4f um²/s\r", i+1, Ai, fracti, Di
		endfor
	endif
End

// -----------------------------------------------------------------------------
// Step Size Heatmap - Step sizeΔt
// X: ΔtY: Step Size
// HMM: Dstate
// HMM: S0
// -----------------------------------------------------------------------------
Function CreateMSDHeatmap(SampleName)
	String SampleName
	
	NVAR/Z Dstate = root:Dstate
	NVAR/Z cHMM = root:cHMM
	NVAR StepDeltaTMin = root:StepDeltaTMin
	NVAR StepDeltaTMax = root:StepDeltaTMax
	NVAR StepHistBin = root:StepHistBin
	NVAR StepHistDim = root:StepHistDim
	NVAR/Z HeatmapMin = root:HeatmapMin
	NVAR/Z HeatmapMax = root:HeatmapMax

	// SVAR
	SVAR Color0 = root:Color0
	SVAR Color1 = root:Color1
	SVAR Color2 = root:Color2
	SVAR Color3 = root:Color3
	SVAR Color4 = root:Color4
	SVAR Color5 = root:Color5

	// Δt
	Variable deltaTMin = StepDeltaTMin
	Variable deltaTMax = StepDeltaTMax

	//
	Variable stepBin = StepHistBin
	Variable stepDim = StepHistDim
	
	// 
	Variable Imin = 0, Imax = 0
	if(NVAR_Exists(HeatmapMin))
		Imin = HeatmapMin
	endif
	if(NVAR_Exists(HeatmapMax))
		Imax = HeatmapMax
	endif
	
	// HMM
	Variable isHMM = 0
	Variable maxState = 0
	if(NVAR_Exists(cHMM) && cHMM == 1 && NVAR_Exists(Dstate))
		isHMM = 1
		maxState = Dstate
	endif
	
	Variable numFolders = CountDataFolders(SampleName)
	Variable m, s, deltaT, j, i
	String FolderName
	Variable numDeltaT = deltaTMax - deltaTMin + 1
	
	Print "=== Creating Step Size Heatmap ===" 
	Printf "Δt range: %d-%d, Step bin: %.4f um, Dim: %d\r", deltaTMin, deltaTMax, stepBin, stepDim
	if(isHMM)
		Printf "HMM mode: displaying S0-S%d\r", maxState
	else
		Print "Non-HMM mode: displaying S0 + fit components (from coef_Step_2D_S0)"
	endif
	
	// 
	for(m = 0; m < numFolders; m += 1)
		FolderName = SampleName + num2str(m + 1)
		SetDataFolder root:$(SampleName):$(FolderName)
		
		// HMM: S0SnHMM: S0
		Variable stateStart = 0, stateEnd = maxState
		
		for(s = stateStart; s <= stateEnd; s += 1)
			// 2D wave: rows = Δt, cols = Step size bins
			// X: Δt, Y: Step Size
			String heatmapName = "StepHeatmap_S" + num2str(s)
			Make/O/D/N=(numDeltaT, stepDim) $heatmapName = 0
			Wave Heatmap = $heatmapName
			
			// 
			SetScale/P x, deltaTMin, 1, "", Heatmap
			SetScale/P y, stepBin/2, stepBin, "", Heatmap
			
			Variable maxVal = 0
			Variable hasData = 0
			
			for(deltaT = deltaTMin; deltaT <= deltaTMax; deltaT += 1)
				Variable dtIdx = deltaT - deltaTMin
				
				// 
				String histName = "StepHist_dt" + num2str(deltaT) + "_S" + num2str(s)
				Wave/Z StepHist = $histName
				
				if(!WaveExists(StepHist))
					continue
				endif
				
				hasData = 1
				
				// 2D wave
				for(j = 0; j < min(stepDim, numpnts(StepHist)); j += 1)
					Heatmap[dtIdx][j] = StepHist[j]
					if(StepHist[j] > maxVal)
						maxVal = StepHist[j]
					endif
				endfor
			endfor
			
			if(hasData == 0)
				Printf "  %s S%d: No histogram data\r", FolderName, s
				continue
			endif
			
			// Imax=0
			Variable useMax = Imax
			if(useMax <= 0)
				useMax = maxVal
			endif
			
			// 
			String winName = "StepHeatmap_S" + num2str(s) + "_" + FolderName
			DoWindow/K $winName
			
			Display/K=1/N=$winName
			AppendImage Heatmap
			
			// SVAR
			if(s == 0)
				ModifyImage $heatmapName ctab={Imin, useMax, $Color0, 0}
			elseif(s == 1)
				ModifyImage $heatmapName ctab={Imin, useMax, $Color1, 0}
			elseif(s == 2)
				ModifyImage $heatmapName ctab={Imin, useMax, $Color2, 0}
			elseif(s == 3)
				ModifyImage $heatmapName ctab={Imin, useMax, $Color3, 0}
			elseif(s == 4)
				ModifyImage $heatmapName ctab={Imin, useMax, $Color4, 0}
			elseif(s == 5)
				ModifyImage $heatmapName ctab={Imin, useMax, $Color5, 0}
			endif
			
			// 
			ModifyGraph tick=0, mirror=0, fStyle=1, fSize=14, font="Arial"
			Label left "Step size (µm)"
			Label bottom "Δt (frames)"
			
			// 
			ModifyGraph width=250, height=200
			ModifyGraph margin(right)=80
			
			// 
			// /E=2: , /A=RC: , /X=5: 5%
			ColorScale/C/N=colorbar/F=0/E=2/A=RC/X=5 image=$heatmapName
			ColorScale/C/N=colorbar font="Arial", fsize=12, "Prob. Density"
			
			String graphTitle = FolderName + " Step Heatmap S" + num2str(s)
			DoWindow/T kwTopWin, graphTitle
		endfor
		
		// ===== HMM:  =====
		if(isHMM == 0)
			// Wave
			Wave/Z Coef2D = coef_Step_2D_S0
			if(!WaveExists(Coef2D))
				Printf "  %s: No fit coefficients found\r", FolderName
			else
				Variable nRows = DimSize(Coef2D, 0)
				Variable nCols = DimSize(Coef2D, 1)
				Variable nStates = (nCols - 2) / 2  // A1...An, sigma1...sigman
				
				// 
				for(i = 0; i < nStates; i += 1)
					String compHeatmapName = "StepHeatmap_C" + num2str(i + 1)
					Make/O/D/N=(numDeltaT, stepDim) $compHeatmapName = 0
					Wave CompHeatmap = $compHeatmapName
					
					SetScale/P x, deltaTMin, 1, "", CompHeatmap
					SetScale/P y, stepBin/2, stepBin, "", CompHeatmap
					
					Variable compMaxVal = 0
					Variable compHasData = 0
					
					for(deltaT = deltaTMin; deltaT <= deltaTMax; deltaT += 1)
						dtIdx = deltaT - deltaTMin
						
						// Δt
						Variable row = -1
						Variable k
						for(k = 0; k < nRows; k += 1)
							if(Coef2D[k][0] == deltaT)
								row = k
								break
							endif
						endfor
						
						if(row < 0)
							continue
						endif
						
						// 
						Variable Ai = Coef2D[row][2 + i]
						Variable sigmai = Coef2D[row][2 + nStates + i]
						
						if(numtype(Ai) != 0 || numtype(sigmai) != 0 || Ai <= 0 || sigmai <= 0)
							continue
						endif
						
						compHasData = 1
						
						// Rayleigh
						for(j = 0; j < stepDim; j += 1)
							Variable r = stepBin * (j + 0.5)
							Variable prob = Ai * (r / (sigmai^2)) * exp(-(r^2) / (2 * sigmai^2))
							CompHeatmap[dtIdx][j] = prob
							if(prob > compMaxVal)
								compMaxVal = prob
							endif
						endfor
					endfor
					
					if(compHasData == 0)
						Printf "  %s C%d: No fit data\r", FolderName, i+1
						continue
					endif
					
					useMax = Imax
					if(useMax <= 0)
						useMax = compMaxVal
					endif
					
					// 
					winName = "StepHeatmap_C" + num2str(i + 1) + "_" + FolderName
					DoWindow/K $winName
					
					Display/K=1/N=$winName
					AppendImage CompHeatmap
					
					// +1
					Variable colorIdx = i + 1
					if(colorIdx == 1)
						ModifyImage $compHeatmapName ctab={Imin, useMax, $Color1, 0}
					elseif(colorIdx == 2)
						ModifyImage $compHeatmapName ctab={Imin, useMax, $Color2, 0}
					elseif(colorIdx == 3)
						ModifyImage $compHeatmapName ctab={Imin, useMax, $Color3, 0}
					elseif(colorIdx == 4)
						ModifyImage $compHeatmapName ctab={Imin, useMax, $Color4, 0}
					elseif(colorIdx == 5)
						ModifyImage $compHeatmapName ctab={Imin, useMax, $Color5, 0}
					else
						ModifyImage $compHeatmapName ctab={Imin, useMax, $Color1, 0}
					endif
					
					// 
					ModifyGraph tick=0, mirror=0, fStyle=1, fSize=14, font="Arial"
					Label left "Step size (µm)"
					Label bottom "Δt (frames)"
					
					// 
					ModifyGraph width=250, height=200
					ModifyGraph margin(right)=80
					
					// 
					ColorScale/C/N=colorbar/F=0/E=2/A=RC/X=5 image=$compHeatmapName
					ColorScale/C/N=colorbar font="Arial", fsize=12, "Prob. Density"
					
					graphTitle = FolderName + " Step Heatmap C" + num2str(i + 1)
					DoWindow/T kwTopWin, graphTitle
				endfor
			endif
		endif
		
		ShowProgress(m+1, numFolders, "Heatmap")
	endfor
	
	EndProgress()
	SetDataFolder root:
	Print "Step Size Heatmap creation complete"
End

// -----------------------------------------------------------------------------
// Origin-Aligned Trajectory
// -----------------------------------------------------------------------------
// (0,0)
// -----------------------------------------------------------------------------

// wave
Function CalculateBlockDifference(roiWave, dataWave, resultWaveName)
	Wave roiWave, dataWave
	String resultWaveName
	
	Variable nPoints = numpnts(roiWave)
	
	// wavewave
	Make/O/D/N=(nPoints) $resultWaveName
	Wave resultWave = $resultWaveName
	
	Variable i
	Variable baseValue = NaN
	
	for(i = 0; i < nPoints; i += 1)
		// ROI waveNaN
		if(numtype(roiWave[i]) == 2)
			// NaN: NaN
			resultWave[i] = NaN
			baseValue = NaN
		else
			// 
			if(numtype(baseValue) == 2)
				// : data
				baseValue = dataWave[i]
			endif
			// data -  
			resultWave[i] = dataWave[i] - baseValue
		endif
	endfor
End

// Origin-Aligned TrajectoryTrace_HMM
// MinStepsTotalSteps
Function CreateOriginAlignedTrajectory(SampleName, [basePath, waveSuffix])
	String SampleName
	String basePath, waveSuffix
	
	// 
	if(ParamIsDefault(basePath))
		basePath = "root"
	endif
	if(ParamIsDefault(waveSuffix))
		waveSuffix = ""
	endif
	
	NVAR Dstate = root:Dstate
	NVAR scale = root:scale
	NVAR PixNum = root:PixNum
	
	// 
	Variable minSteps = 10  // 
	Variable totalSteps = 1000  // 
	Variable axisRange = 2.0  // ±2μm
	Variable lThresh = 1.0  // L threshold
	ControlInfo/W=SMI_MainPanel tab1_sv_minsteps
	if(V_flag != 0)
		minSteps = V_Value
	endif
	ControlInfo/W=SMI_MainPanel tab1_sv_totalsteps
	if(V_flag != 0)
		totalSteps = V_Value
	endif
	ControlInfo/W=SMI_MainPanel tab1_sv_axisrange
	if(V_flag != 0)
		axisRange = V_Value
	endif
	// L thresholdKinetics
	ControlInfo/W=SMI_MainPanel tab4_sv_lthresh
	if(V_flag != 0)
		lThresh = V_Value
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
	
	// 
	Make/FREE/N=(6, 3) StateColorsRGB
	StateColorsRGB[0][0] = 32768;  StateColorsRGB[0][1] = 40704;  StateColorsRGB[0][2] = 65280  // S1: 
	StateColorsRGB[1][0] = 65280;  StateColorsRGB[1][1] = 65280;  StateColorsRGB[1][2] = 0      // S2: 
	StateColorsRGB[2][0] = 0;      StateColorsRGB[2][1] = 65280;  StateColorsRGB[2][2] = 0      // S3: 
	StateColorsRGB[3][0] = 65280;  StateColorsRGB[3][1] = 0;      StateColorsRGB[3][2] = 0      // S4: 
	StateColorsRGB[4][0] = 65280;  StateColorsRGB[4][1] = 40704;  StateColorsRGB[4][2] = 32768  // S5: 
	StateColorsRGB[5][0] = 65535;  StateColorsRGB[5][1] = 65535;  StateColorsRGB[5][2] = 65535  // : 
	
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
	
	Printf "Creating Origin-Aligned Trajectories for %s\r", SampleName
	Printf "  MinSteps=%d, TotalSteps=%d, AxisRange=±%.1f µm, L threshold=%.2f µm\r", minSteps, totalSteps, axisRange, lThresh
	
	for(m = 0; m < numFolders; m += 1)
		FolderName = SampleName + num2str(m + 1)
		String cellPath = samplePath + ":" + FolderName
		
		if(!DataFolderExists(cellPath))
			continue
		endif
		
		SetDataFolder $cellPath
		
		// 
		String winName = FolderName + "_AlignedTraj" + waveSuffix
		DoWindow/K $winName
		String graphTitle = GetGraphTitleWithSeg(FolderName + " Aligned Trajectory", waveSuffix)
		Display/K=1/N=$winName as graphTitle
		
		String Txtbox = ""
		Variable firstTrace = 1
		String firstTraceName = ""
		
		// S1Dstate
		for(s = 1; s <= Dstate; s += 1)
			String roiName = "ROI_S" + num2str(s) + waveSuffix
			String xName = "Xum_S" + num2str(s) + waveSuffix
			String yName = "Yum_S" + num2str(s) + waveSuffix
			
			Wave/Z roiWave = $roiName
			Wave/Z xWave = $xName
			Wave/Z yWave = $yName
			
			if(!WaveExists(roiWave) || !WaveExists(xWave) || !WaveExists(yWave))
				continue
			endif
			
			// aligned wave
			String xAlignedName = xName + "_aligned"
			String yAlignedName = yName + "_aligned"
			
			Variable nExtracted = ExtractAlignedTrajectories(roiWave, xWave, yWave, xAlignedName, yAlignedName, minSteps, totalSteps)
			
			if(nExtracted == 0)
				continue
			endif
			
			Wave xAligned = $xAlignedName
			Wave yAligned = $yAlignedName
			
			// 
			AppendToGraph/W=$winName yAligned vs xAligned
			String traceName = yAlignedName
			
			// 
			Variable colorIdx = s - 1
			if(colorIdx > 5)
				colorIdx = 5
			endif
			Variable rr = StateColorsRGB[colorIdx][0]
			Variable gg = StateColorsRGB[colorIdx][1]
			Variable bb = StateColorsRGB[colorIdx][2]
			
			ModifyGraph/W=$winName rgb($traceName)=(rr, gg, bb)
			ModifyGraph/W=$winName lsize($traceName)=0.25  // 0.25
			
			// 
			String stateLabel = StateNames[nameIdx][s-1]
			Txtbox += "\\F'Arial'\\Z16\r\\K(" + num2str(rr) + "," + num2str(gg) + "," + num2str(bb) + ")" + stateLabel
			
			// 
			if(firstTrace)
				firstTraceName = traceName
				firstTrace = 0
			endif
			
			// LL <= lThresh 
			String coefName = "coef_MSD_S" + num2str(s) + waveSuffix
			Wave/Z coefWave = $coefName
			if(WaveExists(coefWave) && numpnts(coefWave) >= 2)
				Variable Lval = coefWave[1]  // index 1 = L
				if(numtype(Lval) == 0 && Lval > 0 && Lval <= lThresh)
					// wave
					String circleXName = "LCircle_X_S" + num2str(s) + waveSuffix
					String circleYName = "LCircle_Y_S" + num2str(s) + waveSuffix
					Variable nCirclePts = 101
					Make/O/N=(nCirclePts) $circleXName, $circleYName
					Wave circleX = $circleXName
					Wave circleY = $circleYName
					
					Variable radius = Lval / 2  // LL/2
					Variable angle
					Variable pt
					for(pt = 0; pt < nCirclePts; pt += 1)
						angle = pt * 2 * Pi / (nCirclePts - 1)
						circleX[pt] = radius * cos(angle)
						circleY[pt] = radius * sin(angle)
					endfor
					
					// 
					AppendToGraph/W=$winName circleY vs circleX
					String circleTraceName = circleYName
					ModifyGraph/W=$winName rgb($circleTraceName)=(rr, gg, bb)
					ModifyGraph/W=$winName lsize($circleTraceName)=2  // 2
				endif
			endif
		endfor
		
		// ReorderTracesS1
		if(strlen(firstTraceName) > 0)
			String reorderList = ""
			for(s = Dstate; s >= 2; s -= 1)
				String yAlignName = "Yum_S" + num2str(s) + waveSuffix + "_aligned"
				Wave/Z testWave = $yAlignName
				if(WaveExists(testWave))
					// 
					String traceListStr = TraceNameList(winName, ";", 1)
					if(WhichListItem(yAlignName, traceListStr) >= 0)
						if(strlen(reorderList) > 0)
							reorderList += ", "
						endif
						reorderList += yAlignName
					endif
				endif
			endfor
			if(strlen(reorderList) > 0)
				Execute "ReorderTraces/W=" + winName + " " + firstTraceName + ", {" + reorderList + "}"
			endif
		endif
		
		// 
		if(strlen(Txtbox) > 0)
			TextBox/W=$winName/C/N=text0/F=0/B=1/A=RB Txtbox
		endif
		
		// 
		if(firstTrace)
			// 
			DoWindow/K $winName
			Printf "  %s: No valid trajectories found\r", FolderName
			continue
		endif
		
		// 
		ModifyGraph/W=$winName width={Aspect,1}, height={Aspect,1}
		ModifyGraph/W=$winName tick=2, mirror=1, fStyle=1, fSize=12, font="Arial"
		Label/W=$winName bottom "X (µm)"
		Label/W=$winName left "Y (µm)"
		SetAxis/W=$winName bottom -axisRange, axisRange
		SetAxis/W=$winName left -axisRange, axisRange
		ModifyGraph/W=$winName gbRGB=(0,0,0)
		ModifyGraph/W=$winName axRGB(bottom)=(65535,65535,65535)
		ModifyGraph/W=$winName axRGB(left)=(65535,65535,65535)
		ModifyGraph/W=$winName tlblRGB(bottom)=(65535,65535,65535)
		ModifyGraph/W=$winName tlblRGB(left)=(65535,65535,65535)
		ModifyGraph/W=$winName alblRGB(bottom)=(65535,65535,65535)
		ModifyGraph/W=$winName alblRGB(left)=(65535,65535,65535)
		ModifyGraph/W=$winName tickRGB(bottom)=(65535,65535,65535)
		ModifyGraph/W=$winName tickRGB(left)=(65535,65535,65535)
	endfor
	
	SetDataFolder root:
	Print "Origin-Aligned Trajectory creation complete"
	return 0
End

// aligned wave
// MinStepsTotalSteps
Function ExtractAlignedTrajectories(roiWave, xWave, yWave, xResultName, yResultName, minSteps, totalSteps)
	Wave roiWave, xWave, yWave
	String xResultName, yResultName
	Variable minSteps, totalSteps
	
	Variable nPoints = numpnts(roiWave)
	Variable i, j
	
	// 
	Make/FREE/N=0 trajStart, trajLen
	Variable inTraj = 0
	Variable trajStartIdx = 0
	Variable currentLen = 0
	
	for(i = 0; i < nPoints; i += 1)
		if(numtype(roiWave[i]) == 2)  // NaN = 
			if(inTraj && currentLen >= minSteps)
				// 
				Variable nTraj = numpnts(trajStart)
				Redimension/N=(nTraj+1) trajStart, trajLen
				trajStart[nTraj] = trajStartIdx
				trajLen[nTraj] = currentLen
			endif
			inTraj = 0
			currentLen = 0
		else
			if(!inTraj)
				// 
				trajStartIdx = i
				inTraj = 1
			endif
			currentLen += 1
		endif
	endfor
	// 
	if(inTraj && currentLen >= minSteps)
		Variable nTrajFinal = numpnts(trajStart)
		Redimension/N=(nTrajFinal+1) trajStart, trajLen
		trajStart[nTrajFinal] = trajStartIdx
		trajLen[nTrajFinal] = currentLen
	endif
	
	Variable numValidTraj = numpnts(trajStart)
	if(numValidTraj == 0)
		Make/O/D/N=0 $xResultName, $yResultName
		return 0
	endif
	
	// TotalSteps
	Variable extractedSteps = 0
	Variable trajToExtract = 0
	
	for(i = 0; i < numValidTraj; i += 1)
		Variable stepsToAdd = min(trajLen[i], minSteps)  // MinSteps
		if(extractedSteps + stepsToAdd > totalSteps && trajToExtract > 0)
			break  // 1TotalSteps
		endif
		extractedSteps += stepsToAdd
		trajToExtract += 1
		if(extractedSteps >= totalSteps)
			break
		endif
	endfor
	
	// waveNaN
	Variable resultSize = extractedSteps + (trajToExtract - 1)  // NaN
	if(resultSize <= 0)
		Make/O/D/N=0 $xResultName, $yResultName
		return 0
	endif
	
	Make/O/D/N=(resultSize) $xResultName, $yResultName
	Wave xResult = $xResultName
	Wave yResult = $yResultName
	xResult = NaN
	yResult = NaN
	
	Variable outIdx = 0
	for(i = 0; i < trajToExtract; i += 1)
		Variable startIdx = trajStart[i]
		Variable baseX = xWave[startIdx]
		Variable baseY = yWave[startIdx]
		Variable stepsFromThis = min(trajLen[i], minSteps)
		
		// 0
		for(j = 0; j < stepsFromThis; j += 1)
			xResult[outIdx] = xWave[startIdx + j] - baseX
			yResult[outIdx] = yWave[startIdx + j] - baseY
			outIdx += 1
		endfor
		
		// NaN
		if(i < trajToExtract - 1)
			xResult[outIdx] = NaN
			yResult[outIdx] = NaN
			outIdx += 1
		endif
	endfor
	
	Printf "    Extracted %d trajectories (%d steps)\r", trajToExtract, extractedSteps
	return trajToExtract
End

// Average
Function ExtractLimitedTrajectories(roiWave, xWave, yWave, xResultName, yResultName, minSteps, maxTrajCount)
	Wave roiWave, xWave, yWave
	String xResultName, yResultName
	Variable minSteps, maxTrajCount
	
	Variable nPoints = numpnts(roiWave)
	Variable i, j
	
	// 
	Make/FREE/N=0 trajStart, trajLen
	Variable inTraj = 0
	Variable trajStartIdx = 0
	Variable currentLen = 0
	
	for(i = 0; i < nPoints; i += 1)
		if(numtype(roiWave[i]) == 2)
			if(inTraj && currentLen >= minSteps)
				Variable nTraj = numpnts(trajStart)
				Redimension/N=(nTraj+1) trajStart, trajLen
				trajStart[nTraj] = trajStartIdx
				trajLen[nTraj] = currentLen
			endif
			inTraj = 0
			currentLen = 0
		else
			if(!inTraj)
				trajStartIdx = i
				inTraj = 1
			endif
			currentLen += 1
		endif
	endfor
	if(inTraj && currentLen >= minSteps)
		Variable nTrajFinal = numpnts(trajStart)
		Redimension/N=(nTrajFinal+1) trajStart, trajLen
		trajStart[nTrajFinal] = trajStartIdx
		trajLen[nTrajFinal] = currentLen
	endif
	
	Variable numValidTraj = numpnts(trajStart)
	if(numValidTraj == 0)
		Make/O/D/N=0 $xResultName, $yResultName
		return 0
	endif
	
	// 
	Variable trajToExtract = min(numValidTraj, maxTrajCount)
	Variable extractedSteps = trajToExtract * minSteps
	
	// wave
	Variable resultSize = extractedSteps + (trajToExtract - 1)
	if(resultSize <= 0)
		Make/O/D/N=0 $xResultName, $yResultName
		return 0
	endif
	
	Make/O/D/N=(resultSize) $xResultName, $yResultName
	Wave xResult = $xResultName
	Wave yResult = $yResultName
	xResult = NaN
	yResult = NaN
	
	Variable outIdx = 0
	for(i = 0; i < trajToExtract; i += 1)
		Variable startIdx = trajStart[i]
		Variable baseX = xWave[startIdx]
		Variable baseY = yWave[startIdx]
		
		for(j = 0; j < minSteps; j += 1)
			xResult[outIdx] = xWave[startIdx + j] - baseX
			yResult[outIdx] = yWave[startIdx + j] - baseY
			outIdx += 1
		endfor
		
		if(i < trajToExtract - 1)
			xResult[outIdx] = NaN
			yResult[outIdx] = NaN
			outIdx += 1
		endif
	endfor
	
	return trajToExtract
End

// Average Origin-Aligned Trajectory
// 
Function CreateAverageAlignedTrajectory(SampleName)
	String SampleName
	
	NVAR Dstate = root:Dstate
	
	// 
	Variable minSteps = 10
	Variable totalSteps = 1000
	Variable axisRange = 2.0
	Variable lThresh = 1.0
	ControlInfo/W=SMI_MainPanel tab1_sv_minsteps
	if(V_flag != 0)
		minSteps = V_Value
	endif
	ControlInfo/W=SMI_MainPanel tab1_sv_totalsteps
	if(V_flag != 0)
		totalSteps = V_Value
	endif
	ControlInfo/W=SMI_MainPanel tab1_sv_axisrange
	if(V_flag != 0)
		axisRange = V_Value
	endif
	ControlInfo/W=SMI_MainPanel tab4_sv_lthresh
	if(V_flag != 0)
		lThresh = V_Value
	endif
	
	// 
	Variable numCells = CountDataFolders(SampleName)
	if(numCells == 0)
		Print "No cells found for: " + SampleName
		return -1
	endif
	
	// 
	Variable totalTraj = ceil(totalSteps / minSteps)
	Variable trajPerCell = ceil(totalTraj / numCells)
	
	Printf "Creating Average Aligned Trajectory for %s\r", SampleName
	Printf "  NumCells=%d, MinSteps=%d, TotalSteps=%d\r", numCells, minSteps, totalSteps
	Printf "  TrajPerCell=%d (total ~%d trajectories)\r", trajPerCell, trajPerCell * numCells
	
	// 
	Make/FREE/N=(6, 3) StateColorsRGB
	StateColorsRGB[0][0] = 32768;  StateColorsRGB[0][1] = 40704;  StateColorsRGB[0][2] = 65280
	StateColorsRGB[1][0] = 65280;  StateColorsRGB[1][1] = 65280;  StateColorsRGB[1][2] = 0
	StateColorsRGB[2][0] = 0;      StateColorsRGB[2][1] = 65280;  StateColorsRGB[2][2] = 0
	StateColorsRGB[3][0] = 65280;  StateColorsRGB[3][1] = 0;      StateColorsRGB[3][2] = 0
	StateColorsRGB[4][0] = 65280;  StateColorsRGB[4][1] = 40704;  StateColorsRGB[4][2] = 32768
	StateColorsRGB[5][0] = 65535;  StateColorsRGB[5][1] = 65535;  StateColorsRGB[5][2] = 65535
	
	// 
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
	
	// Results
	String resultsPath = "root:" + SampleName + ":Results"
	if(!DataFolderExists(resultsPath))
		NewDataFolder/O $resultsPath
	endif
	SetDataFolder $resultsPath
	
	// 
	String winName = SampleName + "_AvgAlignedTraj"
	DoWindow/K $winName
	Display/K=1/N=$winName as SampleName + " Average Aligned Trajectory"
	
	String Txtbox = ""
	Variable firstTrace = 1
	String firstTraceName = ""
	Variable m, s
	String FolderName
	
	// 
	for(s = 1; s <= Dstate; s += 1)
		// wave
		Make/O/D/N=0 tempX_all, tempY_all
		Variable totalExtracted = 0
		Variable sumL = 0
		Variable countL = 0
		
		// 
		for(m = 0; m < numCells; m += 1)
			FolderName = SampleName + num2str(m + 1)
			String cellPath = "root:" + SampleName + ":" + FolderName
			
			if(!DataFolderExists(cellPath))
				continue
			endif
			
			SetDataFolder $cellPath
			
			String roiName = "ROI_S" + num2str(s)
			String xName = "Xum_S" + num2str(s)
			String yName = "Yum_S" + num2str(s)
			
			Wave/Z roiWave = $roiName
			Wave/Z xWave = $xName
			Wave/Z yWave = $yName
			
			if(!WaveExists(roiWave) || !WaveExists(xWave) || !WaveExists(yWave))
				continue
			endif
			
			// 
			String tempXName = "tempX_cell"
			String tempYName = "tempY_cell"
			Variable nExtracted = ExtractLimitedTrajectories(roiWave, xWave, yWave, tempXName, tempYName, minSteps, trajPerCell)
			
			if(nExtracted > 0)
				Wave tempX = $tempXName
				Wave tempY = $tempYName
				
				// NaN
				Variable currentSize = numpnts(tempX_all)
				Variable addSize = numpnts(tempX)
				if(currentSize > 0)
					// NaN
					Redimension/N=(currentSize + 1 + addSize) tempX_all, tempY_all
					tempX_all[currentSize] = NaN
					tempY_all[currentSize] = NaN
					tempX_all[currentSize+1, currentSize+addSize] = tempX[p - currentSize - 1]
					tempY_all[currentSize+1, currentSize+addSize] = tempY[p - currentSize - 1]
				else
					Redimension/N=(addSize) tempX_all, tempY_all
					tempX_all = tempX[p]
					tempY_all = tempY[p]
				endif
				
				totalExtracted += nExtracted
				
				// L
				String coefName = "coef_MSD_S" + num2str(s)
				Wave/Z coefWave = $coefName
				if(WaveExists(coefWave) && numpnts(coefWave) >= 2)
					Variable cellL = coefWave[1]
					if(numtype(cellL) == 0 && cellL > 0)
						sumL += cellL
						countL += 1
					endif
				endif
				
				KillWaves/Z tempX, tempY
			endif
		endfor
		
		SetDataFolder $resultsPath
		
		if(numpnts(tempX_all) == 0)
			KillWaves/Z tempX_all, tempY_all
			continue
		endif
		
		// wave
		String xAlignedName = "AvgAligned_X_S" + num2str(s)
		String yAlignedName = "AvgAligned_Y_S" + num2str(s)
		Duplicate/O tempX_all, $xAlignedName
		Duplicate/O tempY_all, $yAlignedName
		KillWaves/Z tempX_all, tempY_all
		
		Wave xAligned = $xAlignedName
		Wave yAligned = $yAlignedName
		
		// 
		AppendToGraph/W=$winName yAligned vs xAligned
		String traceName = yAlignedName
		
		Variable colorIdx = s - 1
		if(colorIdx > 5)
			colorIdx = 5
		endif
		Variable rr = StateColorsRGB[colorIdx][0]
		Variable gg = StateColorsRGB[colorIdx][1]
		Variable bb = StateColorsRGB[colorIdx][2]
		
		ModifyGraph/W=$winName rgb($traceName)=(rr, gg, bb)
		ModifyGraph/W=$winName lsize($traceName)=0.25
		
		String stateLabel = StateNames[nameIdx][s-1]
		Txtbox += "\\F'Arial'\\Z16\r\\K(" + num2str(rr) + "," + num2str(gg) + "," + num2str(bb) + ")" + stateLabel
		
		if(firstTrace)
			firstTraceName = traceName
			firstTrace = 0
		endif
		
		// LLL <= lThresh 
		if(countL > 0)
			Variable avgL = sumL / countL
			if(avgL <= lThresh)
				String circleXName = "AvgLCircle_X_S" + num2str(s)
				String circleYName = "AvgLCircle_Y_S" + num2str(s)
				Variable nCirclePts = 101
				Make/O/N=(nCirclePts) $circleXName, $circleYName
				Wave circleX = $circleXName
				Wave circleY = $circleYName
				
				Variable radius = avgL / 2
				Variable angle, pt
				for(pt = 0; pt < nCirclePts; pt += 1)
					angle = pt * 2 * Pi / (nCirclePts - 1)
					circleX[pt] = radius * cos(angle)
					circleY[pt] = radius * sin(angle)
				endfor
				
				AppendToGraph/W=$winName circleY vs circleX
				String circleTraceName = circleYName
				ModifyGraph/W=$winName rgb($circleTraceName)=(rr, gg, bb)
				ModifyGraph/W=$winName lsize($circleTraceName)=2
				
				Printf "  S%d: Avg L = %.3f µm (%d cells)\r", s, avgL, countL
			endif
		endif
		
		Printf "  S%d (%s): %d trajectories from %d cells\r", s, stateLabel, totalExtracted, numCells
	endfor
	
	// ReorderTraces
	if(strlen(firstTraceName) > 0)
		String reorderList = ""
		for(s = Dstate; s >= 2; s -= 1)
			String yAlignName = "AvgAligned_Y_S" + num2str(s)
			Wave/Z testWave = $yAlignName
			if(WaveExists(testWave))
				// 
				String traceListStr = TraceNameList(winName, ";", 1)
				if(WhichListItem(yAlignName, traceListStr) >= 0)
					if(strlen(reorderList) > 0)
						reorderList += ", "
					endif
					reorderList += yAlignName
				endif
			endif
		endfor
		if(strlen(reorderList) > 0)
			Execute "ReorderTraces/W=" + winName + " " + firstTraceName + ", {" + reorderList + "}"
		endif
	endif
	
	// 
	if(strlen(Txtbox) > 0)
		TextBox/W=$winName/C/N=text0/F=0/B=1/A=RB Txtbox
	endif
	
	// 
	if(firstTrace)
		DoWindow/K $winName
		Print "No valid trajectories found for " + SampleName
		SetDataFolder root:
		return -1
	endif
	
	// 
	ModifyGraph/W=$winName width={Aspect,1}, height={Aspect,1}
	ModifyGraph/W=$winName tick=2, mirror=1, fStyle=1, fSize=12, font="Arial"
	Label/W=$winName bottom "X (µm)"
	Label/W=$winName left "Y (µm)"
	SetAxis/W=$winName bottom -axisRange, axisRange
	SetAxis/W=$winName left -axisRange, axisRange
	ModifyGraph/W=$winName gbRGB=(0,0,0)
	ModifyGraph/W=$winName axRGB(bottom)=(65535,65535,65535)
	ModifyGraph/W=$winName axRGB(left)=(65535,65535,65535)
	ModifyGraph/W=$winName tlblRGB(bottom)=(65535,65535,65535)
	ModifyGraph/W=$winName tlblRGB(left)=(65535,65535,65535)
	ModifyGraph/W=$winName alblRGB(bottom)=(65535,65535,65535)
	ModifyGraph/W=$winName alblRGB(left)=(65535,65535,65535)
	ModifyGraph/W=$winName tickRGB(bottom)=(65535,65535,65535)
	ModifyGraph/W=$winName tickRGB(left)=(65535,65535,65535)
	
	DoWindow/T $winName, SampleName + " Average Aligned Trajectory"
	
	// ComparisonAverage State Transition Diagram
	String compFolder = "root:Comparison"
	if(!DataFolderExists(compFolder))
		NewDataFolder/O $compFolder
	endif
	
	for(s = 1; s <= Dstate; s += 1)
		String srcXName = "AvgAligned_X_S" + num2str(s)
		String srcYName = "AvgAligned_Y_S" + num2str(s)
		Wave/Z srcX = $srcXName
		Wave/Z srcY = $srcYName
		
		if(WaveExists(srcX) && WaveExists(srcY))
			// Comparison SampleName_AvgAligned_X_Sn 
			String destXName = compFolder + ":" + SampleName + "_AvgAligned_X_S" + num2str(s)
			String destYName = compFolder + ":" + SampleName + "_AvgAligned_Y_S" + num2str(s)
			Duplicate/O srcX, $destXName
			Duplicate/O srcY, $destYName
		endif
		
		// L
		String srcLXName = "AvgLCircle_X_S" + num2str(s)
		String srcLYName = "AvgLCircle_Y_S" + num2str(s)
		Wave/Z srcLX = $srcLXName
		Wave/Z srcLY = $srcLYName
		
		if(WaveExists(srcLX) && WaveExists(srcLY))
			String destLXName = compFolder + ":" + SampleName + "_AvgLCircle_X_S" + num2str(s)
			String destLYName = compFolder + ":" + SampleName + "_AvgLCircle_Y_S" + num2str(s)
			Duplicate/O srcLX, $destLXName
			Duplicate/O srcLY, $destLYName
		endif
	endfor
	
	SetDataFolder root:
	Print "Average Aligned Trajectory creation complete"
	return 0
End
