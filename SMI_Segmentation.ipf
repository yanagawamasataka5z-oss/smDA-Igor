#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3
#pragma version=1.0

// =============================================================================
// SMI_Segmentation.ipf - Segmentation Analysis Module
// =============================================================================
// Version 1.0 - Initial implementation
// 
// :
// 1. TraceMatrixSegment
// 2. Segment
// 3. Segment
//
// :
// root:SampleName:Cell_* (Total - )
// root:Seg0:SampleName:Cell_* (Segment=0)
// root:Seg1:SampleName:Cell_* (Segment=1)
// ...
//
// Wave:
// Seg*Wave_Seg0, _Seg1
// =============================================================================

// -----------------------------------------------------------------------------
// 
// -----------------------------------------------------------------------------
Static StrConstant kSegFolderPrefix = "Seg"

// =============================================================================
// Seg
// =============================================================================

// IsSegmentationEnabled - Seg≥1
Function IsSegmentationEnabled()
	NVAR/Z MaxSegment = root:MaxSegment
	if(NVAR_Exists(MaxSegment) && MaxSegment >= 1)
		return 1
	endif
	return 0
End

// GetMaxSegmentValue - MaxSegment0-indexed
Function GetMaxSegmentValue()
	NVAR/Z MaxSegment = root:MaxSegment
	if(NVAR_Exists(MaxSegment))
		return MaxSegment
	endif
	return 0
End

// =============================================================================
// Segment
// =============================================================================

// GetSegmentFolderPath - SegmentET
Function/S GetSegmentFolderPath(segIndex)
	Variable segIndex
	
	return "root:" + kSegFolderPrefix + num2str(segIndex)
End

// GetSegmentSuffix - Segment
Function/S GetSegmentSuffix(segIndex)
	Variable segIndex
	
	return "_Seg" + num2str(segIndex)
End

// CreateSegmentFolders - Seg0/Seg1/...
// sampleName: 
// maxSeg: Segment0-indexed, : maxSeg=1 Seg0, Seg1
Function CreateSegmentFolders(sampleName, maxSeg)
	String sampleName
	Variable maxSeg
	
	String savedDF = GetDataFolder(1)
	Variable segIdx
	
	Printf "=== CreateSegmentFolders: %s, maxSeg=%d ===\r", sampleName, maxSeg
	
	// Segment
	for(segIdx = 0; segIdx <= maxSeg; segIdx += 1)
		String segFolderPath = GetSegmentFolderPath(segIdx)
		
		// root:SegN 
		if(!DataFolderExists(segFolderPath))
			NewDataFolder/O $segFolderPath
			Printf "  Created folder: %s\r", segFolderPath
		endif
		
		// root:SegN:SampleName 
		String sampleFolderPath = segFolderPath + ":" + sampleName
		if(!DataFolderExists(sampleFolderPath))
			NewDataFolder/O $sampleFolderPath
			Printf "  Created folder: %s\r", sampleFolderPath
		endif
	endfor
	
	SetDataFolder $savedDF
	return 0
End

// =============================================================================
// TraceMatrixNaN
// =============================================================================

