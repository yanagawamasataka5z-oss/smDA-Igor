#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3

// =============================================================================
// SMI_Comparison.ipf - Sample Comparison and Statistics Display
// Version 2.8.0 - Refactored with common extraction functions
// =============================================================================
// :
// 1. Stats: mean±sem (root:SampleName:Results)
// 2. Compare:  (root:SampleName:Matrix)
// 3. Violin/Box plot with individual data points
// =============================================================================

// -----------------------------------------------------------------------------
// 
// -----------------------------------------------------------------------------

// Packages, Comparison
Function/S GetSampleFolderList()
	String folderList = ""
	Variable numFolders = CountObjects("root:", 4)
	Variable i
	String folderName
	
	for(i = 0; i < numFolders; i += 1)
		folderName = GetIndexedObjName("root:", 4, i)
		// 
		if(IsSystemFolder(folderName))
			continue
		endif
		// Exclude Index_* folders (fiducial / drift correction data)
		if(StringMatch(folderName, "Index_*") == 1)
			continue
		endif
		// Exclude Tif_* folders (imported external images)
		if(StringMatch(folderName, "Tif_*") == 1)
			continue
		endif
		folderList += folderName + ";"
	endfor
	
	return folderList
End

// GetSampleFolderList
Function/S GetSampleList()
	return GetSampleFolderList()
End

// Cell
Function/S GetCellList(sampleName)
	String sampleName
	
	String cellList = ""
	String samplePath = "root:" + sampleName
	
	if(!DataFolderExists(samplePath))
		return ""
	endif
	
	Variable numFolders = CountObjects(samplePath, 4)
	Variable i
	String folderName
	
	for(i = 0; i < numFolders; i += 1)
		folderName = GetIndexedObjName(samplePath, 4, i)
		// CellCell_Results/Matrix
		if(StringMatch(folderName, "Results") || StringMatch(folderName, "Matrix"))
			continue
		endif
		if(StringMatch(folderName, "Fitting"))
			continue
		endif
		cellList += folderName + ";"
	endfor
	
	return cellList
End

// Comparison/
Function EnsureComparisonFolder()
	if(!DataFolderExists("root:Comparison"))
		NewDataFolder/O root:Comparison
	endif
End

// Dstate
Function GetDstateColor(state, r, g, b)
	Variable state
	Variable &r, &g, &b
	
	switch(state)
		case 0:
			r = 0; g = 0; b = 0  // S0: 
			break
		case 1:
			r = 0; g = 0; b = 65535  // S1: 
			break
		case 2:
			r = 65535; g = 43520; b = 0  // S2: 
			break
		case 3:
			r = 0; g = 39168; b = 0  // S3: 
			break
		case 4:
			r = 65535; g = 0; b = 0  // S4: 
			break
		default:
			r = 39168; g = 0; b = 39168  // S5+: 
			break
	endswitch
End

// DstateState Transition Diagram
// stateNum: 0
// Dstate: 2-5
// S0 = AllS1
Function/S GetDstateName(stateNum, Dstate)
	Variable stateNum, Dstate
	
	// S0"all"
	if(stateNum == 0)
		return "all"
	endif
	
	// S1Dstate
	// Dstate=2: S1=Slow, S2=Fast
	// Dstate=3: S1=Immobile, S2=Slow, S3=Fast
	// Dstate=4: S1=Immobile, S2=Slow, S3=Medium, S4=Fast
	// Dstate=5: S1=Immobile, S2=Slow, S3=Medium, S4=Fast, S5=Ultra Fast
	
	Variable stateIdx = stateNum - 1  // 0-based
	
	if(Dstate == 2)
		switch(stateIdx)
			case 0:
				return "slow"
			case 1:
				return "fast"
		endswitch
	elseif(Dstate == 3)
		switch(stateIdx)
			case 0:
				return "immobile"
			case 1:
				return "slow"
			case 2:
				return "fast"
		endswitch
	elseif(Dstate == 4)
		switch(stateIdx)
			case 0:
				return "immobile"
			case 1:
				return "slow"
			case 2:
				return "medium"
			case 3:
				return "fast"
		endswitch
	elseif(Dstate >= 5)
		switch(stateIdx)
			case 0:
				return "immobile"
			case 1:
				return "slow"
			case 2:
				return "medium"
			case 3:
				return "fast"
			case 4:
				return "ultra fast"
		endswitch
	endif
	
	return "S" + num2str(stateNum)
End

// HMM state
// sampleIndex: 0
// numSamples: 
// stateNum: HMM state (0, 1, 2, ...)
Function GetStateColorWithShade(stateNum, sampleIndex, numSamples, r, g, b)
	Variable stateNum, sampleIndex, numSamples
	Variable &r, &g, &b
	
	// HMM state
	GetDstateColor(stateNum, r, g, b)
	
	Variable maxVal = 65535
	
	// 150%
	if(numSamples <= 1)
		r = min(r + (maxVal - r) * 0.5, maxVal)
		g = min(g + (maxVal - g) * 0.5, maxVal)
		b = min(b + (maxVal - b) * 0.5, maxVal)
		return 0
	endif
	
	// 0.0 ~ 1.0
	Variable t = sampleIndex / (numSamples - 1)
	
	// : 40%
	Variable darkR = r * 0.4
	Variable darkG = g * 0.4
	Variable darkB = b * 0.4
	
	// : 50%
	Variable lightR = r + (maxVal - r) * 0.5
	Variable lightG = g + (maxVal - g) * 0.5
	Variable lightB = b + (maxVal - b) * 0.5
	
	// sampleIndex=0sampleIndex=numSamples-1
	r = darkR + (lightR - darkR) * t
	g = darkG + (lightG - darkG) * t
	b = darkB + (lightB - darkB) * t
	
	return 0
End

// =============================================================================
// 
// =============================================================================

// \s()
Function CreateSampleLegendWithTraces(traceList, labelList)
	String traceList, labelList
	
	Variable numTraces = ItemsInList(traceList)
	if(numTraces == 0)
		return 0
	endif
	
	Variable i
	String traceName, labelName, legendStr
	
	legendStr = "\\F'Arial'\\Z12"
	for(i = 0; i < numTraces; i += 1)
		traceName = StringFromList(i, traceList)
		labelName = StringFromList(i, labelList)
		
		if(i > 0)
			legendStr += "\r"
		endif
		legendStr += "\\s(" + traceName + ") " + labelName
	endfor
	
	TextBox/C/N=legend/F=0/B=1/A=RT/X=2/Y=2 legendStr
	return 0
End

// =============================================================================
// Stats - 
// =============================================================================

// -----------------------------------------------------------------------------
// CompareLowerBound - normalized Lower Bound
// cellnLowerBoundMatrix
// : 1) Summary Plot ( + violin plot) 2) Line Plot ()
// -----------------------------------------------------------------------------
Function CompareLowerBound(SampleName)
	String SampleName
	
	// LowerBound5
	Variable numStates = 5
	
	Variable numCells = CountDataFolders(SampleName)
	if(numCells == 0)
		Print "Error: No cells found in sample " + SampleName
		return -1
	endif
	
	String basePath = "root:" + SampleName + ":"
	String matrixPath = basePath + "Matrix:"
	String resultsPath = basePath + "Results:"
	
	// Matrix/Results
	NewDataFolder/O $(basePath + "Matrix")
	NewDataFolder/O $(basePath + "Results")
	
	// nLowerBound_m [state][cell] - 5
	SetDataFolder $matrixPath
	Make/O/D/N=(numStates, numCells) nLowerBound_m = NaN
	Wave nLB_m = nLowerBound_m
	
	// cellnLowerBound
	Variable m, sIdx, j
	String FolderName, wavePath
	
	for(m = 0; m < numCells; m += 1)
		FolderName = SampleName + num2str(m + 1)
		wavePath = basePath + FolderName + ":nLowerBound"
		Wave/Z nLB = $wavePath
		
		if(WaveExists(nLB))
			Variable nPts = min(numStates, numpnts(nLB))
			for(sIdx = 0; sIdx < nPts; sIdx += 1)
				nLB_m[sIdx][m] = nLB[sIdx]
			endfor
		endif
	endfor
	
	// Results - 5
	SetDataFolder $resultsPath
	Make/O/D/N=(numStates) nLowerBound_m_avg = NaN
	Make/O/D/N=(numStates) nLowerBound_m_sd = NaN
	Make/O/D/N=(numStates) nLowerBound_m_sem = NaN
	Make/O/D/N=(numStates) nLowerBound_m_n = NaN
	
	Wave avgW = nLowerBound_m_avg
	Wave sdW = nLowerBound_m_sd
	Wave semW = nLowerBound_m_sem
	Wave nW = nLowerBound_m_n
	
	for(sIdx = 0; sIdx < numStates; sIdx += 1)
		Make/FREE/D/N=(numCells) tempRow
		tempRow = nLB_m[sIdx][p]
		WaveStats/Q tempRow
		avgW[sIdx] = V_avg
		sdW[sIdx] = V_sdev
		nW[sIdx] = V_npnts
		if(V_npnts > 0)
			semW[sIdx] = V_sdev / sqrt(V_npnts)
		else
			semW[sIdx] = NaN
		endif
	endfor
	
	// === Comparison ===
	EnsureComparisonFolder()
	SetDataFolder root:Comparison
	
	// StateWaveX- 5
	Make/O/T/N=(numStates) LB_StateNames
	for(sIdx = 0; sIdx < numStates; sIdx += 1)
		LB_StateNames[sIdx] = "S" + num2str(sIdx + 1)
	endfor
	
	// Wave
	Make/O/N=(numStates) LB_mean = NaN
	Make/O/N=(numStates) LB_sem = NaN
	Wave meanW2 = LB_mean
	Wave semW2 = LB_sem
	meanW2 = avgW[p]
	semW2 = semW[p]
	
	// WaveDstate
	Make/O/N=(numStates, 3) LB_colors = 0
	Wave BarColors = LB_colors
	Variable baseR, baseG, baseB
	for(sIdx = 0; sIdx < numStates; sIdx += 1)
		GetDstateColor(sIdx + 1, baseR, baseG, baseB)
		BarColors[sIdx][0] = baseR
		BarColors[sIdx][1] = baseG
		BarColors[sIdx][2] = baseB
	endfor
	
	// StateCell data
	String cellDataName, firstViolinTrace = ""
	for(sIdx = 0; sIdx < numStates; sIdx += 1)
		cellDataName = "nLB_S" + num2str(sIdx + 1)
		Make/O/N=(numCells) $cellDataName = NaN
		Wave cellData = $cellDataName
		for(j = 0; j < numCells; j += 1)
			cellData[j] = nLB_m[sIdx][j]
		endfor
		// NaN
		WaveTransform zapNaNs cellData
		
		if(strlen(firstViolinTrace) == 0 && numpnts(cellData) > 0)
			firstViolinTrace = cellDataName
		endif
	endfor
	
	// === 1. Summary Plot ( + violin plot) ===
	String winName = "Compare_LowerBound_" + SampleName
	DoWindow/K $winName
	
	// 1-1. Mean±SEM
	Display/K=1/N=$winName meanW2 vs LB_StateNames
	ModifyGraph mode(LB_mean)=5, hbFill(LB_mean)=2
	ModifyGraph zColor(LB_mean)={BarColors,*,*,directRGB,0}
	ModifyGraph useBarStrokeRGB(LB_mean)=1, barStrokeRGB(LB_mean)=(0,0,0)
	ErrorBars LB_mean Y,wave=(semW2, semW2)
	
	// 1-2. Violin Plot/T
	Variable firstViolin = 1
	for(sIdx = 0; sIdx < numStates; sIdx += 1)
		cellDataName = "nLB_S" + num2str(sIdx + 1)
		Wave/Z cellData = $cellDataName
		
		if(!WaveExists(cellData) || numpnts(cellData) == 0)
			continue
		endif
		
		if(firstViolin)
			AppendViolinPlot/T cellData vs LB_StateNames
			firstViolin = 0
		else
			AddWavesToViolinPlot/T=$firstViolinTrace cellData
		endif
	endfor
	
	// 1-3. Violin Plot
	if(strlen(firstViolinTrace) > 0)
		ModifyViolinPlot trace=$firstViolinTrace, LineColor=(65535,65535,65535,0)
		ModifyViolinPlot trace=$firstViolinTrace, DataMarker=19, MarkerColor=(0,0,0)
	endif
	
	// 1-4. Top axis
	ModifyGraph noLabel(top)=2, axThick(top)=0
	ModifyGraph tick(top)=3
	
	// 
	ModifyGraph tick=2, mirror=0, fStyle=1, fSize=14, font="Arial"
	ModifyGraph tick(bottom)=3
	ModifyGraph tkLblRot(bottom)=0
	ModifyGraph catGap(bottom)=0.5
	
	// 5
	SetBarGraphSizeByItems(numStates, baseWidth=150, widthPerItem=30)
	
	Label left "\\F'Arial'\\Z14Normalized Lower Bound"
	SetAxis left 0, 1.1
	DoWindow/T $winName, "Compare Lower Bound (Summary): " + SampleName
	
	// === 2. Line Plot (: mean ± SEM) ===
	String lineWinName = "LowerBound_Line_" + SampleName
	DoWindow/K $lineWinName
	
	// XStateWave
	Make/O/D/N=(numStates) LB_StateX
	LB_StateX = p + 1  // State 1, 2, 3, 4, 5
	
	Display/K=1/N=$lineWinName meanW2 vs LB_StateX
	ModifyGraph mode(LB_mean)=4, marker(LB_mean)=19
	ModifyGraph msize(LB_mean)=6, lsize(LB_mean)=1.5
	ModifyGraph rgb(LB_mean)=(0, 0, 65535)
	ErrorBars LB_mean Y,wave=(semW2, semW2)
	
	// 
	ModifyGraph tick=2, mirror=1, fStyle=1, fSize=14, font="Arial"
	ModifyGraph manTick(bottom)={1,1,0,0}, manMinor(bottom)={0,0}
	ModifyGraph width={Aspect, 1.618}
	Label left "\\F'Arial'\\Z14Normalized Lower Bound"
	Label bottom "\\F'Arial'\\Z14D-state"
	SetAxis left 0, 1.1
	SetAxis bottom 0.5, numStates + 0.5
	DoWindow/T $lineWinName, "Lower Bound (Line): " + SampleName
	
	// 
	Print "=== Lower Bound Comparison: " + SampleName + " ==="
	Print "Number of cells: " + num2str(numCells)
	Print "States: " + num2str(numStates)
	Printf "State\tMean\t±SEM\tn\r"
	for(sIdx = 0; sIdx < numStates; sIdx += 1)
		Printf "S%d\t%.4f\t±%.4f\t%d\r", sIdx+1, avgW[sIdx], semW[sIdx], nW[sIdx]
	endfor
	
	SetDataFolder root:
	
	// Summary Plot
	RunAutoStatisticalTest(winName)
	
	return 0
End

// -----------------------------------------------------------------------------
// AverageMSD - MSD-dt
// Results folderMSD_avg_Sn_m_avg, MSD_time_Sn_m_avg
// AreaRangeMSDDiffusion
// : AverageMSDtPlotSs_Gcount()
// -----------------------------------------------------------------------------
Function AverageMSD(stateNum)
	Variable stateNum  // D-state (0, 1, 2, ...)
	
	EnsureComparisonFolder()
	
	String sampleList = GetSampleFolderList()
	Variable numSamples = ItemsInList(sampleList)
	
	if(numSamples == 0)
		Print "No samples found"
		return -1
	endif
	
	// WaveResults folder
	String stateStr = "S" + num2str(stateNum)
	String MSD_avg_name = "MSD_avg_" + stateStr + "_m_avg"
	String MSD_sem_name = "MSD_avg_" + stateStr + "_m_sem"
	String MSD_time_name = "MSD_time_" + stateStr + "_m_avg"
	
	// : DiffusionAreaRangeMSD
	NVAR AreaRangeMSD = root:AreaRangeMSD
	Variable cutoffPt = AreaRangeMSD

	//
	String winName = "AverageMSD_" + stateStr
	DoWindow/K $winName
	Display/K=1/N=$winName

	//
	NVAR InitialD0 = root:InitialD0
	NVAR InitialL = root:InitialL
	Variable D0init = InitialD0
	Variable Linit = InitialL
	
	Variable i, f, r, g, b
	Variable RowSize
	String smpl, resultsPath
	String wName_avg, wName_sem, wName_time, fit_wName
	String traceList = "", labelList = ""
	
	SetDataFolder root:Comparison
	
	for(i = 0; i < numSamples; i += 1)
		smpl = StringFromList(i, sampleList)
		resultsPath = "root:" + smpl + ":Results:"
		
		// Results folderWave
		Wave/Z MSD_avg_src = $(resultsPath + MSD_avg_name)
		Wave/Z MSD_sem_src = $(resultsPath + MSD_sem_name)
		Wave/Z MSD_time_src = $(resultsPath + MSD_time_name)
		
		if(!WaveExists(MSD_avg_src) || !WaveExists(MSD_time_src))
			Print "MSD waves not found for: " + smpl + " (" + resultsPath + MSD_avg_name + ")"
			continue
		endif
		
		// Comparison folder
		wName_avg = smpl + "_MSD_" + stateStr + "_avg"
		wName_sem = smpl + "_MSD_" + stateStr + "_sem"
		wName_time = smpl + "_MSD_" + stateStr + "_time"
		
		Duplicate/O MSD_avg_src, $wName_avg
		Duplicate/O MSD_time_src, $wName_time
		Wave avgWave = $wName_avg
		Wave timeWave = $wName_time
		
		if(WaveExists(MSD_sem_src))
			Duplicate/O MSD_sem_src, $wName_sem
		else
			// SEM0
			Make/O/N=(numpnts(avgWave)) $wName_sem = 0
		endif
		Wave semWave = $wName_sem
		
		RowSize = numpnts(avgWave)
		
		// AreaRangeMSDNaN
		for(f = cutoffPt + 1; f < RowSize; f += 1)
			avgWave[f] = NaN
			semWave[f] = NaN
		endfor
		
		// sem[0]0
		if(semWave[0] == 0 || numtype(semWave[0]) != 0)
			semWave[0] = 0.00001
		endif
		
		// 
		AppendToGraph avgWave vs timeWave
		ErrorBars $wName_avg Y,wave=(semWave, semWave)
		
		// MSD_dt
		Make/O/D/N=2 W_coef_msd
		W_coef_msd[0] = D0init
		W_coef_msd[1] = Linit
		Make/O/T/N=2 T_Constraints_msd
		T_Constraints_msd[0] = "K0 > 0"
		T_Constraints_msd[1] = "K1 > 0"
		
		// 2
		FuncFit/Q/NTHR=0 MSD_dt W_coef_msd avgWave /X=timeWave /D /C=T_Constraints_msd
		FuncFit/Q/NTHR=0 MSD_dt W_coef_msd avgWave /X=timeWave /D /C=T_Constraints_msd
		
		fit_wName = "fit_" + wName_avg
		
		// HMM state
		GetStateColorWithShade(stateNum, i, numSamples, r, g, b)
		ModifyGraph rgb($wName_avg)=(r, g, b)
		ModifyGraph mode($wName_avg)=3, marker($wName_avg)=19
		
		// Error bar with shading
		ErrorBars $wName_avg SHADE= {0,4,(r,g,b,32768),(r,g,b,32768)},wave=(semWave, semWave)
		
		Wave/Z fitWave = $fit_wName
		if(WaveExists(fitWave))
			ModifyGraph rgb($fit_wName)=(r, g, b)
			ModifyGraph lsize($fit_wName)=1.5
		endif
		
		Print smpl + " (" + stateStr + "): D=" + num2str(W_coef_msd[0]) + " µm²/s, L=" + num2str(W_coef_msd[1]) + " µm"
		
		// 
		traceList = AddListItem(wName_avg, traceList, ";", inf)
		labelList = AddListItem(smpl, labelList, ";", inf)
	endfor
	
	// 
	CreateSampleLegendWithTraces(traceList, labelList)
	
	// 
	ModifyGraph width={Aspect, 1.618}
	ModifyGraph tick=0, mirror=0
	ModifyGraph lowTrip(left)=0.0001
	ModifyGraph axisEnab(left)={0.05, 1}, axisEnab(bottom)={0.05, 1}
	ModifyGraph fStyle=1, fSize=16, font="Arial"
	Label left "\\F'Arial'\\Z14MSD (µm\\S2\\M\\F'Arial'\\Z14)"
	Label bottom "\\F'Arial'\\Z12Δt (s)"
	SetAxis left 0, *
	
	// 
	NVAR DstateVar = root:Dstate
	Variable totalStates = DstateVar
	String stateName = GetDstateName(stateNum, totalStates)
	DoWindow/T $winName, "Average MSD-Δt (" + stateName + ")"
	
	// 
	KillWaves/Z W_coef_msd, T_Constraints_msd
	
	SetDataFolder root:
	Print "Average MSD plot completed for " + stateName
	return 0
End

// -----------------------------------------------------------------------------
// AverageMSDPerSample - D-state MSD1
// Single AnalysisDisplayMSDGraphHMMmean±sem
// -----------------------------------------------------------------------------
Function AverageMSDPerSample(smpl)
	String smpl
	
	NVAR/Z Dstate = root:Dstate
	NVAR/Z cHMM = root:cHMM
	NVAR AreaRangeMSD = root:AreaRangeMSD
	NVAR framerate = root:framerate

	Variable maxState = 0
	if(NVAR_Exists(cHMM) && cHMM == 1 && NVAR_Exists(Dstate))
		maxState = Dstate
	endif

	Variable cutoffPt = AreaRangeMSD
	Variable fr = framerate

	//
	NVAR InitialD0 = root:InitialD0
	NVAR InitialL = root:InitialL
	Variable D0init = InitialD0
	Variable Linit = InitialL
	
	String resultsPath = "root:" + smpl + ":Results:"
	
	// S0:, S1:, S2:, S3:, S4:, S5:
	Make/FREE/N=(6,3) stateColors
	stateColors[0][0] = 0;       stateColors[0][1] = 0;       stateColors[0][2] = 0        // S0: 
	stateColors[1][0] = 0;       stateColors[1][1] = 0;       stateColors[1][2] = 65280    // S1: 
	stateColors[2][0] = 65280;   stateColors[2][1] = 43520;   stateColors[2][2] = 0        // S2: 
	stateColors[3][0] = 0;       stateColors[3][1] = 39168;   stateColors[3][2] = 0        // S3: 
	stateColors[4][0] = 65280;   stateColors[4][1] = 0;       stateColors[4][2] = 0        // S4: 
	stateColors[5][0] = 65280;   stateColors[5][1] = 0;       stateColors[5][2] = 65280    // S5: 
	
	// 
	String winName = "AverageMSD_" + smpl
	DoWindow/K $winName
	
	Variable s, f, RowSize
	Variable firstPlot = 1
	String stateStr, MSD_avg_name, MSD_sem_name, MSD_time_name
	String traceName, fit_traceName
	
	for(s = 0; s <= maxState; s += 1)
		stateStr = "S" + num2str(s)
		MSD_avg_name = "MSD_avg_" + stateStr + "_m_avg"
		MSD_sem_name = "MSD_avg_" + stateStr + "_m_sem"
		MSD_time_name = "MSD_time_" + stateStr + "_m_avg"
		
		Wave/Z MSD_avg = $(resultsPath + MSD_avg_name)
		Wave/Z MSD_sem = $(resultsPath + MSD_sem_name)
		Wave/Z MSD_time = $(resultsPath + MSD_time_name)
		
		if(!WaveExists(MSD_avg) || !WaveExists(MSD_time))
			continue
		endif
		
		// Comparison
		SetDataFolder root:Comparison
		traceName = smpl + "_" + stateStr + "_avg"
		String semName = smpl + "_" + stateStr + "_sem"
		String timeName = smpl + "_" + stateStr + "_time"
		
		Duplicate/O MSD_avg, $traceName
		Duplicate/O MSD_time, $timeName
		Wave avgW = $traceName
		Wave timeW = $timeName
		
		if(WaveExists(MSD_sem))
			Duplicate/O MSD_sem, $semName
		else
			Make/O/N=(numpnts(avgW)) $semName = 0
		endif
		Wave semW = $semName
		
		RowSize = numpnts(avgW)
		
		// 
		for(f = cutoffPt + 1; f < RowSize; f += 1)
			avgW[f] = NaN
			semW[f] = NaN
		endfor
		
		// sem[0]
		if(semW[0] == 0 || numtype(semW[0]) != 0)
			semW[0] = 0.00001
		endif
		
		// 
		if(firstPlot)
			Display/K=1/N=$winName avgW vs timeW
			firstPlot = 0
		else
			AppendToGraph avgW vs timeW
		endif
		
		// Error bar with shading
		ErrorBars $traceName SHADE= {0,4,(stateColors[s][0],stateColors[s][1],stateColors[s][2],32768),(stateColors[s][0],stateColors[s][1],stateColors[s][2],32768)},wave=(semW, semW)
		
		// 
		ModifyGraph mode($traceName)=3, marker($traceName)=19, msize($traceName)=3
		ModifyGraph rgb($traceName)=(stateColors[s][0], stateColors[s][1], stateColors[s][2])
		
		// MSD_dt
		Make/O/D/N=2 W_coef_msd
		W_coef_msd[0] = D0init
		W_coef_msd[1] = Linit
		Make/O/T/N=2 T_Constraints_msd
		T_Constraints_msd[0] = "K0 > 0"
		T_Constraints_msd[1] = "K1 > 0"
		
		FuncFit/Q/NTHR=0 MSD_dt W_coef_msd avgW /X=timeW /D /C=T_Constraints_msd
		FuncFit/Q/NTHR=0 MSD_dt W_coef_msd avgW /X=timeW /D /C=T_Constraints_msd
		
		fit_traceName = "fit_" + traceName
		Wave/Z fitW = $fit_traceName
		if(WaveExists(fitW))
			ModifyGraph mode($fit_traceName)=0, lsize($fit_traceName)=2
			ModifyGraph rgb($fit_traceName)=(stateColors[s][0], stateColors[s][1], stateColors[s][2])
		endif
		
		Print smpl + " " + stateStr + ": D=" + num2str(W_coef_msd[0]) + " µm²/s, L=" + num2str(W_coef_msd[1]) + " µm"
	endfor
	
	if(firstPlot)
		// 
		Print "No MSD data found for: " + smpl
		return -1
	endif
	
	// 
	ModifyGraph tick=0, mirror=0
	ModifyGraph lowTrip(left)=0.0001
	ModifyGraph fStyle=1, fSize=16, font="Arial"
	ModifyGraph width={Aspect, 1.618}
	SetAxis left 0, *
	SetAxis bottom 0, cutoffPt * fr
	Label left "MSD [µm²]"
	Label bottom "Δt [s]"
	DoWindow/T $winName, smpl + " Average MSD-Δt (all states)"
	
	// 
	String legendStr = "\\F'Arial'\\Z12"
	String stateName
	for(s = 0; s <= maxState; s += 1)
		stateStr = "S" + num2str(s)
		traceName = smpl + "_" + stateStr + "_avg"
		Wave/Z tw = root:Comparison:$traceName
		if(WaveExists(tw))
			stateName = GetDstateName(s, maxState)
			if(s == 0)
				legendStr += "\\s(" + traceName + ") " + stateName
			else
				legendStr += "\r\\s(" + traceName + ") " + stateName
			endif
		endif
	endfor
	TextBox/C/N=legend0/F=0/B=1/A=LT legendStr
	
	// 
	KillWaves/Z W_coef_msd, T_Constraints_msd
	
	SetDataFolder root:
	return 0
End

// -----------------------------------------------------------------------------
// StatsIntensity - 
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// StatsDensity - 
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// StatsOffrate - Off-rate
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// StatsOnrate - On-rate
// -----------------------------------------------------------------------------

// =============================================================================
// Compare - 
// =============================================================================

// -----------------------------------------------------------------------------
// CollectSampleData - Matrix/Results
// -----------------------------------------------------------------------------
Function CollectSampleData(paramName, stateName)
	String paramName  // "D", "L", "HMMP", "Intensity", "Density", "Tau", "Onrate"
	String stateName  // "_S0", "_S1", ...  ""
	
	EnsureComparisonFolder()
	SetDataFolder root:Comparison
	
	String sampleList = GetSampleFolderList()
	Variable numSamples = ItemsInList(sampleList)
	
	if(numSamples == 0)
		Print "No samples found"
		SetDataFolder root:
		return -1
	endif
	
	// Wave
	Make/O/T/N=(numSamples) SampleNames
	
	Variable i, j, maxCells = 0
	Variable nCells, nRows
	String smplName, matrixPath, matrixName, cellDataName, cleanDataName
	
	// 
	for(i = 0; i < numSamples; i += 1)
		smplName = StringFromList(i, sampleList)
		SampleNames[i] = smplName
		matrixPath = "root:" + smplName + ":Matrix:"
		
		matrixName = "Matrix" + paramName + stateName
		Wave/Z matrix = $(matrixPath + matrixName)
		if(WaveExists(matrix))
			nCells = DimSize(matrix, 0)
			if(nCells > maxCells)
				maxCells = nCells
			endif
		endif
	endfor
	
	if(maxCells == 0)
		Print "No matrix data found for: " + paramName + stateName
		SetDataFolder root:
		return -1
	endif
	
	// ComparisonMatrix
	String compMatrixName = "Matrix" + paramName + stateName
	Make/O/N=(maxCells, numSamples) $compMatrixName = NaN
	Wave compMatrix = $compMatrixName
	
	// 
	for(i = 0; i < numSamples; i += 1)
		smplName = StringFromList(i, sampleList)
		matrixPath = "root:" + smplName + ":Matrix:"
		
		Wave/Z matrix = $(matrixPath + "Matrix" + paramName + stateName)
		if(WaveExists(matrix))
			nRows = DimSize(matrix, 0)
			for(j = 0; j < nRows; j += 1)
				compMatrix[j][i] = matrix[j][0]  // 1
			endfor
		endif
	endfor
	
	// Wave
	for(i = 0; i < numSamples; i += 1)
		smplName = StringFromList(i, sampleList)
		cellDataName = paramName + stateName + "_celldata_" + smplName
		Make/O/N=(maxCells) $cellDataName = NaN
		Wave cellData = $cellDataName
		cellData[] = compMatrix[p][i]
		
		// NaNWave
		cleanDataName = paramName + stateName + "_" + smplName
		Duplicate/O cellData, tempData
		WaveTransform zapNaNs tempData
		Duplicate/O tempData, $cleanDataName
		KillWaves/Z tempData
	endfor
	
	SetDataFolder root:
	return 0
End

// -----------------------------------------------------------------------------
// CompareD - DMean±SEM + 
// -----------------------------------------------------------------------------
Function CompareD(stateNum)
	Variable stateNum  // 0=S0, 1=S1, ...
	
	String suffix = "_S" + num2str(stateNum)
	String matrixName = "coef_MSD" + suffix + "_m"
	
	EnsureComparisonFolder()
	SetDataFolder root:Comparison
	
	String sampleList = GetSampleFolderList()
	Variable numSamples = ItemsInList(sampleList)
	
	if(numSamples == 0)
		SetDataFolder root:
		return -1
	endif
	
	// Wave
	Make/O/T/N=(numSamples) SampleNames
	
	String winName = "Compare_D" + suffix
	DoWindow/K $winName
	
	// WaveSn
	String meanWaveName = "D_mean" + suffix
	String semWaveName = "D_sem" + suffix
	String colorWaveName = "D_colors" + suffix
	Make/O/N=(numSamples) $meanWaveName = NaN
	Make/O/N=(numSamples) $semWaveName = NaN
	Wave D_meanW = $meanWaveName
	Wave D_semW = $semWaveName
	
	// StateWavezColor
	Make/O/N=(numSamples, 3) $colorWaveName = 0
	Wave BarColors = $colorWaveName
	
	// HMM state
	Variable baseR, baseG, baseB
	GetDstateColor(stateNum, baseR, baseG, baseB)
	
	Variable i, j, nCells
	String smplName, srcMatrixPath, cellDataName
	String avgPath, semPath
	String firstViolinTrace = ""
	
	// 
	for(i = 0; i < numSamples; i += 1)
		smplName = StringFromList(i, sampleList)
		SampleNames[i] = smplName
		srcMatrixPath = "root:" + smplName + ":Matrix:" + matrixName
		Wave/Z srcMatrix = $srcMatrixPath
		
		if(!WaveExists(srcMatrix))
			continue
		endif
		
		nCells = DimSize(srcMatrix, 1)
		
		// Cell dataD = 0
		cellDataName = "D" + suffix + "_" + smplName
		Make/O/N=(nCells) $cellDataName = NaN
		Wave cellData = $cellDataName
		for(j = 0; j < nCells; j += 1)
			cellData[j] = srcMatrix[0][j]  // 0 = D
		endfor
		
		// NaN
		WaveTransform zapNaNs cellData
		
		// Results
		avgPath = "root:" + smplName + ":Results:" + matrixName + "_avg"
		semPath = "root:" + smplName + ":Results:" + matrixName + "_sem"
		Wave/Z avgWave = $avgPath
		Wave/Z semWave = $semPath
		
		if(WaveExists(avgWave) && WaveExists(semWave))
			D_meanW[i] = avgWave[0]  // D avg
			D_semW[i] = semWave[0]   // D sem
		endif
		
		// 
		Variable r = baseR, g = baseG, b = baseB
		if(i > 0)
			r = min(baseR + 15000 * i, 65535)
			g = min(baseG + 15000 * i, 65535)
			b = min(baseB + 15000 * i, 65535)
		endif
		BarColors[i][0] = r
		BarColors[i][1] = g
		BarColors[i][2] = b
		
		// Violin
		if(strlen(firstViolinTrace) == 0 && numpnts(cellData) > 0)
			firstViolinTrace = cellDataName
		endif
	endfor
	
	// ===  ===
	// 1. Mean±SEM
	Display/K=1/N=$winName D_meanW vs SampleNames
	ModifyGraph mode($meanWaveName)=5, hbFill($meanWaveName)=2
	ModifyGraph zColor($meanWaveName)={BarColors,*,*,directRGB,0}
	ModifyGraph useBarStrokeRGB($meanWaveName)=1, barStrokeRGB($meanWaveName)=(0,0,0)
	ErrorBars $meanWaveName Y,wave=(D_semW, D_semW)
	
	// 2. Violin Plot/TTop axis
	Variable firstViolin = 1
	for(i = 0; i < numSamples; i += 1)
		smplName = StringFromList(i, sampleList)
		cellDataName = "D" + suffix + "_" + smplName
		Wave/Z cellData = $cellDataName
		
		if(!WaveExists(cellData) || numpnts(cellData) == 0)
			continue
		endif
		
		if(firstViolin)
			AppendViolinPlot/T cellData vs SampleNames
			firstViolin = 0
		else
			AddWavesToViolinPlot/T=$firstViolinTrace cellData
		endif
	endfor
	
	// 3. Violin Plot
	if(strlen(firstViolinTrace) > 0)
		// alpha=0
		ModifyViolinPlot trace=$firstViolinTrace, LineColor=(65535,65535,65535,0)
		// 
		ModifyViolinPlot trace=$firstViolinTrace, DataMarker=19, MarkerColor=(0,0,0)
	endif
	
	// 4. Top axis
	ModifyGraph noLabel(top)=2, axThick(top)=0
	ModifyGraph tick(top)=3
	
	// 
	NVAR DstateVar = root:Dstate
	Variable totalStates = DstateVar
	String stateName = GetDstateName(stateNum, totalStates)
	
	// 
	ModifyGraph tick=2, mirror=0, fStyle=1, fSize=14, font="Arial"
	ModifyGraph tick(bottom)=3
	ModifyGraph tkLblRot(bottom)=90
	ModifyGraph catGap(bottom)=0.5
	
	// 
	SetBarGraphSizeByItems(numSamples, baseWidth=150, widthPerItem=30)
	
	Label left "\\F'Arial'\\Z14D\\B" + stateName + "\\M [µm\\S2\\M\\F'Arial'\\Z14/s]"
	SetAxis left 0, *
	DoWindow/T $winName, "Compare D (S" + num2str(stateNum) + ": " + stateName + ")"
	
	SetDataFolder root:
	Print "Compare D" + suffix + " completed: " + num2str(numSamples) + " samples"
	
	// 
	RunAutoStatisticalTest(winName)
End

// -----------------------------------------------------------------------------
// CompareL - LMean±SEM + 
// -----------------------------------------------------------------------------
Function CompareL(stateNum)
	Variable stateNum
	
	String suffix = "_S" + num2str(stateNum)
	String matrixName = "coef_MSD" + suffix + "_m"
	
	EnsureComparisonFolder()
	SetDataFolder root:Comparison
	
	String sampleList = GetSampleFolderList()
	Variable numSamples = ItemsInList(sampleList)
	
	if(numSamples == 0)
		SetDataFolder root:
		return -1
	endif
	
	// Wave
	Make/O/T/N=(numSamples) SampleNames
	
	String winName = "Compare_L" + suffix
	DoWindow/K $winName
	
	// WaveSn
	String meanWaveName = "L_mean" + suffix
	String semWaveName = "L_sem" + suffix
	String colorWaveName = "L_colors" + suffix
	Make/O/N=(numSamples) $meanWaveName = NaN
	Make/O/N=(numSamples) $semWaveName = NaN
	Wave L_meanW = $meanWaveName
	Wave L_semW = $semWaveName
	
	// StateWavezColor
	Make/O/N=(numSamples, 3) $colorWaveName = 0
	Wave BarColors = $colorWaveName
	
	// HMM state
	Variable baseR, baseG, baseB
	GetDstateColor(stateNum, baseR, baseG, baseB)
	
	Variable i, j, nCells
	String smplName, srcMatrixPath, cellDataName
	String avgPath, semPath
	String firstViolinTrace = ""
	
	// 
	for(i = 0; i < numSamples; i += 1)
		smplName = StringFromList(i, sampleList)
		SampleNames[i] = smplName
		srcMatrixPath = "root:" + smplName + ":Matrix:" + matrixName
		Wave/Z srcMatrix = $srcMatrixPath
		
		if(!WaveExists(srcMatrix))
			continue
		endif
		
		// L1
		if(DimSize(srcMatrix, 0) < 2)
			continue
		endif
		
		nCells = DimSize(srcMatrix, 1)
		
		// Cell dataL = 1
		cellDataName = "L" + suffix + "_" + smplName
		Make/O/N=(nCells) $cellDataName = NaN
		Wave cellData = $cellDataName
		for(j = 0; j < nCells; j += 1)
			cellData[j] = srcMatrix[1][j]  // 1 = L
		endfor
		
		// NaN
		WaveTransform zapNaNs cellData
		
		// Results
		avgPath = "root:" + smplName + ":Results:" + matrixName + "_avg"
		semPath = "root:" + smplName + ":Results:" + matrixName + "_sem"
		Wave/Z avgWave = $avgPath
		Wave/Z semWave = $semPath
		
		if(WaveExists(avgWave) && WaveExists(semWave) && numpnts(avgWave) >= 2)
			L_meanW[i] = avgWave[1]  // L avg
			L_semW[i] = semWave[1]   // L sem
		endif
		
		// 
		Variable r = baseR, g = baseG, b = baseB
		if(i > 0)
			r = min(baseR + 15000 * i, 65535)
			g = min(baseG + 15000 * i, 65535)
			b = min(baseB + 15000 * i, 65535)
		endif
		BarColors[i][0] = r
		BarColors[i][1] = g
		BarColors[i][2] = b
		
		// Violin
		if(strlen(firstViolinTrace) == 0 && numpnts(cellData) > 0)
			firstViolinTrace = cellDataName
		endif
	endfor
	
	// ===  ===
	// 1. Mean±SEM
	Display/K=1/N=$winName L_meanW vs SampleNames
	ModifyGraph mode($meanWaveName)=5, hbFill($meanWaveName)=2
	ModifyGraph zColor($meanWaveName)={BarColors,*,*,directRGB,0}
	ModifyGraph useBarStrokeRGB($meanWaveName)=1, barStrokeRGB($meanWaveName)=(0,0,0)
	ErrorBars $meanWaveName Y,wave=(L_semW, L_semW)
	
	// 2. Violin Plot/TTop axis
	Variable firstViolin = 1
	for(i = 0; i < numSamples; i += 1)
		smplName = StringFromList(i, sampleList)
		cellDataName = "L" + suffix + "_" + smplName
		Wave/Z cellData = $cellDataName
		
		if(!WaveExists(cellData) || numpnts(cellData) == 0)
			continue
		endif
		
		if(firstViolin)
			AppendViolinPlot/T cellData vs SampleNames
			firstViolin = 0
		else
			AddWavesToViolinPlot/T=$firstViolinTrace cellData
		endif
	endfor
	
	// 3. Violin Plot
	if(strlen(firstViolinTrace) > 0)
		// alpha=0
		ModifyViolinPlot trace=$firstViolinTrace, LineColor=(65535,65535,65535,0)
		// 
		ModifyViolinPlot trace=$firstViolinTrace, DataMarker=19, MarkerColor=(0,0,0)
	endif
	
	// 4. Top axis
	ModifyGraph noLabel(top)=2, axThick(top)=0
	ModifyGraph tick(top)=3
	
	// 
	NVAR DstateVar = root:Dstate
	Variable totalStates = DstateVar
	String stateName = GetDstateName(stateNum, totalStates)
	
	// 
	ModifyGraph tick=2, mirror=0, fStyle=1, fSize=14, font="Arial"
	ModifyGraph tick(bottom)=3
	ModifyGraph tkLblRot(bottom)=90
	ModifyGraph catGap(bottom)=0.5
	
	// 
	SetBarGraphSizeByItems(numSamples, baseWidth=150, widthPerItem=30)
	
	Label left "\\F'Arial'\\Z14L\\B" + stateName + "\\M [µm]"
	SetAxis left 0, *
	DoWindow/T $winName, "Compare L (S" + num2str(stateNum) + ": " + stateName + ")"
	
	SetDataFolder root:
	Print "Compare L" + suffix + " completed: " + num2str(numSamples) + " samples"
	
	// 
	RunAutoStatisticalTest(winName)
