#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3
#pragma version=2.90

// =============================================================================
// SMI_Timelapse.ipf - Time-lapse Analysis Module
// =============================================================================
// Version 2.9.0 - Colocalization Support & basepath compatibility
// - TL_DataSource: Per Channel / Colocalization selection
// - TL_GetComparisonPath: Dynamic comparison path based on data source
// - Colocalization parameters: ColHMMP_abs, ColOntime_mean, ColOnRate, etc.
// - TL_CreateSampleList: 2D sample list creation
// - TL_CompareAllWithMode: Original/Normalize/Difference processing
// - TL_ProcessSelectedParameter: Single parameter processing
// - State names from GetDstateName (all, immobile, slow, etc.)
// - Color-coded buttons: Blue (single), Orange (all), Green (density)
// =============================================================================

// -----------------------------------------------------------------------------
// TL_DataSourceProc - Data Source
// -----------------------------------------------------------------------------
Function TL_DataSourceProc(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	
	NVAR/Z TL_DataSource = root:TL_DataSource
	if(!NVAR_Exists(TL_DataSource))
		Variable/G root:TL_DataSource = 0
	endif
	
	root:TL_DataSource = popNum - 1  // 0=Per Channel, 1=Colocalization
	
	Print "Data Source changed to: " + popStr
	
	// 
	TL_UpdateParameterPopup()
End

// -----------------------------------------------------------------------------
// TL_NormMethodProc - 
// -----------------------------------------------------------------------------
Function TL_NormMethodProc(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	
	NVAR/Z TL_NormMethod = root:TL_NormMethod
	if(!NVAR_Exists(TL_NormMethod))
		Variable/G root:TL_NormMethod = 0
	endif
	
	root:TL_NormMethod = popNum - 1  // 0=Mean, 1=Each cell
	
	// 
	PopupMenu tab7_popup_normby, win=SMI_MainPanel, mode=popNum
	PopupMenu tab7_popup_normby2, win=SMI_MainPanel, mode=popNum
	
	Print "Normalization method changed to: " + popStr
End

// -----------------------------------------------------------------------------
// TL_GetComparisonPath - DataSourceComparison
// -----------------------------------------------------------------------------
Function/S TL_GetComparisonPath()
	NVAR/Z TL_DataSource = root:TL_DataSource
	Variable dataSource = NVAR_Exists(TL_DataSource) ? TL_DataSource : 0
	
	// Per Channel: root:Comparison 
	// Colocalization: root:Comparison 
	// : GetComparisonPathFromBaseEC1/Seg1root:Comparison
	return "root:Comparison"
End

// -----------------------------------------------------------------------------
// TL_IsColocalizationMode - 
// -----------------------------------------------------------------------------
Function TL_IsColocalizationMode()
	NVAR/Z TL_DataSource = root:TL_DataSource
	return (NVAR_Exists(TL_DataSource) && TL_DataSource == 1)
End

// -----------------------------------------------------------------------------
// TL_CreateSampleListForChannel - TL_SampleList/
// channelIdx: 0=C1, 1=C2
// BothTL_SampleList_C1/C2TL_SampleList
// C1/C2TL_SampleList
// : 0=, -1=
// -----------------------------------------------------------------------------
Function TL_CreateSampleListForChannel(channelIdx)
	Variable channelIdx
	
	String savedDF = GetDataFolder(1)
	
	// BothTL_SampleList_C1/C2
	NVAR/Z ColOutputChannel = root:ColOutputChannel
	Variable chMode = NVAR_Exists(ColOutputChannel) ? ColOutputChannel : 0
	
	NewDataFolder/O root:Comparison
	SetDataFolder root:Comparison
	
	if(chMode == 0)
		// Both: TL_SampleList_C1  TL_SampleList_C2  TL_SampleList 
		String srcName = SelectString(channelIdx, "TL_SampleList_C1", "TL_SampleList_C2")
		Wave/T/Z srcList = $srcName
		
		if(!WaveExists(srcList))
			Print "Error: " + srcName + " not found. Please run 'Create Sample List' first."
			SetDataFolder $savedDF
			return -1
		endif
		
		Duplicate/O/T srcList, TL_SampleList
	else
		// C1 or C2 : TL_SampleList
		Wave/T/Z existingList = TL_SampleList
		if(!WaveExists(existingList))
			Print "Error: TL_SampleList not found. Please run 'Create Sample List' first."
			SetDataFolder $savedDF
			return -1
		endif
	endif
	
	SetDataFolder $savedDF
	return 0
End

// -----------------------------------------------------------------------------
// TotalDensityAnalysis - Density
// 
// -----------------------------------------------------------------------------
Function TotalDensityAnalysis(SampleName)
	String SampleName
	
	Variable numFolders = CountDataFolders(SampleName)
	Variable m
	String FolderName
	
	NVAR/Z MinFrame = root:MinFrame
	NVAR/Z FrameNum = root:FrameNum
	NVAR framerate = root:framerate
	NVAR scale = root:scale
	NVAR DSmoothing = root:DSmoothing
	NVAR DensityStartFrame = root:DensityStartFrame
	NVAR DensityEndFrame = root:DensityEndFrame

	Variable startFrame = DensityStartFrame
	Variable endFrame = DensityEndFrame
	Variable smoothing = DSmoothing
	
	Variable rangeFrames = endFrame - startFrame + 1
	
	Print "=== Density Analysis ==="
	Print "Sample: " + SampleName
	Print "Frame range: " + num2str(startFrame) + " - " + num2str(endFrame)
	
	for(m = 0; m < numFolders; m += 1)
		FolderName = SampleName + num2str(m + 1)
		
		if(!DataFolderExists("root:" + SampleName + ":" + FolderName))
			continue
		endif
		
		SetDataFolder root:$(SampleName):$(FolderName)
		
		Wave/Z ROI_S0, Rtime_S0, Xum_S0, Yum_S0
		if(!WaveExists(ROI_S0) || !WaveExists(Rtime_S0))
			continue
		endif
		
		// 
		Make/O/N=(rangeFrames) Wtime_density, Density_t, SpotCount_t
		Wtime_density = (startFrame + p) * framerate
		
		Variable frame, spotCount
		for(frame = startFrame; frame <= endFrame; frame += 1)
			// 
			Extract/FREE ROI_S0, tempROI, Rtime_S0 == frame
			spotCount = numpnts(tempROI)
			SpotCount_t[frame - startFrame] = spotCount
		endfor
		
		// XY
		WaveStats/Q Xum_S0
		Variable xRange = V_max - V_min
		WaveStats/Q Yum_S0
		Variable yRange = V_max - V_min
		Variable areaEst = xRange * yRange
		
		if(areaEst > 0)
			Density_t = SpotCount_t / areaEst
		else
			Density_t = NaN
		endif
		
		// smoothing2NaN
		if(smoothing >= 2)
			WaveStats/Q Density_t
			if(V_npnts > smoothing)
				Smooth/B smoothing, Density_t
			endif
		endif
		
		Print "  " + FolderName + ": Area=" + num2str(areaEst) + " um^2"
	endfor
	
	SetDataFolder root:
End

// -----------------------------------------------------------------------------
// AnalyzeDensityTL - Density
// ParaDensity_m
// -----------------------------------------------------------------------------
Function AnalyzeDensityTL()
	String FName
	String WNameDensity
	
	NewDataFolder/O/S root:Comparison
	SetDataFolder root:
	
	Variable m = CountObjects("", 4)  // 
	Variable i = 1  // i=0Packages
	Variable NumCell
	
	NVAR/Z LigandNumTL = root:LigandNumTL
	NVAR/Z TimeInterval = root:TimeInterval
	
	Variable Interval = 5  // min
	if(NVAR_Exists(TimeInterval) && TimeInterval > 0)
		Interval = TimeInterval
	endif
	
	Do
		SetDataFolder root:
		String exception = GetIndexedObjName("", 4, i)
		
		// 
		if(StringMatch(exception, "Packages") || StringMatch(exception, "Comparison") || StringMatch(exception, "Col") || StringMatch(exception, "ExtCol"))
			i += 1
		endif
		
		if(i == m)
			break
		endif
		
		// ParaDensity
		FName = GetIndexedObjName("", 4, i)
		WNameDensity = FName + "_Density"
		
		String matrixPath = "root:" + FName + ":Matrix:ParaDensity_m"
		Wave/Z ParaDensity_m = $matrixPath
		
		if(!WaveExists(ParaDensity_m))
			i += 1
			continue
		endif
		
		Duplicate/O ParaDensity_m, Density
		MatrixTranspose Density
		NumCell = DimSize(Density, 0)
		
		Make/O/N=(NumCell) root:Comparison:$WNameDensity = Density[p][2]
		
		SetDataFolder root:Comparison
		
		if(i == 1)
			Make/O/N=(NumCell, m-2) MatrixDensity
			Edit $WNameDensity
			MatrixDensity[][i-1] = Density[p][2]
		else
			AppendToTable $WNameDensity
			MatrixDensity[][i-1] = Density[p][2]
		endif
		
		KillWaves/Z Density
		i += 1
	While(i < m)
	
	// 
	Wave/Z MatrixDensity = root:Comparison:MatrixDensity
	if(!WaveExists(MatrixDensity))
		Print "Error: No density data found"
		SetDataFolder root:
		return 0
	endif
	
	MatrixTranspose MatrixDensity
	Edit MatrixDensity
	
	// 
	Duplicate/O MatrixDensity, NormMatrixDensity
	NormMatrixDensity = MatrixDensity[p][q] / MatrixDensity[1][q]
	Edit NormMatrixDensity
	
	// 
	Variable numTimePoints = m - 2
	Make/O/N=(numTimePoints) timelapse
	timelapse = (p - 1) * Interval
	
	// Density
	for(i = 0; i < NumCell; i += 1)
		String WNameDensityCell = "DensityCell" + num2str(i + 1)
		Make/O/N=(numTimePoints) $WNameDensityCell = MatrixDensity[p][i]
		
		if(i == 0)
			Edit timelapse, $WNameDensityCell
			Display $WNameDensityCell vs timelapse
			ModifyGraph width={Aspect, 1.618}
			Label left "\\F'Arial'\\Z14Density [1/µm\\S2\\M]"
			Label bottom "\\Z14\\F'Arial'time (min)"
			ModifyGraph tick=2, mirror=1, fStyle=1, fSize=14, font="Arial"
		else
			AppendToTable $WNameDensityCell
			AppendToGraph $WNameDensityCell vs timelapse
		endif
	endfor
	
	// Density
	for(i = 0; i < NumCell; i += 1)
		String WNameNormDensityCell = "NormDensityCell" + num2str(i + 1)
		Make/O/N=(numTimePoints) $WNameNormDensityCell = NormMatrixDensity[p][i]
		
		if(i == 0)
			Edit timelapse, $WNameNormDensityCell
			Display $WNameNormDensityCell vs timelapse
			ModifyGraph width={Aspect, 1.618}
			Label left "\\F'Arial'\\Z14Norm. Density"
			Label bottom "\\Z14\\F'Arial'time (min)"
			ModifyGraph tick=2, mirror=1, fStyle=1, fSize=14, font="Arial"
		else
			AppendToTable $WNameNormDensityCell
			AppendToGraph $WNameNormDensityCell vs timelapse
		endif
	endfor
	
	// ±SEM
	Make/O/N=(numTimePoints) DensityAverage, DensitySD, DensitySEM, DensityNpnts
	
	for(i = 0; i < numTimePoints; i += 1)
		ImageStats/G={i, i, 0, NumCell-1} MatrixDensity
		DensityAverage[i] = V_avg
		DensitySD[i] = V_sdev
		DensitySEM[i] = V_sdev / sqrt(NumCell)
		DensityNpnts[i] = V_npnts
	endfor
	
	Edit timelapse, DensityAverage, DensitySD, DensitySEM, DensityNpnts
	Display DensityAverage vs timelapse
	ModifyGraph width={Aspect, 1.618}
	Label left "\\F'Arial'\\Z14Density [1/µm\\S2\\M]"
	Label bottom "\\Z14\\F'Arial'time (min)"
	ModifyGraph tick=2, mirror=1, fStyle=1, fSize=14, font="Arial"
	ModifyGraph mode=4, marker=19, rgb=(0,0,0)
	ErrorBars DensityAverage Y, wave=(DensitySEM, DensitySEM)
	
	// 
	Make/O/N=(numTimePoints) NormDensityAverage, NormDensitySD, NormDensitySEM, NormDensityNpnts
	
	for(i = 0; i < numTimePoints; i += 1)
		ImageStats/G={i, i, 0, NumCell-1} NormMatrixDensity
		NormDensityAverage[i] = V_avg
		NormDensitySD[i] = V_sdev
		NormDensitySEM[i] = V_sdev / sqrt(NumCell)
		NormDensityNpnts[i] = V_npnts
	endfor
	
	Edit timelapse, NormDensityAverage, NormDensitySD, NormDensitySEM, NormDensityNpnts
	Display NormDensityAverage vs timelapse
	ModifyGraph width={Aspect, 1.618}
	Label left "\\F'Arial'\\Z14Norm. Density"
	Label bottom "\\Z14\\F'Arial'time (min)"
	ModifyGraph tick=2, mirror=1, fStyle=1, fSize=14, font="Arial"
	ModifyGraph mode=4, marker=19, rgb=(0,0,0)
	ErrorBars NormDensityAverage Y, wave=(NormDensitySEM, NormDensitySEM)
	
	SetDataFolder root:
	Print "=== Density Timelapse Analysis Complete ==="
End

// -----------------------------------------------------------------------------
// NormalizeViolinPlotsTL - Violin plott0
// Summary PlotTimelapse Parameterst0
// root:Comparisoncelldata wave
// -----------------------------------------------------------------------------
Function NormalizeViolinPlotsTL()
	NVAR/Z LigandNumTL = root:LigandNumTL
	NVAR/Z TimeInterval = root:TimeInterval
	NVAR/Z TimePoints = root:TimePoints
	NVAR/Z TimeStimulation = root:TimeStimulation
	
	// 
	if(!NVAR_Exists(TimePoints) || TimePoints < 1)
		DoAlert 0, "TimePoints is not set. Please set Timelapse parameters first."
		return -1
	endif
	
	// root:Comparison
	if(!DataFolderExists("root:Comparison"))
		DoAlert 0, "root:Comparison folder not found.\nPlease run Compare analysis first."
		return -1
	endif
	
	String savedDF = GetDataFolder(1)
	SetDataFolder root:Comparison
	
	// celldata wave
	// : D_S*_*, L_S*_*, HMMP_S*_*, Tau_*_*, Frac_*_*, nLB_S*, Onrate_*_*, IntPop_*_*
	String cellDataList = ""
	String patterns = "D_S*_*;L_S*_*;HMMP_S*_*;Tau*_*_*;Frac*_*_*;nLB_S*;Onrate_*_*;IntPop_*_*;Trans_*_*"
	
	Variable patIdx
	for(patIdx = 0; patIdx < ItemsInList(patterns); patIdx += 1)
		String pattern = StringFromList(patIdx, patterns)
		String foundWaves = WaveList(pattern, ";", "")
		if(strlen(foundWaves) > 0)
			cellDataList += foundWaves
		endif
	endfor
	
	// 
	String cleanList = ""
	String excludePatterns = "*_avg;*_sem;*mean*;*SEM*;*Names*;*Colors*;*StateX*;SampleNames;BarColors"
	
	Variable numWaves = ItemsInList(cellDataList)
	Variable idx
	String wName
	
	for(idx = 0; idx < numWaves; idx += 1)
		wName = StringFromList(idx, cellDataList)
		
		// 
		if(WhichListItem(wName, cleanList) >= 0)
			continue
		endif
		
		// 
		Variable excluded = 0
		Variable exIdx
		for(exIdx = 0; exIdx < ItemsInList(excludePatterns); exIdx += 1)
			if(StringMatch(wName, StringFromList(exIdx, excludePatterns)))
				excluded = 1
				break
			endif
		endfor
		
		if(!excluded)
			Wave/Z testW = $wName
			if(WaveExists(testW) && numpnts(testW) > 0)
				cleanList += wName + ";"
			endif
		endif
	endfor
	
	Variable numCellData = ItemsInList(cleanList)
	if(numCellData == 0)
		DoAlert 0, "No cell data waves found in root:Comparison.\nPlease run Compare analysis first."
		SetDataFolder $savedDF
		return -1
	endif
	
	Print "Found " + num2str(numCellData) + " cell data waves in root:Comparison"
	Print "TimePoints = " + num2str(TimePoints)
	Print "Waves: " + cleanList
	
	// SampleNames
	Wave/T/Z SampleNames
	if(!WaveExists(SampleNames))
		Wave/T/Z SampleNames = root:Comparison:SampleNames
	endif
	
	// Wave
	String normalizedList = ""
	String firstViolinTrace = ""
	
	for(idx = 0; idx < numCellData; idx += 1)
		wName = StringFromList(idx, cleanList)
		Wave/Z srcWave = $wName
		
		if(!WaveExists(srcWave))
			continue
		endif
		
		// t0TimePointswave
		Variable baseIdx = idx - Mod(idx, TimePoints)
		String baseWName = StringFromList(baseIdx, cleanList)
		Wave/Z baseWave = $baseWName
		
		if(!WaveExists(baseWave))
			Print "Warning: Base wave not found for " + wName
			continue
		endif
		
		// wave
		String normWName = "n" + wName
		normalizedList += normWName + ";"
		
		// 
		Variable numPts = numpnts(srcWave)
		Make/O/D/N=(numPts) $normWName
		Wave normWave = $normWName
		
		Variable ptIdx
		for(ptIdx = 0; ptIdx < numPts; ptIdx += 1)
			Variable srcVal = srcWave[ptIdx]
			Variable baseVal = baseWave[ptIdx]
			
			if(numtype(baseVal) == 0 && baseVal != 0)
				normWave[ptIdx] = srcVal / baseVal
			else
				normWave[ptIdx] = NaN
			endif
		endfor
		
		if(strlen(firstViolinTrace) == 0)
			firstViolinTrace = normWName
		endif
	endfor
	
	// 
	if(strlen(normalizedList) > 0)
		Display/K=1
		
		Variable firstViolin = 1
		for(idx = 0; idx < ItemsInList(normalizedList); idx += 1)
			String normName = StringFromList(idx, normalizedList)
			Wave/Z normW = $normName
			
			if(!WaveExists(normW) || numpnts(normW) == 0)
				continue
			endif
			
			if(WaveExists(SampleNames))
				if(firstViolin)
					AppendViolinPlot normW vs SampleNames
					firstViolin = 0
				else
					AddWavesToViolinPlot normW
				endif
			else
				if(firstViolin)
					AppendViolinPlot normW
					firstViolin = 0
				else
					AddWavesToViolinPlot normW
				endif
			endif
		endfor
		
		// Violin Plot
		if(strlen(firstViolinTrace) > 0)
			ModifyViolinPlot trace=$firstViolinTrace, ShowData=0, FillColor=(40000,40000,40000)
			ModifyViolinPlot trace=$firstViolinTrace, MarkerSize=3, MarkerColor=(0,0,0)
			ModifyViolinPlot trace=$firstViolinTrace, ShowData, MeanMarker=16
			ModifyViolinPlot trace=$firstViolinTrace, ShowMean, MeanMarker=26, MeanMarkerSize=5
			ModifyViolinPlot trace=$firstViolinTrace, CloseOutline
		endif
		
		ModifyGraph toMode=2
		ModifyGraph width={Aspect, 1.618}
		ModifyGraph tick=2, mirror=1, fStyle=1, fSize=14, lowTrip=0.0001, font="Arial"
		ModifyGraph tick(bottom)=3
		ModifyGraph tkLblRot(bottom)=45
		Label left "\\Z16\\F'Arial'Normalized Value"
		
		DoWindow/T kwTopWin, "Normalized Violin Plot (t0)"
	endif
	
	SetDataFolder $savedDF
	Print "=== Normalize Violin Plots Complete ==="
	return 0
End

// -----------------------------------------------------------------------------
// DifferenceViolinPlotsTL - Violin plott0
// Summary PlotTimelapse Parameterst0
// root:Comparisoncelldata wave
// -----------------------------------------------------------------------------
Function DifferenceViolinPlotsTL()
	NVAR/Z LigandNumTL = root:LigandNumTL
	NVAR/Z TimeInterval = root:TimeInterval
	NVAR/Z TimePoints = root:TimePoints
	NVAR/Z TimeStimulation = root:TimeStimulation
	
	// 
	if(!NVAR_Exists(TimePoints) || TimePoints < 1)
		DoAlert 0, "TimePoints is not set. Please set Timelapse parameters first."
		return -1
	endif
	
	// root:Comparison
	if(!DataFolderExists("root:Comparison"))
		DoAlert 0, "root:Comparison folder not found.\nPlease run Compare analysis first."
		return -1
	endif
	
	String savedDF = GetDataFolder(1)
	SetDataFolder root:Comparison
	
	// celldata wave
	String cellDataList = ""
	String patterns = "D_S*_*;L_S*_*;HMMP_S*_*;Tau*_*_*;Frac*_*_*;nLB_S*;Onrate_*_*;IntPop_*_*;Trans_*_*"
	
	Variable patIdx
	for(patIdx = 0; patIdx < ItemsInList(patterns); patIdx += 1)
		String pattern = StringFromList(patIdx, patterns)
		String foundWaves = WaveList(pattern, ";", "")
		if(strlen(foundWaves) > 0)
			cellDataList += foundWaves
		endif
	endfor
	
	// 
	String cleanList = ""
	String excludePatterns = "*_avg;*_sem;*mean*;*SEM*;*Names*;*Colors*;*StateX*;SampleNames;BarColors"
	
	Variable numWaves = ItemsInList(cellDataList)
	Variable idx
	String wName
	
	for(idx = 0; idx < numWaves; idx += 1)
		wName = StringFromList(idx, cellDataList)
		
		if(WhichListItem(wName, cleanList) >= 0)
			continue
		endif
		
		Variable excluded = 0
		Variable exIdx
		for(exIdx = 0; exIdx < ItemsInList(excludePatterns); exIdx += 1)
			if(StringMatch(wName, StringFromList(exIdx, excludePatterns)))
				excluded = 1
				break
			endif
		endfor
		
		if(!excluded)
			Wave/Z testW = $wName
			if(WaveExists(testW) && numpnts(testW) > 0)
				cleanList += wName + ";"
			endif
		endif
	endfor
	
	Variable numCellData = ItemsInList(cleanList)
	if(numCellData == 0)
		DoAlert 0, "No cell data waves found in root:Comparison.\nPlease run Compare analysis first."
		SetDataFolder $savedDF
		return -1
	endif
	
	Print "Found " + num2str(numCellData) + " cell data waves in root:Comparison"
	Print "TimePoints = " + num2str(TimePoints)
	
	// SampleNames
	Wave/T/Z SampleNames
	if(!WaveExists(SampleNames))
		Wave/T/Z SampleNames = root:Comparison:SampleNames
	endif
	
	// Wave
	String differenceList = ""
	String firstViolinTrace = ""
	
	for(idx = 0; idx < numCellData; idx += 1)
		wName = StringFromList(idx, cleanList)
		Wave/Z srcWave = $wName
		
		if(!WaveExists(srcWave))
			continue
		endif
		
		// t0
		Variable baseIdx = idx - Mod(idx, TimePoints)
		String baseWName = StringFromList(baseIdx, cleanList)
		Wave/Z baseWave = $baseWName
		
		if(!WaveExists(baseWave))
			Print "Warning: Base wave not found for " + wName
			continue
		endif
		
		// wave
		String difWName = "d" + wName
		differenceList += difWName + ";"
		
		// 
		Variable numPts = numpnts(srcWave)
		Make/O/D/N=(numPts) $difWName
		Wave difWave = $difWName
		
		Variable ptIdx
		for(ptIdx = 0; ptIdx < numPts; ptIdx += 1)
			Variable srcVal = srcWave[ptIdx]
			Variable baseVal = baseWave[ptIdx]
			
			if(numtype(srcVal) == 0 && numtype(baseVal) == 0)
				difWave[ptIdx] = srcVal - baseVal
			else
				difWave[ptIdx] = NaN
			endif
		endfor
		
		if(strlen(firstViolinTrace) == 0)
			firstViolinTrace = difWName
		endif
	endfor
	
	// 
	if(strlen(differenceList) > 0)
		Display/K=1
		
		Variable firstViolin = 1
		for(idx = 0; idx < ItemsInList(differenceList); idx += 1)
			String difName = StringFromList(idx, differenceList)
			Wave/Z difW = $difName
			
			if(!WaveExists(difW) || numpnts(difW) == 0)
				continue
			endif
			
			if(WaveExists(SampleNames))
				if(firstViolin)
					AppendViolinPlot difW vs SampleNames
					firstViolin = 0
				else
					AddWavesToViolinPlot difW
				endif
			else
				if(firstViolin)
					AppendViolinPlot difW
					firstViolin = 0
				else
					AddWavesToViolinPlot difW
				endif
			endif
		endfor
		
		// Violin Plot
		if(strlen(firstViolinTrace) > 0)
			ModifyViolinPlot trace=$firstViolinTrace, ShowData=0, FillColor=(40000,40000,40000)
			ModifyViolinPlot trace=$firstViolinTrace, MarkerSize=3, MarkerColor=(0,0,0)
			ModifyViolinPlot trace=$firstViolinTrace, ShowData, MeanMarker=16
			ModifyViolinPlot trace=$firstViolinTrace, ShowMean, MeanMarker=26, MeanMarkerSize=5
			ModifyViolinPlot trace=$firstViolinTrace, CloseOutline
		endif
		
		ModifyGraph toMode=2
		ModifyGraph width={Aspect, 1.618}
		ModifyGraph tick=2, mirror=1, fStyle=1, fSize=14, lowTrip=0.0001, font="Arial"
		ModifyGraph tick(bottom)=3
		ModifyGraph tkLblRot(bottom)=45
		Label left "\\Z16\\F'Arial'Difference Value"
		
		DoWindow/T kwTopWin, "Difference Violin Plot (from t0)"
	endif
	
	SetDataFolder $savedDF
	Print "=== Difference Violin Plots Complete ==="
	return 0
End

// -----------------------------------------------------------------------------
// ConvertViolinToLinePlotTL - Violin plotLine plot
// Summary PlotTimelapse Parametersmean±sem
// root:Comparisoncelldata wave
// -----------------------------------------------------------------------------
Function ConvertViolinToLinePlotTL()
	NVAR/Z LigandNumTL = root:LigandNumTL
	NVAR/Z TimeInterval = root:TimeInterval
	NVAR/Z TimePoints = root:TimePoints
	NVAR/Z TimeStimulation = root:TimeStimulation
	
	// 
	if(!NVAR_Exists(TimePoints) || TimePoints < 1)
		DoAlert 0, "TimePoints is not set. Please set Timelapse parameters first."
		return -1
	endif
	
	Variable interval = 5  // 
	if(NVAR_Exists(TimeInterval) && TimeInterval > 0)
		interval = TimeInterval
	endif
	
	Variable stimTime = 0
	if(NVAR_Exists(TimeStimulation))
		stimTime = TimeStimulation
	endif
	
	// root:Comparison
	if(!DataFolderExists("root:Comparison"))
		DoAlert 0, "root:Comparison folder not found.\nPlease run Compare analysis first."
		return -1
	endif
	
	String savedDF = GetDataFolder(1)
	SetDataFolder root:Comparison
	
	// celldata wave
	String cellDataList = ""
	String patterns = "D_S*_*;L_S*_*;HMMP_S*_*;Tau*_*_*;Frac*_*_*;nLB_S*;Onrate_*_*;IntPop_*_*;Trans_*_*"
	
	Variable patIdx
	for(patIdx = 0; patIdx < ItemsInList(patterns); patIdx += 1)
		String pattern = StringFromList(patIdx, patterns)
		String foundWaves = WaveList(pattern, ";", "")
		if(strlen(foundWaves) > 0)
			cellDataList += foundWaves
		endif
	endfor
	
	// 
	String cleanList = ""
	String excludePatterns = "*_avg;*_sem;*mean*;*SEM*;*Names*;*Colors*;*StateX*;SampleNames;BarColors"
	
	Variable numWaves = ItemsInList(cellDataList)
	Variable idx
	String wName
	
	for(idx = 0; idx < numWaves; idx += 1)
		wName = StringFromList(idx, cellDataList)
		
		if(WhichListItem(wName, cleanList) >= 0)
			continue
		endif
		
		Variable excluded = 0
		Variable exIdx
		for(exIdx = 0; exIdx < ItemsInList(excludePatterns); exIdx += 1)
			if(StringMatch(wName, StringFromList(exIdx, excludePatterns)))
				excluded = 1
				break
			endif
		endfor
		
		if(!excluded)
			Wave/Z testW = $wName
			if(WaveExists(testW) && numpnts(testW) > 0)
				cleanList += wName + ";"
			endif
		endif
	endfor
	
	Variable numCellData = ItemsInList(cleanList)
	if(numCellData == 0)
		DoAlert 0, "No cell data waves found in root:Comparison.\nPlease run Compare analysis first."
		SetDataFolder $savedDF
		return -1
	endif
	
	Print "Found " + num2str(numCellData) + " cell data waves in root:Comparison"
	Print "TimePoints = " + num2str(TimePoints)
	
	// wave
	String firstWave = StringFromList(0, cleanList)
	String ParameterStr = StringFromList(0, ReplaceString("_", firstWave, ";"))
	
	// wave
	Make/O/D/N=(numCellData) TL_avgList, TL_sdList, TL_semList, TL_nList
	Make/O/T/N=(numCellData) TL_nameList
	
	for(idx = 0; idx < numCellData; idx += 1)
		wName = StringFromList(idx, cleanList)
		Wave/Z dataW = $wName
		
		TL_nameList[idx] = wName
		
		if(WaveExists(dataW) && numpnts(dataW) > 0)
			WaveStats/Q dataW
			TL_avgList[idx] = V_avg
			TL_sdList[idx] = V_sdev
			TL_semList[idx] = V_sem
			TL_nList[idx] = V_npnts
		else
			TL_avgList[idx] = NaN
			TL_sdList[idx] = NaN
			TL_semList[idx] = NaN
			TL_nList[idx] = 0
		endif
	endfor
	
	// 
	Edit/K=1 TL_nameList, TL_avgList, TL_sdList, TL_semList, TL_nList
	DoWindow/T kwTopWin, "Statistics Summary"
	
	// 
	Variable numConditions = numCellData / TimePoints
	if(numConditions < 1)
		numConditions = 1
	endif
	
	// 
	Make/O/D/N=(TimePoints) TL_time_sec = interval * 60 * p - stimTime * 60
	Variable TPstimulation = floor(stimTime / interval)
	if(TPstimulation >= 0 && TPstimulation < TimePoints)
		TL_time_sec[TPstimulation] = 0
	endif
	
	// Line Plot
	Variable condIdx
	Variable firstPlot = 1
	
	for(condIdx = 0; condIdx < numConditions; condIdx += 1)
		String avgName = ParameterStr + "_avg" + num2str(condIdx)
		String sdName = ParameterStr + "_sd" + num2str(condIdx)
		String semName = ParameterStr + "_sem" + num2str(condIdx)
		String nName = ParameterStr + "_n" + num2str(condIdx)
		
		Make/O/D/N=(TimePoints) $avgName, $sdName, $semName, $nName
		Wave avgW = $avgName
		Wave sdW = $sdName
		Wave semW = $semName
		Wave nW = $nName
		
		Variable tpIdx
		for(tpIdx = 0; tpIdx < TimePoints; tpIdx += 1)
			Variable srcIdx = condIdx * TimePoints + tpIdx
			if(srcIdx < numCellData)
				avgW[tpIdx] = TL_avgList[srcIdx]
				sdW[tpIdx] = TL_sdList[srcIdx]
				semW[tpIdx] = TL_semList[srcIdx]
				nW[tpIdx] = TL_nList[srcIdx]
			else
				avgW[tpIdx] = NaN
				sdW[tpIdx] = NaN
				semW[tpIdx] = NaN
				nW[tpIdx] = 0
			endif
		endfor
		
		// 
		String seriesLabel = ""
		Variable labelIdx = condIdx * TimePoints
		if(labelIdx < numCellData)
			String srcWaveName = StringFromList(labelIdx, cleanList)
			// wave: "D_S1_Sample1" -> "Sample1"
			Variable numParts = ItemsInList(srcWaveName, "_")
			if(numParts >= 3)
				seriesLabel = StringFromList(numParts - 1, srcWaveName, "_")
			else
				seriesLabel = "Cond" + num2str(condIdx + 1)
			endif
		else
			seriesLabel = "Cond" + num2str(condIdx + 1)
		endif
		
		// 
		Edit/K=1 TL_time_sec, $avgName, $sdName, $semName, $nName
		DoWindow/T kwTopWin, "Time Course: " + seriesLabel
		
		// Line Plot
		if(firstPlot)
			Display/K=1 avgW vs TL_time_sec
			ErrorBars $avgName SHADE={0,0,(0,0,0,0),(0,0,0,0)}, wave=(semW, semW)
			ModifyGraph mode=4, marker=19, mrkThick=1.5
			
			Label left ParameterStr
			Label bottom "time (s)"
			ModifyGraph tick=0, mirror=0
			ModifyGraph lowTrip(left)=0.0001
			ModifyGraph axisEnab(left)={0.05,1}, axisEnab(bottom)={0.05,1}
			ModifyGraph fStyle=1, fSize=16, font="Arial"
			
			SetAxis left *, *
			ModifyGraph width={Aspect, 1.618}
			
			TextBox/C/N=text0/B=1/F=0/A=MC "\\F'Arial'\\Z14\\s(" + avgName + ")" + seriesLabel
			
			firstPlot = 0
		else
			// 
			Variable colorR = 60000 * (1 - condIdx/numConditions)
			Variable colorG = 10000 + 50000 * condIdx/numConditions
			Variable colorB = 10000 + 50000 * condIdx/numConditions
			
			AppendToGraph/C=(colorR, colorG, colorB) avgW vs TL_time_sec
			ErrorBars $avgName SHADE={0,4,(0,0,0,0),(0,0,0,0),4,(0,0,0,0),(0,0,0,0)}, wave=(semW, semW)
			
			ModifyGraph mode($avgName)=4, marker($avgName)=19, mrkThick($avgName)=1.5
			AppendText "\\s(" + avgName + ")" + seriesLabel
		endif
	endfor
	
	DoWindow/T kwTopWin, "Time Course: " + ParameterStr
	
	SetDataFolder $savedDF
	Print "=== Convert Violin to Line Plot Complete ==="
	return 0
End

// -----------------------------------------------------------------------------
// DensityIntHistToImageTL - Density×Intensity
// Timelapse Parameters
// -----------------------------------------------------------------------------
Function DensityIntHistToImageTL()
	SetDataFolder root:Comparison
	String OriginalWaveListStr = ""
	
	SVAR/Z Color0 = root:Color0
	SVAR/Z Color1 = root:Color1
	SVAR/Z Color2 = root:Color2
	SVAR/Z Color3 = root:Color3
	SVAR/Z Color4 = root:Color4
	SVAR/Z Color5 = root:Color5
	
	NVAR/Z txt = root:DIhistTxt
	NVAR Imin = root:DIhistImageMin
	NVAR Imax = root:DIhistImageMax

	NVAR/Z LigandNumTL = root:LigandNumTL
	NVAR/Z TimeInterval = root:TimeInterval
	NVAR/Z TimePoints = root:TimePoints
	NVAR/Z TimeStimulation = root:TimeStimulation

	NVAR Dstate = root:Dstate
	NVAR HistBin = root:IhistBin
	NVAR HistDim = root:IhistDim

	Variable PixX = 164
	Variable PixY = 100

	//
	Variable showText = 1
	if(NVAR_Exists(txt))
		showText = txt
	endif

	Variable imgMin = Imin
	Variable imgMax = Imax

	// TopGraphWave
	OriginalWaveListStr = WaveList("!*sem", ";", "WIN:")

	Variable Entropy = StringMatch(OriginalWaveListStr, "*Entropy*")
	
	Variable Maxi = ItemsInList(OriginalWaveListStr)
	Variable Maxc = Maxi / (Dstate + 1) / TimePoints
	
	Variable stateIdx, condIdx, timeIdx, waveIdx
	Variable ImageNumber = -1
	
	NewLayout/N=LayoutImageDensityHist/K=1
	
	for(condIdx = 0; condIdx < Maxc; condIdx += 1)
		for(stateIdx = Dstate; stateIdx >= 0; stateIdx -= 1)
			Make/O/N=(HistDim, TimePoints) MatrixNameWave
			
			if(showText == 1)
				SetScale/P x, 0.5*HistBin, HistBin, "Intensity", MatrixNameWave
				SetScale/I y, 0, (TimePoints-1)*TimeInterval, "time (min)", MatrixNameWave
			else
				SetScale/P x, 0.5*HistBin, HistBin, "", MatrixNameWave
				SetScale/I y, 0, TimePoints-1, "", MatrixNameWave
			endif
			
			for(timeIdx = 0; timeIdx < TimePoints; timeIdx += 1)
				waveIdx = condIdx * (Dstate + 1) * TimePoints + stateIdx + timeIdx * (Dstate + 1)
				
				String CurrentWName = StringFromList(waveIdx, OriginalWaveListStr)
				if(timeIdx == 0)
					String MName = "Image_S" + num2str(Dstate - stateIdx) + "_" + CurrentWName
				endif
				
				Wave/Z Data = $CurrentWName
				if(WaveExists(Data))
					MatrixNameWave[][timeIdx] = Data[p]
				endif
			endfor
			
			Duplicate/O MatrixNameWave, $MName
			
			String ImageName = "ImageHistIntDensity" + num2str(ImageNumber)
			
			Display/K=1/N=ImageHistIntDensity
			ModifyGraph width=PixX, height=PixY
			AppendImage $MName
			
			// 
			String ctabName = "Grays"
			if(SVAR_Exists(Color0))
				ctabName = Color0
			endif
			
			if(Entropy == 0)
				ModifyImage $MName ctab={imgMin, imgMax, $ctabName, 0}, log=1
			else
				ModifyImage $MName ctab={imgMin, imgMax, $ctabName, 0}, log=0
			endif
			
			SetAxis/R left *, *
			
			if(showText == 1)
				TextBox/C/N=text0/F=0/B=1/A=MT/E=2/Y=0.00 "\\F'Arial'\\Z08" + MName
				ModifyGraph tick=0, mirror=0, axisEnab(left)={0.05,1}, axisEnab(bottom)={0.05,1}
				ModifyGraph lblLatPos=0, fStyle=1, fSize=16, font="Arial"
			else
				ModifyGraph tick=3, mirror=0, noLabel=2, axRGB=(65535,65535,65535,0), margin=1
			endif
			
			// 
			if(Dstate - stateIdx == 1 && SVAR_Exists(Color1))
				ModifyImage $MName ctab={imgMin, imgMax, $Color1, 0}
			elseif(Dstate - stateIdx == 2 && SVAR_Exists(Color2))
				ModifyImage $MName ctab={imgMin, imgMax, $Color2, 0}
			elseif(Dstate - stateIdx == 3 && SVAR_Exists(Color3))
				ModifyImage $MName ctab={imgMin, imgMax, $Color3, 0}
			elseif(Dstate - stateIdx == 4 && SVAR_Exists(Color4))
				ModifyImage $MName ctab={imgMin, imgMax, $Color4, 0}
			elseif(Dstate - stateIdx == 5 && SVAR_Exists(Color5))
				ModifyImage $MName ctab={imgMin, imgMax, $Color5, 0}
			endif
			
			if(ImageNumber == -1)
				AppendLayoutObject/T=0/F=0 graph ImageHistIntDensity
			else
				AppendLayoutObject/T=0/F=0 graph $ImageName
			endif
			
			ImageNumber += 1
		endfor
	endfor
	
	// 
	Execute "Tile/G=" + num2str(Dstate+1) + "/A=(" + num2str(Maxc) + "," + num2str(Dstate+1) + ")/O=0"
	
	if(showText == 1)
		LayoutPageAction size(-1)=(PixX*(Dstate+4), PixY*(Maxc+5)), margins(-1)=(20, 20, 20, 20)
	else
		LayoutPageAction size(-1)=(PixX*(Dstate+2), PixY*(Maxc+2)), margins(-1)=(20, 20, 20, 20)
	endif
	
	KillWaves/Z MatrixNameWave
	SetDataFolder root:
	Print "=== DxI Histogram to Image Complete ==="
End

// -----------------------------------------------------------------------------
// TL_CreateDxIImage - Int_S*_Phist_xDensityTimelapse Image Plot
// TL_SampleListDensity×Intensity
// Layout
// -----------------------------------------------------------------------------
Function TL_CreateDxIImage()
	String savedDF = GetDataFolder(1)
	SetDataFolder root:Comparison
	
	// 
	NVAR/Z Dstate = root:Dstate
	NVAR IHistBin = root:IhistBin
	NVAR IHistDim = root:IhistDim
	NVAR/Z TimeInterval = root:TimeInterval
	NVAR/Z TimePoints = root:TimePoints
	NVAR Imin = root:DIhistImageMin
	NVAR Imax = root:DIhistImageMax
	NVAR/Z noLabel = root:LayoutNoLabel
	
	// 
	SVAR/Z Color0 = root:Color0
	SVAR/Z Color1 = root:Color1
	SVAR/Z Color2 = root:Color2
	SVAR/Z Color3 = root:Color3
	SVAR/Z Color4 = root:Color4
	SVAR/Z Color5 = root:Color5
	
	// 
	Variable numConditions, numTimePoints, numStates
	Variable HistBin, HistDim, interval, hideLabel, imgMin, imgMax
	Variable PixX, PixY, condIdx, stateIdx, tpIdx, i
	Variable npts, stateForColor, graphCount
	String MName, sampleName, winName
	String folderPath, densHistName, fullPath, ctabName
	
	// TL_SampleList
	Wave/T/Z TL_SampleList
	if(!WaveExists(TL_SampleList))
		DoAlert 0, "TL_SampleList not found.\nPlease run 'Create Sample List' first."
		SetDataFolder $savedDF
		return -1
	endif
	
	numConditions = DimSize(TL_SampleList, 0)
	numTimePoints = DimSize(TL_SampleList, 1)
	
	// Dstate
	numStates = 2
	if(NVAR_Exists(Dstate))
		numStates = Dstate + 1
	endif
	
	//
	HistBin = IHistBin
	HistDim = IHistDim
	
	// 
	interval = 10
	if(NVAR_Exists(TimeInterval))
		interval = TimeInterval
	endif
	
	// 
	hideLabel = 0
	if(NVAR_Exists(noLabel))
		hideLabel = noLabel
	endif
	imgMin = Imin
	imgMax = Imax
	
	// 
	PixX = 164
	PixY = 100
	
	Print "=== TL Mol Density Image Creation ==="
	Print "Conditions: " + num2str(numConditions) + ", TimePoints: " + num2str(numTimePoints)
	Print "States: " + num2str(numStates)
	Print "Image range: " + num2str(imgMin) + " - " + num2str(imgMax)
	
	// Graph
	for(i = 0; i < 100; i += 1)
		winName = "MolDensImg_" + num2str(i)
		DoWindow/K $winName
	endfor
	
	graphCount = 0
	
	// Image Plot
	for(condIdx = 0; condIdx < numConditions; condIdx += 1)
		for(stateIdx = numStates-1; stateIdx >= 0; stateIdx -= 1)
			// Matrix=Intensity bin, =time point
			Make/O/N=(HistDim, numTimePoints) MatrixNameWave = 0
			
			// 
			if(hideLabel == 0)
				SetScale/P x, 0.5*HistBin, HistBin, "Intensity", MatrixNameWave
				SetScale/I y, 0, (numTimePoints-1)*interval, "time (min)", MatrixNameWave
			else
				SetScale/P x, 0.5*HistBin, HistBin, "", MatrixNameWave
				SetScale/I y, 0, numTimePoints-1, "", MatrixNameWave
			endif
			
			// 
			MName = ""
			for(tpIdx = 0; tpIdx < numTimePoints; tpIdx += 1)
				sampleName = TL_SampleList[condIdx][tpIdx]
				if(strlen(sampleName) == 0)
					continue
				endif
				
				// Matrix
				if(tpIdx == 0)
					stateForColor = numStates - 1 - stateIdx
					MName = "Image_S" + num2str(stateForColor) + "_C" + num2str(condIdx+1) + "_" + sampleName
				endif
				
				// Resultswave
				folderPath = "root:" + sampleName + ":Results:"
				densHistName = "Int_S" + num2str(stateIdx) + "_Phist_xDensity_m_avg"
				fullPath = folderPath + densHistName
				
				Wave/Z DensHist = $fullPath
				if(WaveExists(DensHist))
					npts = min(numpnts(DensHist), HistDim)
					MatrixNameWave[0, npts-1][tpIdx] = DensHist[p]
				else
					if(tpIdx == 0)
						Print "  WARNING: " + fullPath + " not found"
					endif
				endif
			endfor
			
			// Matrix
			Duplicate/O MatrixNameWave, $MName
			
			// Graph
			winName = "MolDensImg_" + num2str(graphCount)
			Display/K=1/N=$winName
			ModifyGraph width=PixX, height=PixY
			AppendImage $MName
			
			// 
			ctabName = "Grays"
			if(SVAR_Exists(Color0))
				ctabName = Color0
			endif
			ModifyImage $MName ctab={imgMin, imgMax, $ctabName, 0}, log=1
			
			SetAxis/R left *, *
			
			// 
			if(hideLabel == 0)
				TextBox/C/N=text0/F=0/B=1/A=MT/E=2/Y=0.00 "\\F'Arial'\\Z08" + MName
				ModifyGraph tick=0, mirror=0, axisEnab(left)={0.05,1}, axisEnab(bottom)={0.05,1}
				ModifyGraph lblLatPos=0, fStyle=1, fSize=16, font="Arial"
			else
				ModifyGraph tick=3, mirror=0, noLabel=2, axRGB=(65535,65535,65535,0), margin=1
			endif
			
			// 
			stateForColor = numStates - 1 - stateIdx
			if(stateForColor == 1 && SVAR_Exists(Color1))
				ModifyImage $MName ctab={imgMin, imgMax, $Color1, 0}
			elseif(stateForColor == 2 && SVAR_Exists(Color2))
				ModifyImage $MName ctab={imgMin, imgMax, $Color2, 0}
			elseif(stateForColor == 3 && SVAR_Exists(Color3))
				ModifyImage $MName ctab={imgMin, imgMax, $Color3, 0}
			elseif(stateForColor == 4 && SVAR_Exists(Color4))
				ModifyImage $MName ctab={imgMin, imgMax, $Color4, 0}
			elseif(stateForColor == 5 && SVAR_Exists(Color5))
				ModifyImage $MName ctab={imgMin, imgMax, $Color5, 0}
			endif
			
			graphCount += 1
		endfor
	endfor
	
	KillWaves/Z MatrixNameWave
	SetDataFolder $savedDF
	Print "=== TL Mol Density Image Creation Complete ==="
	Print "Created " + num2str(graphCount) + " image plots"
	return 0
End

// -----------------------------------------------------------------------------
// TL_CreateMolDensLayout - MolDensImg_*
// CreateAutoLayoutWithList + ColorScale + 
// -----------------------------------------------------------------------------
Function TL_CreateMolDensLayout(pageW_inch, pageH_inch, offset_mm, gap_mm, divW, divH, outputMode)
	Variable pageW_inch, pageH_inch, offset_mm, gap_mm, divW, divH, outputMode
	
	// MolDensImg_*
	String graphList = SortList(WinList("MolDensImg_*", ";", "WIN:1"), ";", 16)
	Variable numGraphs = ItemsInList(graphList)
	
	if(numGraphs == 0)
		DoAlert 0, "No MolDensImg_* graph windows found.\nRun 'Mol Density Image' first."
		return -1
	endif
	
	// CreateAutoLayoutWithList
	Variable numPages = CreateAutoLayoutWithList("MolDensImg", pageW_inch, pageH_inch, offset_mm, gap_mm, divW, divH, outputMode, graphList)
	
	// Layout
	String layoutList = WinList("Layout_MolDensImg*", ";", "WIN:4")
	if(strlen(layoutList) > 0)
		String layoutName = StringFromList(0, layoutList)
		
		// Molecular Density Image - Page n
		TL_UpdateMolDensPageTitles(layoutName, numPages)
		
		// ColorScale
		TL_AddColorScalesToLayout(layoutName, numPages, pageW_inch, pageH_inch, offset_mm)
	endif
	
	return numPages
End

// -----------------------------------------------------------------------------
// Molecular Density Image - Page n
// -----------------------------------------------------------------------------
Function TL_UpdateMolDensPageTitles(layoutName, numPages)
	String layoutName
	Variable numPages
	
	Variable pageIdx
	String cmd, newTitle
	
	for(pageIdx = 0; pageIdx < numPages; pageIdx += 1)
		// 
		if(pageIdx > 0)
			sprintf cmd, "LayoutPageAction/W=%s page=(%d)", layoutName, pageIdx + 1
			Execute cmd
		endif
		
		// PageTitle_*
		sprintf cmd, "TextBox/W=%s/K/N=PageTitle_%d", layoutName, pageIdx + 1
		Execute/Z cmd
		
		// 
		sprintf newTitle, "Molecular Density Image - Page %d", pageIdx + 1
		sprintf cmd, "TextBox/W=%s/C/N=MolDensTitle_%d/F=0/B=1/A=LT/X=0/Y=0 \"\\\\Z12\\\\f01%s\"", layoutName, pageIdx + 1, newTitle
		Execute cmd
	endfor
	
	// 
	sprintf cmd, "LayoutPageAction/W=%s page=(1)", layoutName
	Execute cmd
End

// -----------------------------------------------------------------------------
// LayoutColorScale
// -----------------------------------------------------------------------------
Function TL_AddColorScalesToLayout(layoutName, numPages, pageW_inch, pageH_inch, offset_mm)
	String layoutName
	Variable numPages, pageW_inch, pageH_inch, offset_mm
	
	// 
	NVAR Imin = root:DIhistImageMin
	NVAR Imax = root:DIhistImageMax
	NVAR/Z Dstate = root:Dstate
	NVAR/Z scaleFontSize = root:LayoutScaleFontSize
	SVAR/Z Color0 = root:Color0
	SVAR/Z Color1 = root:Color1
	SVAR/Z Color2 = root:Color2
	SVAR/Z Color3 = root:Color3
	SVAR/Z Color4 = root:Color4
	SVAR/Z Color5 = root:Color5
	
	// 
	Variable kPtPerInch = 72
	Variable kMmPerInch = 25.4
	Variable kColorScaleMargin = 40  // ColorScale
	
	// 
	Variable imgMin, imgMax, numStates, fontSize
	Variable offset_pt, pageW_pt, pageH_pt
	Variable contentW, csHeight, csWidth, totalScaleW, scaleSpacing
	Variable pageIdx, stateIdx, csLeft, csTop
	String cmd, csName, csColor

	//
	imgMin = Imin
	imgMax = Imax
	
	numStates = 2
	if(NVAR_Exists(Dstate))
		numStates = Dstate + 1
	endif
	
	fontSize = 14
	if(NVAR_Exists(scaleFontSize))
		fontSize = scaleFontSize
	endif
	
	// 
	offset_pt = offset_mm / kMmPerInch * kPtPerInch
	pageW_pt = pageW_inch * kPtPerInch
	pageH_pt = pageH_inch * kPtPerInch
	
	// ColorScale
	// : width=125pt, height=15pt
	csWidth = 125
	csHeight = 25  // +
	
	// 
	contentW = pageW_pt - 2 * offset_pt
	totalScaleW = numStates * csWidth + (numStates - 1) * 10
	scaleSpacing = csWidth + 10
	
	// 
	csLeft = offset_pt + (contentW - totalScaleW) / 2
	csTop = pageH_pt - offset_pt - kColorScaleMargin + 5
	
	// ColorScale
	for(pageIdx = 0; pageIdx < numPages; pageIdx += 1)
		// 
		if(pageIdx > 0)
			sprintf cmd, "LayoutPageAction/W=%s page=(%d)", layoutName, pageIdx + 1
			Execute cmd
		endif
		
		// ColorScale
		for(stateIdx = 0; stateIdx < numStates; stateIdx += 1)
			csName = "CS_P" + num2str(pageIdx) + "_S" + num2str(stateIdx)
			
			// 
			if(stateIdx == 0)
				csColor = "Grays"
				if(SVAR_Exists(Color0))
					csColor = Color0
				endif
			elseif(stateIdx == 1 && SVAR_Exists(Color1))
				csColor = Color1
			elseif(stateIdx == 2 && SVAR_Exists(Color2))
				csColor = Color2
			elseif(stateIdx == 3 && SVAR_Exists(Color3))
				csColor = Color3
			elseif(stateIdx == 4 && SVAR_Exists(Color4))
				csColor = Color4
			elseif(stateIdx == 5 && SVAR_Exists(Color5))
				csColor = Color5
			else
				csColor = "Grays"
			endif
			
			// ColorScalefsize=width=
			sprintf cmd, "ColorScale/W=%s/C/N=%s/F=0/B=1/G=(0,0,0) vert=0, width=100, fsize=%d, ctab={%g,%g,$\"%s\",0}, log=1, \"\\\\Z%02dS%d\"", layoutName, csName, fontSize, imgMin, imgMax, csColor, fontSize, stateIdx
			Execute/Q cmd
			
			// AppendAndResizeGraph
			sprintf cmd, "ModifyLayout/W=%s left(%s)=%d, top(%s)=%d, width(%s)=%d, height(%s)=%d", layoutName, csName, round(csLeft + stateIdx * scaleSpacing), csName, round(csTop), csName, round(csWidth), csName, round(csHeight)
			Execute cmd
		endfor
	endfor
	
	// 
	sprintf cmd, "LayoutPageAction/W=%s page=(1)", layoutName
	Execute cmd
End

// -----------------------------------------------------------------------------
// DensityIntHistToImageInfoTL - Information
// -p*log(p)Information density
// -----------------------------------------------------------------------------
Function DensityIntHistToImageInfoTL()
	SetDataFolder root:Comparison
	String OriginalWaveListStr = ""
	
	SVAR/Z Color0 = root:Color0
	SVAR/Z Color1 = root:Color1
	SVAR/Z Color2 = root:Color2
	SVAR/Z Color3 = root:Color3
	SVAR/Z Color4 = root:Color4
	SVAR/Z Color5 = root:Color5
	
	NVAR/Z txt = root:DIhistTxt
	NVAR Imin = root:DIhistImageMin
	NVAR Imax = root:DIhistImageMax

	NVAR/Z LigandNumTL = root:LigandNumTL
	NVAR/Z TimeInterval = root:TimeInterval
	NVAR/Z TimePoints = root:TimePoints
	NVAR/Z TimeStimulation = root:TimeStimulation

	NVAR Dstate = root:Dstate
	NVAR HistBin = root:IhistBin
	NVAR HistDim = root:IhistDim

	Variable PixX = 164
	Variable PixY = 100

	//
	Variable showText = 1
	if(NVAR_Exists(txt))
		showText = txt
	endif

	Variable imgMin = Imin
	Variable imgMax = Imax
	
	// TopGraphWave
	OriginalWaveListStr = WaveList("!*sem", ";", "WIN:")
	
	Variable Maxi = ItemsInList(OriginalWaveListStr)
	Variable Maxc = Maxi / (Dstate + 1) / TimePoints
	
	Variable stateIdx, condIdx, timeIdx, waveIdx
	Variable ImageNumber = -1
	
	NewLayout/N=LayoutImageDensityInfo/K=1
	
	for(condIdx = 0; condIdx < Maxc; condIdx += 1)
		for(stateIdx = Dstate; stateIdx >= 0; stateIdx -= 1)
			Make/O/N=(HistDim, TimePoints) MatrixNameWave
			
			if(showText == 1)
				SetScale/P x, 0.5*HistBin, HistBin, "Intensity", MatrixNameWave
				SetScale/I y, 0, (TimePoints-1)*TimeInterval, "time (min)", MatrixNameWave
			else
				SetScale/P x, 0.5*HistBin, HistBin, "", MatrixNameWave
				SetScale/I y, 0, TimePoints-1, "", MatrixNameWave
			endif
			
			for(timeIdx = 0; timeIdx < TimePoints; timeIdx += 1)
				waveIdx = condIdx * (Dstate + 1) * TimePoints + stateIdx + timeIdx * (Dstate + 1)
				
				String CurrentWName = StringFromList(waveIdx, OriginalWaveListStr)
				if(timeIdx == 0)
					String MName = "InfoImage_S" + num2str(Dstate - stateIdx) + "_" + CurrentWName
				endif
				
				Wave/Z Data = $CurrentWName
				if(WaveExists(Data))
					// Information density: -p*log(p)
					MatrixNameWave[][timeIdx] = -(Data[p] + 1e-10) * log(Data[p] + 1e-10)
				endif
			endfor
			
			Duplicate/O MatrixNameWave, $MName
			
			String ImageName = "ImageHistDensityInfo" + num2str(ImageNumber)
			
			Display/K=1/N=ImageHistDensityInfo
			ModifyGraph width=PixX, height=PixY
			AppendImage $MName
			
			// 
			String ctabName = "Grays"
			if(SVAR_Exists(Color0))
				ctabName = Color0
			endif
			
			ModifyImage $MName ctab={imgMin, imgMax, $ctabName, 0}
			
			SetAxis/R left *, *
			
			if(showText == 1)
				TextBox/C/N=text0/F=0/B=1/A=MT/E=2/Y=0.00 "\\F'Arial'\\Z08" + MName
				ModifyGraph tick=0, mirror=0, axisEnab(left)={0.05,1}, axisEnab(bottom)={0.05,1}
				ModifyGraph lblLatPos=0, fStyle=1, fSize=16, font="Arial"
			else
				ModifyGraph tick=3, mirror=0, noLabel=2, axRGB=(65535,65535,65535,0), margin=1
			endif
			
			// 
			if(Dstate - stateIdx == 1 && SVAR_Exists(Color1))
				ModifyImage $MName ctab={imgMin, imgMax, $Color1, 0}
			elseif(Dstate - stateIdx == 2 && SVAR_Exists(Color2))
				ModifyImage $MName ctab={imgMin, imgMax, $Color2, 0}
			elseif(Dstate - stateIdx == 3 && SVAR_Exists(Color3))
				ModifyImage $MName ctab={imgMin, imgMax, $Color3, 0}
			elseif(Dstate - stateIdx == 4 && SVAR_Exists(Color4))
				ModifyImage $MName ctab={imgMin, imgMax, $Color4, 0}
			elseif(Dstate - stateIdx == 5 && SVAR_Exists(Color5))
				ModifyImage $MName ctab={imgMin, imgMax, $Color5, 0}
			endif
			
			if(ImageNumber == -1)
				AppendLayoutObject/T=0/F=0 graph ImageHistDensityInfo
			else
				AppendLayoutObject/T=0/F=0 graph $ImageName
			endif
			
			ImageNumber += 1
		endfor
	endfor
	
	// 
	Execute "Tile/G=" + num2str(Dstate+1) + "/A=(" + num2str(Maxc) + "," + num2str(Dstate+1) + ")/O=0"
	
	if(showText == 1)
		LayoutPageAction size(-1)=(PixX*(Dstate+4), PixY*(Maxc+3)), margins(-1)=(20, 20, 20, 20)
	else
		LayoutPageAction size(-1)=(PixX*(Dstate+2), PixY*(Maxc+2)), margins(-1)=(20, 20, 20, 20)
	endif
	
	KillWaves/Z MatrixNameWave
	SetDataFolder root:
	Print "=== Info Density Image Complete ==="
End

// =============================================================================
// Timelapse Normalized Compare All Functions
// =============================================================================

// -----------------------------------------------------------------------------
// TL_CreateSampleList - 2D Sample List
// X: timepoint (columns), Y: conditions (rows)
// Load
// ColocalizationList_C1/List_C2
// Both2TL_SampleList_C1, TL_SampleList_C2
// -----------------------------------------------------------------------------
Function TL_CreateSampleList()
	NVAR/Z TimePoints = root:TimePoints
	NVAR/Z LigandNumTL = root:LigandNumTL
	NVAR TimeInterval = root:TimeInterval

	//
	if(!NVAR_Exists(TimePoints) || TimePoints < 1)
		DoAlert 0, "TimePoints is not set. Please set Timelapse parameters first."
		return -1
	endif

	Variable numConditions = 1
	if(NVAR_Exists(LigandNumTL) && LigandNumTL > 0)
		numConditions = LigandNumTL
	endif

	//
	Variable isColMode, chMode, channelIdx, numSamples, expectedSamples
	Variable condIdx, tpIdx, sampleIdx, numFolders, idx, interval
	String currentDF, sampleList, chName, folderName, colLabel, rowLabel

	currentDF = GetDataFolder(1)
	interval = TimeInterval
	
	// Colocalization
	isColMode = TL_IsColocalizationMode()
	
	if(isColMode)
		// Colocalization: List_C1/List_C2
		// ColOutputChannel0=Both, 1=C1, 2=C2
		NVAR/Z ColOutputChannel = root:ColOutputChannel
		chMode = NVAR_Exists(ColOutputChannel) ? ColOutputChannel : 0
		
		if(chMode == 0)
			// Both: 2
			Print "Creating TL_SampleList for Both channels (C1 and C2)"
			TL_CreateSampleListForChannelEx(0, "TL_SampleList_C1", numConditions, TimePoints)
			TL_CreateSampleListForChannelEx(1, "TL_SampleList_C2", numConditions, TimePoints)
			
			// Also create TL_SampleList as copy of C1 for compatibility with analysis functions
			SetDataFolder root:Comparison
			Wave/T/Z TL_SampleList_C1
			if(WaveExists(TL_SampleList_C1))
				Duplicate/O/T TL_SampleList_C1, TL_SampleList
			endif
			SetDataFolder $currentDF
			
			// 
			DoWindow/K TL_SampleListTable_C1
			Edit/K=1/N=TL_SampleListTable_C1 root:Comparison:TL_SampleList_C1.ld
			DoWindow/T TL_SampleListTable_C1, "Timelapse Sample List - Channel 1 (Rows=Ligands, Cols=TimePoints)"
			
			DoWindow/K TL_SampleListTable_C2
			Edit/K=1/N=TL_SampleListTable_C2 root:Comparison:TL_SampleList_C2.ld
			DoWindow/T TL_SampleListTable_C2, "Timelapse Sample List - Channel 2 (Rows=Ligands, Cols=TimePoints)"
			
			// 
			MoveWindow/W=TL_SampleListTable_C1 10, 50, 400, 250
			MoveWindow/W=TL_SampleListTable_C2 10, 280, 400, 480
			
			Print "=== Timelapse Sample Lists Created (Both Channels) ==="
			Print "Ligands: " + num2str(numConditions)
			Print "TimePoints: " + num2str(TimePoints)
			Print ""
			Print "Please verify the sample order in BOTH tables."
			Print "Edit TL_SampleList_C1 and TL_SampleList_C2 if necessary."
			Print "Note: TL_SampleList (copy of C1) is also created for analysis functions."
		else
			// C1 or C2: 1
			channelIdx = (chMode == 2) ? 1 : 0
			chName = SelectString(channelIdx, "C1", "C2")
			
			sampleList = GetSampleListForChannel(channelIdx)
			
			if(strlen(sampleList) == 0)
				DoAlert 0, "No samples found in List_" + chName + ". Please set up Colocalization List first."
				return -1
			endif
			
			Print "Creating TL_SampleList from Colocalization List_" + chName
			
			numSamples = ItemsInList(sampleList)
			expectedSamples = numConditions * TimePoints
			if(numSamples != expectedSamples)
				Printf "Warning: Found %d samples, but expected %d (Ligands=%d × TimePoints=%d)\r", numSamples, expectedSamples, numConditions, TimePoints
			endif
			
			// root:Comparison2D Text Wave
			NewDataFolder/O root:Comparison
			SetDataFolder root:Comparison
			
			Make/O/T/N=(numConditions, TimePoints) TL_SampleList
			
			sampleIdx = 0
			for(condIdx = 0; condIdx < numConditions; condIdx += 1)
				for(tpIdx = 0; tpIdx < TimePoints; tpIdx += 1)
					if(sampleIdx < numSamples)
						TL_SampleList[condIdx][tpIdx] = StringFromList(sampleIdx, sampleList)
					else
						TL_SampleList[condIdx][tpIdx] = ""
					endif
					sampleIdx += 1
				endfor
			endfor
			
			// 
			for(tpIdx = 0; tpIdx < TimePoints; tpIdx += 1)
				colLabel = "t" + num2str(tpIdx * interval) + "min"
				SetDimLabel 1, tpIdx, $colLabel, TL_SampleList
			endfor
			
			for(condIdx = 0; condIdx < numConditions; condIdx += 1)
				rowLabel = "L" + num2str(condIdx + 1)
				SetDimLabel 0, condIdx, $rowLabel, TL_SampleList
			endfor
			
			// 
			DoWindow/K TL_SampleListTable
			Edit/K=1/N=TL_SampleListTable TL_SampleList.ld
			DoWindow/T TL_SampleListTable, "Timelapse Sample List - " + chName + " (Rows=Ligands, Cols=TimePoints)"
			
			Print "=== Timelapse Sample List Created ==="
			Print "Channel: " + chName
			Print "Ligands: " + num2str(numConditions)
			Print "TimePoints: " + num2str(TimePoints)
			Print "TimeInterval: " + num2str(interval) + " min"
			
			SetDataFolder root:
		endif
	else
		// Single Channel: root
		sampleList = ""
		SetDataFolder root:
		
		numFolders = CountObjects(":", 4)
		
		for(idx = 0; idx < numFolders; idx += 1)
			folderName = GetIndexedObjName(":", 4, idx)
			// 
			if(StringMatch(folderName, "Packages") || StringMatch(folderName, "Comparison"))
				continue
			endif
			if(StringMatch(folderName, "WMAnalysisHelper") || StringMatch(folderName, "Results"))
				continue
			endif
			sampleList += folderName + ";"
		endfor
		
		SetDataFolder $currentDF
		
		numSamples = ItemsInList(sampleList)
		if(numSamples == 0)
			DoAlert 0, "No sample folders found. Please load data first."
			return -1
		endif
		
		expectedSamples = numConditions * TimePoints
		if(numSamples != expectedSamples)
			Printf "Warning: Found %d samples, but expected %d (Ligands=%d × TimePoints=%d)\r", numSamples, expectedSamples, numConditions, TimePoints
		endif
		
		// root:Comparison2D Text Wave
		NewDataFolder/O root:Comparison
		SetDataFolder root:Comparison
		
		Make/O/T/N=(numConditions, TimePoints) TL_SampleList
		
		sampleIdx = 0
		for(condIdx = 0; condIdx < numConditions; condIdx += 1)
			for(tpIdx = 0; tpIdx < TimePoints; tpIdx += 1)
				if(sampleIdx < numSamples)
					TL_SampleList[condIdx][tpIdx] = StringFromList(sampleIdx, sampleList)
				else
					TL_SampleList[condIdx][tpIdx] = ""
				endif
				sampleIdx += 1
			endfor
		endfor
		
		// 
		for(tpIdx = 0; tpIdx < TimePoints; tpIdx += 1)
			colLabel = "t" + num2str(tpIdx * interval) + "min"
			SetDimLabel 1, tpIdx, $colLabel, TL_SampleList
		endfor
		
		for(condIdx = 0; condIdx < numConditions; condIdx += 1)
			rowLabel = "L" + num2str(condIdx + 1)
			SetDimLabel 0, condIdx, $rowLabel, TL_SampleList
		endfor
		
		// 
		DoWindow/K TL_SampleListTable
		Edit/K=1/N=TL_SampleListTable TL_SampleList.ld
		DoWindow/T TL_SampleListTable, "Timelapse Sample List (Rows=Ligands, Cols=TimePoints)"
		
		Print "=== Timelapse Sample List Created ==="
		Print "Ligands: " + num2str(numConditions)
		Print "TimePoints: " + num2str(TimePoints)
		Print "TimeInterval: " + num2str(interval) + " min"
		Print "Data Source: Single Channel"
		
		SetDataFolder root:
	endif
	
	Print ""
	Print "Edit sample list(s) if necessary, then run Compare functions."
	
	return 0
End

// -----------------------------------------------------------------------------
// TL_CreateSampleListForChannelEx - TL_SampleList
// channelIdx: 0=C1, 1=C2
// listName: wave
// -----------------------------------------------------------------------------
Function TL_CreateSampleListForChannelEx(channelIdx, listName, numConditions, numTimePoints)
	Variable channelIdx
	String listName
	Variable numConditions, numTimePoints
	
	String sampleList = GetSampleListForChannel(channelIdx)
	
	if(strlen(sampleList) == 0)
		String chName = SelectString(channelIdx, "C1", "C2")
		Print "Warning: No samples found in List_" + chName
		return -1
	endif
	
	Variable numSamples = ItemsInList(sampleList)
	
	// root:Comparison2D Text Wave
	NewDataFolder/O root:Comparison
	String savedDF = GetDataFolder(1)
	SetDataFolder root:Comparison
	
	Make/O/T/N=(numConditions, numTimePoints) $listName
	Wave/T listWave = $listName
	
	Variable condIdx, tpIdx, sampleIdx
	sampleIdx = 0
	for(condIdx = 0; condIdx < numConditions; condIdx += 1)
		for(tpIdx = 0; tpIdx < numTimePoints; tpIdx += 1)
			if(sampleIdx < numSamples)
				listWave[condIdx][tpIdx] = StringFromList(sampleIdx, sampleList)
			else
				listWave[condIdx][tpIdx] = ""
			endif
			sampleIdx += 1
		endfor
	endfor
	
	// 
	NVAR TimeInterval = root:TimeInterval
	Variable interval = TimeInterval
	
	for(tpIdx = 0; tpIdx < numTimePoints; tpIdx += 1)
		String colLabel = "t" + num2str(tpIdx * interval) + "min"
		SetDimLabel 1, tpIdx, $colLabel, listWave
	endfor
	
	for(condIdx = 0; condIdx < numConditions; condIdx += 1)
		String rowLabel = "L" + num2str(condIdx + 1)
		SetDimLabel 0, condIdx, $rowLabel, listWave
	endfor
	
	SetDataFolder $savedDF
	return 0
End

// =============================================================================
// Timelapse Normalized Compare All Functions (v2.5.5)
// =============================================================================

// -----------------------------------------------------------------------------
// TL_GetAvailableParameters - Comparison
// Single Channel: D, L, HMMP, Tau, Frac, Int, LP, PDens, MolDens, OnRate, Trans
// Colocalization: Intensity, Diffusion, On-time, On-rate, Affinity
// -----------------------------------------------------------------------------
Function/S TL_GetAvailableParameters()
	String compPath = TL_GetComparisonPath()
	if(!DataFolderExists(compPath))
		return ""
	endif
	
	// 
	Variable isColMode = TL_IsColocalizationMode()
	
	if(isColMode)
		// Colocalization: 
		// waveCompare
		return "Intensity;Diffusion;On-time;On-rate;Affinity;"
	endif
	
	// Single Channel: 
	String savedDF = GetDataFolder(1)
	SetDataFolder $compPath
	
	String paramList = ""
	String allWaves = WaveList("*", ";", "")
	
	// 
	String excludePatterns = "*_sem*;*_mean*;*_Names;*_Colors;*_colors*;*_avg*;TL_*;SampleNames;BarColors;nLB_*;*AllMeans*;*AllSEMs*;*AllLabels*"
	
	Variable waveIdx, numWaves = ItemsInList(allWaves)
	String wName, paramType
	
	for(waveIdx = 0; waveIdx < numWaves; waveIdx += 1)
		wName = StringFromList(waveIdx, allWaves)
		
		// 
		Variable excluded = 0
		Variable exIdx
		for(exIdx = 0; exIdx < ItemsInList(excludePatterns); exIdx += 1)
			if(StringMatch(wName, StringFromList(exIdx, excludePatterns)))
				excluded = 1
				break
			endif
		endfor
		if(excluded)
			continue
		endif
		
		// 
		paramType = ""
		
		// D_S*_*  (: D_S1_Sample1)
		if(StringMatch(wName, "D_S*_*"))
			paramType = "D"
		// L_S*_*  (: L_S1_Sample1)
		elseif(StringMatch(wName, "L_S*_*"))
			paramType = "L"
		// HMMP_S*_*  (: HMMP_S1_Sample1) - S0
		elseif(StringMatch(wName, "HMMP_S*_*") && !StringMatch(wName, "HMMP_S0_*"))
			paramType = "HMMP"
		// Tau_C*_*  (: Tau_C1_Sample1) - On-time τ
		elseif(StringMatch(wName, "Tau_C*_*"))
			paramType = "TauOff"
		// Frac_C*_*  (: Frac_C1_Sample1)
		elseif(StringMatch(wName, "Frac_C*_*"))
			paramType = "Frac"
		// Int_S*_*  (: Int_S1_Sample1) - Mean Oligomer Size
		elseif(StringMatch(wName, "Int_S*_*"))
			paramType = "Int"
		// LP_S*_*  (: LP_S1_Sample1) - Localization Precision
		elseif(StringMatch(wName, "LP_S*_*"))
			paramType = "LP"
		// PDens_S*_*  (: PDens_S1_Sample1) - Particle Density
		elseif(StringMatch(wName, "PDens_S*_*"))
			paramType = "PDens"
		// MolDens_S*_*  (: MolDens_S1_Sample1)
		elseif(StringMatch(wName, "MolDens_S*_*"))
			paramType = "MolDens"
		// OnRate_S*_*  (: OnRate_S1_Sample1)
		elseif(StringMatch(wName, "OnRate_S*_*"))
			paramType = "OnRate"
		// Trans_S*to*_*  (: Trans_S1to2_Sample1)
		elseif(StringMatch(wName, "Trans_S*to*_*"))
			paramType = "Trans"
		// Area_*  (: Area_Sample1)
		elseif(StringMatch(wName, "Area_*"))
			paramType = "Area"
		// NumPts_*  (: NumPts_Sample1)
		elseif(StringMatch(wName, "NumPts_*"))
			paramType = "NumPts"
		endif
		
		// 
		if(strlen(paramType) > 0 && WhichListItem(paramType, paramList) < 0)
			paramList += paramType + ";"
		endif
	endfor
	
	SetDataFolder $savedDF
	return paramList
End

// -----------------------------------------------------------------------------
// TL_GetColChannelList - Colocalization tab
// : "_C1E;_C2E" or "_C1E" or "_C2E"
// -----------------------------------------------------------------------------
Function/S TL_GetColChannelList()
	NVAR/Z ColOutputChannel = root:ColOutputChannel
	Variable mode = NVAR_Exists(ColOutputChannel) ? ColOutputChannel : 0  // 0=Both, 1=C1, 2=C2
	
	if(mode == 0)  // Both
		return "_C1E;_C2E"
	elseif(mode == 1)  // C1
		return "_C1E"
	else  // C2
		return "_C2E"
	endif
End

// -----------------------------------------------------------------------------
// TL_UpdateParameterPopup - 
// -----------------------------------------------------------------------------
Function TL_UpdateParameterPopup()
	String paramList = TL_GetAvailableParameters()
	
	if(strlen(paramList) == 0)
		paramList = "_none_"
	endif
	
	// 
	String/G root:TL_ParameterList = paramList
	
	// 
	PopupMenu tab7_popup_param, mode=1, value=#"root:TL_ParameterList"
	
	Print "Available parameters: " + paramList
End

// -----------------------------------------------------------------------------
// TL_GetBaseColIdx - timepoint index
// -----------------------------------------------------------------------------
Function TL_GetBaseColIdx()
	NVAR/Z TimeInterval = root:TimeInterval
	NVAR/Z TimeStimulation = root:TimeStimulation
	NVAR/Z TimePoints = root:TimePoints
	
	Variable interval = 5
	if(NVAR_Exists(TimeInterval) && TimeInterval > 0)
		interval = TimeInterval
	endif
	
	Variable stimTime = 0
	if(NVAR_Exists(TimeStimulation))
		stimTime = TimeStimulation
	endif
	
	Variable numTimePoints = 6
	if(NVAR_Exists(TimePoints) && TimePoints > 0)
		numTimePoints = TimePoints
	endif
	
	// index
	Variable baseColIdx = 0
	if(stimTime > 0)
		baseColIdx = floor(stimTime / interval)
		if(baseColIdx > 0)
			baseColIdx -= 1
		endif
	endif
	
	if(baseColIdx >= numTimePoints)
		baseColIdx = 0
	endif
	
	return baseColIdx
End

// -----------------------------------------------------------------------------
// TL_GetStateName - GetDstateName
// -----------------------------------------------------------------------------
Function/S TL_GetStateName(stateNum)
	Variable stateNum
	
	NVAR/Z Dstate = root:Dstate
	Variable numStates = 3
	if(NVAR_Exists(Dstate) && Dstate > 0)
		numStates = Dstate
	endif
	
	return GetDstateName(stateNum, numStates)
End

// -----------------------------------------------------------------------------
// TL_GetStateNumFromPrefix - prefix
// Single-Channel: D_S1, L_S0 
// Colocalization: ColOsizeCol_S0_C1E, ColHMMP_abs_S0_C1E 
// -----------------------------------------------------------------------------
Function TL_GetStateNumFromPrefix(prefix)
	String prefix
	
	// "_S"
	Variable sPos = strsearch(prefix, "_S", 0)
	if(sPos < 0)
		return 0  // 
	endif
	
	// "_S"
	String afterS = prefix[sPos+2, strlen(prefix)-1]
	
	// "_"
	Variable nextUnderscore = strsearch(afterS, "_", 0)
	String numStr
	if(nextUnderscore > 0)
		numStr = afterS[0, nextUnderscore-1]
	else
		numStr = afterS
	endif
	
	Variable stateNum = str2num(numStr)
	if(numtype(stateNum) != 0)
		return 0  // NaN
	endif
	
	return stateNum
End

// -----------------------------------------------------------------------------
// TL_GetYAxisLabel - Y
// Batch AnalysisCompare
// -----------------------------------------------------------------------------
Function/S TL_GetYAxisLabel(paramType, stateNum, compIdx)
	String paramType
	Variable stateNum   // D, L, HMMP
	Variable compIdx    // Tau, Frac
	
	String stateName = TL_GetStateName(stateNum)
	String label = ""
	
	strswitch(paramType)
		case "D":
			// D_stateName [µm²/s]
			label = "D\\B" + stateName + "\\M\r[µm\\S2\\M/s]"
			break
		case "L":
			// L_stateName [µm]
			label = "L\\B" + stateName + "\\M\r[µm]"
			break
		case "HMMP":
			// Population_stateName [%]
			label = "Population\\B" + stateName + "\\M\r[%]"
			break
		case "TauOff":
			// τoff_n [s] (On-time)
			label = "τ\\Boff\\M" + num2str(compIdx) + "\r[s]"
			break
		case "Frac":
			// Fractionn [%]
			label = "Fraction" + num2str(compIdx) + "\r[%]"
			break
		case "Int":
			// Mean Oligomer Size_stateName
			label = "Mean Oligomer Size\\B" + stateName + "\\M"
			break
		case "LP":
			// Mean LP_stateName [nm]
			label = "Mean LP\\B" + stateName + "\\M\r[nm]"
			break
		case "PDens":
			// Particle Density_stateName [/µm²]
			label = "Particle Density\\B" + stateName + "\\M\r[/µm\\S2\\M]"
			break
		case "MolDens":
			// Mol. Density_stateName [/µm²]
			label = "Mol. Density\\B" + stateName + "\\M\r[/µm\\S2\\M]"
			break
		case "OnRate":
			// On-Rate_stateName [/µm²/s]
			label = "On-Rate\\B" + stateName + "\\M\r[/µm\\S2\\M/s]"
			break
		case "Trans":
			// τ [s] (transition time)
			label = "τ\r[s]"
			break
		case "Area":
			// Cell Area [µm²]
			label = "Cell Area\r[µm\\S2\\M]"
			break
		case "NumPts":
			// Number of Points
			label = "Number of Points"
			break
		default:
			label = paramType
			break
	endswitch
	
	return label
End

// -----------------------------------------------------------------------------
// TL_GetGraphTitle - 
// -----------------------------------------------------------------------------
Function/S TL_GetGraphTitle(paramType, stateNum, compIdx, fromState, toState)
	String paramType
	Variable stateNum, compIdx, fromState, toState
	
	String stateName = TL_GetStateName(stateNum)
	String title = ""
	
	strswitch(paramType)
		case "D":
			title = "D (" + stateName + ")"
			break
		case "L":
			title = "L (" + stateName + ")"
			break
		case "HMMP":
			title = "Population (" + stateName + ")"
			break
		case "TauOff":
			title = "τoff" + num2str(compIdx)
			break
		case "Frac":
			title = "Fraction" + num2str(compIdx)
			break
		case "Int":
			title = "Oligomer (" + stateName + ")"
			break
		case "LP":
			title = "LP (" + stateName + ")"
			break
		case "PDens":
			title = "PDens (" + stateName + ")"
			break
		case "MolDens":
			title = "MolDens (" + stateName + ")"
			break
		case "OnRate":
			title = "OnRate (" + stateName + ")"
			break
		case "Trans":
			String fromName = TL_GetStateName(fromState)
			String toName = TL_GetStateName(toState)
			title = "Trans (" + fromName + "→" + toName + ")"
			break
		case "Area":
			title = "Cell Area"
			break
		case "NumPts":
			title = "Number of Points"
			break
		default:
			title = paramType
			break
	endswitch
	
	return title
End

// -----------------------------------------------------------------------------
// TL_ProcessSelectedParameter - 
// mode: 0=Original, 1=Normalize, 2=Difference
// D, L, HMMP ColHMMP_abs
// -----------------------------------------------------------------------------
Function TL_ProcessSelectedParameter(mode)
	Variable mode
	
	// 
	ControlInfo tab7_popup_param
	String selectedParam = S_Value
	
	if(strlen(selectedParam) == 0 || StringMatch(selectedParam, "_none_"))
		DoAlert 0, "Please select a parameter first."
		return -1
	endif
	
	// Comparison
	String compPath = TL_GetComparisonPath()
	
	// TL_SampleList
	Wave/T/Z TL_SampleList = $(compPath + ":TL_SampleList")
	if(!WaveExists(TL_SampleList))
		DoAlert 0, "TL_SampleList not found.\nPlease run 'Create Sample List' first."
		return -1
	endif
	
	String savedDF = GetDataFolder(1)
	SetDataFolder $compPath
	
	Variable baseColIdx = TL_GetBaseColIdx()
	
	String modeStr = ""
	switch(mode)
		case 0:
			modeStr = "Original"
			break
		case 1:
			modeStr = "Normalized"
			break
		case 2:
			modeStr = "Difference"
			break
	endswitch
	
	Print "=== " + modeStr + " Summary Plot: " + selectedParam + " ==="
	
	NVAR/Z Dstate = root:Dstate
	NVAR/Z ExpMax_off = root:ExpMax_off
	
	Variable numStates = 3
	if(NVAR_Exists(Dstate) && Dstate > 0)
		numStates = Dstate
	endif
	
	Variable maxExp = 2
	if(NVAR_Exists(ExpMax_off) && ExpMax_off > 0)
		maxExp = ExpMax_off
	endif
	
	Variable stateIdx, chIdx
	String graphTitle, prefix, yLabel
	String chSuffix, chList, checkWaveName
	
	// 
	Variable isColMode = TL_IsColocalizationMode()
	
	if(isColMode)
		// : 
		chList = TL_GetColChannelList()
		
		// Colocalization tab
		NVAR/Z ColWeightingMode = root:ColWeightingMode
		NVAR/Z ColAffinityParam = root:ColAffinityParam
		NVAR/Z ColIntensityMode = root:ColIntensityMode
		NVAR/Z ColDiffusionMode = root:ColDiffusionMode
		NVAR/Z ColOntimeMode = root:ColOntimeMode
		NVAR/Z ColOnrateMode = root:ColOnrateMode
		
		Variable weighting = NVAR_Exists(ColWeightingMode) ? ColWeightingMode : 1  // 0=Particle, 1=Molecule
		Variable affParam = NVAR_Exists(ColAffinityParam) ? ColAffinityParam : 0
		Variable intMode = NVAR_Exists(ColIntensityMode) ? ColIntensityMode : 0
		Variable diffMode = NVAR_Exists(ColDiffusionMode) ? ColDiffusionMode : 0
		Variable ontMode = NVAR_Exists(ColOntimeMode) ? ColOntimeMode : 0
		Variable onrMode = NVAR_Exists(ColOnrateMode) ? ColOnrateMode : 0
		
		// BothC1→C2
		for(chIdx = 0; chIdx < ItemsInList(chList); chIdx += 1)
			chSuffix = StringFromList(chIdx, chList)
			
			// _C1E→0, _C2E→1
			Variable channelIdx = (StringMatch(chSuffix, "_C2E")) ? 1 : 0
			TL_CreateSampleListForChannel(channelIdx)
			
			// TL_CreateSampleListForChannelSetDataFolder
			SetDataFolder $compPath
			
			// TL_SampleList
			Wave/T/Z TL_SampleList = $(compPath + ":TL_SampleList")
			if(!WaveExists(TL_SampleList))
				Print "Warning: Could not create TL_SampleList for channel " + chSuffix
				continue
			endif
			
			Print "Processing channel: " + chSuffix
			
			// Comparison waveColOsizeCol_S0
			checkWaveName = "ColOsizeCol_S0" + chSuffix + "_" + TL_SampleList[0][0]
			Wave/Z checkW = $checkWaveName
			if(!WaveExists(checkW))
				Print "ERROR: Comparison data not found for " + chSuffix
				Print "Please run 'Compare All' in the Colocalization tab first."
				DoAlert 0, "Comparison data not found.\n\nPlease run 'Compare All' in the Colocalization tab before using Timelapse."
				SetDataFolder $savedDF
				return -1
			endif
			
			// 
			strswitch(selectedParam)
				case "Intensity":
					if(intMode == 0)
						for(stateIdx = 0; stateIdx <= numStates; stateIdx += 1)
							prefix = "ColOsizeCol_S" + num2str(stateIdx) + chSuffix
							graphTitle = "Osize S" + num2str(stateIdx) + " " + chSuffix
							yLabel = "Oligomer Size"
							TL_CreateSummaryPlotWithMode2(prefix, TL_SampleList, baseColIdx, graphTitle, yLabel, mode)
						endfor
					else
						for(stateIdx = 0; stateIdx <= numStates; stateIdx += 1)
							prefix = "ColInt_S" + num2str(stateIdx) + chSuffix
							graphTitle = "Int S" + num2str(stateIdx) + " " + chSuffix
							yLabel = "Intensity [a.u.]"
							TL_CreateSummaryPlotWithMode2(prefix, TL_SampleList, baseColIdx, graphTitle, yLabel, mode)
						endfor
					endif
					break
					
				case "Diffusion":
					if(diffMode == 0)
						for(stateIdx = 0; stateIdx <= numStates; stateIdx += 1)
							prefix = "ColHMMP_abs_S" + num2str(stateIdx) + chSuffix
							graphTitle = "HMMP abs S" + num2str(stateIdx) + " " + chSuffix
							yLabel = "HMMP [%]"
							TL_CreateSummaryPlotWithMode2(prefix, TL_SampleList, baseColIdx, graphTitle, yLabel, mode)
						endfor
					elseif(diffMode == 1)
						for(stateIdx = 1; stateIdx <= numStates; stateIdx += 1)
							prefix = "ColHMMP_S" + num2str(stateIdx) + chSuffix
							graphTitle = "HMMP S" + num2str(stateIdx) + " " + chSuffix
							yLabel = "HMMP [%]"
							TL_CreateSummaryPlotWithMode2(prefix, TL_SampleList, baseColIdx, graphTitle, yLabel, mode)
						endfor
					else
						for(stateIdx = 0; stateIdx <= numStates; stateIdx += 1)
							if(weighting == 0)
								prefix = "ColSteps_S" + num2str(stateIdx) + chSuffix
							else
								prefix = "ColStepsMol_S" + num2str(stateIdx) + chSuffix
							endif
							graphTitle = "Steps S" + num2str(stateIdx) + " " + chSuffix
							yLabel = "Steps [%]"
							TL_CreateSummaryPlotWithMode2(prefix, TL_SampleList, baseColIdx, graphTitle, yLabel, mode)
						endfor
					endif
					break
					
				case "On-time":
					if(ontMode == 0)
						for(stateIdx = 0; stateIdx <= numStates; stateIdx += 1)
							prefix = "ColOntime_mean_S" + num2str(stateIdx) + chSuffix
							graphTitle = "On-time S" + num2str(stateIdx) + " " + chSuffix
							yLabel = "On-time [s]"
							TL_CreateSummaryPlotWithMode2(prefix, TL_SampleList, baseColIdx, graphTitle, yLabel, mode)
						endfor
					else
						Variable compIdx
						for(compIdx = 1; compIdx <= maxExp; compIdx += 1)
							prefix = "ColTau_C" + num2str(compIdx) + chSuffix
							graphTitle = "Tau C" + num2str(compIdx) + " " + chSuffix
							yLabel = "τ [s]"
							TL_CreateSummaryPlotWithMode2(prefix, TL_SampleList, baseColIdx, graphTitle, yLabel, mode)
						endfor
					endif
					break
					
				case "On-rate":
					if(onrMode == 0)
						for(stateIdx = 0; stateIdx <= numStates; stateIdx += 1)
							prefix = "ColOnRate_S" + num2str(stateIdx) + chSuffix
							graphTitle = "On-rate S" + num2str(stateIdx) + " " + chSuffix
							yLabel = "On-rate [/µm²/s]"
							TL_CreateSummaryPlotWithMode2(prefix, TL_SampleList, baseColIdx, graphTitle, yLabel, mode)
						endfor
					else
						for(stateIdx = 0; stateIdx <= numStates; stateIdx += 1)
							prefix = "ColKon_S" + num2str(stateIdx) + chSuffix
							graphTitle = "k_on S" + num2str(stateIdx) + " " + chSuffix
							yLabel = "k_on [/µm²/s]"
							TL_CreateSummaryPlotWithMode2(prefix, TL_SampleList, baseColIdx, graphTitle, yLabel, mode)
						endfor
					endif
					break
					
				case "Affinity":
					if(affParam == 0)
						for(stateIdx = 0; stateIdx <= numStates; stateIdx += 1)
							if(weighting == 0)
								prefix = "ColKb_S" + num2str(stateIdx) + chSuffix
							else
								prefix = "ColKbMol_S" + num2str(stateIdx) + chSuffix
							endif
							graphTitle = "Kb S" + num2str(stateIdx) + " " + chSuffix
							yLabel = "Kb [/µm²]"
							TL_CreateSummaryPlotWithMode2(prefix, TL_SampleList, baseColIdx, graphTitle, yLabel, mode)
						endfor
					elseif(affParam == 1)
						for(stateIdx = 0; stateIdx <= numStates; stateIdx += 1)
							if(weighting == 0)
								prefix = "ColPDens_S" + num2str(stateIdx) + chSuffix
								yLabel = "Particle Density [/µm²]"
							else
								prefix = "ColMDens_S" + num2str(stateIdx) + chSuffix
								yLabel = "Molecular Density [/µm²]"
							endif
							graphTitle = "Density S" + num2str(stateIdx) + " " + chSuffix
							TL_CreateSummaryPlotWithMode2(prefix, TL_SampleList, baseColIdx, graphTitle, yLabel, mode)
						endfor
					else
						Print "Distance affinity not yet implemented for Timelapse"
					endif
					break
					
				default:
					Print "Unknown colocalization parameter: " + selectedParam
					break
			endswitch
		endfor
		
		SetDataFolder $savedDF
		return 0
	endif
	
	// Single Channel: Comparison waveD_S1
	checkWaveName = "D_S1_" + TL_SampleList[0][0]
	Wave/Z checkW = $checkWaveName
	if(!WaveExists(checkW))
		Print "ERROR: Comparison data not found."
		Print "Please run 'Compare All' in the Comparison tab first."
		DoAlert 0, "Comparison data not found.\n\nPlease run 'Compare All' in the Comparison tab before using Timelapse."
		SetDataFolder $savedDF
		return -1
	endif
	
	// Single Channel: 
	strswitch(selectedParam)
		// === Single Channel ===
		case "D":
			// D_S0, D_S1, D_S2, ... D_S{Dstate} (S0)
			for(stateIdx = 0; stateIdx <= numStates; stateIdx += 1)
				prefix = "D_S" + num2str(stateIdx)
				graphTitle = TL_GetGraphTitle("D", stateIdx, 0, 0, 0)
				yLabel = TL_GetYAxisLabel("D", stateIdx, 0)
				TL_CreateSummaryPlotWithMode2(prefix, TL_SampleList, baseColIdx, graphTitle, yLabel, mode)
			endfor
			break
			
		case "L":
			// L_S0, L_S1, L_S2, ... L_S{Dstate} (S0)
			for(stateIdx = 0; stateIdx <= numStates; stateIdx += 1)
				prefix = "L_S" + num2str(stateIdx)
				graphTitle = TL_GetGraphTitle("L", stateIdx, 0, 0, 0)
				yLabel = TL_GetYAxisLabel("L", stateIdx, 0)
				TL_CreateSummaryPlotWithMode2(prefix, TL_SampleList, baseColIdx, graphTitle, yLabel, mode)
			endfor
			break
			
		case "HMMP":
			// HMMP_S1, HMMP_S2, ... HMMP_S{Dstate} (S0)
			for(stateIdx = 1; stateIdx <= numStates; stateIdx += 1)
				prefix = "HMMP_S" + num2str(stateIdx)
				graphTitle = TL_GetGraphTitle("HMMP", stateIdx, 0, 0, 0)
				yLabel = TL_GetYAxisLabel("HMMP", stateIdx, 0)
				TL_CreateSummaryPlotWithMode2(prefix, TL_SampleList, baseColIdx, graphTitle, yLabel, mode)
			endfor
			break
			
		case "TauOff":
			// Tau_C1, Tau_C2, ... (ExpMax_off) - On-time τ
			for(stateIdx = 1; stateIdx <= maxExp; stateIdx += 1)
				prefix = "Tau_C" + num2str(stateIdx)
				graphTitle = TL_GetGraphTitle("TauOff", 0, stateIdx, 0, 0)
				yLabel = TL_GetYAxisLabel("TauOff", 0, stateIdx)
				TL_CreateSummaryPlotWithMode2(prefix, TL_SampleList, baseColIdx, graphTitle, yLabel, mode)
			endfor
			break
			
		case "Frac":
			// Frac_C1, Frac_C2, ...
			for(stateIdx = 1; stateIdx <= maxExp; stateIdx += 1)
				prefix = "Frac_C" + num2str(stateIdx)
				graphTitle = TL_GetGraphTitle("Frac", 0, stateIdx, 0, 0)
				yLabel = TL_GetYAxisLabel("Frac", 0, stateIdx)
				TL_CreateSummaryPlotWithMode2(prefix, TL_SampleList, baseColIdx, graphTitle, yLabel, mode)
			endfor
			break
			
		case "Int":
			// Int_S0, Int_S1, Int_S2, ... (Mean Oligomer Size, S0)
			for(stateIdx = 0; stateIdx <= numStates; stateIdx += 1)
				prefix = "Int_S" + num2str(stateIdx)
				graphTitle = TL_GetGraphTitle("Int", stateIdx, 0, 0, 0)
				yLabel = TL_GetYAxisLabel("Int", stateIdx, 0)
				TL_CreateSummaryPlotWithMode2(prefix, TL_SampleList, baseColIdx, graphTitle, yLabel, mode)
			endfor
			break
			
		case "LP":
			// LP_S0, LP_S1, LP_S2, ... (Localization Precision, S0)
			for(stateIdx = 0; stateIdx <= numStates; stateIdx += 1)
				prefix = "LP_S" + num2str(stateIdx)
				graphTitle = TL_GetGraphTitle("LP", stateIdx, 0, 0, 0)
				yLabel = TL_GetYAxisLabel("LP", stateIdx, 0)
				TL_CreateSummaryPlotWithMode2(prefix, TL_SampleList, baseColIdx, graphTitle, yLabel, mode)
			endfor
			break
			
		case "PDens":
			// PDens_S0, PDens_S1, PDens_S2, ... (Particle Density, S0)
			for(stateIdx = 0; stateIdx <= numStates; stateIdx += 1)
				prefix = "PDens_S" + num2str(stateIdx)
				graphTitle = TL_GetGraphTitle("PDens", stateIdx, 0, 0, 0)
				yLabel = TL_GetYAxisLabel("PDens", stateIdx, 0)
				TL_CreateSummaryPlotWithMode2(prefix, TL_SampleList, baseColIdx, graphTitle, yLabel, mode)
			endfor
			break
			
		case "MolDens":
			// MolDens_S0, MolDens_S1, MolDens_S2, ... (S0)
			for(stateIdx = 0; stateIdx <= numStates; stateIdx += 1)
				prefix = "MolDens_S" + num2str(stateIdx)
				graphTitle = TL_GetGraphTitle("MolDens", stateIdx, 0, 0, 0)
				yLabel = TL_GetYAxisLabel("MolDens", stateIdx, 0)
				TL_CreateSummaryPlotWithMode2(prefix, TL_SampleList, baseColIdx, graphTitle, yLabel, mode)
			endfor
			break
			
		case "OnRate":
			// OnRate_S0, OnRate_S1, OnRate_S2, ... (S0)
			for(stateIdx = 0; stateIdx <= numStates; stateIdx += 1)
				prefix = "OnRate_S" + num2str(stateIdx)
				graphTitle = TL_GetGraphTitle("OnRate", stateIdx, 0, 0, 0)
				yLabel = TL_GetYAxisLabel("OnRate", stateIdx, 0)
				TL_CreateSummaryPlotWithMode2(prefix, TL_SampleList, baseColIdx, graphTitle, yLabel, mode)
			endfor
			break
			
		case "Trans":
			// Trans_S{from}to{to} ()
			Variable fromS, toS
			for(fromS = 1; fromS <= numStates; fromS += 1)
				for(toS = 1; toS <= numStates; toS += 1)
					if(fromS != toS)
						prefix = "Trans_S" + num2str(fromS) + "to" + num2str(toS)
						graphTitle = TL_GetGraphTitle("Trans", 0, 0, fromS, toS)
						yLabel = TL_GetYAxisLabel("Trans", 0, 0)
						TL_CreateSummaryPlotWithMode2(prefix, TL_SampleList, baseColIdx, graphTitle, yLabel, mode)
					endif
				endfor
			endfor
			break
			
		case "Area":
			// Area ()
			prefix = "Area"
			graphTitle = TL_GetGraphTitle("Area", 0, 0, 0, 0)
			yLabel = TL_GetYAxisLabel("Area", 0, 0)
			TL_CreateSummaryPlotWithMode2(prefix, TL_SampleList, baseColIdx, graphTitle, yLabel, mode)
			break
			
		case "NumPts":
			// NumPts ()
			prefix = "NumPts"
			graphTitle = TL_GetGraphTitle("NumPts", 0, 0, 0, 0)
			yLabel = TL_GetYAxisLabel("NumPts", 0, 0)
			TL_CreateSummaryPlotWithMode2(prefix, TL_SampleList, baseColIdx, graphTitle, yLabel, mode)
			break
			
		default:
			//  - 
			TL_CreateSummaryPlotWithMode2(selectedParam, TL_SampleList, baseColIdx, selectedParam, selectedParam, mode)
			break
	endswitch
	
	SetDataFolder $savedDF
	return 0
End

// -----------------------------------------------------------------------------
// TL_CreateSummaryPlotWithMode2 - Summary PlotY
// mode: 0=Original, 1=Normalize, 2=Difference
// -----------------------------------------------------------------------------
Function TL_CreateSummaryPlotWithMode2(prefix, sampleList, baseColIdx, graphTitle, yAxisLabel, mode)
	String prefix
	Wave/T sampleList
	Variable baseColIdx
	String graphTitle
	String yAxisLabel
	Variable mode
	
	Variable numConditions = DimSize(sampleList, 0)
	Variable numTimePoints = DimSize(sampleList, 1)
	Variable totalPoints = numConditions * numTimePoints
	
	NVAR/Z TimeInterval = root:TimeInterval
	NVAR/Z Dstate = root:Dstate
	
	Variable interval = 5
	if(NVAR_Exists(TimeInterval) && TimeInterval > 0)
		interval = TimeInterval
	endif
	
	Variable numStates = 3
	if(NVAR_Exists(Dstate) && Dstate > 0)
		numStates = Dstate
	endif
	
	// 
	Variable isColMode = TL_IsColocalizationMode()
	
	// 
	Variable stateNum = TL_GetStateNumFromPrefix(prefix)
	
	// 
	Variable baseR, baseG, baseB
	// Area/NumPts(50%)
	if(StringMatch(prefix, "Area*") || StringMatch(prefix, "NumPts*"))
		baseR = 32768
		baseG = 32768
		baseB = 32768
	else
		GetDstateColor(stateNum, baseR, baseG, baseB)
	endif
	
	// 
	String modePrefix = ""
	String modeLabel = ""
	switch(mode)
		case 0:
			modePrefix = ""
			modeLabel = ""
			break
		case 1:
			modePrefix = "n"
			modeLabel = "Normalized "
			break
		case 2:
			modePrefix = "d"
			modeLabel = "Δ"
			break
	endswitch
	
	// 
	String catAxisName = modePrefix + prefix + "_Names"
	Make/O/T/N=(totalPoints) $catAxisName
	Wave/T catAxis = $catAxisName
	
	// Mean/SEM wave
	String meanWaveName = modePrefix + prefix + "_mean"
	String semWaveName = modePrefix + prefix + "_sem"
	Make/O/D/N=(totalPoints) $meanWaveName, $semWaveName
	Wave meanW = $meanWaveName
	Wave semW = $semWaveName
	
	// wave
	String colorWaveName = modePrefix + prefix + "_Colors"
	Make/O/N=(totalPoints, 3) $colorWaveName
	Wave BarColors = $colorWaveName
	
	// 0=Mean, 1=Each cell
	NVAR/Z TL_NormMethod = root:TL_NormMethod
	Variable normMethod = NVAR_Exists(TL_NormMethod) ? TL_NormMethod : 0
	
	// Mean
	Make/O/D/N=(numConditions) TL_BaseValues
	
	// celldata waveEach cell
	// timepointcelldata
	String baseCelldataList = ""
	
	// 
	Variable condIdx, tpIdx
	String sampleName, celldataName
	
	for(condIdx = 0; condIdx < numConditions; condIdx += 1)
		sampleName = sampleList[condIdx][baseColIdx]
		// : prefix_sampleNameCompareD/CompareL
		celldataName = prefix + "_" + sampleName
		Wave/Z baseCelldata = $celldataName
		
		if(WaveExists(baseCelldata) && numpnts(baseCelldata) > 0)
			WaveStats/Q baseCelldata
			TL_BaseValues[condIdx] = V_avg
			baseCelldataList += celldataName + ";"
		else
			TL_BaseValues[condIdx] = NaN
			baseCelldataList += ";"
		endif
	endfor
	
	// wave
	String processedList = ""
	
	// 
	Variable idx = 0
	for(condIdx = 0; condIdx < numConditions; condIdx += 1)
		Variable baseValue = TL_BaseValues[condIdx]
		String baseWaveName = StringFromList(condIdx, baseCelldataList)
		Wave/Z baseCelldataW = $baseWaveName
		
		for(tpIdx = 0; tpIdx < numTimePoints; tpIdx += 1)
			sampleName = sampleList[condIdx][tpIdx]
			
			// 
			String timeLabel = "t" + num2str(tpIdx * interval)
			String condLabel = "L" + num2str(condIdx + 1)
			catAxis[idx] = timeLabel + "_" + condLabel
			
			// : prefix_sampleNameCompareD/CompareL
			celldataName = prefix + "_" + sampleName
			Wave/Z celldata = $celldataName
			
			// waveOriginalwave
			String processedName
			if(mode == 0)
				processedName = celldataName  // Originalwave
			else
				processedName = modePrefix + celldataName
			endif
			
			if(WaveExists(celldata) && numpnts(celldata) > 0)
				// 
				if(mode == 0)
					// Original: wave
					WaveStats/Q celldata
					meanW[idx] = V_avg
					semW[idx] = V_sem
					processedList += processedName + ";"
				elseif(mode == 1)
					// Normalize: 
					if(normMethod == 0)
						// Mean: 
						if(numtype(baseValue) == 0 && baseValue != 0)
							Duplicate/O celldata, $processedName
							Wave procW = $processedName
							procW = celldata / baseValue
							WaveStats/Q procW
							meanW[idx] = V_avg
							semW[idx] = V_sem
							processedList += processedName + ";"
						else
							meanW[idx] = NaN
							semW[idx] = NaN
						endif
					else
						// Each cell: cellcell
						if(WaveExists(baseCelldataW) && numpnts(baseCelldataW) > 0)
							Variable numCells = min(numpnts(celldata), numpnts(baseCelldataW))
							Duplicate/O celldata, $processedName
							Wave procW = $processedName
							Variable ci
							for(ci = 0; ci < numCells; ci += 1)
								if(baseCelldataW[ci] != 0 && numtype(baseCelldataW[ci]) == 0)
									procW[ci] = celldata[ci] / baseCelldataW[ci]
								else
									procW[ci] = NaN
								endif
							endfor
							// numCellsNaN
							if(numpnts(celldata) > numCells)
								procW[numCells, numpnts(celldata)-1] = NaN
							endif
							WaveStats/Q procW
							meanW[idx] = V_avg
							semW[idx] = V_sem
							processedList += processedName + ";"
						else
							meanW[idx] = NaN
							semW[idx] = NaN
						endif
					endif
				elseif(mode == 2)
					// Difference: 
					if(normMethod == 0)
						// Mean: 
						if(numtype(baseValue) == 0)
							Duplicate/O celldata, $processedName
							Wave procW = $processedName
							procW = celldata - baseValue
							WaveStats/Q procW
							meanW[idx] = V_avg
							semW[idx] = V_sem
							processedList += processedName + ";"
						else
							meanW[idx] = NaN
							semW[idx] = NaN
						endif
					else
						// Each cell: cellcell
						if(WaveExists(baseCelldataW) && numpnts(baseCelldataW) > 0)
							Variable numCellsD = min(numpnts(celldata), numpnts(baseCelldataW))
							Duplicate/O celldata, $processedName
							Wave procW = $processedName
							Variable cj
							for(cj = 0; cj < numCellsD; cj += 1)
								if(numtype(baseCelldataW[cj]) == 0)
									procW[cj] = celldata[cj] - baseCelldataW[cj]
								else
									procW[cj] = NaN
								endif
							endfor
							// numCellsDNaN
							if(numpnts(celldata) > numCellsD)
								procW[numCellsD, numpnts(celldata)-1] = NaN
							endif
							WaveStats/Q procW
							meanW[idx] = V_avg
							semW[idx] = V_sem
							processedList += processedName + ";"
						else
							meanW[idx] = NaN
							semW[idx] = NaN
						endif
					endif
				endif
			else
				meanW[idx] = NaN
				semW[idx] = NaN
			endif
			
			// 
			Variable shade = 1 - tpIdx * 0.08
			Variable condShade = 1 - condIdx * 0.15
			BarColors[idx][0] = min(baseR * shade * condShade, 65535)
			BarColors[idx][1] = min(baseG * shade * condShade, 65535)
			BarColors[idx][2] = min(baseB * shade * condShade, 65535)
			
			idx += 1
		endfor
	endfor
	
	KillWaves/Z TL_BaseValues
	
	// 
	String winName = "TL_" + modePrefix + prefix
	DoWindow/K $winName
	
	// 1. Mean±SEM
	Display/K=1/N=$winName meanW vs catAxis
	// S0hbFill=4hbFill=2
	// stateNum == 0  prefix"_S0"Colocalization
	Variable isS0 = (stateNum == 0) || (strsearch(prefix, "_S0", 0) >= 0)
	if(isS0)
		ModifyGraph mode($meanWaveName)=5, hbFill($meanWaveName)=4
	else
		ModifyGraph mode($meanWaveName)=5, hbFill($meanWaveName)=2
	endif
	ModifyGraph zColor($meanWaveName)={BarColors,*,*,directRGB,0}
	ModifyGraph useBarStrokeRGB($meanWaveName)=1, barStrokeRGB($meanWaveName)=(0,0,0)
	ErrorBars $meanWaveName Y,wave=(semW, semW)
	
	// 2. Violin Plot/T
	Variable firstViolin = 1
	String firstViolinTrace = ""
	
	idx = 0
	for(condIdx = 0; condIdx < numConditions; condIdx += 1)
		for(tpIdx = 0; tpIdx < numTimePoints; tpIdx += 1)
			sampleName = sampleList[condIdx][tpIdx]
			String procName
			// : prefix_sampleNameCompareD/CompareL
			if(mode == 0)
				procName = prefix + "_" + sampleName
			else
				procName = modePrefix + prefix + "_" + sampleName
			endif
			Wave/Z procWave = $procName
			
			if(!WaveExists(procWave) || numpnts(procWave) == 0)
				idx += 1
				continue
			endif
			
			if(firstViolin)
				AppendViolinPlot/T procWave vs catAxis
				firstViolinTrace = procName
				firstViolin = 0
			else
				AddWavesToViolinPlot/T=$firstViolinTrace procWave
			endif
			
			idx += 1
		endfor
	endfor
	
	// 3. Violin PlotTop axisViolin
	if(strlen(firstViolinTrace) > 0)
		ModifyViolinPlot trace=$firstViolinTrace, LineColor=(65535,65535,65535,0)
		ModifyViolinPlot trace=$firstViolinTrace, DataMarker=19, MarkerColor=(0,0,0)
		// Top axisViolin Plot
		ModifyGraph noLabel(top)=2, axThick(top)=0
		ModifyGraph tick(top)=3
	endif
	
	// 
	ModifyGraph tick=2, mirror=0, fStyle=1, fSize=14, font="Arial"
	ModifyGraph lowTrip(left)=0.0001
	ModifyGraph tick(bottom)=3
	ModifyGraph tkLblRot(bottom)=45
	ModifyGraph catGap(bottom)=0.3
	
	// 
	SetBarGraphSizeByItems(totalPoints)
	
	// YyAxisLabel
	// modeLabelΔ
	String yLabel = ""
	if(strlen(modeLabel) > 0)
		// yAxisLabel\rmodeLabel
		Variable crPos = strsearch(yAxisLabel, "\r", 0)
		if(crPos > 0)
			// : "D\\Bimmobile\\M\r[µm²/s]" → "ΔD\\Bimmobile\\M\r[µm²/s]"
			yLabel = "\\F'Arial'\\Z14" + modeLabel + yAxisLabel[0, crPos-1] + "\r" + yAxisLabel[crPos+1, strlen(yAxisLabel)-1]
		else
			// 
			yLabel = "\\F'Arial'\\Z14" + modeLabel + yAxisLabel
		endif
	else
		yLabel = "\\F'Arial'\\Z14" + yAxisLabel
	endif
	Label left yLabel
	
	// Y
	if(mode == 0 || mode == 1)
		SetAxis left 0, *
	endif
	// mode == 2 (Difference) Y
	
	DoWindow/T $winName, modeLabel + graphTitle
	
	// 
	RunAutoStatisticalTest(winName)
	
	Print "  Created: " + winName
	
	// Line Plot
	TL_CreateLinePlotFromData2(prefix, sampleList, graphTitle, yAxisLabel, mode)
End

// -----------------------------------------------------------------------------
// TL_OriginalCompareAll - Compare All
// -----------------------------------------------------------------------------
Function TL_OriginalCompareAll()
	return TL_CompareAllWithMode(0)
End

// -----------------------------------------------------------------------------
// TL_NormalizeCompareAll - Compare All
// -----------------------------------------------------------------------------
Function TL_NormalizeCompareAll()
	return TL_CompareAllWithMode(1)
End

// -----------------------------------------------------------------------------
// TL_DifferenceCompareAll - Compare All
// -----------------------------------------------------------------------------
Function TL_DifferenceCompareAll()
	return TL_CompareAllWithMode(2)
End

// -----------------------------------------------------------------------------
// TL_CompareAllWithMode - Compare All
// mode: 0=Original, 1=Normalize, 2=Difference
// -----------------------------------------------------------------------------
Function TL_CompareAllWithMode(mode)
	Variable mode
	
	NVAR/Z TimePoints = root:TimePoints
	NVAR/Z Dstate = root:Dstate
	NVAR/Z ExpMax_off = root:ExpMax_off
	NVAR/Z MaxOligomer = root:MaxOligomer
	
	// 
	if(!NVAR_Exists(TimePoints) || TimePoints < 1)
		DoAlert 0, "TimePoints is not set."
		return -1
	endif
	
	// Comparison
	String compPath = TL_GetComparisonPath()
	
	// TL_SampleList
	Wave/T/Z TL_SampleList = $(compPath + ":TL_SampleList")
	if(!WaveExists(TL_SampleList))
		DoAlert 0, "TL_SampleList not found.\nPlease run 'Create Sample List' first."
		return -1
	endif
	
	// Line Plot
	Variable/G root:TL_LastMode = mode
	
	Variable baseColIdx = TL_GetBaseColIdx()
	
	String modeStr = ""
	switch(mode)
		case 0:
			modeStr = "Original"
			break
		case 1:
			modeStr = "Normalized"
			break
		case 2:
			modeStr = "Difference"
			break
	endswitch
	
	// 
	Variable isColMode = TL_IsColocalizationMode()
	if(isColMode)
		Print "=== " + modeStr + " Compare All (Colocalization) ==="
	else
		Print "=== " + modeStr + " Compare All (Per Channel) ==="
	endif
	Print "Base timepoint index: " + num2str(baseColIdx)
	
	String savedDF = GetDataFolder(1)
	SetDataFolder $compPath
	
	Variable numStates = 3
	if(NVAR_Exists(Dstate) && Dstate > 0)
		numStates = Dstate
	endif
	
	Variable maxExp = 2
	if(NVAR_Exists(ExpMax_off) && ExpMax_off > 0)
		maxExp = ExpMax_off
	endif
	
	Variable maxOlig = 4
	if(NVAR_Exists(MaxOligomer) && MaxOligomer > 0)
		maxOlig = MaxOligomer
	endif
	
	Variable stateIdx, chIdx, compIdx
	String stateName, graphTitle, prefix, testWaveName, yLabel
	String chSuffix, chList, checkWaveName
	
	// 
	if(isColMode)
		// ===  ===
		// 
		chList = TL_GetColChannelList()
		
		// Colocalization tab
		NVAR/Z ColWeightingMode = root:ColWeightingMode
		NVAR/Z ColAffinityParam = root:ColAffinityParam
		NVAR/Z ColIntensityMode = root:ColIntensityMode
		NVAR/Z ColDiffusionMode = root:ColDiffusionMode
		NVAR/Z ColOntimeMode = root:ColOntimeMode
		NVAR/Z ColOnrateMode = root:ColOnrateMode
		
		Variable weighting = NVAR_Exists(ColWeightingMode) ? ColWeightingMode : 1
		Variable affParam = NVAR_Exists(ColAffinityParam) ? ColAffinityParam : 0
		Variable intMode = NVAR_Exists(ColIntensityMode) ? ColIntensityMode : 0
		Variable diffMode = NVAR_Exists(ColDiffusionMode) ? ColDiffusionMode : 0
		Variable ontMode = NVAR_Exists(ColOntimeMode) ? ColOntimeMode : 0
		Variable onrMode = NVAR_Exists(ColOnrateMode) ? ColOnrateMode : 0
		
		// BothC1→C2
		for(chIdx = 0; chIdx < ItemsInList(chList); chIdx += 1)
			chSuffix = StringFromList(chIdx, chList)
			
			// _C1E→0, _C2E→1
			Variable channelIdx = (StringMatch(chSuffix, "_C2E")) ? 1 : 0
			TL_CreateSampleListForChannel(channelIdx)
			
			// TL_CreateSampleListForChannelSetDataFolder
			SetDataFolder $compPath
			
			// TL_SampleList
			Wave/T/Z TL_SampleList = $(compPath + ":TL_SampleList")
			if(!WaveExists(TL_SampleList))
				Print "Warning: Could not create TL_SampleList for channel " + chSuffix
				continue
			endif
			
			Print "========== Processing channel: " + chSuffix + " =========="
			
			// Comparison waveColOsizeCol_S0
			checkWaveName = "ColOsizeCol_S0" + chSuffix + "_" + TL_SampleList[0][0]
			Wave/Z checkW = $checkWaveName
			if(!WaveExists(checkW))
				Print "ERROR: Comparison data not found for " + chSuffix
				Print "Please run 'Compare All' in the Colocalization tab first."
				DoAlert 0, "Comparison data not found.\n\nPlease run 'Compare All' in the Colocalization tab before using Timelapse."
				SetDataFolder $savedDF
				return -1
			endif
			
			// --- Affinity ---
			Print "--- Affinity ---"
			if(affParam == 0)
				for(stateIdx = 0; stateIdx <= numStates; stateIdx += 1)
					if(weighting == 0)
						prefix = "ColKb_S" + num2str(stateIdx) + chSuffix
					else
						prefix = "ColKbMol_S" + num2str(stateIdx) + chSuffix
					endif
					testWaveName = prefix + "_" + TL_SampleList[0][0]
					Wave/Z testW = $testWaveName
					if(WaveExists(testW))
						graphTitle = "Kb S" + num2str(stateIdx) + " " + chSuffix
						yLabel = "Kb [/µm²]"
						TL_CreateSummaryPlotWithMode2(prefix, TL_SampleList, baseColIdx, graphTitle, yLabel, mode)
					endif
				endfor
			elseif(affParam == 1)
				for(stateIdx = 0; stateIdx <= numStates; stateIdx += 1)
					if(weighting == 0)
						prefix = "ColPDens_S" + num2str(stateIdx) + chSuffix
						yLabel = "Particle Density [/µm²]"
					else
						prefix = "ColMDens_S" + num2str(stateIdx) + chSuffix
						yLabel = "Molecular Density [/µm²]"
					endif
					testWaveName = prefix + "_" + TL_SampleList[0][0]
					Wave/Z testW = $testWaveName
					if(WaveExists(testW))
						graphTitle = "Density S" + num2str(stateIdx) + " " + chSuffix
						TL_CreateSummaryPlotWithMode2(prefix, TL_SampleList, baseColIdx, graphTitle, yLabel, mode)
					endif
				endfor
			else
				Print "Distance affinity not yet implemented for Timelapse"
			endif
			
			// --- Intensity ---
			Print "--- Intensity ---"
			if(intMode == 0)
				for(stateIdx = 0; stateIdx <= numStates; stateIdx += 1)
					prefix = "ColOsizeCol_S" + num2str(stateIdx) + chSuffix
					testWaveName = prefix + "_" + TL_SampleList[0][0]
					Wave/Z testW = $testWaveName
					if(WaveExists(testW))
						graphTitle = "Osize S" + num2str(stateIdx) + " " + chSuffix
						yLabel = "Oligomer Size"
						TL_CreateSummaryPlotWithMode2(prefix, TL_SampleList, baseColIdx, graphTitle, yLabel, mode)
					endif
				endfor
			else
				for(stateIdx = 0; stateIdx <= numStates; stateIdx += 1)
					prefix = "ColInt_S" + num2str(stateIdx) + chSuffix
					testWaveName = prefix + "_" + TL_SampleList[0][0]
					Wave/Z testW = $testWaveName
					if(WaveExists(testW))
						graphTitle = "Int S" + num2str(stateIdx) + " " + chSuffix
						yLabel = "Intensity [a.u.]"
						TL_CreateSummaryPlotWithMode2(prefix, TL_SampleList, baseColIdx, graphTitle, yLabel, mode)
					endif
				endfor
			endif
			
			// --- Diffusion ---
			Print "--- Diffusion ---"
			if(diffMode == 0)
				for(stateIdx = 0; stateIdx <= numStates; stateIdx += 1)
					prefix = "ColHMMP_abs_S" + num2str(stateIdx) + chSuffix
					testWaveName = prefix + "_" + TL_SampleList[0][0]
					Wave/Z testW = $testWaveName
					if(WaveExists(testW))
						graphTitle = "HMMP abs S" + num2str(stateIdx) + " " + chSuffix
						yLabel = "HMMP [%]"
						TL_CreateSummaryPlotWithMode2(prefix, TL_SampleList, baseColIdx, graphTitle, yLabel, mode)
					endif
				endfor
			elseif(diffMode == 1)
				for(stateIdx = 1; stateIdx <= numStates; stateIdx += 1)
					prefix = "ColHMMP_S" + num2str(stateIdx) + chSuffix
					testWaveName = prefix + "_" + TL_SampleList[0][0]
					Wave/Z testW = $testWaveName
					if(WaveExists(testW))
						graphTitle = "HMMP S" + num2str(stateIdx) + " " + chSuffix
						yLabel = "HMMP [%]"
						TL_CreateSummaryPlotWithMode2(prefix, TL_SampleList, baseColIdx, graphTitle, yLabel, mode)
					endif
				endfor
			else
				for(stateIdx = 0; stateIdx <= numStates; stateIdx += 1)
					if(weighting == 0)
						prefix = "ColSteps_S" + num2str(stateIdx) + chSuffix
					else
						prefix = "ColStepsMol_S" + num2str(stateIdx) + chSuffix
					endif
					testWaveName = prefix + "_" + TL_SampleList[0][0]
					Wave/Z testW = $testWaveName
					if(WaveExists(testW))
						graphTitle = "Steps S" + num2str(stateIdx) + " " + chSuffix
						yLabel = "Steps [%]"
						TL_CreateSummaryPlotWithMode2(prefix, TL_SampleList, baseColIdx, graphTitle, yLabel, mode)
					endif
				endfor
			endif
			
			// --- On-time ---
			Print "--- On-time ---"
			if(ontMode == 0)
				for(stateIdx = 0; stateIdx <= numStates; stateIdx += 1)
					prefix = "ColOntime_mean_S" + num2str(stateIdx) + chSuffix
					testWaveName = prefix + "_" + TL_SampleList[0][0]
					Wave/Z testW = $testWaveName
					if(WaveExists(testW))
						graphTitle = "On-time S" + num2str(stateIdx) + " " + chSuffix
						yLabel = "On-time [s]"
						TL_CreateSummaryPlotWithMode2(prefix, TL_SampleList, baseColIdx, graphTitle, yLabel, mode)
					endif
				endfor
			else
				for(compIdx = 1; compIdx <= maxExp; compIdx += 1)
					prefix = "ColTau_C" + num2str(compIdx) + chSuffix
					testWaveName = prefix + "_" + TL_SampleList[0][0]
					Wave/Z testW = $testWaveName
					if(WaveExists(testW))
						graphTitle = "Tau C" + num2str(compIdx) + " " + chSuffix
						yLabel = "τ [s]"
						TL_CreateSummaryPlotWithMode2(prefix, TL_SampleList, baseColIdx, graphTitle, yLabel, mode)
					endif
				endfor
			endif
			
			// --- On-rate ---
			Print "--- On-rate ---"
			if(onrMode == 0)
				for(stateIdx = 0; stateIdx <= numStates; stateIdx += 1)
					prefix = "ColOnRate_S" + num2str(stateIdx) + chSuffix
					testWaveName = prefix + "_" + TL_SampleList[0][0]
					Wave/Z testW = $testWaveName
					if(WaveExists(testW))
						graphTitle = "On-rate S" + num2str(stateIdx) + " " + chSuffix
						yLabel = "On-rate [/µm²/s]"
						TL_CreateSummaryPlotWithMode2(prefix, TL_SampleList, baseColIdx, graphTitle, yLabel, mode)
					endif
				endfor
			else
				for(stateIdx = 0; stateIdx <= numStates; stateIdx += 1)
					prefix = "ColKon_S" + num2str(stateIdx) + chSuffix
					testWaveName = prefix + "_" + TL_SampleList[0][0]
					Wave/Z testW = $testWaveName
					if(WaveExists(testW))
						graphTitle = "k_on S" + num2str(stateIdx) + " " + chSuffix
						yLabel = "k_on [/µm²/s]"
						TL_CreateSummaryPlotWithMode2(prefix, TL_SampleList, baseColIdx, graphTitle, yLabel, mode)
					endif
				endfor
			endif
		endfor
		
	else
		// === Single Channel ===
		
		// Comparison waveD_S1
		checkWaveName = "D_S1_" + TL_SampleList[0][0]
		Wave/Z checkW = $checkWaveName
		if(!WaveExists(checkW))
			Print "ERROR: Comparison data not found."
			Print "Please run 'Compare All' in the Comparison tab first."
			DoAlert 0, "Comparison data not found.\n\nPlease run 'Compare All' in the Comparison tab before using Timelapse."
			SetDataFolder $savedDF
			return -1
		endif
		
		// ----- D () - S0 -----
		for(stateIdx = 0; stateIdx <= numStates; stateIdx += 1)
			prefix = "D_S" + num2str(stateIdx)
			// 
			testWaveName = prefix + "_" + TL_SampleList[0][0]
			Wave/Z testW = $testWaveName
			if(WaveExists(testW))
				graphTitle = TL_GetGraphTitle("D", stateIdx, 0, 0, 0)
				yLabel = TL_GetYAxisLabel("D", stateIdx, 0)
				TL_CreateSummaryPlotWithMode2(prefix, TL_SampleList, baseColIdx, graphTitle, yLabel, mode)
			endif
		endfor
	
	// ----- L () - S0 -----
	for(stateIdx = 0; stateIdx <= numStates; stateIdx += 1)
		prefix = "L_S" + num2str(stateIdx)
		testWaveName = prefix + "_" + TL_SampleList[0][0]
		Wave/Z testW = $testWaveName
		if(WaveExists(testW))
			graphTitle = TL_GetGraphTitle("L", stateIdx, 0, 0, 0)
			yLabel = TL_GetYAxisLabel("L", stateIdx, 0)
			TL_CreateSummaryPlotWithMode2(prefix, TL_SampleList, baseColIdx, graphTitle, yLabel, mode)
		endif
	endfor
	
	// ----- HMMP (HMM) - S0 -----
	for(stateIdx = 1; stateIdx <= numStates; stateIdx += 1)
		prefix = "HMMP_S" + num2str(stateIdx)
		testWaveName = prefix + "_" + TL_SampleList[0][0]
		Wave/Z testW = $testWaveName
		if(WaveExists(testW))
			graphTitle = TL_GetGraphTitle("HMMP", stateIdx, 0, 0, 0)
			yLabel = TL_GetYAxisLabel("HMMP", stateIdx, 0)
			TL_CreateSummaryPlotWithMode2(prefix, TL_SampleList, baseColIdx, graphTitle, yLabel, mode)
		endif
	endfor
	
	// ----- TauOff (On-time) - Tau_C1, Tau_C2, ... -----
	for(stateIdx = 1; stateIdx <= maxExp; stateIdx += 1)
		prefix = "Tau_C" + num2str(stateIdx)
		testWaveName = prefix + "_" + TL_SampleList[0][0]
		Wave/Z testW = $testWaveName
		if(WaveExists(testW))
			graphTitle = TL_GetGraphTitle("TauOff", 0, stateIdx, 0, 0)
			yLabel = TL_GetYAxisLabel("TauOff", 0, stateIdx)
			TL_CreateSummaryPlotWithMode2(prefix, TL_SampleList, baseColIdx, graphTitle, yLabel, mode)
		endif
	endfor
	
	// ----- Frac () - Frac_C1, Frac_C2, ... -----
	for(stateIdx = 1; stateIdx <= maxExp; stateIdx += 1)
		prefix = "Frac_C" + num2str(stateIdx)
		testWaveName = prefix + "_" + TL_SampleList[0][0]
		Wave/Z testW = $testWaveName
		if(WaveExists(testW))
			graphTitle = TL_GetGraphTitle("Frac", 0, stateIdx, 0, 0)
			yLabel = TL_GetYAxisLabel("Frac", 0, stateIdx)
			TL_CreateSummaryPlotWithMode2(prefix, TL_SampleList, baseColIdx, graphTitle, yLabel, mode)
		endif
	endfor
	
	// ----- Int (Mean Oligomer Size) - S0 -----
	for(stateIdx = 0; stateIdx <= numStates; stateIdx += 1)
		prefix = "Int_S" + num2str(stateIdx)
		testWaveName = prefix + "_" + TL_SampleList[0][0]
		Wave/Z testW = $testWaveName
		if(WaveExists(testW))
			graphTitle = TL_GetGraphTitle("Int", stateIdx, 0, 0, 0)
			yLabel = TL_GetYAxisLabel("Int", stateIdx, 0)
			TL_CreateSummaryPlotWithMode2(prefix, TL_SampleList, baseColIdx, graphTitle, yLabel, mode)
		endif
	endfor
	
	// ----- LP (Localization Precision) - S0 -----
	for(stateIdx = 0; stateIdx <= numStates; stateIdx += 1)
		prefix = "LP_S" + num2str(stateIdx)
		testWaveName = prefix + "_" + TL_SampleList[0][0]
		Wave/Z testW = $testWaveName
		if(WaveExists(testW))
			graphTitle = TL_GetGraphTitle("LP", stateIdx, 0, 0, 0)
			yLabel = TL_GetYAxisLabel("LP", stateIdx, 0)
			TL_CreateSummaryPlotWithMode2(prefix, TL_SampleList, baseColIdx, graphTitle, yLabel, mode)
		endif
	endfor
	
	// ----- PDens (Particle Density) - S0 -----
	for(stateIdx = 0; stateIdx <= numStates; stateIdx += 1)
		prefix = "PDens_S" + num2str(stateIdx)
		testWaveName = prefix + "_" + TL_SampleList[0][0]
		Wave/Z testW = $testWaveName
		if(WaveExists(testW))
			graphTitle = TL_GetGraphTitle("PDens", stateIdx, 0, 0, 0)
			yLabel = TL_GetYAxisLabel("PDens", stateIdx, 0)
			TL_CreateSummaryPlotWithMode2(prefix, TL_SampleList, baseColIdx, graphTitle, yLabel, mode)
		endif
	endfor
	
	// ----- MolDens - S0 -----
	for(stateIdx = 0; stateIdx <= numStates; stateIdx += 1)
		prefix = "MolDens_S" + num2str(stateIdx)
		testWaveName = prefix + "_" + TL_SampleList[0][0]
		Wave/Z testW = $testWaveName
		if(WaveExists(testW))
			graphTitle = TL_GetGraphTitle("MolDens", stateIdx, 0, 0, 0)
			yLabel = TL_GetYAxisLabel("MolDens", stateIdx, 0)
			TL_CreateSummaryPlotWithMode2(prefix, TL_SampleList, baseColIdx, graphTitle, yLabel, mode)
		endif
	endfor
	
	// ----- OnRate - S0 -----
	for(stateIdx = 0; stateIdx <= numStates; stateIdx += 1)
		prefix = "OnRate_S" + num2str(stateIdx)
		testWaveName = prefix + "_" + TL_SampleList[0][0]
		Wave/Z testW = $testWaveName
		if(WaveExists(testW))
			graphTitle = TL_GetGraphTitle("OnRate", stateIdx, 0, 0, 0)
			yLabel = TL_GetYAxisLabel("OnRate", stateIdx, 0)
			TL_CreateSummaryPlotWithMode2(prefix, TL_SampleList, baseColIdx, graphTitle, yLabel, mode)
		endif
	endfor
	
	// ----- Trans () -----
	Variable fromS, toS
	for(fromS = 1; fromS <= numStates; fromS += 1)
		for(toS = 1; toS <= numStates; toS += 1)
			if(fromS != toS)
				prefix = "Trans_S" + num2str(fromS) + "to" + num2str(toS)
				testWaveName = prefix + "_" + TL_SampleList[0][0]
				Wave/Z testW = $testWaveName
				if(WaveExists(testW))
					graphTitle = TL_GetGraphTitle("Trans", 0, 0, fromS, toS)
					yLabel = TL_GetYAxisLabel("Trans", 0, 0)
					TL_CreateSummaryPlotWithMode2(prefix, TL_SampleList, baseColIdx, graphTitle, yLabel, mode)
				endif
			endif
		endfor
	endfor
	
	// ----- Area -----
	prefix = "Area"
	testWaveName = prefix + "_" + TL_SampleList[0][0]
	Wave/Z testW = $testWaveName
	if(WaveExists(testW))
		graphTitle = TL_GetGraphTitle("Area", 0, 0, 0, 0)
		yLabel = TL_GetYAxisLabel("Area", 0, 0)
		TL_CreateSummaryPlotWithMode2(prefix, TL_SampleList, baseColIdx, graphTitle, yLabel, mode)
	endif
	
	// ----- NumPts -----
	prefix = "NumPts"
	testWaveName = prefix + "_" + TL_SampleList[0][0]
	Wave/Z testW2 = $testWaveName
	if(WaveExists(testW2))
		graphTitle = TL_GetGraphTitle("NumPts", 0, 0, 0, 0)
		yLabel = TL_GetYAxisLabel("NumPts", 0, 0)
		TL_CreateSummaryPlotWithMode2(prefix, TL_SampleList, baseColIdx, graphTitle, yLabel, mode)
	endif
	
	endif  // end of isColMode else block
	
	SetDataFolder $savedDF
	Print "=== " + modeStr + " Compare All Complete ==="
	return 0
End

// -----------------------------------------------------------------------------
// TL_CreateLinePlots - Line Plot
// mode: 0=Original, 1=Normalize, 2=Difference
// -----------------------------------------------------------------------------
Function TL_CreateLinePlots(mode)
	Variable mode
	
	NVAR/Z TimePoints = root:TimePoints
	NVAR/Z Dstate = root:Dstate
	NVAR/Z ExpMax = root:ExpMax
	NVAR/Z MaxOligomer = root:MaxOligomer
	
	if(!NVAR_Exists(TimePoints) || TimePoints < 1)
		DoAlert 0, "TimePoints is not set."
		return -1
	endif
	
	// Comparison
	String compPath = TL_GetComparisonPath()
	
	Wave/T/Z TL_SampleList = $(compPath + ":TL_SampleList")
	if(!WaveExists(TL_SampleList))
		DoAlert 0, "TL_SampleList not found."
		return -1
	endif
	
	String savedDF = GetDataFolder(1)
	SetDataFolder $compPath
	
	Variable numStates = 3
	if(NVAR_Exists(Dstate) && Dstate > 0)
		numStates = Dstate
	endif
	
	Variable maxExp = 2
	if(NVAR_Exists(ExpMax) && ExpMax > 0)
		maxExp = ExpMax
	endif
	
	Variable maxOlig = 4
	if(NVAR_Exists(MaxOligomer) && MaxOligomer > 0)
		maxOlig = MaxOligomer
	endif
	
	// 
	Variable isColMode = TL_IsColocalizationMode()
	
	Variable stateIdx, chIdx
	String stateName, graphTitle, prefix
	String chSuffix, chList = "C1E;C2E"
	
	// 
	String modePrefix = ""
	switch(mode)
		case 0:
			modePrefix = ""
			break
		case 1:
			modePrefix = "n"
			break
		case 2:
			modePrefix = "d"
			break
	endswitch
	
	if(isColMode)
		// ===  ===
		String testName
		
		// 
		chList = TL_GetColChannelList()
		
		// BothC1→C2
		for(chIdx = 0; chIdx < ItemsInList(chList); chIdx += 1)
			chSuffix = StringFromList(chIdx, chList)
			
			// _C1E→0, _C2E→1
			Variable channelIdx = (StringMatch(chSuffix, "_C2E")) ? 1 : 0
			TL_CreateSampleListForChannel(channelIdx)
			
			// TL_SampleList
			Wave/T/Z TL_SampleList = $(compPath + ":TL_SampleList")
			if(!WaveExists(TL_SampleList))
				Print "Warning: Could not create TL_SampleList for channel " + chSuffix
				continue
			endif
			
			Print "Creating Line Plots for channel: " + chSuffix
			
			// ColHMMP_abs
			for(stateIdx = 0; stateIdx <= numStates; stateIdx += 1)
				prefix = "ColHMMP_abs_S" + num2str(stateIdx) + chSuffix
				testName = modePrefix + TL_SampleList[0][0] + "_" + prefix
				Wave/Z testW = $testName
				if(WaveExists(testW))
					graphTitle = "Col HMMP abs S" + num2str(stateIdx) + " " + chSuffix
					TL_CreateLinePlotFromData(prefix, TL_SampleList, graphTitle, mode)
				endif
			endfor
			
			// ColOntime_mean
			for(stateIdx = 0; stateIdx <= numStates; stateIdx += 1)
				prefix = "ColOntime_mean_S" + num2str(stateIdx) + chSuffix
				testName = modePrefix + TL_SampleList[0][0] + "_" + prefix
				Wave/Z testW = $testName
				if(WaveExists(testW))
					graphTitle = "Col On-time S" + num2str(stateIdx) + " " + chSuffix
					TL_CreateLinePlotFromData(prefix, TL_SampleList, graphTitle, mode)
				endif
			endfor
			
			// ColSteps
			for(stateIdx = 0; stateIdx <= numStates; stateIdx += 1)
				prefix = "ColSteps_S" + num2str(stateIdx) + chSuffix
				testName = modePrefix + TL_SampleList[0][0] + "_" + prefix
				Wave/Z testW = $testName
				if(WaveExists(testW))
					graphTitle = "Col Steps S" + num2str(stateIdx) + " " + chSuffix
					TL_CreateLinePlotFromData(prefix, TL_SampleList, graphTitle, mode)
				endif
			endfor
			
			// ColOnRate
			for(stateIdx = 0; stateIdx <= numStates; stateIdx += 1)
				prefix = "ColOnRate_S" + num2str(stateIdx) + chSuffix
				testName = modePrefix + TL_SampleList[0][0] + "_" + prefix
				Wave/Z testW = $testName
				if(WaveExists(testW))
					graphTitle = "Col On-rate S" + num2str(stateIdx) + " " + chSuffix
					TL_CreateLinePlotFromData(prefix, TL_SampleList, graphTitle, mode)
				endif
			endfor
			
			// ColKb
			for(stateIdx = 0; stateIdx <= numStates; stateIdx += 1)
				prefix = "ColKb_S" + num2str(stateIdx) + chSuffix
				testName = modePrefix + TL_SampleList[0][0] + "_" + prefix
				Wave/Z testW = $testName
				if(WaveExists(testW))
					graphTitle = "Col Kb S" + num2str(stateIdx) + " " + chSuffix
					TL_CreateLinePlotFromData(prefix, TL_SampleList, graphTitle, mode)
				endif
			endfor
			
			// ColPDens
			for(stateIdx = 0; stateIdx <= numStates; stateIdx += 1)
				prefix = "ColPDens_S" + num2str(stateIdx) + chSuffix
				testName = modePrefix + TL_SampleList[0][0] + "_" + prefix
				Wave/Z testW = $testName
				if(WaveExists(testW))
					graphTitle = "Col P Density S" + num2str(stateIdx) + " " + chSuffix
					TL_CreateLinePlotFromData(prefix, TL_SampleList, graphTitle, mode)
				endif
			endfor
			
			// ColMDens
			for(stateIdx = 0; stateIdx <= numStates; stateIdx += 1)
				prefix = "ColMDens_S" + num2str(stateIdx) + chSuffix
				testName = modePrefix + TL_SampleList[0][0] + "_" + prefix
				Wave/Z testW = $testName
				if(WaveExists(testW))
					graphTitle = "Col M Density S" + num2str(stateIdx) + " " + chSuffix
					TL_CreateLinePlotFromData(prefix, TL_SampleList, graphTitle, mode)
				endif
			endfor
		endfor
		
	else
		// === Per Channel ===
		// ----- D -----
		for(stateIdx = 1; stateIdx <= numStates; stateIdx += 1)
			prefix = "D_S" + num2str(stateIdx)
			testName = modePrefix + prefix + "_" + TL_SampleList[0][0]
			Wave/Z testW = $testName
			if(WaveExists(testW))
				stateName = TL_GetStateName(stateIdx)
				graphTitle = "D (" + stateName + ")"
				TL_CreateLinePlotFromData(prefix, TL_SampleList, graphTitle, mode)
			endif
		endfor
	
	// ----- L -----
	for(stateIdx = 1; stateIdx <= numStates; stateIdx += 1)
		prefix = "L_S" + num2str(stateIdx)
		testName = modePrefix + prefix + "_" + TL_SampleList[0][0]
		Wave/Z testW = $testName
		if(WaveExists(testW))
			stateName = TL_GetStateName(stateIdx)
			graphTitle = "L (" + stateName + ")"
			TL_CreateLinePlotFromData(prefix, TL_SampleList, graphTitle, mode)
		endif
	endfor
	
	// ----- HMMP -----
	for(stateIdx = 0; stateIdx <= numStates; stateIdx += 1)
		prefix = "HMMP_S" + num2str(stateIdx)
		testName = modePrefix + prefix + "_" + TL_SampleList[0][0]
		Wave/Z testW = $testName
		if(WaveExists(testW))
			stateName = TL_GetStateName(stateIdx)
			graphTitle = "HMMP (" + stateName + ")"
			TL_CreateLinePlotFromData(prefix, TL_SampleList, graphTitle, mode)
		endif
	endfor
	
	// ----- Tau -----
	for(stateIdx = 1; stateIdx <= maxExp; stateIdx += 1)
		prefix = "Tau" + num2str(stateIdx)
		testName = modePrefix + prefix + "_" + TL_SampleList[0][0]
		Wave/Z testW = $testName
		if(WaveExists(testW))
			graphTitle = "Tau" + num2str(stateIdx)
			TL_CreateLinePlotFromData(prefix, TL_SampleList, graphTitle, mode)
		endif
	endfor
	
	// ----- Frac -----
	for(stateIdx = 1; stateIdx <= maxExp; stateIdx += 1)
		prefix = "Frac" + num2str(stateIdx)
		testName = modePrefix + prefix + "_" + TL_SampleList[0][0]
		Wave/Z testW = $testName
		if(WaveExists(testW))
			graphTitle = "Frac" + num2str(stateIdx)
			TL_CreateLinePlotFromData(prefix, TL_SampleList, graphTitle, mode)
		endif
	endfor
	
	// ----- IntPop -----
	for(stateIdx = 1; stateIdx <= maxOlig; stateIdx += 1)
		prefix = "IntPop" + num2str(stateIdx)
		testName = modePrefix + prefix + "_" + TL_SampleList[0][0]
		Wave/Z testW = $testName
		if(WaveExists(testW))
			graphTitle = "IntPop" + num2str(stateIdx)
			TL_CreateLinePlotFromData(prefix, TL_SampleList, graphTitle, mode)
		endif
	endfor
	
	// ----- Onrate -----
	prefix = "Onrate"
	testName = modePrefix + prefix + "_" + TL_SampleList[0][0]
	Wave/Z testW = $testName
	if(WaveExists(testW))
		graphTitle = "On Rate"
		TL_CreateLinePlotFromData(prefix, TL_SampleList, graphTitle, mode)
	endif
	
	// ----- Trans -----
	Variable fromS, toS
	for(fromS = 1; fromS <= numStates; fromS += 1)
		for(toS = 1; toS <= numStates; toS += 1)
			if(fromS != toS)
				prefix = "Trans_S" + num2str(fromS) + "to" + num2str(toS)
				testName = modePrefix + prefix + "_" + TL_SampleList[0][0]
				Wave/Z testW = $testName
				if(WaveExists(testW))
					String fromName = TL_GetStateName(fromS)
					String toName = TL_GetStateName(toS)
					graphTitle = "Trans (" + fromName + "→" + toName + ")"
					TL_CreateLinePlotFromData(prefix, TL_SampleList, graphTitle, mode)
				endif
			endif
		endfor
	endfor
	
	// ----- nLB -----
	for(stateIdx = 1; stateIdx <= numStates; stateIdx += 1)
		prefix = "nLB_S" + num2str(stateIdx)
		testName = modePrefix + prefix + "_" + TL_SampleList[0][0]
		Wave/Z testW = $testName
		if(WaveExists(testW))
			stateName = TL_GetStateName(stateIdx)
			graphTitle = "nLB (" + stateName + ")"
			TL_CreateLinePlotFromData(prefix, TL_SampleList, graphTitle, mode)
		endif
	endfor
	
	endif  // end of isColMode else block
	
	SetDataFolder $savedDF
	Print "=== Line Plots Created ==="
	return 0
End

// -----------------------------------------------------------------------------
// TL_CreateLinePlotFromData - Line Plot
// -----------------------------------------------------------------------------
Function TL_CreateLinePlotFromData(prefix, sampleList, graphTitle, mode)
	String prefix
	Wave/T sampleList
	String graphTitle
	Variable mode
	
	Variable numConditions = DimSize(sampleList, 0)
	Variable numTimePoints = DimSize(sampleList, 1)
	
	NVAR/Z TimeInterval = root:TimeInterval
	NVAR/Z TimeStimulation = root:TimeStimulation
	NVAR/Z Dstate = root:Dstate
	
	Variable interval = 5
	if(NVAR_Exists(TimeInterval) && TimeInterval > 0)
		interval = TimeInterval
	endif
	
	Variable stimTime = 0
	if(NVAR_Exists(TimeStimulation))
		stimTime = TimeStimulation
	endif
	
	Variable numStates = 3
	if(NVAR_Exists(Dstate) && Dstate > 0)
		numStates = Dstate
	endif
	
	// 
	Variable isColMode = TL_IsColocalizationMode()
	
	// 
	String modePrefix = ""
	String modeLabel = ""
	switch(mode)
		case 0:
			modePrefix = ""
			modeLabel = ""
			break
		case 1:
			modePrefix = "n"
			modeLabel = "Normalized "
			break
		case 2:
			modePrefix = "d"
			modeLabel = "Δ"
			break
	endswitch
	
	// wave: prefix_sampleName
	String testName
	testName = modePrefix + prefix + "_" + sampleList[0][0]
	Wave/Z testWave = $testName
	if(!WaveExists(testWave))
		return 0
	endif
	
	// 
	Variable stateNum = TL_GetStateNumFromPrefix(prefix)
	Variable baseR, baseG, baseB
	GetDstateColor(stateNum, baseR, baseG, baseB)
	
	// 
	Make/O/D/N=(numTimePoints) TL_time_min = p * interval - stimTime
	
	// 
	String winName = "Line_" + modePrefix + prefix
	DoWindow/K $winName
	Display/K=1/N=$winName
	
	Variable firstTrace = 1
	Variable condIdx, tpIdx
	String sampleName, procName
	
	for(condIdx = 0; condIdx < numConditions; condIdx += 1)
		String avgName = modePrefix + prefix + "_avg_C" + num2str(condIdx + 1)
		String semName = modePrefix + prefix + "_sem_C" + num2str(condIdx + 1)
		
		Make/O/D/N=(numTimePoints) $avgName, $semName
		Wave avgW = $avgName
		Wave semW = $semName
		
		for(tpIdx = 0; tpIdx < numTimePoints; tpIdx += 1)
			sampleName = sampleList[condIdx][tpIdx]
			// : prefix_sampleNameCompareD/CompareL
			procName = modePrefix + prefix + "_" + sampleName
			Wave/Z procWave = $procName
			
			if(WaveExists(procWave) && numpnts(procWave) > 0)
				WaveStats/Q procWave
				avgW[tpIdx] = V_avg
				semW[tpIdx] = V_sem
			else
				avgW[tpIdx] = NaN
				semW[tpIdx] = NaN
			endif
		endfor
		
		// : Intensity histogram
		// : 40%
		Variable darkR1 = baseR * 0.4
		Variable darkG1 = baseG * 0.4
		Variable darkB1 = baseB * 0.4
		// : 50%
		Variable maxVal1 = 65535
		Variable lightR1 = baseR + (maxVal1 - baseR) * 0.5
		Variable lightG1 = baseG + (maxVal1 - baseG) * 0.5
		Variable lightB1 = baseB + (maxVal1 - baseB) * 0.5
		// condIdx=0condIdx=numConditions-1
		Variable t1 = 0
		if(numConditions > 1)
			t1 = condIdx / (numConditions - 1)
		endif
		Variable colorR = darkR1 + (lightR1 - darkR1) * t1
		Variable colorG = darkG1 + (lightG1 - darkG1) * t1
		Variable colorB = darkB1 + (lightB1 - darkB1) * t1
		
		// Condition: ●■▲◆▼
		Make/FREE markerTypes = {19, 16, 17, 18, 23}
		Variable markerNum = markerTypes[mod(condIdx, 5)]
		
		if(firstTrace)
			AppendToGraph avgW vs TL_time_min
			firstTrace = 0
		else
			AppendToGraph/C=(colorR, colorG, colorB) avgW vs TL_time_min
		endif
		
		ErrorBars $avgName SHADE={0,0,(0,0,0,0),(0,0,0,0)}, wave=(semW, semW)
		ModifyGraph mode($avgName)=4, marker($avgName)=markerNum, msize($avgName)=6
		ModifyGraph lsize($avgName)=1.5
		ModifyGraph rgb($avgName)=(colorR, colorG, colorB)
	endfor
	
	// 
	ModifyGraph tick=2, mirror=0, fStyle=1, fSize=14, font="Arial"
	ModifyGraph lowTrip(left)=0.0001
	ModifyGraph width={Aspect, 1.618}
	
	// Y
	// graphTitle = "D (immobile)" → "D\r(immobile)" 
	String yLabel = ""
	Variable parenPos = strsearch(graphTitle, "(", 0)
	if(parenPos > 0)
		String paramPart = graphTitle[0, parenPos-2]  // "D" ()
		String statePart = graphTitle[parenPos, strlen(graphTitle)-1]  // "(immobile)"
		if(strlen(modeLabel) > 0)
			yLabel = "\\F'Arial'\\Z14" + modeLabel + paramPart + "\r" + statePart
		else
			yLabel = "\\F'Arial'\\Z14" + paramPart + "\r" + statePart
		endif
	else
		yLabel = "\\F'Arial'\\Z14" + modeLabel + graphTitle
	endif
	Label left yLabel
	Label bottom "\\F'Arial'\\Z14Time (min)"
	
	DoWindow/T $winName, "Time Course: " + modeLabel + graphTitle
	
	// L1, L2...
	String legendStr = ""
	for(condIdx = 0; condIdx < numConditions; condIdx += 1)
		String traceName = modePrefix + prefix + "_avg_C" + num2str(condIdx + 1)
		// L1, L2, ...
		String condLabel = "L" + num2str(condIdx + 1)
		legendStr += "\\s(" + traceName + ") " + condLabel
		if(condIdx < numConditions - 1)
			legendStr += "\r"
		endif
	endfor
	Legend/C/N=text0/J/A=RT/B=1/F=0 legendStr
	
	Print "  Created: " + winName
End

// -----------------------------------------------------------------------------
// TL_CreateLinePlotFromData2 - Line PlotyAxisLabel
// Summary Plot
// -----------------------------------------------------------------------------
Function TL_CreateLinePlotFromData2(prefix, sampleList, graphTitle, yAxisLabel, mode)
	String prefix
	Wave/T sampleList
	String graphTitle
	String yAxisLabel
	Variable mode
	
	Variable numConditions = DimSize(sampleList, 0)
	Variable numTimePoints = DimSize(sampleList, 1)
	
	NVAR/Z TimeInterval = root:TimeInterval
	NVAR/Z TimeStimulation = root:TimeStimulation
	NVAR/Z Dstate = root:Dstate
	
	Variable interval = 10
	if(NVAR_Exists(TimeInterval) && TimeInterval > 0)
		interval = TimeInterval
	endif
	
	Variable stimTime = 0
	if(NVAR_Exists(TimeStimulation))
		stimTime = TimeStimulation
	endif
	
	Variable numStates = 3
	if(NVAR_Exists(Dstate) && Dstate > 0)
		numStates = Dstate
	endif
	
	// 
	Variable isColMode = TL_IsColocalizationMode()
	
	// 
	String modePrefix = ""
	String modeLabel = ""
	switch(mode)
		case 0:
			modePrefix = ""
			modeLabel = ""
			break
		case 1:
			modePrefix = "n"
			modeLabel = "Normalized "
			break
		case 2:
			modePrefix = "d"
			modeLabel = "Δ"
			break
	endswitch
	
	// wave: prefix_sampleName
	String testName
	testName = modePrefix + prefix + "_" + sampleList[0][0]
	Wave/Z testWave = $testName
	if(!WaveExists(testWave))
		return 0
	endif
	
	// 
	Variable stateNum = TL_GetStateNumFromPrefix(prefix)
	
	Variable baseR, baseG, baseB
	// Area/NumPts(50%)
	if(StringMatch(prefix, "Area*") || StringMatch(prefix, "NumPts*"))
		baseR = 32768
		baseG = 32768
		baseB = 32768
	else
		GetDstateColor(stateNum, baseR, baseG, baseB)
	endif
	
	// 
	Make/O/D/N=(numTimePoints) TL_time_min = p * interval - stimTime
	
	// 
	String winName = "Line_" + modePrefix + prefix
	DoWindow/K $winName
	Display/K=1/N=$winName
	
	Variable firstTrace = 1
	Variable condIdx, tpIdx
	String sampleName, procName
	
	for(condIdx = 0; condIdx < numConditions; condIdx += 1)
		String avgName = modePrefix + prefix + "_avg_C" + num2str(condIdx + 1)
		String semName = modePrefix + prefix + "_sem_C" + num2str(condIdx + 1)
		
		Make/O/D/N=(numTimePoints) $avgName, $semName
		Wave avgW = $avgName
		Wave semW = $semName
		
		for(tpIdx = 0; tpIdx < numTimePoints; tpIdx += 1)
			sampleName = sampleList[condIdx][tpIdx]
			// : prefix_sampleNameCompareD/CompareL
			procName = modePrefix + prefix + "_" + sampleName
			Wave/Z procWave = $procName
			
			if(WaveExists(procWave) && numpnts(procWave) > 0)
				WaveStats/Q procWave
				avgW[tpIdx] = V_avg
				semW[tpIdx] = V_sem
			else
				avgW[tpIdx] = NaN
				semW[tpIdx] = NaN
			endif
		endfor
		
		// : Intensity histogram
		// : 40%
		Variable darkR2 = baseR * 0.4
		Variable darkG2 = baseG * 0.4
		Variable darkB2 = baseB * 0.4
		// : 50%
		Variable maxVal2 = 65535
		Variable lightR2 = baseR + (maxVal2 - baseR) * 0.5
		Variable lightG2 = baseG + (maxVal2 - baseG) * 0.5
		Variable lightB2 = baseB + (maxVal2 - baseB) * 0.5
		// condIdx=0condIdx=numConditions-1
		Variable t2 = 0
		if(numConditions > 1)
			t2 = condIdx / (numConditions - 1)
		endif
		Variable colorR = darkR2 + (lightR2 - darkR2) * t2
		Variable colorG = darkG2 + (lightG2 - darkG2) * t2
		Variable colorB = darkB2 + (lightB2 - darkB2) * t2
		
		// Condition: ●■▲◆▼
		Make/FREE markerTypes = {19, 16, 17, 18, 23}
		Variable markerNum = markerTypes[mod(condIdx, 5)]
		
		if(firstTrace)
			AppendToGraph avgW vs TL_time_min
			firstTrace = 0
		else
			AppendToGraph/C=(colorR, colorG, colorB) avgW vs TL_time_min
		endif
		
		ErrorBars $avgName SHADE={0,0,(0,0,0,0),(0,0,0,0)}, wave=(semW, semW)
		ModifyGraph mode($avgName)=4, marker($avgName)=markerNum, msize($avgName)=6
		ModifyGraph lsize($avgName)=1.5
		ModifyGraph rgb($avgName)=(colorR, colorG, colorB)
	endfor
	
	// 
	ModifyGraph tick=2, mirror=0, fStyle=1, fSize=14, font="Arial"
	ModifyGraph lowTrip(left)=0.0001
	ModifyGraph width={Aspect, 1.618}
	
	// YyAxisLabel
	String yLabel = ""
	if(strlen(modeLabel) > 0)
		// yAxisLabel\rmodeLabel
		Variable crPos = strsearch(yAxisLabel, "\r", 0)
		if(crPos > 0)
			yLabel = "\\F'Arial'\\Z14" + modeLabel + yAxisLabel[0, crPos-1] + "\r" + yAxisLabel[crPos+1, strlen(yAxisLabel)-1]
		else
			yLabel = "\\F'Arial'\\Z14" + modeLabel + yAxisLabel
		endif
	else
		yLabel = "\\F'Arial'\\Z14" + yAxisLabel
	endif
	Label left yLabel
	Label bottom "\\F'Arial'\\Z14Time (min)"
	
	DoWindow/T $winName, "Time Course: " + modeLabel + graphTitle
	
	// L1, L2...
	String legendStr = ""
	for(condIdx = 0; condIdx < numConditions; condIdx += 1)
		String traceName = modePrefix + prefix + "_avg_C" + num2str(condIdx + 1)
		// L1, L2, ...
		String condLabel = "L" + num2str(condIdx + 1)
		legendStr += "\\s(" + traceName + ") " + condLabel
		if(condIdx < numConditions - 1)
			legendStr += "\r"
		endif
	endfor
	Legend/C/N=text0/J/A=RT/B=1/F=0 legendStr
	
	Print "  Created: " + winName
End