// SplitTraceMatrixBySegment - TraceMatrixSegment
// sampleName: 
// maxSeg: Segment
// 
// :
// 1. root:SampleName:Cell_*TraceMatrix
// 2. Segment != segIdxNaN
// 3. root:SegN:SampleName:Cell_*
Function SplitTraceMatrixBySegment(sampleName, maxSeg)
	String sampleName
	Variable maxSeg
	
	String savedDF = GetDataFolder(1)
	String srcSamplePath = "root:" + sampleName
	
	if(!DataFolderExists(srcSamplePath))
		Printf "ERROR: Sample folder not found: %s\r", srcSamplePath
		return -1
	endif
	
	// 
	CreateSegmentFolders(sampleName, maxSeg)
	
	Printf "=== SplitTraceMatrixBySegment: %s ===\r", sampleName
	
	// Cell
	SetDataFolder $srcSamplePath
	Variable numFolders = CountObjects("", 4)
	Variable i, segIdx, row
	
	for(i = 0; i < numFolders; i += 1)
		String cellFolderName = GetIndexedObjName("", 4, i)
		
		// Results/Matrix
		if(StringMatch(cellFolderName, "Results") || StringMatch(cellFolderName, "Matrix"))
			continue
		endif
		if(StringMatch(cellFolderName, "Fitting"))
			continue
		endif
		
		String srcCellPath = srcSamplePath + ":" + cellFolderName
		
		// TraceMatrix
		SetDataFolder $srcCellPath
		Wave/Z TraceMatrix
		
		if(!WaveExists(TraceMatrix))
			Printf "  WARNING: TraceMatrix not found in %s\r", srcCellPath
			continue
		endif
		
		Variable numRows = DimSize(TraceMatrix, 0)
		Variable numCols = DimSize(TraceMatrix, 1)
		
		Printf "  Processing %s: %d rows x %d cols\r", cellFolderName, numRows, numCols
		
		// Segment
		for(segIdx = 0; segIdx <= maxSeg; segIdx += 1)
			String dstCellPath = GetSegmentFolderPath(segIdx) + ":" + sampleName + ":" + cellFolderName
			
			// Cell
			if(!DataFolderExists(dstCellPath))
				NewDataFolder/O $dstCellPath
			endif
			
			SetDataFolder $dstCellPath
			
			// TraceMatrix
			String segSuffix = GetSegmentSuffix(segIdx)
			String tmName = "TraceMatrix" + segSuffix
			Duplicate/O TraceMatrix, $tmName
			Wave TM = $tmName
			
			// Segment != segIdxNaN
			// TraceMatrix8Segment
			Variable validCount = 0
			for(row = 0; row < numRows; row += 1)
				Variable segValue = TraceMatrix[row][8]
				if(segValue != segIdx)
					// NaN
					Variable col
					for(col = 0; col < numCols; col += 1)
						TM[row][col] = NaN
					endfor
				else
					validCount += 1
				endif
			endfor
			
			Printf "    Seg%d: %d valid rows (of %d)\r", segIdx, validCount, numRows
		endfor
		
		SetDataFolder $srcSamplePath
	endfor
	
	SetDataFolder $savedDF
	Printf "=== SplitTraceMatrixBySegment completed ===\r"
	return 0
End

// =============================================================================
// Wave
// =============================================================================

// SplitDerivedWavesBySegment - WaveSegment
// TraceMatrixWave
Function SplitDerivedWavesBySegment(sampleName, maxSeg)
	String sampleName
	Variable maxSeg
	
	String savedDF = GetDataFolder(1)
	String srcSamplePath = "root:" + sampleName
	
	if(!DataFolderExists(srcSamplePath))
		Printf "ERROR: Sample folder not found: %s\r", srcSamplePath
		return -1
	endif
	
	Printf "=== SplitDerivedWavesBySegment: %s ===\r", sampleName
	
	// Cell
	SetDataFolder $srcSamplePath
	Variable numFolders = CountObjects("", 4)
	Variable i, segIdx, row
	
	// Wave1D wave
	String waveList1D = "Rtime_S0;Rframe_S0;Xum_S0;Yum_S0;ROI_S0;Int_S0;DF_S0;Dstate_S0;"
	waveList1D += "LocPrecision;Segment;SignalN;SigmaA;Iback;BackN;VarLP;"
	waveList1D += "LocPrecision_S0;"  // S0LocPrecision
	
	// D-stateWave5
	Variable maxState = 5
	Variable stt
	for(stt = 1; stt <= maxState; stt += 1)
		waveList1D += "Rtime_S" + num2str(stt) + ";Rframe_S" + num2str(stt) + ";"
		waveList1D += "Xum_S" + num2str(stt) + ";Yum_S" + num2str(stt) + ";"
		waveList1D += "ROI_S" + num2str(stt) + ";Int_S" + num2str(stt) + ";"
		waveList1D += "DF_S" + num2str(stt) + ";Dstate_S" + num2str(stt) + ";"
		waveList1D += "LocPrecision_S" + num2str(stt) + ";"  // LocPrecision
	endfor
	
	for(i = 0; i < numFolders; i += 1)
		String cellFolderName = GetIndexedObjName("", 4, i)
		
		// Results/Matrix
		if(StringMatch(cellFolderName, "Results") || StringMatch(cellFolderName, "Matrix"))
			continue
		endif
		if(StringMatch(cellFolderName, "Fitting"))
			continue
		endif
		
		String srcCellPath = srcSamplePath + ":" + cellFolderName
		SetDataFolder $srcCellPath
		
		// Segment wave
		Wave/Z SegmentWave = Segment
		if(!WaveExists(SegmentWave))
			Printf "  WARNING: Segment wave not found in %s\r", srcCellPath
			continue
		endif
		
		Variable numRows = numpnts(SegmentWave)
		Printf "  Processing derived waves in %s\r", cellFolderName
		
		// Wave
		Variable wIdx
		Variable numWaves = ItemsInList(waveList1D)
		
		for(wIdx = 0; wIdx < numWaves; wIdx += 1)
			String srcWaveName = StringFromList(wIdx, waveList1D)
			Wave/Z srcWave = $srcWaveName
			
			if(!WaveExists(srcWave))
				continue
			endif
			
			// Segment
			for(segIdx = 0; segIdx <= maxSeg; segIdx += 1)
				String dstCellPath = GetSegmentFolderPath(segIdx) + ":" + sampleName + ":" + cellFolderName
				
				if(!DataFolderExists(dstCellPath))
					NewDataFolder/O $dstCellPath
				endif
				
				SetDataFolder $dstCellPath
				
				String segSuffix = GetSegmentSuffix(segIdx)
				String dstWaveName = srcWaveName + segSuffix
				Duplicate/O srcWave, $dstWaveName
				Wave dstWave = $dstWaveName
				
				// Segment != segIdxNaN
				for(row = 0; row < numRows; row += 1)
					if(SegmentWave[row] != segIdx)
						dstWave[row] = NaN
					endif
				endfor
				
				SetDataFolder $srcCellPath
			endfor
		endfor
		
		SetDataFolder $srcSamplePath
	endfor
	
	SetDataFolder $savedDF
	Printf "=== SplitDerivedWavesBySegment completed ===\r"
	return 0