End

// -----------------------------------------------------------------------------
// CompareDstate - D-state Population
// -----------------------------------------------------------------------------
Function CompareDstate(stateNum)
	Variable stateNum
	
	String suffix = "_S" + num2str(stateNum)
	
	CollectSampleData("HMMP", suffix)
	
	SetDataFolder root:Comparison
	
	String sampleList = GetSampleFolderList()
	Variable numSamples = ItemsInList(sampleList)
	
	Wave/T SampleNames
	
	String winName = "Compare_HMMP" + suffix
	DoWindow/K $winName
	
	Variable i, firstPlot = 1
	String smplName, dataName
	
	for(i = 0; i < numSamples; i += 1)
		smplName = StringFromList(i, sampleList)
		dataName = "HMMP" + suffix + "_" + smplName
		Wave/Z data = $dataName
		
		if(!WaveExists(data) || numpnts(data) == 0)
			continue
		endif
		
		if(firstPlot)
			Display/K=1/N=$winName
			AppendViolinPlot data vs SampleNames
			firstPlot = 0
		else
			AddWavesToViolinPlot data
		endif
	endfor
	
	if(!firstPlot)
		ModifyViolinPlot trace=$("HMMP" + suffix + "_" + StringFromList(0, sampleList)), ShowMean, CloseOutline
		ModifyViolinPlot trace=$("HMMP" + suffix + "_" + StringFromList(0, sampleList)), ShowData, DataMarker=19, MarkerSize=2
		
		ModifyGraph toMode=2
		ModifyGraph tick=0, mirror=0, fStyle=1, fSize=14, font="Arial"
		ModifyGraph tkLblRot(bottom)=90
		
		// 
		NVAR DstateVar = root:Dstate
		Variable totalStates = DstateVar
		String stateName = GetDstateName(stateNum, totalStates)
		Label left "Population [%] (" + stateName + ")"
		SetAxis left 0, *
		
		// 
		SetBarGraphSizeByItems(numSamples, baseWidth=150, widthPerItem=30)
		
		DoWindow/T $winName, "Compare D-state Population (" + stateName + ")"
	endif
	
	SetDataFolder root:
	Print "Compare HMMP" + suffix + " completed"
End

// -----------------------------------------------------------------------------
// CompareDensity - 
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// CompareOffrate - Off-rate
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// CompareOnrate - On-rate
// -----------------------------------------------------------------------------

// =============================================================================
// Compare All - 
// =============================================================================
Function CompareAll()
	// 
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
	
	Print "=========================================="
	Print "Compare All Analysis [Total]"
	Print "=========================================="
	
	// ===== root:SampleName =====
	CompareAllCore(doMSD, doStepSize, doIntensity, doLP, doDensity, doMolDensity, doOffrate, doOnrate, doStateTransition, "root", "")
	
	// ===== Segmentation =====
	//  root:Seg0:SampleName:cell 
	// basePathwaveSuffix/
	if(IsSegmentationEnabled())
		Variable maxSeg = GetMaxSegmentValue()
		Variable segIdx
		for(segIdx = 0; segIdx <= maxSeg; segIdx += 1)
			String basePath = GetSegmentFolderPath(segIdx)
			String segSuffix = GetSegmentSuffix(segIdx)
			Printf "\r==========================================\r"
			Printf "Compare All Analysis [%s]\r", GetSegmentLabel(segSuffix)
			Printf "==========================================\r"
			CompareAllCore(doMSD, doStepSize, doIntensity, doLP, doDensity, doMolDensity, doOffrate, doOnrate, doStateTransition, basePath, segSuffix)
		endfor
	endif
	
	Print "=========================================="
	Print "Compare All completed"
	Print "=========================================="
End

// CompareAllCore - ComparebasePath/waveSuffix
Function CompareAllCore(doMSD, doStepSize, doIntensity, doLP, doDensity, doMolDensity, doOffrate, doOnrate, doStateTransition, basePath, waveSuffix)
	Variable doMSD, doStepSize, doIntensity, doLP, doDensity, doMolDensity, doOffrate, doOnrate, doStateTransition
	String basePath, waveSuffix
	
	// ===== Diffusion Tab Compare =====
	// MSD Parameters (D, L)
	if(doMSD)
		Print "--- Compare MSD Parameters ---"
		CompareMSDParamsCore(basePath, waveSuffix)
	endif
	
	// StepSize (HMMP = D-state population)
	if(doStepSize)
		Print "--- Compare D-state Population (HMMP) ---"
		CompareDstateCore(basePath, waveSuffix)
	endif
	
	// ===== Intensity Tab Compare =====
	// Intensity (Mean Oligomer Size)
	if(doIntensity)
		Print "--- Compare Intensity ---"
		CompareIntensityCore(basePath, waveSuffix)
	endif
	
	// Localization Precision
	if(doLP)
		Print "--- Compare Localization Precision ---"
		CompareLPCore(basePath, waveSuffix)
	endif
	
	// Particle Density
	if(doDensity)
		Print "--- Compare Particle Density ---"
		CompareDensityCore(basePath, waveSuffix)
	endif
	
	// Molecular Density
	if(doMolDensity)
		Print "--- Compare Molecular Density ---"
		CompareMolDensCore(basePath, waveSuffix)
	endif
	
	// ===== Kinetics Tab Compare =====
	// On-time
	if(doOffrate)
		Print "--- Compare On-time ---"
		CompareOntimeCore(basePath, waveSuffix)
	endif
	
	// On-rate
	if(doOnrate)
		Print "--- Compare On-rate ---"
		CompareOnrateCore(basePath, waveSuffix)
	endif
	
	// State Transition Kinetics
	if(doStateTransition)
		Print "--- Compare State Transition Kinetics ---"
		CompareStateTransCore(basePath, waveSuffix)
	endif
	
	// Pixel Value (if Image enabled)
	NVAR/Z cImageFlag = root:cImage
	if(NVAR_Exists(cImageFlag) && cImageFlag == 1)
		Print "--- Compare Pixel Value ---"
		ComparePVMeanCore(basePath, waveSuffix)
	endif
End

// =============================================================================
// Compare
// =============================================================================

// CompareIntensity - Intensity Mean

// CompareLP - Localization Precision 

// CompareMolDensSingleState - Molecular Density 

// CompareOntime - On-time (τoff) 

// CompareStateTransKinetics - State Transition Kinetics 

// =============================================================================
//  with mean±sem + scatter
// =============================================================================

// =============================================================================
// Button Procedure
// =============================================================================

// Average buttons - MSD-dtD-state
Function StatsMSDButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	NVAR/Z Dstate = root:Dstate
	NVAR/Z cHMM = root:cHMM
	
	Variable maxState = 0
	if(NVAR_Exists(cHMM) && cHMM == 1 && NVAR_Exists(Dstate))
		maxState = Dstate
	endif
	
	EnsureComparisonFolder()
	
	// ===== Total=====
	// 1. State: AverageMSD_S0, AverageMSD_S1, ...
	Variable s
	for(s = 0; s <= maxState; s += 1)
		AverageMSD(s)
	endfor
	
	// 2. State: AverageMSD_SampleName1, ...
	String sampleList = GetSampleFolderList()
	Variable numSamples = ItemsInList(sampleList)
	Variable i
	String smpl
	
	for(i = 0; i < numSamples; i += 1)
		smpl = StringFromList(i, sampleList)
		AverageMSDPerSample(smpl)
	endfor
	
	// ===== Segmentation =====
	if(IsSegmentationEnabled())
		Variable maxSeg = GetMaxSegmentValue()
		Variable segIdx
		for(segIdx = 0; segIdx <= maxSeg; segIdx += 1)
			String basePath = GetSegmentFolderPath(segIdx)
			String segSuffix = GetSegmentSuffix(segIdx)
			String segLabel = GetSegmentLabel(segSuffix)
			Print "--- Average MSD [" + segLabel + "] ---"
			
			// SegResults
			String segSampleList = GetSampleFolderListFromPath(basePath)
			Variable segNumSamples = ItemsInList(segSampleList)
			for(i = 0; i < segNumSamples; i += 1)
				smpl = StringFromList(i, segSampleList)
				EnsureAllResultsForAverageWithPath(smpl, "MSD", basePath, segSuffix)
			endfor
			
			// AverageMSDSegWithPath
			for(s = 0; s <= maxState; s += 1)
				AverageMSDWithPath(s, basePath, segSuffix)
			endfor
		endfor
	endif
	
	Print "=== Average MSD completed ==="
	return 0
End

// MSD Parameters (D, L) 
Function CompareMSDParamsButtonProc(ctrlName) : ButtonControl
	String ctrlName
	NVAR/Z Dstate = root:Dstate
	NVAR/Z cHMM = root:cHMM
	
	Variable maxState = 0
	if(NVAR_Exists(cHMM) && cHMM == 1 && NVAR_Exists(Dstate))
		maxState = Dstate
	endif
	
	// ===== Total =====
	String sampleList = GetSampleFolderList()
	Variable numSamples = ItemsInList(sampleList)
	Variable i, s
	String smpl
	
	Print "Ensuring MSD Parameters for all samples..."
	for(i = 0; i < numSamples; i += 1)
		smpl = StringFromList(i, sampleList)
		EnsureAllResultsForAverage(smpl, "MSD")
	endfor
	
	// 
	ResetStatisticsSummaryTable()
	
	// Violin Plotstate
	for(s = 0; s <= maxState; s += 1)
		CompareD(s)
		CompareL(s)
	endfor
	
	// Mean±SEMState1
	CompareMSD_MeanSEM_D()
	CompareMSD_MeanSEM_L()
	
	// ===== Segmentation =====
	if(IsSegmentationEnabled())
		Variable maxSeg = GetMaxSegmentValue()
		Variable segIdx
		for(segIdx = 0; segIdx <= maxSeg; segIdx += 1)
			String basePath = GetSegmentFolderPath(segIdx)
			String segSuffix = GetSegmentSuffix(segIdx)
			String segLabel = GetSegmentLabel(segSuffix)
			Print "--- Compare MSD Params [" + segLabel + "] ---"
			
			// SegResults
			String segSampleList = GetSampleFolderListFromPath(basePath)
			Variable segNumSamples = ItemsInList(segSampleList)
			for(i = 0; i < segNumSamples; i += 1)
				smpl = StringFromList(i, segSampleList)
				EnsureAllResultsForAverageWithPath(smpl, "MSD", basePath, segSuffix)
			endfor
			
			// D, L WithPath
			for(s = 0; s <= maxState; s += 1)
				CompareDWithPath(s, basePath, segSuffix)
				CompareLWithPath(s, basePath, segSuffix)
			endfor
			
			// Mean±SEM
			CompareMSD_MeanSEM_D_WithPath(basePath, segSuffix)
			CompareMSD_MeanSEM_L_WithPath(basePath, segSuffix)
		endfor
	endif
	
	Print "=== Compare MSD Parameters completed ==="
End

Function CompareDstateButtonProc(ctrlName) : ButtonControl
	String ctrlName
	CompareHMMP()
	
	// === Segmentation ===
	if(IsSegmentationEnabled())
		Variable maxSeg = GetMaxSegmentValue()
		Variable segIdx
		for(segIdx = 0; segIdx <= maxSeg; segIdx += 1)
			String basePath = GetSegmentFolderPath(segIdx)
			String segSuffix = GetSegmentSuffix(segIdx)
			String segLabel = GetSegmentLabel(segSuffix)
			Print "--- Compare D-state [" + segLabel + "] ---"
			CompareHMMPWithPath(basePath, segSuffix)
		endfor
	endif
End

// Intensity parameters
Function CompareIntensityButtonProc(ctrlName) : ButtonControl
	String ctrlName
	CompareIntensity()
	
	// === Segmentation ===
	if(IsSegmentationEnabled())
		Variable maxSeg = GetMaxSegmentValue()
		Variable segIdx
		for(segIdx = 0; segIdx <= maxSeg; segIdx += 1)
			String basePath = GetSegmentFolderPath(segIdx)
			String segSuffix = GetSegmentSuffix(segIdx)
			String segLabel = GetSegmentLabel(segSuffix)
			Print "--- Compare Intensity [" + segLabel + "] ---"
			CompareIntensityWithPath(basePath, segSuffix)
		endfor
	endif
End

// Localization Precision
Function CompareLPButtonProc(ctrlName) : ButtonControl
	String ctrlName
	CompareLP()
	
	// === Segmentation ===
	if(IsSegmentationEnabled())
		Variable maxSeg = GetMaxSegmentValue()
		Variable segIdx
		for(segIdx = 0; segIdx <= maxSeg; segIdx += 1)
			String basePath = GetSegmentFolderPath(segIdx)
			String segSuffix = GetSegmentSuffix(segIdx)
			String segLabel = GetSegmentLabel(segSuffix)
			Print "--- Compare LP [" + segLabel + "] ---"
			CompareLPWithPath(basePath, segSuffix)
		endfor
	endif
End

Function CompareDensityButtonProc(ctrlName) : ButtonControl
	String ctrlName
	CompareDensity()
	
	// === Segmentation ===
	if(IsSegmentationEnabled())
		Variable maxSeg = GetMaxSegmentValue()
		Variable segIdx
		for(segIdx = 0; segIdx <= maxSeg; segIdx += 1)
			String basePath = GetSegmentFolderPath(segIdx)
			String segSuffix = GetSegmentSuffix(segIdx)
			String segLabel = GetSegmentLabel(segSuffix)
			Print "--- Compare Density [" + segLabel + "] ---"
			CompareDensityWithPath(basePath, segSuffix)
		endfor
	endif
End

// Molecular Density
Function CompareMolDensButtonProc(ctrlName) : ButtonControl
	String ctrlName
	CompareMolDensity()
	
	// === Segmentation ===
	if(IsSegmentationEnabled())
		Variable maxSeg = GetMaxSegmentValue()
		Variable segIdx
		for(segIdx = 0; segIdx <= maxSeg; segIdx += 1)
			String basePath = GetSegmentFolderPath(segIdx)
			String segSuffix = GetSegmentSuffix(segIdx)
			String segLabel = GetSegmentLabel(segSuffix)
			Print "--- Compare Mol Density [" + segLabel + "] ---"
			CompareMolDensityWithPath(basePath, segSuffix)
		endfor
	endif
End

// On-time (off-rate) 
Function CompareOntimeButtonProc(ctrlName) : ButtonControl
	String ctrlName
	CompareOnTime()
	
	// === Segmentation ===
	if(IsSegmentationEnabled())
		Variable maxSeg = GetMaxSegmentValue()
		Variable segIdx
		for(segIdx = 0; segIdx <= maxSeg; segIdx += 1)
			String basePath = GetSegmentFolderPath(segIdx)
			String segSuffix = GetSegmentSuffix(segIdx)
			String segLabel = GetSegmentLabel(segSuffix)
			Print "--- Compare On-time [" + segLabel + "] ---"
			CompareOntimeWithPath(basePath, segSuffix)
		endfor
	endif
End

Function CompareOnrateButtonProc(ctrlName) : ButtonControl
	String ctrlName
	CompareOnRate()
	
	// === Segmentation ===
	if(IsSegmentationEnabled())
		Variable maxSeg = GetMaxSegmentValue()
		Variable segIdx
		for(segIdx = 0; segIdx <= maxSeg; segIdx += 1)
			String basePath = GetSegmentFolderPath(segIdx)
			String segSuffix = GetSegmentSuffix(segIdx)
			String segLabel = GetSegmentLabel(segSuffix)
			Print "--- Compare On-rate [" + segLabel + "] ---"
			CompareOnrateWithPath(basePath, segSuffix)
		endfor
	endif
End

// State Transition Kinetics
Function CompareStateTransButtonProc(ctrlName) : ButtonControl
	String ctrlName
	CompareStateTransKinetics()
	
	// === Segmentation ===
	if(IsSegmentationEnabled())
		Variable maxSeg = GetMaxSegmentValue()
		Variable segIdx
		for(segIdx = 0; segIdx <= maxSeg; segIdx += 1)
			String basePath = GetSegmentFolderPath(segIdx)
			String segSuffix = GetSegmentSuffix(segIdx)
			String segLabel = GetSegmentLabel(segSuffix)
			Print "--- Compare State Transition [" + segLabel + "] ---"
			CompareStateTransWithPath(basePath, segSuffix)
		endfor
	endif
End

Function CompareAllButtonProc(ctrlName) : ButtonControl
	String ctrlName
	CompareAll()
End

// =============================================================================
// Average Stepsize Histogram - D-stateStep Size Histogram
// =============================================================================
Function AverageStepHist(stateNum, deltaTval)
	Variable stateNum  // D-state (0, 1, 2, ...)
	Variable deltaTval  // deltaT (1)
	
	EnsureComparisonFolder()
	
	String sampleList = GetSampleFolderList()
	Variable numSamples = ItemsInList(sampleList)
	
	if(numSamples == 0)
		Print "No samples found"
		return -1
	endif
	
	// WaveResults folder
	String stateStr = "S" + num2str(stateNum)
	String dtStr = "dt" + num2str(deltaTval)
	String hist_avg_name = "StepHist_" + dtStr + "_" + stateStr + "_m_avg"
	String hist_sem_name = "StepHist_" + dtStr + "_" + stateStr + "_m_sem"
	String hist_x_name = "StepHist_x_" + dtStr + "_" + stateStr + "_m_avg"
	
	// 
	String winName = "AverageStepHist_" + dtStr + "_" + stateStr
	DoWindow/K $winName
	Display/K=1/N=$winName
	
	Variable i, r, g, b
	String smpl, resultsPath
	String traceName, traceSemName, traceXName
	String traceList = "", labelList = ""
	
	SetDataFolder root:Comparison
	
	for(i = 0; i < numSamples; i += 1)
		smpl = StringFromList(i, sampleList)
		resultsPath = "root:" + smpl + ":Results:"
		
		Wave/Z hist_avg = $(resultsPath + hist_avg_name)
		Wave/Z hist_sem = $(resultsPath + hist_sem_name)
		Wave/Z hist_x = $(resultsPath + hist_x_name)
		
		if(!WaveExists(hist_avg) || !WaveExists(hist_x))
			Print "StepHist waves not found for: " + smpl
			continue
		endif
		
		// Comparison
		traceName = smpl + "_StepHist_" + dtStr + "_" + stateStr
		traceXName = smpl + "_StepHistX_" + dtStr + "_" + stateStr
		traceSemName = smpl + "_StepHistSem_" + dtStr + "_" + stateStr
		
		Duplicate/O hist_avg, $traceName
		Duplicate/O hist_x, $traceXName
		Wave histW = $traceName
		Wave xW = $traceXName
		
		if(WaveExists(hist_sem))
			Duplicate/O hist_sem, $traceSemName
		else
			Make/O/N=(numpnts(histW)) $traceSemName = 0
		endif
		Wave semW = $traceSemName
		
		// 
		AppendToGraph histW vs xW
		
		// HMM state
		GetStateColorWithShade(stateNum, i, numSamples, r, g, b)
		ModifyGraph rgb($traceName)=(r, g, b)
		ModifyGraph mode($traceName)=0, lsize($traceName)=1.5
		
		// Error bar with shading
		ErrorBars $traceName SHADE= {0,4,(r,g,b,32768),(r,g,b,32768)},wave=(semW, semW)
		
		// 
		traceList = AddListItem(traceName, traceList, ";", inf)
		labelList = AddListItem(smpl, labelList, ";", inf)
	endfor
	
	// 
	CreateSampleLegendWithTraces(traceList, labelList)
	
	// 
	SetStandardGraphStyle()
	Label left "Probability Density"
	Label bottom "Step size [µm]"
	SetAxis left 0, *
	SetAxis bottom 0, *
	
	// 
	NVAR DstateVar = root:Dstate
	Variable totalStates = DstateVar
	String stateName = GetDstateName(stateNum, totalStates)
	DoWindow/T $winName, "Average Step size Histogram (" + stateName + ", Δt=" + num2str(deltaTval) + ")"
	
	SetDataFolder root:
	Print "Average StepHist plot completed for " + stateName
	return 0
End

// StateStep Size Histogram
Function AverageStepHistPerSample(smpl, deltaTval)
	String smpl
	Variable deltaTval
	
	NVAR/Z Dstate = root:Dstate
	NVAR/Z cHMM = root:cHMM
	
	Variable maxState = 0
	if(NVAR_Exists(cHMM) && cHMM == 1 && NVAR_Exists(Dstate))
		maxState = Dstate
	endif
	
	String resultsPath = "root:" + smpl + ":Results:"
	String dtStr = "dt" + num2str(deltaTval)
	
	// 
	Make/FREE/N=(6,3) stateColors
	stateColors[0][0] = 0;       stateColors[0][1] = 0;       stateColors[0][2] = 0
	stateColors[1][0] = 0;       stateColors[1][1] = 0;       stateColors[1][2] = 65280
	stateColors[2][0] = 65280;   stateColors[2][1] = 43520;   stateColors[2][2] = 0
	stateColors[3][0] = 0;       stateColors[3][1] = 39168;   stateColors[3][2] = 0
	stateColors[4][0] = 65280;   stateColors[4][1] = 0;       stateColors[4][2] = 0
	stateColors[5][0] = 65280;   stateColors[5][1] = 0;       stateColors[5][2] = 65280
	
	String winName = "AverageStepHist_" + smpl
	DoWindow/K $winName
	
	Variable s, firstPlot = 1
	String stateStr, hist_avg_name, hist_sem_name, hist_x_name
	String traceName, traceSemName, traceXName
	
	EnsureComparisonFolder()
	SetDataFolder root:Comparison
	
	for(s = 0; s <= maxState; s += 1)
		stateStr = "S" + num2str(s)
		hist_avg_name = "StepHist_" + dtStr + "_" + stateStr + "_m_avg"
		hist_sem_name = "StepHist_" + dtStr + "_" + stateStr + "_m_sem"
		hist_x_name = "StepHist_x_" + dtStr + "_" + stateStr + "_m_avg"
		
		Wave/Z hist_avg = $(resultsPath + hist_avg_name)
		Wave/Z hist_sem = $(resultsPath + hist_sem_name)
		Wave/Z hist_x = $(resultsPath + hist_x_name)
		
		if(!WaveExists(hist_avg) || !WaveExists(hist_x))
			continue
		endif
		
		traceName = smpl + "_" + stateStr + "_hist"
		traceXName = smpl + "_" + stateStr + "_histX"
		traceSemName = smpl + "_" + stateStr + "_histSem"
		
		Duplicate/O hist_avg, $traceName
		Duplicate/O hist_x, $traceXName
		Wave histW = $traceName
		Wave xW = $traceXName
		
		if(WaveExists(hist_sem))
			Duplicate/O hist_sem, $traceSemName
		else
			Make/O/N=(numpnts(histW)) $traceSemName = 0
		endif
		Wave semW = $traceSemName
		
		if(firstPlot)
			Display/K=1/N=$winName histW vs xW
			firstPlot = 0
		else
			AppendToGraph histW vs xW
		endif
		
		// Error bar with shading
		ErrorBars $traceName SHADE= {0,4,(stateColors[s][0],stateColors[s][1],stateColors[s][2],32768),(stateColors[s][0],stateColors[s][1],stateColors[s][2],32768)},wave=(semW, semW)
		ModifyGraph mode($traceName)=0, lsize($traceName)=1.5
		ModifyGraph rgb($traceName)=(stateColors[s][0], stateColors[s][1], stateColors[s][2])
	endfor
	
	if(firstPlot)
		Print "No StepHist data found for: " + smpl
		SetDataFolder root:
		return -1
	endif
	
	SetStandardGraphStyle()
	Label left "Probability Density"
	Label bottom "Step size [µm]"
	SetAxis left 0, *
	SetAxis bottom 0, *
	DoWindow/T $winName, smpl + " Average Step size Histogram (all states)"
	
	// 
	String legendStr = "\\F'Arial'\\Z12"
	String stateName
	for(s = 0; s <= maxState; s += 1)
		stateStr = "S" + num2str(s)
		traceName = smpl + "_" + stateStr + "_hist"
		Wave/Z tw = root:Comparison:$traceName
		if(WaveExists(tw))
			stateName = GetDstateName(s, maxState)
			if(s == 0)
				legendStr += "\\s(" + traceName + ") " + stateName
			else
				legendStr += "\r\\s(" + traceName + ") " + stateName
			endif
		endif
	endfor
	TextBox/C/N=legend0/F=0/B=1/A=RT legendStr
	
	SetDataFolder root:
	return 0
End

// =============================================================================
// Average Intensity Histogram - Intensity Histogram
// =============================================================================
Function AverageIntHist(stateNum)
	Variable stateNum
	
	EnsureComparisonFolder()
	
	String sampleList = GetSampleFolderList()
	Variable numSamples = ItemsInList(sampleList)
	
	if(numSamples == 0)
		Print "No samples found"
		return -1
	endif
	
	String stateStr = "S" + num2str(stateNum)
	String hist_avg_name = "Int_" + stateStr + "_Phist_m_avg"
	String hist_sem_name = "Int_" + stateStr + "_Phist_m_sem"
	
	String winName = "AverageIntHist_" + stateStr
	DoWindow/K $winName
	Display/K=1/N=$winName
	
	Variable i, r, g, b
	String smpl, resultsPath, matrixPath
	String traceName, traceSemName, traceXName
	String traceList = "", labelList = ""
	
	SetDataFolder root:Comparison
	
	for(i = 0; i < numSamples; i += 1)
		smpl = StringFromList(i, sampleList)
		resultsPath = "root:" + smpl + ":Results:"
		matrixPath = "root:" + smpl + ":Matrix:"
		
		Wave/Z hist_avg = $(resultsPath + hist_avg_name)
		Wave/Z hist_sem = $(resultsPath + hist_sem_name)
		
		// XIntHist_x
		Wave/Z IntHist_x = $(matrixPath + "IntHist_x")
		if(!WaveExists(IntHist_x))
			// ResultsIntHist_x_m_avg
			Wave/Z IntHist_x = $(resultsPath + "IntHist_x_m_avg")
		endif
		
		if(!WaveExists(hist_avg))
			Print "IntHist waves not found for: " + smpl
			continue
		endif
		
		traceName = smpl + "_IntHist_" + stateStr
		traceSemName = smpl + "_IntHistSem_" + stateStr
		traceXName = smpl + "_IntHistX_" + stateStr
		
		Duplicate/O hist_avg, $traceName
		Wave histW = $traceName
		
		// X
		if(WaveExists(IntHist_x))
			Duplicate/O IntHist_x, $traceXName
		else
			Make/O/N=(numpnts(histW)) $traceXName
			Wave xW = $traceXName
			xW = p
		endif
		Wave xW = $traceXName
		
		if(WaveExists(hist_sem))
			Duplicate/O hist_sem, $traceSemName
		else
			Make/O/N=(numpnts(histW)) $traceSemName = 0
		endif
		Wave semW = $traceSemName
		
		AppendToGraph histW vs xW
		
		// HMM state
		GetStateColorWithShade(stateNum, i, numSamples, r, g, b)
		ModifyGraph rgb($traceName)=(r, g, b)
		ModifyGraph mode($traceName)=0, lsize($traceName)=1.5
		
		// Error bar with shading
		ErrorBars $traceName SHADE= {0,4,(r,g,b,32768),(r,g,b,32768)},wave=(semW, semW)
		
		// 
		traceList = AddListItem(traceName, traceList, ";", inf)
		labelList = AddListItem(smpl, labelList, ";", inf)
	endfor
	
	// 
	CreateSampleLegendWithTraces(traceList, labelList)
	
	SetStandardGraphStyle()
	Label left "Probability Density"
	Label bottom "Intensity [a.u.]"
	SetAxis left 0, *
	SetAxis bottom 0, *
	
	// 
	NVAR DstateVar = root:Dstate
	Variable totalStates = DstateVar
	String stateName = GetDstateName(stateNum, totalStates)
	DoWindow/T $winName, "Average Intensity Histogram (" + stateName + ")"
	
	SetDataFolder root:
	Print "Average IntHist plot completed for " + stateName
	return 0
End

// StateIntensity Histogram
Function AverageIntHistPerSample(smpl)
	String smpl
	
	NVAR/Z Dstate = root:Dstate
	NVAR/Z cHMM = root:cHMM
	
	Variable maxState = 0
	if(NVAR_Exists(cHMM) && cHMM == 1 && NVAR_Exists(Dstate))
		maxState = Dstate
	endif
	
	String resultsPath = "root:" + smpl + ":Results:"
	String matrixPath = "root:" + smpl + ":Matrix:"
	
	Make/FREE/N=(6,3) stateColors
	stateColors[0][0] = 0;       stateColors[0][1] = 0;       stateColors[0][2] = 0
	stateColors[1][0] = 0;       stateColors[1][1] = 0;       stateColors[1][2] = 65280
	stateColors[2][0] = 65280;   stateColors[2][1] = 43520;   stateColors[2][2] = 0
	stateColors[3][0] = 0;       stateColors[3][1] = 39168;   stateColors[3][2] = 0
	stateColors[4][0] = 65280;   stateColors[4][1] = 0;       stateColors[4][2] = 0
	stateColors[5][0] = 65280;   stateColors[5][1] = 0;       stateColors[5][2] = 65280
	
	String winName = "AverageIntHist_" + smpl
	DoWindow/K $winName
	
	Variable s, firstPlot = 1
	String stateStr, hist_avg_name, hist_sem_name
	String traceName, traceSemName, traceXName
	
	EnsureComparisonFolder()
	SetDataFolder root:Comparison
	
	// X
	Wave/Z IntHist_x = $(matrixPath + "IntHist_x")
	if(!WaveExists(IntHist_x))
		Wave/Z IntHist_x = $(resultsPath + "IntHist_x_m_avg")
	endif
	
	for(s = 0; s <= maxState; s += 1)
		stateStr = "S" + num2str(s)
		hist_avg_name = "Int_" + stateStr + "_Phist_m_avg"
		hist_sem_name = "Int_" + stateStr + "_Phist_m_sem"
		
		Wave/Z hist_avg = $(resultsPath + hist_avg_name)
		Wave/Z hist_sem = $(resultsPath + hist_sem_name)
		
		if(!WaveExists(hist_avg))
			continue
		endif
		
		traceName = smpl + "_" + stateStr + "_intHist"
		traceSemName = smpl + "_" + stateStr + "_intHistSem"
		traceXName = smpl + "_" + stateStr + "_intHistX"
		
		Duplicate/O hist_avg, $traceName
		Wave histW = $traceName
		
		if(WaveExists(IntHist_x))
			Duplicate/O IntHist_x, $traceXName
		else
			Make/O/N=(numpnts(histW)) $traceXName
			Wave xW = $traceXName
			xW = p
		endif
		Wave xW = $traceXName
		
		if(WaveExists(hist_sem))
			Duplicate/O hist_sem, $traceSemName
		else
			Make/O/N=(numpnts(histW)) $traceSemName = 0
		endif
		Wave semW = $traceSemName
		
		if(firstPlot)
			Display/K=1/N=$winName histW vs xW
			firstPlot = 0
		else
			AppendToGraph histW vs xW
		endif
		
		// Error bar with shading
		ErrorBars $traceName SHADE= {0,4,(stateColors[s][0],stateColors[s][1],stateColors[s][2],32768),(stateColors[s][0],stateColors[s][1],stateColors[s][2],32768)},wave=(semW, semW)
		ModifyGraph mode($traceName)=0, lsize($traceName)=1.5
		ModifyGraph rgb($traceName)=(stateColors[s][0], stateColors[s][1], stateColors[s][2])
	endfor
	
	if(firstPlot)
		Print "No IntHist data found for: " + smpl
		SetDataFolder root:
		return -1
	endif
	
	SetStandardGraphStyle()
	Label left "Probability Density"
	Label bottom "Intensity [a.u.]"
	SetAxis left 0, *
	SetAxis bottom 0, *
	DoWindow/T $winName, smpl + " Average Intensity Histogram (all states)"
	
	// 
	String legendStr = "\\F'Arial'\\Z12"
	String stateName
	for(s = 0; s <= maxState; s += 1)
		stateStr = "S" + num2str(s)
		traceName = smpl + "_" + stateStr + "_intHist"
		Wave/Z tw = root:Comparison:$traceName
		if(WaveExists(tw))
			stateName = GetDstateName(s, maxState)
			if(s == 0)
				legendStr += "\\s(" + traceName + ") " + stateName
			else
				legendStr += "\r\\s(" + traceName + ") " + stateName
			endif
		endif
	endfor
	TextBox/C/N=legend0/F=0/B=1/A=RT legendStr
	
	SetDataFolder root:
	return 0
End

// =============================================================================
// Average LP Histogram - Localization Precision Histogram
// =============================================================================
// State
Function AverageLPHist(stateNum)
	Variable stateNum
	
	EnsureComparisonFolder()
	
	String sampleList = GetSampleFolderList()
	Variable numSamples = ItemsInList(sampleList)
	
	if(numSamples == 0)
		Print "No samples found"
		return -1
	endif
	
	String stateStr = "S" + num2str(stateNum)
	String hist_avg_name = "LP_" + stateStr + "_Phist_m_avg"
	String hist_sem_name = "LP_" + stateStr + "_Phist_m_sem"
	String hist_x_name = "LP_" + stateStr + "_X_m_avg"
	
	String winName = "AverageLPHist_" + stateStr
	DoWindow/K $winName
	Display/K=1/N=$winName
	
	Variable i, r, g, b
	String smpl, resultsPath
	String traceName, traceSemName, traceXName
	String traceList = "", labelList = ""
	
	SetDataFolder root:Comparison
	
	for(i = 0; i < numSamples; i += 1)
		smpl = StringFromList(i, sampleList)
		resultsPath = "root:" + smpl + ":Results:"
		
		Wave/Z hist_avg = $(resultsPath + hist_avg_name)
		Wave/Z hist_sem = $(resultsPath + hist_sem_name)
		Wave/Z hist_x = $(resultsPath + hist_x_name)
		
		if(!WaveExists(hist_avg))
			Print "LP_Phist waves not found for: " + smpl + " (" + stateStr + ")"
			continue
		endif
		
		traceName = smpl + "_LPHist_" + stateStr
		traceSemName = smpl + "_LPHistSem_" + stateStr
		traceXName = smpl + "_LPHistX_" + stateStr

		Duplicate/O hist_avg, $traceName
		Wave histW = $traceName

		if(WaveExists(hist_x))
			Duplicate/O hist_x, $traceXName
		else
			NVAR LPhistBin = root:LPhistBin
			Variable binSize = LPhistBin * 0.001
			Make/O/N=(numpnts(histW)) $traceXName
			Wave xW = $traceXName
			xW = (p + 0.5) * binSize
		endif
		Wave xW = $traceXName
		
		if(WaveExists(hist_sem))
			Duplicate/O hist_sem, $traceSemName
		else
			Make/O/N=(numpnts(histW)) $traceSemName = 0
		endif
		Wave semW = $traceSemName
		
		AppendToGraph histW vs xW
		
		// HMM state
		GetStateColorWithShade(stateNum, i, numSamples, r, g, b)
		ModifyGraph rgb($traceName)=(r, g, b)
		ModifyGraph mode($traceName)=0, lsize($traceName)=1.5
		
		// Error bar with shading
		ErrorBars $traceName SHADE= {0,4,(r,g,b,32768),(r,g,b,32768)},wave=(semW, semW)
		
		// 
		traceList = AddListItem(traceName, traceList, ";", inf)
		labelList = AddListItem(smpl, labelList, ";", inf)
	endfor
	
	// 
	CreateSampleLegendWithTraces(traceList, labelList)
	
	SetStandardGraphStyle()
	Label left "Probability Density"
	Label bottom "Localization Precision [µm]"
	SetAxis left 0, *
	SetAxis bottom 0, *
	
	// 
	NVAR DstateVar = root:Dstate
	Variable totalStates = DstateVar
	String stateName = GetDstateName(stateNum, totalStates)
	DoWindow/T $winName, "Average LP Histogram (" + stateName + ")"
	
	SetDataFolder root:
	Print "Average LP Hist plot completed for " + stateName
	return 0
End

// StateLP Histogram
Function AverageLPHistPerSample(smpl)
	String smpl
	
	NVAR/Z Dstate = root:Dstate
	NVAR/Z cHMM = root:cHMM
	
	Variable maxState = 0
	if(NVAR_Exists(cHMM) && cHMM == 1 && NVAR_Exists(Dstate))
		maxState = Dstate
	endif
	
	String resultsPath = "root:" + smpl + ":Results:"
	
	// 
	Make/FREE/N=(6,3) stateColors
	stateColors[0][0] = 0;       stateColors[0][1] = 0;       stateColors[0][2] = 0
	stateColors[1][0] = 0;       stateColors[1][1] = 0;       stateColors[1][2] = 65280
	stateColors[2][0] = 65280;   stateColors[2][1] = 43520;   stateColors[2][2] = 0
	stateColors[3][0] = 0;       stateColors[3][1] = 39168;   stateColors[3][2] = 0
	stateColors[4][0] = 65280;   stateColors[4][1] = 0;       stateColors[4][2] = 0
	stateColors[5][0] = 65280;   stateColors[5][1] = 0;       stateColors[5][2] = 65280
	
	String winName = "AverageLPHist_" + smpl
	DoWindow/K $winName
	
	Variable s, firstPlot = 1
	String stateStr, hist_avg_name, hist_sem_name, hist_x_name
	String traceName, traceSemName, traceXName
	
	EnsureComparisonFolder()
	SetDataFolder root:Comparison
	
	for(s = 0; s <= maxState; s += 1)
		stateStr = "S" + num2str(s)
		hist_avg_name = "LP_" + stateStr + "_Phist_m_avg"
		hist_sem_name = "LP_" + stateStr + "_Phist_m_sem"
		hist_x_name = "LP_" + stateStr + "_X_m_avg"
		
		Wave/Z hist_avg = $(resultsPath + hist_avg_name)
		Wave/Z hist_sem = $(resultsPath + hist_sem_name)
		Wave/Z hist_x = $(resultsPath + hist_x_name)
		
		if(!WaveExists(hist_avg))
			continue
		endif
		
		traceName = smpl + "_" + stateStr + "_lpHist"
		traceXName = smpl + "_" + stateStr + "_lpHistX"
		traceSemName = smpl + "_" + stateStr + "_lpHistSem"

		Duplicate/O hist_avg, $traceName
		Wave histW = $traceName

		if(WaveExists(hist_x))
			Duplicate/O hist_x, $traceXName
		else
			NVAR LPhistBin = root:LPhistBin
			Variable binSize = LPhistBin * 0.001
			Make/O/N=(numpnts(histW)) $traceXName
			Wave xW = $traceXName
			xW = (p + 0.5) * binSize
		endif
		Wave xW = $traceXName
		
		if(WaveExists(hist_sem))
			Duplicate/O hist_sem, $traceSemName
		else
			Make/O/N=(numpnts(histW)) $traceSemName = 0
		endif
		Wave semW = $traceSemName
		
		if(firstPlot)
			Display/K=1/N=$winName histW vs xW
			firstPlot = 0
		else
			AppendToGraph histW vs xW
		endif
		
		// Error bar with shading
		ErrorBars $traceName SHADE= {0,4,(stateColors[s][0],stateColors[s][1],stateColors[s][2],32768),(stateColors[s][0],stateColors[s][1],stateColors[s][2],32768)},wave=(semW, semW)
		ModifyGraph mode($traceName)=0, lsize($traceName)=1.5
		ModifyGraph rgb($traceName)=(stateColors[s][0], stateColors[s][1], stateColors[s][2])
	endfor
	
	if(firstPlot)
		Print "No LP Hist data found for: " + smpl
		SetDataFolder root:
		return -1
	endif
	
	SetStandardGraphStyle()
	Label left "Probability Density"
	Label bottom "Localization Precision [µm]"
	SetAxis left 0, *
	SetAxis bottom 0, *
	DoWindow/T $winName, smpl + " Average LP Histogram (all states)"
	
	// 
	String legendStr = "\\F'Arial'\\Z12"
	String stateName
	for(s = 0; s <= maxState; s += 1)
		stateStr = "S" + num2str(s)
		traceName = smpl + "_" + stateStr + "_lpHist"
		Wave/Z tw = root:Comparison:$traceName
		if(WaveExists(tw))
			stateName = GetDstateName(s, maxState)
			if(s == 0)
				legendStr += "\\s(" + traceName + ") " + stateName
			else
				legendStr += "\r\\s(" + traceName + ") " + stateName
			endif
		endif
	endfor
	TextBox/C/N=legend0/F=0/B=1/A=RT legendStr
	
	SetDataFolder root:
	return 0
End

// =============================================================================
// Average On-time (Duration) - On-time
// =============================================================================
Function AverageOntime()
	// : Core
	return AverageOntimeCore("root", "")
End

// -----------------------------------------------------------------------------
// AverageOntimeCore - On-time
// basePath: "root"  "root:Seg0" 
// waveSuffix: ""  "_Seg0" 
// -----------------------------------------------------------------------------
Function AverageOntimeCore(basePath, waveSuffix)
	String basePath, waveSuffix
	
	EnsureComparisonFolder()
	
	// 
	String sampleList
	if(StringMatch(basePath, "root"))
		sampleList = GetSampleFolderList()
	else
		sampleList = GetSampleFolderListFromPath(basePath)
	endif
	Variable numSamples = ItemsInList(sampleList)
	
	if(numSamples == 0)
		Print "No samples found" + SelectString(StringMatch(basePath, "root"), " in " + basePath, "")
		return -1
	endif
	
	String segLabel = GetSegmentLabel(waveSuffix)
	
	// WavewaveSuffix
	String pdur_avg_name = "P_Duration" + waveSuffix + "_m_avg"
	String pdur_sem_name = "P_Duration" + waveSuffix + "_m_sem"
	String time_avg_name = "time_Duration" + waveSuffix + "_m_avg"
	
	String winName = "AverageOntime" + waveSuffix
	DoWindow/K $winName
	Display/K=1/N=$winName
	
	Variable i, r, g, b
	String smpl, resultsPath
	String traceName, traceSemName, traceXName
	String traceList = "", labelList = ""
	
	SetDataFolder root:Comparison
	
	for(i = 0; i < numSamples; i += 1)
		smpl = StringFromList(i, sampleList)
		if(StringMatch(basePath, "root"))
			resultsPath = "root:" + smpl + ":Results:"
		else
			resultsPath = basePath + ":" + smpl + ":Results:"
		endif
		
		Wave/Z pdur_avg = $(resultsPath + pdur_avg_name)
		Wave/Z pdur_sem = $(resultsPath + pdur_sem_name)
		Wave/Z time_avg = $(resultsPath + time_avg_name)
		
		if(!WaveExists(pdur_avg))
			Print "P_Duration waves not found for: " + smpl
			continue
		endif
		
		traceName = smpl + "_PDur" + waveSuffix
		traceSemName = smpl + "_PDurSem" + waveSuffix
		traceXName = smpl + "_TimeDur" + waveSuffix
		
		Duplicate/O pdur_avg, $traceName
		Wave durW = $traceName
		
		if(WaveExists(time_avg))
			Duplicate/O time_avg, $traceXName
		else
			NVAR framerate = root:framerate
			Variable fr = framerate
			Make/O/N=(numpnts(durW)) $traceXName
			Wave xW = $traceXName
			xW = (p + 1) * fr
		endif
		Wave xW = $traceXName
		
		if(WaveExists(pdur_sem))
			Duplicate/O pdur_sem, $traceSemName
		else
			Make/O/N=(numpnts(durW)) $traceSemName = 0
		endif
		Wave semW = $traceSemName
		
		AppendToGraph durW vs xW
		
		GetSampleColor(i, r, g, b)
		ModifyGraph rgb($traceName)=(r, g, b)
		ModifyGraph mode($traceName)=3, marker($traceName)=19, msize($traceName)=2
		ErrorBars $traceName SHADE= {0,4,(r,g,b,32768),(r,g,b,32768)},wave=(semW, semW)
		
		traceList = AddListItem(traceName, traceList, ";", inf)
		labelList = AddListItem(smpl, labelList, ";", inf)
	endfor
	
	if(strlen(traceList) == 0)
		Print "WARNING: No data found for AverageOntime [" + segLabel + "]"
		DoWindow/K $winName
		SetDataFolder root:
		return -1
	endif
	
	// 
	for(i = 0; i < numSamples; i += 1)
		smpl = StringFromList(i, sampleList)
		if(StringMatch(basePath, "root"))
			resultsPath = "root:" + smpl + ":Results:"
		else
			resultsPath = basePath + ":" + smpl + ":Results:"
		endif
		
		Wave/Z pdur_avg = $(resultsPath + pdur_avg_name)
		Wave/Z time_avg = $(resultsPath + time_avg_name)
		
		if(!WaveExists(pdur_avg) || !WaveExists(time_avg))
			continue
		endif
		
		// 
		String fitWaveName = "fit_" + pdur_avg_name
		FitAverageDuration(pdur_avg, time_avg, resultsPath, fitWaveName)
		
		// 
		Wave/Z fit_avg = $(resultsPath + fitWaveName)
		if(WaveExists(fit_avg))
			String fitTraceName = smpl + "_FitPDur" + waveSuffix
			
			SetDataFolder root:Comparison
			Duplicate/O fit_avg, $fitTraceName
			Wave fitW = $fitTraceName
			
			// NaN
			Variable nFitPts = numpnts(fitW)
			Variable tMin = NaN, tMax = NaN
			Variable numTimePts = numpnts(time_avg)
			Variable pt
			for(pt = 0; pt < numTimePts; pt += 1)
				if(numtype(pdur_avg[pt]) == 0)
					if(numtype(tMin) != 0)
						tMin = time_avg[pt]
					endif
					tMax = time_avg[pt]
				endif
			endfor
			
			// X
			String fitXName = smpl + "_FitTimeDur" + waveSuffix
			Make/O/N=(nFitPts) $fitXName
			Wave fitXW = $fitXName
			if(numtype(tMin) == 0 && numtype(tMax) == 0)
				fitXW = tMin + p * (tMax - tMin) / (nFitPts - 1)
			endif
			
			AppendToGraph fitW vs fitXW
			
			GetSampleColor(i, r, g, b)
			ModifyGraph rgb($fitTraceName)=(r, g, b)
			ModifyGraph lsize($fitTraceName)=1.5
		endif
	endfor
	
	CreateSampleLegendWithTraces(traceList, labelList)
	
	SetStandardGraphStyle()
	ModifyGraph log(left)=1
	Label left "Survival Probability [%]"
	Label bottom "Time [s]"
	SetAxis left 0.1, 100
	
	String titleSuffix = SelectString(strlen(waveSuffix) > 0, "", " [" + segLabel + "]")
	DoWindow/T $winName, "Average On-time Distribution" + titleSuffix
	
	SetDataFolder root:
	Print "Average On-time plot completed" + titleSuffix
	return 0
End

// -----------------------------------------------------------------------------
// FitAverageDuration - On-time
// -----------------------------------------------------------------------------
Function FitAverageDuration(dataWave, timeWave, outputPath, outputName)
	Wave dataWave, timeWave
	String outputPath, outputName
	
	// 
	FitSumExpAIC(dataWave, timeWave, outputPath, outputName)
End

// -----------------------------------------------------------------------------
// FitAverageOnrate - On-rate
// -----------------------------------------------------------------------------
Function FitAverageOnrate(dataWave, timeWave, outputPath, outputName)
	Wave dataWave, timeWave
	String outputPath, outputName
	
	Variable numPts = numpnts(dataWave)
	
	String savedDF = GetDataFolder(1)
	SetDataFolder $outputPath
	
	// Batch
	NVAR/Z InitialTauon = root:InitialTauon
	NVAR/Z InitialVon = root:InitialVon
	
	// root
	// w[0] = tau ()
	// w[1] = V0 ()
	Variable initTau = NVAR_Exists(InitialTauon) ? InitialTauon : timeWave[numPts/2]
	Variable initV0 = NVAR_Exists(InitialVon) ? InitialVon : dataWave[numPts-1]
	
	// 
	WaveStats/Q/Z dataWave
	if(V_max > 0)
		initV0 = V_max
	endif
	
	Make/O/D/N=2 W_coef_onrate = {initTau, initV0}
	
	// 
	Make/O/T/N=2 T_Constraints_onrate = {"K0 > 0", "K1 > 0"}
	
	// 
	Variable V_FitError = 0
	try
		AbortOnRTE
		FuncFit/Q/N/W=2 OnrateFitFunc, W_coef_onrate, dataWave /X=timeWave /D /C=T_Constraints_onrate; AbortOnRTE
	catch
		V_FitError = 1
	endtry
	
	if(V_FitError == 0)
		// 
		Variable FitPts = numPts * 10
		Make/O/N=(FitPts) $outputName
		Wave fitWave = $outputName
		
		Variable tMin = timeWave[0]
		Variable tMax = timeWave[numPts-1]
		Variable dt = (tMax - tMin) / (FitPts - 1)
		
		// X
		SetScale/P x, tMin, dt, fitWave
		
		Variable pt
		for(pt = 0; pt < FitPts; pt += 1)
			Variable tVal = tMin + pt * dt
			fitWave[pt] = OnrateFitFunc(W_coef_onrate, tVal)
		endfor
		
		Printf "  Avg On-rate fit: tau=%.3f s, V0=%.1f\r", W_coef_onrate[0], W_coef_onrate[1]
	endif
	
	// 
	KillWaves/Z W_coef_onrate, T_Constraints_onrate
	
	SetDataFolder $savedDF
End

// =============================================================================
// Average On-rate - On-rate
// =============================================================================
Function AverageOnrate(stateNum)
	Variable stateNum
	
	// : Core
	return AverageOnrateCore(stateNum, "root", "")
End

// -----------------------------------------------------------------------------
// AverageOnrateCore - On-rate
// stateNum: HMM
// basePath: "root"  "root:Seg0" 
// waveSuffix: ""  "_Seg0" 
// -----------------------------------------------------------------------------
Function AverageOnrateCore(stateNum, basePath, waveSuffix)
	Variable stateNum
	String basePath, waveSuffix
	
	EnsureComparisonFolder()
	
	// 
	String sampleList
	if(StringMatch(basePath, "root"))
		sampleList = GetSampleFolderList()
	else
		sampleList = GetSampleFolderListFromPath(basePath)
	endif
	Variable numSamples = ItemsInList(sampleList)
	
	if(numSamples == 0)
		Print "No samples found" + SelectString(StringMatch(basePath, "root"), " in " + basePath, "")
		return -1
	endif
	
	String stateStr = "S" + num2str(stateNum)
	String segLabel = GetSegmentLabel(waveSuffix)
	
	// WavewaveSuffix
	// root: CumOnEvent_S0_m_avg, Seg: CumOnEvent_S0_Seg0_m_avg
	String cumon_avg_name = "CumOnEvent_" + stateStr + waveSuffix + "_m_avg"
	String cumon_sem_name = "CumOnEvent_" + stateStr + waveSuffix + "_m_sem"
	String time_avg_name = "time_onrate_" + stateStr + waveSuffix + "_m_avg"
	
	String winName = "AverageOnrate_" + stateStr + waveSuffix
	DoWindow/K $winName
	Display/K=1/N=$winName
	
	Variable i, r, g, b
	String smpl, resultsPath
	String traceName, traceSemName, traceXName
	String traceList = "", labelList = ""
	
	SetDataFolder root:Comparison
	
	for(i = 0; i < numSamples; i += 1)
		smpl = StringFromList(i, sampleList)
		if(StringMatch(basePath, "root"))
			resultsPath = "root:" + smpl + ":Results:"
		else
			resultsPath = basePath + ":" + smpl + ":Results:"
		endif
		
		Wave/Z cumon_avg = $(resultsPath + cumon_avg_name)
		Wave/Z cumon_sem = $(resultsPath + cumon_sem_name)
		Wave/Z time_avg = $(resultsPath + time_avg_name)
		
		if(!WaveExists(cumon_avg))
			Print "CumOnEvent waves not found for: " + smpl + " (" + stateStr + ")"
			continue
		endif
		
		traceName = smpl + "_CumOnrate_" + stateStr + waveSuffix
		traceSemName = smpl + "_CumOnrateSem_" + stateStr + waveSuffix
		traceXName = smpl + "_TimeOnrate_" + stateStr + waveSuffix
		
		Duplicate/O cumon_avg, $traceName
		Wave onW = $traceName
		
		if(WaveExists(time_avg))
			Duplicate/O time_avg, $traceXName
		else
			NVAR framerate = root:framerate
			Variable fr = framerate
			Make/O/N=(numpnts(onW)) $traceXName
			Wave xW = $traceXName
			xW = (p + 1) * fr
		endif
		Wave xW = $traceXName
		
		if(WaveExists(cumon_sem))
			Duplicate/O cumon_sem, $traceSemName
		else
			Make/O/N=(numpnts(onW)) $traceSemName = 0
		endif
		Wave semW = $traceSemName
		
		AppendToGraph onW vs xW
		
		// HMM state
		GetStateColorWithShade(stateNum, i, numSamples, r, g, b)
		ModifyGraph rgb($traceName)=(r, g, b)
		ModifyGraph mode($traceName)=0, lsize($traceName)=1.5
		ErrorBars $traceName SHADE= {0,4,(r,g,b,32768),(r,g,b,32768)},wave=(semW, semW)
		
		traceList = AddListItem(traceName, traceList, ";", inf)
		labelList = AddListItem(smpl, labelList, ";", inf)
	endfor
	
	if(strlen(traceList) == 0)
		Print "WARNING: No data found for AverageOnrate " + stateStr + " [" + segLabel + "]"
		DoWindow/K $winName
		SetDataFolder root:
		return -1
	endif
	
	// 
	for(i = 0; i < numSamples; i += 1)
		smpl = StringFromList(i, sampleList)
		if(StringMatch(basePath, "root"))
			resultsPath = "root:" + smpl + ":Results:"
		else
			resultsPath = basePath + ":" + smpl + ":Results:"
		endif
		
		Wave/Z cumon_avg = $(resultsPath + cumon_avg_name)
		Wave/Z time_avg = $(resultsPath + time_avg_name)
		
		if(!WaveExists(cumon_avg) || !WaveExists(time_avg))
			continue
		endif
		
		// 
		String fitWaveName = "fit_" + cumon_avg_name
		FitAverageOnrate(cumon_avg, time_avg, resultsPath, fitWaveName)
		
		// 
		Wave/Z fit_avg = $(resultsPath + fitWaveName)
		if(WaveExists(fit_avg))
			String fitTraceName = smpl + "_FitOnrate_" + stateStr + waveSuffix
			
			SetDataFolder root:Comparison
			Duplicate/O fit_avg, $fitTraceName
			Wave fitW = $fitTraceName
			
			// X
			Variable nFitPts = numpnts(fitW)
			String fitXName = smpl + "_FitTimeOnrate_" + stateStr + waveSuffix
			Make/O/N=(nFitPts) $fitXName
			Wave fitXW = $fitXName
			Variable tMin = time_avg[0]
			Variable tMax = time_avg[numpnts(time_avg)-1]
			fitXW = tMin + p * (tMax - tMin) / (nFitPts - 1)
			
			AppendToGraph fitW vs fitXW
			
			GetStateColorWithShade(stateNum, i, numSamples, r, g, b)
			ModifyGraph rgb($fitTraceName)=(r, g, b)
			ModifyGraph lsize($fitTraceName)=2
		endif
	endfor
	
	CreateSampleLegendWithTraces(traceList, labelList)
	
	SetStandardGraphStyle()
	Label left "Cum. On events"
	Label bottom "Time [s]"
	SetAxis left 0, *
	
	// 
	NVAR DstateVar = root:Dstate
	Variable totalStates = DstateVar
	String stateName = GetDstateName(stateNum, totalStates)
	String titleSuffix = SelectString(strlen(waveSuffix) > 0, "", " [" + segLabel + "]")
	DoWindow/T $winName, "Average Cumulative On-events (" + stateName + ")" + titleSuffix
	
	SetDataFolder root:
	Print "Average On-rate plot completed for " + stateName + titleSuffix
	return 0
End

// StateOn-rate
Function AverageOnratePerSample(smpl)
	String smpl
	
	NVAR/Z Dstate = root:Dstate
	NVAR/Z cHMM = root:cHMM
	
	Variable maxState = 0
	if(NVAR_Exists(cHMM) && cHMM == 1 && NVAR_Exists(Dstate))
		maxState = Dstate
	endif
	
	String resultsPath = "root:" + smpl + ":Results:"
	
	Make/FREE/N=(6,3) stateColors
	stateColors[0][0] = 0;       stateColors[0][1] = 0;       stateColors[0][2] = 0
	stateColors[1][0] = 0;       stateColors[1][1] = 0;       stateColors[1][2] = 65280
	stateColors[2][0] = 65280;   stateColors[2][1] = 43520;   stateColors[2][2] = 0
	stateColors[3][0] = 0;       stateColors[3][1] = 39168;   stateColors[3][2] = 0
	stateColors[4][0] = 65280;   stateColors[4][1] = 0;       stateColors[4][2] = 0
	stateColors[5][0] = 65280;   stateColors[5][1] = 0;       stateColors[5][2] = 65280
	
	String winName = "AverageOnrate_" + smpl
	DoWindow/K $winName
	
	Variable s, firstPlot = 1
	String stateStr, suffix, cumon_avg_name, cumon_sem_name, time_avg_name
	String traceName, traceSemName, traceXName
	
	EnsureComparisonFolder()
	SetDataFolder root:Comparison
	
	for(s = 0; s <= maxState; s += 1)
		stateStr = "S" + num2str(s)
		suffix = "_" + stateStr
		cumon_avg_name = "CumOnEvent" + suffix + "_m_avg"
		cumon_sem_name = "CumOnEvent" + suffix + "_m_sem"
		time_avg_name = "time_onrate" + suffix + "_m_avg"
		
		Wave/Z cumon_avg = $(resultsPath + cumon_avg_name)
		Wave/Z cumon_sem = $(resultsPath + cumon_sem_name)
		Wave/Z time_avg = $(resultsPath + time_avg_name)
		
		if(!WaveExists(cumon_avg))
			continue
		endif
		
		traceName = smpl + "_" + stateStr + "_CumOn"
		traceSemName = smpl + "_" + stateStr + "_CumOnSem"
		traceXName = smpl + "_" + stateStr + "_TimeOn"
		
		Duplicate/O cumon_avg, $traceName
		Wave onW = $traceName
		
		if(WaveExists(time_avg))
			Duplicate/O time_avg, $traceXName
		else
			NVAR framerate = root:framerate
			Variable fr = framerate
			Make/O/N=(numpnts(onW)) $traceXName
			Wave xW = $traceXName
			xW = (p + 1) * fr
		endif
		Wave xW = $traceXName
		
		if(WaveExists(cumon_sem))
			Duplicate/O cumon_sem, $traceSemName
		else
			Make/O/N=(numpnts(onW)) $traceSemName = 0
		endif
		Wave semW = $traceSemName
		
		if(firstPlot)
			Display/K=1/N=$winName onW vs xW
			firstPlot = 0
		else
			AppendToGraph onW vs xW
		endif
		
		// Error bar with shading
		ErrorBars $traceName SHADE= {0,4,(stateColors[s][0],stateColors[s][1],stateColors[s][2],32768),(stateColors[s][0],stateColors[s][1],stateColors[s][2],32768)},wave=(semW, semW)
		ModifyGraph mode($traceName)=0, lsize($traceName)=1.5
		ModifyGraph rgb($traceName)=(stateColors[s][0], stateColors[s][1], stateColors[s][2])
	endfor
	
	if(firstPlot)
		Print "No On-rate data found for: " + smpl
		SetDataFolder root:
		return -1
	endif
	
	SetStandardGraphStyle()
	Label left "Cum. On events"
	Label bottom "Time [s]"
	SetAxis left 0, *
	DoWindow/T $winName, smpl + " Average On-events (all states)"
	
	// 
	String legendStr = "\\F'Arial'\\Z12"
	String stateName
	for(s = 0; s <= maxState; s += 1)
		stateStr = "S" + num2str(s)
		traceName = smpl + "_" + stateStr + "_CumOn"
		Wave/Z tw = root:Comparison:$traceName
		if(WaveExists(tw))
			stateName = GetDstateName(s, maxState)
			if(s == 0)
				legendStr += "\\s(" + traceName + ") " + stateName
			else
				legendStr += "\r\\s(" + traceName + ") " + stateName
			endif
		endif
	endfor
	TextBox/C/N=legend0/F=0/B=1/A=RT legendStr
	
	SetDataFolder root:
	return 0
End

// =============================================================================
// Average Mol Density - Molecular Density
// =============================================================================
// MolDensDist 
Function AverageMolDensHist(stateNum)
	Variable stateNum
	
	EnsureComparisonFolder()
	
	String sampleList = GetSampleFolderList()
	Variable numSamples = ItemsInList(sampleList)
	
	if(numSamples == 0)
		Print "No samples found"
		return -1
	endif
	
	String stateStr = "S" + num2str(stateNum)
	// Wave: MolDensDist_Sn
	String hist_avg_name = "MolDensDist_" + stateStr + "_m_avg"
	String hist_sem_name = "MolDensDist_" + stateStr + "_m_sem"
	
	String winName = "AverageMolDensHist_" + stateStr
	DoWindow/K $winName
	Display/K=1/N=$winName
	
	Variable i, r, g, b
	String smpl, resultsPath
	String traceName, traceSemName, traceXName
	String traceList = "", labelList = ""
	
	SetDataFolder root:Comparison
	
	for(i = 0; i < numSamples; i += 1)
		smpl = StringFromList(i, sampleList)
		resultsPath = "root:" + smpl + ":Results:"
		
		Wave/Z hist_avg = $(resultsPath + hist_avg_name)
		Wave/Z hist_sem = $(resultsPath + hist_sem_name)
		
		if(!WaveExists(hist_avg))
			Print "MolDensDist histogram not found for: " + smpl + " (" + stateStr + ")"
			continue
		endif
		
		traceName = smpl + "_MolDensDist_" + stateStr
		traceSemName = smpl + "_MolDensDistSem_" + stateStr
		traceXName = smpl + "_MolDensDistX_" + stateStr
		
		Duplicate/O hist_avg, $traceName
		Wave histW = $traceName
		
		// X: 1, 2, 3, ... (oligomer size = monomer, dimer, trimer, ...)
		Make/O/N=(numpnts(histW)) $traceXName
		Wave xW = $traceXName
		xW = p + 1
		
		if(WaveExists(hist_sem))
			Duplicate/O hist_sem, $traceSemName
		else
			Make/O/N=(numpnts(histW)) $traceSemName = 0
		endif
		Wave semW = $traceSemName
		
		AppendToGraph histW vs xW
		
		// HMM state
		GetStateColorWithShade(stateNum, i, numSamples, r, g, b)
		ModifyGraph rgb($traceName)=(r, g, b)
		// mode=4: markers+lines (Single Analysis)
		ModifyGraph mode($traceName)=4, marker($traceName)=19, msize($traceName)=3
		ModifyGraph lsize($traceName)=1.5
		
		// Error bar with shading
		ErrorBars $traceName SHADE= {0,4,(r,g,b,32768),(r,g,b,32768)},wave=(semW, semW)
		
		// 
		traceList = AddListItem(traceName, traceList, ";", inf)
		labelList = AddListItem(smpl, labelList, ";", inf)
	endfor
	
	// 
	CreateSampleLegendWithTraces(traceList, labelList)
	
	ModifyGraph tick=2, mirror=0, fStyle=1, fSize=14, font="Arial"
	ModifyGraph width={Aspect, 1.618}
	Label left "Molecular Density (/µm\\S2\\M)"
	Label bottom "Oligomer Size"
	SetAxis left 0, *
	
	// 
	NVAR DstateVar = root:Dstate
	Variable totalStates = DstateVar
	String stateName = GetDstateName(stateNum, totalStates)
	DoWindow/T $winName, "Average Molecular Density Distribution (" + stateName + ")"
	
	SetDataFolder root:
	return 0
End

// State FractionD-state
Function AverageMolDensFraction()
	EnsureComparisonFolder()
	
	String sampleList = GetSampleFolderList()
	Variable numSamples = ItemsInList(sampleList)
	
	if(numSamples == 0)
		Print "No samples found"
		return -1
	endif
	
	// Wave: StateFraction
	String frac_avg_name = "StateFraction_m_avg"
	String frac_sem_name = "StateFraction_m_sem"
	
	String winName = "AverageStateFraction"
	DoWindow/K $winName
	Display/K=1/N=$winName
	
	Variable i, r, g, b
	String smpl, resultsPath
	String traceName, traceSemName, traceXName
	String traceList = "", labelList = ""
	
	NVAR Dstate = root:Dstate
	Variable maxState = Dstate
	
	SetDataFolder root:Comparison
	
	// X labels (skip S0=100%, start from S1)
	Make/O/T/N=(maxState) MolDens_StateLabels
	Variable s
	for(s = 1; s <= maxState; s += 1)
		MolDens_StateLabels[s-1] = GetDstateName(s, maxState)
	endfor
	
	for(i = 0; i < numSamples; i += 1)
		smpl = StringFromList(i, sampleList)
		resultsPath = "root:" + smpl + ":Results:"
		
		Wave/Z frac_avg = $(resultsPath + frac_avg_name)
		Wave/Z frac_sem = $(resultsPath + frac_sem_name)
		
		if(!WaveExists(frac_avg))
			Print "StateFraction not found for: " + smpl
			continue
		endif
		
		traceName = smpl + "_StateFrac"
		traceSemName = smpl + "_StateFracSem"
		
		// Extract S1-Sn only (skip S0)
		Make/O/N=(maxState) $traceName = NaN
		Wave fracW = $traceName
		fracW = frac_avg[p+1]
		
		if(WaveExists(frac_sem))
			Make/O/N=(maxState) $traceSemName = 0
			Wave semW = $traceSemName
			semW = frac_sem[p+1]
		else
			Make/O/N=(maxState) $traceSemName = 0
		endif
		Wave semW = $traceSemName
		
		AppendToGraph fracW vs MolDens_StateLabels
		
		// 
		Variable sr, sg, sb
		GetSampleColor(i, sr, sg, sb)
		
		// mode=5: bars ()
		ModifyGraph mode($traceName)=5, hbFill($traceName)=2
		ModifyGraph rgb($traceName)=(sr, sg, sb)
		ModifyGraph useBarStrokeRGB($traceName)=1, barStrokeRGB($traceName)=(0,0,0)
		
		// Error bars
		ErrorBars $traceName Y,wave=(semW, semW)
		
		// 
		traceList = AddListItem(traceName, traceList, ";", inf)
		labelList = AddListItem(smpl, labelList, ";", inf)
	endfor
	
	// 
	CreateSampleLegendWithTraces(traceList, labelList)
	
	ModifyGraph tick=2, mirror=0, fStyle=1, fSize=14, font="Arial"
	ModifyGraph tick(bottom)=3
	ModifyGraph catGap(bottom)=0.3, barGap(bottom)=0.1
	
	// State× (S1-Sn only)
	Variable totalBarsF = maxState * numSamples
	SetBarGraphSizeByItems(totalBarsF)
	
	Label left "State Fraction [%]"
	Label bottom "Diffusion State"
	SetAxis left 0, *
	DoWindow/T $winName, "Average State Fraction"
	
	SetDataFolder root:
	return 0
End

// Particle vs Molecular Density 
Function AverageParticleVsMolDens()
	EnsureComparisonFolder()
	
	String sampleList = GetSampleFolderList()
	Variable numSamples = ItemsInList(sampleList)
	
	if(numSamples == 0)
		Print "No samples found"
		return -1
	endif
	
	String winName = "AverageParticleVsMolDens"
	DoWindow/K $winName
	Display/K=1/N=$winName
	
	Variable i, r, g, b
	String smpl, resultsPath
	String traceNameP, traceNameM, traceSemP, traceSemM
	String traceList = "", labelList = ""
	
	SetDataFolder root:Comparison
	
	// 
	Make/O/T/N=2 DensityLabels = {"Particle", "Molecular"}
	
	for(i = 0; i < numSamples; i += 1)
		smpl = StringFromList(i, sampleList)
		resultsPath = "root:" + smpl + ":Results:"
		
		// Wave: ParaDensityAvg5, MolDensitySummary4
		Wave/Z ParaDensAvg = $(resultsPath + "ParaDensityAvg_m_avg")
		Wave/Z ParaDensSem = $(resultsPath + "ParaDensityAvg_m_sem")
		Wave/Z MolDensSummary = $(resultsPath + "MolDensitySummary_m_avg")
		Wave/Z MolDensSummarySem = $(resultsPath + "MolDensitySummary_m_sem")
		
		if(!WaveExists(ParaDensAvg) || !WaveExists(MolDensSummary))
			Print "Density data not found for: " + smpl
			continue
		endif
		
		// 2
		String densTraceName = smpl + "_PvM"
		String densSemName = smpl + "_PvMSem"
		
		Make/O/N=2 $densTraceName
		Make/O/N=2 $densSemName
		Wave densW = $densTraceName
		Wave semW = $densSemName
		
		// ParaDensityAvg[2] = Density [/um²]
		// MolDensitySummary[1] = TotalMolDensity [/um²]
		densW[0] = ParaDensAvg[2]
		densW[1] = MolDensSummary[1]
		
		if(WaveExists(ParaDensSem) && WaveExists(MolDensSummarySem))
			semW[0] = ParaDensSem[2]
			semW[1] = MolDensSummarySem[1]
		else
			semW = 0
		endif
		
		AppendToGraph densW vs DensityLabels
		ErrorBars $densTraceName Y,wave=(semW, semW)
		
		GetSampleColor(i, r, g, b)
		ModifyGraph rgb($densTraceName)=(r, g, b)
		// mode=5: bars ()
		ModifyGraph mode($densTraceName)=5, hbFill($densTraceName)=2
		ModifyGraph useBarStrokeRGB($densTraceName)=1, barStrokeRGB($densTraceName)=(0,0,0)
		
		// 
		traceList = AddListItem(densTraceName, traceList, ";", inf)
		labelList = AddListItem(smpl, labelList, ";", inf)
	endfor
	
	// 
	CreateSampleLegendWithTraces(traceList, labelList)
	
	ModifyGraph tick=2, mirror=0, fStyle=1, fSize=14, font="Arial"
	ModifyGraph tick(bottom)=3
	ModifyGraph catGap(bottom)=0.3, barGap(bottom)=0.1
	
	// (2)×
	Variable totalBarsD = 2 * numSamples
	SetBarGraphSizeByItems(totalBarsD)
	
	Label left "Density (/µm\\S2\\M)"
	SetAxis left 0, *
	DoWindow/T $winName, "Average Particle vs Molecular Density"
	
	SetDataFolder root:
	return 0
End

// D-stateParticle vs Molecular DensitySingle Analysis
Function AverageParticleVsMolDensByState(smpl)
	String smpl
	
	NVAR Dstate = root:Dstate
	Variable maxState = Dstate
	
	String resultsPath = "root:" + smpl + ":Results:"
	
	Wave/Z ParticleDens = $(resultsPath + "ParticleDensity_Dstate_m_avg")
	Wave/Z ParticleDensSem = $(resultsPath + "ParticleDensity_Dstate_m_sem")
	Wave/Z MolDens = $(resultsPath + "MolDensity_Dstate_m_avg")
	Wave/Z MolDensSem = $(resultsPath + "MolDensity_Dstate_m_sem")
	
	if(!WaveExists(ParticleDens) || !WaveExists(MolDens))
		Print "Density waves not found for: " + smpl
		return -1
	endif
	
	EnsureComparisonFolder()
	SetDataFolder root:Comparison
	
	String winName = "AvgPvMByState_" + smpl
	DoWindow/K $winName
	
	// 
	Make/O/T/N=(maxState + 1) PvM_StateLabels
	Variable s
	for(s = 0; s <= maxState; s += 1)
		PvM_StateLabels[s] = GetDstateName(s, maxState)
	endfor
	
	// Wave
	String pName = smpl + "_PartDens"
	String mName = smpl + "_MolDens"
	String pSemName = smpl + "_PartDensSem"
	String mSemName = smpl + "_MolDensSem"
	
	Duplicate/O ParticleDens, $pName
	Duplicate/O MolDens, $mName
	Wave pW = $pName
	Wave mW = $mName
	
	if(WaveExists(ParticleDensSem))
		Duplicate/O ParticleDensSem, $pSemName
	else
		Make/O/N=(maxState+1) $pSemName = 0
	endif
	if(WaveExists(MolDensSem))
		Duplicate/O MolDensSem, $mSemName
	else
		Make/O/N=(maxState+1) $mSemName = 0
	endif
	Wave pSem = $pSemName
	Wave mSem = $mSemName
	
	Display/K=1/N=$winName pW vs PvM_StateLabels
	AppendToGraph mW vs PvM_StateLabels
	
	ModifyGraph mode=5, hbFill=2
	ModifyGraph catGap(bottom)=0.3, barGap(bottom)=0
	ModifyGraph tick(bottom)=3
	
	// D-state - zColorSingle Analysis
	Make/O/N=(maxState+1, 3) $(smpl + "_PBarColors") = 0
	Make/O/N=(maxState+1, 3) $(smpl + "_MBarColors") = 0
	Wave PBarColors = $(smpl + "_PBarColors")
	Wave MBarColors = $(smpl + "_MBarColors")
	
	Variable r, g, b
	for(s = 0; s <= maxState; s += 1)
		GetDstateColor(s, r, g, b)
		// Particle: 
		PBarColors[s][0] = min(r + 25000, 65535)
		PBarColors[s][1] = min(g + 25000, 65535)
		PBarColors[s][2] = min(b + 25000, 65535)
		// Molecular: 
		MBarColors[s][0] = r
		MBarColors[s][1] = g
		MBarColors[s][2] = b
	endfor
	
	ModifyGraph zColor($pName)={PBarColors,*,*,directRGB,0}
	ModifyGraph zColor($mName)={MBarColors,*,*,directRGB,0}
	ModifyGraph useBarStrokeRGB($pName)=1, barStrokeRGB($pName)=(30000,30000,30000)
	ModifyGraph useBarStrokeRGB($mName)=1, barStrokeRGB($mName)=(0,0,0)
	
	ErrorBars $pName Y,wave=(pSem, pSem)
	ErrorBars $mName Y,wave=(mSem, mSem)
	
	ModifyGraph tick=2, fStyle=1, fSize=14, font="Arial"
	Label left "Density (/µm\\S2\\M)"
	Label bottom "Diffusion State"
	SetAxis left 0, *
	
	// State
	SetBarGraphSizeByItems(maxState + 1, baseWidth=150, widthPerItem=30)
	
	TextBox/C/N=text0/A=RT/F=0 "Light: Particle\rDark: Molecular"
	
	DoWindow/T $winName, smpl + " Particle vs Molecular Density by State"
	
	SetDataFolder root:
	return 0
End