End

// =============================================================================
// Segmentation
// =============================================================================

// RunSegmentationSplit - 
Function RunSegmentationSplit(sampleName)
	String sampleName
	
	NVAR/Z MaxSegment = root:MaxSegment
	if(!NVAR_Exists(MaxSegment) || MaxSegment == 0)
		Print "ERROR: MaxSegment not set or is 0. Set MaxSegment before running segmentation."
		return -1
	endif
	
	Variable maxSeg = MaxSegment
	
	Printf "========================================\r"
	Printf "Segmentation Split: %s (maxSeg=%d)\r", sampleName, maxSeg
	Printf "========================================\r"
	
	// TraceMatrix
	SplitTraceMatrixBySegment(sampleName, maxSeg)
	
	// Wave
	SplitDerivedWavesBySegment(sampleName, maxSeg)
	
	Printf "========================================\r"
	Printf "Segmentation Split completed\r"
	Printf "========================================\r"
	
	return 0
End

// RunSegmentationAnalysis - SegmentAutoAnalysis
Function RunSegmentationAnalysis(sampleName)
	String sampleName
	
	NVAR/Z MaxSegment = root:MaxSegment
	if(!NVAR_Exists(MaxSegment) || MaxSegment == 0)
		Print "ERROR: MaxSegment not set or is 0."
		return -1
	endif
	
	Variable maxSeg = MaxSegment
	Variable segIdx
	
	Printf "========================================\r"
	Printf "Segmentation Analysis: %s\r"
	Printf "========================================\r"
	
	// 
	RunSegmentationSplit(sampleName)
	
	// SegmentAutoAnalysis
	for(segIdx = 0; segIdx <= maxSeg; segIdx += 1)
		String basePath = GetSegmentFolderPath(segIdx)
		String segSuffix = GetSegmentSuffix(segIdx)
		
		Printf "\r--- Analyzing Segment %d (basePath=%s) ---\r", segIdx, basePath
		
		// AutoAnalysis
		// basePath
		RunSegmentAutoAnalysis(sampleName, basePath, segSuffix)
	endfor
	
	Printf "========================================\r"
	Printf "Segmentation Analysis completed\r"
	Printf "========================================\r"
	
	return 0
End

// RunSegmentAutoAnalysis - SegmentAutoAnalysis
Function RunSegmentAutoAnalysis(sampleName, basePath, waveSuffix)
	String sampleName
	String basePath
	String waveSuffix
	
	Printf "  Running AutoAnalysis for %s in %s (suffix=%s)\r", sampleName, basePath, waveSuffix
	
	// MSD
	NVAR/Z cMSD = root:cMSD
	if(NVAR_Exists(cMSD) && cMSD == 1)
		Printf "    MSD Analysis...\r"
		CalculateMSD(sampleName, basePath=basePath, waveSuffix=waveSuffix)
		NVAR cFitType = root:cFitType
		Variable fitTypeVal = cFitType
		FitMSD_Safe(sampleName, fitTypeVal, basePath=basePath, waveSuffix=waveSuffix)
		DisplayMSDGraphHMM(sampleName, basePath=basePath, waveSuffix=waveSuffix)
	endif
	
	//  (Step Size Histogram)
	NVAR/Z cStepSize = root:cStepSize
	if(!NVAR_Exists(cStepSize) || cStepSize == 1)
		CalculateStepSizeHistogramHMM(sampleName, basePath=basePath, waveSuffix=waveSuffix)
		DisplayStepSizeHistogramHMM(sampleName, basePath=basePath, waveSuffix=waveSuffix)
		NVAR gDstate = root:Dstate
		Variable Dstate = gDstate
		FitStepSizeDistributionHMM(sampleName, Dstate, basePath=basePath, waveSuffix=waveSuffix)
	endif
	
	// 
	NVAR/Z cIntensity = root:cIntensity
	if(!NVAR_Exists(cIntensity) || cIntensity == 1)
		CreateIntensityHistogram(sampleName, basePath=basePath, waveSuffix=waveSuffix)
		DisplayIntensityHistHMM(sampleName, basePath=basePath, waveSuffix=waveSuffix)
	endif
	
	// On-time
	NVAR/Z cOffrate = root:cOffrate
	if(!NVAR_Exists(cOffrate) || cOffrate == 1)
		Duration_Gcount(sampleName, basePath=basePath, waveSuffix=waveSuffix)
	endif
	
	// On-rate
	NVAR/Z cOnrate = root:cOnrate
	if(!NVAR_Exists(cOnrate) || cOnrate == 1)
		OnrateAnalysisWithOption(sampleName, basePath=basePath, waveSuffix=waveSuffix)
	endif
	
	// 
	StatsResultsMatrix(basePath, sampleName, "")
	
	Printf "  AutoAnalysis completed for Segment\r"
	return 0
End

// =============================================================================
// Segment
// =============================================================================

// CompareSegments - Segment
// paramType: "HMMP", "Intensity", "Ontime", "Onrate", etc.
Function CompareSegments(sampleName, paramType)
	String sampleName
	String paramType
	
	NVAR/Z MaxSegment = root:MaxSegment
	if(!NVAR_Exists(MaxSegment) || MaxSegment == 0)
		Print "ERROR: MaxSegment not set or is 0."
		return -1
	endif
	
	Variable maxSeg = MaxSegment
	
	Printf "=== CompareSegments: %s, param=%s ===\r", sampleName, paramType
	
	// 
	// Total (root:SampleName) + Seg0 + Seg1 + ...
	Variable numGroups = 1 + maxSeg + 1  // Total + Seg0SegN
	
	EnsureComparisonFolder()
	SetDataFolder root:Comparison
	
	// 
	String labelWaveName = "SegCmp_" + paramType + "_Labels"
	Make/O/T/N=(numGroups) $labelWaveName
	Wave/T Labels = $labelWaveName
	
	Labels[0] = "Total"
	Variable segIdx
	for(segIdx = 0; segIdx <= maxSeg; segIdx += 1)
		Labels[segIdx + 1] = "Seg" + num2str(segIdx)
	endfor
	
	// 
	strswitch(paramType)
		case "HMMP":
			CompareSegmentHMMP(sampleName, maxSeg)
			break
		case "Intensity":
			CompareSegmentIntensity(sampleName, maxSeg)
			break
		case "Ontime":
			CompareSegmentOntime(sampleName, maxSeg)
			break
		case "Onrate":
			CompareSegmentOnrate(sampleName, maxSeg)
			break
		default:
			Printf "Unknown paramType: %s\r", paramType
			return -1
	endswitch
	
	SetDataFolder root:
	return 0
End

// CompareSegmentHMMP - SegmentHMMP
Function CompareSegmentHMMP(sampleName, maxSeg)
	String sampleName
	Variable maxSeg
	
	NVAR gDstate = root:Dstate
	Variable Dstate = gDstate
	
	Variable numGroups = 1 + maxSeg + 1
	Variable segIdx, stt
	
	SetDataFolder root:Comparison
	
	// 
	for(stt = 1; stt <= Dstate; stt += 1)
		String stateName = GetDstateName(stt, Dstate)
		String meanWaveName = "SegCmp_HMMP_S" + num2str(stt) + "_mean"
		String semWaveName = "SegCmp_HMMP_S" + num2str(stt) + "_sem"
		
		Make/O/D/N=(numGroups) $meanWaveName = NaN
		Make/O/D/N=(numGroups) $semWaveName = NaN
		Wave meanW = $meanWaveName
		Wave semW = $semWaveName
		
		// Total
		String totalAvgPath = "root:" + sampleName + ":Results:HMMP_m_avg"
		String totalSemPath = "root:" + sampleName + ":Results:HMMP_m_sem"
		Wave/Z totalAvg = $totalAvgPath
		Wave/Z totalSem = $totalSemPath
		if(WaveExists(totalAvg) && WaveExists(totalSem))
			if(stt < DimSize(totalAvg, 0))
				meanW[0] = totalAvg[stt]
				semW[0] = totalSem[stt]
			endif
		endif
		
		// Segment
		for(segIdx = 0; segIdx <= maxSeg; segIdx += 1)
			String segBasePath = GetSegmentFolderPath(segIdx)
			String segAvgPath = segBasePath + ":" + sampleName + ":Results:HMMP_m_avg"
			String segSemPath = segBasePath + ":" + sampleName + ":Results:HMMP_m_sem"
			Wave/Z segAvg = $segAvgPath
			Wave/Z segSem = $segSemPath
			if(WaveExists(segAvg) && WaveExists(segSem))
				if(stt < DimSize(segAvg, 0))
					meanW[segIdx + 1] = segAvg[stt]
					semW[segIdx + 1] = segSem[stt]
				endif
			endif
		endfor
		
		// 
		String winName = "SegCmp_HMMP_S" + num2str(stt)
		DoWindow/K $winName
		
		Wave/T Labels = $("SegCmp_HMMP_Labels")
		Display/K=1/N=$winName meanW vs Labels
		
		ModifyGraph mode=5, hbFill=2
		ErrorBars $meanWaveName Y,wave=(semW, semW)
		
		ModifyGraph tick=2, mirror=0, fStyle=1, fSize=14, font="Arial"
		ModifyGraph catGap(bottom)=0.3
		Label left "\\F'Arial'\\Z14Population\\B" + stateName + "\\M [%]"
		SetAxis left 0, *
		
		String graphTitle = sampleName + " HMMP " + stateName + " by Segment"
		DoWindow/T $winName, graphTitle
	endfor
	
	SetDataFolder root:
	return 0