// =============================================================================
// Average Heatmap - Step Size Heatmap
// =============================================================================
Function AverageHeatmap()
	EnsureComparisonFolder()
	
	String sampleList = GetSampleFolderList()
	Variable numSamples = ItemsInList(sampleList)
	
	if(numSamples == 0)
		Print "No samples found"
		return -1
	endif
	
	NVAR/Z Dstate = root:Dstate
	NVAR/Z cHMM = root:cHMM
	Variable maxState = 0
	if(NVAR_Exists(cHMM) && cHMM == 1 && NVAR_Exists(Dstate))
		maxState = Dstate
	endif
	
	NVAR/Z HeatmapMin = root:HeatmapMin
	NVAR HeatmapMax = root:HeatmapMax
	Variable hMin = NVAR_Exists(HeatmapMin) ? HeatmapMin : 0
	Variable hMax = HeatmapMax
	
	// SVAR
	SVAR/Z Color0 = root:Color0
	SVAR/Z Color1 = root:Color1
	SVAR/Z Color2 = root:Color2
	SVAR/Z Color3 = root:Color3
	SVAR/Z Color4 = root:Color4
	SVAR/Z Color5 = root:Color5
	
	String colorTable
	
	Variable i, s
	String smpl, resultsPath
	
	for(i = 0; i < numSamples; i += 1)
		smpl = StringFromList(i, sampleList)
		resultsPath = "root:" + smpl + ":Results:"
		
		// D-state
		for(s = 0; s <= maxState; s += 1)
			String stateStr = "S" + num2str(s)
			String heatmapName = "StepHeatmap_" + stateStr + "_m_avg"
			
			Wave/Z Heatmap_avg = $(resultsPath + heatmapName)
			if(!WaveExists(Heatmap_avg))
				Print "StepHeatmap not found: " + smpl + " " + stateStr
				continue
			endif
			
			String winName = "AverageHeatmap_" + smpl + "_" + stateStr
			DoWindow/K $winName
			
			// 2D
			Display/K=1/N=$winName
			AppendImage Heatmap_avg
			
			// StateSingle Analysis
			if(s == 0 && SVAR_Exists(Color0))
				colorTable = Color0
			elseif(s == 1 && SVAR_Exists(Color1))
				colorTable = Color1
			elseif(s == 2 && SVAR_Exists(Color2))
				colorTable = Color2
			elseif(s == 3 && SVAR_Exists(Color3))
				colorTable = Color3
			elseif(s == 4 && SVAR_Exists(Color4))
				colorTable = Color4
			elseif(s == 5 && SVAR_Exists(Color5))
				colorTable = Color5
			else
				colorTable = "Rainbow"
			endif
			
			ModifyImage $heatmapName ctab={hMin, hMax, $colorTable, 0}
			
			// Single Analysis
			ModifyGraph tick=0, mirror=0, fStyle=1, fSize=14, font="Arial"
			Label left "Step size (µm)"
			Label bottom "Δt (frames)"
			
			// 
			ModifyGraph width=250, height=200
			ModifyGraph margin(right)=80
			
			// 
			ColorScale/C/N=colorbar/F=0/E=2/A=RC/X=5 image=$heatmapName
			ColorScale/C/N=colorbar font="Arial", fsize=12, "Prob. Density"
			
			// 
			String heatStateName = GetDstateName(s, maxState)
			DoWindow/T $winName, smpl + " Average Step Heatmap (" + heatStateName + ")"
		endfor
	endfor
	
	SetDataFolder root:
	Print "Average Heatmap completed"
	return 0
End

// =============================================================================
// Average State Transition Diagram - 
// =============================================================================
Function AverageStateTransDiagram()
	EnsureComparisonFolder()
	
	String sampleList = GetSampleFolderList()
	Variable numSamples = ItemsInList(sampleList)
	
	if(numSamples == 0)
		Print "No samples found"
		return -1
	endif
	
	NVAR gDstate = root:Dstate
	Variable Dstate = gDstate
	
	Variable i, j, s
	String smpl, resultsPath
	
	SetDataFolder root:Comparison
	
	for(i = 0; i < numSamples; i += 1)
		smpl = StringFromList(i, sampleList)
		resultsPath = "root:" + smpl + ":Results:"
		
		// 2DDLPopulation 
		Wave/Z TauTrans_avg = $(resultsPath + "TauTransition_cell_m_avg")
		Wave/Z TauTrans_sem = $(resultsPath + "TauTransition_cell_m_sem")
		Wave/Z TauDwell_avg = $(resultsPath + "TauDwell_cell_m_avg")
		Wave/Z TauDwell_sem = $(resultsPath + "TauDwell_cell_m_sem")
		Wave/Z P_avg = $(resultsPath + "P_values_m_avg")
		Wave/Z P_sem = $(resultsPath + "P_values_m_sem")
		
		// DLcoef_MSD_Sn_m_avg/semMSD
		Make/O/N=(Dstate) temp_D_avg = NaN, temp_D_sem = NaN
		Make/O/N=(Dstate) temp_L_avg = NaN, temp_L_sem = NaN
		
		for(s = 0; s < Dstate; s += 1)
			String coefAvgName = "coef_MSD_S" + num2str(s+1) + "_m_avg"
			String coefSemName = "coef_MSD_S" + num2str(s+1) + "_m_sem"
			Wave/Z coef_avg = $(resultsPath + coefAvgName)
			Wave/Z coef_sem = $(resultsPath + coefSemName)
			if(WaveExists(coef_avg) && numpnts(coef_avg) >= 1)
				temp_D_avg[s] = coef_avg[0]  // row 0 = D
				if(WaveExists(coef_sem))
					temp_D_sem[s] = coef_sem[0]
				endif
				if(numpnts(coef_avg) >= 2)
					temp_L_avg[s] = coef_avg[1]  // row 1 = L
					if(WaveExists(coef_sem) && numpnts(coef_sem) >= 2)
						temp_L_sem[s] = coef_sem[1]
					endif
				endif
			endif
		endfor
		
		Wave D_avg = temp_D_avg
		Wave D_sem = temp_D_sem
		Wave L_avg = temp_L_avg
		Wave L_sem = temp_L_sem
		
		// HMMPPopulation
		if(!WaveExists(P_avg))
			Wave/Z HMMP_avg = $(resultsPath + "HMMP_m_avg")
			Wave/Z HMMP_sem = $(resultsPath + "HMMP_m_sem")
			if(WaveExists(HMMP_avg))
				Make/O/N=(Dstate) temp_P_avg = NaN, temp_P_sem = NaN
				for(s = 0; s < Dstate; s += 1)
					if(s + 1 < numpnts(HMMP_avg))
						temp_P_avg[s] = HMMP_avg[s + 1]
						if(WaveExists(HMMP_sem))
							temp_P_sem[s] = HMMP_sem[s + 1]
						endif
					endif
				endfor
				Wave P_avg = temp_P_avg
				Wave P_sem = temp_P_sem
			endif
		endif
		
		// D_avgP_avg
		if(!WaveExists(D_avg) || !WaveExists(P_avg))
			Print "State Transition data not found for: " + smpl
			continue
		endif
		
		// TauTransition
		DrawAverageStateTransDiagram(smpl, D_avg, D_sem, L_avg, L_sem, P_avg, P_sem, TauTrans_avg, TauTrans_sem, TauDwell_avg, TauDwell_sem, Dstate)
	endfor
	
	KillWaves/Z temp_D_avg, temp_D_sem, temp_L_avg, temp_L_sem, temp_P_avg, temp_P_sem
	SetDataFolder root:
	Print "Average State Transition Diagram completed"
	return 0
End

// DrawStateTransitionDiagramForCell
Function DrawAverageStateTransDiagram(smpl, D_avg, D_sem, L_avg, L_sem, P_avg, P_sem, TauTrans_avg, TauTrans_sem, TauDwell_avg, TauDwell_sem, Dstate)
	String smpl
	Wave D_avg, D_sem, L_avg, L_sem, P_avg, P_sem, TauTrans_avg, TauTrans_sem, TauDwell_avg, TauDwell_sem
	Variable Dstate
	
	NVAR/Z cKinOutputTau = root:cKinOutputTau
	Variable outputTau = NVAR_Exists(cKinOutputTau) ? cKinOutputTau : 1
	
	// Diagram
	Variable stateLabelPct = 200  // State Label offset (%)
	Variable arrowOffsetPct = 4   // Arrow offset (%)
	Variable tauLabelPct = 1      // Tau label offset (%)
	Variable lineSpace = 0        // Line Space
	Variable fontSize = 12        // Font Size
	Variable graphSize = 300      // Graph Size
	ControlInfo/W=SMI_MainPanel tab4_sv_statelabel
	if(V_flag != 0)
		stateLabelPct = V_Value
	endif
	ControlInfo/W=SMI_MainPanel tab4_sv_arrowoffset
	if(V_flag != 0)
		arrowOffsetPct = V_Value
	endif
	ControlInfo/W=SMI_MainPanel tab4_sv_tauoffset
	if(V_flag != 0)
		tauLabelPct = V_Value
	endif
	ControlInfo/W=SMI_MainPanel tab4_sv_linespace
	if(V_flag != 0)
		lineSpace = V_Value
	endif
	ControlInfo/W=SMI_MainPanel tab4_sv_fontsize
	if(V_flag != 0)
		fontSize = V_Value
	endif
	ControlInfo/W=SMI_MainPanel tab4_sv_graphsize
	if(V_flag != 0)
		graphSize = V_Value
	endif
	
	Variable i, j
	Variable baseRadius, angle, centerX, centerY
	Variable maxPop, minMarkerSize, maxMarkerSize, markerSize, avgMarkerSize
	Variable axisRange, labelX, labelY, axisPerPoint
	Variable x1, y1, x2, y2, dx, dy, dist, perpX, perpY
	Variable midX, midY, arrowOffset, arrowStartX, arrowStartY, arrowEndX, arrowEndY
	Variable maxRate, rate, lineThick, arrowLength, arrowLenAxis
	Variable labelTauOffset, gapFromMarker, circleRadius, circleRadius2, maxArrowLen
	Variable arrowNum, labelOffset
	String winName, stateName, labelStr, boxName
	
	// L-threshold1.0
	Variable lThresh = 1.0
	ControlInfo/W=SMI_MainPanel tab4_sv_lthresh
	if(V_flag != 0)
		lThresh = V_Value
	endif
	
	// Single Analysis
	Make/FREE/N=(6, 3) StateColors
	StateColors[0][0] = 0;       StateColors[0][1] = 0;       StateColors[0][2] = 65280   // Blue
	StateColors[1][0] = 65280;   StateColors[1][1] = 43520;   StateColors[1][2] = 0       // Orange
	StateColors[2][0] = 0;       StateColors[2][1] = 39168;   StateColors[2][2] = 0       // Green
	StateColors[3][0] = 65280;   StateColors[3][1] = 0;       StateColors[3][2] = 0       // Red
	StateColors[4][0] = 39168;   StateColors[4][1] = 0;       StateColors[4][2] = 39168   // Purple
	StateColors[5][0] = 0;       StateColors[5][1] = 0;       StateColors[5][2] = 0       // Black
	
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
	
	// Use Aligned Trajectory
	NVAR/Z cUseAlignedTraj = root:cUseAlignedTraj
	Variable useAlignedTraj = NVAR_Exists(cUseAlignedTraj) ? cUseAlignedTraj : 0
	
	// Traj Scale
	Variable trajScale = 2.5
	ControlInfo/W=SMI_MainPanel tab4_sv_trajscale
	if(V_flag != 0)
		trajScale = V_Value
	endif
	
	// DrawStateTransitionDiagramForCell: 300x300
	winName = "AverageStateTrans_" + smpl
	DoWindow/K $winName
	Display/K=1/N=$winName/W=(100,100,400,400) as "Average State Transition: " + smpl
	
	// 20%baseRadius 4.5 → 5.4
	Make/O/N=(Dstate) StateX_pos, StateY_pos
	centerX = 0
	centerY = 0
	baseRadius = 5.4
	
	if(Dstate == 2)
		StateX_pos[0] = -4.05
		StateY_pos[0] = 0
		StateX_pos[1] = 4.05
		StateY_pos[1] = 0
	else
		for(i = 0; i < Dstate; i += 1)
			angle = Pi/2 - 2*Pi*i/Dstate
			StateX_pos[i] = centerX + baseRadius * cos(angle)
			StateY_pos[i] = centerY + baseRadius * sin(angle)
		endfor
	endif
	
	// Population
	WaveStats/Q P_avg
	maxPop = V_max
	if(maxPop <= 0)
		maxPop = 100
	endif
	
	// DrawStateTransitionDiagramForCell: 80%
	minMarkerSize = 6
	maxMarkerSize = 20
	axisPerPoint = 0.018
	
	// 
	maxRate = 0
	Variable minRate = inf
	if(WaveExists(TauTrans_avg))
		for(i = 0; i < Dstate; i += 1)
			for(j = 0; j < Dstate; j += 1)
				if(i != j && numtype(TauTrans_avg[i][j]) == 0 && TauTrans_avg[i][j] > 0)
					rate = 1.0 / TauTrans_avg[i][j]
					if(rate > maxRate)
						maxRate = rate
					endif
					if(rate < minRate)
						minRate = rate
					endif
				endif
			endfor
		endfor
	endif
	if(maxRate == 0)
		maxRate = 1
	endif
	if(minRate == inf || minRate <= 0)
		minRate = maxRate / 10
	endif
	
	// 
	avgMarkerSize = 0
	for(i = 0; i < Dstate; i += 1)
		Variable pop_i = P_avg[i]
		if(numtype(pop_i) != 0 || pop_i <= 0)
			pop_i = maxPop / Dstate
		endif
		markerSize = minMarkerSize + (maxMarkerSize - minMarkerSize) * (pop_i / maxPop)
		avgMarkerSize += markerSize
	endfor
	avgMarkerSize /= Dstate
	
	// ===== Use Aligned Trajectory  =====
	String stateXName, stateYName, traceName
	if(useAlignedTraj)
		// Trace_HMM
		Make/FREE/N=(6, 3) TrajColorsRGB
		TrajColorsRGB[0][0] = 32768;  TrajColorsRGB[0][1] = 40704;  TrajColorsRGB[0][2] = 65280
		TrajColorsRGB[1][0] = 65280;  TrajColorsRGB[1][1] = 65280;  TrajColorsRGB[1][2] = 0
		TrajColorsRGB[2][0] = 0;      TrajColorsRGB[2][1] = 65280;  TrajColorsRGB[2][2] = 0
		TrajColorsRGB[3][0] = 65280;  TrajColorsRGB[3][1] = 0;      TrajColorsRGB[3][2] = 0
		TrajColorsRGB[4][0] = 65280;  TrajColorsRGB[4][1] = 40704;  TrajColorsRGB[4][2] = 32768
		TrajColorsRGB[5][0] = 65535;  TrajColorsRGB[5][1] = 65535;  TrajColorsRGB[5][2] = 65535
		
		// Comparisonwave
		String compPath = "root:Comparison:"
		
		// Average Aligned TrajectoryComparison
		String checkXName = compPath + smpl + "_AvgAligned_X_S1"
		Wave/Z checkWave = $checkXName
		if(!WaveExists(checkWave))
			Print "WARNING: Average Aligned Trajectory data not found in Comparison folder."
			Print "         Please run 'Average Aligned Trajectory' first."
			Print "         Falling back to standard marker mode."
			useAlignedTraj = 0
		endif
		
		if(useAlignedTraj)
			for(i = 0; i < Dstate; i += 1)
				// Comparison SampleName_AvgAligned_X_Sn 
				String avgXName = compPath + smpl + "_AvgAligned_X_S" + num2str(i+1)
				String avgYName = compPath + smpl + "_AvgAligned_Y_S" + num2str(i+1)
				
				Wave/Z avgXWave = $avgXName
				Wave/Z avgYWave = $avgYName
				
				if(WaveExists(avgXWave) && WaveExists(avgYWave) && numpnts(avgXWave) > 0)
					// StateX_pos[i], StateY_pos[i]
					// Wave
					String diagAvgXName = smpl + "_DiagTraj_X_S" + num2str(i+1)
					String diagAvgYName = smpl + "_DiagTraj_Y_S" + num2str(i+1)
					Duplicate/O avgXWave, $diagAvgXName
					Duplicate/O avgYWave, $diagAvgYName
					Wave diagAvgX = $diagAvgXName
					Wave diagAvgY = $diagAvgYName
					
					// 
					diagAvgX = (numtype(avgXWave[p]) == 0) ? StateX_pos[i] + avgXWave[p] * trajScale : NaN
					diagAvgY = (numtype(avgYWave[p]) == 0) ? StateY_pos[i] + avgYWave[p] * trajScale : NaN
					
					AppendToGraph diagAvgY vs diagAvgX
					traceName = diagAvgYName
					
					Variable colorIdx = i
					if(colorIdx > 5)
						colorIdx = 5
					endif
					ModifyGraph rgb($traceName)=(TrajColorsRGB[colorIdx][0], TrajColorsRGB[colorIdx][1], TrajColorsRGB[colorIdx][2])
					ModifyGraph lsize($traceName)=0.25
				endif
				
				// LComparison
				String avgLCircleXName = compPath + smpl + "_AvgLCircle_X_S" + num2str(i+1)
				String avgLCircleYName = compPath + smpl + "_AvgLCircle_Y_S" + num2str(i+1)
				Wave/Z avgLCircleX = $avgLCircleXName
				Wave/Z avgLCircleY = $avgLCircleYName
				
				if(WaveExists(avgLCircleX) && WaveExists(avgLCircleY))
					// StateX_pos[i], StateY_pos[i]
					// Wave
					String diagLCircleXName = smpl + "_DiagLCircle_X_S" + num2str(i+1)
					String diagLCircleYName = smpl + "_DiagLCircle_Y_S" + num2str(i+1)
					Duplicate/O avgLCircleX, $diagLCircleXName
					Duplicate/O avgLCircleY, $diagLCircleYName
					Wave diagLCircleX = $diagLCircleXName
					Wave diagLCircleY = $diagLCircleYName
					
					// 
					diagLCircleX = StateX_pos[i] + avgLCircleX[p] * trajScale
					diagLCircleY = StateY_pos[i] + avgLCircleY[p] * trajScale
					
					AppendToGraph diagLCircleY vs diagLCircleX
					String lCircleTraceName = diagLCircleYName
					
					Variable lColorIdx = i
					if(lColorIdx > 5)
						lColorIdx = 5
					endif
					// L0.5
					ModifyGraph rgb($lCircleTraceName)=(TrajColorsRGB[lColorIdx][0]*0.75, TrajColorsRGB[lColorIdx][1]*0.75, TrajColorsRGB[lColorIdx][2]*0.75)
					ModifyGraph lsize($lCircleTraceName)=2
				endif
			endfor
		endif
	endif
	
	if(!useAlignedTraj)
		// 
		for(i = 0; i < Dstate; i += 1)
			// Wave
			stateXName = smpl + "_StateX_" + num2str(i+1)
			stateYName = smpl + "_StateY_" + num2str(i+1)
			
			Make/O/N=1 $stateXName, $stateYName
			Wave sx = $stateXName
			Wave sy = $stateYName
			sx[0] = StateX_pos[i]
			sy[0] = StateY_pos[i]
			
			AppendToGraph sy vs sx
			traceName = stateYName
			
			// Population
			Variable pop = P_avg[i]
			if(numtype(pop) != 0 || pop <= 0)
				pop = maxPop / Dstate
			endif
			markerSize = minMarkerSize + (maxMarkerSize - minMarkerSize) * (pop / maxPop)
			
			ModifyGraph mode($traceName)=3
			ModifyGraph marker($traceName)=19
			ModifyGraph msize($traceName)=markerSize
			ModifyGraph rgb($traceName)=(StateColors[i][0], StateColors[i][1], StateColors[i][2])
		endfor
		
		// LL-threshold
		for(i = 0; i < Dstate; i += 1)
			Variable lVal = NaN
			if(WaveExists(L_avg) && i < numpnts(L_avg))
				lVal = L_avg[i]
			endif
			Printf "  State S%d: L_avg=%.4f, threshold=%.4f\r", i+1, lVal, lThresh
			
			if(numtype(lVal) == 0 && lVal > 0 && lVal <= lThresh)
				// LlVal * 0.75 
				Variable lCircleRadius = lVal * 0.75
				// 
				Variable lMarkerSize = lCircleRadius / axisPerPoint
				
				// 
				Variable pValL = P_avg[i]
				if(numtype(pValL) != 0 || pValL <= 0)
					pValL = maxPop / Dstate
				endif
				Variable stateMarkerSize = minMarkerSize + (maxMarkerSize - minMarkerSize) * (pValL / maxPop)
				
				Printf "    -> L marker size=%.1f, state marker size=%.1f\r", lMarkerSize, stateMarkerSize
				
				// LWave
				// Wave
				String lXName = smpl + "_LMarkerX_" + num2str(i+1)
				String lYName = smpl + "_LMarkerY_" + num2str(i+1)
				Make/O/N=1 $lXName, $lYName
				Wave lX = $lXName
				Wave lY = $lYName
				lX[0] = StateX_pos[i]
				lY[0] = StateY_pos[i]
				
				AppendToGraph lY vs lX
				String lTraceName = lYName
				
				ModifyGraph mode($lTraceName)=3
				ModifyGraph marker($lTraceName)=8  // 
				ModifyGraph msize($lTraceName)=lMarkerSize
				ModifyGraph lsize($lTraceName)=1  // 1
				
				// L <  →  → 
				if(lMarkerSize < stateMarkerSize)
					Printf "    -> Using WHITE (L < state marker)\r"
					ModifyGraph rgb($lTraceName)=(65535,65535,65535)  // 
				else
					Printf "    -> Using DARK STATE COLOR (L >= state marker)\r"
					ModifyGraph rgb($lTraceName)=(StateColors[i][0]*0.75, StateColors[i][1]*0.75, StateColors[i][2]*0.75)  // 
				endif
			endif
		endfor
	endif
	
	// 75%
	axisRange = baseRadius * 1.33
	SetAxis left -axisRange, axisRange
	SetAxis bottom -axisRange, axisRange
	ModifyGraph width=graphSize, height=graphSize
	ModifyGraph tick=3, mirror=0, noLabel=2, axThick=0
	// 
	ModifyGraph margin(left)=25, margin(right)=25, margin(top)=25, margin(bottom)=25
	
	// TextBoxDrawStateTransitionDiagramForCell
	for(i = 0; i < Dstate; i += 1)
		stateName = StateNames[nameIdx][i]
		pop = P_avg[i]
		if(numtype(pop) != 0 || pop <= 0)
			pop = maxPop / Dstate
		endif
		markerSize = minMarkerSize + (maxMarkerSize - minMarkerSize) * (pop / maxPop)
		
		// (0,0)
		Variable dirX = StateX_pos[i]
		Variable dirY = StateY_pos[i]
		Variable dirLen = sqrt(dirX^2 + dirY^2)
		if(dirLen > 0)
			dirX /= dirLen
			dirY /= dirLen
		else
			dirX = 0
			dirY = 1
		endif
		
		// : 90
		Variable labelDirX = dirY   // 90
		Variable labelDirY = -dirX
		
		// : 
		labelOffset = markerSize * axisPerPoint + 1.2
		labelX = StateX_pos[i] + labelOffset * labelDirX * (stateLabelPct / 100)
		labelY = StateY_pos[i] + labelOffset * labelDirY * (stateLabelPct / 100)
		
		// Dsem
		Variable Dval = D_avg[i]
		Variable Dsem = 0
		if(WaveExists(D_sem) && i < numpnts(D_sem))
			Dsem = D_sem[i]
		endif
		// Lsem
		Lval = NaN
		Variable Lsem = 0
		if(WaveExists(L_avg) && i < numpnts(L_avg))
			Lval = L_avg[i]
		endif
		if(WaveExists(L_sem) && i < numpnts(L_sem))
			Lsem = L_sem[i]
		endif
		Variable Pval = P_avg[i]
		Variable Psem = 0
		if(WaveExists(P_sem) && i < numpnts(P_sem))
			Psem = P_sem[i]
		endif
		
		// 
		Variable stateR = StateColors[i][0]
		Variable stateG = StateColors[i][1]
		Variable stateB = StateColors[i][2]
		
		// TextBoxmean±semLlThreshL
		boxName = "State" + num2str(i+1)
		if(numtype(Lval) == 0 && Lval > 0 && Lval <= lThresh)
			sprintf labelStr, "\\Z14\\f01\\K(%d,%d,%d)%s\r\\Z11\\K(0,0,0)D=%.3f±%.3f µm²/s\rL=%.3f±%.3f µm\rP=%.1f±%.1f%%", stateR, stateG, stateB, stateName, Dval, Dsem, Lval, Lsem, Pval, Psem
		else
			sprintf labelStr, "\\Z14\\f01\\K(%d,%d,%d)%s\r\\Z11\\K(0,0,0)D=%.3f±%.3f µm²/s\rP=%.1f±%.1f%%", stateR, stateG, stateB, stateName, Dval, Dsem, Pval, Psem
		endif
		TextBox/C/N=$boxName/F=0/B=1/A=MC/X=(labelX/axisRange*50)/Y=(labelY/axisRange*50)
		AppendText/N=$boxName labelStr
	endfor
	
	// DrawStateTransitionDiagramForCell
	if(WaveExists(TauTrans_avg))
		SetDrawLayer UserFront
		
		arrowNum = 0
		arrowLenAxis = 8 * axisPerPoint  // DiagramForCell
		
		for(i = 0; i < Dstate; i += 1)
			for(j = 0; j < Dstate; j += 1)
				if(i != j && numtype(TauTrans_avg[i][j]) == 0 && TauTrans_avg[i][j] > 0)
					x1 = StateX_pos[i]
					y1 = StateY_pos[i]
					x2 = StateX_pos[j]
					y2 = StateY_pos[j]
					
					dx = x2 - x1
					dy = y2 - y1
					dist = sqrt(dx^2 + dy^2)
					
					Variable centerMidX = (x1 + x2) / 2
					Variable centerMidY = (y1 + y2) / 2
					
					Variable pop1 = P_avg[i]
					Variable pop2 = P_avg[j]
					if(numtype(pop1) != 0) 
						pop1 = maxPop / Dstate
					endif
					if(numtype(pop2) != 0) 
						pop2 = maxPop / Dstate
					endif
					Variable markerSize1 = minMarkerSize + (maxMarkerSize - minMarkerSize) * (pop1 / maxPop)
					Variable markerSize2 = minMarkerSize + (maxMarkerSize - minMarkerSize) * (pop2 / maxPop)
					circleRadius = markerSize1 * axisPerPoint * 0.55
					circleRadius2 = markerSize2 * axisPerPoint * 0.55
					
					// 
					perpX = dy / dist
					perpY = -dx / dist
					
					// : %
					arrowOffset = dist * arrowOffsetPct / 100
					
					Variable kValue = 1.0 / TauTrans_avg[i][j]
					maxArrowLen = dist - circleRadius - circleRadius2 - 2 * arrowOffset
					if(maxArrowLen < 0.2)
						maxArrowLen = 0.2
					endif
					// log scalek
					Variable logMin = log(minRate)
					Variable logMax = log(maxRate)
					Variable logK = log(kValue)
					Variable normalizedK = (logMax > logMin) ? (logK - logMin) / (logMax - logMin) : 1
					arrowLength = maxArrowLen * normalizedK * (2.0 / 3.0)
					
					midX = centerMidX + arrowOffset * perpX
					midY = centerMidY + arrowOffset * perpY
					
					// log scale
					lineThick = 1.5 + 1.5 * normalizedK
					
					// 
					Variable arrowAngle = atan2(dy, dx) * 180 / pi
					
					// normalizedK
					Variable numBars = 1 + round(14 * normalizedK)  // 115
					String arrowStr = ""
					Variable bi
					
					// i < j→
					if(i < j)
						arrowStr = "◀"
						for(bi = 0; bi < numBars; bi += 1)
							arrowStr += "─"
						endfor
						arrowAngle += 180  // 180
					else
						for(bi = 0; bi < numBars; bi += 1)
							arrowStr += "─"
						endfor
						arrowStr += "▶"
					endif
					
					arrowNum += 1
					boxName = "TauArrow" + num2str(arrowNum)
					
					// τ/k
					String tauLabel = ""
					if(outputTau)
						// τsem
						Variable tauSem = 0
						if(WaveExists(TauTrans_sem))
							tauSem = TauTrans_sem[i][j]
						endif
						if(numtype(tauSem) == 0 && tauSem > 0)
							sprintf tauLabel, "τ=%.2f±%.2f s", TauTrans_avg[i][j], tauSem
						else
							sprintf tauLabel, "τ=%.2f s", TauTrans_avg[i][j]
						endif
					else
						// k = 1/τ
						Variable kSem = 0
						if(WaveExists(TauTrans_sem) && TauTrans_avg[i][j] > 0)
							// : σ_k ≈ σ_τ / τ^2
							kSem = TauTrans_sem[i][j] / (TauTrans_avg[i][j]^2)
						endif
						if(kSem > 0)
							sprintf tauLabel, "k=%.3f±%.3f/s", kValue, kSem
						else
							sprintf tauLabel, "k=%.3f/s", kValue
						endif
					endif
					
					// τ: 
					labelTauOffset = dist * tauLabelPct / 100
					Variable labelPerpX = labelTauOffset * perpX
					Variable labelPerpY = labelTauOffset * perpY
					
					// τ1TextBox
					// i < j: τ / i > j: τ
					// TextBox
					Variable xPct = (midX + labelPerpX) / axisRange * 50
					Variable yPct = (midY + labelPerpY) / axisRange * 50
					if(i < j)
						// →: τ
						sprintf labelStr, "\\JC\\Z%d%s\r\\Z%d%s", fontSize, tauLabel, fontSize, arrowStr
					else
						// →: τ
						sprintf labelStr, "\\JC\\Z%d%s\r\\Z%d%s", fontSize, arrowStr, fontSize, tauLabel
					endif
					TextBox/C/N=$boxName/F=0/B=1/A=MC/X=(xPct)/Y=(yPct)/O=(arrowAngle)/LS=(lineSpace) labelStr
				endif
			endfor
		endfor
	endif
	
	// 14Arial
	NVAR framerate = root:framerate
	Variable fr = framerate
	sprintf labelStr, "\\F'Arial'\\Z14Average State Transition: %s (%d states)\r\\Z12framerate = %.3f s", smpl, Dstate, fr
	TextBox/C/N=title/F=0/B=1/A=LT/X=0/Y=0 labelStr
	
	// Use Aligned Trajectory
	if(useAlignedTraj)
		// : 1 µm trajScale
		Variable scaleBarLen = 1.0 * trajScale  // 1 µm
		Variable scaleBarX1 = -axisRange * 0.90
		Variable scaleBarX2 = scaleBarX1 + scaleBarLen
		Variable scaleBarYPos = axisRange * 0.65  // 
		
		// Wave
		String scaleBarXName = smpl + "_ScaleBar_X"
		String scaleBarYName = smpl + "_ScaleBar_Y"
		Make/O/N=2 $scaleBarXName, $scaleBarYName
		Wave ScaleBar_X = $scaleBarXName
		Wave ScaleBar_Y = $scaleBarYName
		ScaleBar_X[0] = scaleBarX1
		ScaleBar_X[1] = scaleBarX2
		ScaleBar_Y[0] = scaleBarYPos
		ScaleBar_Y[1] = scaleBarYPos
		
		AppendToGraph ScaleBar_Y vs ScaleBar_X
		ModifyGraph rgb($scaleBarYName)=(0,0,0)
		ModifyGraph lsize($scaleBarYName)=2
		
		// 
		String scaleLabel
		sprintf scaleLabel, "\\Z10\\K(0,0,0)1 µm"
		Variable scaleLabelX = (scaleBarX1 + scaleBarX2) / 2
		Variable scaleLabelYPos = scaleBarYPos - axisRange * 0.10
		TextBox/C/N=scalebar/F=0/B=1/A=MC/X=(scaleLabelX/axisRange*50)/Y=(scaleLabelYPos/axisRange*50) scaleLabel
	endif
	
	KillWaves/Z StateX_pos, StateY_pos
	return 0
End

// =============================================================================
// Button Procedures - Average
// =============================================================================
Function AverageStepHistButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	NVAR/Z Dstate = root:Dstate
	NVAR/Z cHMM = root:cHMM
	NVAR/Z StepDeltaTMin = root:StepDeltaTMin
	NVAR/Z StepDeltaTMax = root:StepDeltaTMax
	
	Variable maxState = 0
	if(NVAR_Exists(cHMM) && cHMM == 1 && NVAR_Exists(Dstate))
		maxState = Dstate
	endif
	
	Variable dtMin, dtMax
	if(NVAR_Exists(StepDeltaTMin))
		dtMin = StepDeltaTMin
	else
		dtMin = 1
	endif
	if(NVAR_Exists(StepDeltaTMax))
		dtMax = StepDeltaTMax
	else
		dtMax = 1
	endif
	
	EnsureComparisonFolder()
	
	// ===== Total =====
	String sampleList = GetSampleFolderList()
	Variable numSamples = ItemsInList(sampleList)
	Variable i, dt, s
	String smpl
	
	Print "Ensuring Results for StepHist..."
	for(i = 0; i < numSamples; i += 1)
		smpl = StringFromList(i, sampleList)
		EnsureAllResultsForAverage(smpl, "StepHist")
	endfor
	
	// Δt
	for(dt = dtMin; dt <= dtMax; dt += 1)
		// 1. State
		for(s = 0; s <= maxState; s += 1)
			AverageStepHist(s, dt)
		endfor
		
		// 2. State
		for(i = 0; i < numSamples; i += 1)
			smpl = StringFromList(i, sampleList)
			AverageStepHistPerSample(smpl, dt)
		endfor
	endfor
	
	// ===== Segmentation =====
	if(IsSegmentationEnabled())
		Variable maxSeg = GetMaxSegmentValue()
		Variable segIdx
		for(segIdx = 0; segIdx <= maxSeg; segIdx += 1)
			String basePath = GetSegmentFolderPath(segIdx)
			String segSuffix = GetSegmentSuffix(segIdx)
			String segLabel = GetSegmentLabel(segSuffix)
			Print "--- Average StepHist [" + segLabel + "] ---"
			
			// SegResults
			String segSampleList = GetSampleFolderListFromPath(basePath)
			Variable segNumSamples = ItemsInList(segSampleList)
			for(i = 0; i < segNumSamples; i += 1)
				smpl = StringFromList(i, segSampleList)
				EnsureAllResultsForAverageWithPath(smpl, "StepHist", basePath, segSuffix)
			endfor
			
			// Δt
			for(dt = dtMin; dt <= dtMax; dt += 1)
				for(s = 0; s <= maxState; s += 1)
					AverageStepHistWithPath(s, dt, basePath, segSuffix)
				endfor
			endfor
		endfor
	endif
	
	Print "=== Average Stepsize Histogram completed ==="
	return 0
End

Function AverageIntHistButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	NVAR/Z Dstate = root:Dstate
	NVAR/Z cHMM = root:cHMM
	
	Variable maxState = 0
	if(NVAR_Exists(cHMM) && cHMM == 1 && NVAR_Exists(Dstate))
		maxState = Dstate
	endif
	
	EnsureComparisonFolder()
	
	// ===== Total =====
	String sampleList = GetSampleFolderList()
	Variable numSamples = ItemsInList(sampleList)
	Variable i, s
	String smpl
	
	Print "Ensuring Results for IntHist..."
	for(i = 0; i < numSamples; i += 1)
		smpl = StringFromList(i, sampleList)
		EnsureAllResultsForAverage(smpl, "IntHist")
	endfor
	
	for(s = 0; s <= maxState; s += 1)
		AverageIntHist(s)
	endfor
	
	for(i = 0; i < numSamples; i += 1)
		smpl = StringFromList(i, sampleList)
		AverageIntHistPerSample(smpl)
	endfor
	
	// ===== Segmentation =====
	if(IsSegmentationEnabled())
		Variable maxSeg = GetMaxSegmentValue()
		Variable segIdx
		for(segIdx = 0; segIdx <= maxSeg; segIdx += 1)
			String basePath = GetSegmentFolderPath(segIdx)
			String segSuffix = GetSegmentSuffix(segIdx)
			String segLabel = GetSegmentLabel(segSuffix)
			Print "--- Average IntHist [" + segLabel + "] ---"
			
			// SegResults
			String segSampleList = GetSampleFolderListFromPath(basePath)
			Variable segNumSamples = ItemsInList(segSampleList)
			for(i = 0; i < segNumSamples; i += 1)
				smpl = StringFromList(i, segSampleList)
				EnsureAllResultsForAverageWithPath(smpl, "IntHist", basePath, segSuffix)
			endfor
			
			for(s = 0; s <= maxState; s += 1)
				AverageIntHistWithPath(s, basePath, segSuffix)
			endfor
		endfor
	endif
	
	Print "=== Average Intensity Histogram completed ==="
	return 0
End

Function AverageLPHistButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	NVAR/Z Dstate = root:Dstate
	NVAR/Z cHMM = root:cHMM
	
	Variable maxState = 0
	if(NVAR_Exists(cHMM) && cHMM == 1 && NVAR_Exists(Dstate))
		maxState = Dstate
	endif
	
	// ===== Total =====
	String sampleList = GetSampleFolderList()
	Variable numSamples = ItemsInList(sampleList)
	Variable i, s
	String smpl
	
	Print "Ensuring Results for LP..."
	for(i = 0; i < numSamples; i += 1)
		smpl = StringFromList(i, sampleList)
		EnsureAllResultsForAverage(smpl, "LP")
	endfor
	
	// 1. State
	for(s = 0; s <= maxState; s += 1)
		AverageLPHist(s)
	endfor
	
	// 2. State
	for(i = 0; i < numSamples; i += 1)
		smpl = StringFromList(i, sampleList)
		AverageLPHistPerSample(smpl)
	endfor
	
	// ===== Segmentation =====
	if(IsSegmentationEnabled())
		Variable maxSeg = GetMaxSegmentValue()
		Variable segIdx
		for(segIdx = 0; segIdx <= maxSeg; segIdx += 1)
			String basePath = GetSegmentFolderPath(segIdx)
			String segSuffix = GetSegmentSuffix(segIdx)
			String segLabel = GetSegmentLabel(segSuffix)
			Print "--- Average LP [" + segLabel + "] ---"
			
			// SegResults
			String segSampleList = GetSampleFolderListFromPath(basePath)
			Variable segNumSamples = ItemsInList(segSampleList)
			for(i = 0; i < segNumSamples; i += 1)
				smpl = StringFromList(i, segSampleList)
				EnsureAllResultsForAverageWithPath(smpl, "LP", basePath, segSuffix)
			endfor
			
			for(s = 0; s <= maxState; s += 1)
				AverageLPHistWithPath(s, basePath, segSuffix)
			endfor
		endfor
	endif
	
	Print "=== Average LP Histogram completed ==="
	return 0
End

Function AverageOntimeButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	// ===== Total =====
	String sampleList = GetSampleFolderList()
	Variable numSamples = ItemsInList(sampleList)
	Variable i
	String smpl
	
	Print "Ensuring Results for Duration..."
	for(i = 0; i < numSamples; i += 1)
		smpl = StringFromList(i, sampleList)
		EnsureAllResultsForAverage(smpl, "Duration")
	endfor
	
	AverageOntime()
	
	// ===== Segmentation =====
	if(IsSegmentationEnabled())
		Variable maxSeg = GetMaxSegmentValue()
		Variable segIdx
		for(segIdx = 0; segIdx <= maxSeg; segIdx += 1)
			String basePath = GetSegmentFolderPath(segIdx)
			String segSuffix = GetSegmentSuffix(segIdx)
			String segLabel = GetSegmentLabel(segSuffix)
			Print "--- Average On-time [" + segLabel + "] ---"
			
			// SegResults
			String segSampleList = GetSampleFolderListFromPath(basePath)
			Variable segNumSamples = ItemsInList(segSampleList)
			for(i = 0; i < segNumSamples; i += 1)
				smpl = StringFromList(i, segSampleList)
				EnsureAllResultsForAverageWithPath(smpl, "Duration", basePath, segSuffix)
			endfor
			
			AverageOntimeWithPath(basePath, segSuffix)
		endfor
	endif
	
	Print "=== Average On-time completed ==="
	return 0
End