End

// CompareSegmentIntensity - SegmentIntensity
Function CompareSegmentIntensity(sampleName, maxSeg)
	String sampleName
	Variable maxSeg
	
	NVAR gDstate = root:Dstate
	Variable Dstate = gDstate
	
	Variable numGroups = 1 + maxSeg + 1
	Variable segIdx, stt
	
	SetDataFolder root:Comparison
	
	// 
	for(stt = 0; stt <= Dstate; stt += 1)
		String stateName = GetDstateName(stt, Dstate)
		String meanWaveName = "SegCmp_Int_S" + num2str(stt) + "_mean"
		String semWaveName = "SegCmp_Int_S" + num2str(stt) + "_sem"
		
		Make/O/D/N=(numGroups) $meanWaveName = NaN
		Make/O/D/N=(numGroups) $semWaveName = NaN
		Wave meanW = $meanWaveName
		Wave semW = $semWaveName
		
		// Total
		String totalAvgPath = "root:" + sampleName + ":Results:mean_osize_m_avg"
		String totalSemPath = "root:" + sampleName + ":Results:mean_osize_m_sem"
		Wave/Z totalAvg = $totalAvgPath
		Wave/Z totalSem = $totalSemPath
		if(WaveExists(totalAvg) && WaveExists(totalSem))
			if(stt < DimSize(totalAvg, 0))
				meanW[0] = totalAvg[stt]
				semW[0] = totalSem[stt]
			endif
		endif
		
		// Segment
		for(segIdx = 0; segIdx <= maxSeg; segIdx += 1)
			String segBasePath = GetSegmentFolderPath(segIdx)
			String segAvgPath = segBasePath + ":" + sampleName + ":Results:mean_osize_m_avg"
			String segSemPath = segBasePath + ":" + sampleName + ":Results:mean_osize_m_sem"
			Wave/Z segAvg = $segAvgPath
			Wave/Z segSem = $segSemPath
			if(WaveExists(segAvg) && WaveExists(segSem))
				if(stt < DimSize(segAvg, 0))
					meanW[segIdx + 1] = segAvg[stt]
					semW[segIdx + 1] = segSem[stt]
				endif
			endif
		endfor
		
		// 
		String winName = "SegCmp_Int_S" + num2str(stt)
		DoWindow/K $winName
		
		Wave/T Labels = $("SegCmp_Intensity_Labels")
		if(!WaveExists(Labels))
			// 
			Make/O/T/N=(numGroups) SegCmp_Intensity_Labels
			Wave/T Labels = SegCmp_Intensity_Labels
			Labels[0] = "Total"
			Variable idx
			for(idx = 0; idx <= maxSeg; idx += 1)
				Labels[idx + 1] = "Seg" + num2str(idx)
			endfor
		endif
		
		Display/K=1/N=$winName meanW vs Labels
		
		ModifyGraph mode=5, hbFill=2
		ErrorBars $meanWaveName Y,wave=(semW, semW)
		
		ModifyGraph tick=2, mirror=0, fStyle=1, fSize=14, font="Arial"
		ModifyGraph catGap(bottom)=0.3
		Label left "\\F'Arial'\\Z14Mean Oligomer Size\\B" + stateName + "\\M"
		SetAxis left 0, *
		
		String graphTitle = sampleName + " Intensity " + stateName + " by Segment"
		DoWindow/T $winName, graphTitle
	endfor
	
	SetDataFolder root:
	Printf "CompareSegmentIntensity completed\r"
	return 0
End

// CompareSegmentOntime - SegmentOn-time
Function CompareSegmentOntime(sampleName, maxSeg)
	String sampleName
	Variable maxSeg
	
	NVAR gDstate = root:Dstate
	Variable Dstate = gDstate
	
	Variable numGroups = 1 + maxSeg + 1
	Variable segIdx, stt
	
	SetDataFolder root:Comparison
	
	// 
	Make/O/T/N=(numGroups) SegCmp_Ontime_Labels
	Wave/T Labels = SegCmp_Ontime_Labels
	Labels[0] = "Total"
	for(segIdx = 0; segIdx <= maxSeg; segIdx += 1)
		Labels[segIdx + 1] = "Seg" + num2str(segIdx)
	endfor
	
	//  (Tau)
	for(stt = 1; stt <= Dstate; stt += 1)
		String stateName = GetDstateName(stt, Dstate)
		String meanWaveName = "SegCmp_Tau_S" + num2str(stt) + "_mean"
		String semWaveName = "SegCmp_Tau_S" + num2str(stt) + "_sem"
		
		Make/O/D/N=(numGroups) $meanWaveName = NaN
		Make/O/D/N=(numGroups) $semWaveName = NaN
		Wave meanW = $meanWaveName
		Wave semW = $semWaveName
		
		// Total
		String totalAvgPath = "root:" + sampleName + ":Results:Tau_Duration_m_avg"
		String totalSemPath = "root:" + sampleName + ":Results:Tau_Duration_m_sem"
		Wave/Z totalAvg = $totalAvgPath
		Wave/Z totalSem = $totalSemPath
		if(WaveExists(totalAvg) && WaveExists(totalSem))
			if(stt < DimSize(totalAvg, 0))
				meanW[0] = totalAvg[stt]
				semW[0] = totalSem[stt]
			endif
		endif
		
		// Segment
		for(segIdx = 0; segIdx <= maxSeg; segIdx += 1)
			String segBasePath = GetSegmentFolderPath(segIdx)
			String segAvgPath = segBasePath + ":" + sampleName + ":Results:Tau_Duration_m_avg"
			String segSemPath = segBasePath + ":" + sampleName + ":Results:Tau_Duration_m_sem"
			Wave/Z segAvg = $segAvgPath
			Wave/Z segSem = $segSemPath
			if(WaveExists(segAvg) && WaveExists(segSem))
				if(stt < DimSize(segAvg, 0))
					meanW[segIdx + 1] = segAvg[stt]
					semW[segIdx + 1] = segSem[stt]
				endif
			endif
		endfor
		
		// 
		String winName = "SegCmp_Tau_S" + num2str(stt)
		DoWindow/K $winName
		
		Display/K=1/N=$winName meanW vs Labels
		
		ModifyGraph mode=5, hbFill=2
		ErrorBars $meanWaveName Y,wave=(semW, semW)
		
		ModifyGraph tick=2, mirror=0, fStyle=1, fSize=14, font="Arial"
		ModifyGraph catGap(bottom)=0.3
		Label left "\\F'Arial'\\Z14τ\\B" + stateName + "\\M [s]"
		SetAxis left 0, *
		
		String graphTitle = sampleName + " On-time τ " + stateName + " by Segment"
		DoWindow/T $winName, graphTitle
	endfor
	
	// Fraction
	for(stt = 1; stt <= Dstate; stt += 1)
		stateName = GetDstateName(stt, Dstate)
		meanWaveName = "SegCmp_Frac_S" + num2str(stt) + "_mean"
		semWaveName = "SegCmp_Frac_S" + num2str(stt) + "_sem"
		
		Make/O/D/N=(numGroups) $meanWaveName = NaN
		Make/O/D/N=(numGroups) $semWaveName = NaN
		Wave meanW = $meanWaveName
		Wave semW = $semWaveName
		
		// Total
		totalAvgPath = "root:" + sampleName + ":Results:Fraction_Duration_m_avg"
		totalSemPath = "root:" + sampleName + ":Results:Fraction_Duration_m_sem"
		Wave/Z totalAvg = $totalAvgPath
		Wave/Z totalSem = $totalSemPath
		if(WaveExists(totalAvg) && WaveExists(totalSem))
			if(stt < DimSize(totalAvg, 0))
				meanW[0] = totalAvg[stt]
				semW[0] = totalSem[stt]
			endif
		endif
		
		// Segment
		for(segIdx = 0; segIdx <= maxSeg; segIdx += 1)
			segBasePath = GetSegmentFolderPath(segIdx)
			segAvgPath = segBasePath + ":" + sampleName + ":Results:Fraction_Duration_m_avg"
			segSemPath = segBasePath + ":" + sampleName + ":Results:Fraction_Duration_m_sem"
			Wave/Z segAvg = $segAvgPath
			Wave/Z segSem = $segSemPath
			if(WaveExists(segAvg) && WaveExists(segSem))
				if(stt < DimSize(segAvg, 0))
					meanW[segIdx + 1] = segAvg[stt]
					semW[segIdx + 1] = segSem[stt]
				endif
			endif
		endfor
		
		// 
		winName = "SegCmp_Frac_S" + num2str(stt)
		DoWindow/K $winName
		
		Display/K=1/N=$winName meanW vs Labels
		
		ModifyGraph mode=5, hbFill=2
		ErrorBars $meanWaveName Y,wave=(semW, semW)
		
		ModifyGraph tick=2, mirror=0, fStyle=1, fSize=14, font="Arial"
		ModifyGraph catGap(bottom)=0.3
		Label left "\\F'Arial'\\Z14Fraction\\B" + stateName + "\\M [%]"
		SetAxis left 0, *
		
		graphTitle = sampleName + " On-time Fraction " + stateName + " by Segment"
		DoWindow/T $winName, graphTitle
	endfor
	
	SetDataFolder root:
	Printf "CompareSegmentOntime completed\r"
	return 0