Function AverageOnrateButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	NVAR/Z Dstate = root:Dstate
	NVAR/Z cHMM = root:cHMM
	
	Variable maxState = 0
	if(NVAR_Exists(cHMM) && cHMM == 1 && NVAR_Exists(Dstate))
		maxState = Dstate
	endif
	
	EnsureComparisonFolder()
	
	// ===== Total =====
	String sampleList = GetSampleFolderList()
	Variable numSamples = ItemsInList(sampleList)
	Variable i, s
	String smpl
	
	Print "Ensuring Results for Onrate..."
	for(i = 0; i < numSamples; i += 1)
		smpl = StringFromList(i, sampleList)
		EnsureAllResultsForAverage(smpl, "Onrate")
	endfor
	
	for(s = 0; s <= maxState; s += 1)
		AverageOnrate(s)
	endfor
	
	for(i = 0; i < numSamples; i += 1)
		smpl = StringFromList(i, sampleList)
		AverageOnratePerSample(smpl)
	endfor
	
	// ===== Segmentation =====
	if(IsSegmentationEnabled())
		Variable maxSeg = GetMaxSegmentValue()
		Variable segIdx
		for(segIdx = 0; segIdx <= maxSeg; segIdx += 1)
			String basePath = GetSegmentFolderPath(segIdx)
			String segSuffix = GetSegmentSuffix(segIdx)
			String segLabel = GetSegmentLabel(segSuffix)
			Print "--- Average On-rate [" + segLabel + "] ---"
			
			// SegResults
			String segSampleList = GetSampleFolderListFromPath(basePath)
			Variable segNumSamples = ItemsInList(segSampleList)
			for(i = 0; i < segNumSamples; i += 1)
				smpl = StringFromList(i, segSampleList)
				EnsureAllResultsForAverageWithPath(smpl, "Onrate", basePath, segSuffix)
			endfor
			
			for(s = 0; s <= maxState; s += 1)
				AverageOnrateWithPath(s, basePath, segSuffix)
			endfor
		endfor
	endif
	
	Print "=== Average On-rate completed ==="
	return 0
End

Function AverageMolDensButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	NVAR/Z Dstate = root:Dstate
	NVAR/Z cHMM = root:cHMM
	
	Variable maxState = 0
	if(NVAR_Exists(cHMM) && cHMM == 1 && NVAR_Exists(Dstate))
		maxState = Dstate
	endif
	
	// ===== Total =====
	// Results
	String sampleList = GetSampleFolderList()
	Variable numSamples = ItemsInList(sampleList)
	Variable i
	String smpl
	
	Print "Ensuring Results for MolDens..."
	for(i = 0; i < numSamples; i += 1)
		smpl = StringFromList(i, sampleList)
		EnsureAllResultsForAverage(smpl, "MolDens")
	endfor
	
	// 1. State
	Variable s
	for(s = 0; s <= maxState; s += 1)
		AverageMolDensHist(s)
	endfor
	
	// 2. Fraction
	AverageMolDensFraction()
	
	// 3. Particle vs Mol Density
	AverageParticleVsMolDens()
	
	// 4. Particle vs Mol DensityD-stateSingle Analysis
	for(i = 0; i < numSamples; i += 1)
		smpl = StringFromList(i, sampleList)
		AverageParticleVsMolDensByState(smpl)
	endfor
	
	// ===== Segmentation =====
	if(IsSegmentationEnabled())
		Variable maxSeg = GetMaxSegmentValue()
		Variable segIdx
		for(segIdx = 0; segIdx <= maxSeg; segIdx += 1)
			String basePath = GetSegmentFolderPath(segIdx)
			String segSuffix = GetSegmentSuffix(segIdx)
			String segLabel = GetSegmentLabel(segSuffix)
			Print "--- Average Mol Density [" + segLabel + "] ---"
			
			// SegResults
			String segSampleList = GetSampleFolderListFromPath(basePath)
			Variable segNumSamples = ItemsInList(segSampleList)
			for(i = 0; i < segNumSamples; i += 1)
				smpl = StringFromList(i, segSampleList)
				EnsureAllResultsForAverageWithPath(smpl, "MolDens", basePath, segSuffix)
			endfor
			
			// State
			for(s = 0; s <= maxState; s += 1)
				AverageMolDensHistWithPath(s, basePath, segSuffix)
			endfor
			
			// Fraction
			AverageMolDensFractionWithPath(basePath, segSuffix)
			
			Printf "  Average Mol Density [%s] completed\r", segLabel
		endfor
	endif
	
	Print "=== Average Mol Density completed ==="
	return 0
End

Function AverageHeatmapButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	// Δt max >= 2 
	NVAR/Z StepDeltaTMax = root:StepDeltaTMax
	if(NVAR_Exists(StepDeltaTMax) && StepDeltaTMax < 2)
		if(StringMatch(ctrlName, "auto"))
			Print "  Skipping Average Heatmap (Δt max < 2)"
		else
			DoAlert 0, "Heatmap requires Δt max ≥ 2"
		endif
		return 0
	endif
	
	// Results
	String sampleList = GetSampleFolderList()
	Variable numSamples = ItemsInList(sampleList)
	Variable i
	String smpl
	
	Print "Ensuring Results for Heatmap..."
	for(i = 0; i < numSamples; i += 1)
		smpl = StringFromList(i, sampleList)
		EnsureAllResultsForAverage(smpl, "Heatmap")
	endfor
	
	AverageHeatmap()
	Print "=== Average Heatmap completed ==="
	return 0
End

Function AverageStateTransButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	// Results
	String sampleList = GetSampleFolderList()
	Variable numSamples = ItemsInList(sampleList)
	Variable i
	String smpl
	
	Print "Ensuring Results for StateTrans..."
	for(i = 0; i < numSamples; i += 1)
		smpl = StringFromList(i, sampleList)
		EnsureAllResultsForAverage(smpl, "StateTrans")
	endfor
	
	AverageStateTransDiagram()
	Print "=== Average State Transition Diagram completed ==="
	return 0
End

// =============================================================================
// Compare MSD Parameters - Mean±SEMState1
// v2.3.38
// =============================================================================

// -----------------------------------------------------------------------------
// CompareMSD_MeanSEM_D - StateDMean±SEM
// AverageParticleVsMolDensByStatezColorState
// -----------------------------------------------------------------------------
Function CompareMSD_MeanSEM_D()
	EnsureComparisonFolder()
	SetDataFolder root:Comparison
	
	String sampleList = GetSampleFolderList()
	Variable numSamples = ItemsInList(sampleList)
	
	if(numSamples == 0)
		Print "No samples found"
		SetDataFolder root:
		return -1
	endif
	
	NVAR/Z Dstate = root:Dstate
	NVAR/Z cHMM = root:cHMM
	Variable maxState = 0
	if(NVAR_Exists(cHMM) && cHMM == 1 && NVAR_Exists(Dstate))
		maxState = Dstate
	endif
	
	// X: State × Sample2
	Variable totalBars = (maxState + 1) * numSamples
	Make/O/T/N=(totalBars) MSD_D_AllLabels
	Make/O/N=(totalBars) MSD_D_AllMeans = NaN
	Make/O/N=(totalBars) MSD_D_AllSEMs = NaN
	Make/O/N=(totalBars, 3) MSD_D_AllColors = 0
	
	Variable stt, barIdx, smplIdx
	Variable r, g, b
	String smplName, avgPath, semPath, stateName
	
	// Dstate
	Variable totalStates = maxState + 1
	
	barIdx = 0
	for(stt = 0; stt <= maxState; stt += 1)
		stateName = GetDstateName(stt, totalStates)
		
		for(smplIdx = 0; smplIdx < numSamples; smplIdx += 1)
			smplName = StringFromList(smplIdx, sampleList)
			
			// : -State1
			MSD_D_AllLabels[barIdx] = smplName + "-" + stateName
			
			// 
			avgPath = "root:" + smplName + ":Results:coef_MSD_S" + num2str(stt) + "_m_avg"
			semPath = "root:" + smplName + ":Results:coef_MSD_S" + num2str(stt) + "_m_sem"
			Wave/Z avgWave = $avgPath
			Wave/Z semWave = $semPath
			
			if(WaveExists(avgWave) && WaveExists(semWave))
				MSD_D_AllMeans[barIdx] = avgWave[0]  // row 0 = D
				MSD_D_AllSEMs[barIdx] = semWave[0]
			endif
			
			// State + 
			GetDstateColor(stt, r, g, b)
			if(smplIdx > 0)
				r = min(r + 15000 * smplIdx, 65535)
				g = min(g + 15000 * smplIdx, 65535)
				b = min(b + 15000 * smplIdx, 65535)
			endif
			MSD_D_AllColors[barIdx][0] = r
			MSD_D_AllColors[barIdx][1] = g
			MSD_D_AllColors[barIdx][2] = b
			
			barIdx += 1
		endfor
	endfor
	
	// 
	String winName = "CompareMSD_D_MeanSEM"
	DoWindow/K $winName
	
	Display/K=1/N=$winName MSD_D_AllMeans vs MSD_D_AllLabels
	
	// 
	ModifyGraph mode=5, hbFill=2
	ModifyGraph zColor(MSD_D_AllMeans)={MSD_D_AllColors,*,*,directRGB,0}
	ModifyGraph useBarStrokeRGB(MSD_D_AllMeans)=1, barStrokeRGB(MSD_D_AllMeans)=(0,0,0)
	
	// 
	ErrorBars MSD_D_AllMeans Y,wave=(MSD_D_AllSEMs, MSD_D_AllSEMs)
	
	// 
	ModifyGraph tick=2, mirror=0, fStyle=1, fSize=14, font="Arial"
	ModifyGraph tick(bottom)=3, fSize(bottom)=10
	ModifyGraph tkLblRot(bottom)=90
	ModifyGraph catGap(bottom)=0.3
	
	// 
	SetBarGraphSizeByItems(totalBars)
	
	Label left "\\F'Arial'\\Z14D [µm\\S2\\M\\F'Arial'\\Z14/s]"
	SetAxis left 0, *
	DoWindow/T $winName, "Compare D - Mean±SEM (All States)"
	
	SetDataFolder root:
	Print "CompareMSD_D_MeanSEM completed"
	return 0
End

// -----------------------------------------------------------------------------
// CompareMSD_MeanSEM_L - StateLMean±SEM
// AverageParticleVsMolDensByStatezColorState
// -----------------------------------------------------------------------------
Function CompareMSD_MeanSEM_L()
	EnsureComparisonFolder()
	SetDataFolder root:Comparison
	
	String sampleList = GetSampleFolderList()
	Variable numSamples = ItemsInList(sampleList)
	
	if(numSamples == 0)
		Print "No samples found"
		SetDataFolder root:
		return -1
	endif
	
	NVAR/Z Dstate = root:Dstate
	NVAR/Z cHMM = root:cHMM
	Variable maxState = 0
	if(NVAR_Exists(cHMM) && cHMM == 1 && NVAR_Exists(Dstate))
		maxState = Dstate
	endif
	
	// X: State × Sample2
	Variable totalBars = (maxState + 1) * numSamples
	Make/O/T/N=(totalBars) MSD_L_AllLabels
	Make/O/N=(totalBars) MSD_L_AllMeans = NaN
	Make/O/N=(totalBars) MSD_L_AllSEMs = NaN
	Make/O/N=(totalBars, 3) MSD_L_AllColors = 0
	
	Variable stt, barIdx, smplIdx
	Variable r, g, b
	String smplName, avgPath, semPath, stateName
	
	// Dstate
	Variable totalStates = maxState + 1
	
	barIdx = 0
	for(stt = 0; stt <= maxState; stt += 1)
		stateName = GetDstateName(stt, totalStates)
		
		for(smplIdx = 0; smplIdx < numSamples; smplIdx += 1)
			smplName = StringFromList(smplIdx, sampleList)
			
			// : -State1
			MSD_L_AllLabels[barIdx] = smplName + "-" + stateName
			
			// 
			avgPath = "root:" + smplName + ":Results:coef_MSD_S" + num2str(stt) + "_m_avg"
			semPath = "root:" + smplName + ":Results:coef_MSD_S" + num2str(stt) + "_m_sem"
			Wave/Z avgWave = $avgPath
			Wave/Z semWave = $semPath
			
			if(WaveExists(avgWave) && WaveExists(semWave))
				MSD_L_AllMeans[barIdx] = avgWave[1]  // row 1 = L
				MSD_L_AllSEMs[barIdx] = semWave[1]
			endif
			
			// State + 
			GetDstateColor(stt, r, g, b)
			if(smplIdx > 0)
				r = min(r + 15000 * smplIdx, 65535)
				g = min(g + 15000 * smplIdx, 65535)
				b = min(b + 15000 * smplIdx, 65535)
			endif
			MSD_L_AllColors[barIdx][0] = r
			MSD_L_AllColors[barIdx][1] = g
			MSD_L_AllColors[barIdx][2] = b
			
			barIdx += 1
		endfor
	endfor
	
	// 
	String winName = "CompareMSD_L_MeanSEM"
	DoWindow/K $winName
	
	Display/K=1/N=$winName MSD_L_AllMeans vs MSD_L_AllLabels
	
	// 
	ModifyGraph mode=5, hbFill=2
	ModifyGraph zColor(MSD_L_AllMeans)={MSD_L_AllColors,*,*,directRGB,0}
	ModifyGraph useBarStrokeRGB(MSD_L_AllMeans)=1, barStrokeRGB(MSD_L_AllMeans)=(0,0,0)
	
	// 
	ErrorBars MSD_L_AllMeans Y,wave=(MSD_L_AllSEMs, MSD_L_AllSEMs)
	
	// 
	ModifyGraph tick=2, mirror=0, fStyle=1, fSize=14, font="Arial"
	ModifyGraph tick(bottom)=3, fSize(bottom)=10
	ModifyGraph tkLblRot(bottom)=90
	ModifyGraph catGap(bottom)=0.3
	
	// 
	SetBarGraphSizeByItems(totalBars)
	
	Label left "\\F'Arial'\\Z14L [µm]"
	SetAxis left 0, *
	DoWindow/T $winName, "Compare L - Mean±SEM (All States)"
	
	SetDataFolder root:
	Print "CompareMSD_L_MeanSEM completed"
	return 0
End

// =============================================================================
// Compare HMMP (D-state Population)
// Δt=1step size histogram
// =============================================================================
Function CompareHMMP()
	String savedDF = GetDataFolder(1)
	String basePath = "root:"
	
	NVAR gDstate = root:Dstate
	Variable Dstate = gDstate
	
	ResetStatisticsSummaryTable()
	Print "=== Compare HMMP (D-state Population) ==="
	
	// HMMP_m  [state][cell] 2D
	String matrixBaseName = "HMMP_m"
	
	// Summary PlotS1DstateS0
	Variable stt
	String stateName, winName, outputPrefix, yLabel, graphTitle
	
	for(stt = 1; stt <= Dstate; stt += 1)
		stateName = GetDstateName(stt, Dstate)
		outputPrefix = "HMMP_S" + num2str(stt)
		winName = "Compare_HMMP_S" + num2str(stt)
		yLabel = "\\F'Arial'\\Z14Population\\B" + stateName + "\\M [%]"
		graphTitle = "Compare HMMP (S" + num2str(stt) + ": " + stateName + ")"
		
		//  + 
		CreateComparisonSummaryPlot(basePath, matrixBaseName, stt, outputPrefix, winName, yLabel, graphTitle, 1, stt)
		
		RunAutoStatisticalTest(winName)
		Print "  Compare HMMP S" + num2str(stt) + " completed"
	endfor
	
	// ========================================
	// Part 2: StateMean±SEM
	// ========================================
	String sampleList = GetSampleListFromBase(basePath)
	Variable numSamples = ItemsInList(sampleList)
	
	if(numSamples == 0)
		Print "No samples found"
		return -1
	endif
	
	String compPath = GetComparisonPathFromBase(basePath)
	SetDataFolder $compPath
	
	Variable totalBars = Dstate * numSamples
	Make/O/T/N=(totalBars) HMMP_AllLabels
	Make/O/N=(totalBars) HMMP_AllMeans = NaN
	Make/O/N=(totalBars) HMMP_AllSEMs = NaN
	Make/O/N=(totalBars, 3) HMMP_AllColors = 0
	
	Variable barIdx = 0, smplIdx
	Variable r, g, b
	String smplName, avgPath, semPath
	
	for(stt = 1; stt <= Dstate; stt += 1)
		stateName = GetDstateName(stt, Dstate)
		
		for(smplIdx = 0; smplIdx < numSamples; smplIdx += 1)
			smplName = StringFromList(smplIdx, sampleList)
			
			HMMP_AllLabels[barIdx] = smplName + "-" + stateName
			
			avgPath = basePath + smplName + ":Results:HMMP_m_avg"
			semPath = basePath + smplName + ":Results:HMMP_m_sem"
			Wave/Z avgWave = $avgPath
			Wave/Z semWave = $semPath
			
			if(WaveExists(avgWave) && WaveExists(semWave))
				if(stt < DimSize(avgWave, 0))
					HMMP_AllMeans[barIdx] = avgWave[stt]
					HMMP_AllSEMs[barIdx] = semWave[stt]
				endif
			endif
			
			GetStateColorWithShade(stt, smplIdx, numSamples, r, g, b)
			HMMP_AllColors[barIdx][0] = r
			HMMP_AllColors[barIdx][1] = g
			HMMP_AllColors[barIdx][2] = b
			
			barIdx += 1
		endfor
	endfor
	
	// State
	winName = "Compare_HMMP_All"
	DoWindow/K $winName
	
	Display/K=1/N=$winName HMMP_AllMeans vs HMMP_AllLabels
	
	ModifyGraph mode=5, hbFill=2
	ModifyGraph zColor(HMMP_AllMeans)={HMMP_AllColors,*,*,directRGB,0}
	ModifyGraph useBarStrokeRGB(HMMP_AllMeans)=1, barStrokeRGB(HMMP_AllMeans)=(0,0,0)
	
	ErrorBars HMMP_AllMeans Y,wave=(HMMP_AllSEMs, HMMP_AllSEMs)
	
	ModifyGraph tick=2, mirror=0, fStyle=1, fSize=14, font="Arial"
	ModifyGraph tick(bottom)=3, fSize(bottom)=10
	ModifyGraph tkLblRot(bottom)=90
	ModifyGraph catGap(bottom)=0.3
	
	// 
	SetBarGraphSizeByItems(totalBars)
	
	Label left "\\F'Arial'\\Z14Population [%]"
	SetAxis left 0, *
	DoWindow/T $winName, "Compare HMMP - Mean±SEM (All States)"
	
	SetDataFolder $savedDF
	Print "CompareHMMP completed"
	return 0
End

// =============================================================================
// Compare Intensity ()
// Matrix:coef_Int_S*_m CompareD
// =============================================================================
Function CompareIntensity()
	String savedDF = GetDataFolder(1)
	String basePath = "root:"
	
	NVAR gDstate = root:Dstate
	Variable Dstate = gDstate
	
	ResetStatisticsSummaryTable()
	Print "=== Compare Intensity (Mean Oligomer Size) ==="
	
	// mean_osize_m  [state][cell] 2D
	String matrixBaseName = "mean_osize_m"
	
	// Summary Plot
	Variable stt
	String stateName, winName, outputPrefix, yLabel, graphTitle
	
	for(stt = 0; stt <= Dstate; stt += 1)
		stateName = GetDstateName(stt, Dstate)
		outputPrefix = "Int_S" + num2str(stt)
		winName = "Compare_Int_S" + num2str(stt)
		yLabel = "\\F'Arial'\\Z14Mean Oligomer Size\\B" + stateName + "\\M"
		graphTitle = "Compare Mean Oligomer Size (S" + num2str(stt) + ": " + stateName + ")"
		
		//  +  (rowIndex = stt )
		CreateComparisonSummaryPlot(basePath, matrixBaseName, stt, outputPrefix, winName, yLabel, graphTitle, 1, stt)
		
		RunAutoStatisticalTest(winName)
		Print "  Compare Intensity S" + num2str(stt) + " completed"
	endfor
	
	// ========================================
	// Part 2: StateMean±SEM
	// ========================================
	String sampleList = GetSampleListFromBase(basePath)
	Variable numSamples = ItemsInList(sampleList)
	
	if(numSamples == 0)
		Print "No samples found"
		return -1
	endif
	
	String compPath = GetComparisonPathFromBase(basePath)
	SetDataFolder $compPath
	
	Variable totalBars = (Dstate + 1) * numSamples
	Make/O/T/N=(totalBars) Int_AllLabels
	Make/O/N=(totalBars) Int_AllMeans = NaN
	Make/O/N=(totalBars) Int_AllSEMs = NaN
	Make/O/N=(totalBars, 3) Int_AllColors = 0
	
	Variable barIdx = 0, smplIdx
	Variable r, g, b
	String smplName, avgPath, semPath
	
	for(stt = 0; stt <= Dstate; stt += 1)
		stateName = GetDstateName(stt, Dstate)
		
		for(smplIdx = 0; smplIdx < numSamples; smplIdx += 1)
			smplName = StringFromList(smplIdx, sampleList)
			
			Int_AllLabels[barIdx] = smplName + "-" + stateName
			
			avgPath = basePath + smplName + ":Results:mean_osize_m_avg"
			semPath = basePath + smplName + ":Results:mean_osize_m_sem"
			Wave/Z avgWave = $avgPath
			Wave/Z semWave = $semPath
			
			if(WaveExists(avgWave) && WaveExists(semWave))
				if(stt < numpnts(avgWave))
					Int_AllMeans[barIdx] = avgWave[stt]
					Int_AllSEMs[barIdx] = semWave[stt]
				endif
			endif
			
			GetStateColorWithShade(stt, smplIdx, numSamples, r, g, b)
			Int_AllColors[barIdx][0] = r
			Int_AllColors[barIdx][1] = g
			Int_AllColors[barIdx][2] = b
			
			barIdx += 1
		endfor
	endfor
	
	// State
	winName = "Compare_Int_All"
	DoWindow/K $winName
	
	Display/K=1/N=$winName Int_AllMeans vs Int_AllLabels
	
	ModifyGraph mode=5, hbFill=2
	ModifyGraph zColor(Int_AllMeans)={Int_AllColors,*,*,directRGB,0}
	ModifyGraph useBarStrokeRGB(Int_AllMeans)=1, barStrokeRGB(Int_AllMeans)=(0,0,0)
	
	ErrorBars Int_AllMeans Y,wave=(Int_AllSEMs, Int_AllSEMs)
	
	ModifyGraph tick=2, mirror=0, fStyle=1, fSize=14, font="Arial"
	ModifyGraph tick(bottom)=3, fSize(bottom)=10
	ModifyGraph tkLblRot(bottom)=90
	ModifyGraph catGap(bottom)=0.3
	
	// 
	SetBarGraphSizeByItems(totalBars)
	
	Label left "\\F'Arial'\\Z14Mean Oligomer Size"
	SetAxis left 0, *
	DoWindow/T $winName, "Compare Mean Oligomer Size - Mean±SEM (All States)"
	
	SetDataFolder $savedDF
	Print "CompareIntensity completed"
	return 0
End

// =============================================================================
// Compare LP (Localization Precision)
// Matrix:mean_LP_m CompareD
// =============================================================================
Function CompareLP()
	String savedDF = GetDataFolder(1)
	String basePath = "root:"
	
	NVAR gDstate = root:Dstate
	Variable Dstate = gDstate
	
	ResetStatisticsSummaryTable()
	Print "=== Compare LP (Localization Precision) ==="
	
	// mean_LP_m  [state][cell] 2D
	String matrixBaseName = "mean_LP_m"
	
	// Summary Plot
	Variable stt
	String stateName, winName, outputPrefix, yLabel, graphTitle
	
	for(stt = 0; stt <= Dstate; stt += 1)
		stateName = GetDstateName(stt, Dstate)
		outputPrefix = "LP_S" + num2str(stt)
		winName = "Compare_LP_S" + num2str(stt)
		yLabel = "\\F'Arial'\\Z14Mean LP\\B" + stateName + "\\M [nm]"
		graphTitle = "Compare Mean LP (S" + num2str(stt) + ": " + stateName + ")"
		
		CreateComparisonSummaryPlot(basePath, matrixBaseName, stt, outputPrefix, winName, yLabel, graphTitle, 1, stt)
		
		RunAutoStatisticalTest(winName)
		Print "  Compare LP S" + num2str(stt) + " completed"
	endfor
	
	// ========================================
	// Part 2: StateMean±SEM
	// ========================================
	String sampleList = GetSampleListFromBase(basePath)
	Variable numSamples = ItemsInList(sampleList)
	
	if(numSamples == 0)
		Print "No samples found"
		return -1
	endif
	
	String compPath = GetComparisonPathFromBase(basePath)
	SetDataFolder $compPath
	
	Variable totalBars = (Dstate + 1) * numSamples
	Make/O/T/N=(totalBars) LP_AllLabels
	Make/O/N=(totalBars) LP_AllMeans = NaN
	Make/O/N=(totalBars) LP_AllSEMs = NaN
	Make/O/N=(totalBars, 3) LP_AllColors = 0
	
	Variable barIdx = 0, smplIdx
	Variable r, g, b
	String smplName, avgPath, semPath
	
	for(stt = 0; stt <= Dstate; stt += 1)
		stateName = GetDstateName(stt, Dstate)
		
		for(smplIdx = 0; smplIdx < numSamples; smplIdx += 1)
			smplName = StringFromList(smplIdx, sampleList)
			
			LP_AllLabels[barIdx] = smplName + "-" + stateName
			
			avgPath = basePath + smplName + ":Results:mean_LP_m_avg"
			semPath = basePath + smplName + ":Results:mean_LP_m_sem"
			Wave/Z avgWave = $avgPath
			Wave/Z semWave = $semPath
			
			if(WaveExists(avgWave) && WaveExists(semWave))
				if(stt < numpnts(avgWave))
					LP_AllMeans[barIdx] = avgWave[stt]
					LP_AllSEMs[barIdx] = semWave[stt]
				endif
			endif
			
			GetStateColorWithShade(stt, smplIdx, numSamples, r, g, b)
			LP_AllColors[barIdx][0] = r
			LP_AllColors[barIdx][1] = g
			LP_AllColors[barIdx][2] = b
			
			barIdx += 1
		endfor
	endfor
	
	// State
	winName = "Compare_LP_All"
	DoWindow/K $winName
	
	Display/K=1/N=$winName LP_AllMeans vs LP_AllLabels
	
	ModifyGraph mode=5, hbFill=2
	ModifyGraph zColor(LP_AllMeans)={LP_AllColors,*,*,directRGB,0}
	ModifyGraph useBarStrokeRGB(LP_AllMeans)=1, barStrokeRGB(LP_AllMeans)=(0,0,0)
	
	ErrorBars LP_AllMeans Y,wave=(LP_AllSEMs, LP_AllSEMs)
	
	ModifyGraph tick=2, mirror=0, fStyle=1, fSize=14, font="Arial"
	ModifyGraph tick(bottom)=3, fSize(bottom)=10
	ModifyGraph tkLblRot(bottom)=90
	ModifyGraph catGap(bottom)=0.3
	
	// 
	SetBarGraphSizeByItems(totalBars)
	
	Label left "\\F'Arial'\\Z14Mean LP [nm]"
	SetAxis left 0, *
	DoWindow/T $winName, "Compare Mean LP - Mean±SEM (All States)"
	
	SetDataFolder $savedDF
	Print "CompareLP completed"
	return 0
End

// =============================================================================
// Compare Density (Particle Density & Area)
// Matrix:ParaDensityAvg_m [0]=NumPoints, [1]=Area, [2]=DensityCompareD
// =============================================================================
Function CompareDensity()
	String savedDF = GetDataFolder(1)
	String basePath = "root:"
	
	NVAR gDstate = root:Dstate
	Variable Dstate = gDstate
	
	ResetStatisticsSummaryTable()
	Print "=== Compare Particle Density ==="
	
	// ========================================
	// Part 1: State Particle Density 
	// ParticleDensity_Dstate_m [state][cell] 
	// ========================================
	Variable stt
	String stateName, winName, outputPrefix, yLabel, graphTitle
	
	for(stt = 0; stt <= Dstate; stt += 1)
		stateName = GetDstateName(stt, Dstate)
		outputPrefix = "PDens_S" + num2str(stt)
		winName = "Compare_PDens_S" + num2str(stt)
		yLabel = "\\F'Arial'\\Z14Particle Density\\B" + stateName + "\\M [/µm\\S2\\M]"
		graphTitle = "Compare Particle Density (S" + num2str(stt) + ": " + stateName + ")"
		
		CreateComparisonSummaryPlot(basePath, "ParticleDensity_Dstate_m", stt, outputPrefix, winName, yLabel, graphTitle, 1, stt)
		
		RunAutoStatisticalTest(winName)
		Print "  Compare Particle Density S" + num2str(stt) + " completed"
	endfor
	
	// ========================================
	// Part 2: Cell Area 
	// ParaDensityAvg_m [1][cell] 
	// ========================================
	outputPrefix = "Area"
	winName = "Compare_Area"
	yLabel = "\\F'Arial'\\Z14Cell Area [µm\\S2\\M]"
	graphTitle = "Compare Cell Area"
	
	CreateComparisonSummaryPlot(basePath, "ParaDensityAvg_m", 1, outputPrefix, winName, yLabel, graphTitle, 0, 0)
	
	RunAutoStatisticalTest(winName)
	Print "  Compare Cell Area completed"
	
	// ========================================
	// Part 3: NumPoints 
	// ParaDensityAvg_m [0][cell] 
	// ========================================
	outputPrefix = "NumPts"
	winName = "Compare_NumPoints"
	yLabel = "\\F'Arial'\\Z14Number of Points"
	graphTitle = "Compare Number of Points"
	
	CreateComparisonSummaryPlot(basePath, "ParaDensityAvg_m", 0, outputPrefix, winName, yLabel, graphTitle, 0, 0)
	
	RunAutoStatisticalTest(winName)
	Print "  Compare NumPoints completed"
	
	// ========================================
	// Part 4: State Particle DensityMean±SEM
	// ========================================
	String sampleList = GetSampleListFromBase(basePath)
	Variable numSamples = ItemsInList(sampleList)
	
	if(numSamples == 0)
		Print "No samples found"
		return -1
	endif
	
	String compPath = GetComparisonPathFromBase(basePath)
	SetDataFolder $compPath
	
	Variable totalBars = (Dstate + 1) * numSamples
	Make/O/T/N=(totalBars) PDens_AllLabels
	Make/O/N=(totalBars) PDens_AllMeans = NaN
	Make/O/N=(totalBars) PDens_AllSEMs = NaN
	Make/O/N=(totalBars, 3) PDens_AllColors = 0
	
	Variable barIdx = 0, smplIdx
	Variable r, g, b
	String smplName, avgPath, semPath
	
	for(stt = 0; stt <= Dstate; stt += 1)
		stateName = GetDstateName(stt, Dstate)
		
		for(smplIdx = 0; smplIdx < numSamples; smplIdx += 1)
			smplName = StringFromList(smplIdx, sampleList)
			
			PDens_AllLabels[barIdx] = smplName + "-" + stateName
			
			avgPath = basePath + smplName + ":Results:ParticleDensity_Dstate_m_avg"
			semPath = basePath + smplName + ":Results:ParticleDensity_Dstate_m_sem"
			Wave/Z avgWave = $avgPath
			Wave/Z semWave = $semPath
			
			if(WaveExists(avgWave) && WaveExists(semWave))
				if(stt < numpnts(avgWave))
					PDens_AllMeans[barIdx] = avgWave[stt]
					PDens_AllSEMs[barIdx] = semWave[stt]
				endif
			endif
			
			GetStateColorWithShade(stt, smplIdx, numSamples, r, g, b)
			PDens_AllColors[barIdx][0] = r
			PDens_AllColors[barIdx][1] = g
			PDens_AllColors[barIdx][2] = b
			
			barIdx += 1
		endfor
	endfor
	
	// State
	winName = "Compare_PDens_All"
	DoWindow/K $winName
	
	Display/K=1/N=$winName PDens_AllMeans vs PDens_AllLabels
	
	ModifyGraph mode=5, hbFill=2
	ModifyGraph zColor(PDens_AllMeans)={PDens_AllColors,*,*,directRGB,0}
	ModifyGraph useBarStrokeRGB(PDens_AllMeans)=1, barStrokeRGB(PDens_AllMeans)=(0,0,0)
	
	ErrorBars PDens_AllMeans Y,wave=(PDens_AllSEMs, PDens_AllSEMs)
	
	ModifyGraph tick=2, mirror=0, fStyle=1, fSize=14, font="Arial"
	ModifyGraph tick(bottom)=3, fSize(bottom)=10
	ModifyGraph tkLblRot(bottom)=90
	ModifyGraph catGap(bottom)=0.3
	
	// 
	SetBarGraphSizeByItems(totalBars)
	
	Label left "\\F'Arial'\\Z14Particle Density [/µm\\S2\\M]"
	SetAxis left 0, *
	DoWindow/T $winName, "Compare Particle Density - Mean±SEM (All States)"
	
	SetDataFolder $savedDF
	Print "CompareDensity completed"
	return 0
End

// =============================================================================
// Compare Molecular Density
// Matrix:MolDensity_Dstate_m CompareD
// =============================================================================
Function CompareMolDensity()
	String savedDF = GetDataFolder(1)
	String basePath = "root:"
	
	NVAR gDstate = root:Dstate
	Variable Dstate = gDstate
	
	ResetStatisticsSummaryTable()
	Print "=== Compare Molecular Density ==="
	
	// Summary Plot
	Variable stt
	String stateName, winName, outputPrefix, yLabel, graphTitle
	
	for(stt = 0; stt <= Dstate; stt += 1)
		stateName = GetDstateName(stt, Dstate)
		outputPrefix = "MolDens_S" + num2str(stt)
		winName = "Compare_MolDens_S" + num2str(stt)
		yLabel = "\\F'Arial'\\Z14Mol. Density\\B" + stateName + "\\M [/µm\\S2\\M]"
		graphTitle = "Compare Molecular Density (S" + num2str(stt) + ": " + stateName + ")"
		
		CreateComparisonSummaryPlot(basePath, "MolDensity_Dstate_m", stt, outputPrefix, winName, yLabel, graphTitle, 1, stt)
		
		RunAutoStatisticalTest(winName)
		Print "  Compare Mol. Density S" + num2str(stt) + " completed"
	endfor
	
	// ========================================
	// Part 2: State Molecular DensityMean±SEM
	// ========================================
	String sampleList = GetSampleListFromBase(basePath)
	Variable numSamples = ItemsInList(sampleList)
	
	if(numSamples == 0)
		Print "No samples found"
		return -1
	endif
	
	String compPath = GetComparisonPathFromBase(basePath)
	SetDataFolder $compPath
	
	Variable totalBars = (Dstate + 1) * numSamples
	Make/O/T/N=(totalBars) MolDens_AllLabels
	Make/O/N=(totalBars) MolDens_AllMeans = NaN
	Make/O/N=(totalBars) MolDens_AllSEMs = NaN
	Make/O/N=(totalBars, 3) MolDens_AllColors = 0
	
	Variable barIdx = 0, smplIdx
	Variable r, g, b
	String smplName, avgPath, semPath
	
	for(stt = 0; stt <= Dstate; stt += 1)
		stateName = GetDstateName(stt, Dstate)
		
		for(smplIdx = 0; smplIdx < numSamples; smplIdx += 1)
			smplName = StringFromList(smplIdx, sampleList)
			
			MolDens_AllLabels[barIdx] = smplName + "-" + stateName
			
			avgPath = basePath + smplName + ":Results:MolDensity_Dstate_m_avg"
			semPath = basePath + smplName + ":Results:MolDensity_Dstate_m_sem"
			Wave/Z avgWave = $avgPath
			Wave/Z semWave = $semPath
			
			if(WaveExists(avgWave) && WaveExists(semWave))
				if(stt < numpnts(avgWave))
					MolDens_AllMeans[barIdx] = avgWave[stt]
					MolDens_AllSEMs[barIdx] = semWave[stt]
				endif
			endif
			
			GetStateColorWithShade(stt, smplIdx, numSamples, r, g, b)
			MolDens_AllColors[barIdx][0] = r
			MolDens_AllColors[barIdx][1] = g
			MolDens_AllColors[barIdx][2] = b
			
			barIdx += 1
		endfor
	endfor
	
	// State
	winName = "Compare_MolDens_All"
	DoWindow/K $winName
	
	Display/K=1/N=$winName MolDens_AllMeans vs MolDens_AllLabels
	
	ModifyGraph mode=5, hbFill=2
	ModifyGraph zColor(MolDens_AllMeans)={MolDens_AllColors,*,*,directRGB,0}
	ModifyGraph useBarStrokeRGB(MolDens_AllMeans)=1, barStrokeRGB(MolDens_AllMeans)=(0,0,0)
	
	ErrorBars MolDens_AllMeans Y,wave=(MolDens_AllSEMs, MolDens_AllSEMs)
	
	ModifyGraph tick=2, mirror=0, fStyle=1, fSize=14, font="Arial"
	ModifyGraph tick(bottom)=3, fSize(bottom)=10
	ModifyGraph tkLblRot(bottom)=90
	ModifyGraph catGap(bottom)=0.3
	
	// 
	SetBarGraphSizeByItems(totalBars)
	
	Label left "\\F'Arial'\\Z14Molecular Density [/µm\\S2\\M]"
	SetAxis left 0, *
	DoWindow/T $winName, "Compare Molecular Density - Mean±SEM (All States)"
	
	SetDataFolder $savedDF
	Print "CompareMolDensity completed"
	return 0
End