End

// CompareSegmentOnrate - SegmentOn-rate
Function CompareSegmentOnrate(sampleName, maxSeg)
	String sampleName
	Variable maxSeg
	
	NVAR gDstate = root:Dstate
	Variable Dstate = gDstate
	
	Variable numGroups = 1 + maxSeg + 1
	Variable segIdx, stt
	
	SetDataFolder root:Comparison
	
	// 
	Make/O/T/N=(numGroups) SegCmp_Onrate_Labels
	Wave/T Labels = SegCmp_Onrate_Labels
	Labels[0] = "Total"
	for(segIdx = 0; segIdx <= maxSeg; segIdx += 1)
		Labels[segIdx + 1] = "Seg" + num2str(segIdx)
	endfor
	
	// 
	for(stt = 1; stt <= Dstate; stt += 1)
		String stateName = GetDstateName(stt, Dstate)
		String meanWaveName = "SegCmp_Onrate_S" + num2str(stt) + "_mean"
		String semWaveName = "SegCmp_Onrate_S" + num2str(stt) + "_sem"
		
		Make/O/D/N=(numGroups) $meanWaveName = NaN
		Make/O/D/N=(numGroups) $semWaveName = NaN
		Wave meanW = $meanWaveName
		Wave semW = $semWaveName
		
		// Total - Statewave
		String totalAvgPath = "root:" + sampleName + ":Results:ParaOnrate_S" + num2str(stt) + "_m_avg"
		String totalSemPath = "root:" + sampleName + ":Results:ParaOnrate_S" + num2str(stt) + "_m_sem"
		Wave/Z totalAvg = $totalAvgPath
		Wave/Z totalSem = $totalSemPath
		
		// State
		if(!WaveExists(totalAvg))
			totalAvgPath = "root:" + sampleName + ":Results:ParaOnrate_m_avg"
			totalSemPath = "root:" + sampleName + ":Results:ParaOnrate_m_sem"
			Wave/Z totalAvg = $totalAvgPath
			Wave/Z totalSem = $totalSemPath
			if(WaveExists(totalAvg) && WaveExists(totalSem))
				// k_on (row 0) 
				meanW[0] = totalAvg[0]
				semW[0] = totalSem[0]
			endif
		else
			if(WaveExists(totalAvg) && WaveExists(totalSem))
				meanW[0] = totalAvg[0]
				semW[0] = totalSem[0]
			endif
		endif
		
		// Segment
		for(segIdx = 0; segIdx <= maxSeg; segIdx += 1)
			String segBasePath = GetSegmentFolderPath(segIdx)
			String segAvgPath = segBasePath + ":" + sampleName + ":Results:ParaOnrate_S" + num2str(stt) + "_m_avg"
			String segSemPath = segBasePath + ":" + sampleName + ":Results:ParaOnrate_S" + num2str(stt) + "_m_sem"
			Wave/Z segAvg = $segAvgPath
			Wave/Z segSem = $segSemPath
			
			if(!WaveExists(segAvg))
				segAvgPath = segBasePath + ":" + sampleName + ":Results:ParaOnrate_m_avg"
				segSemPath = segBasePath + ":" + sampleName + ":Results:ParaOnrate_m_sem"
				Wave/Z segAvg = $segAvgPath
				Wave/Z segSem = $segSemPath
				if(WaveExists(segAvg) && WaveExists(segSem))
					meanW[segIdx + 1] = segAvg[0]
					semW[segIdx + 1] = segSem[0]
				endif
			else
				if(WaveExists(segAvg) && WaveExists(segSem))
					meanW[segIdx + 1] = segAvg[0]
					semW[segIdx + 1] = segSem[0]
				endif
			endif
		endfor
		
		// 
		String winName = "SegCmp_Onrate_S" + num2str(stt)
		DoWindow/K $winName
		
		Display/K=1/N=$winName meanW vs Labels
		
		ModifyGraph mode=5, hbFill=2
		ErrorBars $meanWaveName Y,wave=(semW, semW)
		
		ModifyGraph tick=2, mirror=0, fStyle=1, fSize=14, font="Arial"
		ModifyGraph catGap(bottom)=0.3
		Label left "\\F'Arial'\\Z14k\\Bon\\M\\B" + stateName + "\\M [/μm²/s]"
		SetAxis left 0, *
		
		String graphTitle = sampleName + " On-rate " + stateName + " by Segment"
		DoWindow/T $winName, graphTitle
	endfor
	
	SetDataFolder root:
	Printf "CompareSegmentOnrate completed\r"
	return 0