// =============================================================================
// Compare On-Time
// Matrix:Tau_Duration_m, Fraction_Duration_m CompareD
// =============================================================================
Function CompareOnTime()
	String savedDF = GetDataFolder(1)
	String basePath = "root:"
	
	// ExpMax_offOn-time
	NVAR gExpMax = root:ExpMax_off
	Variable expMax = gExpMax
	
	ResetStatisticsSummaryTable()
	Print "=== Compare On-Time (tau & kinetic state fractions) ==="
	
	String sampleList = GetSampleListFromBase(basePath)
	Variable numSamples = ItemsInList(sampleList)
	
	if(numSamples == 0)
		Print "No samples found"
		return -1
	endif
	
	String compPath = GetComparisonPathFromBase(basePath)
	EnsureComparisonFolderForBase(basePath)
	SetDataFolder $compPath
	
	// Wave
	Make/O/T/N=(numSamples) SampleNames
	Variable i
	for(i = 0; i < numSamples; i += 1)
		SampleNames[i] = StringFromList(i, sampleList)
	endfor
	
	Variable smplIdx, compIdx, cellIdx, nCells
	String smplName, matrixPath, avgPath, semPath
	String cellDataName, firstViolinTrace
	Variable r, g, b
	
	// ========================================
	// tau
	// ========================================
	for(compIdx = 1; compIdx <= expMax; compIdx += 1)
		String winName = "Compare_Tau_C" + num2str(compIdx)
		String outputPrefix = "Tau_C" + num2str(compIdx)
		String yLabel = "\\F'Arial'\\Z14τ" + num2str(compIdx) + " [s]"
		String graphTitle = "Compare On-Time τ" + num2str(compIdx)
		
		//  +  (rowIndex = compIdx-1)
		CreateComparisonSummaryPlot(basePath, "Tau_Duration_m", compIdx-1, outputPrefix, winName, yLabel, graphTitle, 0, 0)
		
		RunAutoStatisticalTest(winName)
		Print "  Compare Tau component " + num2str(compIdx) + " completed"
	endfor
	
	// ========================================
	// Kinetic state fraction (A1, A2, ...)
	// ========================================
	for(compIdx = 1; compIdx <= expMax; compIdx += 1)
		winName = "Compare_Frac_C" + num2str(compIdx)
		outputPrefix = "Frac_C" + num2str(compIdx)
		yLabel = "\\F'Arial'\\Z14Fraction" + num2str(compIdx) + " [%]"
		graphTitle = "Compare Kinetic State Fraction " + num2str(compIdx)
		
		//  + 
		CreateComparisonSummaryPlot(basePath, "Fraction_Duration_m", compIdx-1, outputPrefix, winName, yLabel, graphTitle, 0, 0)
		
		RunAutoStatisticalTest(winName)
		Print "  Compare Fraction component " + num2str(compIdx) + " completed"
	endfor
	
	// ========================================
	// Part 3: TauMean±SEM
	// ========================================
	Variable totalBars = expMax * numSamples
	Make/O/T/N=(totalBars) Tau_AllLabels
	Make/O/N=(totalBars) Tau_AllMeans = NaN
	Make/O/N=(totalBars) Tau_AllSEMs = NaN
	Make/O/N=(totalBars, 3) Tau_AllColors = 0
	
	Variable barIdx = 0
	for(compIdx = 1; compIdx <= expMax; compIdx += 1)
		for(smplIdx = 0; smplIdx < numSamples; smplIdx += 1)
			smplName = StringFromList(smplIdx, sampleList)
			
			Tau_AllLabels[barIdx] = smplName + "-τ" + num2str(compIdx)
			
			avgPath = basePath + smplName + ":Results:Tau_Duration_m_avg"
			semPath = basePath + smplName + ":Results:Tau_Duration_m_sem"
			Wave/Z avgWave = $avgPath
			Wave/Z semWave = $semPath
			
			if(WaveExists(avgWave) && WaveExists(semWave))
				if(compIdx - 1 < DimSize(avgWave, 0))
					Tau_AllMeans[barIdx] = avgWave[compIdx - 1]
					Tau_AllSEMs[barIdx] = semWave[compIdx - 1]
				endif
			endif
			
			GetStateColorWithShade(compIdx, smplIdx, numSamples, r, g, b)
			Tau_AllColors[barIdx][0] = r
			Tau_AllColors[barIdx][1] = g
			Tau_AllColors[barIdx][2] = b
			
			barIdx += 1
		endfor
	endfor
	
	// 
	winName = "Compare_Tau_All"
	DoWindow/K $winName
	
	Display/K=1/N=$winName Tau_AllMeans vs Tau_AllLabels
	
	ModifyGraph mode=5, hbFill=2
	ModifyGraph zColor(Tau_AllMeans)={Tau_AllColors,*,*,directRGB,0}
	ModifyGraph useBarStrokeRGB(Tau_AllMeans)=1, barStrokeRGB(Tau_AllMeans)=(0,0,0)
	
	ErrorBars Tau_AllMeans Y,wave=(Tau_AllSEMs, Tau_AllSEMs)
	
	ModifyGraph tick=2, mirror=0, fStyle=1, fSize=14, font="Arial"
	ModifyGraph tick(bottom)=3, tkLblRot(bottom)=90, catGap(bottom)=0.3
	ModifyGraph fSize(bottom)=10
	
	// 
	SetBarGraphSizeByItems(totalBars)
	
	Label left "\\F'Arial'\\Z14τ [s]"
	SetAxis left 0, *
	DoWindow/T $winName, "Compare On-Time τ - Mean±SEM (All Components)"
	
	// ========================================
	// Part 4: FractionMean±SEM
	// ========================================
	Make/O/T/N=(totalBars) Frac_AllLabels
	Make/O/N=(totalBars) Frac_AllMeans = NaN
	Make/O/N=(totalBars) Frac_AllSEMs = NaN
	Make/O/N=(totalBars, 3) Frac_AllColors = 0
	
	barIdx = 0
	for(compIdx = 1; compIdx <= expMax; compIdx += 1)
		for(smplIdx = 0; smplIdx < numSamples; smplIdx += 1)
			smplName = StringFromList(smplIdx, sampleList)
			
			Frac_AllLabels[barIdx] = smplName + "-A" + num2str(compIdx)
			
			avgPath = basePath + smplName + ":Results:Fraction_Duration_m_avg"
			semPath = basePath + smplName + ":Results:Fraction_Duration_m_sem"
			Wave/Z avgWave = $avgPath
			Wave/Z semWave = $semPath
			
			if(WaveExists(avgWave) && WaveExists(semWave))
				if(compIdx - 1 < DimSize(avgWave, 0))
					Frac_AllMeans[barIdx] = avgWave[compIdx - 1]
					Frac_AllSEMs[barIdx] = semWave[compIdx - 1]
				endif
			endif
			
			GetStateColorWithShade(compIdx, smplIdx, numSamples, r, g, b)
			Frac_AllColors[barIdx][0] = r
			Frac_AllColors[barIdx][1] = g
			Frac_AllColors[barIdx][2] = b
			
			barIdx += 1
		endfor
	endfor
	
	// 
	winName = "Compare_Fraction_All"
	DoWindow/K $winName
	
	Display/K=1/N=$winName Frac_AllMeans vs Frac_AllLabels
	
	ModifyGraph mode=5, hbFill=2
	ModifyGraph zColor(Frac_AllMeans)={Frac_AllColors,*,*,directRGB,0}
	ModifyGraph useBarStrokeRGB(Frac_AllMeans)=1, barStrokeRGB(Frac_AllMeans)=(0,0,0)
	
	ErrorBars Frac_AllMeans Y,wave=(Frac_AllSEMs, Frac_AllSEMs)
	
	ModifyGraph tick=2, mirror=0, fStyle=1, fSize=14, font="Arial"
	ModifyGraph tick(bottom)=3, tkLblRot(bottom)=90, catGap(bottom)=0.3
	ModifyGraph fSize(bottom)=10
	
	// 
	SetBarGraphSizeByItems(totalBars)
	
	Label left "\\F'Arial'\\Z14Fraction [%]"
	SetAxis left 0, *
	DoWindow/T $winName, "Compare Kinetic State Fraction - Mean±SEM (All Components)"
	
	SetDataFolder $savedDF
	Print "CompareOnTime completed"
	return 0
End

// =============================================================================
// Compare On-rate
// Matrix:ParaOnrate_S*_m [1]=OnRateCompareD
// =============================================================================
Function CompareOnRate()
	String savedDF = GetDataFolder(1)
	String basePath = "root:"
	
	NVAR gDstate = root:Dstate
	Variable Dstate = gDstate
	
	ResetStatisticsSummaryTable()
	Print "=== Compare On-rate ==="
	
	String sampleList = GetSampleListFromBase(basePath)
	Variable numSamples = ItemsInList(sampleList)
	
	if(numSamples == 0)
		Print "No samples found"
		return -1
	endif
	
	String compPath = GetComparisonPathFromBase(basePath)
	EnsureComparisonFolderForBase(basePath)
	SetDataFolder $compPath
	
	// Wave
	Make/O/T/N=(numSamples) SampleNames
	Variable i
	for(i = 0; i < numSamples; i += 1)
		SampleNames[i] = StringFromList(i, sampleList)
	endfor
	
	Variable stt, smplIdx, cellIdx, nCells
	String smplName, matrixPath, avgPath, semPath, stateName
	String cellDataName, firstViolinTrace
	Variable r, g, b
	
	for(stt = 0; stt <= Dstate; stt += 1)
		stateName = GetDstateName(stt, Dstate)
		String winName = "Compare_OnRate_S" + num2str(stt)
		DoWindow/K $winName
		
		String meanWaveName = "OnRate_mean_S" + num2str(stt)
		String semWaveName = "OnRate_sem_S" + num2str(stt)
		String colorWaveName = "OnRate_colors_S" + num2str(stt)
		Make/O/N=(numSamples) $meanWaveName = NaN
		Make/O/N=(numSamples) $semWaveName = NaN
		Wave OnR_meanW = $meanWaveName
		Wave OnR_semW = $semWaveName
		
		Make/O/N=(numSamples, 3) $colorWaveName = 0
		Wave BarColors = $colorWaveName
		
		firstViolinTrace = ""
		
		for(smplIdx = 0; smplIdx < numSamples; smplIdx += 1)
			smplName = StringFromList(smplIdx, sampleList)
			
			matrixPath = basePath + smplName + ":Matrix:ParaOnrate_S" + num2str(stt) + "_m"
			Wave/Z onrateMatrix = $matrixPath
			
			if(!WaveExists(onrateMatrix))
				// S0ParaOnrate_m
				if(stt == 0)
					matrixPath = basePath + smplName + ":Matrix:ParaOnrate_m"
					Wave/Z onrateMatrix = $matrixPath
				endif
			endif
			
			if(!WaveExists(onrateMatrix))
				Print "  Warning: ParaOnrate_S" + num2str(stt) + "_m not found for " + smplName
				continue
			endif
			
			nCells = DimSize(onrateMatrix, 1)
			if(nCells == 0)
				continue
			endif
			
			// Cell data1 = OnRate
			cellDataName = "OnRate_S" + num2str(stt) + "_" + smplName
			Make/O/N=(nCells) $cellDataName = NaN
			Wave cellData = $cellDataName
			
			for(cellIdx = 0; cellIdx < nCells; cellIdx += 1)
				cellData[cellIdx] = onrateMatrix[1][cellIdx]
			endfor
			
			WaveTransform zapNaNs cellData
			
			avgPath = basePath + smplName + ":Results:ParaOnrate_S" + num2str(stt) + "_m_avg"
			semPath = basePath + smplName + ":Results:ParaOnrate_S" + num2str(stt) + "_m_sem"
			Wave/Z avgWave = $avgPath
			Wave/Z semWave = $semPath
			
			if(!WaveExists(avgWave) && stt == 0)
				avgPath = basePath + smplName + ":Results:ParaOnrate_m_avg"
				semPath = basePath + smplName + ":Results:ParaOnrate_m_sem"
				Wave/Z avgWave = $avgPath
				Wave/Z semWave = $semPath
			endif
			
			if(WaveExists(avgWave) && WaveExists(semWave))
				OnR_meanW[smplIdx] = avgWave[1]
				OnR_semW[smplIdx] = semWave[1]
			endif
			
			GetStateColorWithShade(stt, smplIdx, numSamples, r, g, b)
			BarColors[smplIdx][0] = r
			BarColors[smplIdx][1] = g
			BarColors[smplIdx][2] = b
			
			if(strlen(firstViolinTrace) == 0 && numpnts(cellData) > 0)
				firstViolinTrace = cellDataName
			endif
		endfor
		
		// 
		Display/K=1/N=$winName OnR_meanW vs SampleNames
		ModifyGraph mode($meanWaveName)=5, hbFill($meanWaveName)=2
		ModifyGraph zColor($meanWaveName)={BarColors,*,*,directRGB,0}
		ModifyGraph useBarStrokeRGB($meanWaveName)=1, barStrokeRGB($meanWaveName)=(0,0,0)
		ErrorBars $meanWaveName Y,wave=(OnR_semW, OnR_semW)
		
		// Violin Plot
		Variable firstViolin = 1
		for(smplIdx = 0; smplIdx < numSamples; smplIdx += 1)
			smplName = StringFromList(smplIdx, sampleList)
			cellDataName = "OnRate_S" + num2str(stt) + "_" + smplName
			Wave/Z cellData = $cellDataName
			
			if(!WaveExists(cellData) || numpnts(cellData) == 0)
				continue
			endif
			
			if(firstViolin)
				AppendViolinPlot/T cellData vs SampleNames
				firstViolin = 0
			else
				AddWavesToViolinPlot/T=$firstViolinTrace cellData
			endif
		endfor
		
		if(strlen(firstViolinTrace) > 0)
			ModifyViolinPlot trace=$firstViolinTrace, LineColor=(65535,65535,65535,0)
			ModifyViolinPlot trace=$firstViolinTrace, DataMarker=19, MarkerColor=(0,0,0)
		endif
		
		ModifyGraph noLabel(top)=2, axThick(top)=0
		ModifyGraph tick(top)=3
		
		ModifyGraph tick=2, mirror=0, fStyle=1, fSize=14, font="Arial"
		ModifyGraph tick(bottom)=3, tkLblRot(bottom)=90, catGap(bottom)=0.5
		
		// 
		SetBarGraphSizeByItems(numSamples, baseWidth=150, widthPerItem=30)
		
		Label left "\\F'Arial'\\Z14On-rate\\B" + stateName + "\\M [/µm\\S2\\M/s]"
		SetAxis left 0, *
		DoWindow/T $winName, "Compare On-rate (S" + num2str(stt) + ": " + stateName + ")"
		
		RunAutoStatisticalTest(winName)
		Print "  Compare On-rate S" + num2str(stt) + " completed"
	endfor
	
	// ========================================
	// Part 2: StateMean±SEM
	// ========================================
	Variable totalBars = (Dstate + 1) * numSamples
	Make/O/T/N=(totalBars) OnRate_AllLabels
	Make/O/N=(totalBars) OnRate_AllMeans = NaN
	Make/O/N=(totalBars) OnRate_AllSEMs = NaN
	Make/O/N=(totalBars, 3) OnRate_AllColors = 0
	
	Variable barIdx = 0
	for(stt = 0; stt <= Dstate; stt += 1)
		stateName = GetDstateName(stt, Dstate)
		
		for(smplIdx = 0; smplIdx < numSamples; smplIdx += 1)
			smplName = StringFromList(smplIdx, sampleList)
			
			OnRate_AllLabels[barIdx] = smplName + "-" + stateName
			
			avgPath = basePath + smplName + ":Results:ParaOnrate_S" + num2str(stt) + "_m_avg"
			semPath = basePath + smplName + ":Results:ParaOnrate_S" + num2str(stt) + "_m_sem"
			Wave/Z avgWave = $avgPath
			Wave/Z semWave = $semPath
			
			if(!WaveExists(avgWave) && stt == 0)
				avgPath = basePath + smplName + ":Results:ParaOnrate_m_avg"
				semPath = basePath + smplName + ":Results:ParaOnrate_m_sem"
				Wave/Z avgWave = $avgPath
				Wave/Z semWave = $semPath
			endif
			
			if(WaveExists(avgWave) && WaveExists(semWave))
				OnRate_AllMeans[barIdx] = avgWave[1]
				OnRate_AllSEMs[barIdx] = semWave[1]
			endif
			
			GetStateColorWithShade(stt, smplIdx, numSamples, r, g, b)
			OnRate_AllColors[barIdx][0] = r
			OnRate_AllColors[barIdx][1] = g
			OnRate_AllColors[barIdx][2] = b
			
			barIdx += 1
		endfor
	endfor
	
	// State
	winName = "Compare_OnRate_All"
	DoWindow/K $winName
	
	Display/K=1/N=$winName OnRate_AllMeans vs OnRate_AllLabels
	
	ModifyGraph mode=5, hbFill=2
	ModifyGraph zColor(OnRate_AllMeans)={OnRate_AllColors,*,*,directRGB,0}
	ModifyGraph useBarStrokeRGB(OnRate_AllMeans)=1, barStrokeRGB(OnRate_AllMeans)=(0,0,0)
	
	ErrorBars OnRate_AllMeans Y,wave=(OnRate_AllSEMs, OnRate_AllSEMs)
	
	ModifyGraph tick=2, mirror=0, fStyle=1, fSize=14, font="Arial"
	ModifyGraph tick(bottom)=3, tkLblRot(bottom)=90, catGap(bottom)=0.3
	ModifyGraph fSize(bottom)=10
	
	// 
	SetBarGraphSizeByItems(totalBars)
	
	Label left "\\F'Arial'\\Z14On-rate [/µm\\S2\\M/s]"
	SetAxis left 0, *
	DoWindow/T $winName, "Compare On-rate - Mean±SEM (All States)"
	
	SetDataFolder $savedDF
	Print "CompareOnRate completed"
	return 0
End

// =============================================================================
// Compare State Transition Kinetics
// Matrix:TauValues_cell_m τcKinOutputTau=0k=1/τ
// =============================================================================
Function CompareStateTransKinetics()
	EnsureComparisonFolder()
	SetDataFolder root:Comparison
	
	String sampleList = GetSampleFolderList()
	Variable numSamples = ItemsInList(sampleList)
	
	if(numSamples == 0)
		Print "No samples found"
		SetDataFolder root:
		return -1
	endif
	
	NVAR gDstate = root:Dstate
	Variable Dstate = gDstate
	
	NVAR/Z cKinOutputTau = root:cKinOutputTau
	Variable outputTau = NVAR_Exists(cKinOutputTau) ? cKinOutputTau : 1
	
	// WaveASCII
	String outputName = SelectString(outputTau, "k", "Tau")
	// 
	String outputLabel = SelectString(outputTau, "k", "τ")
	String unitLabel = SelectString(outputTau, "k [/s]", "τ [s]")
	
	ResetStatisticsSummaryTable()
	Print "=== Compare State Transition Kinetics (" + outputLabel + ") ==="
	
	// Wave
	Make/O/T/N=(numSamples) SampleNames
	Variable i
	for(i = 0; i < numSamples; i += 1)
		SampleNames[i] = StringFromList(i, sampleList)
	endfor
	
	Variable smplIdx, cellIdx, nCells, tauIdx
	String smplName, matrixPath, avgPath, semPath
	String cellDataName, firstViolinTrace, paramLabel
	Variable r, g, b
	
	Variable numDwell = Dstate
	Variable numTrans = Dstate * (Dstate - 1)
	Variable numTotal = numDwell + numTrans
	
	// 
	String prefix = SelectString(outputTau, "k_", "τ_")
	Make/O/T/N=(numTotal) TauIndexLabels
	Make/O/N=(numTotal, 2) TauIndexMap
	
	Variable idx = 0
	Variable fromS, toS
	
	// Dwell times
	for(i = 0; i < Dstate; i += 1)
		TauIndexLabels[idx] = prefix + num2str(i+1) + num2str(i+1) + " (dwell)"
		TauIndexMap[idx][0] = i + 1
		TauIndexMap[idx][1] = i + 1
		idx += 1
	endfor
	
	// Transition times
	for(fromS = 1; fromS <= Dstate; fromS += 1)
		for(toS = 1; toS <= Dstate; toS += 1)
			if(fromS != toS)
				TauIndexLabels[idx] = prefix + num2str(fromS) + num2str(toS)
				TauIndexMap[idx][0] = fromS
				TauIndexMap[idx][1] = toS
				idx += 1
			endif
		endfor
	endfor
	
	// ========================================
	// Part 1: τ/kSummary Plot
	// ========================================
	for(tauIdx = 0; tauIdx < numTotal; tauIdx += 1)
		paramLabel = TauIndexLabels[tauIdx]
		fromS = TauIndexMap[tauIdx][0]
		toS = TauIndexMap[tauIdx][1]
		
		String winName
		String meanWaveName, semWaveName, colorWaveName
		
		if(fromS == toS)
			winName = "Compare_" + outputName + "_S" + num2str(fromS) + "_dwell"
			meanWaveName = outputName + "_mean_S" + num2str(fromS) + "_dwell"
			semWaveName = outputName + "_sem_S" + num2str(fromS) + "_dwell"
			colorWaveName = outputName + "_colors_S" + num2str(fromS) + "_dwell"
		else
			winName = "Compare_" + outputName + "_S" + num2str(fromS) + "to" + num2str(toS)
			meanWaveName = outputName + "_mean_S" + num2str(fromS) + "to" + num2str(toS)
			semWaveName = outputName + "_sem_S" + num2str(fromS) + "to" + num2str(toS)
			colorWaveName = outputName + "_colors_S" + num2str(fromS) + "to" + num2str(toS)
		endif
		
		DoWindow/K $winName
		
		Make/O/N=(numSamples) $meanWaveName = NaN
		Make/O/N=(numSamples) $semWaveName = NaN
		Wave Param_meanW = $meanWaveName
		Wave Param_semW = $semWaveName
		
		Make/O/N=(numSamples, 3) $colorWaveName = 0
		Wave BarColors = $colorWaveName
		
		Variable baseR, baseG, baseB
		GetDstateColor(fromS, baseR, baseG, baseB)
		
		firstViolinTrace = ""
		
		for(smplIdx = 0; smplIdx < numSamples; smplIdx += 1)
			smplName = StringFromList(smplIdx, sampleList)
			
			matrixPath = "root:" + smplName + ":Matrix:TauValues_cell_m"
			Wave/Z tauMatrix = $matrixPath
			
			if(!WaveExists(tauMatrix))
				Print "  Warning: TauValues_cell_m not found for " + smplName
				continue
			endif
			
			nCells = DimSize(tauMatrix, 1)
			if(nCells == 0)
				continue
			endif
			
			// Cell data
			if(fromS == toS)
				cellDataName = outputName + "_S" + num2str(fromS) + "_dwell_" + smplName
			else
				cellDataName = outputName + "_S" + num2str(fromS) + "to" + num2str(toS) + "_" + smplName
			endif
			Make/O/N=(nCells) $cellDataName = NaN
			Wave cellData = $cellDataName
			
			for(cellIdx = 0; cellIdx < nCells; cellIdx += 1)
				Variable tauVal = tauMatrix[tauIdx][cellIdx]
				if(outputTau)
					cellData[cellIdx] = tauVal
				else
					// k = 1/τ
					if(tauVal > 0 && numtype(tauVal) == 0)
						cellData[cellIdx] = 1 / tauVal
					endif
				endif
			endfor
			
			WaveTransform zapNaNs cellData
			
			// 
			if(numpnts(cellData) > 0)
				WaveStats/Q cellData
				Param_meanW[smplIdx] = V_avg
				if(V_npnts > 1)
					Param_semW[smplIdx] = V_sdev / sqrt(V_npnts)
				endif
			endif
			
			r = baseR
			g = baseG
			b = baseB
			if(smplIdx > 0)
				r = min(baseR + 15000 * smplIdx, 65535)
				g = min(baseG + 15000 * smplIdx, 65535)
				b = min(baseB + 15000 * smplIdx, 65535)
			endif
			BarColors[smplIdx][0] = r
			BarColors[smplIdx][1] = g
			BarColors[smplIdx][2] = b
			
			if(strlen(firstViolinTrace) == 0 && numpnts(cellData) > 0)
				firstViolinTrace = cellDataName
			endif
		endfor
		
		// 
		Display/K=1/N=$winName Param_meanW vs SampleNames
		ModifyGraph mode($meanWaveName)=5, hbFill($meanWaveName)=2
		ModifyGraph zColor($meanWaveName)={BarColors,*,*,directRGB,0}
		ModifyGraph useBarStrokeRGB($meanWaveName)=1, barStrokeRGB($meanWaveName)=(0,0,0)
		ErrorBars $meanWaveName Y,wave=(Param_semW, Param_semW)
		
		// Violin Plot
		Variable firstViolin = 1
		for(smplIdx = 0; smplIdx < numSamples; smplIdx += 1)
			smplName = StringFromList(smplIdx, sampleList)
			if(fromS == toS)
				cellDataName = outputName + "_S" + num2str(fromS) + "_dwell_" + smplName
			else
				cellDataName = outputName + "_S" + num2str(fromS) + "to" + num2str(toS) + "_" + smplName
			endif
			Wave/Z cellData = $cellDataName
			
			if(!WaveExists(cellData) || numpnts(cellData) == 0)
				continue
			endif
			
			if(firstViolin)
				AppendViolinPlot/T cellData vs SampleNames
				firstViolin = 0
			else
				AddWavesToViolinPlot/T=$firstViolinTrace cellData
			endif
		endfor
		
		if(strlen(firstViolinTrace) > 0)
			ModifyViolinPlot trace=$firstViolinTrace, LineColor=(65535,65535,65535,0)
			ModifyViolinPlot trace=$firstViolinTrace, DataMarker=19, MarkerColor=(0,0,0)
		endif
		
		ModifyGraph noLabel(top)=2, axThick(top)=0
		ModifyGraph tick(top)=3
		
		ModifyGraph tick=2, mirror=0, fStyle=1, fSize=14, font="Arial"
		ModifyGraph tick(bottom)=3
		ModifyGraph tkLblRot(bottom)=90
		ModifyGraph catGap(bottom)=0.5
		
		// 
		SetBarGraphSizeByItems(numSamples, baseWidth=150, widthPerItem=30)
		
		Label left "\\F'Arial'\\Z14" + unitLabel
		SetAxis left 0, *
		
		String graphTitle
		if(fromS == toS)
			String stateName = GetDstateName(fromS, Dstate)
			graphTitle = "Compare " + paramLabel + " (" + stateName + " dwell)"
		else
			String fromName = GetDstateName(fromS, Dstate)
			String toName = GetDstateName(toS, Dstate)
			graphTitle = "Compare " + paramLabel + " (" + fromName + "→" + toName + ")"
		endif
		DoWindow/T $winName, graphTitle
		
		RunAutoStatisticalTest(winName)
		Print "  " + graphTitle + " completed"
	endfor
	
	// ========================================
	// Part 2: τ/kMean±SEM
	// ========================================
	Variable totalBars = numTotal * numSamples
	Make/O/T/N=(totalBars) Trans_AllLabels
	Make/O/N=(totalBars) Trans_AllMeans = NaN
	Make/O/N=(totalBars) Trans_AllSEMs = NaN
	Make/O/N=(totalBars, 3) Trans_AllColors = 0
	
	Variable barIdx = 0
	
	for(tauIdx = 0; tauIdx < numTotal; tauIdx += 1)
		paramLabel = TauIndexLabels[tauIdx]
		fromS = TauIndexMap[tauIdx][0]
		
		GetDstateColor(fromS, baseR, baseG, baseB)
		
		for(smplIdx = 0; smplIdx < numSamples; smplIdx += 1)
			smplName = StringFromList(smplIdx, sampleList)
			
			Trans_AllLabels[barIdx] = smplName + "-" + paramLabel
			
			// 
			if(fromS == TauIndexMap[tauIdx][1])
				cellDataName = outputName + "_S" + num2str(fromS) + "_dwell_" + smplName
			else
				cellDataName = outputName + "_S" + num2str(fromS) + "to" + num2str(TauIndexMap[tauIdx][1]) + "_" + smplName
			endif
			Wave/Z cellData = $cellDataName
			if(WaveExists(cellData) && numpnts(cellData) > 0)
				WaveStats/Q cellData
				Trans_AllMeans[barIdx] = V_avg
				if(V_npnts > 1)
					Trans_AllSEMs[barIdx] = V_sdev / sqrt(V_npnts)
				endif
			endif
			
			r = baseR
			g = baseG
			b = baseB
			if(smplIdx > 0)
				r = min(baseR + 15000 * smplIdx, 65535)
				g = min(baseG + 15000 * smplIdx, 65535)
				b = min(baseB + 15000 * smplIdx, 65535)
			endif
			Trans_AllColors[barIdx][0] = r
			Trans_AllColors[barIdx][1] = g
			Trans_AllColors[barIdx][2] = b
			
			barIdx += 1
		endfor
	endfor
	
	// 
	winName = "Compare_Trans_All"
	DoWindow/K $winName
	
	Display/K=1/N=$winName Trans_AllMeans vs Trans_AllLabels
	
	ModifyGraph mode=5, hbFill=2
	ModifyGraph zColor(Trans_AllMeans)={Trans_AllColors,*,*,directRGB,0}
	ModifyGraph useBarStrokeRGB(Trans_AllMeans)=1, barStrokeRGB(Trans_AllMeans)=(0,0,0)
	
	ErrorBars Trans_AllMeans Y,wave=(Trans_AllSEMs, Trans_AllSEMs)
	
	ModifyGraph tick=2, mirror=0, fStyle=1, fSize=14, font="Arial"
	ModifyGraph tick(bottom)=3, fSize(bottom)=10
	ModifyGraph tkLblRot(bottom)=90
	ModifyGraph catGap(bottom)=0.3
	
	// 
	SetBarGraphSizeByItems(totalBars)
	
	Label left "\\F'Arial'\\Z14" + unitLabel
	SetAxis left 0, *
	DoWindow/T $winName, "Compare State Transition Kinetics (" + outputLabel + ") - Mean±SEM (All)"
	
	SetDataFolder root:
	Print "CompareStateTransKinetics completed"
	return 0
End

// =============================================================================
// : X
// =============================================================================
Function SetCategoryLabelsFromSamples(graphName, sampleList)
	String graphName, sampleList
	
	Variable numSamples = ItemsInList(sampleList)
	if(numSamples == 0)
		return -1
	endif
	
	// X
	String labelWaveName = "XLabels_" + graphName
	Make/O/T/N=(numSamples) root:Comparison:$labelWaveName
	Wave/T labelWave = root:Comparison:$labelWaveName
	
	Variable i
	for(i = 0; i < numSamples; i += 1)
		labelWave[i] = StringFromList(i, sampleList)
	endfor
	
	// 
	ModifyGraph/W=$graphName userticks(bottom)={labelWave, labelWave}
	
	return 0
End

// =============================================================================
// : 
// =============================================================================
Function GetSampleColor(smplIdx, r, g, b)
	Variable smplIdx
	Variable &r, &g, &b
	
	// 10
	switch(smplIdx)
		case 0:
			r = 31457; g = 44718; b = 63479  // 
			break
		case 1:
			r = 59881; g = 27242; b = 22616  // 
			break
		case 2:
			r = 25186; g = 52685; b = 25186  // 
			break
		case 3:
			r = 50372; g = 31457; b = 59881  // 
			break
		case 4:
			r = 59881; g = 47288; b = 12850  // 
			break
		case 5:
			r = 12850; g = 52685; b = 52685  // 
			break
		case 6:
			r = 59881; g = 12850; b = 47288  // 
			break
		case 7:
			r = 47288; g = 47288; b = 12850  // 
			break
		case 8:
			r = 39321; g = 39321; b = 39321  // 
			break
		default:
			r = 0; g = 0; b = 0  // 
			break
	endswitch
End

// =============================================================================
// Segmentation Core
// basePath/waveSuffixCompare
// =============================================================================

// CompareMSDParamsCore - MSD Parameters (D, L) 
Function CompareMSDParamsCore(basePath, waveSuffix)
	String basePath, waveSuffix
	
	NVAR/Z Dstate = root:Dstate
	NVAR/Z cHMM = root:cHMM
	
	Variable maxState = 0
	if(NVAR_Exists(cHMM) && cHMM == 1 && NVAR_Exists(Dstate))
		maxState = Dstate
	endif
	
	// SegmentationComparison
	String compFolder = EnsureComparisonFolderForSeg(basePath, waveSuffix)
	
	// MSD
	String sampleList = GetSampleFolderListFromPath(basePath)
	Variable numSamples = ItemsInList(sampleList)
	Variable i, s
	String smpl
	
	Print "Ensuring MSD Parameters for all samples..."
	for(i = 0; i < numSamples; i += 1)
		smpl = StringFromList(i, sampleList)
		EnsureAllResultsForAverageWithPath(smpl, "MSD", basePath, waveSuffix)
	endfor
	
	// StateCompare
	for(s = 0; s <= maxState; s += 1)
		CompareDWithPath(s, basePath, waveSuffix)
		CompareLWithPath(s, basePath, waveSuffix)
	endfor
	
	// Mean±SEM
	CompareMSD_MeanSEM_D_WithPath(basePath, waveSuffix)
	CompareMSD_MeanSEM_L_WithPath(basePath, waveSuffix)
	
	Print "=== Compare MSD Parameters completed ==="
End

// CompareDstateCore - D-state population (HMMP) 
Function CompareDstateCore(basePath, waveSuffix)
	String basePath, waveSuffix
	
	// SegmentationComparison
	String compFolder = EnsureComparisonFolderForSeg(basePath, waveSuffix)
	
	// Seg: Results
	if(!StringMatch(basePath, "root") || strlen(waveSuffix) > 0)
		String sampleList = GetSampleFolderListFromPath(basePath)
		Variable numSamples = ItemsInList(sampleList)
		Variable i
		for(i = 0; i < numSamples; i += 1)
			String smpl = StringFromList(i, sampleList)
			EnsureAllResultsForAverageWithPath(smpl, "HMMP", basePath, waveSuffix)
		endfor
	endif
	
	CompareHMMPWithPath(basePath, waveSuffix)
End

// CompareIntensityCore - Intensity
Function CompareIntensityCore(basePath, waveSuffix)
	String basePath, waveSuffix
	
	String compFolder = EnsureComparisonFolderForSeg(basePath, waveSuffix)
	
	// Seg: Results
	if(!StringMatch(basePath, "root") || strlen(waveSuffix) > 0)
		String sampleList = GetSampleFolderListFromPath(basePath)
		Variable numSamples = ItemsInList(sampleList)
		Variable i
		for(i = 0; i < numSamples; i += 1)
			String smpl = StringFromList(i, sampleList)
			EnsureAllResultsForAverageWithPath(smpl, "Intensity", basePath, waveSuffix)
		endfor
	endif
	
	CompareIntensityWithPath(basePath, waveSuffix)
End

// CompareLPCore - Localization Precision
Function CompareLPCore(basePath, waveSuffix)
	String basePath, waveSuffix
	
	String compFolder = EnsureComparisonFolderForSeg(basePath, waveSuffix)
	
	// Seg: Results
	if(!StringMatch(basePath, "root") || strlen(waveSuffix) > 0)
		String sampleList = GetSampleFolderListFromPath(basePath)
		Variable numSamples = ItemsInList(sampleList)
		Variable i
		for(i = 0; i < numSamples; i += 1)
			String smpl = StringFromList(i, sampleList)
			EnsureAllResultsForAverageWithPath(smpl, "LP", basePath, waveSuffix)
		endfor
	endif
	
	CompareLPWithPath(basePath, waveSuffix)
End

// CompareDensityCore - Particle Density
Function CompareDensityCore(basePath, waveSuffix)
	String basePath, waveSuffix
	
	String compFolder = EnsureComparisonFolderForSeg(basePath, waveSuffix)
	
	// Seg: Results
	if(!StringMatch(basePath, "root") || strlen(waveSuffix) > 0)
		String sampleList = GetSampleFolderListFromPath(basePath)
		Variable numSamples = ItemsInList(sampleList)
		Variable i
		for(i = 0; i < numSamples; i += 1)
			String smpl = StringFromList(i, sampleList)
			EnsureAllResultsForAverageWithPath(smpl, "Density", basePath, waveSuffix)
		endfor
	endif
	
	CompareDensityWithPath(basePath, waveSuffix)
End

// CompareMolDensCore - Molecular Density
Function CompareMolDensCore(basePath, waveSuffix)
	String basePath, waveSuffix
	
	String compFolder = EnsureComparisonFolderForSeg(basePath, waveSuffix)
	
	// Seg: Results
	if(!StringMatch(basePath, "root") || strlen(waveSuffix) > 0)
		String sampleList = GetSampleFolderListFromPath(basePath)
		Variable numSamples = ItemsInList(sampleList)
		Variable i
		for(i = 0; i < numSamples; i += 1)
			String smpl = StringFromList(i, sampleList)
			EnsureAllResultsForAverageWithPath(smpl, "MolDens", basePath, waveSuffix)
		endfor
	endif
	
	CompareMolDensityWithPath(basePath, waveSuffix)
End

// CompareOntimeCore - On-time
Function CompareOntimeCore(basePath, waveSuffix)
	String basePath, waveSuffix
	
	String compFolder = EnsureComparisonFolderForSeg(basePath, waveSuffix)
	
	// Seg: Results
	if(!StringMatch(basePath, "root") || strlen(waveSuffix) > 0)
		String sampleList = GetSampleFolderListFromPath(basePath)
		Variable numSamples = ItemsInList(sampleList)
		Variable i
		for(i = 0; i < numSamples; i += 1)
			String smpl = StringFromList(i, sampleList)
			EnsureAllResultsForAverageWithPath(smpl, "OnTime", basePath, waveSuffix)
		endfor
	endif
	
	CompareOntimeWithPath(basePath, waveSuffix)
End

// CompareOnrateCore - On-rate
Function CompareOnrateCore(basePath, waveSuffix)
	String basePath, waveSuffix
	
	String compFolder = EnsureComparisonFolderForSeg(basePath, waveSuffix)
	
	// Seg: Results
	if(!StringMatch(basePath, "root") || strlen(waveSuffix) > 0)
		String sampleList = GetSampleFolderListFromPath(basePath)
		Variable numSamples = ItemsInList(sampleList)
		Variable i
		for(i = 0; i < numSamples; i += 1)
			String smpl = StringFromList(i, sampleList)
			EnsureAllResultsForAverageWithPath(smpl, "OnRate", basePath, waveSuffix)
		endfor
	endif
	
	CompareOnrateWithPath(basePath, waveSuffix)
End

// CompareStateTransCore - State Transition Kinetics
Function CompareStateTransCore(basePath, waveSuffix)
	String basePath, waveSuffix
	
	String compFolder = EnsureComparisonFolderForSeg(basePath, waveSuffix)
	CompareStateTransWithPath(basePath, waveSuffix)
End

// =============================================================================
// 
// =============================================================================

// EnsureComparisonFolderForSeg - SegComparison
Function/S EnsureComparisonFolderForSeg(basePath, waveSuffix)
	String basePath, waveSuffix
	
	String compFolder
	if(StringMatch(basePath, "root"))
		compFolder = "root:Comparison"
	else
		// root:Seg0:Comparison, root:Seg1:Comparison
		compFolder = basePath + ":Comparison"
	endif
	
	if(!DataFolderExists(compFolder))
		NewDataFolder/O $compFolder
	endif
	
	return compFolder
End

// GetSampleFolderListFromPath - 
Function/S GetSampleFolderListFromPath(basePath)
	String basePath
	
	if(StringMatch(basePath, "root"))
		return GetSampleFolderList()
	endif
	
	// Seg: basePath
	String savedDF = GetDataFolder(1)
	String sampleList = ""
	
	if(!DataFolderExists(basePath))
		return ""
	endif
	
	SetDataFolder $basePath
	
	Variable numFolders = CountObjects("", 4)  // 4 = data folders
	Variable i
	String folderName
	
	for(i = 0; i < numFolders; i += 1)
		folderName = GetIndexedObjName("", 4, i)
		// Comparison
		if(!StringMatch(folderName, "Comparison"))
			sampleList += folderName + ";"
		endif
	endfor
	
	SetDataFolder $savedDF
	return sampleList
End

// EnsureAllResultsForAverageWithPath - basePath
// StatsResultsMatrix
// Seg basePath:SampleName:Matrix/Results 
// 
Function EnsureAllResultsForAverageWithPath(SampleName, analysisType, basePath, waveSuffix)
	String SampleName, analysisType, basePath, waveSuffix
	
	// Total
	if(StringMatch(basePath, "root") && strlen(waveSuffix) == 0)
		EnsureAllResultsForAverage(SampleName, analysisType)
		return 0
	endif
	
	// Seg: StatsResultsMatrix
	// basePath = "root:Seg0" 
	String samplePath = basePath + ":" + SampleName
	
	if(!DataFolderExists(samplePath))
		Printf "EnsureAllResultsForAverageWithPath: Sample folder not found: %s\r", samplePath
		return -1
	endif
	
	// 
	String firstCell = samplePath + ":" + SampleName + "1"
	if(!DataFolderExists(firstCell))
		Printf "EnsureAllResultsForAverageWithPath: First cell folder not found: %s\r", firstCell
		return -1
	endif
	
	// MSDWave
	Wave/Z testCoef = $(firstCell + ":coef_MSD_S0")
	if(!WaveExists(testCoef))
		Printf "EnsureAllResultsForAverageWithPath: coef_MSD_S0 not found in %s\r", firstCell
		Printf "  MSDSeg\r"
		Printf "  BatchAnalysisSeg=ONSegmentation Analysis\r"
	endif
	
	// StatsResultsMatrixMatrix/Results/
	Printf "EnsureAllResultsForAverageWithPath: Running StatsResultsMatrix(%s, %s)\r", basePath, SampleName
	StatsResultsMatrix(basePath, SampleName, "")
	
	return 0
End


// =============================================================================
// WithPathCompare - 
// =============================================================================

Function CompareDWithPath(stateNum, basePath, waveSuffix)
	Variable stateNum
	String basePath, waveSuffix
	
	// Total
	if(StringMatch(basePath, "root") && strlen(waveSuffix) == 0)
		CompareD(stateNum)
		return 0
	endif
	
	// Seg
	// StatsResultsMatrix basePath:SampleName:Matrix/Results 
	// WavewaveSuffix
	String suffix = "_S" + num2str(stateNum) + waveSuffix  // suffix
	String matrixName = "coef_MSD_S" + num2str(stateNum) + "_m"  // Wavesuffix
	
	EnsureComparisonFolder()
	SetDataFolder root:Comparison
	
	// basePath
	String sampleList = GetSampleFolderListFromPath(basePath)
	Variable numSamples = ItemsInList(sampleList)
	
	if(numSamples == 0)
		SetDataFolder root:
		return -1
	endif
	
	// Wave
	String sampleNamesWave = "SampleNames" + waveSuffix
	Make/O/T/N=(numSamples) $sampleNamesWave
	Wave/T SampleNames = $sampleNamesWave
	
	String winName = "Compare_D_S" + num2str(stateNum) + waveSuffix
	DoWindow/K $winName
	
	// Wave
	String meanWaveName = "D_mean" + suffix
	String semWaveName = "D_sem" + suffix
	String colorWaveName = "D_colors" + suffix
	Make/O/N=(numSamples) $meanWaveName = NaN
	Make/O/N=(numSamples) $semWaveName = NaN
	Wave D_meanW = $meanWaveName
	Wave D_semW = $semWaveName
	
	Make/O/N=(numSamples, 3) $colorWaveName = 0
	Wave BarColors = $colorWaveName
	
	// HMM state
	Variable baseR, baseG, baseB
	GetDstateColor(stateNum, baseR, baseG, baseB)
	
	Variable i, j, nCells
	String smplName, srcMatrixPath, cellDataName
	String avgPath, semPath
	String firstViolinTrace = ""
	
	//  - basePath:SampleName:Matrix 
	for(i = 0; i < numSamples; i += 1)
		smplName = StringFromList(i, sampleList)
		SampleNames[i] = smplName
		//  basePath:SampleName:Matrix 
		srcMatrixPath = basePath + ":" + smplName + ":Matrix:" + matrixName
		Wave/Z srcMatrix = $srcMatrixPath
		
		if(!WaveExists(srcMatrix))
			Printf "Matrix not found: %s\r", srcMatrixPath
			continue
		endif
		
		nCells = DimSize(srcMatrix, 1)
		
		// Cell dataD = 0
		cellDataName = "D" + suffix + "_" + smplName
		Make/O/N=(nCells) $cellDataName = NaN
		Wave cellData = $cellDataName
		for(j = 0; j < nCells; j += 1)
			cellData[j] = srcMatrix[0][j]
		endfor
		
		WaveTransform zapNaNs cellData
		
		//  - basePath:SampleName:Results 
		avgPath = basePath + ":" + smplName + ":Results:" + matrixName + "_avg"
		semPath = basePath + ":" + smplName + ":Results:" + matrixName + "_sem"
		Wave/Z avgWave = $avgPath
		Wave/Z semWave = $semPath
		
		if(WaveExists(avgWave) && WaveExists(semWave))
			D_meanW[i] = avgWave[0]
			D_semW[i] = semWave[0]
		endif
		
		// 
		Variable r = baseR, g = baseG, b = baseB
		if(i > 0)
			r = min(baseR + 15000 * i, 65535)
			g = min(baseG + 15000 * i, 65535)
			b = min(baseB + 15000 * i, 65535)
		endif
		BarColors[i][0] = r
		BarColors[i][1] = g
		BarColors[i][2] = b
		
		if(strlen(firstViolinTrace) == 0 && numpnts(cellData) > 0)
			firstViolinTrace = cellDataName
		endif
	endfor
	
	// 1
	Variable hasData = 0
	for(i = 0; i < numSamples; i += 1)
		if(numtype(D_meanW[i]) == 0)  // NaN
			hasData = 1
			break
		endif
	endfor
	
	if(!hasData)
		Print "WARNING: No data found for Compare D" + suffix
		Print "  basePath=" + basePath + ", matrixName=" + matrixName
		SetDataFolder root:
		return -1
	endif
	
	// 
	Display/K=1/N=$winName D_meanW vs SampleNames
	ModifyGraph mode($meanWaveName)=5, hbFill($meanWaveName)=2
	ModifyGraph zColor($meanWaveName)={BarColors,*,*,directRGB,0}
	ModifyGraph useBarStrokeRGB($meanWaveName)=1, barStrokeRGB($meanWaveName)=(0,0,0)
	ErrorBars $meanWaveName Y,wave=(D_semW, D_semW)
	
	// Violin Plot
	Variable firstViolin = 1
	for(i = 0; i < numSamples; i += 1)
		smplName = StringFromList(i, sampleList)
		cellDataName = "D" + suffix + "_" + smplName
		Wave/Z cellData = $cellDataName
		
		if(!WaveExists(cellData) || numpnts(cellData) == 0)
			continue
		endif
		
		if(firstViolin)
			AppendViolinPlot/T cellData vs SampleNames
			firstViolin = 0
		else
			AddWavesToViolinPlot/T=$firstViolinTrace cellData
		endif
	endfor
	
	if(strlen(firstViolinTrace) > 0)
		ModifyViolinPlot trace=$firstViolinTrace, LineColor=(65535,65535,65535,0)
		ModifyViolinPlot trace=$firstViolinTrace, DataMarker=19, MarkerColor=(0,0,0)
		// topViolin Plot
		ModifyGraph noLabel(top)=2, axThick(top)=0, tick(top)=3
	endif
	
	NVAR DstateVar = root:Dstate
	Variable totalStates = DstateVar
	String stateName = GetDstateName(stateNum, totalStates)
	
	ModifyGraph tick=2, mirror=0, fStyle=1, fSize=14, font="Arial"
	ModifyGraph tick(bottom)=3, tkLblRot(bottom)=90, catGap(bottom)=0.5
	
	// 
	SetBarGraphSizeByItems(numSamples, baseWidth=150, widthPerItem=30)
	
	Label left "\\F'Arial'\\Z14D\\B" + stateName + "\\M [µm\\S2\\M\\F'Arial'\\Z14/s]"
	SetAxis left 0, *
	
	String segLabel = GetSegmentLabel(waveSuffix)
	DoWindow/T $winName, "Compare D (S" + num2str(stateNum) + ": " + stateName + ") [" + segLabel + "]"
	
	SetDataFolder root:
	Print "Compare D" + suffix + " completed: " + num2str(numSamples) + " samples"
End

Function CompareLWithPath(stateNum, basePath, waveSuffix)
	Variable stateNum
	String basePath, waveSuffix
	
	if(StringMatch(basePath, "root") && strlen(waveSuffix) == 0)
		CompareL(stateNum)
		return 0
	endif
	
	// Seg
	// StatsResultsMatrix basePath:SampleName:Matrix/Results 
	String suffix = "_S" + num2str(stateNum) + waveSuffix  // suffix
	String matrixName = "coef_MSD_S" + num2str(stateNum) + "_m"  // Wavesuffix
	
	EnsureComparisonFolder()
	SetDataFolder root:Comparison
	
	String sampleList = GetSampleFolderListFromPath(basePath)
	Variable numSamples = ItemsInList(sampleList)
	
	if(numSamples == 0)
		SetDataFolder root:
		return -1
	endif
	
	Wave/T/Z SampleNames = $("SampleNames" + waveSuffix)
	if(!WaveExists(SampleNames))
		Make/O/T/N=(numSamples) $("SampleNames" + waveSuffix)
		Wave/T SampleNames = $("SampleNames" + waveSuffix)
	endif
	
	String winName = "Compare_L_S" + num2str(stateNum) + waveSuffix
	DoWindow/K $winName
	
	String meanWaveName = "L_mean" + suffix
	String semWaveName = "L_sem" + suffix
	String colorWaveName = "L_colors" + suffix
	Make/O/N=(numSamples) $meanWaveName = NaN
	Make/O/N=(numSamples) $semWaveName = NaN
	Wave L_meanW = $meanWaveName
	Wave L_semW = $semWaveName
	
	Make/O/N=(numSamples, 3) $colorWaveName = 0
	Wave BarColors = $colorWaveName
	
	Variable baseR, baseG, baseB
	GetDstateColor(stateNum, baseR, baseG, baseB)
	
	Variable i, j, nCells
	String smplName, srcMatrixPath, cellDataName
	String firstViolinTrace = ""
	
	for(i = 0; i < numSamples; i += 1)
		smplName = StringFromList(i, sampleList)
		SampleNames[i] = smplName
		//  basePath:SampleName:Matrix 
		srcMatrixPath = basePath + ":" + smplName + ":Matrix:" + matrixName
		Wave/Z srcMatrix = $srcMatrixPath
		
		if(!WaveExists(srcMatrix))
			Printf "Matrix not found: %s\r", srcMatrixPath
			continue
		endif
		
		nCells = DimSize(srcMatrix, 1)
		
		cellDataName = "L" + suffix + "_" + smplName
		Make/O/N=(nCells) $cellDataName = NaN
		Wave cellData = $cellDataName
		for(j = 0; j < nCells; j += 1)
			cellData[j] = srcMatrix[1][j]  // 1 = L
		endfor
		
		WaveTransform zapNaNs cellData
		
		// basePath:SampleName:Results 
		String avgPath = basePath + ":" + smplName + ":Results:" + matrixName + "_avg"
		String semPath = basePath + ":" + smplName + ":Results:" + matrixName + "_sem"
		Wave/Z avgWave = $avgPath
		Wave/Z semWave = $semPath
		
		if(WaveExists(avgWave) && WaveExists(semWave))
			L_meanW[i] = avgWave[1]
			L_semW[i] = semWave[1]
		endif
		
		Variable r = baseR, g = baseG, b = baseB
		if(i > 0)
			r = min(baseR + 15000 * i, 65535)
			g = min(baseG + 15000 * i, 65535)
			b = min(baseB + 15000 * i, 65535)
		endif
		BarColors[i][0] = r
		BarColors[i][1] = g
		BarColors[i][2] = b
		
		if(strlen(firstViolinTrace) == 0 && numpnts(cellData) > 0)
			firstViolinTrace = cellDataName
		endif
	endfor
	
	// 1
	Variable hasData = 0
	for(i = 0; i < numSamples; i += 1)
		if(numtype(L_meanW[i]) == 0)  // NaN
			hasData = 1
			break
		endif
	endfor
	
	if(!hasData)
		Print "WARNING: No data found for Compare L" + suffix
		Print "  basePath=" + basePath + ", matrixName=" + matrixName
		SetDataFolder root:
		return -1
	endif
	
	Display/K=1/N=$winName L_meanW vs SampleNames
	ModifyGraph mode($meanWaveName)=5, hbFill($meanWaveName)=2
	ModifyGraph zColor($meanWaveName)={BarColors,*,*,directRGB,0}
	ModifyGraph useBarStrokeRGB($meanWaveName)=1, barStrokeRGB($meanWaveName)=(0,0,0)
	ErrorBars $meanWaveName Y,wave=(L_semW, L_semW)
	
	Variable firstViolin = 1
	for(i = 0; i < numSamples; i += 1)
		smplName = StringFromList(i, sampleList)
		cellDataName = "L" + suffix + "_" + smplName
		Wave/Z cellData = $cellDataName
		
		if(!WaveExists(cellData) || numpnts(cellData) == 0)
			continue
		endif
		
		if(firstViolin)
			AppendViolinPlot/T cellData vs SampleNames
			firstViolin = 0
		else
			AddWavesToViolinPlot/T=$firstViolinTrace cellData
		endif
	endfor
	
	if(strlen(firstViolinTrace) > 0)
		ModifyViolinPlot trace=$firstViolinTrace, LineColor=(65535,65535,65535,0)
		ModifyViolinPlot trace=$firstViolinTrace, DataMarker=19, MarkerColor=(0,0,0)
		// topViolin Plot
		ModifyGraph noLabel(top)=2, axThick(top)=0, tick(top)=3
	endif
	
	NVAR DstateVar = root:Dstate
	Variable totalStates = DstateVar
	String stateName = GetDstateName(stateNum, totalStates)
	
	ModifyGraph tick=2, mirror=0, fStyle=1, fSize=14, font="Arial"
	ModifyGraph tick(bottom)=3, tkLblRot(bottom)=90, catGap(bottom)=0.5
	
	// 
	SetBarGraphSizeByItems(numSamples, baseWidth=150, widthPerItem=30)
	
	Label left "\\F'Arial'\\Z14L\\B" + stateName + "\\M [µm]"
	SetAxis left 0, *
	
	String segLabel = GetSegmentLabel(waveSuffix)
	DoWindow/T $winName, "Compare L (S" + num2str(stateNum) + ": " + stateName + ") [" + segLabel + "]"
	
	SetDataFolder root:
	Print "Compare L" + suffix + " completed: " + num2str(numSamples) + " samples"
End

Function CompareMSD_MeanSEM_D_WithPath(basePath, waveSuffix)
	String basePath, waveSuffix
	
	if(StringMatch(basePath, "root") && strlen(waveSuffix) == 0)
		CompareMSD_MeanSEM_D()
		return 0
	endif
	
	// Seg: DMean±SEM
	String savedDF = GetDataFolder(1)
	String basePathColon = basePath + ":"
	String segLabel = GetSegmentLabel(waveSuffix)
	
	NVAR gDstate = root:Dstate
	Variable Dstate = gDstate
	
	String sampleList = GetSampleListFromBase(basePathColon)
	Variable numSamples = ItemsInList(sampleList)
	
	if(numSamples == 0)
		return -1
	endif
	
	String compPath = GetComparisonPathFromBase(basePathColon)
	SetDataFolder $compPath
	
	Variable totalBars = (Dstate + 1) * numSamples
	String allLabelsName = "D_AllLabels" + waveSuffix
	String allMeansName = "D_AllMeans" + waveSuffix
	String allSEMsName = "D_AllSEMs" + waveSuffix
	String allColorsName = "D_AllColors" + waveSuffix
	
	Make/O/T/N=(totalBars) $allLabelsName
	Make/O/N=(totalBars) $allMeansName = NaN
	Make/O/N=(totalBars) $allSEMsName = NaN
	Make/O/N=(totalBars, 3) $allColorsName = 0
	
	Wave/T D_AllLabels = $allLabelsName
	Wave D_AllMeans = $allMeansName
	Wave D_AllSEMs = $allSEMsName
	Wave D_AllColors = $allColorsName
	
	Variable barIdx = 0, smplIdx, stt
	Variable r, g, b
	String smplName, avgPath, semPath, matrixName, stateName
	
	for(stt = 0; stt <= Dstate; stt += 1)
		stateName = GetDstateName(stt, Dstate)
		matrixName = "coef_MSD_S" + num2str(stt) + "_m"
		
		for(smplIdx = 0; smplIdx < numSamples; smplIdx += 1)
			smplName = StringFromList(smplIdx, sampleList)
			
			D_AllLabels[barIdx] = smplName + "-" + stateName
			
			avgPath = basePathColon + smplName + ":Results:" + matrixName + "_avg"
			semPath = basePathColon + smplName + ":Results:" + matrixName + "_sem"
			Wave/Z avgWave = $avgPath
			Wave/Z semWave = $semPath
			
			if(WaveExists(avgWave) && WaveExists(semWave))
				D_AllMeans[barIdx] = avgWave[0]  // D = row 0
				D_AllSEMs[barIdx] = semWave[0]
			endif
			
			GetStateColorWithShade(stt, smplIdx, numSamples, r, g, b)
			D_AllColors[barIdx][0] = r
			D_AllColors[barIdx][1] = g
			D_AllColors[barIdx][2] = b
			
			barIdx += 1
		endfor
	endfor
	
	String winName = "Compare_D_All" + waveSuffix
	DoWindow/K $winName
	
	Display/K=1/N=$winName D_AllMeans vs D_AllLabels
	ModifyGraph mode=5, hbFill=2
	ModifyGraph zColor($allMeansName)={D_AllColors,*,*,directRGB,0}
	ModifyGraph useBarStrokeRGB($allMeansName)=1, barStrokeRGB($allMeansName)=(0,0,0)
	ErrorBars $allMeansName Y,wave=(D_AllSEMs, D_AllSEMs)
	
	ModifyGraph tick=2, mirror=0, fStyle=1, fSize=14, font="Arial"
	ModifyGraph tick(bottom)=3, fSize(bottom)=10, tkLblRot(bottom)=90
	ModifyGraph catGap(bottom)=0.3
	
	// 
	SetBarGraphSizeByItems(totalBars)
	
	Label left "\\F'Arial'\\Z14D [µm\\S2\\M/s]"
	SetAxis left 0, *
	DoWindow/T $winName, "Compare D - Mean±SEM [" + segLabel + "]"
	
	SetDataFolder $savedDF
	return 0
End

Function CompareMSD_MeanSEM_L_WithPath(basePath, waveSuffix)
	String basePath, waveSuffix
	
	if(StringMatch(basePath, "root") && strlen(waveSuffix) == 0)
		CompareMSD_MeanSEM_L()
		return 0
	endif
	
	// Seg: LMean±SEM
	String savedDF = GetDataFolder(1)
	String basePathColon = basePath + ":"
	String segLabel = GetSegmentLabel(waveSuffix)
	
	NVAR gDstate = root:Dstate
	Variable Dstate = gDstate
	
	String sampleList = GetSampleListFromBase(basePathColon)
	Variable numSamples = ItemsInList(sampleList)
	
	if(numSamples == 0)
		return -1
	endif
	
	String compPath = GetComparisonPathFromBase(basePathColon)
	SetDataFolder $compPath
	
	Variable totalBars = (Dstate + 1) * numSamples
	String allLabelsName = "L_AllLabels" + waveSuffix
	String allMeansName = "L_AllMeans" + waveSuffix
	String allSEMsName = "L_AllSEMs" + waveSuffix
	String allColorsName = "L_AllColors" + waveSuffix
	
	Make/O/T/N=(totalBars) $allLabelsName
	Make/O/N=(totalBars) $allMeansName = NaN
	Make/O/N=(totalBars) $allSEMsName = NaN
	Make/O/N=(totalBars, 3) $allColorsName = 0
	
	Wave/T L_AllLabels = $allLabelsName
	Wave L_AllMeans = $allMeansName
	Wave L_AllSEMs = $allSEMsName
	Wave L_AllColors = $allColorsName
	
	Variable barIdx = 0, smplIdx, stt
	Variable r, g, b
	String smplName, avgPath, semPath, matrixName, stateName
	
	for(stt = 0; stt <= Dstate; stt += 1)
		stateName = GetDstateName(stt, Dstate)
		matrixName = "coef_MSD_S" + num2str(stt) + "_m"
		
		for(smplIdx = 0; smplIdx < numSamples; smplIdx += 1)
			smplName = StringFromList(smplIdx, sampleList)
			
			L_AllLabels[barIdx] = smplName + "-" + stateName
			
			avgPath = basePathColon + smplName + ":Results:" + matrixName + "_avg"
			semPath = basePathColon + smplName + ":Results:" + matrixName + "_sem"
			Wave/Z avgWave = $avgPath
			Wave/Z semWave = $semPath
			
			if(WaveExists(avgWave) && WaveExists(semWave))
				L_AllMeans[barIdx] = avgWave[1]  // L = row 1
				L_AllSEMs[barIdx] = semWave[1]
			endif
			
			GetStateColorWithShade(stt, smplIdx, numSamples, r, g, b)
			L_AllColors[barIdx][0] = r
			L_AllColors[barIdx][1] = g
			L_AllColors[barIdx][2] = b
			
			barIdx += 1
		endfor
	endfor
	
	String winName = "Compare_L_All" + waveSuffix
	DoWindow/K $winName
	
	Display/K=1/N=$winName L_AllMeans vs L_AllLabels
	ModifyGraph mode=5, hbFill=2
	ModifyGraph zColor($allMeansName)={L_AllColors,*,*,directRGB,0}
	ModifyGraph useBarStrokeRGB($allMeansName)=1, barStrokeRGB($allMeansName)=(0,0,0)
	ErrorBars $allMeansName Y,wave=(L_AllSEMs, L_AllSEMs)
	
	ModifyGraph tick=2, mirror=0, fStyle=1, fSize=14, font="Arial"
	ModifyGraph tick(bottom)=3, fSize(bottom)=10, tkLblRot(bottom)=90
	ModifyGraph catGap(bottom)=0.3
	
	// 
	SetBarGraphSizeByItems(totalBars)
	
	Label left "\\F'Arial'\\Z14L [µm]"
	SetAxis left 0, *
	DoWindow/T $winName, "Compare L - Mean±SEM [" + segLabel + "]"
	
	SetDataFolder $savedDF
	return 0
End

Function CompareHMMPWithPath(basePath, waveSuffix)
	String basePath, waveSuffix
	
	if(StringMatch(basePath, "root") && strlen(waveSuffix) == 0)
		CompareHMMP()
		return 0
	endif
	
	// Seg
	String savedDF = GetDataFolder(1)
	String basePathColon = basePath + ":"
	
	NVAR gDstate = root:Dstate
	Variable Dstate = gDstate
	
	Print "=== Compare HMMP (D-state Population) [" + GetSegmentLabel(waveSuffix) + "] ==="
	
	// WavewaveSuffix - CalculateStepSizeHistogramHMM
	String matrixBaseName = "HMMP" + waveSuffix + "_m"
	
	Variable stt
	String stateName, winName, outputPrefix, yLabel, graphTitle, segLabel
	segLabel = GetSegmentLabel(waveSuffix)
	
	for(stt = 1; stt <= Dstate; stt += 1)
		stateName = GetDstateName(stt, Dstate)
		outputPrefix = "HMMP_S" + num2str(stt) + waveSuffix
		winName = "Compare_HMMP_S" + num2str(stt) + waveSuffix
		yLabel = "\\F'Arial'\\Z14Population\\B" + stateName + "\\M [%]"
		graphTitle = "Compare HMMP (S" + num2str(stt) + ": " + stateName + ") [" + segLabel + "]"
		
		CreateComparisonSummaryPlot(basePathColon, matrixBaseName, stt, outputPrefix, winName, yLabel, graphTitle, 1, stt)
		
		Print "  Compare HMMP S" + num2str(stt) + " [" + segLabel + "] completed"
	endfor
	
	// Part 2: State
	String sampleList = GetSampleListFromBase(basePathColon)
	Variable numSamples = ItemsInList(sampleList)
	
	if(numSamples == 0)
		SetDataFolder $savedDF
		return -1
	endif
	
	String compPath = GetComparisonPathFromBase(basePathColon)
	SetDataFolder $compPath
	
	Variable totalBars = Dstate * numSamples
	String allLabelsName = "HMMP_AllLabels" + waveSuffix
	String allMeansName = "HMMP_AllMeans" + waveSuffix
	String allSEMsName = "HMMP_AllSEMs" + waveSuffix
	String allColorsName = "HMMP_AllColors" + waveSuffix
	
	Make/O/T/N=(totalBars) $allLabelsName
	Make/O/N=(totalBars) $allMeansName = NaN
	Make/O/N=(totalBars) $allSEMsName = NaN
	Make/O/N=(totalBars, 3) $allColorsName = 0
	
	Wave/T HMMP_AllLabels = $allLabelsName
	Wave HMMP_AllMeans = $allMeansName
	Wave HMMP_AllSEMs = $allSEMsName
	Wave HMMP_AllColors = $allColorsName
	
	Variable barIdx = 0, smplIdx
	Variable r, g, b
	String smplName, avgPath, semPath
	
	for(stt = 1; stt <= Dstate; stt += 1)
		stateName = GetDstateName(stt, Dstate)
		
		for(smplIdx = 0; smplIdx < numSamples; smplIdx += 1)
			smplName = StringFromList(smplIdx, sampleList)
			
			HMMP_AllLabels[barIdx] = smplName + "-" + stateName
			
			avgPath = basePathColon + smplName + ":Results:" + matrixBaseName + "_avg"
			semPath = basePathColon + smplName + ":Results:" + matrixBaseName + "_sem"
			Wave/Z avgWave = $avgPath
			Wave/Z semWave = $semPath
			
			if(WaveExists(avgWave) && WaveExists(semWave))
				if(stt < DimSize(avgWave, 0))
					HMMP_AllMeans[barIdx] = avgWave[stt]
					HMMP_AllSEMs[barIdx] = semWave[stt]
				endif
			endif
			
			GetStateColorWithShade(stt, smplIdx, numSamples, r, g, b)
			HMMP_AllColors[barIdx][0] = r
			HMMP_AllColors[barIdx][1] = g
			HMMP_AllColors[barIdx][2] = b
			
			barIdx += 1
		endfor
	endfor
	
	winName = "Compare_HMMP_All" + waveSuffix
	DoWindow/K $winName
	
	Display/K=1/N=$winName HMMP_AllMeans vs HMMP_AllLabels
	
	ModifyGraph mode=5, hbFill=2
	ModifyGraph zColor($allMeansName)={HMMP_AllColors,*,*,directRGB,0}
	ModifyGraph useBarStrokeRGB($allMeansName)=1, barStrokeRGB($allMeansName)=(0,0,0)
	
	ErrorBars $allMeansName Y,wave=(HMMP_AllSEMs, HMMP_AllSEMs)
	
	ModifyGraph tick=2, mirror=0, fStyle=1, fSize=14, font="Arial"
	ModifyGraph tick(bottom)=3, fSize(bottom)=10
	ModifyGraph tkLblRot(bottom)=90
	ModifyGraph catGap(bottom)=0.3
	
	// 
	SetBarGraphSizeByItems(totalBars)
	
	Label left "\\F'Arial'\\Z14Population [%]"
	SetAxis left 0, *
	DoWindow/T $winName, "Compare HMMP - Mean±SEM (All States) [" + segLabel + "]"
	
	SetDataFolder $savedDF
	Print "CompareHMMP [" + segLabel + "] completed"
	return 0
End

Function CompareIntensityWithPath(basePath, waveSuffix)
	String basePath, waveSuffix
	
	if(StringMatch(basePath, "root") && strlen(waveSuffix) == 0)
		CompareIntensity()
		return 0
	endif
	
	// Seg - Total
	// mean_osize_m (2D: [state][cell]) 
	String savedDF = GetDataFolder(1)
	String basePathColon = basePath + ":"
	
	NVAR gDstate = root:Dstate
	Variable Dstate = gDstate
	
	String segLabel = GetSegmentLabel(waveSuffix)
	Print "=== Compare Intensity (Mean Oligomer Size) [" + segLabel + "] ==="
	
	// Total: mean_osize_m (2D)
	String matrixBaseName = "mean_osize_m"
	
	Variable stt
	String stateName, winName, outputPrefix, yLabel, graphTitle
	
	// StaterowIndex=stt 
	for(stt = 0; stt <= Dstate; stt += 1)
		stateName = GetDstateName(stt, Dstate)
		
		outputPrefix = "Int_S" + num2str(stt) + waveSuffix
		winName = "Compare_Int_S" + num2str(stt) + waveSuffix
		yLabel = "\\F'Arial'\\Z14Mean Oligomer Size\\B" + stateName + "\\M"
		graphTitle = "Compare Mean Oligomer Size (S" + num2str(stt) + ": " + stateName + ") [" + segLabel + "]"
		
		// rowIndex=stt Total
		CreateComparisonSummaryPlot(basePathColon, matrixBaseName, stt, outputPrefix, winName, yLabel, graphTitle, 1, stt)
		Print "  Compare Intensity S" + num2str(stt) + " [" + segLabel + "] completed"
	endfor
	
	// Part 2: State
	String sampleList = GetSampleListFromBase(basePathColon)
	Variable numSamples = ItemsInList(sampleList)
	
	if(numSamples == 0)
		SetDataFolder $savedDF
		return -1
	endif
	
	String compPath = GetComparisonPathFromBase(basePathColon)
	SetDataFolder $compPath
	
	Variable totalBars = (Dstate + 1) * numSamples
	String allLabelsName = "Int_AllLabels" + waveSuffix
	String allMeansName = "Int_AllMeans" + waveSuffix
	String allSEMsName = "Int_AllSEMs" + waveSuffix
	String allColorsName = "Int_AllColors" + waveSuffix
	
	Make/O/T/N=(totalBars) $allLabelsName
	Make/O/N=(totalBars) $allMeansName = NaN
	Make/O/N=(totalBars) $allSEMsName = NaN
	Make/O/N=(totalBars, 3) $allColorsName = 0
	
	Wave/T Int_AllLabels = $allLabelsName
	Wave Int_AllMeans = $allMeansName
	Wave Int_AllSEMs = $allSEMsName
	Wave Int_AllColors = $allColorsName
	
	Variable barIdx = 0, smplIdx
	Variable r, g, b
	String smplName, avgPath, semPath
	
	for(stt = 0; stt <= Dstate; stt += 1)
		stateName = GetDstateName(stt, Dstate)
		
		for(smplIdx = 0; smplIdx < numSamples; smplIdx += 1)
			smplName = StringFromList(smplIdx, sampleList)
			
			Int_AllLabels[barIdx] = smplName + "-" + stateName
			
			// Total: mean_osize_m_avg[stt] 
			avgPath = basePathColon + smplName + ":Results:mean_osize_m_avg"
			semPath = basePathColon + smplName + ":Results:mean_osize_m_sem"
			Wave/Z avgWave = $avgPath
			Wave/Z semWave = $semPath
			
			if(WaveExists(avgWave) && WaveExists(semWave))
				if(stt < numpnts(avgWave))
					Int_AllMeans[barIdx] = avgWave[stt]
					Int_AllSEMs[barIdx] = semWave[stt]
				endif
			endif
			
			GetStateColorWithShade(stt, smplIdx, numSamples, r, g, b)
			Int_AllColors[barIdx][0] = r
			Int_AllColors[barIdx][1] = g
			Int_AllColors[barIdx][2] = b
			
			barIdx += 1
		endfor
	endfor
	
	winName = "Compare_Int_All" + waveSuffix
	DoWindow/K $winName
	
	Display/K=1/N=$winName Int_AllMeans vs Int_AllLabels
	
	ModifyGraph mode=5, hbFill=2
	ModifyGraph zColor($allMeansName)={Int_AllColors,*,*,directRGB,0}
	ModifyGraph useBarStrokeRGB($allMeansName)=1, barStrokeRGB($allMeansName)=(0,0,0)
	
	ErrorBars $allMeansName Y,wave=(Int_AllSEMs, Int_AllSEMs)
	
	ModifyGraph tick=2, mirror=0, fStyle=1, fSize=14, font="Arial"
	ModifyGraph tick(bottom)=3, fSize(bottom)=10
	ModifyGraph tkLblRot(bottom)=90
	ModifyGraph catGap(bottom)=0.3
	
	// 
	SetBarGraphSizeByItems(totalBars)
	
	Label left "\\F'Arial'\\Z14Mean Oligomer Size"
	SetAxis left 0, *
	DoWindow/T $winName, "Compare Mean Oligomer Size - Mean±SEM [" + segLabel + "]"
	
	SetDataFolder $savedDF
	Print "CompareIntensity [" + segLabel + "] completed"
	return 0
End

Function CompareLPWithPath(basePath, waveSuffix)
	String basePath, waveSuffix
	
	if(StringMatch(basePath, "root") && strlen(waveSuffix) == 0)
		CompareLP()
		return 0
	endif
	
	// Seg
	String savedDF = GetDataFolder(1)
	String basePathColon = basePath + ":"
	
	NVAR gDstate = root:Dstate
	Variable Dstate = gDstate
	
	String segLabel = GetSegmentLabel(waveSuffix)
	Print "=== Compare LP (Localization Precision) [" + segLabel + "] ==="
	
	String matrixBaseName = "mean_LP_m"
	
	Variable stt
	String stateName, winName, outputPrefix, yLabel, graphTitle
	
	for(stt = 0; stt <= Dstate; stt += 1)
		stateName = GetDstateName(stt, Dstate)
		outputPrefix = "LP_S" + num2str(stt) + waveSuffix
		winName = "Compare_LP_S" + num2str(stt) + waveSuffix
		yLabel = "\\F'Arial'\\Z14Mean LP\\B" + stateName + "\\M [nm]"
		graphTitle = "Compare Mean LP (S" + num2str(stt) + ": " + stateName + ") [" + segLabel + "]"
		
		CreateComparisonSummaryPlot(basePathColon, matrixBaseName, stt, outputPrefix, winName, yLabel, graphTitle, 1, stt)
		Print "  Compare LP S" + num2str(stt) + " [" + segLabel + "] completed"
	endfor
	
	// Part 2: State
	String sampleList = GetSampleListFromBase(basePathColon)
	Variable numSamples = ItemsInList(sampleList)
	
	if(numSamples == 0)
		SetDataFolder $savedDF
		return -1
	endif
	
	String compPath = GetComparisonPathFromBase(basePathColon)
	SetDataFolder $compPath
	
	Variable totalBars = (Dstate + 1) * numSamples
	String allLabelsName = "LP_AllLabels" + waveSuffix
	String allMeansName = "LP_AllMeans" + waveSuffix
	String allSEMsName = "LP_AllSEMs" + waveSuffix
	String allColorsName = "LP_AllColors" + waveSuffix
	
	Make/O/T/N=(totalBars) $allLabelsName
	Make/O/N=(totalBars) $allMeansName = NaN
	Make/O/N=(totalBars) $allSEMsName = NaN
	Make/O/N=(totalBars, 3) $allColorsName = 0
	
	Wave/T LP_AllLabels = $allLabelsName
	Wave LP_AllMeans = $allMeansName
	Wave LP_AllSEMs = $allSEMsName
	Wave LP_AllColors = $allColorsName
	
	Variable barIdx = 0, smplIdx
	Variable r, g, b
	String smplName, avgPath, semPath
	
	for(stt = 0; stt <= Dstate; stt += 1)
		stateName = GetDstateName(stt, Dstate)
		
		for(smplIdx = 0; smplIdx < numSamples; smplIdx += 1)
			smplName = StringFromList(smplIdx, sampleList)
			
			LP_AllLabels[barIdx] = smplName + "-" + stateName
			
			avgPath = basePathColon + smplName + ":Results:" + matrixBaseName + "_avg"
			semPath = basePathColon + smplName + ":Results:" + matrixBaseName + "_sem"
			Wave/Z avgWave = $avgPath
			Wave/Z semWave = $semPath
			
			if(WaveExists(avgWave) && WaveExists(semWave))
				if(stt < numpnts(avgWave))
					LP_AllMeans[barIdx] = avgWave[stt]
					LP_AllSEMs[barIdx] = semWave[stt]
				endif
			endif
			
			GetStateColorWithShade(stt, smplIdx, numSamples, r, g, b)
			LP_AllColors[barIdx][0] = r
			LP_AllColors[barIdx][1] = g
			LP_AllColors[barIdx][2] = b
			
			barIdx += 1
		endfor
	endfor
	
	winName = "Compare_LP_All" + waveSuffix
	DoWindow/K $winName
	
	Display/K=1/N=$winName LP_AllMeans vs LP_AllLabels
	
	ModifyGraph mode=5, hbFill=2
	ModifyGraph zColor($allMeansName)={LP_AllColors,*,*,directRGB,0}
	ModifyGraph useBarStrokeRGB($allMeansName)=1, barStrokeRGB($allMeansName)=(0,0,0)
	
	ErrorBars $allMeansName Y,wave=(LP_AllSEMs, LP_AllSEMs)
	
	ModifyGraph tick=2, mirror=0, fStyle=1, fSize=14, font="Arial"
	ModifyGraph tick(bottom)=3, fSize(bottom)=10
	ModifyGraph tkLblRot(bottom)=90
	ModifyGraph catGap(bottom)=0.3
	
	// 
	SetBarGraphSizeByItems(totalBars)
	
	Label left "\\F'Arial'\\Z14Mean LP [nm]"
	SetAxis left 0, *
	DoWindow/T $winName, "Compare Mean LP - Mean±SEM [" + segLabel + "]"
	
	SetDataFolder $savedDF
	Print "CompareLP [" + segLabel + "] completed"
	return 0
End

Function CompareDensityWithPath(basePath, waveSuffix)
	String basePath, waveSuffix
	
	if(StringMatch(basePath, "root") && strlen(waveSuffix) == 0)
		CompareDensity()
		return 0
	endif
	
	// Seg
	String savedDF = GetDataFolder(1)
	String basePathColon = basePath + ":"
	
	NVAR gDstate = root:Dstate
	Variable Dstate = gDstate
	
	String segLabel = GetSegmentLabel(waveSuffix)
	Print "=== Compare Particle Density [" + segLabel + "] ==="
	
	// Part 1: State Particle Density
	Variable stt
	String stateName, winName, outputPrefix, yLabel, graphTitle
	String matrixName = "ParticleDensity_Dstate_m"
	
	for(stt = 0; stt <= Dstate; stt += 1)
		stateName = GetDstateName(stt, Dstate)
		outputPrefix = "PDens_S" + num2str(stt) + waveSuffix
		winName = "Compare_PDens_S" + num2str(stt) + waveSuffix
		yLabel = "\\F'Arial'\\Z14Particle Density\\B" + stateName + "\\M [/µm\\S2\\M]"
		graphTitle = "Compare Particle Density (S" + num2str(stt) + ") [" + segLabel + "]"
		
		CreateComparisonSummaryPlot(basePathColon, matrixName, stt, outputPrefix, winName, yLabel, graphTitle, 1, stt)
		Print "  Compare Particle Density S" + num2str(stt) + " [" + segLabel + "] completed"
	endfor
	
	// Part 2: Cell Area
	String areaMatrixName = "ParaDensityAvg_m"
	outputPrefix = "Area" + waveSuffix
	winName = "Compare_Area" + waveSuffix
	yLabel = "\\F'Arial'\\Z14Cell Area [µm\\S2\\M]"
	graphTitle = "Compare Cell Area [" + segLabel + "]"
	CreateComparisonSummaryPlot(basePathColon, areaMatrixName, 1, outputPrefix, winName, yLabel, graphTitle, 0, 0)
	
	// Part 3: NumPoints
	outputPrefix = "NumPts" + waveSuffix
	winName = "Compare_NumPoints" + waveSuffix
	yLabel = "\\F'Arial'\\Z14Number of Points"
	graphTitle = "Compare Number of Points [" + segLabel + "]"
	CreateComparisonSummaryPlot(basePathColon, areaMatrixName, 0, outputPrefix, winName, yLabel, graphTitle, 0, 0)
	
	SetDataFolder $savedDF
	Print "CompareDensity [" + segLabel + "] completed"
	return 0