End

// =============================================================================
// 
// =============================================================================

// GetMaxSegmentFromData - Segment
Function GetMaxSegmentFromData(sampleName)
	String sampleName
	
	String savedDF = GetDataFolder(1)
	String samplePath = "root:" + sampleName
	
	if(!DataFolderExists(samplePath))
		return -1
	endif
	
	Variable maxSegFound = 0
	
	SetDataFolder $samplePath
	Variable numFolders = CountObjects("", 4)
	Variable i
	
	for(i = 0; i < numFolders; i += 1)
		String folderName = GetIndexedObjName("", 4, i)
		if(StringMatch(folderName, "Results") || StringMatch(folderName, "Matrix"))
			continue
		endif
		
		String cellPath = samplePath + ":" + folderName
		SetDataFolder $cellPath
		
		Wave/Z SegmentWave = Segment
		if(WaveExists(SegmentWave))
			WaveStats/Q SegmentWave
			if(V_max > maxSegFound)
				maxSegFound = V_max
			endif
		endif
		
		SetDataFolder $samplePath
	endfor
	
	SetDataFolder $savedDF
	
	Printf "GetMaxSegmentFromData: %s -> maxSeg=%d\r", sampleName, maxSegFound
	return maxSegFound
End

// UpdateMaxSegmentFromData - MaxSegment
Function UpdateMaxSegmentFromData(sampleName)
	String sampleName
	
	Variable maxSeg = GetMaxSegmentFromData(sampleName)
	
	if(maxSeg >= 0)
		Variable/G root:MaxSegment = maxSeg
		Printf "MaxSegment updated to %d\r", maxSeg
	endif
	
	return maxSeg
End

// =============================================================================
// 
// =============================================================================

// GetSegmentLabel - waveSuffixSeg
// waveSuffix = "" → "Total" (Seg≥1) or "" (Seg=0)
// waveSuffix = "_Seg0" → "Seg0"
// waveSuffix = "_Seg1" → "Seg1"
Function/S GetSegmentLabel(waveSuffix)
	String waveSuffix
	
	if(strlen(waveSuffix) == 0)
		// Seg≥1"Total"
		if(IsSegmentationEnabled())
			return "Total"
		else
			return ""
		endif
	else
		// "_Seg0" → "Seg0", "_Seg1" → "Seg1"
		if(StringMatch(waveSuffix, "_Seg*"))
			return waveSuffix[1, strlen(waveSuffix)-1]
		else
			return waveSuffix
		endif
	endif
End

// GetGraphTitleWithSeg - Seg
// baseTitle = "IntHist_sample1", waveSuffix = "_Seg0" → "IntHist_sample1 [Seg0]"
Function/S GetGraphTitleWithSeg(baseTitle, waveSuffix)
	String baseTitle, waveSuffix
	
	String segLabel = GetSegmentLabel(waveSuffix)
	if(strlen(segLabel) > 0)
		return baseTitle + " [" + segLabel + "]"
	else
		return baseTitle
	endif
End

// GetTraceNameWithSeg - Seg
// baseName = "S1", waveSuffix = "_Seg0" → "S1 (Seg0)"
Function/S GetTraceNameWithSeg(baseName, waveSuffix)
	String baseName, waveSuffix
	
	String segLabel = GetSegmentLabel(waveSuffix)
	if(strlen(segLabel) > 0)
		return baseName + " (" + segLabel + ")"
	else
		return baseName
	endif
End