End

Function CompareMolDensityWithPath(basePath, waveSuffix)
	String basePath, waveSuffix
	
	if(StringMatch(basePath, "root") && strlen(waveSuffix) == 0)
		CompareMolDensity()
		return 0
	endif
	
	// Seg
	String savedDF = GetDataFolder(1)
	String basePathColon = basePath + ":"
	
	NVAR gDstate = root:Dstate
	Variable Dstate = gDstate
	
	String segLabel = GetSegmentLabel(waveSuffix)
	Print "=== Compare Molecular Density [" + segLabel + "] ==="
	
	Variable stt
	String stateName, winName, outputPrefix, yLabel, graphTitle
	String matrixName = "MolDensity_Dstate_m"
	
	for(stt = 0; stt <= Dstate; stt += 1)
		stateName = GetDstateName(stt, Dstate)
		outputPrefix = "MDens_S" + num2str(stt) + waveSuffix
		winName = "Compare_MDens_S" + num2str(stt) + waveSuffix
		yLabel = "\\F'Arial'\\Z14Molecular Density\\B" + stateName + "\\M [/µm\\S2\\M]"
		graphTitle = "Compare Molecular Density (S" + num2str(stt) + ") [" + segLabel + "]"
		
		CreateComparisonSummaryPlot(basePathColon, matrixName, stt, outputPrefix, winName, yLabel, graphTitle, 1, stt)
		Print "  Compare Molecular Density S" + num2str(stt) + " [" + segLabel + "] completed"
	endfor
	
	SetDataFolder $savedDF
	Print "CompareMolDensity [" + segLabel + "] completed"
	return 0
End

Function CompareOntimeWithPath(basePath, waveSuffix)
	String basePath, waveSuffix
	
	if(StringMatch(basePath, "root") && strlen(waveSuffix) == 0)
		CompareOnTime()
		return 0
	endif
	
	// Seg
	String savedDF = GetDataFolder(1)
	String basePathColon = basePath + ":"
	String segLabel = GetSegmentLabel(waveSuffix)
	
	Print "=== Compare On-time [" + segLabel + "] ==="
	
	// Tau_Duration_Seg0_m [tau1, tau2, ...][cell]
	String matrixName = "Tau_Duration" + waveSuffix + "_m"
	String outputPrefix = "OnTime" + waveSuffix
	String winName = "Compare_OnTime" + waveSuffix
	String yLabel = "\\F'Arial'\\Z14On-time τ [s]"
	String graphTitle = "Compare On-time [" + segLabel + "]"
	
	// τ1 (0) 
	CreateComparisonSummaryPlot(basePathColon, matrixName, 0, outputPrefix, winName, yLabel, graphTitle, 0, 0)
	
	SetDataFolder $savedDF
	Print "CompareOnTime [" + segLabel + "] completed"
	return 0
End

Function CompareOnrateWithPath(basePath, waveSuffix)
	String basePath, waveSuffix
	
	if(StringMatch(basePath, "root") && strlen(waveSuffix) == 0)
		CompareOnRate()
		return 0
	endif
	
	// Seg - CompareOnRateState
	String savedDF = GetDataFolder(1)
	String basePathColon = basePath + ":"
	String segLabel = GetSegmentLabel(waveSuffix)
	
	NVAR gDstate = root:Dstate
	Variable Dstate = gDstate
	
	Print "=== Compare On-rate [" + segLabel + "] ==="
	
	String sampleList = GetSampleListFromBase(basePathColon)
	Variable numSamples = ItemsInList(sampleList)
	
	if(numSamples == 0)
		Print "No samples found"
		SetDataFolder $savedDF
		return -1
	endif
	
	String compPath = GetComparisonPathFromBase(basePathColon)
	EnsureComparisonFolderForBase(basePathColon)
	SetDataFolder $compPath
	
	// Wave
	String sampleNamesWaveName = "SampleNames" + waveSuffix
	Make/O/T/N=(numSamples) $sampleNamesWaveName
	Wave/T SampleNames = $sampleNamesWaveName
	Variable i
	for(i = 0; i < numSamples; i += 1)
		SampleNames[i] = StringFromList(i, sampleList)
	endfor
	
	Variable stt, smplIdx, nCells, cellIdx
	String smplName, matrixPath, avgPath, semPath, stateName
	String cellDataName, firstViolinTrace
	Variable r, g, b
	
	// State
	for(stt = 0; stt <= Dstate; stt += 1)
		stateName = GetDstateName(stt, Dstate)
		String winName = "Compare_OnRate_S" + num2str(stt) + waveSuffix
		DoWindow/K $winName
		
		String meanWaveName = "OnRate_mean_S" + num2str(stt) + waveSuffix
		String semWaveName = "OnRate_sem_S" + num2str(stt) + waveSuffix
		String colorWaveName = "OnRate_colors_S" + num2str(stt) + waveSuffix
		Make/O/N=(numSamples) $meanWaveName = NaN
		Make/O/N=(numSamples) $semWaveName = NaN
		Wave OnR_meanW = $meanWaveName
		Wave OnR_semW = $semWaveName
		
		Make/O/N=(numSamples, 3) $colorWaveName = 0
		Wave BarColors = $colorWaveName
		
		firstViolinTrace = ""
		
		for(smplIdx = 0; smplIdx < numSamples; smplIdx += 1)
			smplName = StringFromList(smplIdx, sampleList)
			
			// WavewaveSuffix
			matrixPath = basePathColon + smplName + ":Matrix:ParaOnrate_S" + num2str(stt) + waveSuffix + "_m"
			Wave/Z onrateMatrix = $matrixPath
			
			if(!WaveExists(onrateMatrix))
				if(stt == 0)
					matrixPath = basePathColon + smplName + ":Matrix:ParaOnrate" + waveSuffix + "_m"
					Wave/Z onrateMatrix = $matrixPath
				endif
			endif
			
			if(!WaveExists(onrateMatrix))
				Printf "  Warning: ParaOnrate_S%d%s_m not found for %s\r", stt, waveSuffix, smplName
				continue
			endif
			
			nCells = DimSize(onrateMatrix, 1)
			if(nCells == 0)
				continue
			endif
			
			// Cell data1 = On-rate V0/Area
			cellDataName = "OnRate_S" + num2str(stt) + "_" + smplName + waveSuffix
			Make/O/N=(nCells) $cellDataName = NaN
			Wave cellData = $cellDataName
			for(cellIdx = 0; cellIdx < nCells; cellIdx += 1)
				cellData[cellIdx] = onrateMatrix[1][cellIdx]
			endfor
			
			WaveTransform zapNaNs cellData
			
			// Results WaveSEM1 = On-rate
			avgPath = basePathColon + smplName + ":Results:ParaOnrate_S" + num2str(stt) + waveSuffix + "_m_avg"
			semPath = basePathColon + smplName + ":Results:ParaOnrate_S" + num2str(stt) + waveSuffix + "_m_sem"
			Wave/Z avgWave = $avgPath
			Wave/Z semWave = $semPath
			
			if(!WaveExists(avgWave) && stt == 0)
				avgPath = basePathColon + smplName + ":Results:ParaOnrate" + waveSuffix + "_m_avg"
				semPath = basePathColon + smplName + ":Results:ParaOnrate" + waveSuffix + "_m_sem"
				Wave/Z avgWave = $avgPath
				Wave/Z semWave = $semPath
			endif
			
			if(WaveExists(avgWave) && WaveExists(semWave))
				OnR_meanW[smplIdx] = avgWave[1]
				OnR_semW[smplIdx] = semWave[1]
			endif
			
			// State + 
			GetStateColorWithShade(stt, smplIdx, numSamples, r, g, b)
			BarColors[smplIdx][0] = r
			BarColors[smplIdx][1] = g
			BarColors[smplIdx][2] = b
		endfor
		
		// 
		Variable validCount = 0
		for(i = 0; i < numSamples; i += 1)
			if(numtype(OnR_meanW[i]) == 0)
				validCount += 1
			endif
		endfor
		
		if(validCount == 0)
			Print "  No valid data for S" + num2str(stt) + " [" + segLabel + "]"
			continue
		endif
		
		// 
		Display/K=1/N=$winName OnR_meanW vs SampleNames
		ModifyGraph mode=5, hbFill=2
		ModifyGraph zColor($meanWaveName)={BarColors,*,*,directRGB,0}
		ModifyGraph useBarStrokeRGB=1, barStrokeRGB=(0,0,0)
		ErrorBars $meanWaveName Y,wave=(OnR_semW, OnR_semW)
		
		// Violin Plot
		Variable firstViolin = 1
		for(smplIdx = 0; smplIdx < numSamples; smplIdx += 1)
			smplName = StringFromList(smplIdx, sampleList)
			cellDataName = "OnRate_S" + num2str(stt) + "_" + smplName + waveSuffix
			Wave/Z cellData = $cellDataName
			
			if(!WaveExists(cellData) || numpnts(cellData) == 0)
				continue
			endif
			
			if(firstViolin)
				AppendViolinPlot/T cellData vs SampleNames
				firstViolinTrace = cellDataName
				firstViolin = 0
			else
				AddWavesToViolinPlot/T=$firstViolinTrace cellData
			endif
		endfor
		
		// Violin Plot
		if(strlen(firstViolinTrace) > 0)
			ModifyViolinPlot trace=$firstViolinTrace, LineColor=(65535,65535,65535,0)
			ModifyViolinPlot trace=$firstViolinTrace, DataMarker=19, MarkerColor=(0,0,0)
		endif
		
		// 
		String topAxisInfo = AxisInfo(winName, "top")
		if(strlen(topAxisInfo) > 0)
			ModifyGraph noLabel(top)=2, axThick(top)=0, tick(top)=3
		endif
		
		ModifyGraph tick=2, mirror=0, fStyle=1, fSize=14, font="Arial"
		ModifyGraph tick(bottom)=3, tkLblRot(bottom)=90, catGap(bottom)=0.5
		
		// 
		SetBarGraphSizeByItems(numSamples, baseWidth=150, widthPerItem=30)
		
		Label left "\\F'Arial'\\Z14On-rate [/µm\\S2\\M/s]"
		SetAxis left 0, *
		DoWindow/T $winName, "Compare On-rate (" + stateName + ") [" + segLabel + "]"
		
		Print "  Compare On-rate S" + num2str(stt) + " [" + segLabel + "] completed"
	endfor
	
	SetDataFolder $savedDF
	Print "CompareOnRate [" + segLabel + "] completed"
	return 0
End

Function CompareStateTransWithPath(basePath, waveSuffix)
	String basePath, waveSuffix
	
	if(StringMatch(basePath, "root") && strlen(waveSuffix) == 0)
		CompareStateTransKinetics()
		return 0
	endif
	
	// Seg
	String segLabel = GetSegmentLabel(waveSuffix)
	Print "=== Compare State Transition Kinetics [" + segLabel + "] ==="
	
	// State Transition Kinetics
	Printf "CompareStateTransWithPath: Partial implementation for %s\r", segLabel
	
	return 0
End

// =============================================================================
// AverageWithPathSeg
// =============================================================================

// AverageMSDWithPath - MSDSeg
Function AverageMSDWithPath(stateNum, basePath, waveSuffix)
	Variable stateNum
	String basePath, waveSuffix
	
	// Total
	if(StringMatch(basePath, "root") && strlen(waveSuffix) == 0)
		AverageMSD(stateNum)
		return 0
	endif
	
	// Seg
	// StatsResultsMatrix basePath:SampleName:Results 
	// WavewaveSuffix
	EnsureComparisonFolder()
	String sampleList = GetSampleFolderListFromPath(basePath)
	Variable numSamples = ItemsInList(sampleList)
	
	if(numSamples == 0)
		Print "No samples found in " + basePath
		return -1
	endif
	
	String stateStr = "S" + num2str(stateNum)
	String segLabel = GetSegmentLabel(waveSuffix)
	
	// Wavesuffix - StatsResultsMatrix
	String MSD_avg_name = "MSD_avg_" + stateStr + "_m_avg"
	String MSD_sem_name = "MSD_avg_" + stateStr + "_m_sem"
	String MSD_time_name = "MSD_time_" + stateStr + "_m_avg"
	
	NVAR AreaRangeMSD = root:AreaRangeMSD
	Variable cutoffPt = AreaRangeMSD

	String winName = "AverageMSD_" + stateStr + waveSuffix
	DoWindow/K $winName
	Display/K=1/N=$winName

	NVAR InitialD0 = root:InitialD0
	NVAR InitialL = root:InitialL
	Variable D0init = InitialD0
	Variable Linit = InitialL
	
	Variable i, f, r, g, b
	Variable RowSize
	String smpl, resultsPath
	String wName_avg, wName_sem, wName_time, fit_wName
	String traceList = "", labelList = ""
	
	SetDataFolder root:Comparison
	
	for(i = 0; i < numSamples; i += 1)
		smpl = StringFromList(i, sampleList)
		//  basePath:SampleName:Results 
		resultsPath = basePath + ":" + smpl + ":Results:"
		
		Wave/Z MSD_avg_src = $(resultsPath + MSD_avg_name)
		Wave/Z MSD_sem_src = $(resultsPath + MSD_sem_name)
		Wave/Z MSD_time_src = $(resultsPath + MSD_time_name)
		
		if(!WaveExists(MSD_avg_src) || !WaveExists(MSD_time_src))
			Print "MSD waves not found for: " + smpl + " (" + resultsPath + MSD_avg_name + ")"
			continue
		endif
		
		wName_avg = smpl + "_MSD_" + stateStr + waveSuffix + "_avg"
		wName_sem = smpl + "_MSD_" + stateStr + waveSuffix + "_sem"
		wName_time = smpl + "_MSD_" + stateStr + waveSuffix + "_time"
		
		Duplicate/O MSD_avg_src, $wName_avg
		Duplicate/O MSD_time_src, $wName_time
		Wave avgWave = $wName_avg
		Wave timeWave = $wName_time
		
		if(WaveExists(MSD_sem_src))
			Duplicate/O MSD_sem_src, $wName_sem
		else
			Make/O/N=(numpnts(avgWave)) $wName_sem = 0
		endif
		Wave semWave = $wName_sem
		
		RowSize = numpnts(avgWave)
		
		for(f = cutoffPt + 1; f < RowSize; f += 1)
			avgWave[f] = NaN
			semWave[f] = NaN
		endfor
		
		if(semWave[0] == 0 || numtype(semWave[0]) != 0)
			semWave[0] = 0.00001
		endif
		
		AppendToGraph avgWave vs timeWave
		ErrorBars $wName_avg Y,wave=(semWave, semWave)
		
		// 
		Make/O/D/N=2 W_coef_msd
		W_coef_msd[0] = D0init
		W_coef_msd[1] = Linit
		Make/O/T/N=2 T_Constraints_msd
		T_Constraints_msd[0] = "K0 > 0"
		T_Constraints_msd[1] = "K1 > 0"
		
		FuncFit/Q/NTHR=0 MSD_dt W_coef_msd avgWave /X=timeWave /D /C=T_Constraints_msd
		FuncFit/Q/NTHR=0 MSD_dt W_coef_msd avgWave /X=timeWave /D /C=T_Constraints_msd
		
		fit_wName = "fit_" + wName_avg
		
		// HMM stateAverageMSD
		GetStateColorWithShade(stateNum, i, numSamples, r, g, b)
		ModifyGraph rgb($wName_avg)=(r, g, b)
		ModifyGraph mode($wName_avg)=3, marker($wName_avg)=19
		
		// Error bar with shading
		ErrorBars $wName_avg SHADE= {0,4,(r,g,b,32768),(r,g,b,32768)},wave=(semWave, semWave)
		
		Wave/Z fitWave = $fit_wName
		if(WaveExists(fitWave))
			ModifyGraph rgb($fit_wName)=(r, g, b)
			ModifyGraph lsize($fit_wName)=1.5
		endif
		
		Print smpl + " (S" + num2str(stateNum) + "): D=" + num2str(W_coef_msd[0]) + " µm²/s, L=" + num2str(W_coef_msd[1]) + " µm"
		
		traceList = AddListItem(wName_avg, traceList, ";", inf)
		labelList = AddListItem(smpl, labelList, ";", inf)
	endfor
	
	// 
	if(strlen(traceList) == 0)
		Print "WARNING: No data found for AverageMSD " + stateStr + " [" + segLabel + "]"
		DoWindow/K $winName
		SetDataFolder root:
		return -1
	endif
	
	// AverageMSD
	CreateSampleLegendWithTraces(traceList, labelList)
	
	// AverageMSD
	ModifyGraph width={Aspect, 1.618}
	ModifyGraph tick=0, mirror=0
	ModifyGraph lowTrip(left)=0.0001
	ModifyGraph axisEnab(left)={0.05, 1}, axisEnab(bottom)={0.05, 1}
	ModifyGraph fStyle=1, fSize=16, font="Arial"
	Label left "\\F'Arial'\\Z14MSD (µm\\S2\\M\\F'Arial'\\Z14)"
	Label bottom "\\F'Arial'\\Z12Δt (s)"
	SetAxis left 0, *
	
	// Seg
	NVAR DstateVar = root:Dstate
	Variable totalStates = DstateVar
	String stateName = GetDstateName(stateNum, totalStates)
	DoWindow/T $winName, "Average MSD-Δt (" + stateName + ") [" + segLabel + "]"
	
	// 
	KillWaves/Z W_coef_msd, T_Constraints_msd
	
	SetDataFolder root:
	Print "AverageMSD " + stateStr + " [" + segLabel + "] completed"
	return 0
End

// AverageStepHistWithPath - Step SizeSeg
Function AverageStepHistWithPath(stateNum, deltaTval, basePath, waveSuffix)
	Variable stateNum, deltaTval
	String basePath, waveSuffix
	
	if(StringMatch(basePath, "root") && strlen(waveSuffix) == 0)
		AverageStepHist(stateNum, deltaTval)
		return 0
	endif
	
	// Seg
	EnsureComparisonFolder()
	String sampleList = GetSampleFolderListFromPath(basePath)
	Variable numSamples = ItemsInList(sampleList)
	
	if(numSamples == 0)
		Print "No samples found in " + basePath
		return -1
	endif
	
	String stateStr = "S" + num2str(stateNum)
	String dtStr = "dt" + num2str(deltaTval)
	String segLabel = GetSegmentLabel(waveSuffix)
	
	// WavewaveSuffix - CalculateStepSizeHistogramHMM
	String hist_avg_name = "StepHist_" + dtStr + "_" + stateStr + waveSuffix + "_m_avg"
	String hist_sem_name = "StepHist_" + dtStr + "_" + stateStr + waveSuffix + "_m_sem"
	String hist_x_name = "StepHist_x_" + dtStr + "_" + stateStr + waveSuffix + "_m_avg"
	
	String winName = "AverageStepHist_" + dtStr + "_" + stateStr + waveSuffix
	DoWindow/K $winName
	Display/K=1/N=$winName
	
	Variable i, r, g, b
	String smpl, resultsPath
	String traceName, traceSemName, traceXName
	String traceList = "", labelList = ""
	
	SetDataFolder root:Comparison
	
	for(i = 0; i < numSamples; i += 1)
		smpl = StringFromList(i, sampleList)
		resultsPath = basePath + ":" + smpl + ":Results:"
		
		Wave/Z hist_avg = $(resultsPath + hist_avg_name)
		Wave/Z hist_sem = $(resultsPath + hist_sem_name)
		Wave/Z hist_x = $(resultsPath + hist_x_name)
		
		if(!WaveExists(hist_avg))
			Print "StepHist waves not found for: " + smpl
			continue
		endif
		
		traceName = smpl + "_StepHist_" + dtStr + "_" + stateStr + waveSuffix + "_avg"
		traceSemName = smpl + "_StepHist_" + dtStr + "_" + stateStr + waveSuffix + "_sem"
		traceXName = smpl + "_StepHist_" + dtStr + "_" + stateStr + waveSuffix + "_x"
		
		Duplicate/O hist_avg, $traceName
		Wave avgWave = $traceName
		
		if(WaveExists(hist_x))
			Duplicate/O hist_x, $traceXName
			Wave xWave = $traceXName
		else
			// X wave
			Make/O/N=(numpnts(avgWave)) $traceXName
			Wave xWave = $traceXName
			xWave = DimOffset(hist_avg, 0) + p * DimDelta(hist_avg, 0)
		endif
		
		if(WaveExists(hist_sem))
			Duplicate/O hist_sem, $traceSemName
		else
			Make/O/N=(numpnts(avgWave)) $traceSemName = 0
		endif
		Wave semWave = $traceSemName
		
		AppendToGraph avgWave vs xWave
		
		GetStateColorWithShade(stateNum, i, numSamples, r, g, b)
		ModifyGraph rgb($traceName)=(r, g, b)
		ModifyGraph mode($traceName)=0, lsize($traceName)=1.5
		ErrorBars $traceName SHADE= {0,4,(r,g,b,32768),(r,g,b,32768)},wave=(semWave, semWave)
		
		traceList = AddListItem(traceName, traceList, ";", inf)
		labelList = AddListItem(smpl, labelList, ";", inf)
	endfor
	
	if(strlen(traceList) == 0)
		Print "WARNING: No data found for AverageStepHist " + stateStr + " [" + segLabel + "]"
		DoWindow/K $winName
		SetDataFolder root:
		return -1
	endif
	
	CreateSampleLegendWithTraces(traceList, labelList)
	
	ModifyGraph width={Aspect, 1.618}
	ModifyGraph tick=0, mirror=0, fStyle=1, fSize=16, font="Arial"
	Label left "\\F'Arial'\\Z14Probability Density"
	Label bottom "\\F'Arial'\\Z12Step size [µm]"
	SetAxis left 0, *
	
	NVAR DstateVar = root:Dstate
	Variable totalStates = DstateVar
	String stateName = GetDstateName(stateNum, totalStates)
	DoWindow/T $winName, "Average Step size Histogram (" + stateName + ", Δt=" + num2str(deltaTval) + ") [" + segLabel + "]"
	
	SetDataFolder root:
	Print "AverageStepHist " + stateStr + " dt=" + num2str(deltaTval) + " [" + segLabel + "] completed"
	return 0
End

// AverageIntHistWithPath - IntensitySeg
Function AverageIntHistWithPath(stateNum, basePath, waveSuffix)
	Variable stateNum
	String basePath, waveSuffix
	
	if(StringMatch(basePath, "root") && strlen(waveSuffix) == 0)
		AverageIntHist(stateNum)
		return 0
	endif
	
	// Seg
	EnsureComparisonFolder()
	String sampleList = GetSampleFolderListFromPath(basePath)
	Variable numSamples = ItemsInList(sampleList)
	
	if(numSamples == 0)
		Print "No samples found in " + basePath
		return -1
	endif
	
	String stateStr = "S" + num2str(stateNum)
	String segLabel = GetSegmentLabel(waveSuffix)
	
	// WavewaveSuffix - CreateIntensityHistogram
	String hist_avg_name = "Int_" + stateStr + waveSuffix + "_Phist_m_avg"
	String hist_sem_name = "Int_" + stateStr + waveSuffix + "_Phist_m_sem"
	
	String winName = "AverageIntHist_" + stateStr + waveSuffix
	DoWindow/K $winName
	Display/K=1/N=$winName
	
	Variable i, r, g, b
	String smpl, resultsPath
	String traceName, traceSemName
	String traceList = "", labelList = ""
	
	SetDataFolder root:Comparison
	
	for(i = 0; i < numSamples; i += 1)
		smpl = StringFromList(i, sampleList)
		resultsPath = basePath + ":" + smpl + ":Results:"
		
		Wave/Z hist_avg = $(resultsPath + hist_avg_name)
		Wave/Z hist_sem = $(resultsPath + hist_sem_name)
		
		if(!WaveExists(hist_avg))
			Print "IntHist waves not found for: " + smpl + " (" + resultsPath + hist_avg_name + ")"
			continue
		endif
		
		traceName = smpl + "_IntHist_" + stateStr + waveSuffix + "_avg"
		traceSemName = smpl + "_IntHist_" + stateStr + waveSuffix + "_sem"
		
		Duplicate/O hist_avg, $traceName
		Wave avgWave = $traceName
		
		if(WaveExists(hist_sem))
			Duplicate/O hist_sem, $traceSemName
		else
			Make/O/N=(numpnts(avgWave)) $traceSemName = 0
		endif
		Wave semWave = $traceSemName
		
		AppendToGraph avgWave
		
		// HMM state
		GetStateColorWithShade(stateNum, i, numSamples, r, g, b)
		ModifyGraph rgb($traceName)=(r, g, b)
		ModifyGraph mode($traceName)=0, lsize($traceName)=1.5
		
		// Error bar with shading
		ErrorBars $traceName SHADE= {0,4,(r,g,b,32768),(r,g,b,32768)},wave=(semWave, semWave)
		
		traceList = AddListItem(traceName, traceList, ";", inf)
		labelList = AddListItem(smpl, labelList, ";", inf)
	endfor
	
	if(strlen(traceList) == 0)
		Print "WARNING: No data found for AverageIntHist " + stateStr + " [" + segLabel + "]"
		DoWindow/K $winName
		SetDataFolder root:
		return -1
	endif
	
	// 
	CreateSampleLegendWithTraces(traceList, labelList)
	
	// 
	ModifyGraph width={Aspect, 1.618}
	ModifyGraph tick=0, mirror=0, fStyle=1, fSize=16, font="Arial"
	Label left "\\F'Arial'\\Z14Probability Density"
	Label bottom "\\F'Arial'\\Z12Intensity [a.u.]"
	SetAxis left 0, *
	
	// 
	NVAR DstateVar = root:Dstate
	Variable totalStates = DstateVar
	String stateName = GetDstateName(stateNum, totalStates)
	DoWindow/T $winName, "Average Intensity Histogram (" + stateName + ") [" + segLabel + "]"
	
	SetDataFolder root:
	Print "AverageIntHist " + stateStr + " [" + segLabel + "] completed"
	return 0
End

// AverageLPHistWithPath - LPSeg
Function AverageLPHistWithPath(stateNum, basePath, waveSuffix)
	Variable stateNum
	String basePath, waveSuffix
	
	if(StringMatch(basePath, "root") && strlen(waveSuffix) == 0)
		AverageLPHist(stateNum)
		return 0
	endif
	
	// Seg
	EnsureComparisonFolder()
	String sampleList = GetSampleFolderListFromPath(basePath)
	Variable numSamples = ItemsInList(sampleList)
	
	if(numSamples == 0)
		Print "No samples found in " + basePath
		return -1
	endif
	
	String stateStr = "S" + num2str(stateNum)
	String segLabel = GetSegmentLabel(waveSuffix)
	
	// WaveTotalAverageLPHistLPwaveSuffix
	String hist_avg_name = "LP_" + stateStr + "_Phist_m_avg"
	String hist_sem_name = "LP_" + stateStr + "_Phist_m_sem"
	
	String winName = "AverageLPHist_" + stateStr + waveSuffix
	DoWindow/K $winName
	Display/K=1/N=$winName
	
	Variable i, r, g, b
	String smpl, resultsPath
	String traceName, traceSemName
	String traceList = "", labelList = ""
	
	SetDataFolder root:Comparison
	
	for(i = 0; i < numSamples; i += 1)
		smpl = StringFromList(i, sampleList)
		resultsPath = basePath + ":" + smpl + ":Results:"
		
		Wave/Z hist_avg = $(resultsPath + hist_avg_name)
		Wave/Z hist_sem = $(resultsPath + hist_sem_name)
		
		if(!WaveExists(hist_avg))
			Print "LP waves not found for: " + smpl
			continue
		endif
		
		traceName = smpl + "_LP_" + stateStr + waveSuffix + "_avg"
		traceSemName = smpl + "_LP_" + stateStr + waveSuffix + "_sem"
		
		Duplicate/O hist_avg, $traceName
		Wave avgWave = $traceName
		
		if(WaveExists(hist_sem))
			Duplicate/O hist_sem, $traceSemName
		else
			Make/O/N=(numpnts(avgWave)) $traceSemName = 0
		endif
		Wave semWave = $traceSemName
		
		AppendToGraph avgWave
		
		GetStateColorWithShade(stateNum, i, numSamples, r, g, b)
		ModifyGraph rgb($traceName)=(r, g, b)
		ModifyGraph mode($traceName)=0, lsize($traceName)=1.5
		ErrorBars $traceName SHADE= {0,4,(r,g,b,32768),(r,g,b,32768)},wave=(semWave, semWave)
		
		traceList = AddListItem(traceName, traceList, ";", inf)
		labelList = AddListItem(smpl, labelList, ";", inf)
	endfor
	
	if(strlen(traceList) == 0)
		Print "WARNING: No data found for AverageLPHist " + stateStr + " [" + segLabel + "]"
		DoWindow/K $winName
		SetDataFolder root:
		return -1
	endif
	
	CreateSampleLegendWithTraces(traceList, labelList)
	
	ModifyGraph width={Aspect, 1.618}
	ModifyGraph tick=0, mirror=0, fStyle=1, fSize=16, font="Arial"
	Label left "\\F'Arial'\\Z14Probability Density"
	Label bottom "\\F'Arial'\\Z12Localization Precision [nm]"
	SetAxis left 0, *
	
	NVAR DstateVar = root:Dstate
	Variable totalStates = DstateVar
	String stateName = GetDstateName(stateNum, totalStates)
	DoWindow/T $winName, "Average LP Histogram (" + stateName + ") [" + segLabel + "]"
	
	SetDataFolder root:
	Print "AverageLPHist " + stateStr + " [" + segLabel + "] completed"
	return 0
End

// AverageOntimeWithPath - On-timeSeg
Function AverageOntimeWithPath(basePath, waveSuffix)
	String basePath, waveSuffix
	
	// Core
	return AverageOntimeCore(basePath, waveSuffix)
End

// AverageOnrateWithPath - On-rateSeg
Function AverageOnrateWithPath(stateNum, basePath, waveSuffix)
	Variable stateNum
	String basePath, waveSuffix
	
	// Core
	return AverageOnrateCore(stateNum, basePath, waveSuffix)
End

// =============================================================================
// Average Mol Density - Seg
// =============================================================================

// AverageMolDensHistWithPath - Mol DensitySeg
Function AverageMolDensHistWithPath(stateNum, basePath, waveSuffix)
	Variable stateNum
	String basePath, waveSuffix
	
	if(StringMatch(basePath, "root") && strlen(waveSuffix) == 0)
		AverageMolDensHist(stateNum)
		return 0
	endif
	
	// Seg
	EnsureComparisonFolder()
	String sampleList = GetSampleFolderListFromPath(basePath)
	Variable numSamples = ItemsInList(sampleList)
	
	if(numSamples == 0)
		Print "No samples found in " + basePath
		return -1
	endif
	
	String stateStr = "S" + num2str(stateNum)
	String segLabel = GetSegmentLabel(waveSuffix)
	
	// Wavesuffix - 
	String hist_avg_name = "MolDensDist_" + stateStr + "_m_avg"
	String hist_sem_name = "MolDensDist_" + stateStr + "_m_sem"
	
	String winName = "AverageMolDensHist_" + stateStr + waveSuffix
	DoWindow/K $winName
	Display/K=1/N=$winName
	
	Variable i, r, g, b
	String smpl, resultsPath
	String traceName, traceSemName, traceXName
	String traceList = "", labelList = ""
	
	SetDataFolder root:Comparison
	
	for(i = 0; i < numSamples; i += 1)
		smpl = StringFromList(i, sampleList)
		resultsPath = basePath + ":" + smpl + ":Results:"
		
		Wave/Z hist_avg = $(resultsPath + hist_avg_name)
		Wave/Z hist_sem = $(resultsPath + hist_sem_name)
		
		if(!WaveExists(hist_avg))
			Print "MolDensDist histogram not found for: " + smpl + " (" + resultsPath + hist_avg_name + ")"
			continue
		endif
		
		traceName = smpl + "_MolDensDist_" + stateStr + waveSuffix
		traceSemName = smpl + "_MolDensDistSem_" + stateStr + waveSuffix
		traceXName = smpl + "_MolDensDistX_" + stateStr + waveSuffix
		
		Duplicate/O hist_avg, $traceName
		Wave histW = $traceName
		
		// X: 1, 2, 3, ... (oligomer size = monomer, dimer, trimer, ...)
		Make/O/N=(numpnts(histW)) $traceXName
		Wave xW = $traceXName
		xW = p + 1
		
		if(WaveExists(hist_sem))
			Duplicate/O hist_sem, $traceSemName
		else
			Make/O/N=(numpnts(histW)) $traceSemName = 0
		endif
		Wave semW = $traceSemName
		
		AppendToGraph histW vs xW
		
		GetStateColorWithShade(stateNum, i, numSamples, r, g, b)
		ModifyGraph rgb($traceName)=(r, g, b)
		ModifyGraph mode($traceName)=4, marker($traceName)=19, msize($traceName)=3
		ModifyGraph lsize($traceName)=1.5
		
		ErrorBars $traceName SHADE= {0,4,(r,g,b,32768),(r,g,b,32768)},wave=(semW, semW)
		
		traceList = AddListItem(traceName, traceList, ";", inf)
		labelList = AddListItem(smpl, labelList, ";", inf)
	endfor
	
	if(strlen(traceList) == 0)
		Print "WARNING: No data found for AverageMolDensHist " + stateStr + " [" + segLabel + "]"
		DoWindow/K $winName
		SetDataFolder root:
		return -1
	endif
	
	CreateSampleLegendWithTraces(traceList, labelList)
	
	ModifyGraph tick=2, mirror=0, fStyle=1, fSize=14, font="Arial"
	ModifyGraph width={Aspect, 1.618}
	Label left "Molecular Density (/µm\\S2\\M)"
	Label bottom "Oligomer Size"
	SetAxis left 0, *
	
	NVAR DstateVar = root:Dstate
	Variable totalStates = DstateVar
	String stateName = GetDstateName(stateNum, totalStates)
	DoWindow/T $winName, "Average Molecular Density Distribution (" + stateName + ") [" + segLabel + "]"
	
	SetDataFolder root:
	Print "  AverageMolDensHist " + stateStr + " [" + segLabel + "] completed"
	return 0
End

// AverageMolDensFractionWithPath - State FractionSeg
Function AverageMolDensFractionWithPath(basePath, waveSuffix)
	String basePath, waveSuffix
	
	if(StringMatch(basePath, "root") && strlen(waveSuffix) == 0)
		AverageMolDensFraction()
		return 0
	endif
	
	// Seg
	EnsureComparisonFolder()
	String sampleList = GetSampleFolderListFromPath(basePath)
	Variable numSamples = ItemsInList(sampleList)
	
	if(numSamples == 0)
		Print "No samples found in " + basePath
		return -1
	endif
	
	String segLabel = GetSegmentLabel(waveSuffix)
	
	// Wavesuffix - 
	String frac_avg_name = "StateFraction_m_avg"
	String frac_sem_name = "StateFraction_m_sem"
	
	String winName = "AverageStateFraction" + waveSuffix
	DoWindow/K $winName
	Display/K=1/N=$winName
	
	Variable i, s
	String smpl, resultsPath
	String traceName, traceSemName
	String traceList = "", labelList = ""
	
	NVAR Dstate = root:Dstate
	Variable maxState = Dstate
	
	SetDataFolder root:Comparison
	
	// X labels (skip S0=100%, start from S1)
	String labelsName = "MolDens_StateLabels" + waveSuffix
	Make/O/T/N=(maxState) $labelsName
	Wave/T StateLabels = $labelsName
	for(s = 1; s <= maxState; s += 1)
		StateLabels[s-1] = GetDstateName(s, maxState)
	endfor
	
	for(i = 0; i < numSamples; i += 1)
		smpl = StringFromList(i, sampleList)
		resultsPath = basePath + ":" + smpl + ":Results:"
		
		Wave/Z frac_avg = $(resultsPath + frac_avg_name)
		Wave/Z frac_sem = $(resultsPath + frac_sem_name)
		
		if(!WaveExists(frac_avg))
			Print "StateFraction not found for: " + smpl + " (" + resultsPath + frac_avg_name + ")"
			continue
		endif
		
		traceName = smpl + "_StateFrac" + waveSuffix
		traceSemName = smpl + "_StateFracSem" + waveSuffix
		
		// Extract S1-Sn only (skip S0)
		Make/O/N=(maxState) $traceName = NaN
		Wave fracW = $traceName
		fracW = frac_avg[p+1]
		
		if(WaveExists(frac_sem))
			Make/O/N=(maxState) $traceSemName = 0
			Wave semW = $traceSemName
			semW = frac_sem[p+1]
		else
			Make/O/N=(maxState) $traceSemName = 0
		endif
		Wave semW = $traceSemName
		
		AppendToGraph fracW vs StateLabels
		
		Variable sr, sg, sb
		GetSampleColor(i, sr, sg, sb)
		
		ModifyGraph mode($traceName)=5, hbFill($traceName)=2
		ModifyGraph rgb($traceName)=(sr, sg, sb)
		ModifyGraph useBarStrokeRGB($traceName)=1, barStrokeRGB($traceName)=(0,0,0)
		
		ErrorBars $traceName Y,wave=(semW, semW)
		
		traceList = AddListItem(traceName, traceList, ";", inf)
		labelList = AddListItem(smpl, labelList, ";", inf)
	endfor
	
	if(strlen(traceList) == 0)
		Print "WARNING: No data found for AverageMolDensFraction [" + segLabel + "]"
		DoWindow/K $winName
		SetDataFolder root:
		return -1
	endif
	
	CreateSampleLegendWithTraces(traceList, labelList)
	
	ModifyGraph tick=2, mirror=0, fStyle=1, fSize=14, font="Arial"
	ModifyGraph tick(bottom)=3
	ModifyGraph catGap(bottom)=0.3, barGap(bottom)=0.1
	
	// State× (S1-Sn only)
	Variable totalBarsSeg = maxState * numSamples
	SetBarGraphSizeByItems(totalBarsSeg)
	
	Label left "State Fraction [%]"
	Label bottom "Diffusion State"
	SetAxis left 0, *
	DoWindow/T $winName, "Average State Fraction [" + segLabel + "]"
	
	SetDataFolder root:
	Print "  AverageMolDensFraction [" + segLabel + "] completed"
	return 0
End

// =============================================================================
// Compare Pixel Value Mean per state
// Uses CreateComparisonSummaryPlot (same as ParticleDensity)
// =============================================================================
Function ComparePVMeanCore(basePath, waveSuffix)
	String basePath, waveSuffix
	
	NVAR gDstate = root:Dstate
	Variable Dstate = gDstate
	
	Variable stt
	String stateName, winName, outputPrefix, yLabel, graphTitle
	
	for(stt = 0; stt <= Dstate; stt += 1)
		stateName = GetDstateName(stt, Dstate)
		outputPrefix = "PVMean_S" + num2str(stt)
		winName = "Compare_PVMean_S" + num2str(stt)
		yLabel = "\\F'Arial'\\Z14Pixel Value (S" + num2str(stt) + ": " + stateName + ")"
		graphTitle = "Compare Pixel Value Mean (S" + num2str(stt) + ": " + stateName + ")"
		
		CreateComparisonSummaryPlot(basePath, "PV_mean_m", stt, outputPrefix, winName, yLabel, graphTitle, 1, stt)
		
		RunAutoStatisticalTest(winName)
		Print "  Compare PV Mean S" + num2str(stt) + " completed"
	endfor
	
	return 0
End
