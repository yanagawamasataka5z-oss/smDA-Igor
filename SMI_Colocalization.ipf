#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3

// =============================================================================
// SMI_Colocalization.ipf
// Single Molecule Imaging Analysis Suite - Colocalization Analysis Module
// Version 2.9.0 - Added Compare mode popups, List_C1/C2 naming, Ontime Simple, Reaction Rate
// =============================================================================

// -----------------------------------------------------------------------------
// Button Control Functions (Panel Callbacks)
// -----------------------------------------------------------------------------

// Make Target Lists 
Function ColMakeListProc(ctrlName) : ButtonControl
	String ctrlName
	
	Print "=== Make Target Lists ==="
	MakeFolderListCol()
End

// Analyze Colocalization Individual Analysis
Function ColAnalyzeProc(ctrlName) : ButtonControl
	String ctrlName
	
	Print "=== Analyze Colocalization (Full Pipeline) ==="
	ColAnalyzeFromList()
End

// Compare Parameters 
Function ColCompareProc(ctrlName) : ButtonControl
	String ctrlName
	
	Print "=== Compare Colocalization Parameters ==="
	ColCompareAll()
End

// Find 
Function ColFindProc(ctrlName) : ButtonControl
	String ctrlName
	
	Print "=== Find Colocalization ==="
	ColFindFromList()
End

// Trajectory 
Function ColTrajectoryProc(ctrlName) : ButtonControl
	String ctrlName
	
	Print "=== Colocalization Trajectory ==="
	ColTrajectoryFromList()
End

// Intensity 
Function ColIntensityProc(ctrlName) : ButtonControl
	String ctrlName
	
	Print "=== Colocalization Intensity ==="
	ColIntensityFromList()
End

// Diffusion 
Function ColDiffusionProc(ctrlName) : ButtonControl
	String ctrlName
	
	Print "=== Colocalization Diffusion ==="
	ColDiffusionFromList()
End

// On-time 
Function ColOntimeProc(ctrlName) : ButtonControl
	String ctrlName
	
	Print "=== Colocalization On-time ==="
	ColOntimeFromList()
End

// On-rate 
Function ColOnrateProc(ctrlName) : ButtonControl
	String ctrlName
	
	Print "=== Colocalization On-rate ==="
	ColOnrateFromList()
End

// -----------------------------------------------------------------------------
// Average Histograms Button Functions
// -----------------------------------------------------------------------------

// Average Histograms 
Function ColAvgHistProc(ctrlName) : ButtonControl
	String ctrlName
	
	Print "=== Average Histograms (All) ==="
	ColAvgDistanceFromList()
	ColAvgIntensityFromList()
	ColAvgDiffusionFromList()
	ColAvgOntimeFromList()
	ColAvgOnrateFromList()
End

// Average Distance 
Function ColAvgDistanceProc(ctrlName) : ButtonControl
	String ctrlName
	
	Print "=== Average Distance Histogram ==="
	ColAvgDistanceFromList()
End

// Average Intensity 
Function ColAvgIntensityProc(ctrlName) : ButtonControl
	String ctrlName
	
	Print "=== Average Intensity Histogram ==="
	ColAvgIntensityFromList()
End

// Average Diffusion 
Function ColAvgDiffusionProc(ctrlName) : ButtonControl
	String ctrlName
	
	Print "=== Average Diffusion Histogram ==="
	ColAvgDiffusionFromList()
End

// Average On-time 
Function ColAvgOntimeProc(ctrlName) : ButtonControl
	String ctrlName
	
	Print "=== Average On-time Histogram ==="
	ColAvgOntimeFromList()
End

// Average On-rate 
Function ColAvgOnrateProc(ctrlName) : ButtonControl
	String ctrlName
	
	Print "=== Average On-rate Histogram ==="
	ColAvgOnrateFromList()
End

// -----------------------------------------------------------------------------
// Compare Parameters Button Functions
// -----------------------------------------------------------------------------

// Compare Affinity 
Function ColCmpAffinityProc(ctrlName) : ButtonControl
	String ctrlName
	
	NVAR ColAffinityParam = root:ColAffinityParam
	NVAR ColWeightingMode = root:ColWeightingMode
	Variable param = ColAffinityParam  // 0=Kb, 1=Density, 2=Distance
	Variable weighting = ColWeightingMode  // 0=Particle, 1=Molecule
	
	String weightStr = SelectString(weighting, "Particle", "Molecule")
	
	if(param == 0)
		// Kb
		Print "=== Compare Affinity: Kb (" + weightStr + ") ==="
		if(weighting == 0)
			ColCompareKbByState()        // Kb by state (Particle)
		else
			ColCompareKbByStateMol()     // Kb by state (Molecule)
		endif
	elseif(param == 1)
		// Density
		Print "=== Compare Affinity: Density (" + weightStr + ") ==="
		if(weighting == 0)
			ColCompareParticleDensity()  // Particle Density by state
		else
			ColCompareMolecularDensity() // Molecular Density by state
		endif
	else
		// Distance
		Print "=== Compare Affinity: Distance ==="
		ColCompareAffinity()         // Distance ()
	endif
End

// Compare Intensity 
Function ColCmpIntensityProc(ctrlName) : ButtonControl
	String ctrlName
	
	NVAR ColIntensityMode = root:ColIntensityMode
	Variable mode = ColIntensityMode

	if(mode == 0)
		// Simple mode (Int/MeanInt)
		Print "=== Compare Intensity (Simple) ==="
		ColCompareOsizeCol()
	else
		// Fitting mode
		Print "=== Compare Intensity (Fitting) ==="
		ColCompareIntensity()
	endif
End

// === Popup Menu Procedures ===
Function ColWeightingModeProc(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	NVAR ColWeightingMode = root:ColWeightingMode
	ColWeightingMode = popNum - 1  // 0=Particle, 1=Molecule
End

Function ColAffinityParamProc(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	NVAR ColAffinityParam = root:ColAffinityParam
	ColAffinityParam = popNum - 1  // 0=Kb, 1=Density, 2=Distance
End

Function ColIntensityModeProc(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	NVAR ColIntensityMode = root:ColIntensityMode
	ColIntensityMode = popNum - 1
End

Function ColDiffusionModeProc(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	NVAR ColDiffusionMode = root:ColDiffusionMode
	ColDiffusionMode = popNum - 1
End

Function ColOntimeModeProc(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	NVAR ColOntimeMode = root:ColOntimeMode
	ColOntimeMode = popNum - 1
End

Function ColOnrateModeProc(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	NVAR ColOnrateMode = root:ColOnrateMode
	ColOnrateMode = popNum - 1
End

Function ColChannelModeProc(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	NVAR ColOutputChannel = root:ColOutputChannel
	ColOutputChannel = popNum - 1  // 0=Both, 1=C1, 2=C2
End

// Area normalization mode callback: 0=Min, 1=Max
Function ColAreaModeProc(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	Variable/G root:ColAreaMode = popNum - 1  // 0=Min, 1=Max
End

// -----------------------------------------------------------------------------
// GetOutputChannelList - Output
// -----------------------------------------------------------------------------
// useECSuffix: 1 = "_C1E;_C2E" , 0 = "_C1;_C2" 
Function/S GetOutputChannelList(useECSuffix)
	Variable useECSuffix
	
	NVAR ColOutputChannel = root:ColOutputChannel
	Variable mode = ColOutputChannel
	
	String suffix1, suffix2
	if(useECSuffix)
		suffix1 = "_C1E"
		suffix2 = "_C2E"
	else
		suffix1 = "_C1"
		suffix2 = "_C2"
	endif
	
	if(mode == 0)  // Both
		return suffix1 + ";" + suffix2
	elseif(mode == 1)  // C1 only
		return suffix1
	else  // C2 only
		return suffix2
	endif
End

// GetChannelLabel - suffix
Function/S GetChannelLabel(chSuffix)
	String chSuffix
	
	if(StringMatch(chSuffix, "*C1*"))
		return "Ch1"
	else
		return "Ch2"
	endif
End

// GetChannelIndex - suffix (0=C1, 1=C2)
Function GetChannelIndex(chSuffix)
	String chSuffix
	
	if(StringMatch(chSuffix, "*C1*"))
		return 0
	else
		return 1
	endif
End

// Compare D-state 
Function ColCmpDiffusionProc(ctrlName) : ButtonControl
	String ctrlName
	
	NVAR ColDiffusionMode = root:ColDiffusionMode
	Variable mode = ColDiffusionMode

	if(mode == 0)
		// per Total mode (Absolute HMMP = Colocalization %)
		Print "=== Compare D-state Population (per Total) ==="
		ColCompareAbsoluteHMMP()
	elseif(mode == 1)
		// per Col mode (relative HMMP within colocalized)
		Print "=== Compare D-state Population (per Col) ==="
		ColCompareDiffusion()
	else
		// Steps mode (number of steps per state)
		Print "=== Compare D-state Steps ==="
		ColCompareSteps()
	endif

	// Steps Density (ColSteps / Area) - always run
	Print "=== Compare Steps Density ==="
	ColCompareStepsDensity()
End

// Compare On-time
Function ColCmpOntimeProc(ctrlName) : ButtonControl
	String ctrlName
	
	NVAR ColOntimeMode = root:ColOntimeMode
	Variable mode = ColOntimeMode

	if(mode == 0)
		// Simple mode
		Print "=== Compare On-time (Simple Mean) ==="
		ColCompareOntimeSimple()
	else
		// Fitting mode
		Print "=== Compare On-time (Fitting) ==="
		ColCompareOntime()
	endif
End

// Compare On-rate 
Function ColCmpOnrateProc(ctrlName) : ButtonControl
	String ctrlName
	
	NVAR ColOnrateMode = root:ColOnrateMode
	Variable mode = ColOnrateMode

	if(mode == 0)
		// Event rate mode
		Print "=== Compare On-rate (On-event Rate) ==="
		ColCompareOnrate()
	else
		// Reaction rate mode
		Print "=== Compare On-rate (k_on) ==="
		ColCompareReactionRate()
	endif
End

// -----------------------------------------------------------------------------
// Target List Functions
// -----------------------------------------------------------------------------

// Get count of valid cell folders for a sample
// Directly counts folders without creating CellFolderList wave
Function GetCellCount(sampleName)
	String sampleName
	
	// Determine folder structure
	String baseFolder
	if(DataFolderExists("root:Samples:" + sampleName))
		baseFolder = "root:Samples:" + sampleName
	else
		baseFolder = "root:" + sampleName
	endif
	
	if(!DataFolderExists(baseFolder))
		return 0
	endif
	
	// Count sequential cell folders
	Variable cellIdx = 1
	do
		String expectedName = sampleName + num2str(cellIdx)
		String checkPath = baseFolder + ":" + expectedName
		if(!DataFolderExists(checkPath))
			break
		endif
		cellIdx += 1
	while(cellIdx < 1000)  // Safety limit
	
	return cellIdx - 1
End

// Get cell folder name by index (0-based)
// Directly generates folder name without creating CellFolderList wave
Function/S GetCellFolderName(sampleName, cellIndex)
	String sampleName
	Variable cellIndex
	
	// Cell folder name is simply SampleName + (index + 1)
	String expectedName = sampleName + num2str(cellIndex + 1)
	
	// Verify the folder exists
	String baseFolder
	if(DataFolderExists("root:Samples:" + sampleName))
		baseFolder = "root:Samples:" + sampleName
	else
		baseFolder = "root:" + sampleName
	endif
	
	String checkPath = baseFolder + ":" + expectedName
	if(DataFolderExists(checkPath))
		return expectedName
	endif
	
	return ""
End

// Make Folder List for Colocalization
Function MakeFolderListCol()
	String savedDF = GetDataFolder(1)
	SetDataFolder root:
	
	// Get folder list - check both root: and root:Samples:
	String folderList = ""
	String tempList
	
	// Check root:Samples: first (SMI Suite standard)
	if(DataFolderExists("root:Samples"))
		SetDataFolder root:Samples
		tempList = ReplaceString(",", StringByKey("FOLDERS", DataFolderDir(1)), ";")
		folderList = tempList
	endif
	
	// Also check root: (original format)
	SetDataFolder root:
	tempList = ReplaceString(",", StringByKey("FOLDERS", DataFolderDir(1)), ";")
	tempList = ListMatch(tempList, "!Packages*", ";")
	tempList = ListMatch(tempList, "!Samples*", ";")
	tempList = ListMatch(tempList, "!Col*", ";")
	tempList = ListMatch(tempList, "!EC*", ";")
	folderList += tempList
	
	folderList = SortList(folderList, ";")
	
	if(strlen(folderList) == 0)
		DoAlert 0, "No sample folders found"
		SetDataFolder $savedDF
		return -1
	endif
	
	// Prompt user for targets
	String selectedFolder = ""
	String target1 = ""
	String target2 = ""
	
	Prompt selectedFolder, "Sample list (for reference)", popup, folderList
	Prompt target1, "Target_1 (keyword for Ch1)"
	Prompt target2, "Target_2 (keyword for Ch2)"
	DoPrompt "Enter targets for colocalization analysis", selectedFolder, target1, target2
	
	if(V_Flag != 0)
		Print "User Canceled"
		SetDataFolder $savedDF
		return -1
	endif
	
	// Create Folder_A list (matching target1)
	String matchListA = ListMatch(folderList, "*" + target1 + "*")
	if(strlen(matchListA) == 0)
		Print "No folders found matching target1: " + target1
		SetDataFolder $savedDF
		return -1
	endif
	
	Make/O/T/N=(ItemsInList(matchListA)) root:List_C1
	Wave/T List_C1 = root:List_C1
	Variable i
	for(i = 0; i < ItemsInList(matchListA); i += 1)
		List_C1[i] = StringFromList(i, matchListA)
	endfor
	Print "Target_1: ", numpnts(List_C1), " folders found"
	
	// Create Folder_B list (matching target2)
	String matchListB = ListMatch(folderList, "*" + target2 + "*")
	if(strlen(matchListB) == 0)
		Print "No folders found matching target2: " + target2
		SetDataFolder $savedDF
		return -1
	endif
	
	Make/O/T/N=(ItemsInList(matchListB)) root:List_C2
	Wave/T List_C2 = root:List_C2
	for(i = 0; i < ItemsInList(matchListB); i += 1)
		List_C2[i] = StringFromList(i, matchListB)
	endfor
	Print "Target_2: ", numpnts(List_C2), " folders found"
	
	// Validate lists
	if(numpnts(List_C1) != numpnts(List_C2))
		Print "Warning: Folder counts do not match! A=" + num2str(numpnts(List_C1)) + ", B=" + num2str(numpnts(List_C2))
	endif
	
	// Display the lists
	Edit/K=1 root:List_C1, root:List_C2
	
	SetDataFolder $savedDF
	return 0
End

// -----------------------------------------------------------------------------
// Colocalization Analysis Functions
// -----------------------------------------------------------------------------

// Analyze Colocalization from List - Full Pipeline
// Calls: FindCol → Trajectory → Intensity → Diffusion → On-time → On-rate → Stats
Function ColAnalyzeFromList()
	String savedDF = GetDataFolder(1)
	
	Wave/T/Z List_C1 = root:List_C1
	Wave/T/Z List_C2 = root:List_C2
	
	if(!WaveExists(List_C1) || !WaveExists(List_C2))
		DoAlert 0, "Please create List_C1 and List_C2 first using 'Make Target Lists'"
		return -1
	endif
	
	Variable numPairs = min(numpnts(List_C1), numpnts(List_C2))
	if(numPairs == 0)
		DoAlert 0, "No samples found in lists"
		return -1
	endif
	
	Printf "========================================\r"
	Printf "Full Colocalization Analysis Pipeline\r"
	Printf "Number of pairs: %d\r", numPairs
	Printf "========================================\r"
	
	Variable totalStartTime = DateTime
	Variable stepTime
	
	// Step 1: Find Colocalization
	Printf "\r=== Step 1/7: Find Colocalization ===\r"
	stepTime = DateTime
	ColFindFromList()
	Printf "Find Colocalization: %.1f sec\r", DateTime - stepTime
	
	// Step 2: Trajectory
	Printf "\r=== Step 2/7: Trajectory ===\r"
	stepTime = DateTime
	ColTrajectoryFromList()
	Printf "Trajectory: %.1f sec\r", DateTime - stepTime
	
	// Step 3: Intensity
	Printf "\r=== Step 3/7: Intensity ===\r"
	stepTime = DateTime
	ColIntensityFromList()
	Printf "Intensity: %.1f sec\r", DateTime - stepTime
	
	// Step 4: Diffusion
	Printf "\r=== Step 4/7: Diffusion ===\r"
	stepTime = DateTime
	ColDiffusionFromList()
	Printf "Diffusion: %.1f sec\r", DateTime - stepTime
	
	// Step 5: On-time
	Printf "\r=== Step 5/7: On-time ===\r"
	stepTime = DateTime
	ColOntimeFromList()
	Printf "On-time: %.1f sec\r", DateTime - stepTime
	
	// Step 6: On-rate
	Printf "\r=== Step 6/7: On-rate ===\r"
	stepTime = DateTime
	ColOnrateFromList()
	Printf "On-rate: %.1f sec\r", DateTime - stepTime
	
	// Step 7: Statistics (Matrix & Results)
	Printf "\r=== Step 7/7: Statistics ===\r"
	stepTime = DateTime
	ColStatsFromList()
	Printf "Statistics: %.1f sec\r", DateTime - stepTime
	
	Printf "========================================\r"
	Printf "Full Pipeline Complete (Total: %.1f sec)\r", DateTime - totalStartTime
	Printf "========================================\r"
	
	SetDataFolder $savedDF
	return 0
End

// Find Colocalization only (without subsequent analysis)
Function ColFindFromList()
	String savedDF = GetDataFolder(1)
	
	Wave/T/Z List_C1 = root:List_C1
	Wave/T/Z List_C2 = root:List_C2
	
	if(!WaveExists(List_C1) || !WaveExists(List_C2))
		DoAlert 0, "Please create List_C1 and List_C2 first using 'Make Target Lists'"
		return -1
	endif
	
	Variable numPairs = min(numpnts(List_C1), numpnts(List_C2))
	if(numPairs == 0)
		DoAlert 0, "No samples found in lists"
		return -1
	endif
	
	// Col/EC
	InitColFolders()
	
	Printf "========================================\r"
	Printf "Find Colocalization (Detection Only)\r"
	Printf "Number of pairs: %d\r", numPairs
	Printf "========================================\r"
	
	Variable totalStartTime = DateTime
	Variable i
	String sampleName1, sampleName2
	
	for(i = 0; i < numPairs; i += 1)
		sampleName1 = List_C1[i]
		sampleName2 = List_C2[i]
		
		Printf "\r--- Pair %d/%d: %s vs %s ---\r", i+1, numPairs, sampleName1, sampleName2
		ColFindPair(sampleName1, sampleName2)
	endfor
	
	Printf "========================================\r"
	Printf "Find Colocalization Complete (Total: %.1f sec)\r", DateTime - totalStartTime
	Printf "========================================\r"
	
	SetDataFolder $savedDF
	return 0
End

// Find colocalization for a single pair (detection + EC folder creation)
Function ColFindPair(sampleName1, sampleName2)
	String sampleName1, sampleName2
	
	String savedDF = GetDataFolder(1)
	
	// Determine folder structure
	String baseFolder1, baseFolder2
	if(DataFolderExists("root:Samples:" + sampleName1))
		baseFolder1 = "root:Samples:" + sampleName1
		baseFolder2 = "root:Samples:" + sampleName2
	else
		baseFolder1 = "root:" + sampleName1
		baseFolder2 = "root:" + sampleName2
	endif
	
	if(!DataFolderExists(baseFolder1) || !DataFolderExists(baseFolder2))
		Printf "Warning: Folder not found\r"
		return -1
	endif
	
	// Create TraceMatrix_col for both samples
	MakeTraceMatrixCol(sampleName1)
	MakeTraceMatrixCol(sampleName2)
	
	// Run colocalization detection
	Colocalization_HMM(sampleName1, sampleName2)
	
	// Convert ColMatrix to individual waves (Col folder)
	MakeColWave_HMM(sampleName1, sampleName2)
	
	// Create D-state specific analysis waves (Col folder)
	MakeAnalysisWavesCol_HMM(sampleName1, sampleName2)
	
	// Extract colocalized data to EC folder
	ExtractColocalizationAll_HMM(sampleName1, sampleName2)
	
	SetDataFolder $savedDF
	return 0
End

// Analyze a single pair of samples (full pipeline)
Function ColAnalyzePair(sampleName1, sampleName2)
	String sampleName1, sampleName2
	
	String savedDF = GetDataFolder(1)
	
	// Determine folder structure
	String baseFolder1, baseFolder2
	if(DataFolderExists("root:Samples:" + sampleName1))
		baseFolder1 = "root:Samples:" + sampleName1
		baseFolder2 = "root:Samples:" + sampleName2
	else
		baseFolder1 = "root:" + sampleName1
		baseFolder2 = "root:" + sampleName2
	endif
	
	if(!DataFolderExists(baseFolder1) || !DataFolderExists(baseFolder2))
		Printf "Warning: Folder not found\r"
		return -1
	endif
	
	// Create TraceMatrix_col for both samples
	MakeTraceMatrixCol(sampleName1)
	MakeTraceMatrixCol(sampleName2)
	
	// Run colocalization detection
	Colocalization_HMM(sampleName1, sampleName2)
	
	// Convert ColMatrix to individual waves
	MakeColWave_HMM(sampleName1, sampleName2)
	
	// Create D-state specific analysis waves
	MakeAnalysisWavesCol_HMM(sampleName1, sampleName2)
	
	// Extract and visualize colocalization
	ExtractColocalizationAll_HMM(sampleName1, sampleName2)
	
	// Create result matrix
	MakeResultMatrixCol_HMM(sampleName1, sampleName2)
	
	// Calculate statistics
	StatResultMatrixCol_HMM(sampleName1, sampleName2)
	
	SetDataFolder $savedDF
	return 0
End

// Create output folder structure safely
static Function ColCreateOutputFolders(sampleName1, sampleName2)
	String sampleName1, sampleName2
	
	String savedDF = GetDataFolder(1)
	
	// 
	String colBase = GetColBasePath()
	
	// Create Col folder (e.g., root:Col1)
	NewDataFolder/O $colBase
	
	// Create sample subfolders
	NewDataFolder/O $(colBase + ":" + sampleName1)
	NewDataFolder/O $(colBase + ":" + sampleName2)
	
	SetDataFolder $savedDF
End

// Create cell subfolder safely
static Function ColCreateCellFolder(sampleName, folderName)
	String sampleName, folderName
	
	String savedDF = GetDataFolder(1)
	
	// 
	String colBase = GetColBasePath()
	String parentPath = colBase + ":" + sampleName
	
	if(DataFolderExists(parentPath))
		SetDataFolder $parentPath
		NewDataFolder/O $folderName
	endif
	
	SetDataFolder $savedDF
End

// -----------------------------------------------------------------------------
// TraceMatrix_col Creation for a single cell
// Converts TraceMatrix (row=data points, ROI-sorted) to TraceMatrix_col (row=frame number)
// -----------------------------------------------------------------------------

Function MakeTraceMatrixColSingleCell(cellFolder)
	String cellFolder
	
	// Get framerate for time conversion
	NVAR/Z framerate = root:framerate
	Variable hasFramerate = NVAR_Exists(framerate) && framerate > 0
	
	Wave/Z TraceMatrix
	if(!WaveExists(TraceMatrix))
		return -1
	endif
	
	// Delete existing TraceMatrix_col to free memory
	Wave/Z existingCol = TraceMatrix_col
	if(WaveExists(existingCol))
		KillWaves/Z existingCol
	endif
	
	Variable numRows = DimSize(TraceMatrix, 0)
	Variable numCols = DimSize(TraceMatrix, 1)
	
	// Extract ROI column
	Make/O/N=(numRows) tempROI
	tempROI = TraceMatrix[p][0]
	
	Variable numROI = WaveMax(tempROI)
	if(numROI <= 0)
		KillWaves/Z tempROI
		return -1
	endif
	
	// First pass: find maximum frame number across all data points
	// TraceMatrix[i][2] is real time (seconds) after MakeTraceMatrixTimeBase
	Variable maxFrameNum = 0
	Variable i, rawTimeVal, frameNum
	
	for(i = 0; i < numRows; i += 1)
		rawTimeVal = TraceMatrix[i][2]
		if(hasFramerate && framerate > 0)
			frameNum = round(rawTimeVal / framerate)
		else
			frameNum = round(rawTimeVal)
		endif
		if(frameNum > maxFrameNum)
			maxFrameNum = frameNum
		endif
	endfor
	
	// Sanity check: limit maximum size to prevent memory issues
	if(maxFrameNum > 100000)
		Printf "Warning: maxFrameNum=%d is very large for %s, limiting to 100000\r", maxFrameNum, cellFolder
		maxFrameNum = 100000
	endif
	
	// Create TraceMatrix_col with correct dimensions (row=frame, columns=ROI×8)
	// Use single precision (no /D flag) to match original and save memory
	Make/O/N=(maxFrameNum + 1, numROI * 8) TraceMatrix_col = NaN
	
	// Second pass: place each data point at its correct frame row
	Variable roiIdx, colIdx
	
	for(i = 0; i < numRows; i += 1)
		roiIdx = TraceMatrix[i][0] - 1  // ROI is 1-indexed
		if(roiIdx < 0 || roiIdx >= numROI)
			continue
		endif
		
		rawTimeVal = TraceMatrix[i][2]
		if(hasFramerate && framerate > 0)
			frameNum = round(rawTimeVal / framerate)
		else
			frameNum = round(rawTimeVal)
		endif
		
		// Bounds check
		if(frameNum < 0 || frameNum > maxFrameNum)
			continue
		endif
		
		// Copy 8 columns for this data point to the correct frame row
		for(colIdx = 0; colIdx < 8 && colIdx < numCols; colIdx += 1)
			TraceMatrix_col[frameNum][roiIdx * 8 + colIdx] = TraceMatrix[i][colIdx]
		endfor
		
		// Store frame number in Rtime column (col 2)
		TraceMatrix_col[frameNum][roiIdx * 8 + 2] = frameNum
	endfor
	
	KillWaves/Z tempROI
	
	return 0
End

// MakeTraceMatrixCol - kept for backward compatibility but now only creates on-demand
Function MakeTraceMatrixCol(sampleName)
	String sampleName
	
	// This function is now a no-op
	// TraceMatrix_col is created on-demand in Colocalization_HMM
	// to minimize memory usage
	return 0
End

// -----------------------------------------------------------------------------
// Core Colocalization Detection (Optimized - same structure as original)
// -----------------------------------------------------------------------------

Function Colocalization_HMM(SampleName1, SampleName2) //PA()2
    String SampleName1, SampleName2
    String FolderName1, MName1 
    String FolderName2, MName2
    variable m = 0  //folder counter
    
    // 
    String colBase = GetColBasePath()
    
    // Use GetCellFolderList instead of CountObjects for robust cell counting
    Variable n = GetCellCount(SampleName1)
    if(n == 0)
        Print "Warning: No valid cell folders found for " + SampleName1
        return -1
    endif
    
    SetDataFolder root:$(SampleName1)
    NVAR framerate = root:framerate  //[sec]
    NVAR PA = root:MaxDistance // : nm
    NVAR cSameHMMD = root:cSameHMMD // 
    NVAR MaxDratio = root:MaxDratio // : 
    NVAR ColMinFrame = root:ColMinFrame //: ColMinFrame
    NVAR ColRoom = root:ColRoom //: 10101
    variable PAum=PA/1000 //nm -> um    
   
      NewDataFolder/O $colBase
      NewDataFolder/O $(colBase + ":" + SampleName1)
      NewDataFolder/O $(colBase + ":" + SampleName2)
         
     Do
        FolderName1 = GetCellFolderName(SampleName1, m)
        if(strlen(FolderName1) == 0)
            break  // No more valid cell folders
        endif
        
        // Verify source folder exists
        if(!DataFolderExists("root:" + SampleName1 + ":" + FolderName1))
            m += 1
            continue
        endif
        
        NewDataFolder/O $(colBase + ":" + SampleName1 + ":" + FolderName1)
        SetDataFolder root:$(SampleName1):$(FolderName1)
        
        // Create TraceMatrix_col on-demand for this cell
        MakeTraceMatrixColSingleCell(FolderName1)
        
        wave/Z TraceMatrix_col
        if(!WaveExists(TraceMatrix_col))
            m += 1
            continue
        endif
        
        // Use Duplicate like original (required for same-sample comparison)
        Duplicate/O TraceMatrix_col, Matrix1
        variable ColumnSize1 = DimSize(TraceMatrix_col, 1)
        variable RowSize1 = DimSize(TraceMatrix_col, 0)
        
        // Delete TraceMatrix_col after Duplicate to free memory
        KillWaves/Z TraceMatrix_col
                
        FolderName2 = GetCellFolderName(SampleName2, m)
        if(strlen(FolderName2) == 0)
            KillWaves/Z Matrix1
            break
        endif
        
        // Verify source folder exists
        if(!DataFolderExists("root:" + SampleName2 + ":" + FolderName2))
            KillWaves/Z Matrix1
            m += 1
            continue
        endif
        
        NewDataFolder/O $(colBase + ":" + SampleName2 + ":" + FolderName2)
        SetDataFolder root:$(SampleName2):$(FolderName2)
        
        // Create TraceMatrix_col on-demand for this cell
        MakeTraceMatrixColSingleCell(FolderName2)
        
        wave/Z TraceMatrix_col
        if(!WaveExists(TraceMatrix_col))
            KillWaves/Z Matrix1
            m += 1
            continue
        endif
        
        // Use Duplicate like original
        Duplicate/O TraceMatrix_col, Matrix2
        variable RowSize2 = DimSize(TraceMatrix_col, 0)
        variable ColumnSize2 = DimSize(TraceMatrix_col, 1)
        
        // Delete TraceMatrix_col after Duplicate to free memory
        KillWaves/Z TraceMatrix_col
        
        variable ColumnSize3 = (ColumnSize1/8+ColumnSize2/8)*20
        variable RowSize3 = max(RowSize1, RowSize2)
        Make/O/N=(RowSize3, ColumnSize3), ColMatrix
        ColMatrix=nan
        String ColMName = FolderName1+"_"+FolderName2+"_col"

        variable r   //row counter 1,2
        variable point    //
        variable c1, c2  //column counter
        variable c3 = 0  //column counter ColMatrix
        variable dis //2
        variable C1start=0 //ch1 
        variable C2start=0 //ch2 
        variable ColROI=0  //ROI(1)
 
                    c1 = C1start
                    c2 = C2start
       
             For(c1 = C1start; c1 < ColumnSize1; c1+=8)
                For(c2 = C2start; c2 < ColumnSize2; c2+=8)
                       For (r = 0; r < RowSize3; r+=1)// C1C2
                              
                              //r2
                              // : rMatrixNaN
                              If(r >= RowSize1 || r >= RowSize2 || numtype(Matrix1[r][c1])==2 || numtype(Matrix2[r][c2])==2) //rnan
                              Else
                                dis = ((Matrix1[r][c1+3] - Matrix2[r][c2+3])^2 + (Matrix1[r][c1+4] - Matrix2[r][c2+4])^2)^0.5   
                                  If(dis < PAum) //r
                                     ColMatrix[][c3, c3+7] = Matrix1[p][c1+q-c3]                     //Ch18ColMatrix (c3: 0-7)
                                     ColMatrix[][c3+8, c3+15] = Matrix2[p][c2+q-(c3+8)]           //Ch28ColMatrix (c3: 8-15)
                                     ColMatrix[][c3+16] = ((Matrix1[p][c1+3] - Matrix2[p][c2+3])^2 + (Matrix1[p][c1+4] - Matrix2[p][c2+4])^2)^0.5 //2 (c3: 16)
                                  
                                 //(Displacement)
                                     if(cSameHMMD==0)
                                       
                                       variable D1, D2, Dratio 
                                       
                                       For(point = 0; point < RowSize3; point+=1)
                                         D1 = (ColMatrix[point][c3+6]+0.0000001)^2/(4*framerate)   //Displacement⇒
                                         D2 = (ColMatrix[point][c3+14]+0.0000001)^2/(4*framerate)  //Displacement⇒
                                         
                                         If(D1<D2)
                                           Dratio = D2/D1
                                         Else
                                           Dratio = D1/D2
                                         Endif
                                         
                                         if(ColMatrix[point][c3+16] < PAum && Dratio<MaxDratio)  //2PA 
                                           ColMatrix[point][c3+17] = 1  //(c3: 17, dis<PAum1)
                                         Elseif(numtype(ColMatrix[point][c3+16] )==0)
                                           ColMatrix[point][c3+17] = 0  
                                         Endif   
                                       Endfor
                                        
                                 // (PAumDstate)
                                    elseif(cSameHMMD==1) 
                               
                                       For(point = 0; point < RowSize3; point+=1)
                                           D1 = ColMatrix[point][c3+7]
                                           D2 = ColMatrix[point][c3+15]
                                       
                                        if(ColMatrix[point][c3+16] < PAum && abs(D1-D2)<=0)  //2PA 
                                           ColMatrix[point][c3+17] = 1  //(c3: 17, dis<PAum1)
                                         Elseif(numtype(ColMatrix[point][c3+16] )==0)
                                           ColMatrix[point][c3+17] = 0  
                                         Endif   
                                       Endfor
                                  
                                    endif 
                                     
                                   
                                   //ColRoom(1)
                                     If(ColRoom==1)
                                       
                                       For(point = 1; point < RowSize3-1; point+=1)
                                        if(ColMatrix[point-1][c3+17]==1 && ColMatrix[point+1][c3+17]==1)  //1 
                                           ColMatrix[point][c3+17] = 1  
                                        Endif   
                                       Endfor
                                     
                                     Endif  
                                    
                                    //(c3: 18   11                                       
                                        If(ColMatrix[0][c3+17]==1)//011
                                           ColMatrix[0][c3+18] = 1
                                       Endif
                                       
                                       For(point = 1; point < RowSize3; point+=1)
                                         If(numtype(ColMatrix[point-1][c3+17]) == 2 && ColMatrix[point][c3+17]==1) //point-1nanpoint11
                                           ColMatrix[point][c3+18] = 1
                                         Elseif(ColMatrix[point-1][c3+17] == 0 && ColMatrix[point][c3+17]==1) //point-10point11
                                           ColMatrix[point][c3+18] = 1                                          
                                         Elseif(ColMatrix[point-1][c3+17]==1 && ColMatrix[point][c3+17]==1) //point-11point1+1
                                           ColMatrix[point][c3+18] = ColMatrix[point-1][c3+18]+ 1  //frame
                                         Endif                                            
                                       Endfor
                                       
                                      //(c3: 18 01     
                                       For(point = RowSize3-2; point > 0; point-=1) //
                                         If(ColMatrix[point][c3+17] == 0 && ColMatrix[point+1][c3+17]==1) //point0point+110
                                           ColMatrix[point][c3+18] = 0
                                         Elseif(ColMatrix[point][c3+17] == 0 && ColMatrix[point+1][c3+17]==0) //0-1
                                           ColMatrix[point][c3+18] = ColMatrix[point+1][c3+18]-1   //frame                                  
                                         Endif                                            
                                       Endfor
                                       
                                       //ColMinFrame
                                        
                                        Make/O/N=(RowSize3) ColLength
                                        ColLength = ColMatrix[p][c3+18]
                                        variable MaxLength = wavemax(ColLength)
                                       
                                        If(MaxLength < ColMinFrame)
                                           ColMatrix[][c3+17]=nan
                                        Endif
                                        
                                       
                                       //ROI (c3: 19)
                                        If(ColMatrix[0][c3+18]==1)//011
                                           ColROI += 1
                                           ColMatrix[0][c3+19] = ColROI
                                       Endif
                                       
                                       For(point = 1; point < RowSize3; point+=1)
                                          variable sameROI = ColMatrix[point][c3+18] - ColMatrix[point-1][c3+18]
                                          If(numtype(ColMatrix[point][c3+18]) == 2)  //pointnannan
                                          Elseif(numtype(ColMatrix[point-1][c3+18]) == 2 && numtype(ColMatrix[point][c3+18]) == 0) //point-1nanpoint
                                           ColROI+=1 //+1
                                           ColMatrix[point][c3+19] = ColROI
                                          Elseif(sameROI == 1) //ROI(1)ROI
                                           ColMatrix[point][c3+19] = ColROI //ROI
                                          Elseif(sameROI != 1)//ROI(1)ROI+1
                                           ColROI+=1
                                           ColMatrix[point][c3+19] = ColROI //ROI                                                         
                                          Endif
                                       Endfor
                                     
                                   //
                                       variable Colcount
                                            Colcount = 0 //DF state
                                       
                                       For(point = 0; point < RowSize3; point+=1)
                                                                                  
                                         if(ColMatrix[point][c3+17]==1)  //2DF state 
                                           Colcount+=1 
                                         Endif 
                                           
                                       Endfor  
                                    
                                   //Colcount<120colomun    
                                   If(Colcount<1)   
                                      DeletePoints/M=1 c3, 20, ColMatrix 
                                   Else
                                      c3 += 20 //ColMatrixColMatrix
                                   Endif
                                   
                                     r += RowSize3 // 
                                  Endif
                                Endif 
                                
                           Endfor
                         Endfor  
                   Endfor
        DeletePoints/M=1 c3, ColumnSize3 - c3, ColMatrix
        Duplicate/O ColMatrix, $(colBase + ":" + SampleName1 + ":" + FolderName1 + ":" + ColMName)
        Duplicate/O ColMatrix, $(colBase + ":" + SampleName2 + ":" + FolderName2 + ":" + ColMName)
        
        // Clean up Matrix1, Matrix2, ColMatrix to free memory
        KillWaves/Z Matrix1, Matrix2, ColMatrix
        
        m+=1
    While(m<n)
              
End

// -----------------------------------------------------------------------------
// Wave Conversion Functions
// -----------------------------------------------------------------------------

// =============================================================================
// SeparateStateWavesFromS0 - S0S1Sn
// =============================================================================
// S0 waveDstate_S0S1Sn
// S0S0 = ΣSn 
// 
// :
//   - MakeAnalysisWavesCol_HMM (Col): State
//   - ExtractColocalizationAll_HMM (EC): Colocalize==0
// =============================================================================
Function SeparateStateWavesFromS0(suffix, maxState)
	String suffix      // "_C1", "_C2", "_C1E", "_C2E"
	Variable maxState  // Dstate
	
	// S0 wave
	Wave/Z ROI_S0 = $("ROI_S0" + suffix)
	Wave/Z Rframe_S0 = $("Rframe_S0" + suffix)
	Wave/Z Rtime_S0 = $("Rtime_S0" + suffix)
	Wave/Z Xum_S0 = $("Xum_S0" + suffix)
	Wave/Z Yum_S0 = $("Yum_S0" + suffix)
	Wave/Z Int_S0 = $("Int_S0" + suffix)
	Wave/Z DF_S0 = $("DF_S0" + suffix)
	Wave/Z Dstate_S0 = $("Dstate_S0" + suffix)
	
	if(!WaveExists(ROI_S0) || !WaveExists(Dstate_S0))
		Printf "SeparateStateWavesFromS0: S0 waves not found (suffix=%s)\r", suffix
		return -1
	endif
	
	Variable RowSize = numpnts(ROI_S0)
	Variable s, r
	
	// S1Sn
	for(s = 1; s <= maxState; s += 1)
		String WName0 = "ROI_S" + num2str(s) + suffix
		String WName1 = "Rframe_S" + num2str(s) + suffix
		String WName2 = "Rtime_S" + num2str(s) + suffix
		String WName3 = "Xum_S" + num2str(s) + suffix
		String WName4 = "Yum_S" + num2str(s) + suffix
		String WName5 = "Int_S" + num2str(s) + suffix
		String WName6 = "DF_S" + num2str(s) + suffix
		String WName7 = "Dstate_S" + num2str(s) + suffix
		
		// S0
		Duplicate/O ROI_S0, $WName0
		Duplicate/O Rframe_S0, $WName1
		Duplicate/O Rtime_S0, $WName2
		Duplicate/O Xum_S0, $WName3
		Duplicate/O Yum_S0, $WName4
		Duplicate/O Int_S0, $WName5
		Duplicate/O DF_S0, $WName6
		Duplicate/O Dstate_S0, $WName7
		
		Wave W0 = $WName0
		Wave W1 = $WName1
		Wave W2 = $WName2
		Wave W3 = $WName3
		Wave W4 = $WName4
		Wave W5 = $WName5
		Wave W6 = $WName6
		Wave W7 = $WName7
		
		// Dstate_S0 != s NaN
		for(r = 0; r < RowSize; r += 1)
			if(numtype(Dstate_S0[r]) == 2 || Dstate_S0[r] != s)
				W0[r] = NaN
				W1[r] = NaN
				W2[r] = NaN
				W3[r] = NaN
				W4[r] = NaN
				W5[r] = NaN
				W6[r] = NaN
				W7[r] = NaN
			endif
		endfor
	endfor
	
	return 0
End

// Convert ColMatrix to individual waves (for Ch1 and Ch2)
Function MakeColWave_HMM(SampleName1, SampleName2)
	String SampleName1, SampleName2
	String FolderName1, MName1
	String FolderName2, MName2
	Variable m = 0
	
	// 
	String colBase = GetColBasePath()
	
	// Use GetCellFolderList instead of CountObjects
	Variable n = GetCellCount(SampleName1)
	if(n == 0)
		Print "Warning: No valid cell folders found for " + SampleName1
		return -1
	endif
	
	SetDataFolder root:$(SampleName1)
	NVAR/Z PA = root:PA
	NVAR Dstate = root:Dstate
	Variable PAum = 0
	if(NVAR_Exists(PA))
		PAum = PA / 1000
	endif
	
	// C1
	Do
		FolderName1 = GetCellFolderName(SampleName1, m)
		FolderName2 = GetCellFolderName(SampleName2, m)
		
		if(strlen(FolderName1) == 0 || strlen(FolderName2) == 0)
			break
		endif
		
		// Verify Col folder exists
		String colPath1 = colBase + ":" + SampleName1 + ":" + FolderName1
		if(!DataFolderExists(colPath1))
			m += 1
			continue
		endif
		
		String ColMName = FolderName1 + "_" + FolderName2 + "_col"
		SetDataFolder $colPath1
		
		// Check if ColMatrix exists
		Wave/Z ColMatrixCheck = $ColMName
		if(!WaveExists(ColMatrixCheck))
			m += 1
			continue
		endif
		
		Duplicate/O $(ColMName), Matrix
		Wave Matrix
		
		Variable s = 0
		
		Variable RowSize = DimSize(Matrix, 0)
		Variable ColumnSize = DimSize(Matrix, 1)
		String WName0 = "ROI_S" + num2str(s) + "_C1"
		String WName1 = "Rframe_S" + num2str(s) + "_C1"
		String WName2 = "Rtime_S" + num2str(s) + "_C1"
		String WName3 = "Xum_S" + num2str(s) + "_C1"
		String WName4 = "Yum_S" + num2str(s) + "_C1"
		String WName5 = "Int_S" + num2str(s) + "_C1"
		String WName6 = "DF_S" + num2str(s) + "_C1"
		String WName7 = "Dstate_S" + num2str(s) + "_C1"
		String WName8 = "Distance_C1"
		String WName9 = "Colocalize_C1"
		String WName10 = "Cframe_S" + num2str(s) + "_C1"
		Make/O/D/N=(RowSize*ColumnSize/20) Wave0, Wave1, Wave2, Wave3, Wave4, Wave5, Wave6, Wave7, Wave8, Wave9, Wave10
		Wave0 = NaN; Wave1 = NaN; Wave2 = NaN; Wave3 = NaN; Wave4 = NaN; Wave5 = NaN; Wave6 = NaN; Wave7 = NaN; Wave8 = NaN; Wave9 = NaN; Wave10 = NaN
		
		Variable r
		Variable c
		Variable RowWave
		
		For(c = 0; c < ColumnSize; c += 20)
			RowWave = RowSize * c / 20
			For(r = 0; r < RowSize; r += 1)
				MultiThread Wave0[r+RowWave] = Matrix[r][c]
				MultiThread Wave1[r+RowWave] = Matrix[r][c+1]
				MultiThread Wave2[r+RowWave] = Matrix[r][c+2]
				MultiThread Wave3[r+RowWave] = Matrix[r][c+3]
				MultiThread Wave4[r+RowWave] = Matrix[r][c+4]
				MultiThread Wave5[r+RowWave] = Matrix[r][c+5]
				MultiThread Wave6[r+RowWave] = Matrix[r][c+6]
				MultiThread Wave7[r+RowWave] = Matrix[r][c+7]
				MultiThread Wave8[r+RowWave] = Matrix[r][c+16]
				MultiThread Wave9[r+RowWave] = Matrix[r][c+17]
				MultiThread Wave10[r+RowWave] = Matrix[r][c+18]
			Endfor
		Endfor
		
		Extract/O Wave0, ext_Wave0, numtype(Wave0) == 0
		Extract/O Wave1, ext_Wave1, numtype(Wave0) == 0
		Extract/O Wave2, ext_Wave2, numtype(Wave0) == 0
		Extract/O Wave3, ext_Wave3, numtype(Wave0) == 0
		Extract/O Wave4, ext_Wave4, numtype(Wave0) == 0
		Extract/O Wave5, ext_Wave5, numtype(Wave0) == 0
		Extract/O Wave6, ext_Wave6, numtype(Wave0) == 0
		Extract/O Wave7, ext_Wave7, numtype(Wave0) == 0
		Extract/O Wave8, ext_Wave8, numtype(Wave0) == 0
		Extract/O Wave9, ext_Wave9, numtype(Wave0) == 0
		Extract/O Wave10, ext_Wave10, numtype(Wave0) == 0
		Variable ExtDimSize = DimSize(ext_Wave0, 0)
		
		For(r = 1; r < ExtDimSize; r += 1)
			If(ext_Wave0[r] != ext_Wave0[r-1])
				InsertPoints r, 1, ext_Wave0; ext_Wave0[r] = NaN
				InsertPoints r, 1, ext_Wave1; ext_Wave1[r] = NaN
				InsertPoints r, 1, ext_Wave2; ext_Wave2[r] = NaN
				InsertPoints r, 1, ext_Wave3; ext_Wave3[r] = NaN
				InsertPoints r, 1, ext_Wave4; ext_Wave4[r] = NaN
				InsertPoints r, 1, ext_Wave5; ext_Wave5[r] = NaN
				InsertPoints r, 1, ext_Wave6; ext_Wave6[r] = NaN
				InsertPoints r, 1, ext_Wave7; ext_Wave7[r] = NaN
				InsertPoints r, 1, ext_Wave8; ext_Wave8[r] = NaN
				InsertPoints r, 1, ext_Wave9; ext_Wave9[r] = NaN
				InsertPoints r, 1, ext_Wave10; ext_Wave10[r] = NaN
				ExtDimSize += 1
				r += 1
			Endif
		Endfor
		
		Duplicate/O ext_Wave0, $(WName0)
		Duplicate/O ext_Wave1, $(WName1)
		Duplicate/O ext_Wave2, $(WName2)
		Duplicate/O ext_Wave3, $(WName3)
		Duplicate/O ext_Wave4, $(WName4)
		Duplicate/O ext_Wave5, $(WName5)
		Duplicate/O ext_Wave6, $(WName6)
		Duplicate/O ext_Wave7, $(WName7)
		Duplicate/O ext_Wave8, $(WName8)
		Duplicate/O ext_Wave9, $(WName9)
		Duplicate/O ext_Wave10, $(WName10)
		KillWaves Wave0, Wave1, Wave2, Wave3, Wave4, Wave5, Wave6, Wave7, Wave8, Wave9, Wave10, Matrix
		
		m += 1
	While(m < n)
	
	m = 0
	// C2
	Do
		FolderName1 = GetCellFolderName(SampleName1, m)
		FolderName2 = GetCellFolderName(SampleName2, m)
		
		if(strlen(FolderName1) == 0 || strlen(FolderName2) == 0)
			break
		endif
		
		// Verify Col folder exists
		String colPath2 = colBase + ":" + SampleName2 + ":" + FolderName2
		if(!DataFolderExists(colPath2))
			m += 1
			continue
		endif
		
		ColMName = FolderName1 + "_" + FolderName2 + "_col"
		SetDataFolder $colPath2
		
		// Check if ColMatrix exists
		Wave/Z ColMatrixCheck2 = $ColMName
		if(!WaveExists(ColMatrixCheck2))
			m += 1
			continue
		endif
		
		Duplicate/O $(ColMName), Matrix
		Wave Matrix
		
		s = 0
		
		RowSize = DimSize(Matrix, 0)
		ColumnSize = DimSize(Matrix, 1)
		WName0 = "ROI_S" + num2str(s) + "_C2"
		WName1 = "Rframe_S" + num2str(s) + "_C2"
		WName2 = "Rtime_S" + num2str(s) + "_C2"
		WName3 = "Xum_S" + num2str(s) + "_C2"
		WName4 = "Yum_S" + num2str(s) + "_C2"
		WName5 = "Int_S" + num2str(s) + "_C2"
		WName6 = "DF_S" + num2str(s) + "_C2"
		WName7 = "Dstate_S" + num2str(s) + "_C2"
		WName8 = "Distance_C2"
		WName9 = "Colocalize_C2"
		WName10 = "Cframe_S" + num2str(s) + "_C2"
		Make/O/D/N=(RowSize*ColumnSize/20) Wave0, Wave1, Wave2, Wave3, Wave4, Wave5, Wave6, Wave7, Wave8, Wave9, Wave10
		Wave0 = NaN; Wave1 = NaN; Wave2 = NaN; Wave3 = NaN; Wave4 = NaN; Wave5 = NaN; Wave6 = NaN; Wave7 = NaN; Wave8 = NaN; Wave9 = NaN; Wave10 = NaN
		
		For(c = 0; c < ColumnSize; c += 20)
			RowWave = RowSize * c / 20
			For(r = 0; r < RowSize; r += 1)
				MultiThread Wave0[r+RowWave] = Matrix[r][c+8]
				MultiThread Wave1[r+RowWave] = Matrix[r][c+9]
				MultiThread Wave2[r+RowWave] = Matrix[r][c+10]
				MultiThread Wave3[r+RowWave] = Matrix[r][c+11]
				MultiThread Wave4[r+RowWave] = Matrix[r][c+12]
				MultiThread Wave5[r+RowWave] = Matrix[r][c+13]
				MultiThread Wave6[r+RowWave] = Matrix[r][c+14]
				MultiThread Wave7[r+RowWave] = Matrix[r][c+15]
				MultiThread Wave8[r+RowWave] = Matrix[r][c+16]
				MultiThread Wave9[r+RowWave] = Matrix[r][c+17]
				MultiThread Wave10[r+RowWave] = Matrix[r][c+18]
			Endfor
		Endfor
		
		Extract/O Wave0, ext_Wave0, numtype(Wave0) == 0
		Extract/O Wave1, ext_Wave1, numtype(Wave0) == 0
		Extract/O Wave2, ext_Wave2, numtype(Wave0) == 0
		Extract/O Wave3, ext_Wave3, numtype(Wave0) == 0
		Extract/O Wave4, ext_Wave4, numtype(Wave0) == 0
		Extract/O Wave5, ext_Wave5, numtype(Wave0) == 0
		Extract/O Wave6, ext_Wave6, numtype(Wave0) == 0
		Extract/O Wave7, ext_Wave7, numtype(Wave0) == 0
		Extract/O Wave8, ext_Wave8, numtype(Wave0) == 0
		Extract/O Wave9, ext_Wave9, numtype(Wave0) == 0
		Extract/O Wave10, ext_Wave10, numtype(Wave0) == 0
		ExtDimSize = DimSize(ext_Wave0, 0)
		
		For(r = 1; r < ExtDimSize; r += 1)
			If(ext_Wave0[r] != ext_Wave0[r-1])
				InsertPoints r, 1, ext_Wave0; ext_Wave0[r] = NaN
				InsertPoints r, 1, ext_Wave1; ext_Wave1[r] = NaN
				InsertPoints r, 1, ext_Wave2; ext_Wave2[r] = NaN
				InsertPoints r, 1, ext_Wave3; ext_Wave3[r] = NaN
				InsertPoints r, 1, ext_Wave4; ext_Wave4[r] = NaN
				InsertPoints r, 1, ext_Wave5; ext_Wave5[r] = NaN
				InsertPoints r, 1, ext_Wave6; ext_Wave6[r] = NaN
				InsertPoints r, 1, ext_Wave7; ext_Wave7[r] = NaN
				InsertPoints r, 1, ext_Wave8; ext_Wave8[r] = NaN
				InsertPoints r, 1, ext_Wave9; ext_Wave9[r] = NaN
				InsertPoints r, 1, ext_Wave10; ext_Wave10[r] = NaN
				ExtDimSize += 1
				r += 2
			Endif
		Endfor
		
		Duplicate/O ext_Wave0, $(WName0)
		Duplicate/O ext_Wave1, $(WName1)
		Duplicate/O ext_Wave2, $(WName2)
		Duplicate/O ext_Wave3, $(WName3)
		Duplicate/O ext_Wave4, $(WName4)
		Duplicate/O ext_Wave5, $(WName5)
		Duplicate/O ext_Wave6, $(WName6)
		Duplicate/O ext_Wave7, $(WName7)
		Duplicate/O ext_Wave8, $(WName8)
		Duplicate/O ext_Wave9, $(WName9)
		Duplicate/O ext_Wave10, $(WName10)
		KillWaves Wave0, Wave1, Wave2, Wave3, Wave4, Wave5, Wave6, Wave7, Wave8, Wave9, Wave10, Matrix
		
		m += 1
	While(m < n)
End

// Extract non-NaN values and add separators between different colocalization events
static Function ColExtractAndSeparate(waveList)
	String waveList
	
	Variable numWaves = ItemsInList(waveList)
	if(numWaves == 0)
		return -1
	endif
	
	// Get reference wave for extraction (ROI_S0)
	String refWaveName = StringFromList(0, waveList)
	Wave/Z refWave = $refWaveName
	if(!WaveExists(refWave))
		return -1
	endif
	
	// Get Rframe wave for separator detection (index 1 in list)
	String rframeName = StringFromList(1, waveList)  // Rframe_S0_C1 or C2
	Wave/Z RframeWave = $rframeName
	
	// Extract non-NaN values for all waves
	Variable i
	String wName
	for(i = 0; i < numWaves; i += 1)
		wName = StringFromList(i, waveList)
		Wave/Z w = $wName
		if(WaveExists(w))
			Extract/O w, $("ext_" + wName), numtype(refWave) == 0
		endif
	endfor
	
	// Get extracted Rframe wave for separator insertion
	String extRframeName = "ext_" + rframeName
	Wave/Z extRframe = $extRframeName
	if(!WaveExists(extRframe))
		return -1
	endif
	
	Variable extSize = numpnts(extRframe)
	Variable rr
	
	// Add separators when Rframe resets to 0 (new colocalization event)
	for(rr = 1; rr < extSize; rr += 1)
		// Rframe==0  Rframe>0 → 
		if(numtype(extRframe[rr]) == 0 && extRframe[rr] == 0 && numtype(extRframe[rr-1]) == 0 && extRframe[rr-1] > 0)
			// Insert NaN separator
			for(i = 0; i < numWaves; i += 1)
				wName = "ext_" + StringFromList(i, waveList)
				Wave/Z w = $wName
				if(WaveExists(w))
					InsertPoints rr, 1, w
					w[rr] = NaN
				endif
			endfor
			extSize += 1
			rr += 1
		endif
	endfor
	
	// Rename extracted waves back to original names
	for(i = 0; i < numWaves; i += 1)
		wName = StringFromList(i, waveList)
		String extName = "ext_" + wName
		Wave/Z extW = $extName
		Wave/Z origW = $wName
		if(WaveExists(extW) && WaveExists(origW))
			Duplicate/O extW, $wName
			KillWaves/Z extW
		endif
	endfor
	
	return 0
End

// Create D-state specific waves
Function MakeAnalysisWavesCol_HMM(SampleName1, SampleName2)
	String SampleName1, SampleName2
	String FolderName1, FolderName2
	
	// 
	String colBase = GetColBasePath()
	
	// Use GetCellFolderList instead of CountObjects
	Variable n = GetCellCount(SampleName1)
	if(n == 0)
		Print "Warning: No valid cell folders found for " + SampleName1
		return -1
	endif
	
	SetDataFolder $(colBase + ":" + SampleName1)
	Variable m = 0
	NVAR Dstate = root:Dstate
	
	Do
		// Ch1
		FolderName1 = GetCellFolderName(SampleName1, m)
		FolderName2 = GetCellFolderName(SampleName2, m)
		
		if(strlen(FolderName1) == 0 || strlen(FolderName2) == 0)
			break
		endif
		
		// Verify Col folder exists
		String colPath1 = colBase + ":" + SampleName1 + ":" + FolderName1
		if(!DataFolderExists(colPath1))
			m += 1
			continue
		endif
		
		SetDataFolder $colPath1
		// S1Sn
		SeparateStateWavesFromS0("_C1", Dstate)
		
		// Ch2
		String colPath2 = colBase + ":" + SampleName2 + ":" + FolderName2
		if(!DataFolderExists(colPath2))
			m += 1
			continue
		endif
		SetDataFolder $colPath2
		// S1Sn
		SeparateStateWavesFromS0("_C2", Dstate)
		
		m += 1
	While(m < n)
End

// Extract and visualize colocalization ()
Function ExtractColocalizationAll_HMM(SampleName1, SampleName2)
    String SampleName1, SampleName2
    String FolderName1,  FolderName2
    
    // 
    String colBase = GetColBasePath()
    String ecBase = GetECBasePath()
    
    // Use GetCellFolderList instead of CountObjects
    variable n = GetCellCount(SampleName1)
    if(n == 0)
        Print "Warning: No valid cell folders found for " + SampleName1
        return -1
    endif
    
    SetDataFolder $(colBase + ":" + SampleName1)
    variable m = 0  //cell counter
    NVAR framerate= root:framerate  //[sec]
    NVAR FrameNum=root:FrameNum
        
    Do //Copy Col data to EC folder 
         FolderName1 = GetCellFolderName(SampleName1, m)
         FolderName2 = GetCellFolderName(SampleName2, m)
         
         if(strlen(FolderName1) == 0 || strlen(FolderName2) == 0)
             break
         endif
         
         // Verify Col folders exist
         String colPath1 = colBase + ":" + SampleName1 + ":" + FolderName1
         String colPath2 = colBase + ":" + SampleName2 + ":" + FolderName2
         if(!DataFolderExists(colPath1) || !DataFolderExists(colPath2))
             m += 1
             continue
         endif
         
           if(m==0)
             if(DataFolderExists(ecBase)==0)
             NewDataFolder/O $ecBase
             endif
             // Sample
             if(DataFolderExists(ecBase + ":" + SampleName1))
                 KillDataFolder/Z $(ecBase + ":" + SampleName1)
             endif
             if(DataFolderExists(ecBase + ":" + SampleName2))
                 KillDataFolder/Z $(ecBase + ":" + SampleName2)
             endif
             NewDataFolder/O $(ecBase + ":" + SampleName1)
             NewDataFolder/O $(ecBase + ":" + SampleName2)
           endif

         // 
         String ecCellPath1 = ecBase + ":" + SampleName1 + ":" + FolderName1
         String ecCellPath2 = ecBase + ":" + SampleName2 + ":" + FolderName2
         if(DataFolderExists(ecCellPath1))
             KillDataFolder/Z $ecCellPath1
         endif
         if(DataFolderExists(ecCellPath2))
             KillDataFolder/Z $ecCellPath2
         endif
         
         DuplicateDataFolder $(colBase + ":" + SampleName1 + ":" + FolderName1), $(ecBase + ":" + SampleName1 + ":" + FolderName1)
         SetDataFolder $(ecBase + ":" + SampleName1 + ":" + FolderName1)
          variable index=0
          string OldName, NewName 
      do
		OldName = WaveName("", index, 4)
		NewName = OldName+"E"
		if (!WaveExists($(OldName)))
			break
		endif
		Rename $(OldName), $(NewName)
		index += 1
	   while(1)
         
         DuplicateDataFolder $(colBase + ":" + SampleName2 + ":" + FolderName2), $(ecBase + ":" + SampleName2 + ":" + FolderName2)
         SetDataFolder $(ecBase + ":" + SampleName2 + ":" + FolderName2)
           index=0
      do
		OldName = WaveName("", index, 4)
		NewName = OldName+"E"
		if (!WaveExists($(OldName)))
			break
		endif
		Rename $(OldName), $(NewName)
		index += 1
	   while(1)
	   
    // Ch1: Colocalize==0NaNNaNDeletepointsrow
    SetDataFolder $(ecBase + ":" + SampleName1 + ":" + FolderName1)
    Wave Rtime_S0_C1E, Rframe_S0_C1E, Xum_S0_C1E, Yum_S0_C1E, ROI_S0_C1E, Int_S0_C1E, DF_S0_C1E, Dstate_S0_C1E, Distance_C1E, Colocalize_C1E
    
    variable i=0
    variable DataNo1 = numpnts(Colocalize_C1E)
    
    // Colocalize==0NaNNaNrow
    for(i = 0; i < DataNo1; i += 1)
        if(numtype(Colocalize_C1E[i]) == 2 || Colocalize_C1E[i] == 0)
            Rtime_S0_C1E[i] = NaN
            Rframe_S0_C1E[i] = NaN
            Xum_S0_C1E[i] = NaN
            Yum_S0_C1E[i] = NaN
            ROI_S0_C1E[i] = NaN
            Int_S0_C1E[i] = NaN
            DF_S0_C1E[i] = NaN
            Dstate_S0_C1E[i] = NaN
            Distance_C1E[i] = NaN
            Colocalize_C1E[i] = NaN
        endif
    endfor
    
    // Rframe0
    // NaN0
    Variable frameCounter = 0
    DataNo1 = numpnts(Rframe_S0_C1E)
    for(i = 0; i < DataNo1; i += 1)
        if(numtype(Rframe_S0_C1E[i]) == 2)  // NaN
            frameCounter = 0
        else
            Rframe_S0_C1E[i] = frameCounter
            frameCounter += 1
        endif
    endfor
    
    // Ch2: 
    SetDataFolder $(ecBase + ":" + SampleName2 + ":" + FolderName2)
    Wave Rtime_S0_C2E, Rframe_S0_C2E, Xum_S0_C2E, Yum_S0_C2E, ROI_S0_C2E, Int_S0_C2E, DF_S0_C2E, Dstate_S0_C2E, Distance_C2E, Colocalize_C2E
    
    variable DataNo2 = numpnts(Colocalize_C2E)
    
    for(i = 0; i < DataNo2; i += 1)
        if(numtype(Colocalize_C2E[i]) == 2 || Colocalize_C2E[i] == 0)
            Rtime_S0_C2E[i] = NaN
            Rframe_S0_C2E[i] = NaN
            Xum_S0_C2E[i] = NaN
            Yum_S0_C2E[i] = NaN
            ROI_S0_C2E[i] = NaN
            Int_S0_C2E[i] = NaN
            DF_S0_C2E[i] = NaN
            Dstate_S0_C2E[i] = NaN
            Distance_C2E[i] = NaN
            Colocalize_C2E[i] = NaN
        endif
    endfor
    
    // Rframe0
    frameCounter = 0
    DataNo2 = numpnts(Rframe_S0_C2E)
    for(i = 0; i < DataNo2; i += 1)
        if(numtype(Rframe_S0_C2E[i]) == 2)  // NaN
            frameCounter = 0
        else
            Rframe_S0_C2E[i] = frameCounter
            frameCounter += 1
        endif
    endfor
    
    // S0S1SnS0Dstate_S0S0 = ΣSn 
    NVAR/Z Dstate = root:Dstate
    if(NVAR_Exists(Dstate) && Dstate > 0)
        // Ch1: S1Sn
        SetDataFolder $(ecBase + ":" + SampleName1 + ":" + FolderName1)
        SeparateStateWavesFromS0("_C1E", Dstate)
        
        // Ch2: S1Sn
        SetDataFolder $(ecBase + ":" + SampleName2 + ":" + FolderName2)
        SeparateStateWavesFromS0("_C2E", Dstate)
    endif
    
      
  
   //Col Ratio, Distance mean, Distance SD
   variable Pcol, Tcol, Tall1, Tall2, Area1, Area2, Dcol1, Dcol2
   
   //ch1//
   SetDataFolder  root:$(SampleName1):$(FolderName1)
   wave Rtime_S0, ParaDensityAvg
   Extract/FREE/O Rtime_S0, extracted, numtype(Rtime_S0) != 2
              Tall1 = numpnts(extracted) // ch1
              Area1 = ParaDensityAvg[1] //ch1
              Dcol1 = ParaDensityAvg[2] //ch1
   //ch2//
   SetDataFolder  root:$(SampleName2):$(FolderName2)
   wave Rtime_S0, ParaDensityAvg
   Extract/FREE/O Rtime_S0, extracted, numtype(Rtime_S0) != 2
              Tall2 = numpnts(extracted) //Ch2
              Area2 = ParaDensityAvg[1] //ch2
              Dcol2 = ParaDensityAvg[2] //ch2
   
   NVAR/Z ColAreaMode = root:ColAreaMode
   Variable areaMode = NVAR_Exists(ColAreaMode) ? ColAreaMode : 1  // 0=Min, 1=Max
   variable AreaMin = (areaMode == 0) ? min(Area1, Area2) : max(Area1, Area2)
              
   //ch1//           
   SetDataFolder $(ecBase + ":" + SampleName1 + ":" + FolderName1) 
   wave Rtime_S0_C1E, Distance_C1E
   Make/O/N=10 ParaCol_C1   //0=PercentC_C1, 1=Distance_mean_C1, 2=Distane_sd_C1, 3=Kb
   Extract/FREE/O Rtime_S0_C1E, extracted, numtype(Rtime_S0_C1E) != 2
              Tcol = numpnts(extracted)
              Pcol = Tcol/Tall1*100
              ParaCol_C1[0] = Pcol 
              ParaCol_C1[3] = (Tcol/AreaMin)*FrameNum/(((Tall1-Tcol)/Area1)*((Tall2-Tcol)/Area2))
              ParaCol_C1[4] = Area1
              ParaCol_C1[5] = Area2
              ParaCol_C1[6] = AreaMin
              ParaCol_C1[7] = Tall1
              ParaCol_C1[8] = Tall2
              ParaCol_C1[9] = Tcol
                      
   Wavestats/Q/Z  Distance_C1E
              ParaCol_C1[1] = V_avg * 1000  // µm → nm
              ParaCol_C1[2] = V_sdev * 1000  // µm → nm
              
               
              
  //ch2// 
              
   SetDataFolder $(ecBase + ":" + SampleName2 + ":" + FolderName2)
   wave Rtime_S0_C2E, Distance_C2E
   Make/O/N=10 ParaCol_C2   //0=PercentC_C2, 1=Dmean_C2, 2=Dsd_C2, 3=Kb
   Extract/FREE/O Rtime_S0_C2E, extracted, numtype(Rtime_S0_C2E) != 2
              Tcol = numpnts(extracted)
              Pcol = Tcol/Tall2*100
              ParaCol_C2[0] = Pcol 
              ParaCol_C2[3] = (Tcol/AreaMin)*FrameNum/(((Tall1-Tcol)/Area1)*((Tall2-Tcol)/Area2))
              ParaCol_C2[4] = Area1
              ParaCol_C2[5] = Area2
              ParaCol_C2[6] = AreaMin
              ParaCol_C2[7] = Tall1
              ParaCol_C2[8] = Tall2
              ParaCol_C2[9] = Tcol
                      
   Wavestats/Q/Z  Distance_C2E
              ParaCol_C2[1] = V_avg * 1000  // µm → nm
              ParaCol_C2[2] = V_sdev * 1000  // µm → nm
              
   // Create label wave for ParaCol (in EC folder, only once)
   SetDataFolder $ecBase
   String paraColLabelsPath = ecBase + ":ParaCol_Labels"
   if(!WaveExists($paraColLabelsPath))
      Make/O/T/N=10 ParaCol_Labels
      ParaCol_Labels[0] = "PercentC (%)"
      ParaCol_Labels[1] = "Distance_mean [nm]"
      ParaCol_Labels[2] = "Distance_SD [nm]"
      ParaCol_Labels[3] = "Kb"
      ParaCol_Labels[4] = "Area1"
      ParaCol_Labels[5] = "Area2"
      ParaCol_Labels[6] = "AreaNorm"
      ParaCol_Labels[7] = "Tall1"
      ParaCol_Labels[8] = "Tall2"
      ParaCol_Labels[9] = "Tcol"
   endif
   Wave/T ParaCol_Labels = $paraColLabelsPath
   
   Edit ParaCol_Labels, ParaCol_C1, ParaCol_C2
   
    m+=1
    While(m<n)

End

// Create result matrix
Function MakeResultMatrixCol_HMM(sampleName1, sampleName2)
	String sampleName1, sampleName2
	
	String savedDF = GetDataFolder(1)
	
	// 
	String colBase = GetColBasePath()
	
	// Create Results folder
	String resultsFolder = colBase + ":" + sampleName1 + ":Results"
	SetDataFolder $(colBase + ":" + sampleName1)
	NewDataFolder/O Results
	
	SetDataFolder $resultsFolder
	
	// Count cells and collect statistics
	Variable numCells = 0
	String folderName1
	
	do
		folderName1 = sampleName1 + num2str(numCells + 1)
		if(!DataFolderExists(colBase + ":" + sampleName1 + ":" + folderName1))
			break
		endif
		numCells += 1
	while(1)
	
	if(numCells == 0)
		SetDataFolder $savedDF
		return -1
	endif
	
	// Create result waves
	Make/O/D/N=(numCells) Col_NumPairs = 0
	Make/O/D/N=(numCells) Col_TotalColFrames = 0
	Make/O/D/N=(numCells) Col_MeanDuration = 0
	
	Variable m
	String colMName
	String folderName2
	
	for(m = 0; m < numCells; m += 1)
		folderName1 = sampleName1 + num2str(m + 1)
		folderName2 = sampleName2 + num2str(m + 1)
		colMName = folderName1 + "_" + folderName2 + "_col"
		
		SetDataFolder $(colBase + ":" + sampleName1 + ":" + folderName1)
		Wave/Z ColMat = $colMName
		
		if(WaveExists(ColMat))
			Variable colSize = DimSize(ColMat, 1)
			Variable numPairs = colSize / 20
			Col_NumPairs[m] = numPairs
			
			// Count colocalized frames
			Variable totalColFrames = 0
			Variable rr, cc
			for(cc = 0; cc < numPairs; cc += 1)
				for(rr = 0; rr < DimSize(ColMat, 0); rr += 1)
					if(ColMat[rr][cc*20 + 17] == 1)
						totalColFrames += 1
					endif
				endfor
			endfor
			Col_TotalColFrames[m] = totalColFrames
			
			if(numPairs > 0)
				Col_MeanDuration[m] = totalColFrames / numPairs
			endif
		endif
	endfor
	
	SetDataFolder $resultsFolder
	
	Printf "MakeResultMatrixCol_HMM: Created result matrix for %d cells\r", numCells
	
	SetDataFolder $savedDF
	return 0
End

// Calculate statistics
Function StatResultMatrixCol_HMM(sampleName1, sampleName2)
	String sampleName1, sampleName2
	
	String savedDF = GetDataFolder(1)
	
	// 
	String colBase = GetColBasePath()
	
	String resultsFolder = colBase + ":" + sampleName1 + ":Results"
	if(!DataFolderExists(resultsFolder))
		SetDataFolder $savedDF
		return -1
	endif
	
	SetDataFolder $resultsFolder
	
	Wave/Z Col_NumPairs, Col_TotalColFrames, Col_MeanDuration
	
	if(!WaveExists(Col_NumPairs))
		SetDataFolder $savedDF
		return -1
	endif
	
	// Calculate mean and SD
	WaveStats/Q Col_NumPairs
	Variable meanPairs = V_avg
	Variable sdPairs = V_sdev
	
	WaveStats/Q Col_TotalColFrames
	Variable meanFrames = V_avg
	Variable sdFrames = V_sdev
	
	WaveStats/Q Col_MeanDuration
	Variable meanDuration = V_avg
	Variable sdDuration = V_sdev
	
	Printf "\r=== Colocalization Statistics for %s vs %s ===\r", sampleName1, sampleName2
	Printf "Number of cells: %d\r", numpnts(Col_NumPairs)
	Printf "Colocalized pairs: %.2f ± %.2f\r", meanPairs, sdPairs
	Printf "Total col frames: %.2f ± %.2f\r", meanFrames, sdFrames
	Printf "Mean duration: %.2f ± %.2f frames\r", meanDuration, sdDuration
	
	SetDataFolder $savedDF
	return 0
End

// =============================================================================
// Individual Analysis Functions for Colocalization
// =============================================================================


// -----------------------------------------------------------------------------
// Trajectory Analysis (EC folder)
// -----------------------------------------------------------------------------

Function ColTrajectoryFromList()
	String savedDF = GetDataFolder(1)
	
	Wave/T/Z List_C1 = root:List_C1
	Wave/T/Z List_C2 = root:List_C2
	
	if(!WaveExists(List_C1) || !WaveExists(List_C2))
		DoAlert 0, "Please create List_C1 and List_C2 first"
		return -1
	endif
	
	Variable numPairs = min(numpnts(List_C1), numpnts(List_C2))
	Variable i
	
	for(i = 0; i < numPairs; i += 1)
		ColTrajectoryPair(List_C1[i], List_C2[i])
	endfor
	
	// Create distance histograms for each sample pair
	Print "=== Creating Distance Histograms ==="
	for(i = 0; i < numPairs; i += 1)
		ColDistanceHistogram(List_C1[i], "_C1E")
		ColDistanceHistogram(List_C2[i], "_C2E")
	endfor
	
	// Collect histogram data to Matrix/Results using standard flow
	Print "=== Collecting Distance Histogram Statistics ==="
	for(i = 0; i < numPairs; i += 1)
		ColStatsResults_Distance(List_C1[i], "_C1E", "_C1")
		ColStatsResults_Distance(List_C2[i], "_C2E", "_C2")
	endfor
	
	SetDataFolder $savedDF
	return 0
End

// Wrapper function for distance histogram statistics (follows standard policy)
Function ColStatsResults_Distance(sampleName, ecSuffix, colSuffix)
	String sampleName
	String ecSuffix   // "_C1E" or "_C2E"
	String colSuffix  // "_C1" or "_C2"
	
	NVAR/Z Dstate = root:Dstate
	NVAR/Z cHMM = root:cHMM
	
	Variable maxState = 0
	if(NVAR_Exists(cHMM) && cHMM == 1 && NVAR_Exists(Dstate))
		maxState = Dstate
	endif
	
	// Build wave name list for EC folder
	String ecWaveList = ""
	Variable s
	for(s = 0; s <= maxState; s += 1)
		ecWaveList += "Dist_S" + num2str(s) + "_ColPhist" + ecSuffix + ";"
		ecWaveList += "Dist_S" + num2str(s) + "_X" + ecSuffix + ";"
	endfor
	
	// Build wave name list for Col folder
	String colWaveList = ""
	for(s = 0; s <= maxState; s += 1)
		colWaveList += "Dist_S" + num2str(s) + "_ColPhist" + colSuffix + ";"
		colWaveList += "Dist_S" + num2str(s) + "_X" + colSuffix + ";"
	endfor
	
	// Call standard statistics function
	// 
	String colBase = GetColBasePath()
	String ecBase = GetECBasePath()
	
	StatsResultsMatrix(ecBase, sampleName, ecWaveList)
	
	if(DataFolderExists(colBase + ":" + sampleName))
		StatsResultsMatrix(colBase, sampleName, colWaveList)
	endif
	
	return 0
End

Function ColTrajectoryPair(sampleName1, sampleName2)
	String sampleName1, sampleName2
	
	String savedDF = GetDataFolder(1)
	NVAR Dstate = root:Dstate
	NVAR scale = root:scale
	NVAR PixNum = root:PixNum
	Variable maxState = Dstate
	Variable ImageSize = scale * PixNum
	
	// 
	String colBase = GetColBasePath()
	String ecBase = GetECBasePath()
	
	// Determine base folder
	String baseFolder1, baseFolder2
	if(DataFolderExists("root:Samples:" + sampleName1))
		baseFolder1 = "root:Samples:" + sampleName1
		baseFolder2 = "root:Samples:" + sampleName2
	else
		baseFolder1 = "root:" + sampleName1
		baseFolder2 = "root:" + sampleName2
	endif
	
	Variable m = 0
	String folderName1, folderName2
	
	do
		folderName1 = sampleName1 + num2str(m + 1)
		folderName2 = sampleName2 + num2str(m + 1)
		
		String cellFolder1 = baseFolder1 + ":" + folderName1
		String cellFolder2 = baseFolder2 + ":" + folderName2
		String colFolder1 = colBase + ":" + sampleName1 + ":" + folderName1
		String colFolder2 = colBase + ":" + sampleName2 + ":" + folderName2
		String ecFolder1 = ecBase + ":" + sampleName1 + ":" + folderName1
		String ecFolder2 = ecBase + ":" + sampleName2 + ":" + folderName2
		
		if(!DataFolderExists(cellFolder1) || !DataFolderExists(cellFolder2))
			break
		endif
		
		// === Graph 1: All trajectories with colocalization overlay ===
		String graphWin = folderName1 + "_ColTraj"
		DoWindow/K $graphWin
		
		Variable traceCount = 0
		
		// Find first wave to create graph with
		SetDataFolder $cellFolder1
		Wave/Z Xum_S0, Yum_S0
		
		if(WaveExists(Xum_S0) && WaveExists(Yum_S0))
			// Create graph with first wave
			Display/K=1/N=$graphWin Yum_S0 vs Xum_S0 as folderName1 + " Colocalization Trajectory"
			String tName1 = "Yum_S0"
			ModifyGraph rgb($tName1)=(65280,48896,48896), lsize($tName1)=0.25
			traceCount += 1
			
			// Layer 1b: Second sample original trajectory
			SetDataFolder $cellFolder2
			Wave/Z Xum_S0, Yum_S0
			if(WaveExists(Xum_S0) && WaveExists(Yum_S0))
				AppendToGraph Yum_S0 vs Xum_S0
				String tName2 = "Yum_S0#1"
				ModifyGraph rgb($tName2)=(48896,65280,48896), lsize($tName2)=0.25
				traceCount += 1
			endif
			
			// Layer 2: Col folder trajectories (darker colors)
			if(DataFolderExists(colFolder1))
				SetDataFolder $colFolder1
				Wave/Z Xum_S0_C1, Yum_S0_C1
				if(WaveExists(Xum_S0_C1) && WaveExists(Yum_S0_C1))
					AppendToGraph Yum_S0_C1 vs Xum_S0_C1
					ModifyGraph rgb(Yum_S0_C1)=(65280,0,65280), lsize(Yum_S0_C1)=0.5
					traceCount += 1
				endif
			endif
			
			if(DataFolderExists(colFolder2))
				SetDataFolder $colFolder2
				Wave/Z Xum_S0_C2, Yum_S0_C2
				if(WaveExists(Xum_S0_C2) && WaveExists(Yum_S0_C2))
					AppendToGraph Yum_S0_C2 vs Xum_S0_C2
					ModifyGraph rgb(Yum_S0_C2)=(0,52428,0), lsize(Yum_S0_C2)=0.5
					traceCount += 1
				endif
			endif
			
			// Layer 3a: EC folder Ch1 trajectories (yellow, line+marker)
			if(DataFolderExists(ecFolder1))
				SetDataFolder $ecFolder1
				Wave/Z Xum_S0_C1E, Yum_S0_C1E
				if(WaveExists(Xum_S0_C1E) && WaveExists(Yum_S0_C1E))
					AppendToGraph Yum_S0_C1E vs Xum_S0_C1E
					String traceList = TraceNameList(graphWin, ";", 1)
					String tNameEC1 = StringFromList(ItemsInList(traceList, ";") - 1, traceList, ";")
					ModifyGraph mode($tNameEC1)=4, rgb($tNameEC1)=(65280,65280,0)
					ModifyGraph marker($tNameEC1)=8, msize($tNameEC1)=2, lsize($tNameEC1)=1
					traceCount += 1
				endif
			endif

			// Layer 3b: EC folder Ch2 trajectories (cyan, line+marker)
			if(DataFolderExists(ecFolder2))
				SetDataFolder $ecFolder2
				Wave/Z Xum_S0_C2E, Yum_S0_C2E
				if(WaveExists(Xum_S0_C2E) && WaveExists(Yum_S0_C2E))
					AppendToGraph Yum_S0_C2E vs Xum_S0_C2E
					traceList = TraceNameList(graphWin, ";", 1)
					String tNameEC2 = StringFromList(ItemsInList(traceList, ";") - 1, traceList, ";")
					ModifyGraph mode($tNameEC2)=4, rgb($tNameEC2)=(0,65280,65280)
					ModifyGraph marker($tNameEC2)=5, msize($tNameEC2)=2, lsize($tNameEC2)=1
					traceCount += 1
				endif
			endif
			
			// Apply formatting after all traces added (same as Trace_HMM)
			ModifyGraph width={Aspect,1}, height={Aspect,1}
			ModifyGraph tick=0, mirror=0, lowTrip=0.001, fStyle=1, fSize=16, font="Arial"
			Label bottom "X µm"
			Label left "Y µm"
			SetAxis bottom 0, ImageSize
			SetAxis left 0, ImageSize
			ModifyGraph gbRGB=(0,0,0)
			ModifyGraph tickRGB(bottom)=(65535,65535,65535), tickRGB(left)=(65535,65535,65535)
		endif
		
		// === Graph 2: Col trajectories by state (using Col folder which has Dstate separation) ===
		if(DataFolderExists(colFolder1))
			String graphWin2 = folderName1 + "_ColTrajState"
			DoWindow/K $graphWin2
			
			SetDataFolder $colFolder1
			
			Variable s
			String Txtbox = ""
			Variable traceAdded = 0
			
			// State colors (same as Trajectory button)
			Make/FREE/N=(6, 3) StateColorsRGB
			StateColorsRGB[0][0] = 32768;  StateColorsRGB[0][1] = 40704;  StateColorsRGB[0][2] = 65280  // S1: Blue
			StateColorsRGB[1][0] = 65280;  StateColorsRGB[1][1] = 65280;  StateColorsRGB[1][2] = 0      // S2: Yellow
			StateColorsRGB[2][0] = 0;      StateColorsRGB[2][1] = 65280;  StateColorsRGB[2][2] = 0      // S3: Green
			StateColorsRGB[3][0] = 65280;  StateColorsRGB[3][1] = 0;      StateColorsRGB[3][2] = 0      // S4: Red
			StateColorsRGB[4][0] = 65280;  StateColorsRGB[4][1] = 40704;  StateColorsRGB[4][2] = 32768  // S5: Pink
			StateColorsRGB[5][0] = 65535;  StateColorsRGB[5][1] = 65535;  StateColorsRGB[5][2] = 65535  // Other: White
			
			// State names
			Make/FREE/T/N=(5, 5) StateNames
			StateNames[0][0] = "Slow"; StateNames[0][1] = "Fast"
			StateNames[1][0] = "Immobile"; StateNames[1][1] = "Slow"; StateNames[1][2] = "Fast"
			StateNames[2][0] = "Immobile"; StateNames[2][1] = "Slow"; StateNames[2][2] = "Medium"; StateNames[2][3] = "Fast"
			StateNames[3][0] = "Immobile"; StateNames[3][1] = "Slow"; StateNames[3][2] = "Medium"; StateNames[3][3] = "Fast"; StateNames[3][4] = "Ultra Fast"
			
			Variable nameIdx = maxState - 2
			if(nameIdx < 0)
				nameIdx = 0
			endif
			if(nameIdx > 3)
				nameIdx = 3
			endif
			
			// First check for S0 wave to create graph with
			Wave/Z Xum_S0_C1, Yum_S0_C1
			if(WaveExists(Xum_S0_C1) && WaveExists(Yum_S0_C1))
				// Create graph with first wave
				Display/K=1/N=$graphWin2 Yum_S0_C1 vs Xum_S0_C1 as folderName1 + " Colocalization by State"
				ModifyGraph rgb(Yum_S0_C1)=(65535,65535,65535), lsize(Yum_S0_C1)=0.25
				traceAdded = 1
				
				// Add each D-state
				for(s = 1; s <= maxState; s += 1)
					String xWaveName = "Xum_S" + num2str(s) + "_C1"
					String yWaveName = "Yum_S" + num2str(s) + "_C1"
					
					Wave/Z xWv = $xWaveName
					Wave/Z yWv = $yWaveName
					
					if(!WaveExists(xWv) || !WaveExists(yWv))
						continue
					endif
					
					if(numpnts(xWv) > 0)
						AppendToGraph yWv vs xWv
						
						Variable colorIdx = s - 1
						if(colorIdx > 5)
							colorIdx = 5
						endif
						Variable rr = StateColorsRGB[colorIdx][0]
						Variable gg = StateColorsRGB[colorIdx][1]
						Variable bb = StateColorsRGB[colorIdx][2]
						
						ModifyGraph rgb($yWaveName)=(rr, gg, bb), lsize($yWaveName)=0.25
						
						// Textbox
						String stateName = StateNames[nameIdx][s-1]
						Txtbox += "\\F'Arial'\\Z16\r\\K(" + num2str(rr) + "," + num2str(gg) + "," + num2str(bb) + ")" + stateName
					endif
				endfor
				
				// Add textbox
				if(strlen(Txtbox) > 0)
					TextBox/C/N=text0/F=0/B=1/A=RB Txtbox
				endif
				
				// Apply formatting after all traces added (same as Trace_HMM)
				ModifyGraph width={Aspect,1}, height={Aspect,1}
				ModifyGraph tick=0, mirror=0, lowTrip=0.001, fStyle=1, fSize=16, font="Arial"
				Label bottom "X µm"
				Label left "Y µm"
				SetAxis bottom 0, ImageSize
				SetAxis left 0, ImageSize
				ModifyGraph gbRGB=(0,0,0)
				ModifyGraph tickRGB(bottom)=(65535,65535,65535), tickRGB(left)=(65535,65535,65535)
			endif
		endif
		
		m += 1
	while(1)
	
	SetDataFolder $savedDF
	return 0
End

// -----------------------------------------------------------------------------
// Distance Histogram (EC and Col folders)
// Creates histogram of colocalization distances by Dstate
// Distance values are converted from µm to nm (×1000)
// ColPhist: normalized by Col S0 total count (for cross-cell statistics)
// -----------------------------------------------------------------------------

Function ColDistanceHistogram(sampleName, suffix)
	String sampleName
	String suffix  // "_C1E" or "_C2E"
	
	String savedDF = GetDataFolder(1)
	
	// 
	String ecBasePath = GetECBasePath()
	String colBasePath = GetColBasePath()
	
	// Determine Col suffix from EC suffix
	String colSuffix
	if(StringMatch(suffix, "_C1E"))
		colSuffix = "_C1"
	else
		colSuffix = "_C2"
	endif
	
	// Get histogram parameters from LPhistBin/LPhistDim
	NVAR LPhistBin = root:LPhistBin
	NVAR LPhistDim = root:LPhistDim
	NVAR/Z Dstate = root:Dstate
	NVAR/Z cHMM = root:cHMM

	Variable distBin = LPhistBin * 20  // nm
	Variable distDim = LPhistDim
	
	Variable maxState = 0
	if(NVAR_Exists(cHMM) && cHMM == 1 && NVAR_Exists(Dstate))
		maxState = Dstate
	endif
	
	String ecBase = ecBasePath + ":" + sampleName
	String colBase = colBasePath + ":" + sampleName
	
	if(!DataFolderExists(ecBase))
		Printf "Warning: %s does not exist\r", ecBase
		SetDataFolder $savedDF
		return -1
	endif
	
	// Count cells
	Variable numCells = GetCellCount(sampleName)
	if(numCells <= 0)
		Printf "Warning: No cell folders for %s\r", sampleName
		SetDataFolder $savedDF
		return -1
	endif
	
	Printf "ColDistanceHistogram: %s, cells=%d, bin=%.1fnm, dim=%d, maxState=%d\r", sampleName, numCells, distBin, distDim, maxState
	
	Variable m, s, i
	Variable totalDistEC = 0, totalDistCol = 0
	
	// ==========================================================================
	// First pass: Count Col S0 total for each cell (for ColPhist normalization)
	// ==========================================================================
	Make/FREE/N=(numCells) colS0Counts = 0
	
	for(m = 0; m < numCells; m += 1)
		String folderName = sampleName + num2str(m + 1)
		String colFolder = colBase + ":" + folderName
		
		if(!DataFolderExists(colFolder))
			continue
		endif
		
		SetDataFolder $colFolder
		String colDistName = "Distance" + colSuffix
		Wave/Z colDistWave = $colDistName
		
		if(WaveExists(colDistWave))
			// Count valid (non-NaN) distances
			Extract/FREE/O colDistWave, validDist, numtype(colDistWave) == 0
			colS0Counts[m] = numpnts(validDist)
			totalDistCol += colS0Counts[m]
		endif
	endfor
	
	// ==========================================================================
	// Second pass: Process each cell - create histograms
	// ==========================================================================
	for(m = 0; m < numCells; m += 1)
		folderName = sampleName + num2str(m + 1)
		String ecFolder = ecBase + ":" + folderName
		colFolder = colBase + ":" + folderName
		
		if(!DataFolderExists(ecFolder))
			continue
		endif
		
		Variable colS0Total = colS0Counts[m]  // This cell's Col S0 count
		
		// =====================================================
		// Process EC folder (extended colocalization)
		// =====================================================
		SetDataFolder $ecFolder
		
		String distWaveName = "Distance" + suffix
		String dstateWaveName = "Dstate_S0" + suffix
		
		Wave/Z distWave = $distWaveName
		Wave/Z dstateWave = $dstateWaveName
		Wave/Z hmmWave = $("HMMP" + suffix)
		
		if(!WaveExists(distWave))
			continue
		endif
		
		Variable nPts = numpnts(distWave)
		if(nPts == 0)
			continue
		endif
		
		// Create Distance_Sn waves (nm, ×1000 from µm)
		for(s = 0; s <= maxState; s += 1)
			String distSnName = "Distance_S" + num2str(s) + suffix
			
			if(s == 0)
				// S0: all valid distances
				Extract/O distWave, $distSnName, numtype(distWave) == 0
				Wave distSn = $distSnName
				distSn *= 1000  // µm → nm
				totalDistEC += numpnts(distSn)
			else
				// S1-Sn: filter by Dstate
				if(WaveExists(dstateWave))
					Extract/O distWave, $distSnName, (numtype(distWave) == 0) && (dstateWave == s)
					Wave/Z distSn = $distSnName
					if(WaveExists(distSn))
						distSn *= 1000  // µm → nm
					endif
				endif
			endif
		endfor
		
		// Create histograms for each state (EC folder)
		for(s = 0; s <= maxState; s += 1)
			String distSnN = "Distance_S" + num2str(s) + suffix
			Wave/Z distSnW = $distSnN
			
			if(!WaveExists(distSnW) || numpnts(distSnW) == 0)
				continue
			endif
			
			String histName = "Dist_S" + num2str(s) + "_Hist" + suffix
			String pHistName = "Dist_S" + num2str(s) + "_Phist" + suffix
			String colPhistName = "Dist_S" + num2str(s) + "_ColPhist" + suffix
			String xName = "Dist_S" + num2str(s) + "_X" + suffix
			
			Make/O/N=(distDim) $histName = 0, $pHistName = 0, $colPhistName = 0, $xName = 0
			Wave DistHist = $histName
			Wave DistPhist = $pHistName
			Wave DistColPhist = $colPhistName
			Wave DistX = $xName
			
			// Set X axis (center of each bin, in nm)
			DistX = distBin * (p + 0.5)
			
			// Calculate histogram
			Histogram/B={0, distBin, distDim} distSnW, DistHist
			
			// Phist: normalized by own count (sum = 1)
			Variable nValid = numpnts(distSnW)
			if(nValid > 0)
				DistPhist = DistHist / (nValid * distBin)
			endif
			
			// ColPhist: normalized by Col S0 total (for cross-cell comparison)
			if(colS0Total > 0)
				DistColPhist = DistHist / (colS0Total * distBin)
			endif
		endfor
		
		// =====================================================
		// Process Col folder (all colocalized, not just extended)
		// =====================================================
		if(DataFolderExists(colFolder))
			SetDataFolder $colFolder
			
			colDistName = "Distance" + colSuffix
			String colDstateName = "Dstate_S0" + colSuffix
			
			Wave/Z colDistWave = $colDistName
			Wave/Z colDstateWave = $colDstateName
			
			if(WaveExists(colDistWave) && numpnts(colDistWave) > 0)
				// Create Distance_Sn waves for Col folder (nm)
				for(s = 0; s <= maxState; s += 1)
					String colDistSnName = "Distance_S" + num2str(s) + colSuffix
					
					if(s == 0)
						// S0: all valid distances
						Extract/O colDistWave, $colDistSnName, numtype(colDistWave) == 0
						Wave/Z colDistSn = $colDistSnName
						if(WaveExists(colDistSn))
							colDistSn *= 1000  // µm → nm
						endif
					else
						// S1-Sn: filter by Dstate
						if(WaveExists(colDstateWave))
							Extract/O colDistWave, $colDistSnName, (numtype(colDistWave) == 0) && (colDstateWave == s)
							Wave/Z colDistSn = $colDistSnName
							if(WaveExists(colDistSn))
								colDistSn *= 1000  // µm → nm
							endif
						endif
					endif
				endfor
				
				// Calculate HMMP for Col folder from Rtime (data point counts)
				Make/O/N=(maxState + 1) $("HMMP" + colSuffix) = 0
				Wave colHMMP = $("HMMP" + colSuffix)
				
				for(s = 0; s <= maxState; s += 1)
					String colRtimeSnN = "Rtime_S" + num2str(s) + colSuffix
					Wave/Z colRtimeSnW = $colRtimeSnN
					if(WaveExists(colRtimeSnW))
						// NaN
						Extract/FREE/O colRtimeSnW, tempRtime, numtype(colRtimeSnW) != 2
						if(s == 0)
							colHMMP[0] = numpnts(tempRtime)
						else
							colHMMP[s] = numpnts(tempRtime)
						endif
					endif
				endfor
				
				// Convert to percentages
				if(colS0Total > 0)
					colHMMP[0] = 100  // S0 = 100%
					Variable sumS1Sn = 0
					for(s = 1; s <= maxState; s += 1)
						sumS1Sn += colHMMP[s]
					endfor
					if(sumS1Sn > 0)
						for(s = 1; s <= maxState; s += 1)
							colHMMP[s] = colHMMP[s] / sumS1Sn * 100
						endfor
					endif
				endif
				
				// Create histograms for Col folder
				for(s = 0; s <= maxState; s += 1)
					String colDistSnN = "Distance_S" + num2str(s) + colSuffix
					Wave/Z colDistSnW = $colDistSnN
					
					if(!WaveExists(colDistSnW) || numpnts(colDistSnW) == 0)
						continue
					endif
					
					String colHistName = "Dist_S" + num2str(s) + "_Hist" + colSuffix
					String colPhistNameW = "Dist_S" + num2str(s) + "_Phist" + colSuffix
					String colColPhistName = "Dist_S" + num2str(s) + "_ColPhist" + colSuffix
					String colXName = "Dist_S" + num2str(s) + "_X" + colSuffix
					
					Make/O/N=(distDim) $colHistName = 0, $colPhistNameW = 0, $colColPhistName = 0, $colXName = 0
					Wave ColDistHist = $colHistName
					Wave ColDistPhist = $colPhistNameW
					Wave ColDistColPhist = $colColPhistName
					Wave ColDistX = $colXName
					
					ColDistX = distBin * (p + 0.5)
					
					Histogram/B={0, distBin, distDim} colDistSnW, ColDistHist
					
					// Phist: normalized by own count
					Variable nColValid = numpnts(colDistSnW)
					if(nColValid > 0)
						ColDistPhist = ColDistHist / (nColValid * distBin)
					endif
					
					// ColPhist: normalized by Col S0 total
					if(colS0Total > 0)
						ColDistColPhist = ColDistHist / (colS0Total * distBin)
					endif
				endfor
			endif
		endif
	endfor
	
	Printf "  Total distance points: EC=%d, Col=%d\r", totalDistEC, totalDistCol
	
	// Create summary graph if data exists
	if(totalDistEC > 0 || totalDistCol > 0)
		ColDisplayDistanceHistogram(sampleName, suffix, colSuffix, distBin, maxState)
	endif
	
	SetDataFolder $savedDF
	return 0
End

// Display Distance Histogram (using Hist counts, not probability density)
// EC folder: solid lines, Col folder: dashed lines
Function ColDisplayDistanceHistogram(sampleName, suffix, colSuffix, distBin, maxState)
	String sampleName
	String suffix      // EC suffix: "_C1E" or "_C2E"
	String colSuffix   // Col suffix: "_C1" or "_C2"
	Variable distBin
	Variable maxState
	
	String savedDF = GetDataFolder(1)
	
	// 
	String ecBasePath = GetECBasePath()
	String colBasePath = GetColBasePath()
	
	String ecBase = ecBasePath + ":" + sampleName
	String colBase = colBasePath + ":" + sampleName
	Variable numCells = GetCellCount(sampleName)
	
	// Color definition (same as LP Hist / Intensity Hist)
	Make/FREE/N=(6,3) stateColors
	stateColors[0][0] = 45000;   stateColors[0][1] = 45000;   stateColors[0][2] = 45000    // S0: 
	stateColors[1][0] = 0;       stateColors[1][1] = 0;       stateColors[1][2] = 65280    // S1: 
	stateColors[2][0] = 65280;   stateColors[2][1] = 43520;   stateColors[2][2] = 0        // S2: 
	stateColors[3][0] = 0;       stateColors[3][1] = 39168;   stateColors[3][2] = 0        // S3: 
	stateColors[4][0] = 65280;   stateColors[4][1] = 0;       stateColors[4][2] = 0        // S4: 
	stateColors[5][0] = 65280;   stateColors[5][1] = 0;       stateColors[5][2] = 65280    // S5: 
	
	Variable m, s
	
	// Create graph for each cell
	for(m = 0; m < numCells; m += 1)
		String folderName = sampleName + num2str(m + 1)
		String ecFolder = ecBase + ":" + folderName
		String colFolder = colBase + ":" + folderName
		
		if(!DataFolderExists(ecFolder))
			continue
		endif
		
		SetDataFolder $ecFolder
		
		// Check S0 data exists (use Hist for display)
		String histS0Name = "Dist_S0_Hist" + suffix
		String xS0Name = "Dist_S0_X" + suffix
		Wave/Z Dist_S0_Hist = $histS0Name
		Wave/Z Dist_S0_X = $xS0Name
		
		if(!WaveExists(Dist_S0_Hist) || !WaveExists(Dist_S0_X))
			continue
		endif
		
		String graphName = "Dist_" + folderName + suffix
		DoWindow/K $graphName
		
		// ===== EC folder (solid lines) =====
		// S0: histogram fill style
		Display/K=1/N=$graphName Dist_S0_Hist vs Dist_S0_X
		ModifyGraph mode($histS0Name)=5, hbFill($histS0Name)=4
		ModifyGraph rgb($histS0Name)=(stateColors[0][0], stateColors[0][1], stateColors[0][2])
		
		// S1-Sn: marker style (solid)
		for(s = 1; s <= maxState; s += 1)
			String histSnName = "Dist_S" + num2str(s) + "_Hist" + suffix
			String xSnName = "Dist_S" + num2str(s) + "_X" + suffix
			Wave/Z HistWave = $histSnName
			Wave/Z XWave = $xSnName
			
			if(WaveExists(HistWave) && WaveExists(XWave))
				AppendToGraph HistWave vs XWave
				ModifyGraph mode($histSnName)=4, marker($histSnName)=19, msize($histSnName)=3
				Variable colorIdx = s
				if(colorIdx > 5)
					colorIdx = 5
				endif
				ModifyGraph rgb($histSnName)=(stateColors[colorIdx][0], stateColors[colorIdx][1], stateColors[colorIdx][2])
			endif
		endfor
		
		// ===== Col folder (dashed lines) =====
		if(DataFolderExists(colFolder))
			SetDataFolder $colFolder
			
			// S0: histogram bar style (unfilled)
			String colHistS0Name = "Dist_S0_Hist" + colSuffix
			String colXS0Name = "Dist_S0_X" + colSuffix
			Wave/Z ColDist_S0_Hist = $colHistS0Name
			Wave/Z ColDist_S0_X = $colXS0Name
			
			if(WaveExists(ColDist_S0_Hist) && WaveExists(ColDist_S0_X))
				AppendToGraph ColDist_S0_Hist vs ColDist_S0_X
				ModifyGraph mode($colHistS0Name)=5, hbFill($colHistS0Name)=0  // bar, unfilled
				ModifyGraph rgb($colHistS0Name)=(stateColors[0][0], stateColors[0][1], stateColors[0][2])
			endif
			
			// S1-Sn: dashed line with markers
			for(s = 1; s <= maxState; s += 1)
				String colHistSnName = "Dist_S" + num2str(s) + "_Hist" + colSuffix
				String colXSnName = "Dist_S" + num2str(s) + "_X" + colSuffix
				Wave/Z ColHistWave = $colHistSnName
				Wave/Z ColXWave = $colXSnName
				
				if(WaveExists(ColHistWave) && WaveExists(ColXWave))
					AppendToGraph ColHistWave vs ColXWave
					ModifyGraph mode($colHistSnName)=4, marker($colHistSnName)=8, msize($colHistSnName)=2  // open circle
					ModifyGraph lstyle($colHistSnName)=2  // dashed
					colorIdx = s
					if(colorIdx > 5)
						colorIdx = 5
					endif
					ModifyGraph rgb($colHistSnName)=(stateColors[colorIdx][0], stateColors[colorIdx][1], stateColors[colorIdx][2])
				endif
			endfor
		endif
		
		// Graph formatting (same as LP hist)
		ModifyGraph tick=0, mirror=0, fStyle=1, fSize=14, font="Arial"
		SetAxis left 0, *
		SetAxis bottom 0, *
		Label left "Counts"
		Label bottom "Distance [nm]"
		ModifyGraph width={Aspect,1.618}
		
		String graphTitle = folderName + " Distance Histogram"
		DoWindow/T $graphName, graphTitle
		
		// Legend (EC: solid, Col: dashed)
		SetDataFolder $ecFolder
		String legendStr = "\\F'Arial'\\Z12\\s(" + histS0Name + ") " + GetDstateName(0, maxState) + " (EC)"
		for(s = 1; s <= maxState; s += 1)
			histSnName = "Dist_S" + num2str(s) + "_Hist" + suffix
			Wave/Z PW = $histSnName
			if(WaveExists(PW))
				legendStr += "\r\\s(" + histSnName + ") " + GetDstateName(s, maxState) + " (EC)"
			endif
		endfor
		
		if(DataFolderExists(colFolder))
			SetDataFolder $colFolder
			colHistS0Name = "Dist_S0_Hist" + colSuffix
			Wave/Z ColPW0 = $colHistS0Name
			if(WaveExists(ColPW0))
				legendStr += "\r\\s(" + colHistS0Name + ") " + GetDstateName(0, maxState) + " (Col)"
			endif
			for(s = 1; s <= maxState; s += 1)
				colHistSnName = "Dist_S" + num2str(s) + "_Hist" + colSuffix
				Wave/Z ColPW = $colHistSnName
				if(WaveExists(ColPW))
					legendStr += "\r\\s(" + colHistSnName + ") " + GetDstateName(s, maxState) + " (Col)"
				endif
			endfor
		endif
		TextBox/C/N=text0/F=0/B=1/A=RT legendStr
	endfor
	
	SetDataFolder $savedDF
	return 0
End

// -----------------------------------------------------------------------------
// Intensity Analysis (EC folder)
// -----------------------------------------------------------------------------

Function ColIntensityFromList()
	String savedDF = GetDataFolder(1)
	
	// 
	String ecBase = GetECBasePath()
	
	Wave/T/Z List_C1 = root:List_C1
	Wave/T/Z List_C2 = root:List_C2
	
	if(!WaveExists(List_C1) || !WaveExists(List_C2))
		DoAlert 0, "Please create List_C1 and List_C2 first"
		return -1
	endif
	
	NVAR ColIntHistBin = root:ColIntHistBin
	NVAR ColIntHistDim = root:ColIntHistDim
	NVAR/Z MinOligomerSize = root:MinOligomerSize
	NVAR/Z MaxOligomerSize = root:MaxOligomerSize
	
	// Intensity tab
	Variable numOligomers = 1
	if(NVAR_Exists(MaxOligomerSize))
		numOligomers = MaxOligomerSize
	endif
	
	Variable numPairs = min(numpnts(List_C1), numpnts(List_C2))
	Variable i
	
	Print "=== Colocalization Intensity Analysis ==="
	Printf "Using %s folder, Bin: %d, Dim: %d, Oligomers: %d\r", ecBase, ColIntHistBin, ColIntHistDim, numOligomers
	
	for(i = 0; i < numPairs; i += 1)
		String sampleName1 = List_C1[i]
		String sampleName2 = List_C2[i]
		
		Printf "Processing: %s vs %s\r", sampleName1, sampleName2
		
		// Ch1: waveSuffix
		CreateIntensityHistogram(sampleName1, basePath=ecBase, useHistBin=ColIntHistBin, useHistDim=ColIntHistDim, waveSuffix="_C1E")
		FitIntensityGauss_Safe(sampleName1, numOligomers, basePath=ecBase, useHistBin=ColIntHistBin, useHistDim=ColIntHistDim, waveSuffix="_C1E")
		DisplayIntensityHistHMM(sampleName1, basePath=ecBase, waveSuffix="_C1E")
		
		// Ch2: waveSuffix
		CreateIntensityHistogram(sampleName2, basePath=ecBase, useHistBin=ColIntHistBin, useHistDim=ColIntHistDim, waveSuffix="_C2E")
		FitIntensityGauss_Safe(sampleName2, numOligomers, basePath=ecBase, useHistBin=ColIntHistBin, useHistDim=ColIntHistDim, waveSuffix="_C2E")
		DisplayIntensityHistHMM(sampleName2, basePath=ecBase, waveSuffix="_C2E")
	endfor
	
	// coef_IntpopulationMean Oligomer SizeMatrix/Results
	Print "=== Calculating Mean Oligomer Size ==="
	for(i = 0; i < numPairs; i += 1)
		String smplName1 = List_C1[i]
		String smplName2 = List_C2[i]
		
		CalculatePopulationFromCoefEx(smplName1, ecBase, "_C1E")
		CalculatePopulationFromCoefEx(smplName2, ecBase, "_C2E")
	endfor
	
	SetDataFolder $savedDF
	return 0
End

// ECwave
// mode=0: _C1E/_C2E → 
// mode=1:  → _C1E/_C2E
static Function ColRenameWavesForAnalysis(sampleName, suffix, mode)
	String sampleName, suffix
	Variable mode  // 0=remove suffix, 1=restore suffix
	
	String savedDF = GetDataFolder(1)
	
	// 
	String ecBasePath = GetECBasePath()
	String ecBase = ecBasePath + ":" + sampleName
	
	if(!DataFolderExists(ecBase))
		return -1
	endif
	
	NVAR Dstate = root:Dstate
	Variable maxState = Dstate

	Variable m = 0
	String folderName
	
	do
		folderName = sampleName + num2str(m + 1)
		String ecFolder = ecBase + ":" + folderName
		
		if(!DataFolderExists(ecFolder))
			break
		endif
		
		SetDataFolder $ecFolder
		
		// WaveS0-Sn
		String baseNames = "ROI;Rframe;Rtime;Xum;Yum;Int;DF;Dstate"
		Variable numNames = ItemsInList(baseNames, ";")
		Variable j, ss
		
		for(ss = 0; ss <= maxState; ss += 1)
			for(j = 0; j < numNames; j += 1)
				String baseName = StringFromList(j, baseNames, ";")
				String srcName, dstName
				
				if(mode == 0)
					// Remove suffix: _C1/_C2 → 
					srcName = baseName + "_S" + num2str(ss) + suffix
					dstName = baseName + "_S" + num2str(ss)
				else
					// Restore suffix:  → _C1/_C2
					srcName = baseName + "_S" + num2str(ss)
					dstName = baseName + "_S" + num2str(ss) + suffix
				endif
				
				Wave/Z srcWave = $srcName
				if(WaveExists(srcWave))
					Rename srcWave, $dstName
				endif
			endfor
		endfor
		
		// WaveIntensity
		for(ss = 0; ss <= maxState; ss += 1)
			String histName, histDstName
			if(mode == 0)
				histName = "Int_S" + num2str(ss) + suffix + "_Phist"
				histDstName = "Int_S" + num2str(ss) + "_Phist"
			else
				histName = "Int_S" + num2str(ss) + "_Phist"
				histDstName = "Int_S" + num2str(ss) + suffix + "_Phist"
			endif
			
			Wave/Z histWave = $histName
			if(WaveExists(histWave))
				Rename histWave, $histDstName
			endif
			
			// WaveIntensity
			String fitHistName, fitHistDstName, fitXName, fitXDstName
			if(mode == 0)
				fitHistName = "fit_Int_S" + num2str(ss) + suffix + "_Phist"
				fitHistDstName = "fit_Int_S" + num2str(ss) + "_Phist"
				fitXName = "fit_IntX_S" + num2str(ss) + suffix
				fitXDstName = "fit_IntX_S" + num2str(ss)
			else
				fitHistName = "fit_Int_S" + num2str(ss) + "_Phist"
				fitHistDstName = "fit_Int_S" + num2str(ss) + suffix + "_Phist"
				fitXName = "fit_IntX_S" + num2str(ss)
				fitXDstName = "fit_IntX_S" + num2str(ss) + suffix
			endif
			
			Wave/Z fitHistWave = $fitHistName
			if(WaveExists(fitHistWave))
				Rename fitHistWave, $fitHistDstName
			endif
			Wave/Z fitXWave = $fitXName
			if(WaveExists(fitXWave))
				Rename fitXWave, $fitXDstName
			endif
		endfor
		
		// DiffusionWaveStepAll, StepHist, StepHist_x, fit_StepHist, fit_StepX, comp*
		Variable deltaT = 1  // ColocalizationΔt=1
		for(ss = 0; ss <= maxState; ss += 1)
			// StepAll
			String stepAllName, stepAllDstName
			if(mode == 0)
				stepAllName = "StepAll_dt" + num2str(deltaT) + "_S" + num2str(ss) + suffix
				stepAllDstName = "StepAll_dt" + num2str(deltaT) + "_S" + num2str(ss)
			else
				stepAllName = "StepAll_dt" + num2str(deltaT) + "_S" + num2str(ss)
				stepAllDstName = "StepAll_dt" + num2str(deltaT) + "_S" + num2str(ss) + suffix
			endif
			Wave/Z stepAllWave = $stepAllName
			if(WaveExists(stepAllWave))
				Rename stepAllWave, $stepAllDstName
			endif
			
			// StepHist
			String stepHistName, stepHistDstName
			if(mode == 0)
				stepHistName = "StepHist_dt" + num2str(deltaT) + "_S" + num2str(ss) + suffix
				stepHistDstName = "StepHist_dt" + num2str(deltaT) + "_S" + num2str(ss)
			else
				stepHistName = "StepHist_dt" + num2str(deltaT) + "_S" + num2str(ss)
				stepHistDstName = "StepHist_dt" + num2str(deltaT) + "_S" + num2str(ss) + suffix
			endif
			Wave/Z stepHistWave = $stepHistName
			if(WaveExists(stepHistWave))
				Rename stepHistWave, $stepHistDstName
			endif
			
			// StepHist_x
			String stepXName, stepXDstName
			if(mode == 0)
				stepXName = "StepHist_x_dt" + num2str(deltaT) + "_S" + num2str(ss) + suffix
				stepXDstName = "StepHist_x_dt" + num2str(deltaT) + "_S" + num2str(ss)
			else
				stepXName = "StepHist_x_dt" + num2str(deltaT) + "_S" + num2str(ss)
				stepXDstName = "StepHist_x_dt" + num2str(deltaT) + "_S" + num2str(ss) + suffix
			endif
			Wave/Z stepXWave = $stepXName
			if(WaveExists(stepXWave))
				Rename stepXWave, $stepXDstName
			endif
			
			// fit_StepHist
			String fitStepHistName, fitStepHistDstName
			if(mode == 0)
				fitStepHistName = "fit_StepHist_dt" + num2str(deltaT) + "_S" + num2str(ss) + suffix
				fitStepHistDstName = "fit_StepHist_dt" + num2str(deltaT) + "_S" + num2str(ss)
			else
				fitStepHistName = "fit_StepHist_dt" + num2str(deltaT) + "_S" + num2str(ss)
				fitStepHistDstName = "fit_StepHist_dt" + num2str(deltaT) + "_S" + num2str(ss) + suffix
			endif
			Wave/Z fitStepHistWave = $fitStepHistName
			if(WaveExists(fitStepHistWave))
				Rename fitStepHistWave, $fitStepHistDstName
			endif
			
			// fit_StepX
			String fitStepXName, fitStepXDstName
			if(mode == 0)
				fitStepXName = "fit_StepX_dt" + num2str(deltaT) + "_S" + num2str(ss) + suffix
				fitStepXDstName = "fit_StepX_dt" + num2str(deltaT) + "_S" + num2str(ss)
			else
				fitStepXName = "fit_StepX_dt" + num2str(deltaT) + "_S" + num2str(ss)
				fitStepXDstName = "fit_StepX_dt" + num2str(deltaT) + "_S" + num2str(ss) + suffix
			endif
			Wave/Z fitStepXWave = $fitStepXName
			if(WaveExists(fitStepXWave))
				Rename fitStepXWave, $fitStepXDstName
			endif
			
			// comp1, comp2, ...
			Variable compIdx
			for(compIdx = 1; compIdx <= 5; compIdx += 1)
				String compName, compDstName
				if(mode == 0)
					compName = "comp" + num2str(compIdx) + "_Step_dt" + num2str(deltaT) + "_S" + num2str(ss) + suffix
					compDstName = "comp" + num2str(compIdx) + "_Step_dt" + num2str(deltaT) + "_S" + num2str(ss)
				else
					compName = "comp" + num2str(compIdx) + "_Step_dt" + num2str(deltaT) + "_S" + num2str(ss)
					compDstName = "comp" + num2str(compIdx) + "_Step_dt" + num2str(deltaT) + "_S" + num2str(ss) + suffix
				endif
				Wave/Z compWave = $compName
				if(WaveExists(compWave))
					Rename compWave, $compDstName
				endif
			endfor
		endfor
		
		// OntimeWave
		for(ss = 0; ss <= maxState; ss += 1)
			// time_onrate, OnEvent, CumOnEvent
			String timeOnrateName, timeOnrateDstName
			String onEventName, onEventDstName
			String cumOnEventName, cumOnEventDstName
			
			if(mode == 0)
				timeOnrateName = "time_onrate_S" + num2str(ss) + suffix
				timeOnrateDstName = "time_onrate_S" + num2str(ss)
				onEventName = "OnEvent_S" + num2str(ss) + suffix
				onEventDstName = "OnEvent_S" + num2str(ss)
				cumOnEventName = "CumOnEvent_S" + num2str(ss) + suffix
				cumOnEventDstName = "CumOnEvent_S" + num2str(ss)
			else
				timeOnrateName = "time_onrate_S" + num2str(ss)
				timeOnrateDstName = "time_onrate_S" + num2str(ss) + suffix
				onEventName = "OnEvent_S" + num2str(ss)
				onEventDstName = "OnEvent_S" + num2str(ss) + suffix
				cumOnEventName = "CumOnEvent_S" + num2str(ss)
				cumOnEventDstName = "CumOnEvent_S" + num2str(ss) + suffix
			endif
			
			Wave/Z timeOnrateWave = $timeOnrateName
			if(WaveExists(timeOnrateWave))
				Rename timeOnrateWave, $timeOnrateDstName
			endif
			Wave/Z onEventWave = $onEventName
			if(WaveExists(onEventWave))
				Rename onEventWave, $onEventDstName
			endif
			Wave/Z cumOnEventWave = $cumOnEventName
			if(WaveExists(cumOnEventWave))
				Rename cumOnEventWave, $cumOnEventDstName
			endif
		endfor
		
		m += 1
	while(1)
	
	SetDataFolder $savedDF
	return 0
End

// -----------------------------------------------------------------------------
// Diffusion Analysis (Stepsize Histogram, EC folder)
// Same as CalculateStepSizeHistogramHMM + DisplayStepSizeHistogramHMM
// -----------------------------------------------------------------------------

Function ColDiffusionFromList()
	String savedDF = GetDataFolder(1)
	
	// 
	String ecBase = GetECBasePath()
	
	Wave/T/Z List_C1 = root:List_C1
	Wave/T/Z List_C2 = root:List_C2
	
	if(!WaveExists(List_C1) || !WaveExists(List_C2))
		DoAlert 0, "Please create List_C1 and List_C2 first"
		return -1
	endif
	
	NVAR/Z StepFitState = root:StepFitState
	Variable numFitStates = 1
	if(NVAR_Exists(StepFitState))
		numFitStates = StepFitState
	endif
	
	Variable numPairs = min(numpnts(List_C1), numpnts(List_C2))
	Variable i
	
	Print "=== Colocalization Diffusion (Stepsize Histogram) ==="
	Printf "Using %s folder, Δt=1 frame only, Fit states: %d\r", ecBase, numFitStates
	
	for(i = 0; i < numPairs; i += 1)
		String sampleName1 = List_C1[i]
		String sampleName2 = List_C2[i]
		
		Printf "Processing: %s vs %s\r", sampleName1, sampleName2
		
		// Ch1: waveSuffix
		CalculateStepSizeHistogramHMM(sampleName1, basePath=ecBase, useDeltaTMin=1, useDeltaTMax=1, waveSuffix="_C1E")
		FitStepSizeDistributionHMM(sampleName1, numFitStates, basePath=ecBase, useDeltaTMin=1, useDeltaTMax=1, waveSuffix="_C1E")
		DisplayStepSizeHistogramHMM(sampleName1, basePath=ecBase, useDeltaTMin=1, useDeltaTMax=1, waveSuffix="_C1E")
		
		// Ch2: 
		CalculateStepSizeHistogramHMM(sampleName2, basePath=ecBase, useDeltaTMin=1, useDeltaTMax=1, waveSuffix="_C2E")
		FitStepSizeDistributionHMM(sampleName2, numFitStates, basePath=ecBase, useDeltaTMin=1, useDeltaTMax=1, waveSuffix="_C2E")
		DisplayStepSizeHistogramHMM(sampleName2, basePath=ecBase, useDeltaTMin=1, useDeltaTMax=1, waveSuffix="_C2E")
	endfor
	
	// Particle Density
	ColDiffusionStatsFromList()
	
	SetDataFolder $savedDF
	return 0
End

// Rename HMMP to HMMP_C*E in EC folder
Function ColRenameHMMP(sampleName, suffix)
	String sampleName
	String suffix  // "_C1E" or "_C2E"
	
	String savedDF = GetDataFolder(1)
	String ecBase = GetECBasePath() + ":" + sampleName
	
	if(!DataFolderExists(ecBase))
		SetDataFolder $savedDF
		return -1
	endif
	
	Variable numCells = GetCellCount(sampleName)
	Variable m
	
	for(m = 0; m < numCells; m += 1)
		String folderName = sampleName + num2str(m + 1)
		String cellFolder = ecBase + ":" + folderName
		
		if(!DataFolderExists(cellFolder))
			continue
		endif
		
		SetDataFolder $cellFolder
		
		Wave/Z HMMP
		if(WaveExists(HMMP))
			String newName = "HMMP" + suffix
			Duplicate/O HMMP, $newName
			KillWaves/Z HMMP
		endif
	endfor
	
	SetDataFolder $savedDF
	return 0
End
// -----------------------------------------------------------------------------
// ColCalculateAbsoluteHMMP - 
// -----------------------------------------------------------------------------
// EC /  × 100 [%]
// : ColHMMP_abs_C{ch}E [state] - 
//       ColHMMP_abs_C{ch}E_m [state][cell] - Matrix
// : Orig_S0
Function ColCalculateAbsoluteHMMP(sampleName, waveSuffix)
	String sampleName
	String waveSuffix    // "_C1E" or "_C2E"
	
	String savedDF = GetDataFolder(1)
	String ecBase = GetECBasePath()
	String origBase = "root"
	
	NVAR/Z Dstate = root:Dstate
	NVAR/Z cHMM = root:cHMM
	NVAR MeanIntGauss = root:MeanIntGauss
	Variable maxState = 0
	if(NVAR_Exists(cHMM) && cHMM == 1 && NVAR_Exists(Dstate))
		maxState = Dstate
	endif

	Variable meanInt = MeanIntGauss

	Variable numCells = CountDataFoldersInPath(ecBase, sampleName)
	if(numCells == 0)
		SetDataFolder $savedDF
		return -1
	endif

	String ecSamplePath = ecBase + ":" + sampleName + ":"
	String origSamplePath = origBase + ":" + sampleName + ":"
	
	// Matrix
	String matrixPath = ecSamplePath + "Matrix"
	if(!DataFolderExists(matrixPath))
		NewDataFolder $matrixPath
	endif
	
	// Matrix wave: ParticleMolecule
	SetDataFolder $matrixPath
	Variable s, m
	for(s = 0; s <= maxState; s += 1)
		// Particle
		String absMatrixName = "ColHMMP_abs_S" + num2str(s) + waveSuffix + "_m"
		Make/O/N=(numCells) $absMatrixName = NaN
		// Molecule
		String absMolMatrixName = "ColHMMPMol_abs_S" + num2str(s) + waveSuffix + "_m"
		Make/O/N=(numCells) $absMolMatrixName = NaN
	endfor
	
	// 
	for(m = 0; m < numCells; m += 1)
		String folderName = sampleName + num2str(m + 1)
		String ecCellPath = ecSamplePath + folderName
		String origCellPath = origSamplePath + folderName
		
		if(!DataFolderExists(ecCellPath) || !DataFolderExists(origCellPath))
			continue
		endif
		
		SetDataFolder $ecCellPath
		
		// Particle: ColHMMP_abs_waveSuffix
		String absWaveName = "ColHMMP_abs" + waveSuffix
		Make/O/N=(maxState + 1) $absWaveName = NaN
		Wave absWave = $absWaveName
		
		// Molecule: ColHMMPMol_abs_waveSuffix
		String absMolWaveName = "ColHMMPMol_abs" + waveSuffix
		Make/O/N=(maxState + 1) $absMolWaveName = NaN
		Wave absMolWave = $absMolWaveName
		
		// === : Orig_S0===
		// Particle: Orig_S0
		String origRtimeS0Path = origCellPath + ":Rtime_S0"
		Wave/Z origRtimeS0 = $origRtimeS0Path
		Variable origTotalPoints = 0
		if(WaveExists(origRtimeS0))
			Extract/FREE/O origRtimeS0, tempOrigS0, numtype(origRtimeS0) != 2
			origTotalPoints = numpnts(tempOrigS0)
		endif
		
		// Molecule: Orig_S0Osize
		Variable origTotalOsize = 0
		String origIntS0Path = origCellPath + ":Int_S0"
		Wave/Z origIntS0 = $origIntS0Path
		if(WaveExists(origIntS0) && meanInt > 0)
			Variable i, nPts = numpnts(origIntS0)
			for(i = 0; i < nPts; i += 1)
				Variable intVal = origIntS0[i]
				if(numtype(intVal) == 0 && intVal > 0)
					origTotalOsize += intVal / meanInt
				endif
			endfor
		endif
		
		// === ===
		for(s = 0; s <= maxState; s += 1)
			// --- Particle ---
			// EC
			String ecRtimeName = "Rtime_S" + num2str(s) + waveSuffix
			Wave/Z ecRtimeWave = $ecRtimeName
			
			Variable ecPoints = 0
			if(WaveExists(ecRtimeWave))
				Extract/FREE/O ecRtimeWave, tempEC, numtype(ecRtimeWave) != 2
				ecPoints = numpnts(tempEC)
			endif
			
			// Particle: Orig_S0
			if(origTotalPoints > 0)
				absWave[s] = ecPoints / origTotalPoints * 100
			endif
			
			// --- Molecule ---
			// ECOsize
			String ecIntName = "Int_S" + num2str(s) + waveSuffix
			Wave/Z ecIntWave = $ecIntName
			Variable ecTotalOsize = 0
			
			if(WaveExists(ecIntWave) && meanInt > 0)
				nPts = numpnts(ecIntWave)
				for(i = 0; i < nPts; i += 1)
					intVal = ecIntWave[i]
					if(numtype(intVal) == 0 && intVal > 0)
						ecTotalOsize += intVal / meanInt
					endif
				endfor
			endif
			
			// Molecule: OsizeOrig_S0Osize
			if(origTotalOsize > 0)
				absMolWave[s] = ecTotalOsize / origTotalOsize * 100
			endif
			
			// Matrix
			SetDataFolder $matrixPath
			String absMatName = "ColHMMP_abs_S" + num2str(s) + waveSuffix + "_m"
			Wave absMatrix = $absMatName
			absMatrix[m] = absWave[s]
			
			String absMolMatName = "ColHMMPMol_abs_S" + num2str(s) + waveSuffix + "_m"
			Wave absMolMatrix = $absMolMatName
			absMolMatrix[m] = absMolWave[s]
			
			SetDataFolder $ecCellPath
		endfor
	endfor
	
	// ResultsParticleMolecule
	String resultsPath = ecSamplePath + "Results"
	if(!DataFolderExists(resultsPath))
		NewDataFolder $resultsPath
	endif
	
	for(s = 0; s <= maxState; s += 1)
		// Particle
		String srcMatName = "ColHMMP_abs_S" + num2str(s) + waveSuffix + "_m"
		SetDataFolder $matrixPath
		Wave/Z srcMatrix = $srcMatName
		
		if(WaveExists(srcMatrix))
			SetDataFolder $resultsPath
			String avgName = srcMatName + "_avg"
			String semName = srcMatName + "_sem"
			Make/O/N=1 $avgName = NaN
			Make/O/N=1 $semName = NaN
			Wave avgW = $avgName
			Wave semW = $semName
			
			Make/FREE/N=(numCells) tempData
			Variable k, validCount = 0
			for(k = 0; k < numCells; k += 1)
				Variable val = srcMatrix[k]
				if(numtype(val) == 0)
					tempData[validCount] = val
					validCount += 1
				endif
			endfor
			
			if(validCount > 0)
				Redimension/N=(validCount) tempData
				WaveStats/Q tempData
				avgW[0] = V_avg
				if(V_npnts > 1)
					semW[0] = V_sdev / sqrt(V_npnts)
				else
					semW[0] = 0
				endif
			endif
		endif
		
		// Molecule
		srcMatName = "ColHMMPMol_abs_S" + num2str(s) + waveSuffix + "_m"
		SetDataFolder $matrixPath
		Wave/Z srcMatrixMol = $srcMatName
		
		if(WaveExists(srcMatrixMol))
			SetDataFolder $resultsPath
			avgName = srcMatName + "_avg"
			semName = srcMatName + "_sem"
			Make/O/N=1 $avgName = NaN
			Make/O/N=1 $semName = NaN
			Wave avgWMol = $avgName
			Wave semWMol = $semName
			
			Make/FREE/N=(numCells) tempDataMol
			validCount = 0
			for(k = 0; k < numCells; k += 1)
				val = srcMatrixMol[k]
				if(numtype(val) == 0)
					tempDataMol[validCount] = val
					validCount += 1
				endif
			endfor
			
			if(validCount > 0)
				Redimension/N=(validCount) tempDataMol
				WaveStats/Q tempDataMol
				avgWMol[0] = V_avg
				if(V_npnts > 1)
					semWMol[0] = V_sdev / sqrt(V_npnts)
				else
					semWMol[0] = 0
				endif
			endif
		endif
	endfor
	
	SetDataFolder $savedDF
	Printf "  ColHMMP_abs%s calculated for %s\r", waveSuffix, sampleName
	return 0
End

// -----------------------------------------------------------------------------
// ColCalculateSteps - 
// -----------------------------------------------------------------------------
// Particle: 
// Molecule: Osize
Function ColCalculateSteps(sampleName, waveSuffix)
	String sampleName
	String waveSuffix    // "_C1E" or "_C2E"
	
	String savedDF = GetDataFolder(1)
	String ecBase = GetECBasePath()
	
	NVAR/Z Dstate = root:Dstate
	NVAR/Z cHMM = root:cHMM
	NVAR MeanIntGauss = root:MeanIntGauss

	Variable maxState = 0
	if(NVAR_Exists(cHMM) && cHMM == 1 && NVAR_Exists(Dstate))
		maxState = Dstate
	endif

	Variable meanInt = MeanIntGauss

	if(meanInt <= 0)
		Printf "  WARNING: MeanIntGauss not set (<=0), skipping molecule steps calculation in ColCalculateSteps\r"
		SetDataFolder $savedDF
		return -1
	endif

	Variable numCells = CountDataFoldersInPath(ecBase, sampleName)
	if(numCells == 0)
		SetDataFolder $savedDF
		return -1
	endif

	String ecSamplePath = ecBase + ":" + sampleName + ":"

	// Matrix
	String matrixPath = ecSamplePath + "Matrix"
	if(!DataFolderExists(matrixPath))
		NewDataFolder $matrixPath
	endif

	// Matrix waveParticleMolecule
	SetDataFolder $matrixPath
	Variable s, m
	for(s = 0; s <= maxState; s += 1)
		// Particle:
		String stepsMatrixName = "ColSteps_S" + num2str(s) + waveSuffix + "_m"
		Make/O/N=(numCells) $stepsMatrixName = NaN
		// Molecule:
		String stepsMolMatrixName = "ColStepsMol_S" + num2str(s) + waveSuffix + "_m"
		Make/O/N=(numCells) $stepsMolMatrixName = NaN
	endfor

	//
	for(m = 0; m < numCells; m += 1)
		String folderName = sampleName + num2str(m + 1)
		String ecCellPath = ecSamplePath + folderName

		if(!DataFolderExists(ecCellPath))
			continue
		endif

		SetDataFolder $ecCellPath

		// ColSteps_waveSuffixParticle
		String stepsWaveName = "ColSteps" + waveSuffix
		Make/O/N=(maxState + 1) $stepsWaveName = NaN
		Wave stepsWave = $stepsWaveName

		// ColStepsMol_waveSuffixMolecule
		String stepsMolWaveName = "ColStepsMol" + waveSuffix
		Make/O/N=(maxState + 1) $stepsMolWaveName = NaN
		Wave stepsMolWave = $stepsMolWaveName

		//
		for(s = 0; s <= maxState; s += 1)
			// Rtime_Sn_waveSuffix
			String rtimeWaveName = "Rtime_S" + num2str(s) + waveSuffix
			Wave/Z rtimeWave = $rtimeWaveName

			// Int_Sn_waveSuffix
			String intWaveName = "Int_S" + num2str(s) + waveSuffix
			Wave/Z intWave = $intWaveName

			// Particle: NaN
			Variable particleSteps = 0
			if(WaveExists(rtimeWave))
				Extract/FREE/O rtimeWave, tempRtime, numtype(rtimeWave) != 2
				particleSteps = numpnts(tempRtime)
			endif
			stepsWave[s] = particleSteps

			// Molecule: Osize
			Variable moleculeSteps = 0
			if(WaveExists(intWave))
				Variable i, nPts = numpnts(intWave)
				for(i = 0; i < nPts; i += 1)
					Variable intVal = intWave[i]
					if(numtype(intVal) == 0 && intVal > 0)
						moleculeSteps += intVal / meanInt
					endif
				endfor
			endif
			stepsMolWave[s] = moleculeSteps
			
			// Matrix
			SetDataFolder $matrixPath
			String stepsMatName = "ColSteps_S" + num2str(s) + waveSuffix + "_m"
			Wave stepsMatrix = $stepsMatName
			stepsMatrix[m] = particleSteps
			
			String stepsMolMatName = "ColStepsMol_S" + num2str(s) + waveSuffix + "_m"
			Wave stepsMolMatrix = $stepsMolMatName
			stepsMolMatrix[m] = moleculeSteps
			
			SetDataFolder $ecCellPath
		endfor
	endfor
	
	// ResultsParticleMolecule
	String resultsPath = ecSamplePath + "Results"
	if(!DataFolderExists(resultsPath))
		NewDataFolder $resultsPath
	endif
	
	for(s = 0; s <= maxState; s += 1)
		// Particle
		String srcMatName = "ColSteps_S" + num2str(s) + waveSuffix + "_m"
		SetDataFolder $matrixPath
		Wave/Z srcMatrix = $srcMatName
		
		if(WaveExists(srcMatrix))
			SetDataFolder $resultsPath
			String avgName = srcMatName + "_avg"
			String semName = srcMatName + "_sem"
			Make/O/N=1 $avgName = NaN
			Make/O/N=1 $semName = NaN
			Wave avgW = $avgName
			Wave semW = $semName
			
			Make/FREE/N=(numCells) tempData
			Variable k, validCount = 0
			for(k = 0; k < numCells; k += 1)
				Variable val = srcMatrix[k]
				if(numtype(val) == 0)
					tempData[validCount] = val
					validCount += 1
				endif
			endfor
			
			if(validCount > 0)
				Redimension/N=(validCount) tempData
				WaveStats/Q tempData
				avgW[0] = V_avg
				if(V_npnts > 1)
					semW[0] = V_sdev / sqrt(V_npnts)
				else
					semW[0] = 0
				endif
			endif
		endif
		
		// Molecule
		srcMatName = "ColStepsMol_S" + num2str(s) + waveSuffix + "_m"
		SetDataFolder $matrixPath
		Wave/Z srcMatrixMol = $srcMatName
		
		if(WaveExists(srcMatrixMol))
			SetDataFolder $resultsPath
			avgName = srcMatName + "_avg"
			semName = srcMatName + "_sem"
			Make/O/N=1 $avgName = NaN
			Make/O/N=1 $semName = NaN
			Wave avgWMol = $avgName
			Wave semWMol = $semName
			
			Make/FREE/N=(numCells) tempDataMol
			validCount = 0
			for(k = 0; k < numCells; k += 1)
				val = srcMatrixMol[k]
				if(numtype(val) == 0)
					tempDataMol[validCount] = val
					validCount += 1
				endif
			endfor
			
			if(validCount > 0)
				Redimension/N=(validCount) tempDataMol
				WaveStats/Q tempDataMol
				avgWMol[0] = V_avg
				if(V_npnts > 1)
					semWMol[0] = V_sdev / sqrt(V_npnts)
				else
					semWMol[0] = 0
				endif
			endif
		endif
	endfor
	
	// =============================================
	// ColStepsDensity = ColSteps / Area [/um^2]
	// =============================================
	// Determine original channel suffix for area lookup
	String origSuffix
	if(StringMatch(waveSuffix, "_C1E"))
		origSuffix = "1"
	else
		origSuffix = "2"
	endif

	// Get sample names from EC base
	String sampleListStr = GetSampleListForChannel(str2num(origSuffix))
	String origSampleName = sampleName

	for(m = 0; m < numCells; m += 1)
		String fn = sampleName + num2str(m + 1)
		String eccp = ecSamplePath + fn
		if(!DataFolderExists(eccp))
			continue
		endif

		// Get cell area from original data folder
		String origCellPath = "root:" + origSampleName + ":" + fn
		Wave/Z ParaDensityAvg = $(origCellPath + ":ParaDensityAvg")
		Variable cellArea = NaN
		if(WaveExists(ParaDensityAvg) && numpnts(ParaDensityAvg) > 1)
			cellArea = ParaDensityAvg[1]
		endif

		SetDataFolder $eccp

		// Create ColStepsDensity = ColSteps / Area (particle)
		Wave/Z stW = $("ColSteps" + waveSuffix)
		if(WaveExists(stW) && numtype(cellArea) == 0 && cellArea > 0)
			String densPName = "ColStepsDensity" + waveSuffix
			Make/O/N=(maxState + 1) $densPName = NaN
			Wave densPW = $densPName
			for(s = 0; s <= maxState; s += 1)
				if(numtype(stW[s]) == 0)
					densPW[s] = stW[s] / cellArea
				endif
			endfor
		endif

		// Create ColStepsMolDensity = ColStepsMol / Area (molecule)
		Wave/Z stMW = $("ColStepsMol" + waveSuffix)
		if(WaveExists(stMW) && numtype(cellArea) == 0 && cellArea > 0)
			String densMName = "ColStepsMolDensity" + waveSuffix
			Make/O/N=(maxState + 1) $densMName = NaN
			Wave densMW = $densMName
			for(s = 0; s <= maxState; s += 1)
				if(numtype(stMW[s]) == 0)
					densMW[s] = stMW[s] / cellArea
				endif
			endfor
		endif
	endfor

	// Collect density to matrix and compute avg/sem
	SetDataFolder $matrixPath
	for(s = 0; s <= maxState; s += 1)
		// Particle density
		String densPMatName = "ColStepsDensity_S" + num2str(s) + waveSuffix + "_m"
		Make/O/N=(numCells) $densPMatName = NaN
		Wave densPMat = $densPMatName
		// Molecule density
		String densMMatName = "ColStepsMolDensity_S" + num2str(s) + waveSuffix + "_m"
		Make/O/N=(numCells) $densMMatName = NaN
		Wave densMmat = $densMMatName

		for(m = 0; m < numCells; m += 1)
			fn = sampleName + num2str(m + 1)
			eccp = ecSamplePath + fn
			if(!DataFolderExists(eccp))
				continue
			endif
			Wave/Z dpW = $(eccp + ":ColStepsDensity" + waveSuffix)
			if(WaveExists(dpW))
				densPMat[m] = dpW[s]
			endif
			Wave/Z dmW = $(eccp + ":ColStepsMolDensity" + waveSuffix)
			if(WaveExists(dmW))
				densMmat[m] = dmW[s]
			endif
		endfor
	endfor

	// Compute avg/sem for density
	SetDataFolder $resultsPath
	for(s = 0; s <= maxState; s += 1)
		// Particle density
		densPMatName = "ColStepsDensity_S" + num2str(s) + waveSuffix + "_m"
		SetDataFolder $matrixPath
		Wave/Z dpMat = $densPMatName
		if(WaveExists(dpMat))
			SetDataFolder $resultsPath
			Make/O/N=1 $(densPMatName + "_avg") = NaN, $(densPMatName + "_sem") = NaN
			Wave dpAvg = $(densPMatName + "_avg")
			Wave dpSem = $(densPMatName + "_sem")
			Make/FREE/N=(numCells) tmpDP
			Variable vc2 = 0
			for(k = 0; k < numCells; k += 1)
				if(numtype(dpMat[k]) == 0)
					tmpDP[vc2] = dpMat[k]
					vc2 += 1
				endif
			endfor
			if(vc2 > 0)
				Redimension/N=(vc2) tmpDP
				WaveStats/Q tmpDP
				dpAvg[0] = V_avg
				dpSem[0] = vc2 > 1 ? V_sdev / sqrt(V_npnts) : 0
			endif
		endif
		// Molecule density
		densMMatName = "ColStepsMolDensity_S" + num2str(s) + waveSuffix + "_m"
		SetDataFolder $matrixPath
		Wave/Z dmMat = $densMMatName
		if(WaveExists(dmMat))
			SetDataFolder $resultsPath
			Make/O/N=1 $(densMMatName + "_avg") = NaN, $(densMMatName + "_sem") = NaN
			Wave dmAvg = $(densMMatName + "_avg")
			Wave dmSem = $(densMMatName + "_sem")
			Make/FREE/N=(numCells) tmpDM
			vc2 = 0
			for(k = 0; k < numCells; k += 1)
				if(numtype(dmMat[k]) == 0)
					tmpDM[vc2] = dmMat[k]
					vc2 += 1
				endif
			endfor
			if(vc2 > 0)
				Redimension/N=(vc2) tmpDM
				WaveStats/Q tmpDM
				dmAvg[0] = V_avg
				dmSem[0] = vc2 > 1 ? V_sdev / sqrt(V_npnts) : 0
			endif
		endif
	endfor

	SetDataFolder $savedDF
	Printf "  ColSteps%s + ColStepsDensity calculated for %s\r", waveSuffix, sampleName
	return 0
End

// -----------------------------------------------------------------------------
// ColCalculateParticleDensityEC - Particle Density
// -----------------------------------------------------------------------------
//  / (Area × TotalTime) [/µm²]
// Arearoot:SampleName:CellFolder:ParaDensityAvg[1]
// : ColParticleDensity_C{ch}E [state] - 
//       ColParticleDensity_Sn_C{ch}E_m [cell] - Matrix
Function ColCalculateParticleDensityEC(sampleName, waveSuffix)
	String sampleName
	String waveSuffix    // "_C1E" or "_C2E"
	
	String savedDF = GetDataFolder(1)
	String ecBase = GetECBasePath()
	String origBase = "root"
	
	NVAR/Z Dstate = root:Dstate
	NVAR/Z cHMM = root:cHMM
	NVAR/Z FrameNum = root:FrameNum
	NVAR/Z framerate = root:framerate
	
	Variable maxState = 0
	if(NVAR_Exists(cHMM) && cHMM == 1 && NVAR_Exists(Dstate))
		maxState = Dstate
	endif
	
	Variable totalTime = 100  // 
	if(NVAR_Exists(FrameNum) && NVAR_Exists(framerate))
		totalTime = FrameNum * framerate
	endif
	
	Variable numCells = CountDataFoldersInPath(ecBase, sampleName)
	if(numCells == 0)
		SetDataFolder $savedDF
		return -1
	endif
	
	String ecSamplePath = ecBase + ":" + sampleName + ":"
	String origSamplePath = origBase + ":" + sampleName + ":"
	
	// Matrix
	String matrixPath = ecSamplePath + "Matrix"
	if(!DataFolderExists(matrixPath))
		NewDataFolder $matrixPath
	endif
	
	// Matrix wave
	SetDataFolder $matrixPath
	Variable s, m
	for(s = 0; s <= maxState; s += 1)
		String densMatrixName = "ColParticleDensity_S" + num2str(s) + waveSuffix + "_m"
		Make/O/N=(numCells) $densMatrixName = NaN
	endfor
	
	// 
	for(m = 0; m < numCells; m += 1)
		String folderName = sampleName + num2str(m + 1)
		String ecCellPath = ecSamplePath + folderName
		String origCellPath = origSamplePath + folderName
		
		if(!DataFolderExists(ecCellPath) || !DataFolderExists(origCellPath))
			continue
		endif
		
		// Area
		String paraDensPath = origCellPath + ":ParaDensityAvg"
		Wave/Z ParaDensityAvg = $paraDensPath
		
		Variable cellArea = NaN
		if(WaveExists(ParaDensityAvg) && numpnts(ParaDensityAvg) > 1)
			cellArea = ParaDensityAvg[1]  // Area [µm²]
		endif
		
		if(numtype(cellArea) != 0 || cellArea <= 0)
			Printf "    WARNING: Invalid area for %s, skipping\r", folderName
			continue
		endif
		
		SetDataFolder $ecCellPath
		
		// ColParticleDensity_waveSuffix
		String densWaveName = "ColParticleDensity" + waveSuffix
		Make/O/N=(maxState + 1) $densWaveName = NaN
		Wave densWave = $densWaveName
		
		// Particle Density
		for(s = 0; s <= maxState; s += 1)
			// EC≒-1
			// ROI
			String roiWaveName = "ROI_S" + num2str(s) + waveSuffix
			Wave/Z roiWave = $roiWaveName
			
			Variable numSpots = 0
			if(WaveExists(roiWave))
				// ROI
				Make/FREE/N=(numpnts(roiWave)) tempROI
				tempROI = roiWave
				WaveTransform zapNaNs tempROI
				if(numpnts(tempROI) > 0)
					// 
					numSpots = numpnts(tempROI)
				endif
			endif
			
			// Particle Density =  / (Area × TotalTime) × framerate
			// = / / Area
			if(numSpots > 0 && cellArea > 0)
				// numSpots×TotalFrames/
				Variable avgSpotsPerFrame = numSpots / FrameNum
				densWave[s] = avgSpotsPerFrame / cellArea
			endif
			
			// Matrix
			SetDataFolder $matrixPath
			String densMatName = "ColParticleDensity_S" + num2str(s) + waveSuffix + "_m"
			Wave densMatrix = $densMatName
			densMatrix[m] = densWave[s]
			SetDataFolder $ecCellPath
		endfor
	endfor
	
	// Results
	String resultsPath = ecSamplePath + "Results"
	if(!DataFolderExists(resultsPath))
		NewDataFolder $resultsPath
	endif
	SetDataFolder $resultsPath
	
	for(s = 0; s <= maxState; s += 1)
		String srcMatName = "ColParticleDensity_S" + num2str(s) + waveSuffix + "_m"
		SetDataFolder $matrixPath
		Wave/Z srcMatrix = $srcMatName
		
		if(!WaveExists(srcMatrix))
			continue
		endif
		
		SetDataFolder $resultsPath
		
		String avgName = srcMatName + "_avg"
		String semName = srcMatName + "_sem"
		Make/O/N=1 $avgName = NaN
		Make/O/N=1 $semName = NaN
		Wave avgW = $avgName
		Wave semW = $semName
		
		Make/FREE/N=(numCells) tempData
		Variable k, validCount = 0
		for(k = 0; k < numCells; k += 1)
			Variable val = srcMatrix[k]
			if(numtype(val) == 0)
				tempData[validCount] = val
				validCount += 1
			endif
		endfor
		
		if(validCount > 0)
			Redimension/N=(validCount) tempData
			WaveStats/Q tempData
			avgW[0] = V_avg
			if(V_npnts > 1)
				semW[0] = V_sdev / sqrt(V_npnts)
			else
				semW[0] = 0
			endif
		endif
	endfor
	
	SetDataFolder $savedDF
	Printf "  ColParticleDensity%s calculated for %s\r", waveSuffix, sampleName
	return 0
End

// -----------------------------------------------------------------------------
// ColCalculateMolecularDensityEC - Molecular Density
// -----------------------------------------------------------------------------
// Molecular Density = Σ(Int/MeanIntGauss) / FrameNum / Area [molecules/µm²]
// OsizeCol_Sn_waveSuffix 
// : ColMolecularDensity_Sn_waveSuffix_m [cell]
Function ColCalculateMolecularDensityEC(sampleName, waveSuffix)
	String sampleName
	String waveSuffix    // "_C1E" or "_C2E"
	
	String savedDF = GetDataFolder(1)
	String ecBase = GetECBasePath()
	String origBase = "root"
	
	NVAR/Z Dstate = root:Dstate
	NVAR/Z cHMM = root:cHMM
	NVAR FrameNum = root:FrameNum

	Variable maxState = 0
	if(NVAR_Exists(cHMM) && cHMM == 1 && NVAR_Exists(Dstate))
		maxState = Dstate
	endif

	Variable frameNumVal = FrameNum

	Variable numCells = CountDataFoldersInPath(ecBase, sampleName)
	if(numCells == 0)
		SetDataFolder $savedDF
		return -1
	endif
	
	String ecSamplePath = ecBase + ":" + sampleName + ":"
	String origSamplePath = origBase + ":" + sampleName + ":"
	
	// Matrix
	String matrixPath = ecSamplePath + "Matrix"
	if(!DataFolderExists(matrixPath))
		NewDataFolder $matrixPath
	endif
	
	// Matrix wave
	SetDataFolder $matrixPath
	Variable s, m
	for(s = 0; s <= maxState; s += 1)
		String densMatrixName = "ColMolecularDensity_S" + num2str(s) + waveSuffix + "_m"
		Make/O/N=(numCells) $densMatrixName = NaN
	endfor
	
	// 
	for(m = 0; m < numCells; m += 1)
		String folderName = sampleName + num2str(m + 1)
		String ecCellPath = ecSamplePath + folderName
		String origCellPath = origSamplePath + folderName
		
		if(!DataFolderExists(ecCellPath) || !DataFolderExists(origCellPath))
			continue
		endif
		
		// Area
		String paraDensPath = origCellPath + ":ParaDensityAvg"
		Wave/Z ParaDensityAvg = $paraDensPath
		
		Variable cellArea = NaN
		if(WaveExists(ParaDensityAvg) && numpnts(ParaDensityAvg) > 1)
			cellArea = ParaDensityAvg[1]  // Area [µm²]
		endif
		
		if(numtype(cellArea) != 0 || cellArea <= 0)
			continue
		endif
		
		SetDataFolder $ecCellPath
		
		// ColMolecularDensity_waveSuffix
		String densWaveName = "ColMolecularDensity" + waveSuffix
		Make/O/N=(maxState + 1) $densWaveName = NaN
		Wave densWave = $densWaveName
		
		// 
		for(s = 0; s <= maxState; s += 1)
			// OsizeCol_Sn_waveSuffix 
			String osizeColName = "OsizeCol_S" + num2str(s) + waveSuffix
			Wave/Z OsizeColWave = $osizeColName
			
			Variable totalMolecules = 0
			if(WaveExists(OsizeColWave))
				// OsizeCol = 
				WaveStats/Q OsizeColWave
				totalMolecules = V_sum
			endif
			
			// Molecular Density =  / FrameNum / Area
			// = / / Area [molecules/µm²]
			if(totalMolecules > 0 && cellArea > 0 && frameNumVal > 0)
				densWave[s] = totalMolecules / frameNumVal / cellArea
			endif
			
			// Matrix
			SetDataFolder $matrixPath
			String densMatName = "ColMolecularDensity_S" + num2str(s) + waveSuffix + "_m"
			Wave densMatrix = $densMatName
			densMatrix[m] = densWave[s]
			SetDataFolder $ecCellPath
		endfor
	endfor
	
	// Results
	String resultsPath = ecSamplePath + "Results"
	if(!DataFolderExists(resultsPath))
		NewDataFolder $resultsPath
	endif
	
	for(s = 0; s <= maxState; s += 1)
		String srcMatName = "ColMolecularDensity_S" + num2str(s) + waveSuffix + "_m"
		SetDataFolder $matrixPath
		Wave/Z srcMatrix = $srcMatName
		
		if(!WaveExists(srcMatrix))
			continue
		endif
		
		SetDataFolder $resultsPath
		
		String avgName = srcMatName + "_avg"
		String semName = srcMatName + "_sem"
		Make/O/N=1 $avgName = NaN
		Make/O/N=1 $semName = NaN
		Wave avgW = $avgName
		Wave semW = $semName
		
		Make/FREE/N=(numCells) tempData
		Variable k, validCount = 0
		for(k = 0; k < numCells; k += 1)
			Variable val = srcMatrix[k]
			if(numtype(val) == 0)
				tempData[validCount] = val
				validCount += 1
			endif
		endfor
		
		if(validCount > 0)
			Redimension/N=(validCount) tempData
			WaveStats/Q tempData
			avgW[0] = V_avg
			if(V_npnts > 1)
				semW[0] = V_sdev / sqrt(V_npnts)
			else
				semW[0] = 0
			endif
		endif
	endfor
	
	SetDataFolder $savedDF
	Printf "  ColMolecularDensity%s calculated for %s\r", waveSuffix, sampleName
	return 0
End

// -----------------------------------------------------------------------------
// ColCalculateKbByState - KbParticle
// -----------------------------------------------------------------------------
// Kb_s = (Tcol_s/AreaMin) * FrameNum / ((Tall1_s/Area1 - Tcol_s/AreaMin) * (Tall2_s/Area2 - Tcol_s/AreaMin))
// : ColKb_Sn_waveSuffix_m [cell] - Kb
Function ColCalculateKbByState(sampleName1, sampleName2, waveSuffix)
	String sampleName1   // Ch1 sample name
	String sampleName2   // Ch2 sample name (for paired calculation)
	String waveSuffix    // "_C1E" or "_C2E"
	
	String savedDF = GetDataFolder(1)
	String ecBase = GetECBasePath()
	String origBase = "root"
	
	NVAR/Z gDstate = root:Dstate
	NVAR/Z cHMM = root:cHMM
	NVAR FrameNum = root:FrameNum

	Variable maxState = 0
	if(NVAR_Exists(cHMM) && cHMM == 1 && NVAR_Exists(gDstate))
		maxState = gDstate
	endif

	Variable frameNumVal = FrameNum

	// EC
	String ecSampleName = SelectString(StringMatch(waveSuffix, "*C1*"), sampleName2, sampleName1)
	String origSampleName1 = sampleName1
	String origSampleName2 = sampleName2
	
	Variable numCells = CountDataFoldersInPath(ecBase, ecSampleName)
	if(numCells == 0)
		SetDataFolder $savedDF
		return -1
	endif
	
	String ecSamplePath = ecBase + ":" + ecSampleName + ":"
	
	// Matrix
	String matrixPath = ecSamplePath + "Matrix"
	if(!DataFolderExists(matrixPath))
		NewDataFolder $matrixPath
	endif
	
	// Matrix wave: ColKb_Sn_waveSuffix_m [cell]
	SetDataFolder $matrixPath
	Variable s
	for(s = 0; s <= maxState; s += 1)
		String kbMatrixName = "ColKb_S" + num2str(s) + waveSuffix + "_m"
		Make/O/N=(numCells) $kbMatrixName = NaN
	endfor
	
	// 
	Variable m
	for(m = 0; m < numCells; m += 1)
		String folderName1 = origSampleName1 + num2str(m + 1)
		String folderName2 = origSampleName2 + num2str(m + 1)
		String ecFolderName = ecSampleName + num2str(m + 1)
		
		String origCellPath1 = origBase + ":" + origSampleName1 + ":" + folderName1
		String origCellPath2 = origBase + ":" + origSampleName2 + ":" + folderName2
		String ecCellPath = ecSamplePath + ecFolderName
		
		if(!DataFolderExists(ecCellPath))
			continue
		endif
		
		// Area
		SetDataFolder $origCellPath1
		Wave/Z ParaDensityAvg1 = ParaDensityAvg
		Variable Area1 = WaveExists(ParaDensityAvg1) ? ParaDensityAvg1[1] : 0
		
		SetDataFolder $origCellPath2
		Wave/Z ParaDensityAvg2 = ParaDensityAvg
		Variable Area2 = WaveExists(ParaDensityAvg2) ? ParaDensityAvg2[1] : 0
		
		if(Area1 <= 0 || Area2 <= 0)
			continue
		endif
		
		NVAR/Z ColAreaMode = root:ColAreaMode
		Variable areaMode = NVAR_Exists(ColAreaMode) ? ColAreaMode : 1  // 0=Min, 1=Max
		Variable AreaMin = (areaMode == 0) ? min(Area1, Area2) : max(Area1, Area2)
		
		// 
		for(s = 0; s <= maxState; s += 1)
			// Tall1_s, Tall2_s
			String origRtime1Name = "Rtime_S" + num2str(s)
			String origRtime2Name = "Rtime_S" + num2str(s)
			
			SetDataFolder $origCellPath1
			Wave/Z origRtime1 = $origRtime1Name
			Variable Tall1_s = 0
			if(WaveExists(origRtime1))
				Extract/FREE/O origRtime1, tempOrig1, numtype(origRtime1) != 2
				Tall1_s = numpnts(tempOrig1)
			endif
			
			SetDataFolder $origCellPath2
			Wave/Z origRtime2 = $origRtime2Name
			Variable Tall2_s = 0
			if(WaveExists(origRtime2))
				Extract/FREE/O origRtime2, tempOrig2, numtype(origRtime2) != 2
				Tall2_s = numpnts(tempOrig2)
			endif
			
			// ECTcol_s
			SetDataFolder $ecCellPath
			String ecRtimeName = "Rtime_S" + num2str(s) + waveSuffix
			Wave/Z ecRtime = $ecRtimeName
			Variable Tcol_s = 0
			if(WaveExists(ecRtime))
				Extract/FREE/O ecRtime, tempEC, numtype(ecRtime) != 2
				Tcol_s = numpnts(tempEC)
			endif
			
			// Kb (particle): A_free/B_free use same-channel normalization
			Variable A_free = (Tall1_s - Tcol_s) / Area1
			Variable B_free = (Tall2_s - Tcol_s) / Area2

			Variable Kb_s = NaN
			if(A_free > 0 && B_free > 0 && AreaMin > 0)
				Kb_s = (Tcol_s/AreaMin) * frameNumVal / (A_free * B_free)
			endif
			
			// Matrix
			SetDataFolder $matrixPath
			String kbMatName = "ColKb_S" + num2str(s) + waveSuffix + "_m"
			Wave kbMatrix = $kbMatName
			kbMatrix[m] = Kb_s
		endfor
	endfor
	
	// Results
	String resultsPath = ecSamplePath + "Results"
	if(!DataFolderExists(resultsPath))
		NewDataFolder $resultsPath
	endif
	
	for(s = 0; s <= maxState; s += 1)
		String srcMatName = "ColKb_S" + num2str(s) + waveSuffix + "_m"
		SetDataFolder $matrixPath
		Wave/Z srcMatrix = $srcMatName
		
		if(!WaveExists(srcMatrix))
			continue
		endif
		
		SetDataFolder $resultsPath
		
		String avgName = srcMatName + "_avg"
		String semName = srcMatName + "_sem"
		Make/O/N=1 $avgName = NaN
		Make/O/N=1 $semName = NaN
		Wave avgW = $avgName
		Wave semW = $semName
		
		Make/FREE/N=(numCells) tempData
		Variable k, validCount = 0
		for(k = 0; k < numCells; k += 1)
			Variable val = srcMatrix[k]
			if(numtype(val) == 0)
				tempData[validCount] = val
				validCount += 1
			endif
		endfor
		
		if(validCount > 0)
			Redimension/N=(validCount) tempData
			WaveStats/Q tempData
			avgW[0] = V_avg
			if(V_npnts > 1)
				semW[0] = V_sdev / sqrt(V_npnts)
			else
				semW[0] = 0
			endif
		endif
	endfor
	
	SetDataFolder $savedDF
	Printf "  ColKb%s calculated by state for %s\r", waveSuffix, ecSampleName
	return 0
End

// -----------------------------------------------------------------------------
// ColCalculateKbByStateMol - KbMolecule
// -----------------------------------------------------------------------------
// Kb_mol_s = (Mcol_s/AreaMin) * FrameNum / ((Mall1_s/Area1 - Mcol_s/AreaMin) * (Mall2_s/Area2 - Mcol_s/AreaMin))
// Mcol_s = Σ(OsizeCol_Sn) in EC folder ()
// Mall_s = Σ(Int_Sn / MeanIntGauss) in original folder ()
// : ColKbMol_Sn_waveSuffix_m [cell] - Kb()
Function ColCalculateKbByStateMol(sampleName1, sampleName2, waveSuffix)
	String sampleName1   // Ch1 sample name
	String sampleName2   // Ch2 sample name (for paired calculation)
	String waveSuffix    // "_C1E" or "_C2E"
	
	String savedDF = GetDataFolder(1)
	String ecBase = GetECBasePath()
	String origBase = "root"
	
	NVAR/Z gDstate = root:Dstate
	NVAR/Z cHMM = root:cHMM
	NVAR FrameNum = root:FrameNum
	NVAR MeanIntGauss = root:MeanIntGauss

	Variable maxState = 0
	if(NVAR_Exists(cHMM) && cHMM == 1 && NVAR_Exists(gDstate))
		maxState = gDstate
	endif

	Variable frameNumVal = FrameNum
	Variable meanInt = MeanIntGauss

	if(meanInt <= 0)
		Printf "  WARNING: MeanIntGauss not set, skipping Kb_mol calculation\r"
		SetDataFolder $savedDF
		return -1
	endif
	
	// EC
	String ecSampleName = SelectString(StringMatch(waveSuffix, "*C1*"), sampleName2, sampleName1)
	String origSampleName1 = sampleName1
	String origSampleName2 = sampleName2
	
	Variable numCells = CountDataFoldersInPath(ecBase, ecSampleName)
	if(numCells == 0)
		SetDataFolder $savedDF
		return -1
	endif
	
	String ecSamplePath = ecBase + ":" + ecSampleName + ":"
	
	// Matrix
	String matrixPath = ecSamplePath + "Matrix"
	if(!DataFolderExists(matrixPath))
		NewDataFolder $matrixPath
	endif
	
	// Matrix wave: ColKbMol_Sn_waveSuffix_m [cell]
	SetDataFolder $matrixPath
	Variable s
	for(s = 0; s <= maxState; s += 1)
		String kbMatrixName = "ColKbMol_S" + num2str(s) + waveSuffix + "_m"
		Make/O/N=(numCells) $kbMatrixName = NaN
	endfor
	
	// 
	Variable m
	for(m = 0; m < numCells; m += 1)
		String folderName1 = origSampleName1 + num2str(m + 1)
		String folderName2 = origSampleName2 + num2str(m + 1)
		String ecFolderName = ecSampleName + num2str(m + 1)
		
		String origCellPath1 = origBase + ":" + origSampleName1 + ":" + folderName1
		String origCellPath2 = origBase + ":" + origSampleName2 + ":" + folderName2
		String ecCellPath = ecSamplePath + ecFolderName
		
		if(!DataFolderExists(ecCellPath))
			continue
		endif
		
		// Area
		SetDataFolder $origCellPath1
		Wave/Z ParaDensityAvg1 = ParaDensityAvg
		Variable Area1 = WaveExists(ParaDensityAvg1) ? ParaDensityAvg1[1] : 0
		
		SetDataFolder $origCellPath2
		Wave/Z ParaDensityAvg2 = ParaDensityAvg
		Variable Area2 = WaveExists(ParaDensityAvg2) ? ParaDensityAvg2[1] : 0
		
		if(Area1 <= 0 || Area2 <= 0)
			continue
		endif
		
		NVAR/Z ColAreaMode = root:ColAreaMode
		Variable areaMode = NVAR_Exists(ColAreaMode) ? ColAreaMode : 1  // 0=Min, 1=Max
		Variable AreaMin = (areaMode == 0) ? min(Area1, Area2) : max(Area1, Area2)
		
		// 
		for(s = 0; s <= maxState; s += 1)
			// Mall1_s, Mall2_s = Σ(Int_Sn / MeanIntGauss)
			String origInt1Name = "Int_S" + num2str(s)
			String origInt2Name = "Int_S" + num2str(s)
			
			SetDataFolder $origCellPath1
			Wave/Z origInt1 = $origInt1Name
			Variable Mall1_s = 0
			if(WaveExists(origInt1))
				Variable i, nPts = numpnts(origInt1)
				for(i = 0; i < nPts; i += 1)
					Variable intVal = origInt1[i]
					if(numtype(intVal) == 0 && intVal > 0)
						Mall1_s += intVal / meanInt
					endif
				endfor
			endif
			
			SetDataFolder $origCellPath2
			Wave/Z origInt2 = $origInt2Name
			Variable Mall2_s = 0
			if(WaveExists(origInt2))
				nPts = numpnts(origInt2)
				for(i = 0; i < nPts; i += 1)
					intVal = origInt2[i]
					if(numtype(intVal) == 0 && intVal > 0)
						Mall2_s += intVal / meanInt
					endif
				endfor
			endif
			
			// EC: Mcol per channel — each channel's colocalized molecule count
			// Mcol_ch1 = Σ(OsizeCol_Sn_C1E), Mcol_ch2 = Σ(OsizeCol_Sn_C2E)
			// A_free uses Ch1's Mcol, B_free uses Ch2's Mcol (regardless of waveSuffix)
			String ecCellPath1 = GetECBasePath() + ":" + origSampleName1 + ":" + origSampleName1 + num2str(m + 1)
			String ecCellPath2 = GetECBasePath() + ":" + origSampleName2 + ":" + origSampleName2 + num2str(m + 1)

			Variable Mcol_ch1 = 0
			if(DataFolderExists(ecCellPath1))
				SetDataFolder $ecCellPath1
				String osizeC1Name = "OsizeCol_S" + num2str(s) + "_C1E"
				Wave/Z OsizeC1Wave = $osizeC1Name
				if(WaveExists(OsizeC1Wave))
					WaveStats/Q OsizeC1Wave
					Mcol_ch1 = V_sum
				endif
			endif

			Variable Mcol_ch2 = 0
			if(DataFolderExists(ecCellPath2))
				SetDataFolder $ecCellPath2
				String osizeC2Name = "OsizeCol_S" + num2str(s) + "_C2E"
				Wave/Z OsizeC2Wave = $osizeC2Name
				if(WaveExists(OsizeC2Wave))
					WaveStats/Q OsizeC2Wave
					Mcol_ch2 = V_sum
				endif
			endif

			// Kb_mol: A_free/B_free use same-channel normalization (Mall - Mcol always >= 0)
			// Mcol_complex = geometric mean of Ch1 and Ch2 coloc molecule counts
			Variable Mcol_mean = sqrt(Mcol_ch1 * Mcol_ch2)
			Variable A_free = (Mall1_s - Mcol_ch1) / Area1
			Variable B_free = (Mall2_s - Mcol_ch2) / Area2

			Variable Kb_mol_s = NaN
			if(A_free > 0 && B_free > 0 && AreaMin > 0)
				Kb_mol_s = (Mcol_mean/AreaMin) * frameNumVal / (A_free * B_free)
			endif
			
			// Matrix
			SetDataFolder $matrixPath
			String kbMatName = "ColKbMol_S" + num2str(s) + waveSuffix + "_m"
			Wave kbMatrix = $kbMatName
			kbMatrix[m] = Kb_mol_s
		endfor
	endfor
	
	// Results
	String resultsPath = ecSamplePath + "Results"
	if(!DataFolderExists(resultsPath))
		NewDataFolder $resultsPath
	endif
	
	for(s = 0; s <= maxState; s += 1)
		String srcMatName = "ColKbMol_S" + num2str(s) + waveSuffix + "_m"
		SetDataFolder $matrixPath
		Wave/Z srcMatrix = $srcMatName
		
		if(!WaveExists(srcMatrix))
			continue
		endif
		
		SetDataFolder $resultsPath
		
		String avgName = srcMatName + "_avg"
		String semName = srcMatName + "_sem"
		Make/O/N=1 $avgName = NaN
		Make/O/N=1 $semName = NaN
		Wave avgW = $avgName
		Wave semW = $semName
		
		Make/FREE/N=(numCells) tempData
		Variable k, validCount = 0
		for(k = 0; k < numCells; k += 1)
			Variable val = srcMatrix[k]
			if(numtype(val) == 0)
				tempData[validCount] = val
				validCount += 1
			endif
		endfor
		
		if(validCount > 0)
			Redimension/N=(validCount) tempData
			WaveStats/Q tempData
			avgW[0] = V_avg
			if(V_npnts > 1)
				semW[0] = V_sdev / sqrt(V_npnts)
			else
				semW[0] = 0
			endif
		endif
	endfor
	
	SetDataFolder $savedDF
	Printf "  ColKbMol%s calculated by state for %s\r", waveSuffix, ecSampleName
	return 0
End

// -----------------------------------------------------------------------------
// ColDiffusionStatsFromList - 
// -----------------------------------------------------------------------------
// ColDiffusionFromList()
Function ColDiffusionStatsFromList()
	String savedDF = GetDataFolder(1)
	
	Wave/T/Z List_C1 = root:List_C1
	Wave/T/Z List_C2 = root:List_C2
	
	if(!WaveExists(List_C1) || !WaveExists(List_C2))
		DoAlert 0, "Please create List_C1 and List_C2 first"
		return -1
	endif
	
	Variable numPairs = min(numpnts(List_C1), numpnts(List_C2))
	Variable i
	
	Print "=== Colocalization D-state Statistics ==="
	Print "Calculating Absolute HMMP and Steps..."
	
	for(i = 0; i < numPairs; i += 1)
		String sampleName1 = List_C1[i]
		String sampleName2 = List_C2[i]
		
		Printf "Processing: %s vs %s\r", sampleName1, sampleName2
		
		// ParticleMolecule
		ColCalculateAbsoluteHMMP(sampleName1, "_C1E")
		ColCalculateAbsoluteHMMP(sampleName2, "_C2E")
		
		// ParticleMolecule
		ColCalculateSteps(sampleName1, "_C1E")
		ColCalculateSteps(sampleName2, "_C2E")
	endfor
	
	SetDataFolder $savedDF
	Print "D-state statistics calculation complete"
	return 0
End

// -----------------------------------------------------------------------------
// ColAffinityStatsFromList - Particle DensityKb
// -----------------------------------------------------------------------------
Function ColAffinityStatsFromList()
	String savedDF = GetDataFolder(1)
	
	Wave/T/Z List_C1 = root:List_C1
	Wave/T/Z List_C2 = root:List_C2
	
	if(!WaveExists(List_C1) || !WaveExists(List_C2))
		DoAlert 0, "Please create List_C1 and List_C2 first"
		return -1
	endif
	
	Variable numPairs = min(numpnts(List_C1), numpnts(List_C2))
	Variable i
	
	Print "=== Colocalization Affinity Statistics ==="
	Print "Calculating Particle/Molecular Density and Kb by state..."
	
	for(i = 0; i < numPairs; i += 1)
		String sampleName1 = List_C1[i]
		String sampleName2 = List_C2[i]
		
		Printf "Processing: %s vs %s\r", sampleName1, sampleName2
		
		// Particle Density ()
		ColCalculateParticleDensityEC(sampleName1, "_C1E")
		ColCalculateParticleDensityEC(sampleName2, "_C2E")
		
		// Molecular Density ()
		ColCalculateMolecularDensityEC(sampleName1, "_C1E")
		ColCalculateMolecularDensityEC(sampleName2, "_C2E")
		
		// Kb by state (Particle-based)
		ColCalculateKbByState(sampleName1, sampleName2, "_C1E")
		ColCalculateKbByState(sampleName1, sampleName2, "_C2E")
		
		// Kb by state (Molecule-based)
		ColCalculateKbByStateMol(sampleName1, sampleName2, "_C1E")
		ColCalculateKbByStateMol(sampleName1, sampleName2, "_C2E")
	endfor
	
	SetDataFolder $savedDF
	Print "Affinity statistics calculation complete"
	return 0
End

// -----------------------------------------------------------------------------
// ColCalculateOntimeSimple - On-time
// -----------------------------------------------------------------------------
Function ColCalculateOntimeSimple(sampleName, waveSuffix)
	String sampleName
	String waveSuffix    // "_C1E" or "_C2E"
	
	String savedDF = GetDataFolder(1)
	String ecBase = GetECBasePath()
	
	NVAR/Z Dstate = root:Dstate
	NVAR/Z cHMM = root:cHMM
	NVAR framerate = root:framerate
	NVAR MeanIntGauss = root:MeanIntGauss

	Variable maxState = 0
	if(NVAR_Exists(cHMM) && cHMM == 1 && NVAR_Exists(Dstate))
		maxState = Dstate
	endif

	Variable fr = framerate

	Variable meanInt = MeanIntGauss
	
	Variable numCells = CountDataFoldersInPath(ecBase, sampleName)
	if(numCells == 0)
		SetDataFolder $savedDF
		return -1
	endif
	
	String ecSamplePath = ecBase + ":" + sampleName + ":"
	
	// Matrix
	String matrixPath = ecSamplePath + "Matrix"
	if(!DataFolderExists(matrixPath))
		NewDataFolder $matrixPath
	endif
	
	// Matrix waveParticleMolecule
	SetDataFolder $matrixPath
	Variable s, m
	for(s = 0; s <= maxState; s += 1)
		// Particle
		String matrixName = "Ontime_mean_S" + num2str(s) + waveSuffix + "_m"
		Make/O/N=(numCells) $matrixName = NaN
		// Molecule
		String matrixMolName = "OntimeMol_mean_S" + num2str(s) + waveSuffix + "_m"
		Make/O/N=(numCells) $matrixMolName = NaN
	endfor
	
	// 
	for(m = 0; m < numCells; m += 1)
		String folderName = sampleName + num2str(m + 1)
		String ecCellPath = ecSamplePath + folderName
		
		if(!DataFolderExists(ecCellPath))
			continue
		endif
		
		SetDataFolder $ecCellPath
		
		// ROI_S0_waveSuffix  Rframe_S0_waveSuffix 
		String roiWaveName = "ROI_S0" + waveSuffix
		String rframeWaveName = "Rframe_S0" + waveSuffix
		String dstateWaveName = "Dstate_S0" + waveSuffix
		String intWaveName = "Int_S0" + waveSuffix
		
		Wave/Z ROI_wave = $roiWaveName
		Wave/Z Rframe_wave = $rframeWaveName
		Wave/Z Dstate_wave = $dstateWaveName
		Wave/Z Int_wave = $intWaveName
		
		if(!WaveExists(ROI_wave) || !WaveExists(Rframe_wave))
			continue
		endif
		
		Variable numPts = numpnts(ROI_wave)
		if(numPts == 0)
			continue
		endif
		
		// --- S0: ---
		// ROINaN
		Make/FREE/N=(numPts) tempROI
		tempROI = ROI_wave
		WaveTransform zapNaNs tempROI  // NaN
		Variable validPts = numpnts(tempROI)
		if(validPts == 0)
			continue
		endif
		
		// FindDuplicates2
		Make/FREE/N=0 uniqueROIs
		if(validPts == 1)
			// 1ROI
			Redimension/N=1 uniqueROIs
			uniqueROIs[0] = tempROI[0]
		else
			FindDuplicates/FREE/RN=uniqueROIs tempROI
		endif
		
		Variable numTrajectories = numpnts(uniqueROIs)
		if(numTrajectories == 0)
			continue
		endif
		
		// Osize
		Make/FREE/N=(numTrajectories) trajDurations = NaN
		Make/FREE/N=(numTrajectories) trajMeanOsize = NaN
		
		Variable t, i
		Variable debugTotalFrames = 0  // : 
		for(t = 0; t < numTrajectories; t += 1)
			Variable roiNum = uniqueROIs[t]
			
			// Osize
			Variable frameCount = 0
			Variable osizeSum = 0
			Variable osizeCount = 0
			
			for(i = 0; i < numPts; i += 1)
				// NaNROI_wave[i]NaN
				if(numtype(ROI_wave[i]) == 0 && ROI_wave[i] == roiNum)
					frameCount += 1
					// Osize
					if(WaveExists(Int_wave) && meanInt > 0)
						Variable intVal = Int_wave[i]
						if(numtype(intVal) == 0 && intVal > 0)
							osizeSum += intVal / meanInt
							osizeCount += 1
						endif
					endif
				endif
			endfor
			
			trajDurations[t] = frameCount * fr  //  → 
			debugTotalFrames += frameCount
			
			// Osize
			if(osizeCount > 0)
				trajMeanOsize[t] = osizeSum / osizeCount
			else
				trajMeanOsize[t] = 1  // 
			endif
		endfor
		
		WaveStats/Q trajDurations
		
		SetDataFolder $matrixPath
		String matName = "Ontime_mean_S0" + waveSuffix + "_m"
		Wave mat = $matName
		mat[m] = V_avg
		
		// Molecule: Osize
		// Weighted Mean Duration = Σ(Duration × MeanOsize) / Σ(MeanOsize)
		Make/FREE/N=(numTrajectories) weightedDur
		weightedDur = trajDurations * trajMeanOsize
		Variable sumWeightedDur = sum(weightedDur)
		Variable sumOsize = sum(trajMeanOsize)
		
		String matMolName = "OntimeMol_mean_S0" + waveSuffix + "_m"
		Wave matMol = $matMolName
		if(sumOsize > 0)
			matMol[m] = sumWeightedDur / sumOsize
		endif
		
		// wave
		SetDataFolder $ecCellPath
		String trajDurName = "TrajDuration" + waveSuffix
		Duplicate/O trajDurations, $trajDurName
		String trajOsizeName = "TrajMeanOsize" + waveSuffix
		Duplicate/O trajMeanOsize, $trajOsizeName
		
		// --- S1-Sn:  ---
		if(maxState > 0 && WaveExists(Dstate_wave))
			for(s = 1; s <= maxState; s += 1)
				// Osize
				Make/FREE/N=0 stateDurations
				Make/FREE/N=0 stateMeanOsize
				
				for(t = 0; t < numTrajectories; t += 1)
					roiNum = uniqueROIs[t]
					
					// DstateInt
					Make/FREE/N=0 trajFrames, trajDstates, trajInts
					for(i = 0; i < numPts; i += 1)
						// NaN
						if(numtype(ROI_wave[i]) == 0 && ROI_wave[i] == roiNum)
							Variable n = numpnts(trajFrames)
							InsertPoints n, 1, trajFrames, trajDstates, trajInts
							trajFrames[n] = Rframe_wave[i]
							trajDstates[n] = Dstate_wave[i]
							if(WaveExists(Int_wave))
								trajInts[n] = Int_wave[i]
							else
								trajInts[n] = meanInt
							endif
						endif
					endfor
					
					// 
					if(numpnts(trajFrames) > 1)
						Sort trajFrames, trajFrames, trajDstates, trajInts
					endif
					
					// 
					Variable inState = 0
					Variable stateStart = 0
					Variable stateOsizeSum = 0
					Variable stateOsizeCount = 0
					Variable j
					for(j = 0; j < numpnts(trajDstates); j += 1)
						if(trajDstates[j] == s)
							if(!inState)
								inState = 1
								stateStart = j
								stateOsizeSum = 0
								stateOsizeCount = 0
							endif
							// Osize
							if(meanInt > 0 && numtype(trajInts[j]) == 0 && trajInts[j] > 0)
								stateOsizeSum += trajInts[j] / meanInt
								stateOsizeCount += 1
							endif
						else
							if(inState)
								// 
								Variable duration = (j - stateStart) * fr
								n = numpnts(stateDurations)
								InsertPoints n, 1, stateDurations, stateMeanOsize
								stateDurations[n] = duration
								if(stateOsizeCount > 0)
									stateMeanOsize[n] = stateOsizeSum / stateOsizeCount
								else
									stateMeanOsize[n] = 1
								endif
								inState = 0
							endif
						endif
					endfor
					// 
					if(inState)
						duration = (numpnts(trajDstates) - stateStart) * fr
						n = numpnts(stateDurations)
						InsertPoints n, 1, stateDurations, stateMeanOsize
						stateDurations[n] = duration
						if(stateOsizeCount > 0)
							stateMeanOsize[n] = stateOsizeSum / stateOsizeCount
						else
							stateMeanOsize[n] = 1
						endif
					endif
				endfor
				
				// 
				if(numpnts(stateDurations) > 0)
					// Particle
					WaveStats/Q stateDurations
					
					SetDataFolder $matrixPath
					matName = "Ontime_mean_S" + num2str(s) + waveSuffix + "_m"
					Wave matS = $matName
					matS[m] = V_avg
					
					// Molecule
					Make/FREE/N=(numpnts(stateDurations)) stateWeightedDur
					stateWeightedDur = stateDurations * stateMeanOsize
					sumWeightedDur = sum(stateWeightedDur)
					sumOsize = sum(stateMeanOsize)
					
					matMolName = "OntimeMol_mean_S" + num2str(s) + waveSuffix + "_m"
					Wave matSMol = $matMolName
					if(sumOsize > 0)
						matSMol[m] = sumWeightedDur / sumOsize
					endif
					
					// wave
					SetDataFolder $ecCellPath
					String stateDurName = "StateDuration_S" + num2str(s) + waveSuffix
					Duplicate/O stateDurations, $stateDurName
				endif
				
				SetDataFolder $ecCellPath
			endfor
		endif
	endfor
	
	// ResultsParticleMolecule
	String resultsPath = ecSamplePath + "Results"
	if(!DataFolderExists(resultsPath))
		NewDataFolder $resultsPath
	endif
	
	for(s = 0; s <= maxState; s += 1)
		// Particle
		String srcMatName = "Ontime_mean_S" + num2str(s) + waveSuffix + "_m"
		SetDataFolder $matrixPath
		Wave/Z srcMatrix = $srcMatName
		
		if(WaveExists(srcMatrix))
			SetDataFolder $resultsPath
			String avgName = srcMatName + "_avg"
			String semName = srcMatName + "_sem"
			Make/O/N=1 $avgName = NaN
			Make/O/N=1 $semName = NaN
			Wave avgW = $avgName
			Wave semW = $semName
			
			Make/FREE/N=(numCells) tempData
			Variable k, validCount = 0
			for(k = 0; k < numCells; k += 1)
				Variable val = srcMatrix[k]
				if(numtype(val) == 0)
					tempData[validCount] = val
					validCount += 1
				endif
			endfor
			
			if(validCount > 0)
				Redimension/N=(validCount) tempData
				WaveStats/Q tempData
				avgW[0] = V_avg
				if(V_npnts > 1)
					semW[0] = V_sdev / sqrt(V_npnts)
				else
					semW[0] = 0
				endif
			endif
		endif
		
		// Molecule
		srcMatName = "OntimeMol_mean_S" + num2str(s) + waveSuffix + "_m"
		SetDataFolder $matrixPath
		Wave/Z srcMatrixMol = $srcMatName
		
		if(WaveExists(srcMatrixMol))
			SetDataFolder $resultsPath
			avgName = srcMatName + "_avg"
			semName = srcMatName + "_sem"
			Make/O/N=1 $avgName = NaN
			Make/O/N=1 $semName = NaN
			Wave avgWMol = $avgName
			Wave semWMol = $semName
			
			Make/FREE/N=(numCells) tempDataMol
			validCount = 0
			for(k = 0; k < numCells; k += 1)
				val = srcMatrixMol[k]
				if(numtype(val) == 0)
					tempDataMol[validCount] = val
					validCount += 1
				endif
			endfor
			
			if(validCount > 0)
				Redimension/N=(validCount) tempDataMol
				WaveStats/Q tempDataMol
				avgWMol[0] = V_avg
				if(V_npnts > 1)
					semWMol[0] = V_sdev / sqrt(V_npnts)
				else
					semWMol[0] = 0
				endif
			endif
		endif
	endfor
	
	SetDataFolder $savedDF
	Printf "  Ontime_mean%s calculated for %s\r", waveSuffix, sampleName
	return 0
End
			else
				semW[0] = 0
			endif
		endif
	endfor
	
	SetDataFolder $savedDF
	Printf "  Ontime_mean%s calculated for %s\r", waveSuffix, sampleName
	return 0
End

// -----------------------------------------------------------------------------
// ColCalculateReactionRate - Reaction rate = OnRate / ([A][B])
// -----------------------------------------------------------------------------
// [A][B] = ParticleDensity_C1 × ParticleDensity_C2
Function ColCalculateReactionRate(sampleName, waveSuffix)
	String sampleName
	String waveSuffix    // "_C1E" or "_C2E"
	
	String savedDF = GetDataFolder(1)
	String ecBase = GetECBasePath()
	String origBase = "root"
	
	NVAR/Z Dstate = root:Dstate
	NVAR/Z cHMM = root:cHMM
	
	Variable maxState = 0
	if(NVAR_Exists(cHMM) && cHMM == 1 && NVAR_Exists(Dstate))
		maxState = Dstate
	endif
	
	// 
	Wave/T/Z List_C1 = root:List_C1
	Wave/T/Z List_C2 = root:List_C2
	
	if(!WaveExists(List_C1) || !WaveExists(List_C2))
		SetDataFolder $savedDF
		return -1
	endif
	
	// sampleNameList_C1List_C2
	Variable listIdx = -1
	Variable i
	for(i = 0; i < numpnts(List_C1); i += 1)
		if(StringMatch(List_C1[i], sampleName))
			listIdx = i
			break
		endif
	endfor
	if(listIdx < 0)
		for(i = 0; i < numpnts(List_C2); i += 1)
			if(StringMatch(List_C2[i], sampleName))
				listIdx = i
				break
			endif
		endfor
	endif
	
	if(listIdx < 0)
		SetDataFolder $savedDF
		return -1
	endif
	
	// 
	String sampleName_C1 = List_C1[listIdx]
	String sampleName_C2 = List_C2[listIdx]
	
	Variable numCells = CountDataFoldersInPath(ecBase, sampleName)
	if(numCells == 0)
		SetDataFolder $savedDF
		return -1
	endif
	
	String ecSamplePath = ecBase + ":" + sampleName + ":"
	
	// Matrix
	String matrixPath = ecSamplePath + "Matrix"
	if(!DataFolderExists(matrixPath))
		NewDataFolder $matrixPath
	endif
	
	// Matrix wave
	SetDataFolder $matrixPath
	Variable s, m
	for(s = 0; s <= maxState; s += 1)
		String matrixName = "ReactionRate_S" + num2str(s) + waveSuffix + "_m"
		Make/O/N=(numCells) $matrixName = NaN
	endfor
	
	// 
	for(m = 0; m < numCells; m += 1)
		String folderName = sampleName + num2str(m + 1)
		String ecCellPath = ecSamplePath + folderName
		String folderName_C1 = sampleName_C1 + num2str(m + 1)
		String folderName_C2 = sampleName_C2 + num2str(m + 1)
		String origCellPath_C1 = origBase + ":" + sampleName_C1 + ":" + folderName_C1
		String origCellPath_C2 = origBase + ":" + sampleName_C2 + ":" + folderName_C2
		
		if(!DataFolderExists(ecCellPath))
			continue
		endif
		
		// Particle Density
		// ParaDensityAvg[2] = spot density [/µm²]
		String paraDensPath_C1 = origCellPath_C1 + ":ParaDensityAvg"
		String paraDensPath_C2 = origCellPath_C2 + ":ParaDensityAvg"
		Wave/Z ParaDensityAvg_C1 = $paraDensPath_C1
		Wave/Z ParaDensityAvg_C2 = $paraDensPath_C2
		
		Variable densA = NaN, densB = NaN
		if(WaveExists(ParaDensityAvg_C1) && numpnts(ParaDensityAvg_C1) > 2)
			densA = ParaDensityAvg_C1[2]
		endif
		if(WaveExists(ParaDensityAvg_C2) && numpnts(ParaDensityAvg_C2) > 2)
			densB = ParaDensityAvg_C2[2]
		endif
		
		Variable densProduct = densA * densB
		if(numtype(densProduct) != 0 || densProduct <= 0)
			continue
		endif
		
		SetDataFolder $ecCellPath
		
		// Reaction Rate
		for(s = 0; s <= maxState; s += 1)
			// ParaOnrate_Sn_waveSuffix  OnRate
			String paraName = "ParaOnrate_S" + num2str(s) + waveSuffix
			Wave/Z paraWave = $paraName
			
			if(!WaveExists(paraWave) || numpnts(paraWave) < 2)
				continue
			endif
			
			Variable onRate = paraWave[1]  // [1] = OnRate [/µm²/s]
			
			if(numtype(onRate) == 0)
				// Reaction Rate = OnRate / [A][B]
				Variable reactionRate = onRate / densProduct
				
				// Matrix
				SetDataFolder $matrixPath
				String matName = "ReactionRate_S" + num2str(s) + waveSuffix + "_m"
				Wave mat = $matName
				mat[m] = reactionRate
				SetDataFolder $ecCellPath
			endif
		endfor
	endfor
	
	// Results
	String resultsPath = ecSamplePath + "Results"
	if(!DataFolderExists(resultsPath))
		NewDataFolder $resultsPath
	endif
	
	for(s = 0; s <= maxState; s += 1)
		String srcMatName = "ReactionRate_S" + num2str(s) + waveSuffix + "_m"
		SetDataFolder $matrixPath
		Wave/Z srcMatrix = $srcMatName
		
		if(!WaveExists(srcMatrix))
			continue
		endif
		
		SetDataFolder $resultsPath
		
		String avgName = srcMatName + "_avg"
		String semName = srcMatName + "_sem"
		Make/O/N=1 $avgName = NaN
		Make/O/N=1 $semName = NaN
		Wave avgW = $avgName
		Wave semW = $semName
		
		Make/FREE/N=(numCells) tempData
		Variable k, validCount = 0
		for(k = 0; k < numCells; k += 1)
			Variable val = srcMatrix[k]
			if(numtype(val) == 0)
				tempData[validCount] = val
				validCount += 1
			endif
		endfor
		
		if(validCount > 0)
			Redimension/N=(validCount) tempData
			WaveStats/Q tempData
			avgW[0] = V_avg
			if(V_npnts > 1)
				semW[0] = V_sdev / sqrt(V_npnts)
			else
				semW[0] = 0
			endif
		endif
	endfor
	
	SetDataFolder $savedDF
	Printf "  ReactionRate%s calculated for %s\r", waveSuffix, sampleName
	return 0
End

// -----------------------------------------------------------------------------
// ColCalculateReactionRateMol - Moleculek_on
// -----------------------------------------------------------------------------
// k_on_mol = Molecular Event rate / (MolecularDensity_A × MolecularDensity_B)
// MolecularDensity = ColMolecularDensity_S0_waveSuffix
Function ColCalculateReactionRateMol(sampleName, waveSuffix)
	String sampleName
	String waveSuffix    // "_C1E" or "_C2E"
	
	String savedDF = GetDataFolder(1)
	String ecBase = GetECBasePath()
	
	NVAR/Z Dstate = root:Dstate
	NVAR/Z cHMM = root:cHMM
	
	Variable maxState = 0
	if(NVAR_Exists(cHMM) && cHMM == 1 && NVAR_Exists(Dstate))
		maxState = Dstate
	endif
	
	// 
	Wave/T/Z List_C1 = root:List_C1
	Wave/T/Z List_C2 = root:List_C2
	
	if(!WaveExists(List_C1) || !WaveExists(List_C2))
		SetDataFolder $savedDF
		return -1
	endif
	
	// sampleNameList_C1List_C2
	Variable listIdx = -1
	Variable i
	for(i = 0; i < numpnts(List_C1); i += 1)
		if(StringMatch(List_C1[i], sampleName))
			listIdx = i
			break
		endif
	endfor
	if(listIdx < 0)
		for(i = 0; i < numpnts(List_C2); i += 1)
			if(StringMatch(List_C2[i], sampleName))
				listIdx = i
				break
			endif
		endfor
	endif
	
	if(listIdx < 0)
		SetDataFolder $savedDF
		return -1
	endif
	
	// 
	String sampleName_C1 = List_C1[listIdx]
	String sampleName_C2 = List_C2[listIdx]
	
	Variable numCells = CountDataFoldersInPath(ecBase, sampleName)
	if(numCells == 0)
		SetDataFolder $savedDF
		return -1
	endif
	
	String ecSamplePath = ecBase + ":" + sampleName + ":"
	String ecSamplePath_C1 = ecBase + ":" + sampleName_C1 + ":"
	String ecSamplePath_C2 = ecBase + ":" + sampleName_C2 + ":"
	
	// Matrix
	String matrixPath = ecSamplePath + "Matrix"
	if(!DataFolderExists(matrixPath))
		NewDataFolder $matrixPath
	endif
	
	// Matrix wave
	SetDataFolder $matrixPath
	Variable s, m
	for(s = 0; s <= maxState; s += 1)
		String matrixName = "ReactionRateMol_S" + num2str(s) + waveSuffix + "_m"
		Make/O/N=(numCells) $matrixName = NaN
	endfor
	
	// 
	for(m = 0; m < numCells; m += 1)
		String folderName = sampleName + num2str(m + 1)
		String ecCellPath = ecSamplePath + folderName
		String folderName_C1 = sampleName_C1 + num2str(m + 1)
		String folderName_C2 = sampleName_C2 + num2str(m + 1)
		String ecCellPath_C1 = ecSamplePath_C1 + folderName_C1
		String ecCellPath_C2 = ecSamplePath_C2 + folderName_C2
		
		if(!DataFolderExists(ecCellPath))
			continue
		endif
		
		// Reaction Rate (Molecule)
		for(s = 0; s <= maxState; s += 1)
			// Molecular On-event rate
			SetDataFolder $ecCellPath
			String paraName = "ParaOnrateMol_S" + num2str(s) + waveSuffix
			Wave/Z paraWave = $paraName
			
			Variable molOnRate = NaN
			if(WaveExists(paraWave) && numpnts(paraWave) > 1)
				molOnRate = paraWave[1]  // [molecules/µm²/s]
			endif
			
			// Molecular Density
			// Ch1Molecular Density
			SetDataFolder $ecCellPath_C1
			String molDensName_C1 = "ColMolecularDensity_C1E"
			Wave/Z molDensWave_C1 = $molDensName_C1
			Variable molDensA = NaN
			if(WaveExists(molDensWave_C1) && numpnts(molDensWave_C1) > s)
				molDensA = molDensWave_C1[s]
			endif
			
			// Ch2Molecular Density
			SetDataFolder $ecCellPath_C2
			String molDensName_C2 = "ColMolecularDensity_C2E"
			Wave/Z molDensWave_C2 = $molDensName_C2
			Variable molDensB = NaN
			if(WaveExists(molDensWave_C2) && numpnts(molDensWave_C2) > s)
				molDensB = molDensWave_C2[s]
			endif
			
			// k_on_mol = Molecular On-event rate / (MolDens_A × MolDens_B)
			Variable molDensProduct = molDensA * molDensB
			Variable konMol = NaN
			if(numtype(molOnRate) == 0 && numtype(molDensProduct) == 0 && molDensProduct > 0)
				konMol = molOnRate / molDensProduct
			endif
			
			// Matrix
			SetDataFolder $matrixPath
			String matName = "ReactionRateMol_S" + num2str(s) + waveSuffix + "_m"
			Wave mat = $matName
			mat[m] = konMol
		endfor
	endfor
	
	// Results
	String resultsPath = ecSamplePath + "Results"
	if(!DataFolderExists(resultsPath))
		NewDataFolder $resultsPath
	endif
	
	for(s = 0; s <= maxState; s += 1)
		String srcMatName = "ReactionRateMol_S" + num2str(s) + waveSuffix + "_m"
		SetDataFolder $matrixPath
		Wave/Z srcMatrix = $srcMatName
		
		if(!WaveExists(srcMatrix))
			continue
		endif
		
		SetDataFolder $resultsPath
		
		String avgName = srcMatName + "_avg"
		String semName = srcMatName + "_sem"
		Make/O/N=1 $avgName = NaN
		Make/O/N=1 $semName = NaN
		Wave avgW = $avgName
		Wave semW = $semName
		
		Make/FREE/N=(numCells) tempData
		Variable k, validCount = 0
		for(k = 0; k < numCells; k += 1)
			Variable val = srcMatrix[k]
			if(numtype(val) == 0)
				tempData[validCount] = val
				validCount += 1
			endif
		endfor
		
		if(validCount > 0)
			Redimension/N=(validCount) tempData
			WaveStats/Q tempData
			avgW[0] = V_avg
			if(V_npnts > 1)
				semW[0] = V_sdev / sqrt(V_npnts)
			else
				semW[0] = 0
			endif
		endif
	endfor
	
	SetDataFolder $savedDF
	Printf "  ReactionRateMol%s calculated for %s\r", waveSuffix, sampleName
	return 0
End

// -----------------------------------------------------------------------------
// ColOntimeStatsFromList - On-time
// -----------------------------------------------------------------------------
Function ColOntimeStatsFromList()
	String savedDF = GetDataFolder(1)
	
	Wave/T/Z List_C1 = root:List_C1
	Wave/T/Z List_C2 = root:List_C2
	
	if(!WaveExists(List_C1) || !WaveExists(List_C2))
		return -1
	endif
	
	Variable numPairs = min(numpnts(List_C1), numpnts(List_C2))
	Variable i
	
	Print "=== Calculating On-time Simple and k_on ==="
	
	for(i = 0; i < numPairs; i += 1)
		String sampleName1 = List_C1[i]
		String sampleName2 = List_C2[i]
		
		// On-timeParticleMolecule
		ColCalculateOntimeSimple(sampleName1, "_C1E")
		ColCalculateOntimeSimple(sampleName2, "_C2E")
		
		// Reaction Rate (k_on) - Particle
		ColCalculateReactionRate(sampleName1, "_C1E")
		ColCalculateReactionRate(sampleName2, "_C2E")
		
		// Molecular On-event rate
		ColCalculateOnrateMol(sampleName1, "_C1E")
		ColCalculateOnrateMol(sampleName2, "_C2E")
		
		// k_on - Molecule
		ColCalculateReactionRateMol(sampleName1, "_C1E")
		ColCalculateReactionRateMol(sampleName2, "_C2E")
	endfor
	
	SetDataFolder $savedDF
	return 0
End

// -----------------------------------------------------------------------------
// ColCalculateOnrateMol - On-event rate
// -----------------------------------------------------------------------------
// Molecular On-event rate = Σ(Osize_start) / Area / TotalTime [molecules/µm²/s]
// Osize
Function ColCalculateOnrateMol(sampleName, waveSuffix)
	String sampleName
	String waveSuffix    // "_C1E" or "_C2E"
	
	String savedDF = GetDataFolder(1)
	String ecBase = GetECBasePath()
	String origBase = "root"
	
	NVAR/Z Dstate = root:Dstate
	NVAR/Z cHMM = root:cHMM
	NVAR/Z FrameNum = root:FrameNum
	NVAR/Z framerate = root:framerate
	NVAR MeanIntGauss = root:MeanIntGauss

	Variable maxState = 0
	if(NVAR_Exists(cHMM) && cHMM == 1 && NVAR_Exists(Dstate))
		maxState = Dstate
	endif

	Variable totalTime = 100  //
	if(NVAR_Exists(FrameNum) && NVAR_Exists(framerate))
		totalTime = FrameNum * framerate
	endif

	Variable meanInt = MeanIntGauss
	if(meanInt <= 0)
		SetDataFolder $savedDF
		return -1
	endif
	
	Variable numCells = CountDataFoldersInPath(ecBase, sampleName)
	if(numCells == 0)
		SetDataFolder $savedDF
		return -1
	endif
	
	String ecSamplePath = ecBase + ":" + sampleName + ":"
	String origSamplePath = origBase + ":" + sampleName + ":"
	
	// Matrix
	String matrixPath = ecSamplePath + "Matrix"
	if(!DataFolderExists(matrixPath))
		NewDataFolder $matrixPath
	endif
	
	// Matrix wave: ParaOnrateMol_Sn_waveSuffix_m
	SetDataFolder $matrixPath
	Variable s
	for(s = 0; s <= maxState; s += 1)
		String matrixName = "ParaOnrateMol_S" + num2str(s) + waveSuffix + "_m"
		Make/O/N=(3, numCells) $matrixName = NaN  // [0]=tau, [1]=MolRate, [2]=totalMol
	endfor
	
	// 
	Variable m
	for(m = 0; m < numCells; m += 1)
		String folderName = sampleName + num2str(m + 1)
		String ecCellPath = ecSamplePath + folderName
		String origCellPath = origSamplePath + folderName
		
		if(!DataFolderExists(ecCellPath) || !DataFolderExists(origCellPath))
			continue
		endif
		
		// Area
		String paraDensPath = origCellPath + ":ParaDensityAvg"
		Wave/Z ParaDensityAvg = $paraDensPath
		
		Variable cellArea = NaN
		if(WaveExists(ParaDensityAvg) && numpnts(ParaDensityAvg) > 1)
			cellArea = ParaDensityAvg[1]
		endif
		
		if(numtype(cellArea) != 0 || cellArea <= 0)
			continue
		endif
		
		SetDataFolder $ecCellPath
		
		// 
		for(s = 0; s <= maxState; s += 1)
			// ROI_Sn, Rframe_Sn, Int_Sn 
			String roiWaveName = "ROI_S" + num2str(s) + waveSuffix
			String rframeWaveName = "Rframe_S" + num2str(s) + waveSuffix
			String intWaveName = "Int_S" + num2str(s) + waveSuffix
			
			Wave/Z ROI_wave = $roiWaveName
			Wave/Z Rframe_wave = $rframeWaveName
			Wave/Z Int_wave = $intWaveName
			
			if(!WaveExists(ROI_wave) || !WaveExists(Rframe_wave) || !WaveExists(Int_wave))
				continue
			endif
			
			Variable numPts = numpnts(ROI_wave)
			if(numPts == 0)
				continue
			endif
			
			// ROINaN
			Make/FREE/N=(numPts) tempROI
			tempROI = ROI_wave
			WaveTransform zapNaNs tempROI  // NaN
			Variable validPts = numpnts(tempROI)
			if(validPts == 0)
				continue
			endif
			
			// FindDuplicates2
			Make/FREE/N=0 uniqueROIs
			if(validPts == 1)
				// 1ROI
				Redimension/N=1 uniqueROIs
				uniqueROIs[0] = tempROI[0]
			else
				FindDuplicates/FREE/RN=uniqueROIs tempROI
			endif
			
			Variable numTrajectories = numpnts(uniqueROIs)
			if(numTrajectories == 0)
				continue
			endif
			
			// Osize
			Variable totalMolecules = 0
			Variable t, i
			for(t = 0; t < numTrajectories; t += 1)
				Variable roiNum = uniqueROIs[t]
				
				// 
				Variable minFrame = Inf
				Variable startIdx = -1
				for(i = 0; i < numPts; i += 1)
					// NaN
					if(numtype(ROI_wave[i]) == 0 && ROI_wave[i] == roiNum)
						if(Rframe_wave[i] < minFrame)
							minFrame = Rframe_wave[i]
							startIdx = i
						endif
					endif
				endfor
				
				// Osize
				if(startIdx >= 0)
					Variable intVal = Int_wave[startIdx]
					if(numtype(intVal) == 0 && intVal > 0)
						totalMolecules += intVal / meanInt
					else
						totalMolecules += 1  // 
					endif
				endif
			endfor
			
			// Molecular On-event rate =  / Area / TotalTime [molecules/µm²/s]
			Variable molRate = totalMolecules / cellArea / totalTime
			
			// ParaOnrateMol_Sn_waveSuffix 
			String paraName = "ParaOnrateMol_S" + num2str(s) + waveSuffix
			Make/O/N=3 $paraName
			Wave paraWave = $paraName
			paraWave[0] = NaN  // tau ()
			paraWave[1] = molRate  // Molecular On-event rate [molecules/µm²/s]
			paraWave[2] = totalMolecules  // 
			
			// Matrix
			SetDataFolder $matrixPath
			String matName = "ParaOnrateMol_S" + num2str(s) + waveSuffix + "_m"
			Wave mat = $matName
			mat[0][m] = NaN
			mat[1][m] = molRate
			mat[2][m] = totalMolecules
			SetDataFolder $ecCellPath
		endfor
	endfor
	
	// Results
	String resultsPath = ecSamplePath + "Results"
	if(!DataFolderExists(resultsPath))
		NewDataFolder $resultsPath
	endif
	
	for(s = 0; s <= maxState; s += 1)
		String srcMatName = "ParaOnrateMol_S" + num2str(s) + waveSuffix + "_m"
		SetDataFolder $matrixPath
		Wave/Z srcMatrix = $srcMatName
		
		if(!WaveExists(srcMatrix))
			continue
		endif
		
		SetDataFolder $resultsPath
		
		String avgName = srcMatName + "_avg"
		String semName = srcMatName + "_sem"
		Make/O/N=3 $avgName = NaN
		Make/O/N=3 $semName = NaN
		Wave avgW = $avgName
		Wave semW = $semName
		
		// row 1 (MolRate) 
		Make/FREE/N=(numCells) tempData
		Variable k, validCount = 0
		for(k = 0; k < numCells; k += 1)
			Variable val = srcMatrix[1][k]
			if(numtype(val) == 0)
				tempData[validCount] = val
				validCount += 1
			endif
		endfor
		
		if(validCount > 0)
			Redimension/N=(validCount) tempData
			WaveStats/Q tempData
			avgW[1] = V_avg
			if(V_npnts > 1)
				semW[1] = V_sdev / sqrt(V_npnts)
			else
				semW[1] = 0
			endif
		endif
	endfor
	
	SetDataFolder $savedDF
	Printf "  ParaOnrateMol%s calculated for %s\r", waveSuffix, sampleName
	return 0
End

// -----------------------------------------------------------------------------
// On-time Analysis (EC folder)
// Same as Duration_Gcount
// Uses Colocalization-specific parameters (ColTau1, ColTauScale, ColA1, ColAScale)
// -----------------------------------------------------------------------------

Function ColOntimeFromList()
	String savedDF = GetDataFolder(1)
	
	// 
	String ecBase = GetECBasePath()
	
	Wave/T/Z List_C1 = root:List_C1
	Wave/T/Z List_C2 = root:List_C2
	
	if(!WaveExists(List_C1) || !WaveExists(List_C2))
		DoAlert 0, "Please create List_C1 and List_C2 first"
		return -1
	endif
	
	NVAR ColMinFrame = root:ColMinFrame
	
	// Colocalization
	NVAR ColTau1 = root:ColTau1
	NVAR ColTauScale = root:ColTauScale
	NVAR ColA1 = root:ColA1
	NVAR ColAScale = root:ColAScale

	// Colocalization fit parameters (passed as overrides — globals NOT modified)
	Variable colTau1Val = ColTau1
	Variable colTauScaleVal = ColTauScale
	Variable colA1Val = ColA1
	Variable colAScaleVal = ColAScale

	Variable numPairs = min(numpnts(List_C1), numpnts(List_C2))
	Variable i

	Print "=== Colocalization On-time (Off-rate) Analysis ==="
	Printf "Using %s folder, ColMinFrame: %d\r", ecBase, ColMinFrame
	Printf "Fit params: Tau1=%.3f, Scale_tau=%.1f, A1=%.1f, Scale_A=%.2f\r", colTau1Val, colTauScaleVal, colA1Val, colAScaleVal
	
	for(i = 0; i < numPairs; i += 1)
		String sampleName1 = List_C1[i]
		String sampleName2 = List_C2[i]
		
		Printf "Processing: %s vs %s\r", sampleName1, sampleName2
		
		// Ch1: waveSuffix
		Duration_Gcount(sampleName1, basePath=ecBase, useMinFrame=ColMinFrame, waveSuffix="_C1E", overrideTau1=colTau1Val, overrideTauScale=colTauScaleVal, overrideA1=colA1Val, overrideAScale=colAScaleVal)
		
		// Ch2: 
		Duration_Gcount(sampleName2, basePath=ecBase, useMinFrame=ColMinFrame, waveSuffix="_C2E", overrideTau1=colTau1Val, overrideTauScale=colTauScaleVal, overrideA1=colA1Val, overrideAScale=colAScaleVal)
	endfor
	
	SetDataFolder $savedDF
	return 0
End
	// -----------------------------------------------------------------------------
// On-rate Analysis (EC folder)
// Uses OnrateAnalysisWithOption with Dstate support
// -----------------------------------------------------------------------------

Function ColOnrateFromList()
	String savedDF = GetDataFolder(1)
	
	// 
	String ecBase = GetECBasePath()
	
	Wave/T/Z List_C1 = root:List_C1
	Wave/T/Z List_C2 = root:List_C2
	
	if(!WaveExists(List_C1) || !WaveExists(List_C2))
		DoAlert 0, "Please create List_C1 and List_C2 first"
		return -1
	endif
	
	Variable numPairs = min(numpnts(List_C1), numpnts(List_C2))
	Variable i
	
	Print "=== Colocalization On-rate Analysis ==="
	Printf "Using %s folder with Dstate support\r", ecBase
	
	for(i = 0; i < numPairs; i += 1)
		String sampleName1 = List_C1[i]
		String sampleName2 = List_C2[i]
		
		Printf "Processing: %s vs %s\r", sampleName1, sampleName2
		
		// Ch1: waveSuffix
		OnrateAnalysisWithOption(sampleName1, basePath=ecBase, waveSuffix="_C1E")
		
		// Ch2: 
		OnrateAnalysisWithOption(sampleName2, basePath=ecBase, waveSuffix="_C2E")
	endfor
	
	// On-rateMatrix/Results
	Print "  Creating Matrix/Results for On-rate..."
	for(i = 0; i < numPairs; i += 1)
		sampleName1 = List_C1[i]
		sampleName2 = List_C2[i]
		
		// On-ratewave
		StatsResultsMatrix(ecBase, sampleName1, "")
		StatsResultsMatrix(ecBase, sampleName2, "")
	endfor
	
	SetDataFolder $savedDF
	return 0
End

// -----------------------------------------------------------------------------
// Statistics Analysis (EC folder)
// Creates Matrix and Results folders with averaged parameters
// -----------------------------------------------------------------------------

Function ColStatsFromList()
	String savedDF = GetDataFolder(1)
	
	// 
	String ecBase = GetECBasePath()
	
	Wave/T/Z List_C1 = root:List_C1
	Wave/T/Z List_C2 = root:List_C2
	
	if(!WaveExists(List_C1) || !WaveExists(List_C2))
		DoAlert 0, "Please create List_C1 and List_C2 first"
		return -1
	endif
	
	Variable numPairs = min(numpnts(List_C1), numpnts(List_C2))
	Variable i
	
	Print "=== Colocalization Statistics ==="
	Printf "Creating Matrix and Results in %s folder\r", ecBase
	
	for(i = 0; i < numPairs; i += 1)
		String sampleName1 = List_C1[i]
		String sampleName2 = List_C2[i]
		
		Printf "Processing: %s, %s\r", sampleName1, sampleName2
		
		// Ch1: WavewaveNameList = ""
		StatsResultsMatrix(ecBase, sampleName1, "")
		
		// Ch2: 
		StatsResultsMatrix(ecBase, sampleName2, "")
	endfor
	
	// OsizeCol: Int / MeanIntGauss
	Print "=== Calculating OsizeCol (Simple Method) ==="
	for(i = 0; i < numPairs; i += 1)
		String smplName1 = List_C1[i]
		String smplName2 = List_C2[i]
		
		ColCalculateOsizeCol(smplName1, "_C1E")
		ColCalculateOsizeCol(smplName2, "_C2E")
	endfor
	
	// DiffusionAbsolute HMMP
	Print "=== Calculating Absolute HMMP ==="
	ColDiffusionStatsFromList()
	
	// AffinityParticle Density, Kb by state
	Print "=== Calculating Particle Density and Kb by State ==="
	ColAffinityStatsFromList()
	
	// On-timeSimple Mean, Reaction Rate
	Print "=== Calculating On-time Simple and k_on ==="
	ColOntimeStatsFromList()
	
	SetDataFolder $savedDF
	return 0
End

// -----------------------------------------------------------------------------
// ColCalculateOsizeCol - Oligomer Size
// -----------------------------------------------------------------------------
// OsizeCol = Int / MeanIntGauss
// MeanIntGaussAutoAnalysisIntensity1
Function ColCalculateOsizeCol(sampleName, waveSuffix)
	String sampleName
	String waveSuffix    // "_C1E" or "_C2E"
	
	String savedDF = GetDataFolder(1)
	String ecBase = GetECBasePath()
	String origBase = "root"
	
	NVAR/Z MeanIntGauss = root:MeanIntGauss
	NVAR/Z gDstate = root:Dstate
	NVAR/Z cHMM = root:cHMM
	
	// MeanIntGauss
	if(!NVAR_Exists(MeanIntGauss) || MeanIntGauss <= 0)
		Printf "  WARNING: MeanIntGauss not set or invalid, skipping OsizeCol for %s\r", sampleName
		SetDataFolder $savedDF
		return -1
	endif
	
	Variable maxState = 0
	if(NVAR_Exists(cHMM) && cHMM == 1 && NVAR_Exists(gDstate))
		maxState = gDstate
	endif
	
	Variable numCells = CountDataFoldersInPath(ecBase, sampleName)
	if(numCells == 0)
		SetDataFolder $savedDF
		return -1
	endif
	
	String ecSamplePath = ecBase + ":" + sampleName + ":"
	
	// Matrix
	String matrixPath = ecSamplePath + "Matrix"
	if(!DataFolderExists(matrixPath))
		NewDataFolder $matrixPath
	endif
	
	// OsizeColwaveParticleMolecule
	SetDataFolder $matrixPath
	Variable s
	for(s = 0; s <= maxState; s += 1)
		// Particle
		String osizeMeanMatName = "OsizeCol_mean_S" + num2str(s) + waveSuffix + "_m"
		String osizeSDMatName = "OsizeCol_sd_S" + num2str(s) + waveSuffix + "_m"
		String osizeNMatName = "OsizeCol_n_S" + num2str(s) + waveSuffix + "_m"
		Make/O/N=(numCells) $osizeMeanMatName = NaN
		Make/O/N=(numCells) $osizeSDMatName = NaN
		Make/O/N=(numCells) $osizeNMatName = NaN
		// Molecule
		String osizeMolMatName = "OsizeColMol_mean_S" + num2str(s) + waveSuffix + "_m"
		Make/O/N=(numCells) $osizeMolMatName = NaN
	endfor
	
	Variable m
	
	// 
	for(m = 0; m < numCells; m += 1)
		String folderName = sampleName + num2str(m + 1)
		String ecCellPath = ecSamplePath + folderName
		
		if(!DataFolderExists(ecCellPath))
			continue
		endif
		
		SetDataFolder $ecCellPath
		
		// Int_Sn_waveSuffix
		for(s = 0; s <= maxState; s += 1)
			String intWaveName = "Int_S" + num2str(s) + waveSuffix
			Wave/Z IntWave = $intWaveName
			
			if(!WaveExists(IntWave))
				continue
			endif
			
			// NaNOsizeCol
			Variable numPts = numpnts(IntWave)
			Make/FREE/N=(numPts) OsizeTemp = NaN
			
			Variable i, validCount = 0
			for(i = 0; i < numPts; i += 1)
				Variable intVal = IntWave[i]
				if(numtype(intVal) == 0 && intVal > 0)
					OsizeTemp[validCount] = intVal / MeanIntGauss
					validCount += 1
				endif
			endfor
			
			if(validCount > 0)
				Redimension/N=(validCount) OsizeTemp
				
				// OsizeCol_Sn wave
				String osizeColName = "OsizeCol_S" + num2str(s) + waveSuffix
				Duplicate/O OsizeTemp, $osizeColName
				
				// Particle: 
				WaveStats/Q OsizeTemp
				
				SetDataFolder $matrixPath
				String matMeanN = "OsizeCol_mean_S" + num2str(s) + waveSuffix + "_m"
				String matSDN = "OsizeCol_sd_S" + num2str(s) + waveSuffix + "_m"
				String matNN = "OsizeCol_n_S" + num2str(s) + waveSuffix + "_m"
				Wave matMean = $matMeanN
				Wave matSD = $matSDN
				Wave matN = $matNN
				matMean[m] = V_avg
				matSD[m] = V_sdev
				matN[m] = V_npnts
				
				// Molecule: Weighted Mean = Σ(Osize²) / Σ(Osize)
				// Oligomer Size
				Variable sumOsize = V_sum
				Make/FREE/N=(validCount) OsizeSq
				OsizeSq = OsizeTemp * OsizeTemp
				Variable sumOsizeSq = sum(OsizeSq)
				
				String matMolN = "OsizeColMol_mean_S" + num2str(s) + waveSuffix + "_m"
				Wave matMol = $matMolN
				if(sumOsize > 0)
					matMol[m] = sumOsizeSq / sumOsize
				endif
				
				SetDataFolder $ecCellPath
			endif
		endfor
	endfor
	
	// ResultsParticleMolecule
	String resultsPath = ecSamplePath + "Results"
	if(!DataFolderExists(resultsPath))
		NewDataFolder $resultsPath
	endif
	
	for(s = 0; s <= maxState; s += 1)
		// Particle
		String srcMatName = "OsizeCol_mean_S" + num2str(s) + waveSuffix + "_m"
		SetDataFolder $matrixPath
		Wave/Z srcMatrix = $srcMatName
		
		if(WaveExists(srcMatrix))
			SetDataFolder $resultsPath
			String avgName = srcMatName + "_avg"
			String semName = srcMatName + "_sem"
			Make/O/N=1 $avgName = NaN
			Make/O/N=1 $semName = NaN
			Wave avgW = $avgName
			Wave semW = $semName
			
			Make/FREE/N=(numCells) tempData
			Variable k, vc = 0
			for(k = 0; k < numCells; k += 1)
				Variable val = srcMatrix[k]
				if(numtype(val) == 0)
					tempData[vc] = val
					vc += 1
				endif
			endfor
			
			if(vc > 0)
				Redimension/N=(vc) tempData
				WaveStats/Q tempData
				avgW[0] = V_avg
				if(V_npnts > 1)
					semW[0] = V_sdev / sqrt(V_npnts)
				else
					semW[0] = 0
				endif
			endif
		endif
		
		// Molecule
		srcMatName = "OsizeColMol_mean_S" + num2str(s) + waveSuffix + "_m"
		SetDataFolder $matrixPath
		Wave/Z srcMatrixMol = $srcMatName
		
		if(WaveExists(srcMatrixMol))
			SetDataFolder $resultsPath
			avgName = srcMatName + "_avg"
			semName = srcMatName + "_sem"
			Make/O/N=1 $avgName = NaN
			Make/O/N=1 $semName = NaN
			Wave avgWMol = $avgName
			Wave semWMol = $semName
			
			Make/FREE/N=(numCells) tempDataMol
			vc = 0
			for(k = 0; k < numCells; k += 1)
				val = srcMatrixMol[k]
				if(numtype(val) == 0)
					tempDataMol[vc] = val
					vc += 1
				endif
			endfor
			
			if(vc > 0)
				Redimension/N=(vc) tempDataMol
				WaveStats/Q tempDataMol
				avgWMol[0] = V_avg
				if(V_npnts > 1)
					semWMol[0] = V_sdev / sqrt(V_npnts)
				else
					semWMol[0] = 0
				endif
			endif
		endif
	endfor
	
	SetDataFolder $savedDF
	Printf "  OsizeCol%s calculated for %s (MeanIntGauss=%.1f, %d states)\r", waveSuffix, sampleName, MeanIntGauss, maxState+1
	return 0
End

// -----------------------------------------------------------------------------
// MakeResultMatrixEC - ECMatrix
// -----------------------------------------------------------------------------
Function MakeResultMatrixEC(SampleName)
	String SampleName
	String FolderName, WName, MName
	Variable m = 0
	
	// 
	String ecBasePath = GetECBasePath()
	String ecBase = ecBasePath + ":" + SampleName
	if(!DataFolderExists(ecBase))
		Printf "Warning: %s does not exist\r", ecBase
		return -1
	endif
	
	// Count cell folders
	Variable n = GetCellCount(SampleName)
	if(n <= 0)
		Printf "Warning: No cell folders found for %s\r", SampleName
		return -1
	endif
	
	Printf "MakeResultMatrixEC: %s, folders = %d\r", SampleName, n
	
	// Get first folder to count waves
	FolderName = SampleName + "1"
	String firstFolder = ecBase + ":" + FolderName
	if(!DataFolderExists(firstFolder))
		Printf "Warning: %s does not exist\r", firstFolder
		return -1
	endif
	
	SetDataFolder $firstFolder
	Variable NumWave = CountObjects("", 1)
	
	// Create Matrix folder
	NewDataFolder/O $(ecBase + ":Matrix")
	
	Printf "  Processing %d waves\r", NumWave
	
	Variable i = 0
	Variable RowSize, ColumnSize, MatrixRowSize, MatrixColSize
	Variable copyRows, copyCols, r, c
	
	Do
		m = 0
		FolderName = SampleName + "1"
		String cellFolder = ecBase + ":" + FolderName
		
		if(!DataFolderExists(cellFolder))
			i += 1
			continue
		endif
		
		SetDataFolder $cellFolder
		WName = GetIndexedObjName("", 1, i)
		
		if(strlen(WName) == 0)
			i += 1
			continue
		endif
		
		// Exclude patterns (same as original)
		Variable exc0 = StringMatch(WName, "*Trace*")
		Variable exc1 = StringMatch(WName, "*GFit*")
		Variable exc2 = StringMatch(WName, "*sig*")
		Variable exc3 = StringMatch(WName, "*name*")
		Variable exc4 = StringMatch(WName, "*_um*")  // "_um"CumOnEvent
		Variable exc5 = StringMatch(WName, "*ROI*")
		Variable exc6 = StringMatch(WName, "*Image*")
		Variable exc7 = StringMatch(WName, "*_x")
		Variable exc8 = StringMatch(WName, "*Hist*")
		Variable exc9 = StringMatch(WName, "*Distance*")
		Variable exc10 = StringMatch(WName, "*Colocalize*")
		
		if(exc0 == 0 && exc1 == 0 && exc2 == 0 && exc3 == 0 && exc4 == 0 && exc5 == 0 && exc6 == 0 && exc7 == 0 && exc8 == 0 && exc9 == 0 && exc10 == 0)
			
			MatrixRowSize = 0
			MatrixColSize = 0
			
			Do
				FolderName = SampleName + num2str(m + 1)
				cellFolder = ecBase + ":" + FolderName
				
				if(!DataFolderExists(cellFolder))
					m += 1
					if(m >= n)
						break
					endif
					continue
				endif
				
				SetDataFolder $cellFolder
				
				Wave/Z sourceWave = $WName
				if(!WaveExists(sourceWave))
					m += 1
					continue
				endif
				
				if(WaveType(sourceWave) != 0)
					RowSize = DimSize(sourceWave, 0)
					ColumnSize = DimSize(sourceWave, 1)
					
					SetDataFolder $ecBase
					MName = WName + "_m"
					
					if(m == 0 && ColumnSize == 0)
						Make/O/N=(RowSize, n) Matrix = NaN
						MatrixRowSize = RowSize
						MatrixColSize = 0
					elseif(m == 0 && n >= 3 && ColumnSize > 1)
						Make/O/N=(RowSize, ColumnSize, n) Matrix = NaN
						MatrixRowSize = RowSize
						MatrixColSize = ColumnSize
					elseif(m == 0 && n < 3 && ColumnSize > 1)
						Make/O/N=(RowSize, ColumnSize, 3) Matrix = NaN
						MatrixRowSize = RowSize
						MatrixColSize = ColumnSize
					endif
					
					Wave/Z Matrix
					if(WaveExists(Matrix) && MatrixRowSize > 0)
						copyRows = min(RowSize, MatrixRowSize)
						
						if(ColumnSize == 0 && MatrixColSize == 0)
							for(r = 0; r < copyRows; r += 1)
								Matrix[r][m] = sourceWave[r]
							endfor
						elseif(ColumnSize > 0 && MatrixColSize > 0)
							copyCols = min(ColumnSize, MatrixColSize)
							for(r = 0; r < copyRows; r += 1)
								for(c = 0; c < copyCols; c += 1)
									Matrix[r][c][m] = sourceWave[r][c]
								endfor
							endfor
						endif
					endif
				endif
				
				m += 1
			While(m < n)
			
			SetDataFolder $ecBase
			Wave/Z Matrix
			if(WaveExists(Matrix) && WaveType(Matrix) != 0)
				Duplicate/O Matrix, $(ecBase + ":Matrix:" + MName)
			endif
			KillWaves/Z Matrix
		endif
		
		KillWaves/Z Matrix
		m = 0
		i += 1
	While(i < NumWave)
	
	SetDataFolder root:
	Printf "Matrix created: EC:%s:Matrix (folders=%d)\r", SampleName, n
	return 0
End

// -----------------------------------------------------------------------------
// StatResultMatrixEC - EC
// -----------------------------------------------------------------------------
Function StatResultMatrixEC(SampleName)
	String SampleName
	String MName, WName_avg, WName_sd, WName_sem, WName_n
	
	// 
	String ecBasePath = GetECBasePath()
	String ecBase = ecBasePath + ":" + SampleName
	String matrixFolder = ecBase + ":Matrix"
	
	if(!DataFolderExists(matrixFolder))
		Printf "Warning: %s does not exist\r", matrixFolder
		return -1
	endif
	
	NewDataFolder/O $(ecBase + ":Results")
	SetDataFolder $matrixFolder
	Variable NumWave = CountObjects("", 1)
	
	if(NumWave == 0)
		Printf "Warning: No waves in %s\r", matrixFolder
		SetDataFolder root:
		return -1
	endif
	
	Variable w = 0
	
	Do
		MName = GetIndexedObjName("", 1, w)
		
		Wave/Z MWave = $MName
		if(!WaveExists(MWave))
			w += 1
			continue
		endif
		
		if(WaveType(MWave) == 0)
			w += 1
			continue
		endif
		
		WName_avg = MName + "_avg"
		WName_sd = MName + "_sd"
		WName_sem = MName + "_sem"
		WName_n = MName + "_n"
		
		Variable RowSize = DimSize(MWave, 0)
		Variable ColumnSize = DimSize(MWave, 1)
		Variable LayerSize = DimSize(MWave, 2)
		Variable i
		
		if(LayerSize == 0)
			Make/O/D/N=(RowSize) Average = NaN
			Make/O/D/N=(RowSize) SD = NaN
			Make/O/D/N=(RowSize) SEM = NaN
			Make/O/D/N=(RowSize) Npnts = NaN
			
			for(i = 0; i < RowSize; i += 1)
				ImageStats/G={i, i, 0, ColumnSize-1} MWave
				Average[i] = V_avg
				SD[i] = V_sdev
				if(V_npnts > 0)
					SEM[i] = V_sdev / sqrt(V_npnts)
				endif
				Npnts[i] = V_npnts
			endfor
		elseif(LayerSize > 1)
			Make/O/D/N=(RowSize, ColumnSize) Average = NaN
			Make/O/D/N=(RowSize, ColumnSize) SD = NaN
			Make/O/D/N=(RowSize, ColumnSize) SEM = NaN
			Make/O/D/N=(RowSize, ColumnSize) Npnts = NaN
			
			if(WaveDims(MWave) >= 3)
				ImageTransform/METH=1 averageImage MWave
			else
				Printf "  WARNING: ImageTransform skipped in StatResultMatrixEC — %s is %dD (LayerSize=%d)\r", MName, WaveDims(MWave), LayerSize
			endif
			Wave/Z M_AveImage, M_StdvImage
			
			if(WaveExists(M_AveImage) && WaveExists(M_StdvImage))
				Average[][] = M_AveImage[p][q]
				SD[][] = M_StdvImage[p][q]
				SEM[][] = M_StdvImage[p][q] / sqrt(LayerSize)
				Npnts[][] = LayerSize
			endif
			
			KillWaves/Z M_AveImage, M_StdvImage
		endif
		
		// Save results
		Duplicate/O Average, $(ecBase + ":Results:" + WName_avg)
		Duplicate/O SD, $(ecBase + ":Results:" + WName_sd)
		Duplicate/O SEM, $(ecBase + ":Results:" + WName_sem)
		Duplicate/O Npnts, $(ecBase + ":Results:" + WName_n)
		
		KillWaves/Z Average, SD, SEM, Npnts
		w += 1
	While(w < NumWave)
	
	SetDataFolder root:
	Printf "Statistics created: EC:%s:Results\r", SampleName
	return 0
End

// =============================================================================
// Average Histogram Functions
// =============================================================================

// Average Distance Histogram
// Collects Dist_Sn_ColPhist_m_avg from each sample and displays in EC:Comparison
Function ColAvgDistanceFromList()
	String savedDF = GetDataFolder(1)
	
	// 
	String ecBasePath = GetECBasePath()
	String colBasePath = GetColBasePath()
	
	Wave/T/Z List_C1 = root:List_C1
	Wave/T/Z List_C2 = root:List_C2
	
	if(!WaveExists(List_C1) || !WaveExists(List_C2))
		DoAlert 0, "Please create List_C1 and List_C2 first"
		return -1
	endif
	
	NVAR/Z Dstate = root:Dstate
	NVAR/Z cHMM = root:cHMM
	
	Variable maxState = 0
	if(NVAR_Exists(cHMM) && cHMM == 1 && NVAR_Exists(Dstate))
		maxState = Dstate
	endif
	
	Variable numPairs = min(numpnts(List_C1), numpnts(List_C2))
	Variable i, s, r, g, b
	
	Print "=== Average Distance Histogram ==="
	
	// Create Comparison folders
	String ecCompPath = ecBasePath + ":Comparison"
	String colCompPath = colBasePath + ":Comparison"
	
	if(!DataFolderExists(ecCompPath))
		NewDataFolder $ecCompPath
	endif
	if(DataFolderExists(colBasePath))
		if(!DataFolderExists(colCompPath))
			NewDataFolder $colCompPath
		endif
	endif
	
	Variable ch
	String sampleName
	
	// ===== Process Ch1 and Ch2 separately =====
	for(ch = 0; ch < 2; ch += 1)
		String ecSuffix, colSuffix
		if(ch == 0)
			ecSuffix = "_C1E"
			colSuffix = "_C1"
		else
			ecSuffix = "_C2E"
			colSuffix = "_C2"
		endif
		
		// Collect EC data to Comparison folder
		for(i = 0; i < numPairs; i += 1)
			if(ch == 0)
				sampleName = List_C1[i]
			else
				sampleName = List_C2[i]
			endif
			String ecResultsPath = ecBasePath + ":" + sampleName + ":Results"
			
			if(!DataFolderExists(ecResultsPath))
				continue
			endif
			
			SetDataFolder $ecResultsPath
			
			for(s = 0; s <= maxState; s += 1)
				String srcAvgName = "Dist_S" + num2str(s) + "_ColPhist" + ecSuffix + "_m_avg"
				String srcSemName = "Dist_S" + num2str(s) + "_ColPhist" + ecSuffix + "_m_sem"
				String srcXName = "Dist_S" + num2str(s) + "_X" + ecSuffix + "_m_avg"
				
				Wave/Z srcAvg = $srcAvgName
				Wave/Z srcSem = $srcSemName
				Wave/Z srcX = $srcXName
				
				if(WaveExists(srcAvg))
					String dstAvgName = sampleName + "_Dist_S" + num2str(s) + "_ColPhist_m_avg" + ecSuffix
					String dstSemName = sampleName + "_Dist_S" + num2str(s) + "_ColPhist_m_sem" + ecSuffix
					String dstXName = sampleName + "_Dist_S" + num2str(s) + "_X_m_avg" + ecSuffix
					
					Duplicate/O srcAvg, $(ecCompPath + ":" + dstAvgName)
					if(WaveExists(srcSem))
						Duplicate/O srcSem, $(ecCompPath + ":" + dstSemName)
					endif
					if(WaveExists(srcX))
						Duplicate/O srcX, $(ecCompPath + ":" + dstXName)
					endif
				endif
			endfor
		endfor
		
		// Collect Col data to Comparison folder
		if(DataFolderExists(colCompPath))
			for(i = 0; i < numPairs; i += 1)
				if(ch == 0)
					sampleName = List_C1[i]
				else
					sampleName = List_C2[i]
				endif
				String colResultsPath = colBasePath + ":" + sampleName + ":Results"
				
				if(!DataFolderExists(colResultsPath))
					continue
				endif
				
				SetDataFolder $colResultsPath
				
				for(s = 0; s <= maxState; s += 1)
					srcAvgName = "Dist_S" + num2str(s) + "_ColPhist" + colSuffix + "_m_avg"
					srcSemName = "Dist_S" + num2str(s) + "_ColPhist" + colSuffix + "_m_sem"
					srcXName = "Dist_S" + num2str(s) + "_X" + colSuffix + "_m_avg"
					
					Wave/Z srcAvg = $srcAvgName
					Wave/Z srcSem = $srcSemName
					Wave/Z srcX = $srcXName
					
					if(WaveExists(srcAvg))
						dstAvgName = sampleName + "_Dist_S" + num2str(s) + "_ColPhist_m_avg" + colSuffix
						dstSemName = sampleName + "_Dist_S" + num2str(s) + "_ColPhist_m_sem" + colSuffix
						dstXName = sampleName + "_Dist_S" + num2str(s) + "_X_m_avg" + colSuffix
						
						Duplicate/O srcAvg, $(colCompPath + ":" + dstAvgName)
						if(WaveExists(srcSem))
							Duplicate/O srcSem, $(colCompPath + ":" + dstSemName)
						endif
						if(WaveExists(srcX))
							Duplicate/O srcX, $(colCompPath + ":" + dstXName)
						endif
					endif
				endfor
			endfor
		endif
		
		// ===== Create individual sample graphs (EC/Col overlay like Batch) =====
		for(i = 0; i < numPairs; i += 1)
			if(ch == 0)
				sampleName = List_C1[i]
			else
				sampleName = List_C2[i]
			endif
			
			String graphName = "AvgDist_" + sampleName + ecSuffix
			DoWindow/K $graphName
			
			SetDataFolder $ecCompPath
			
			// Check S0 data exists
			String s0AvgName = sampleName + "_Dist_S0_ColPhist_m_avg" + ecSuffix
			String s0XName = sampleName + "_Dist_S0_X_m_avg" + ecSuffix
			Wave/Z s0Avg = $s0AvgName
			Wave/Z s0X = $s0XName
			
			if(!WaveExists(s0Avg) || !WaveExists(s0X))
				continue
			endif
			
			// Display EC S0 (filled bar, use GetDstateColor)
			Display/K=1/N=$graphName s0Avg vs s0X
			GetDstateColor(0, r, g, b)
			ModifyGraph mode($s0AvgName)=5, hbFill($s0AvgName)=4
			ModifyGraph rgb($s0AvgName)=(r, g, b)
			
			// Add EC S1-Sn (markers)
			for(s = 1; s <= maxState; s += 1)
				String avgSnName = sampleName + "_Dist_S" + num2str(s) + "_ColPhist_m_avg" + ecSuffix
				String xSnName = sampleName + "_Dist_S" + num2str(s) + "_X_m_avg" + ecSuffix
				Wave/Z avgSnW = $avgSnName
				Wave/Z xSnW = $xSnName
				
				if(WaveExists(avgSnW) && WaveExists(xSnW))
					AppendToGraph avgSnW vs xSnW
					GetDstateColor(s, r, g, b)
					ModifyGraph mode($avgSnName)=4, marker($avgSnName)=19, msize($avgSnName)=3
					ModifyGraph rgb($avgSnName)=(r, g, b)
				endif
			endfor
			
			// Add Col data (unfilled bar/open markers, dashed)
			if(DataFolderExists(colCompPath))
				SetDataFolder $colCompPath
				
				String colS0AvgName = sampleName + "_Dist_S0_ColPhist_m_avg" + colSuffix
				String colS0XName = sampleName + "_Dist_S0_X_m_avg" + colSuffix
				Wave/Z colS0Avg = $colS0AvgName
				Wave/Z colS0X = $colS0XName
				
				if(WaveExists(colS0Avg) && WaveExists(colS0X))
					AppendToGraph colS0Avg vs colS0X
					GetDstateColor(0, r, g, b)
					ModifyGraph mode($colS0AvgName)=5, hbFill($colS0AvgName)=0
					ModifyGraph rgb($colS0AvgName)=(r, g, b)
				endif
				
				for(s = 1; s <= maxState; s += 1)
					String colAvgSnName = sampleName + "_Dist_S" + num2str(s) + "_ColPhist_m_avg" + colSuffix
					String colXSnName = sampleName + "_Dist_S" + num2str(s) + "_X_m_avg" + colSuffix
					Wave/Z colAvgSnW = $colAvgSnName
					Wave/Z colXSnW = $colXSnName
					
					if(WaveExists(colAvgSnW) && WaveExists(colXSnW))
						AppendToGraph colAvgSnW vs colXSnW
						GetDstateColor(s, r, g, b)
						ModifyGraph mode($colAvgSnName)=4, marker($colAvgSnName)=8, msize($colAvgSnName)=2
						ModifyGraph lstyle($colAvgSnName)=2
						ModifyGraph rgb($colAvgSnName)=(r, g, b)
					endif
				endfor
			endif
			
			// Graph formatting
			ModifyGraph tick=0, mirror=0, fStyle=1, fSize=14, font="Arial"
			SetAxis left 0, *
			SetAxis bottom 0, *
			Label left "Probability Density"
			Label bottom "Distance [nm]"
			ModifyGraph width={Aspect,1.618}
			
			String chLabel
			if(ch == 0)
				chLabel = "Ch1"
			else
				chLabel = "Ch2"
			endif
			DoWindow/T $graphName, "Average Distance - " + sampleName + " (" + chLabel + ")"
		endfor
		
		// ===== Create State comparison graphs (S0, S1, S2... with all samples) =====
		SetDataFolder $ecCompPath
		
		for(s = 0; s <= maxState; s += 1)
			graphName = "AvgDist_S" + num2str(s) + ecSuffix
			DoWindow/K $graphName
			
			Variable graphCreated = 0
			Variable numValidSamples = 0
			
			// First pass: count valid samples
			for(i = 0; i < numPairs; i += 1)
				if(ch == 0)
					sampleName = List_C1[i]
				else
					sampleName = List_C2[i]
				endif
				String testAvgName = sampleName + "_Dist_S" + num2str(s) + "_ColPhist_m_avg" + ecSuffix
				Wave/Z testAvgW = $testAvgName
				if(WaveExists(testAvgW))
					numValidSamples += 1
				endif
			endfor
			
			Variable validIdx = 0
			
			// Add all samples for this state
			for(i = 0; i < numPairs; i += 1)
				if(ch == 0)
					sampleName = List_C1[i]
				else
					sampleName = List_C2[i]
				endif
				
				String avgName = sampleName + "_Dist_S" + num2str(s) + "_ColPhist_m_avg" + ecSuffix
				String xName = sampleName + "_Dist_S" + num2str(s) + "_X_m_avg" + ecSuffix
				
				Wave/Z avgW = $avgName
				Wave/Z xW = $xName
				
				if(!WaveExists(avgW) || !WaveExists(xW))
					continue
				endif
				
				if(graphCreated == 0)
					Display/K=1/N=$graphName avgW vs xW
					graphCreated = 1
				else
					AppendToGraph avgW vs xW
				endif
				
				// Use state color with shade variation
				GetStateColorWithShade(s, validIdx, numValidSamples, r, g, b)
				if(s == 0)
					ModifyGraph mode($avgName)=5, hbFill($avgName)=4
				else
					ModifyGraph mode($avgName)=4, marker($avgName)=19, msize($avgName)=3
				endif
				ModifyGraph rgb($avgName)=(r, g, b)
				
				// Add Col data with same shade
				if(DataFolderExists(colCompPath))
					SetDataFolder $colCompPath
					String colAvgName = sampleName + "_Dist_S" + num2str(s) + "_ColPhist_m_avg" + colSuffix
					String colXName = sampleName + "_Dist_S" + num2str(s) + "_X_m_avg" + colSuffix
					
					Wave/Z colAvgW = $colAvgName
					Wave/Z colXW = $colXName
					
					if(WaveExists(colAvgW) && WaveExists(colXW))
						AppendToGraph colAvgW vs colXW
						if(s == 0)
							ModifyGraph mode($colAvgName)=5, hbFill($colAvgName)=0
						else
							ModifyGraph mode($colAvgName)=4, marker($colAvgName)=8, msize($colAvgName)=2
							ModifyGraph lstyle($colAvgName)=2
						endif
						ModifyGraph rgb($colAvgName)=(r, g, b)  // Same shade as EC
					endif
					SetDataFolder $ecCompPath
				endif
				validIdx += 1
			endfor
			
			if(graphCreated == 0)
				continue
			endif
			
			// Graph formatting
			ModifyGraph tick=0, mirror=0, fStyle=1, fSize=14, font="Arial"
			SetAxis left 0, *
			SetAxis bottom 0, *
			Label left "Probability Density"
			Label bottom "Distance [nm]"
			ModifyGraph width={Aspect,1.618}
			
			if(ch == 0)
				chLabel = "Ch1"
			else
				chLabel = "Ch2"
			endif
			DoWindow/T $graphName, "Average Distance S" + num2str(s) + " (" + chLabel + ")"
			
			// Legend
			String legendStr = "\\F'Arial'\\Z10"
			for(i = 0; i < numPairs; i += 1)
				if(ch == 0)
					sampleName = List_C1[i]
				else
					sampleName = List_C2[i]
				endif
				avgName = sampleName + "_Dist_S" + num2str(s) + "_ColPhist_m_avg" + ecSuffix
				Wave/Z checkW = $avgName
				if(WaveExists(checkW))
					if(i > 0)
						legendStr += "\r"
					endif
					legendStr += "\\s(" + avgName + ") " + sampleName
				endif
			endfor
			TextBox/C/N=text0/F=0/B=1/A=RT legendStr
		endfor
	endfor
	
	NVAR ColIndex = root:ColIndex
	Printf "Distance histogram averages saved to EC%d:Comparison and Col%d:Comparison\r", ColIndex, ColIndex
	
	SetDataFolder $savedDF
	return 0
End

// =============================================================================
// FitAverageIntensityHistogram - Average
// =============================================================================
// Average Stepsize Histogram
// DisplacementDist1
// =============================================================================
static Function FitAverageStepsizeHistogram(histWave, xWave, fitWaveName)
	Wave histWave, xWave
	String fitWaveName
	
	if(!WaveExists(histWave) || !WaveExists(xWave))
		return -1
	endif
	
	Variable numPts = numpnts(histWave)
	if(numPts < 5)
		return -1
	endif
	
	// WaveStats
	WaveStats/Q/Z histWave
	Variable peakY = V_max
	Variable peakIdx = V_maxRowLoc
	Variable peakX = xWave[peakIdx]
	
	if(peakX <= 0)
		peakX = 0.1
	endif
	
	// : DisplacementDist1 w[0]=A, w[1]=sigma
	Make/FREE/D/N=2 coef_temp
	coef_temp[0] = peakY * peakX  // A ()
	coef_temp[1] = peakX           // sigma
	
	// DisplacementDist1
	Variable V_FitError = 0
	Variable V_FitQuitReason = 0
	
	try
		FuncFit/Q/N/NTHR=0/W=2 DisplacementDist1, coef_temp, histWave /X=xWave
		AbortOnRTE
	catch
		V_FitError = 1
	endtry
	
	if(V_FitError != 0 || V_FitQuitReason > 1)
		return -1
	endif
	
	// 10
	Variable xMin = xWave[0]
	Variable xMax = xWave[numPts-1]
	Variable numFitPts = (numPts - 1) * 10 + 1
	Variable xDelta = (xMax - xMin) / (numFitPts - 1)
	
	Make/O/D/N=(numFitPts) $fitWaveName
	Wave fitW = $fitWaveName
	
	SetScale/P x, xMin, xDelta, fitW
	
	// DisplacementDist1
	Variable A = coef_temp[0], sigma = coef_temp[1]
	Variable sigma2 = sigma^2
	Variable k, xVal
	for(k = 0; k < numFitPts; k += 1)
		xVal = xMin + k * xDelta
		if(xVal > 0 && sigma > 0)
			fitW[k] = A * (xVal / sigma2) * exp(-(xVal^2) / (2 * sigma2))
		else
			fitW[k] = 0
		endif
	endfor
	
	return 0
End

// =============================================================================
// Average On-timeSumExp 
// BatchExpMin_off/ExpMax_off
// =============================================================================
static Function FitAverageOntime(avgWave, timeWave, fitWaveName)
	Wave avgWave, timeWave
	String fitWaveName
	
	if(!WaveExists(avgWave) || !WaveExists(timeWave))
		return -1
	endif
	
	Variable numPts = numpnts(avgWave)
	if(numPts < 5)
		return -1
	endif
	
	// 
	String currentDF = GetDataFolder(1)
	
	// FitSumExpAICSMI_Kinetics.ipf
	// FitSumExpAICroot:On-timeInitialTau1_off
	// ColAvgOntimeFromListColroot
	// Colocalization
	Variable result = FitSumExpAIC(avgWave, timeWave, currentDF, fitWaveName)
	
	if(result > 0)
		return 0  // 
	else
		return -1  // 
	endif
End

// =============================================================================
// Average On-rate
// BatchOnrateFitFunc: CumOnEvent = V0 * (1 - exp(-t/tau))
// SMI_Comparison.ipfFitAverageOnrate
// =============================================================================
static Function FitAverageOnrateCol(avgWave, timeWave, fitWaveName)
	Wave avgWave, timeWave
	String fitWaveName
	
	if(!WaveExists(avgWave) || !WaveExists(timeWave))
		return -1
	endif
	
	Variable numPts = numpnts(avgWave)
	if(numPts < 5)
		return -1
	endif
	
	// 
	String currentDF = GetDataFolder(1)
	
	// SMI_Comparison.ipfFitAverageOnrate
	// FitAverageOnrateroot:InitialTauon, root:InitialVon
	FitAverageOnrate(avgWave, timeWave, currentDF, fitWaveName)
	
	// 
	Wave/Z fitW = $fitWaveName
	if(WaveExists(fitW))
		return 0  // 
	else
		return -1  // 
	endif
End

// =============================================================================
// _m_avg waveGaussfit_*
// SumGauss
// Parameters:
//   histWave - wave
//   fitWaveName - fit wave
//   numOligomers - 1-16
// Returns: 0=, -1=
// =============================================================================
static Function FitAverageIntensityHistogram(histWave, fitWaveName, numOligomers)
	Wave histWave
	String fitWaveName
	Variable numOligomers
	
	if(!WaveExists(histWave))
		return -1
	endif
	
	Variable numPts = numpnts(histWave)
	if(numPts < 5)
		return -1
	endif
	
	// SetScaleX wave
	Variable xOffset = DimOffset(histWave, 0)
	Variable xDelta = DimDelta(histWave, 0)
	
	if(xDelta == 0)
		xDelta = 1  // 
	endif
	
	Make/FREE/D/N=(numPts) xWave
	xWave = xOffset + p * xDelta
	
	// SumGauss: w[0..N-1]=A, w[N]=mean, w[N+1]=sd
	Variable numParams = numOligomers + 2
	Make/FREE/D/N=(numParams) coef_temp
	
	// 
	Variable i
	for(i = 0; i < numOligomers; i += 1)
		coef_temp[i] = 1.0 / numOligomers  // 
	endfor
	
	// mean, sd 
	WaveStats/Q/Z histWave
	Variable peakIdx = V_maxRowLoc
	Variable peakX = xOffset + peakIdx * xDelta
	Variable meanIdx = numOligomers
	Variable sdIdx = numOligomers + 1
	
	NVAR/Z MeanIntGauss = root:MeanIntGauss
	NVAR/Z SDIntGauss = root:SDIntGauss
	
	coef_temp[meanIdx] = NVAR_Exists(MeanIntGauss) ? MeanIntGauss : peakX
	coef_temp[sdIdx] = NVAR_Exists(SDIntGauss) ? SDIntGauss : peakX * 0.3
	
	// SumGauss
	String fitFunc = "SumGauss" + num2str(numOligomers)
	
	// 
	Variable V_FitError = 0
	Variable V_FitQuitReason = 0
	
	try
		FuncFit/Q/N/NTHR=0/W=2 $fitFunc, coef_temp, histWave /X=xWave
		AbortOnRTE
	catch
		V_FitError = 1
	endtry
	
	if(V_FitError != 0 || V_FitQuitReason > 1)
		return -1
	endif
	
	// 10
	Variable numFitPts = (numPts - 1) * 10 + 1
	Variable fitXDelta = xDelta / 10.0
	
	Make/O/D/N=(numFitPts) $fitWaveName
	Wave fitW = $fitWaveName
	
	SetScale/P x, xOffset, fitXDelta, fitW
	
	// SumGauss
	Variable k, jj
	Variable xVal, yVal, amp, mean, sd
	for(k = 0; k < numFitPts; k += 1)
		xVal = xOffset + k * fitXDelta
		yVal = 0
		for(jj = 0; jj < numOligomers; jj += 1)
			amp = coef_temp[jj]
			mean = coef_temp[meanIdx] * (jj + 1)
			sd = coef_temp[sdIdx] * sqrt(jj + 1)  // SumGauss: sd * sqrt(n)
			yVal += amp * exp(-((xVal - mean)^2) / (2 * sd^2))
		endfor
		fitW[k] = yVal
	endfor
	
	return 0
End

// Average Intensity Histogram
// 1. SampleIntensity histogram
// 2. S0,S1,S2...List A/B
Function ColAvgIntensityFromList()
	String savedDF = GetDataFolder(1)
	
	// 
	String ecBasePath = GetECBasePath()
	String ecCompPath = ecBasePath + ":Comparison"
	
	Wave/T/Z List_C1 = root:List_C1
	Wave/T/Z List_C2 = root:List_C2
	
	if(!WaveExists(List_C1) || !WaveExists(List_C2))
		DoAlert 0, "Please create List_C1 and List_C2 first"
		return -1
	endif
	
	NVAR/Z Dstate = root:Dstate
	NVAR/Z cHMM = root:cHMM
	
	Variable maxState = 0
	if(NVAR_Exists(cHMM) && cHMM == 1 && NVAR_Exists(Dstate))
		maxState = Dstate
	endif
	
	Variable numPairs = min(numpnts(List_C1), numpnts(List_C2))
	Variable i, s, r, g, b
	
	//
	NVAR numOligomers = root:numOligomers
	Variable nOlig = numOligomers
	
	Print "=== Average Intensity Histogram ==="
	
	// Create Comparison folder
	if(!DataFolderExists(ecCompPath))
		NewDataFolder $ecCompPath
	endif
	
	String sampleName
	
	// ===== Collect data to Comparison folder =====
	// Process List_C1 (Ch1) - waveSuffix = "_C1E"
	for(i = 0; i < numPairs; i += 1)
		sampleName = List_C1[i]
		String resultsPath = ecBasePath + ":" + sampleName + ":Results"
		
		if(!DataFolderExists(resultsPath))
			continue
		endif
		
		SetDataFolder $resultsPath
		
		for(s = 0; s <= maxState; s += 1)
			// waveSuffix="_C1E" 
			String srcAvgName = "Int_S" + num2str(s) + "_C1E_Phist_m_avg"
			String srcSemName = "Int_S" + num2str(s) + "_C1E_Phist_m_sem"
			
			Wave/Z srcAvg = $srcAvgName
			Wave/Z srcSem = $srcSemName
			
			if(WaveExists(srcAvg))
				String dstAvgName = sampleName + "_Int_S" + num2str(s) + "_C1E_Phist_m_avg"
				String dstSemName = sampleName + "_Int_S" + num2str(s) + "_C1E_Phist_m_sem"
				
				Duplicate/O srcAvg, $(ecCompPath + ":" + dstAvgName)
				if(WaveExists(srcSem))
					Duplicate/O srcSem, $(ecCompPath + ":" + dstSemName)
				endif
			endif
		endfor
	endfor
	
	// Process List_C2 (Ch2) - waveSuffix = "_C2E"
	for(i = 0; i < numPairs; i += 1)
		sampleName = List_C2[i]
		resultsPath = ecBasePath + ":" + sampleName + ":Results"
		
		if(!DataFolderExists(resultsPath))
			continue
		endif
		
		SetDataFolder $resultsPath
		
		for(s = 0; s <= maxState; s += 1)
			// waveSuffix="_C2E" 
			srcAvgName = "Int_S" + num2str(s) + "_C2E_Phist_m_avg"
			srcSemName = "Int_S" + num2str(s) + "_C2E_Phist_m_sem"
			
			Wave/Z srcAvg = $srcAvgName
			Wave/Z srcSem = $srcSemName
			
			if(WaveExists(srcAvg))
				dstAvgName = sampleName + "_Int_S" + num2str(s) + "_C2E_Phist_m_avg"
				dstSemName = sampleName + "_Int_S" + num2str(s) + "_C2E_Phist_m_sem"
				
				Duplicate/O srcAvg, $(ecCompPath + ":" + dstAvgName)
				if(WaveExists(srcSem))
					Duplicate/O srcSem, $(ecCompPath + ":" + dstSemName)
				endif
			endif
		endfor
	endfor
	
	SetDataFolder $ecCompPath
	
	// ===== Create individual sample graphs (all states per sample) =====
	// Use GetDstateColor for state colors
	
	// List_C1 samples (waveSuffix="_C1E")
	for(i = 0; i < numPairs; i += 1)
		sampleName = List_C1[i]
		
		String graphName = "AvgInt_" + sampleName + "_C1E"
		DoWindow/K $graphName
		
		String s0AvgName = sampleName + "_Int_S0_C1E_Phist_m_avg"
		Wave/Z s0Avg = $s0AvgName
		
		if(!WaveExists(s0Avg))
			continue
		endif
		
		Display/K=1/N=$graphName s0Avg
		GetDstateColor(0, r, g, b)
		ModifyGraph rgb($s0AvgName)=(r, g, b)
		
		// S0
		String fitName = sampleName + "_fit_Int_S0_C1E_Phist_m_avg"
		if(FitAverageIntensityHistogram(s0Avg, fitName, nOlig) == 0)
			Wave/Z fitW = $fitName
			if(WaveExists(fitW))
				AppendToGraph fitW
				ModifyGraph rgb($fitName)=(r, g, b)
				ModifyGraph mode($fitName)=0, lsize($fitName)=1.5
			endif
		endif
		
		for(s = 1; s <= maxState; s += 1)
			String histName = sampleName + "_Int_S" + num2str(s) + "_C1E_Phist_m_avg"
			Wave/Z histW = $histName
			if(WaveExists(histW))
				AppendToGraph histW
				GetDstateColor(s, r, g, b)
				ModifyGraph rgb($histName)=(r, g, b)
				
				// 
				fitName = sampleName + "_fit_Int_S" + num2str(s) + "_C1E_Phist_m_avg"
				if(FitAverageIntensityHistogram(histW, fitName, nOlig) == 0)
					Wave/Z fitW = $fitName
					if(WaveExists(fitW))
						AppendToGraph fitW
						ModifyGraph rgb($fitName)=(r, g, b)
						ModifyGraph mode($fitName)=0, lsize($fitName)=1.5
					endif
				endif
			endif
		endfor
		
		// Graph formatting
		ModifyGraph tick=0, mirror=0, fStyle=1, fSize=14, font="Arial"
		SetAxis left 0, *
		SetAxis bottom 0, *
		Label left "Probability Density"
		Label bottom "Intensity [a.u.]"
		ModifyGraph width={Aspect,1.618}
		DoWindow/T $graphName, "Average Intensity - " + sampleName
	endfor
	
	// List_C2 samples (waveSuffix="_C2E")
	for(i = 0; i < numPairs; i += 1)
		sampleName = List_C2[i]
		
		graphName = "AvgInt_" + sampleName + "_C2E"
		DoWindow/K $graphName
		
		s0AvgName = sampleName + "_Int_S0_C2E_Phist_m_avg"
		Wave/Z s0Avg = $s0AvgName
		
		if(!WaveExists(s0Avg))
			continue
		endif
		
		Display/K=1/N=$graphName s0Avg
		GetDstateColor(0, r, g, b)
		ModifyGraph rgb($s0AvgName)=(r, g, b)
		
		// S0
		fitName = sampleName + "_fit_Int_S0_C2E_Phist_m_avg"
		if(FitAverageIntensityHistogram(s0Avg, fitName, nOlig) == 0)
			Wave/Z fitW = $fitName
			if(WaveExists(fitW))
				AppendToGraph fitW
				ModifyGraph rgb($fitName)=(r, g, b)
				ModifyGraph mode($fitName)=0, lsize($fitName)=1.5
			endif
		endif
		
		for(s = 1; s <= maxState; s += 1)
			histName = sampleName + "_Int_S" + num2str(s) + "_C2E_Phist_m_avg"
			Wave/Z histW = $histName
			if(WaveExists(histW))
				AppendToGraph histW
				GetDstateColor(s, r, g, b)
				ModifyGraph rgb($histName)=(r, g, b)
				
				// 
				fitName = sampleName + "_fit_Int_S" + num2str(s) + "_C2E_Phist_m_avg"
				if(FitAverageIntensityHistogram(histW, fitName, nOlig) == 0)
					Wave/Z fitW = $fitName
					if(WaveExists(fitW))
						AppendToGraph fitW
						ModifyGraph rgb($fitName)=(r, g, b)
						ModifyGraph mode($fitName)=0, lsize($fitName)=1.5
					endif
				endif
			endif
		endfor
		
		// Graph formatting
		ModifyGraph tick=0, mirror=0, fStyle=1, fSize=14, font="Arial"
		SetAxis left 0, *
		SetAxis bottom 0, *
		Label left "Probability Density"
		Label bottom "Intensity [a.u.]"
		ModifyGraph width={Aspect,1.618}
		DoWindow/T $graphName, "Average Intensity - " + sampleName
	endfor
	
	// ===== Create comparison graphs (S0, S1, S2... with all samples) =====
	// Use GetStateColorWithShade: same state = same color family with shade variation
	for(s = 0; s <= maxState; s += 1)
		// List A comparison graph (waveSuffix="_C1E")
		graphName = "AvgInt_S" + num2str(s) + "_C1E_ListA"
		DoWindow/K $graphName
		
		Variable graphCreated = 0
		Variable numValidSamples = 0
		
		// First pass: count valid samples
		for(i = 0; i < numPairs; i += 1)
			sampleName = List_C1[i]
			String avgName = sampleName + "_Int_S" + num2str(s) + "_C1E_Phist_m_avg"
			Wave/Z avgW = $avgName
			if(WaveExists(avgW))
				numValidSamples += 1
			endif
		endfor
		
		Variable validIdx = 0
		for(i = 0; i < numPairs; i += 1)
			sampleName = List_C1[i]
			avgName = sampleName + "_Int_S" + num2str(s) + "_C1E_Phist_m_avg"
			
			Wave/Z avgW = $avgName
			if(!WaveExists(avgW))
				continue
			endif
			
			if(graphCreated == 0)
				Display/K=1/N=$graphName avgW
				graphCreated = 1
			else
				AppendToGraph avgW
			endif
			
			// Use state color with shade variation
			GetStateColorWithShade(s, validIdx, numValidSamples, r, g, b)
			ModifyGraph rgb($avgName)=(r, g, b)
			ModifyGraph mode($avgName)=0, lsize($avgName)=1.5
			
			// 
			fitName = sampleName + "_fit_Int_S" + num2str(s) + "_C1E_Phist_m_avg"
			if(FitAverageIntensityHistogram(avgW, fitName, nOlig) == 0)
				Wave/Z fitW = $fitName
				if(WaveExists(fitW))
					AppendToGraph fitW
					ModifyGraph rgb($fitName)=(r, g, b)
					ModifyGraph mode($fitName)=0, lsize($fitName)=1, lstyle($fitName)=2
				endif
			endif
			validIdx += 1
		endfor
		
		if(graphCreated == 1)
			ModifyGraph tick=0, mirror=0, fStyle=1, fSize=14, font="Arial"
			SetAxis left 0, *
			SetAxis bottom 0, *
			Label left "Probability Density"
			Label bottom "Intensity [a.u.]"
			ModifyGraph width={Aspect,1.618}
			DoWindow/T $graphName, "Intensity S" + num2str(s) + " Comparison (List A - C1E)"
			
			// Legend
			String legendStr = "\\F'Arial'\\Z10"
			for(i = 0; i < numPairs; i += 1)
				sampleName = List_C1[i]
				avgName = sampleName + "_Int_S" + num2str(s) + "_C1E_Phist_m_avg"
				Wave/Z checkW = $avgName
				if(WaveExists(checkW))
					if(i > 0)
						legendStr += "\r"
					endif
					legendStr += "\\s(" + avgName + ") " + sampleName
				endif
			endfor
			TextBox/C/N=text0/F=0/B=1/A=RT legendStr
		endif
		
		// List B comparison graph (waveSuffix="_C2E")
		graphName = "AvgInt_S" + num2str(s) + "_C2E_ListB"
		DoWindow/K $graphName
		
		graphCreated = 0
		numValidSamples = 0
		
		// First pass: count valid samples
		for(i = 0; i < numPairs; i += 1)
			sampleName = List_C2[i]
			avgName = sampleName + "_Int_S" + num2str(s) + "_C2E_Phist_m_avg"
			Wave/Z avgW = $avgName
			if(WaveExists(avgW))
				numValidSamples += 1
			endif
		endfor
		
		validIdx = 0
		for(i = 0; i < numPairs; i += 1)
			sampleName = List_C2[i]
			avgName = sampleName + "_Int_S" + num2str(s) + "_C2E_Phist_m_avg"
			
			Wave/Z avgW = $avgName
			if(!WaveExists(avgW))
				continue
			endif
			
			if(graphCreated == 0)
				Display/K=1/N=$graphName avgW
				graphCreated = 1
			else
				AppendToGraph avgW
			endif
			
			// Use state color with shade variation
			GetStateColorWithShade(s, validIdx, numValidSamples, r, g, b)
			ModifyGraph rgb($avgName)=(r, g, b)
			ModifyGraph mode($avgName)=0, lsize($avgName)=1.5
			
			// 
			fitName = sampleName + "_fit_Int_S" + num2str(s) + "_C2E_Phist_m_avg"
			if(FitAverageIntensityHistogram(avgW, fitName, nOlig) == 0)
				Wave/Z fitW = $fitName
				if(WaveExists(fitW))
					AppendToGraph fitW
					ModifyGraph rgb($fitName)=(r, g, b)
					ModifyGraph mode($fitName)=0, lsize($fitName)=1, lstyle($fitName)=2
				endif
			endif
			validIdx += 1
		endfor
		
		if(graphCreated == 1)
			ModifyGraph tick=0, mirror=0, fStyle=1, fSize=14, font="Arial"
			SetAxis left 0, *
			SetAxis bottom 0, *
			Label left "Probability Density"
			Label bottom "Intensity [a.u.]"
			ModifyGraph width={Aspect,1.618}
			DoWindow/T $graphName, "Intensity S" + num2str(s) + " Comparison (List B - C2E)"
			
			// Legend
			legendStr = "\\F'Arial'\\Z10"
			for(i = 0; i < numPairs; i += 1)
				sampleName = List_C2[i]
				avgName = sampleName + "_Int_S" + num2str(s) + "_C2E_Phist_m_avg"
				Wave/Z checkW = $avgName
				if(WaveExists(checkW))
					if(i > 0)
						legendStr += "\r"
					endif
					legendStr += "\\s(" + avgName + ") " + sampleName
				endif
			endfor
			TextBox/C/N=text0/F=0/B=1/A=RT legendStr
		endif
	endfor
	
	NVAR ColIndex = root:ColIndex
	Printf "Intensity histogram averages saved to EC%d:Comparison\r", ColIndex
	
	SetDataFolder $savedDF
	return 0
End

// Average MSD (Diffusion) Plot
// 1. SampleMSDState
// 2. S0,S1,S2...List A/BMSD
// Average Stepsize Histogram
// 1. SampleStepsizeState
// 2. S0,S1,S2...List A/BStepsize
// Note: Colocalization tabΔt=1
Function ColAvgDiffusionFromList()
	String savedDF = GetDataFolder(1)
	
	// 
	String ecBasePath = GetECBasePath()
	String ecCompPath = ecBasePath + ":Comparison"
	
	Wave/T/Z List_C1 = root:List_C1
	Wave/T/Z List_C2 = root:List_C2
	
	if(!WaveExists(List_C1) || !WaveExists(List_C2))
		DoAlert 0, "Please create List_C1 and List_C2 first"
		return -1
	endif
	
	NVAR/Z Dstate = root:Dstate
	NVAR/Z cHMM = root:cHMM
	
	Variable maxState = 0
	if(NVAR_Exists(cHMM) && cHMM == 1 && NVAR_Exists(Dstate))
		maxState = Dstate
	endif
	
	Variable deltaT = 1  // Colocalization uses deltaT=1 only
	String dtStr = "dt" + num2str(deltaT)
	
	Variable numPairs = min(numpnts(List_C1), numpnts(List_C2))
	Variable i, s, r, g, b
	
	Print "=== Average Stepsize Histogram ==="
	
	// Create Comparison folder
	if(!DataFolderExists(ecCompPath))
		NewDataFolder $ecCompPath
	endif
	
	String sampleName
	
	// ===== Collect data to Comparison folder =====
	// Process List_C1 (waveSuffix="_C1E")
	for(i = 0; i < numPairs; i += 1)
		sampleName = List_C1[i]
		String resultsPath = ecBasePath + ":" + sampleName + ":Results"
		
		if(!DataFolderExists(resultsPath))
			Printf "  Results NOT found: %s\r", resultsPath
			continue
		endif
		
		SetDataFolder $resultsPath
		Printf "  Checking %s...\r", resultsPath
		
		for(s = 0; s <= maxState; s += 1)
			// waveSuffix "_C1E" 
			String srcAvgName = "StepHist_" + dtStr + "_S" + num2str(s) + "_C1E_m_avg"
			String srcSemName = "StepHist_" + dtStr + "_S" + num2str(s) + "_C1E_m_sem"
			String srcXName = "StepHist_x_" + dtStr + "_S" + num2str(s) + "_C1E_m_avg"
			
			Wave/Z srcAvg = $srcAvgName
			Wave/Z srcSem = $srcSemName
			Wave/Z srcX = $srcXName
			
			if(WaveExists(srcAvg))
				String dstAvgName = sampleName + "_Step_S" + num2str(s) + "_C1E_avg"
				String dstSemName = sampleName + "_Step_S" + num2str(s) + "_C1E_sem"
				String dstXName = sampleName + "_Step_S" + num2str(s) + "_C1E_x"
				
				Duplicate/O srcAvg, $(ecCompPath + ":" + dstAvgName)
				if(WaveExists(srcSem))
					Duplicate/O srcSem, $(ecCompPath + ":" + dstSemName)
				endif
				if(WaveExists(srcX))
					Duplicate/O srcX, $(ecCompPath + ":" + dstXName)
				endif
				Printf "    S%d: StepHist found\r", s
			else
				Printf "    S%d: %s NOT found\r", s, srcAvgName
			endif
		endfor
	endfor
	
	// Process List_C2 (waveSuffix="_C2E")
	for(i = 0; i < numPairs; i += 1)
		sampleName = List_C2[i]
		resultsPath = ecBasePath + ":" + sampleName + ":Results"
		
		if(!DataFolderExists(resultsPath))
			Printf "  Results NOT found: %s\r", resultsPath
			continue
		endif
		
		SetDataFolder $resultsPath
		Printf "  Checking %s...\r", resultsPath
		
		for(s = 0; s <= maxState; s += 1)
			// waveSuffix "_C2E" 
			srcAvgName = "StepHist_" + dtStr + "_S" + num2str(s) + "_C2E_m_avg"
			srcSemName = "StepHist_" + dtStr + "_S" + num2str(s) + "_C2E_m_sem"
			srcXName = "StepHist_x_" + dtStr + "_S" + num2str(s) + "_C2E_m_avg"
			
			Wave/Z srcAvg = $srcAvgName
			Wave/Z srcSem = $srcSemName
			Wave/Z srcX = $srcXName
			
			if(WaveExists(srcAvg))
				dstAvgName = sampleName + "_Step_S" + num2str(s) + "_C2E_avg"
				dstSemName = sampleName + "_Step_S" + num2str(s) + "_C2E_sem"
				dstXName = sampleName + "_Step_S" + num2str(s) + "_C2E_x"
				
				Duplicate/O srcAvg, $(ecCompPath + ":" + dstAvgName)
				if(WaveExists(srcSem))
					Duplicate/O srcSem, $(ecCompPath + ":" + dstSemName)
				endif
				if(WaveExists(srcX))
					Duplicate/O srcX, $(ecCompPath + ":" + dstXName)
				endif
			endif
		endfor
	endfor
	
	SetDataFolder $ecCompPath
	
	// ===== Create individual sample graphs (all states per sample) =====
	// List_C1 samples (waveSuffix="_C1E")
	for(i = 0; i < numPairs; i += 1)
		sampleName = List_C1[i]
		
		String graphName = "AvgStep_" + sampleName + "_C1E"
		DoWindow/K $graphName
		
		String s0AvgName = sampleName + "_Step_S0_C1E_avg"
		String s0XName = sampleName + "_Step_S0_C1E_x"
		Wave/Z s0Avg = $s0AvgName
		Wave/Z s0X = $s0XName
		
		if(!WaveExists(s0Avg) || !WaveExists(s0X))
			continue
		endif
		
		Display/K=1/N=$graphName s0Avg vs s0X
		GetDstateColor(0, r, g, b)
		ModifyGraph rgb($s0AvgName)=(r, g, b)
		ModifyGraph mode($s0AvgName)=0, lsize($s0AvgName)=1.5
		
		// S0 
		String fitName = sampleName + "_fit_Step_S0_C1E"
		if(FitAverageStepsizeHistogram(s0Avg, s0X, fitName) == 0)
			Wave/Z fitW = $fitName
			if(WaveExists(fitW))
				AppendToGraph fitW
				ModifyGraph rgb($fitName)=(r, g, b)
				ModifyGraph mode($fitName)=0, lsize($fitName)=1.5, lstyle($fitName)=2
			endif
		endif
		
		for(s = 1; s <= maxState; s += 1)
			String avgName = sampleName + "_Step_S" + num2str(s) + "_C1E_avg"
			String xName = sampleName + "_Step_S" + num2str(s) + "_C1E_x"
			Wave/Z avgW = $avgName
			Wave/Z xW = $xName
			if(WaveExists(avgW) && WaveExists(xW))
				AppendToGraph avgW vs xW
				GetDstateColor(s, r, g, b)
				ModifyGraph rgb($avgName)=(r, g, b)
				ModifyGraph mode($avgName)=0, lsize($avgName)=1.5
				
				// Sn 
				fitName = sampleName + "_fit_Step_S" + num2str(s) + "_C1E"
				if(FitAverageStepsizeHistogram(avgW, xW, fitName) == 0)
					Wave/Z fitW = $fitName
					if(WaveExists(fitW))
						AppendToGraph fitW
						ModifyGraph rgb($fitName)=(r, g, b)
						ModifyGraph mode($fitName)=0, lsize($fitName)=1.5, lstyle($fitName)=2
					endif
				endif
			endif
		endfor
		
		ModifyGraph tick=0, mirror=0, fStyle=1, fSize=14, font="Arial"
		SetAxis left 0, *
		SetAxis bottom 0, *
		Label left "Relative Frequency"
		Label bottom "Step size [µm]"
		ModifyGraph width={Aspect,1.618}
		DoWindow/T $graphName, "Average Stepsize - " + sampleName
	endfor
	
	// List_C2 samples (waveSuffix="_C2E")
	for(i = 0; i < numPairs; i += 1)
		sampleName = List_C2[i]
		
		graphName = "AvgStep_" + sampleName + "_C2E"
		DoWindow/K $graphName
		
		s0AvgName = sampleName + "_Step_S0_C2E_avg"
		s0XName = sampleName + "_Step_S0_C2E_x"
		Wave/Z s0Avg = $s0AvgName
		Wave/Z s0X = $s0XName
		
		if(!WaveExists(s0Avg) || !WaveExists(s0X))
			continue
		endif
		
		Display/K=1/N=$graphName s0Avg vs s0X
		GetDstateColor(0, r, g, b)
		ModifyGraph rgb($s0AvgName)=(r, g, b)
		ModifyGraph mode($s0AvgName)=0, lsize($s0AvgName)=1.5
		
		// S0 
		fitName = sampleName + "_fit_Step_S0_C2E"
		if(FitAverageStepsizeHistogram(s0Avg, s0X, fitName) == 0)
			Wave/Z fitW = $fitName
			if(WaveExists(fitW))
				AppendToGraph fitW
				ModifyGraph rgb($fitName)=(r, g, b)
				ModifyGraph mode($fitName)=0, lsize($fitName)=1.5, lstyle($fitName)=2
			endif
		endif
		
		for(s = 1; s <= maxState; s += 1)
			avgName = sampleName + "_Step_S" + num2str(s) + "_C2E_avg"
			xName = sampleName + "_Step_S" + num2str(s) + "_C2E_x"
			Wave/Z avgW = $avgName
			Wave/Z xW = $xName
			if(WaveExists(avgW) && WaveExists(xW))
				AppendToGraph avgW vs xW
				GetDstateColor(s, r, g, b)
				ModifyGraph rgb($avgName)=(r, g, b)
				ModifyGraph mode($avgName)=0, lsize($avgName)=1.5
				
				// Sn 
				fitName = sampleName + "_fit_Step_S" + num2str(s) + "_C2E"
				if(FitAverageStepsizeHistogram(avgW, xW, fitName) == 0)
					Wave/Z fitW = $fitName
					if(WaveExists(fitW))
						AppendToGraph fitW
						ModifyGraph rgb($fitName)=(r, g, b)
						ModifyGraph mode($fitName)=0, lsize($fitName)=1.5, lstyle($fitName)=2
					endif
				endif
			endif
		endfor
		
		ModifyGraph tick=0, mirror=0, fStyle=1, fSize=14, font="Arial"
		SetAxis left 0, *
		SetAxis bottom 0, *
		Label left "Relative Frequency"
		Label bottom "Step size [µm]"
		ModifyGraph width={Aspect,1.618}
		DoWindow/T $graphName, "Average Stepsize - " + sampleName
	endfor
	
	// ===== Create comparison graphs (S0, S1, S2... with all samples) =====
	for(s = 0; s <= maxState; s += 1)
		// List A comparison graph (waveSuffix="_C1E")
		graphName = "AvgStep_S" + num2str(s) + "_C1E_ListA"
		DoWindow/K $graphName
		
		Variable graphCreated = 0
		Variable numValidSamples = 0
		
		for(i = 0; i < numPairs; i += 1)
			sampleName = List_C1[i]
			String testAvgName = sampleName + "_Step_S" + num2str(s) + "_C1E_avg"
			Wave/Z testW = $testAvgName
			if(WaveExists(testW))
				numValidSamples += 1
			endif
		endfor
		
		Variable validIdx = 0
		for(i = 0; i < numPairs; i += 1)
			sampleName = List_C1[i]
			avgName = sampleName + "_Step_S" + num2str(s) + "_C1E_avg"
			xName = sampleName + "_Step_S" + num2str(s) + "_C1E_x"
			String semName = sampleName + "_Step_S" + num2str(s) + "_C1E_sem"
			
			Wave/Z avgW = $avgName
			Wave/Z xW = $xName
			Wave/Z semW = $semName
			
			if(!WaveExists(avgW) || !WaveExists(xW))
				continue
			endif
			
			if(graphCreated == 0)
				Display/K=1/N=$graphName avgW vs xW
				graphCreated = 1
			else
				AppendToGraph avgW vs xW
			endif
			
			GetStateColorWithShade(s, validIdx, numValidSamples, r, g, b)
			ModifyGraph rgb($avgName)=(r, g, b)
			ModifyGraph mode($avgName)=0, lsize($avgName)=1.5
			
			if(WaveExists(semW))
				ErrorBars $avgName SHADE= {0,4,(r,g,b,32768),(r,g,b,32768)},wave=(semW, semW)
			endif
			validIdx += 1
		endfor
		
		if(graphCreated == 1)
			ModifyGraph tick=0, mirror=0, fStyle=1, fSize=14, font="Arial"
			SetAxis left 0, *
			SetAxis bottom 0, *
			Label left "Relative Frequency"
			Label bottom "Step size [µm]"
			ModifyGraph width={Aspect,1.618}
			DoWindow/T $graphName, "Stepsize S" + num2str(s) + " Comparison (List A - C1E)"
			
			String legendStr = "\\F'Arial'\\Z10"
			for(i = 0; i < numPairs; i += 1)
				sampleName = List_C1[i]
				avgName = sampleName + "_Step_S" + num2str(s) + "_C1E_avg"
				Wave/Z checkW = $avgName
				if(WaveExists(checkW))
					if(i > 0)
						legendStr += "\r"
					endif
					legendStr += "\\s(" + avgName + ") " + sampleName
				endif
			endfor
			TextBox/C/N=text0/F=0/B=1/A=RT legendStr
		endif
		
		// List B comparison graph (waveSuffix="_C2E")
		graphName = "AvgStep_S" + num2str(s) + "_C2E_ListB"
		DoWindow/K $graphName
		
		graphCreated = 0
		numValidSamples = 0
		
		for(i = 0; i < numPairs; i += 1)
			sampleName = List_C2[i]
			testAvgName = sampleName + "_Step_S" + num2str(s) + "_C2E_avg"
			Wave/Z testW = $testAvgName
			if(WaveExists(testW))
				numValidSamples += 1
			endif
		endfor
		
		validIdx = 0
		for(i = 0; i < numPairs; i += 1)
			sampleName = List_C2[i]
			avgName = sampleName + "_Step_S" + num2str(s) + "_C2E_avg"
			xName = sampleName + "_Step_S" + num2str(s) + "_C2E_x"
			semName = sampleName + "_Step_S" + num2str(s) + "_C2E_sem"
			
			Wave/Z avgW = $avgName
			Wave/Z xW = $xName
			Wave/Z semW = $semName
			
			if(!WaveExists(avgW) || !WaveExists(xW))
				continue
			endif
			
			if(graphCreated == 0)
				Display/K=1/N=$graphName avgW vs xW
				graphCreated = 1
			else
				AppendToGraph avgW vs xW
			endif
			
			GetStateColorWithShade(s, validIdx, numValidSamples, r, g, b)
			ModifyGraph rgb($avgName)=(r, g, b)
			ModifyGraph mode($avgName)=0, lsize($avgName)=1.5
			
			if(WaveExists(semW))
				ErrorBars $avgName SHADE= {0,4,(r,g,b,32768),(r,g,b,32768)},wave=(semW, semW)
			endif
			validIdx += 1
		endfor
		
		if(graphCreated == 1)
			ModifyGraph tick=0, mirror=0, fStyle=1, fSize=14, font="Arial"
			SetAxis left 0, *
			SetAxis bottom 0, *
			Label left "Relative Frequency"
			Label bottom "Step size [µm]"
			ModifyGraph width={Aspect,1.618}
			DoWindow/T $graphName, "Stepsize S" + num2str(s) + " Comparison (List B - C2E)"
			
			legendStr = "\\F'Arial'\\Z10"
			for(i = 0; i < numPairs; i += 1)
				sampleName = List_C2[i]
				avgName = sampleName + "_Step_S" + num2str(s) + "_C2E_avg"
				Wave/Z checkW = $avgName
				if(WaveExists(checkW))
					if(i > 0)
						legendStr += "\r"
					endif
					legendStr += "\\s(" + avgName + ") " + sampleName
				endif
			endfor
			TextBox/C/N=text0/F=0/B=1/A=RT legendStr
		endif
	endfor
	
	NVAR ColIndex = root:ColIndex
	Printf "Stepsize histogram averages saved to EC%d:Comparison\r", ColIndex
	
	SetDataFolder $savedDF
	return 0
End

// Average On-time Distribution
// State P_Duration
Function ColAvgOntimeFromList()
	String savedDF = GetDataFolder(1)
	
	// 
	String ecBasePath = GetECBasePath()
	String ecCompPath = ecBasePath + ":Comparison"
	
	Wave/T/Z List_C1 = root:List_C1
	Wave/T/Z List_C2 = root:List_C2
	
	if(!WaveExists(List_C1) || !WaveExists(List_C2))
		DoAlert 0, "Please create List_C1 and List_C2 first"
		return -1
	endif
	
	// Colocalization
	NVAR ColTau1 = root:ColTau1
	NVAR ColTauScale = root:ColTauScale
	NVAR ColA1 = root:ColA1
	NVAR ColAScale = root:ColAScale

	// Colocalization fit parameters (display only — globals NOT modified)
	Variable colTau1Val = ColTau1
	Variable colTauScaleVal = ColTauScale
	Variable colA1Val = ColA1
	Variable colAScaleVal = ColAScale
	
	Variable numPairs = min(numpnts(List_C1), numpnts(List_C2))
	Variable i, r, g, b
	
	Print "=== Average On-time Distribution ==="
	Printf "Fit params: Tau1=%.3f, Scale_tau=%.1f, A1=%.1f, Scale_A=%.2f\r", colTau1Val, colTauScaleVal, colA1Val, colAScaleVal
	
	// Create Comparison folder
	if(!DataFolderExists(ecCompPath))
		NewDataFolder $ecCompPath
	endif
	
	// Sample colors for comparison
	Make/FREE/N=(8,3) sampleColors
	sampleColors[0][0] = 0;       sampleColors[0][1] = 0;       sampleColors[0][2] = 0
	sampleColors[1][0] = 65280;   sampleColors[1][1] = 0;       sampleColors[1][2] = 0
	sampleColors[2][0] = 0;       sampleColors[2][1] = 0;       sampleColors[2][2] = 65280
	sampleColors[3][0] = 0;       sampleColors[3][1] = 39168;   sampleColors[3][2] = 0
	sampleColors[4][0] = 65280;   sampleColors[4][1] = 43520;   sampleColors[4][2] = 0
	sampleColors[5][0] = 65280;   sampleColors[5][1] = 0;       sampleColors[5][2] = 65280
	sampleColors[6][0] = 0;       sampleColors[6][1] = 65280;   sampleColors[6][2] = 65280
	sampleColors[7][0] = 39168;   sampleColors[7][1] = 26112;   sampleColors[7][2] = 13056
	
	String sampleName
	
	// ===== Collect data to Comparison folder =====
	// List_C1 (Ch1) - waveSuffix="_C1E"
	for(i = 0; i < numPairs; i += 1)
		sampleName = List_C1[i]
		String resultsPath = ecBasePath + ":" + sampleName + ":Results"
		
		if(!DataFolderExists(resultsPath))
			Printf "  Results not found: %s\r", resultsPath
			continue
		endif
		
		SetDataFolder $resultsPath
		
		// 
		String srcAvgName = "P_Duration_C1E_m_avg"
		String srcSemName = "P_Duration_C1E_m_sem"
		String srcTimeName = "time_Duration_C1E_m_avg"
		String srcFitName = "fit_P_Duration_C1E_m_avg"
		
		Wave/Z srcAvg = $srcAvgName
		Wave/Z srcSem = $srcSemName
		Wave/Z srcTime = $srcTimeName
		Wave/Z srcFit = $srcFitName
		
		if(WaveExists(srcAvg))
			String dstAvgName = sampleName + "_PDur_C1E_avg"
			String dstSemName = sampleName + "_PDur_C1E_sem"
			String dstTimeName = sampleName + "_TimeDur_C1E"
			String dstFitName = sampleName + "_PDur_C1E_fit"
			
			Duplicate/O srcAvg, $(ecCompPath + ":" + dstAvgName)
			if(WaveExists(srcSem))
				Duplicate/O srcSem, $(ecCompPath + ":" + dstSemName)
			endif
			if(WaveExists(srcTime))
				Duplicate/O srcTime, $(ecCompPath + ":" + dstTimeName)
			endif
			if(WaveExists(srcFit))
				Duplicate/O srcFit, $(ecCompPath + ":" + dstFitName)
			endif
			Printf "  %s: P_Duration_C1E found\r", sampleName
		else
			Printf "  %s: P_Duration_C1E NOT found in %s\r", sampleName, resultsPath
		endif
	endfor
	
	// List_C2 (Ch2) - waveSuffix="_C2E"
	for(i = 0; i < numPairs; i += 1)
		sampleName = List_C2[i]
		resultsPath = ecBasePath + ":" + sampleName + ":Results"
		
		if(!DataFolderExists(resultsPath))
			Printf "  Results not found: %s\r", resultsPath
			continue
		endif
		
		SetDataFolder $resultsPath
		
		srcAvgName = "P_Duration_C2E_m_avg"
		srcSemName = "P_Duration_C2E_m_sem"
		srcTimeName = "time_Duration_C2E_m_avg"
		srcFitName = "fit_P_Duration_C2E_m_avg"
		
		Wave/Z srcAvg = $srcAvgName
		Wave/Z srcSem = $srcSemName
		Wave/Z srcTime = $srcTimeName
		Wave/Z srcFit = $srcFitName
		
		if(WaveExists(srcAvg))
			dstAvgName = sampleName + "_PDur_C2E_avg"
			dstSemName = sampleName + "_PDur_C2E_sem"
			dstTimeName = sampleName + "_TimeDur_C2E"
			dstFitName = sampleName + "_PDur_C2E_fit"
			
			Duplicate/O srcAvg, $(ecCompPath + ":" + dstAvgName)
			if(WaveExists(srcSem))
				Duplicate/O srcSem, $(ecCompPath + ":" + dstSemName)
			endif
			if(WaveExists(srcTime))
				Duplicate/O srcTime, $(ecCompPath + ":" + dstTimeName)
			endif
			if(WaveExists(srcFit))
				Duplicate/O srcFit, $(ecCompPath + ":" + dstFitName)
			endif
			Printf "  %s: P_Duration_C2E found\r", sampleName
		else
			Printf "  %s: P_Duration_C2E NOT found in %s\r", sampleName, resultsPath
		endif
	endfor
	
	SetDataFolder $ecCompPath
	
	// ===== Create comparison graph (List A - Ch1) =====
	String graphName = "AvgOntime_ListA"
	DoWindow/K $graphName
	
	Variable graphCreated = 0
	
	for(i = 0; i < numPairs; i += 1)
		sampleName = List_C1[i]
		String avgName = sampleName + "_PDur_C1E_avg"
		String timeName = sampleName + "_TimeDur_C1E"
		String semName = sampleName + "_PDur_C1E_sem"
		
		Wave/Z avgW = $avgName
		Wave/Z timeW = $timeName
		Wave/Z semW = $semName
		
		if(!WaveExists(avgW))
			continue
		endif
		
		// Create time wave if not exists
		if(!WaveExists(timeW))
			NVAR framerate = root:framerate
			Variable fr = framerate
			Make/O/N=(numpnts(avgW)) $timeName
			Wave timeW = $timeName
			timeW = (p + 1) * fr
		endif
		
		Variable sampleColorIdx = mod(i, 8)
		
		if(graphCreated == 0)
			Display/K=1/N=$graphName avgW vs timeW
			graphCreated = 1
		else
			AppendToGraph avgW vs timeW
		endif
		
		r = sampleColors[sampleColorIdx][0]
		g = sampleColors[sampleColorIdx][1]
		b = sampleColors[sampleColorIdx][2]
		ModifyGraph rgb($avgName)=(r, g, b)
		ModifyGraph mode($avgName)=3, marker($avgName)=19, msize($avgName)=2
		
		if(WaveExists(semW))
			ErrorBars $avgName SHADE= {0,4,(r,g,b,32768),(r,g,b,32768)},wave=(semW, semW)
		endif
		
		// SetScale
		String fitName = sampleName + "_fit_PDur_C1E"
		if(FitAverageOntime(avgW, timeW, fitName) == 0)
			Wave/Z fitW = $fitName
			if(WaveExists(fitW))
				AppendToGraph fitW
				ModifyGraph rgb($fitName)=(r, g, b)
				ModifyGraph mode($fitName)=0, lsize($fitName)=1.5
			endif
		endif
	endfor
	
	if(graphCreated == 1)
		ModifyGraph tick=0, mirror=0, fStyle=1, fSize=14, font="Arial"
		ModifyGraph width={Aspect, 1.618}
		ModifyGraph log(left)=1
		Label left "Survival Probability [%]"
		Label bottom "Time [s]"
		SetAxis left 0.1, 100
		DoWindow/T $graphName, "On-time Distribution (List A - Ch1)"
		
		String legendStr = "\\F'Arial'\\Z10"
		for(i = 0; i < numPairs; i += 1)
			sampleName = List_C1[i]
			avgName = sampleName + "_PDur_C1E_avg"
			Wave/Z checkW = $avgName
			if(WaveExists(checkW))
				if(i > 0)
					legendStr += "\r"
				endif
				legendStr += "\\s(" + avgName + ") " + sampleName
			endif
		endfor
		TextBox/C/N=text0/F=0/B=1/A=RT legendStr
	endif
	
	// ===== Create comparison graph (List B - Ch2) =====
	graphName = "AvgOntime_ListB"
	DoWindow/K $graphName
	
	graphCreated = 0
	
	for(i = 0; i < numPairs; i += 1)
		sampleName = List_C2[i]
		avgName = sampleName + "_PDur_C2E_avg"
		timeName = sampleName + "_TimeDur_C2E"
		semName = sampleName + "_PDur_C2E_sem"
		
		Wave/Z avgW = $avgName
		Wave/Z timeW = $timeName
		Wave/Z semW = $semName
		
		if(!WaveExists(avgW))
			continue
		endif
		
		if(!WaveExists(timeW))
			NVAR framerate = root:framerate
			fr = framerate
			Make/O/N=(numpnts(avgW)) $timeName
			Wave timeW = $timeName
			timeW = (p + 1) * fr
		endif
		
		sampleColorIdx = mod(i, 8)
		
		if(graphCreated == 0)
			Display/K=1/N=$graphName avgW vs timeW
			graphCreated = 1
		else
			AppendToGraph avgW vs timeW
		endif
		
		r = sampleColors[sampleColorIdx][0]
		g = sampleColors[sampleColorIdx][1]
		b = sampleColors[sampleColorIdx][2]
		ModifyGraph rgb($avgName)=(r, g, b)
		ModifyGraph mode($avgName)=3, marker($avgName)=19, msize($avgName)=2
		
		if(WaveExists(semW))
			ErrorBars $avgName SHADE= {0,4,(r,g,b,32768),(r,g,b,32768)},wave=(semW, semW)
		endif
		
		// SetScale
		fitName = sampleName + "_fit_PDur_C2E"
		if(FitAverageOntime(avgW, timeW, fitName) == 0)
			Wave/Z fitW = $fitName
			if(WaveExists(fitW))
				AppendToGraph fitW
				ModifyGraph rgb($fitName)=(r, g, b)
				ModifyGraph mode($fitName)=0, lsize($fitName)=1.5
			endif
		endif
	endfor
	
	if(graphCreated == 1)
		ModifyGraph tick=0, mirror=0, fStyle=1, fSize=14, font="Arial"
		ModifyGraph width={Aspect, 1.618}
		ModifyGraph log(left)=1
		Label left "Survival Probability [%]"
		Label bottom "Time [s]"
		SetAxis left 0.1, 100
		DoWindow/T $graphName, "On-time Distribution (List B - Ch2)"
		
		legendStr = "\\F'Arial'\\Z10"
		for(i = 0; i < numPairs; i += 1)
			sampleName = List_C2[i]
			avgName = sampleName + "_PDur_C2E_avg"
			Wave/Z checkW = $avgName
			if(WaveExists(checkW))
				if(i > 0)
					legendStr += "\r"
				endif
				legendStr += "\\s(" + avgName + ") " + sampleName
			endif
		endfor
		TextBox/C/N=text0/F=0/B=1/A=RT legendStr
	endif
	
	NVAR ColIndex = root:ColIndex
	Printf "On-time averages saved to EC%d:Comparison\r", ColIndex
	
	SetDataFolder $savedDF
	return 0
End

// Average On-rate (Cumulative On-events)
// 1. SampleOn-rateState
// 2. S0,S1,S2...List A/BOn-rate
Function ColAvgOnrateFromList()
	String savedDF = GetDataFolder(1)
	
	// 
	String ecBasePath = GetECBasePath()
	String ecCompPath = ecBasePath + ":Comparison"
	
	Wave/T/Z List_C1 = root:List_C1
	Wave/T/Z List_C2 = root:List_C2
	
	if(!WaveExists(List_C1) || !WaveExists(List_C2))
		DoAlert 0, "Please create List_C1 and List_C2 first"
		return -1
	endif
	
	NVAR/Z Dstate = root:Dstate
	NVAR/Z cHMM = root:cHMM
	
	Variable maxState = 0
	if(NVAR_Exists(cHMM) && cHMM == 1 && NVAR_Exists(Dstate))
		maxState = Dstate
	endif
	
	Variable numPairs = min(numpnts(List_C1), numpnts(List_C2))
	Variable i, s, r, g, b
	
	Print "=== Average On-rate ==="
	Printf "  maxState = %d\r", maxState
	
	// Create Comparison folder
	if(!DataFolderExists(ecCompPath))
		NewDataFolder $ecCompPath
	endif
	
	String sampleName
	
	// ===== Collect data to Comparison folder =====
	// Process List_C1 (Ch1) - waveSuffix="_C1E"
	for(i = 0; i < numPairs; i += 1)
		sampleName = List_C1[i]
		String resultsPath = ecBasePath + ":" + sampleName + ":Results"
		
		if(!DataFolderExists(resultsPath))
			Printf "  Results NOT found: %s\r", resultsPath
			continue
		endif
		
		SetDataFolder $resultsPath
		Printf "  Checking %s (Ch1)...\r", sampleName
		
		for(s = 0; s <= maxState; s += 1)
			// : CumOnEvent_S0_C1E_m_avg
			String srcAvgName = "CumOnEvent_S" + num2str(s) + "_C1E_m_avg"
			String srcSemName = "CumOnEvent_S" + num2str(s) + "_C1E_m_sem"
			String srcTimeName = "time_onrate_S" + num2str(s) + "_C1E_m_avg"
			
			Wave/Z srcAvg = $srcAvgName
			Wave/Z srcSem = $srcSemName
			Wave/Z srcTime = $srcTimeName
			
			if(WaveExists(srcAvg))
				String dstAvgName = sampleName + "_CumOn_S" + num2str(s) + "_C1E_avg"
				String dstSemName = sampleName + "_CumOn_S" + num2str(s) + "_C1E_sem"
				String dstTimeName = sampleName + "_TimeOn_S" + num2str(s) + "_C1E"
				
				Duplicate/O srcAvg, $(ecCompPath + ":" + dstAvgName)
				if(WaveExists(srcSem))
					Duplicate/O srcSem, $(ecCompPath + ":" + dstSemName)
				endif
				if(WaveExists(srcTime))
					Duplicate/O srcTime, $(ecCompPath + ":" + dstTimeName)
				endif
				Printf "    S%d: CumOnEvent_C1E found\r", s
			else
				Printf "    S%d: %s NOT found\r", s, srcAvgName
			endif
		endfor
	endfor
	
	// Process List_C2 (Ch2) - waveSuffix="_C2E"
	for(i = 0; i < numPairs; i += 1)
		sampleName = List_C2[i]
		resultsPath = ecBasePath + ":" + sampleName + ":Results"
		
		if(!DataFolderExists(resultsPath))
			Printf "  Results NOT found: %s\r", resultsPath
			continue
		endif
		
		SetDataFolder $resultsPath
		Printf "  Checking %s (Ch2)...\r", sampleName
		
		for(s = 0; s <= maxState; s += 1)
			srcAvgName = "CumOnEvent_S" + num2str(s) + "_C2E_m_avg"
			srcSemName = "CumOnEvent_S" + num2str(s) + "_C2E_m_sem"
			srcTimeName = "time_onrate_S" + num2str(s) + "_C2E_m_avg"
			
			Wave/Z srcAvg = $srcAvgName
			Wave/Z srcSem = $srcSemName
			Wave/Z srcTime = $srcTimeName
			
			if(WaveExists(srcAvg))
				dstAvgName = sampleName + "_CumOn_S" + num2str(s) + "_C2E_avg"
				dstSemName = sampleName + "_CumOn_S" + num2str(s) + "_C2E_sem"
				dstTimeName = sampleName + "_TimeOn_S" + num2str(s) + "_C2E"
				
				Duplicate/O srcAvg, $(ecCompPath + ":" + dstAvgName)
				if(WaveExists(srcSem))
					Duplicate/O srcSem, $(ecCompPath + ":" + dstSemName)
				endif
				if(WaveExists(srcTime))
					Duplicate/O srcTime, $(ecCompPath + ":" + dstTimeName)
				endif
				Printf "    S%d: CumOnEvent_C2E found\r", s
			else
				Printf "    S%d: %s NOT found\r", s, srcAvgName
			endif
		endfor
	endfor
	
	SetDataFolder $ecCompPath
	
	// ===== Create individual sample graphs (all states per sample) =====
	// List_C1 samples (Ch1)
	for(i = 0; i < numPairs; i += 1)
		sampleName = List_C1[i]
		
		String graphName = "AvgOnrate_" + sampleName + "_C1E"
		DoWindow/K $graphName
		
		String s0AvgName = sampleName + "_CumOn_S0_C1E_avg"
		String s0TimeName = sampleName + "_TimeOn_S0_C1E"
		Wave/Z s0Avg = $s0AvgName
		Wave/Z s0Time = $s0TimeName
		
		if(!WaveExists(s0Avg))
			continue
		endif
		
		// Create time wave if not exists
		if(!WaveExists(s0Time))
			NVAR framerate = root:framerate
			Variable fr = framerate
			Make/O/N=(numpnts(s0Avg)) $s0TimeName
			Wave s0Time = $s0TimeName
			s0Time = (p + 1) * fr
		endif
		
		Display/K=1/N=$graphName s0Avg vs s0Time
		GetDstateColor(0, r, g, b)
		// : Batch
		ModifyGraph mode($s0AvgName)=3, marker($s0AvgName)=19, msize($s0AvgName)=1
		ModifyGraph rgb($s0AvgName)=(r, g, b)
		
		// S0
		String fitName = sampleName + "_fit_CumOn_S0_C1E"
		if(FitAverageOnrateCol(s0Avg, s0Time, fitName) == 0)
			Wave/Z fitW = $fitName
			if(WaveExists(fitW))
				AppendToGraph fitW
				ModifyGraph rgb($fitName)=(r, g, b)
				// : Batch
				ModifyGraph lsize($fitName)=1.5
			endif
		endif
		
		for(s = 1; s <= maxState; s += 1)
			String avgName = sampleName + "_CumOn_S" + num2str(s) + "_C1E_avg"
			String timeName = sampleName + "_TimeOn_S" + num2str(s) + "_C1E"
			Wave/Z avgW = $avgName
			Wave/Z timeW = $timeName
			
			if(WaveExists(avgW))
				if(!WaveExists(timeW))
					Make/O/N=(numpnts(avgW)) $timeName
					Wave timeW = $timeName
					timeW = (p + 1) * fr
				endif
				AppendToGraph avgW vs timeW
				GetDstateColor(s, r, g, b)
				// : Batch
				ModifyGraph mode($avgName)=3, marker($avgName)=19, msize($avgName)=1
				ModifyGraph rgb($avgName)=(r, g, b)
				
				// 
				fitName = sampleName + "_fit_CumOn_S" + num2str(s) + "_C1E"
				if(FitAverageOnrateCol(avgW, timeW, fitName) == 0)
					Wave/Z fitW = $fitName
					if(WaveExists(fitW))
						AppendToGraph fitW
						ModifyGraph rgb($fitName)=(r, g, b)
						// : Batch
						ModifyGraph lsize($fitName)=1.5
					endif
				endif
			endif
		endfor
		
		ModifyGraph tick=0, mirror=0, fStyle=1, fSize=14, font="Arial"
		SetAxis left 0, *
		SetAxis bottom 0, *
		Label left "Cum. On events"
		Label bottom "Time [s]"
		ModifyGraph width={Aspect,1.618}
		DoWindow/T $graphName, "Average On-rate - " + sampleName + " (Ch1)"
	endfor
	
	// List_C2 samples (Ch2)
	for(i = 0; i < numPairs; i += 1)
		sampleName = List_C2[i]
		
		graphName = "AvgOnrate_" + sampleName + "_C2E"
		DoWindow/K $graphName
		
		s0AvgName = sampleName + "_CumOn_S0_C2E_avg"
		s0TimeName = sampleName + "_TimeOn_S0_C2E"
		Wave/Z s0Avg = $s0AvgName
		Wave/Z s0Time = $s0TimeName
		
		if(!WaveExists(s0Avg))
			continue
		endif
		
		if(!WaveExists(s0Time))
			NVAR framerate = root:framerate
			fr = framerate
			Make/O/N=(numpnts(s0Avg)) $s0TimeName
			Wave s0Time = $s0TimeName
			s0Time = (p + 1) * fr
		endif
		
		Display/K=1/N=$graphName s0Avg vs s0Time
		GetDstateColor(0, r, g, b)
		// : Batch
		ModifyGraph mode($s0AvgName)=3, marker($s0AvgName)=19, msize($s0AvgName)=1
		ModifyGraph rgb($s0AvgName)=(r, g, b)
		
		// S0
		fitName = sampleName + "_fit_CumOn_S0_C2E"
		if(FitAverageOnrateCol(s0Avg, s0Time, fitName) == 0)
			Wave/Z fitW = $fitName
			if(WaveExists(fitW))
				AppendToGraph fitW
				ModifyGraph rgb($fitName)=(r, g, b)
				// : Batch
				ModifyGraph lsize($fitName)=1.5
			endif
		endif
		
		for(s = 1; s <= maxState; s += 1)
			avgName = sampleName + "_CumOn_S" + num2str(s) + "_C2E_avg"
			timeName = sampleName + "_TimeOn_S" + num2str(s) + "_C2E"
			Wave/Z avgW = $avgName
			Wave/Z timeW = $timeName
			
			if(WaveExists(avgW))
				if(!WaveExists(timeW))
					Make/O/N=(numpnts(avgW)) $timeName
					Wave timeW = $timeName
					timeW = (p + 1) * fr
				endif
				AppendToGraph avgW vs timeW
				GetDstateColor(s, r, g, b)
				// : Batch
				ModifyGraph mode($avgName)=3, marker($avgName)=19, msize($avgName)=1
				ModifyGraph rgb($avgName)=(r, g, b)
				
				// 
				fitName = sampleName + "_fit_CumOn_S" + num2str(s) + "_C2E"
				if(FitAverageOnrateCol(avgW, timeW, fitName) == 0)
					Wave/Z fitW = $fitName
					if(WaveExists(fitW))
						AppendToGraph fitW
						ModifyGraph rgb($fitName)=(r, g, b)
						// : Batch
						ModifyGraph lsize($fitName)=1.5
					endif
				endif
			endif
		endfor
		
		ModifyGraph tick=0, mirror=0, fStyle=1, fSize=14, font="Arial"
		SetAxis left 0, *
		SetAxis bottom 0, *
		Label left "Cum. On events"
		Label bottom "Time [s]"
		ModifyGraph width={Aspect,1.618}
		DoWindow/T $graphName, "Average On-rate - " + sampleName + " (Ch2)"
	endfor
	
	// ===== Create comparison graphs (S0, S1, S2... with all samples) =====
	for(s = 0; s <= maxState; s += 1)
		// List A (Ch1) comparison graph
		graphName = "AvgOnrate_S" + num2str(s) + "_ListA"
		DoWindow/K $graphName
		
		Variable graphCreated = 0
		Variable numValidSamples = 0
		
		for(i = 0; i < numPairs; i += 1)
			sampleName = List_C1[i]
			String testAvgName = sampleName + "_CumOn_S" + num2str(s) + "_C1E_avg"
			Wave/Z testW = $testAvgName
			if(WaveExists(testW))
				numValidSamples += 1
			endif
		endfor
		
		Variable validIdx = 0
		for(i = 0; i < numPairs; i += 1)
			sampleName = List_C1[i]
			avgName = sampleName + "_CumOn_S" + num2str(s) + "_C1E_avg"
			timeName = sampleName + "_TimeOn_S" + num2str(s) + "_C1E"
			String semName = sampleName + "_CumOn_S" + num2str(s) + "_C1E_sem"

			Wave/Z avgW = $avgName
			Wave/Z timeW = $timeName
			Wave/Z semW = $semName

			if(!WaveExists(avgW))
				continue
			endif

			if(!WaveExists(timeW))
				NVAR framerate = root:framerate
				fr = framerate
				Make/O/N=(numpnts(avgW)) $timeName
				Wave timeW = $timeName
				timeW = (p + 1) * fr
			endif
			
			if(graphCreated == 0)
				Display/K=1/N=$graphName avgW vs timeW
				graphCreated = 1
			else
				AppendToGraph avgW vs timeW
			endif
			
			GetStateColorWithShade(s, validIdx, numValidSamples, r, g, b)
			// : Batch
			ModifyGraph mode($avgName)=3, marker($avgName)=19, msize($avgName)=1
			ModifyGraph rgb($avgName)=(r, g, b)
			
			// 
			fitName = sampleName + "_fit_CumOn_S" + num2str(s) + "_C1E"
			if(FitAverageOnrateCol(avgW, timeW, fitName) == 0)
				Wave/Z fitW = $fitName
				if(WaveExists(fitW))
					AppendToGraph fitW
					ModifyGraph rgb($fitName)=(r, g, b)
					ModifyGraph lsize($fitName)=1.5
				endif
			endif
			
			if(WaveExists(semW))
				ErrorBars $avgName SHADE= {0,4,(r,g,b,32768),(r,g,b,32768)},wave=(semW, semW)
			endif
			validIdx += 1
		endfor
		
		if(graphCreated == 1)
			ModifyGraph tick=0, mirror=0, fStyle=1, fSize=14, font="Arial"
			SetAxis left 0, *
			SetAxis bottom 0, *
			Label left "Cum. On events"
			Label bottom "Time [s]"
			ModifyGraph width={Aspect,1.618}
			DoWindow/T $graphName, "On-rate S" + num2str(s) + " Comparison (List A - Ch1)"
			
			String legendStr = "\\F'Arial'\\Z10"
			for(i = 0; i < numPairs; i += 1)
				sampleName = List_C1[i]
				avgName = sampleName + "_CumOn_S" + num2str(s) + "_C1E_avg"
				Wave/Z checkW = $avgName
				if(WaveExists(checkW))
					if(i > 0)
						legendStr += "\r"
					endif
					legendStr += "\\s(" + avgName + ") " + sampleName
				endif
			endfor
			TextBox/C/N=text0/F=0/B=1/A=RT legendStr
		endif
		
		// List B (Ch2) comparison graph
		graphName = "AvgOnrate_S" + num2str(s) + "_ListB"
		DoWindow/K $graphName
		
		graphCreated = 0
		numValidSamples = 0
		
		for(i = 0; i < numPairs; i += 1)
			sampleName = List_C2[i]
			testAvgName = sampleName + "_CumOn_S" + num2str(s) + "_C2E_avg"
			Wave/Z testW = $testAvgName
			if(WaveExists(testW))
				numValidSamples += 1
			endif
		endfor
		
		validIdx = 0
		for(i = 0; i < numPairs; i += 1)
			sampleName = List_C2[i]
			avgName = sampleName + "_CumOn_S" + num2str(s) + "_C2E_avg"
			timeName = sampleName + "_TimeOn_S" + num2str(s) + "_C2E"
			semName = sampleName + "_CumOn_S" + num2str(s) + "_C2E_sem"

			Wave/Z avgW = $avgName
			Wave/Z timeW = $timeName
			Wave/Z semW = $semName

			if(!WaveExists(avgW))
				continue
			endif

			if(!WaveExists(timeW))
				NVAR framerate = root:framerate
				fr = framerate
				Make/O/N=(numpnts(avgW)) $timeName
				Wave timeW = $timeName
				timeW = (p + 1) * fr
			endif
			
			if(graphCreated == 0)
				Display/K=1/N=$graphName avgW vs timeW
				graphCreated = 1
			else
				AppendToGraph avgW vs timeW
			endif
			
			GetStateColorWithShade(s, validIdx, numValidSamples, r, g, b)
			// : Batch
			ModifyGraph mode($avgName)=3, marker($avgName)=19, msize($avgName)=1
			ModifyGraph rgb($avgName)=(r, g, b)
			
			// 
			fitName = sampleName + "_fit_CumOn_S" + num2str(s) + "_C2E"
			if(FitAverageOnrateCol(avgW, timeW, fitName) == 0)
				Wave/Z fitW = $fitName
				if(WaveExists(fitW))
					AppendToGraph fitW
					ModifyGraph rgb($fitName)=(r, g, b)
					ModifyGraph lsize($fitName)=1.5
				endif
			endif
			
			if(WaveExists(semW))
				ErrorBars $avgName SHADE= {0,4,(r,g,b,32768),(r,g,b,32768)},wave=(semW, semW)
			endif
			validIdx += 1
		endfor
		
		if(graphCreated == 1)
			ModifyGraph tick=0, mirror=0, fStyle=1, fSize=14, font="Arial"
			SetAxis left 0, *
			SetAxis bottom 0, *
			Label left "Cum. On events"
			Label bottom "Time [s]"
			ModifyGraph width={Aspect,1.618}
			DoWindow/T $graphName, "On-rate S" + num2str(s) + " Comparison (List B - Ch2)"
			
			legendStr = "\\F'Arial'\\Z10"
			for(i = 0; i < numPairs; i += 1)
				sampleName = List_C2[i]
				avgName = sampleName + "_CumOn_S" + num2str(s) + "_C2E_avg"
				Wave/Z checkW = $avgName
				if(WaveExists(checkW))
					if(i > 0)
						legendStr += "\r"
					endif
					legendStr += "\\s(" + avgName + ") " + sampleName
				endif
			endfor
			TextBox/C/N=text0/F=0/B=1/A=RT legendStr
		endif
	endfor
	
	NVAR ColIndex = root:ColIndex
	Printf "On-rate averages saved to EC%d:Comparison\r", ColIndex
	
	SetDataFolder $savedDF
	return 0
End

// =============================================================================
// VerifyECFolderConsistency - EC
// =============================================================================
// EC
// 1. WaveRowS0Sn
// 2. S0 = ΣSn NaN
// 
// : VerifyECFolderConsistency("SampleName") 
//           VerifyECFolderConsistency("") 
// =============================================================================
Function VerifyECFolderConsistency(targetSample)
	String targetSample  // 
	
	String savedDF = GetDataFolder(1)
	
	// 
	String ecBasePath = GetECBasePath()
	
	if(!DataFolderExists(ecBasePath))
		Printf "Error: %s folder does not exist\r", ecBasePath
		return -1
	endif
	
	NVAR Dstate = root:Dstate
	Variable maxState = Dstate

	Print "=============================================="
	Print "EC Folder Consistency Verification"
	Print "=============================================="
	Printf "Max Dstate: %d\r", maxState
	
	Variable totalErrors = 0
	Variable totalCells = 0
	
	// 
	SetDataFolder $ecBasePath
	Variable numSamples = CountObjects("", 4)
	Variable sampleIdx, cellIdx
	
	for(sampleIdx = 0; sampleIdx < numSamples; sampleIdx += 1)
		String sampleName = GetIndexedObjName("", 4, sampleIdx)
		
		// 
		if(strlen(sampleName) == 0)
			continue
		endif
		
		// 
		if(strlen(targetSample) > 0 && !StringMatch(sampleName, targetSample))
			continue
		endif
		
		// 
		if(StringMatch(sampleName, "Comparison") || StringMatch(sampleName, "Matrix") || StringMatch(sampleName, "Results"))
			continue
		endif
		
		String samplePath = ecBasePath + ":" + sampleName
		if(!DataFolderExists(samplePath))
			continue
		endif
		
		Print "----------------------------------------------"
		Printf "Sample: %s\r", sampleName
		
		SetDataFolder $samplePath
		Variable numCells = CountObjects("", 4)
		
		for(cellIdx = 0; cellIdx < numCells; cellIdx += 1)
			String cellName = GetIndexedObjName("", 4, cellIdx)
			
			// 
			if(strlen(cellName) == 0)
				continue
			endif
			
			// Matrix/Results
			if(StringMatch(cellName, "Matrix") || StringMatch(cellName, "Results"))
				continue
			endif
			
			String cellPath = samplePath + ":" + cellName
			if(!DataFolderExists(cellPath))
				continue
			endif
			
			SetDataFolder $cellPath
			totalCells += 1
			
			// _C1E, _C2E- $
			String suffix = ""
			Wave/Z testROI = $"ROI_S0_C1E"
			if(WaveExists(testROI))
				suffix = "_C1E"
			else
				Wave/Z testROI2 = $"ROI_S0_C2E"
				if(WaveExists(testROI2))
					suffix = "_C2E"
				endif
			endif
			
			if(strlen(suffix) == 0)
				// : wave
				Variable numWavesInCell = CountObjects("", 1)
				String firstWaves = ""
				Variable wIdx
				for(wIdx = 0; wIdx < min(numWavesInCell, 5); wIdx += 1)
					firstWaves += GetIndexedObjName("", 1, wIdx) + "; "
				endfor
				Printf "  %s: No ROI_S0_C1E/C2E found. Waves: %s\r", cellName, firstWaves
				continue
			endif
			
			// === 1: Row ===
			Variable s0Rows = 0
			Wave/Z ROI_S0 = $("ROI_S0" + suffix)
			if(WaveExists(ROI_S0))
				s0Rows = numpnts(ROI_S0)
			endif
			
			Variable rowMismatch = 0
			Variable ss
			for(ss = 1; ss <= maxState; ss += 1)
				Wave/Z ROI_Sn = $("ROI_S" + num2str(ss) + suffix)
				if(WaveExists(ROI_Sn))
					if(numpnts(ROI_Sn) != s0Rows)
						Printf "  %s: ROI_S%d rows=%d != S0 rows=%d\r", cellName, ss, numpnts(ROI_Sn), s0Rows
						rowMismatch = 1
						totalErrors += 1
					endif
				endif
			endfor
			
			// === 2: Wave ===
			Printf "  %s (suffix=%s, rows=%d):\r", cellName, suffix, s0Rows
			
			// Wave
			String checkWaveTypes = "ROI;Int;Rtime"
			Variable wt, ii
			Variable hasError = 0
			
			for(wt = 0; wt < ItemsInList(checkWaveTypes); wt += 1)
				String waveType = StringFromList(wt, checkWaveTypes)
				
				// State
				Make/FREE/N=(maxState + 1) validCounts = 0
				
				for(ss = 0; ss <= maxState; ss += 1)
					String waveName = waveType + "_S" + num2str(ss) + suffix
					Wave/Z wRef = $waveName
					if(WaveExists(wRef))
						Variable validCount = 0
						for(ii = 0; ii < numpnts(wRef); ii += 1)
							if(numtype(wRef[ii]) == 0)  // NaN
								validCount += 1
							endif
						endfor
						validCounts[ss] = validCount
					endif
				endfor
				
				// S0 = ΣSn 
				Variable s0Count = validCounts[0]
				Variable sumSnCount = 0
				for(ss = 1; ss <= maxState; ss += 1)
					sumSnCount += validCounts[ss]
				endfor
				
				// 
				String stateStr = ""
				for(ss = 0; ss <= maxState; ss += 1)
					stateStr += "S" + num2str(ss) + "=" + num2str(validCounts[ss])
					if(ss < maxState)
						stateStr += ", "
					endif
				endfor
				
				String checkResult = ""
				if(s0Count == sumSnCount)
					checkResult = "OK"
				else
					checkResult = "ERROR (S0≠ΣSn, diff=" + num2str(s0Count - sumSnCount) + ")"
					hasError = 1
					totalErrors += 1
				endif
				
				Printf "    %s: %s [%s]\r", waveType, stateStr, checkResult
			endfor
			
			// === 3: Distance StateEC ===
			// DistanceState
			Make/FREE/N=(maxState + 1) distValidCounts = 0
			
			for(ss = 0; ss <= maxState; ss += 1)
				String distName = "Distance_S" + num2str(ss) + suffix
				Wave/Z distRef = $distName
				if(WaveExists(distRef))
					Variable distValidCount = 0
					for(ii = 0; ii < numpnts(distRef); ii += 1)
						if(numtype(distRef[ii]) == 0)  // NaN
							distValidCount += 1
						endif
					endfor
					distValidCounts[ss] = distValidCount
				endif
			endfor
			
			// S0 = ΣSn 
			Variable distS0Count = distValidCounts[0]
			Variable distSumSnCount = 0
			for(ss = 1; ss <= maxState; ss += 1)
				distSumSnCount += distValidCounts[ss]
			endfor
			
			// 
			String distStateStr = ""
			for(ss = 0; ss <= maxState; ss += 1)
				distStateStr += "S" + num2str(ss) + "=" + num2str(distValidCounts[ss])
				if(ss < maxState)
					distStateStr += ", "
				endif
			endfor
			
			String distCheckResult = ""
			if(distS0Count == distSumSnCount)
				distCheckResult = "OK"
			else
				distCheckResult = "ERROR (S0≠ΣSn, diff=" + num2str(distS0Count - distSumSnCount) + ")"
				totalErrors += 1
			endif
			
			Printf "    Distance: %s [%s]\r", distStateStr, distCheckResult
			
			// === 4: Colocalize row ===
			Wave/Z Colocalize = $("Colocalize" + suffix)
			if(WaveExists(Colocalize) && numpnts(Colocalize) != s0Rows)
				Printf "    Colocalize rows=%d != S0 rows=%d\r", numpnts(Colocalize), s0Rows
				totalErrors += 1
			endif
		endfor
	endfor
	
	Print "=============================================="
	Printf "Total cells checked: %d\r", totalCells
	Printf "Total errors found: %d\r", totalErrors
	
	if(totalErrors == 0)
		Print "✓ All consistency checks PASSED"
	else
		Print "✗ Consistency check FAILED - see errors above"
	endif
	Print "=============================================="
	
	SetDataFolder $savedDF
	return totalErrors
End

// =============================================================================
// VerifyColFolderConsistency - Col
// =============================================================================
Function VerifyColFolderConsistency(targetSample)
	String targetSample
	
	String savedDF = GetDataFolder(1)
	
	// 
	String colBasePath = GetColBasePath()
	
	if(!DataFolderExists(colBasePath))
		Printf "Error: %s folder does not exist\r", colBasePath
		return -1
	endif
	
	NVAR Dstate = root:Dstate
	Variable maxState = Dstate

	Print "=============================================="
	Print "Col Folder Consistency Verification"
	Print "=============================================="
	Printf "Max Dstate: %d\r", maxState
	
	Variable totalErrors = 0
	Variable totalCells = 0
	
	SetDataFolder $colBasePath
	Variable numSamples = CountObjects("", 4)
	Variable sampleIdx, cellIdx
	
	for(sampleIdx = 0; sampleIdx < numSamples; sampleIdx += 1)
		String sampleName = GetIndexedObjName("", 4, sampleIdx)
		
		// 
		if(strlen(sampleName) == 0)
			continue
		endif
		
		if(strlen(targetSample) > 0 && !StringMatch(sampleName, targetSample))
			continue
		endif
		
		if(StringMatch(sampleName, "Comparison") || StringMatch(sampleName, "Matrix") || StringMatch(sampleName, "Results"))
			continue
		endif
		
		String samplePath = colBasePath + ":" + sampleName
		if(!DataFolderExists(samplePath))
			continue
		endif
		
		Print "----------------------------------------------"
		Printf "Sample: %s\r", sampleName
		
		SetDataFolder $samplePath
		Variable numCells = CountObjects("", 4)
		
		for(cellIdx = 0; cellIdx < numCells; cellIdx += 1)
			String cellName = GetIndexedObjName("", 4, cellIdx)
			
			// 
			if(strlen(cellName) == 0)
				continue
			endif
			
			if(StringMatch(cellName, "Matrix") || StringMatch(cellName, "Results"))
				continue
			endif
			
			String cellPath = samplePath + ":" + cellName
			if(!DataFolderExists(cellPath))
				continue
			endif
			
			SetDataFolder $cellPath
			totalCells += 1
			
			//  - $
			String suffix = ""
			Wave/Z testROI = $"ROI_S0_C1"
			if(WaveExists(testROI))
				suffix = "_C1"
			else
				Wave/Z testROI2 = $"ROI_S0_C2"
				if(WaveExists(testROI2))
					suffix = "_C2"
				endif
			endif
			
			if(strlen(suffix) == 0)
				Printf "  %s: No ROI_S0 found, skipping\r", cellName
				continue
			endif
			
			// Row
			Variable s0Rows = 0
			Wave/Z ROI_S0 = $("ROI_S0" + suffix)
			if(WaveExists(ROI_S0))
				s0Rows = numpnts(ROI_S0)
			endif
			
			Variable rowMismatch = 0
			Variable ss
			for(ss = 1; ss <= maxState; ss += 1)
				Wave/Z ROI_Sn = $("ROI_S" + num2str(ss) + suffix)
				if(WaveExists(ROI_Sn))
					if(numpnts(ROI_Sn) != s0Rows)
						Printf "  %s: ROI_S%d rows=%d != S0 rows=%d\r", cellName, ss, numpnts(ROI_Sn), s0Rows
						rowMismatch = 1
						totalErrors += 1
					endif
				endif
			endfor
			
			// === Wave ===
			Printf "  %s (suffix=%s, rows=%d):\r", cellName, suffix, s0Rows
			
			// Wave
			String checkWaveTypes = "ROI;Int;Rtime"
			Variable wt, ii
			Variable hasError = 0
			
			for(wt = 0; wt < ItemsInList(checkWaveTypes); wt += 1)
				String waveType = StringFromList(wt, checkWaveTypes)
				
				// State
				Make/FREE/N=(maxState + 1) validCounts = 0
				
				for(ss = 0; ss <= maxState; ss += 1)
					String waveName = waveType + "_S" + num2str(ss) + suffix
					Wave/Z wRef = $waveName
					if(WaveExists(wRef))
						Variable validCount = 0
						for(ii = 0; ii < numpnts(wRef); ii += 1)
							if(numtype(wRef[ii]) == 0)  // NaN
								validCount += 1
							endif
						endfor
						validCounts[ss] = validCount
					endif
				endfor
				
				// S0 = ΣSn 
				Variable s0Count = validCounts[0]
				Variable sumSnCount = 0
				for(ss = 1; ss <= maxState; ss += 1)
					sumSnCount += validCounts[ss]
				endfor
				
				// 
				String stateStr = ""
				for(ss = 0; ss <= maxState; ss += 1)
					stateStr += "S" + num2str(ss) + "=" + num2str(validCounts[ss])
					if(ss < maxState)
						stateStr += ", "
					endif
				endfor
				
				String checkResult = ""
				if(s0Count == sumSnCount)
					checkResult = "OK"
				else
					checkResult = "ERROR (S0≠ΣSn, diff=" + num2str(s0Count - sumSnCount) + ")"
					hasError = 1
					totalErrors += 1
				endif
				
				Printf "    %s: %s [%s]\r", waveType, stateStr, checkResult
			endfor
		endfor
	endfor
	
	Print "=============================================="
	Printf "Total cells checked: %d\r", totalCells
	Printf "Total errors found: %d\r", totalErrors
	
	if(totalErrors == 0)
		Print "✓ All consistency checks PASSED"
	else
		Print "✗ Consistency check FAILED - see errors above"
	endif
	Print "=============================================="
	
	SetDataFolder $savedDF
	return totalErrors
End


// =============================================================================
// Compare Functions - Colocalization 
// =============================================================================
// AutoAnalysisCompare
// : root:EC:SampleName:Matrix, root:EC:SampleName:Results
// : root:Comparison
// =============================================================================

// -----------------------------------------------------------------------------
// ColCompareIntensity - Mean Oligomer Size 
// : SMI_Comparison.ipf::CompareIntensity()
// -----------------------------------------------------------------------------
Function ColCompareIntensity()
	String savedDF = GetDataFolder(1)
	String basePath = GetECBasePath() + ":"
	
	NVAR gDstate = root:Dstate
	Variable Dstate = gDstate

	Print "=== Compare Colocalization Intensity (Mean Oligomer Size) ==="
	
	String channelList = GetOutputChannelList(1)
	Variable chIdx, stt
	String chSuffix, chLabel, stateName, sampleList
	String matrixName, outputPrefix, winName, yLabel, graphTitle
	
	for(chIdx = 0; chIdx < ItemsInList(channelList); chIdx += 1)
		chSuffix = StringFromList(chIdx, channelList)
		chLabel = GetChannelLabel(chSuffix)
		// 
		sampleList = GetSampleListForChannel(GetChannelIndex(chSuffix))
		
		for(stt = 0; stt <= Dstate; stt += 1)
			stateName = GetDstateName(stt, Dstate)
			matrixName = "mean_osize_S" + num2str(stt) + chSuffix + "_m"
			outputPrefix = "ColInt_S" + num2str(stt) + chSuffix
			winName = "ColCmp_Int_S" + num2str(stt) + chSuffix
			yLabel = "\\F'Arial'\\Z14Mean Oligomer Size\\B" + stateName + "\\M"
			graphTitle = "Col Compare Intensity " + chLabel + " (S" + num2str(stt) + ": " + stateName + ")"
			
			// rowIndex=-1: 1D wavesampleList
			CreateComparisonSummaryPlotEx(basePath, matrixName, -1, outputPrefix, winName, yLabel, graphTitle, 1, stt, sampleList)
			
			Print "  Compare Intensity " + chLabel + " S" + num2str(stt) + " completed"
		endfor
	endfor
	
	SetDataFolder $savedDF
	return 0
End

// -----------------------------------------------------------------------------
// ColCompareDiffusion - D-state Population (HMMP) 
// -----------------------------------------------------------------------------
Function ColCompareDiffusion()
	String savedDF = GetDataFolder(1)
	String basePath = GetECBasePath() + ":"
	
	NVAR gDstate = root:Dstate
	Variable Dstate = gDstate

	Print "=== Compare Colocalization Diffusion (D-state Population) ==="
	
	String channelList = GetOutputChannelList(1)
	Variable chIdx, stt
	String chSuffix, chLabel, stateName, sampleList
	String matrixName, outputPrefix, winName, yLabel, graphTitle
	
	for(chIdx = 0; chIdx < ItemsInList(channelList); chIdx += 1)
		chSuffix = StringFromList(chIdx, channelList)
		chLabel = GetChannelLabel(chSuffix)
		matrixName = "HMMP" + chSuffix + "_m"
		sampleList = GetSampleListForChannel(GetChannelIndex(chSuffix))
		
		// S1DstateS0
		for(stt = 1; stt <= Dstate; stt += 1)
			stateName = GetDstateName(stt, Dstate)
			outputPrefix = "ColHMMP_S" + num2str(stt) + chSuffix
			winName = "ColCmp_HMMP_S" + num2str(stt) + chSuffix
			yLabel = "\\F'Arial'\\Z14Population\\B" + stateName + "\\M [%]"
			graphTitle = "Col Compare D-state " + chLabel + " (S" + num2str(stt) + ": " + stateName + ")"
			
			// 2D matrix [state][cell] state
			CreateComparisonSummaryPlotEx(basePath, matrixName, stt, outputPrefix, winName, yLabel, graphTitle, 1, stt, sampleList)
			
			Print "  Compare D-state " + chLabel + " S" + num2str(stt) + " completed"
		endfor
	endfor
	
	SetDataFolder $savedDF
	return 0
End

// -----------------------------------------------------------------------------
// ColCompareOntime - On-time (τ, Fraction) 
// -----------------------------------------------------------------------------
Function ColCompareOntime()
	String savedDF = GetDataFolder(1)
	String basePath = GetECBasePath() + ":"
	
	NVAR gExpMax = root:ExpMax_off
	Variable expMax = gExpMax
	
	Print "=== Compare Colocalization On-Time (τ & Fraction) ==="
	
	String channelList = GetOutputChannelList(1)
	Variable chIdx, compIdx
	String chSuffix, chLabel, sampleList
	String matrixName, outputPrefix, winName, yLabel, graphTitle
	
	for(chIdx = 0; chIdx < ItemsInList(channelList); chIdx += 1)
		chSuffix = StringFromList(chIdx, channelList)
		chLabel = GetChannelLabel(chSuffix)
		sampleList = GetSampleListForChannel(GetChannelIndex(chSuffix))
		
		// τ
		matrixName = "Tau_Duration" + chSuffix + "_m"
		for(compIdx = 1; compIdx <= expMax; compIdx += 1)
			outputPrefix = "ColTau_C" + num2str(compIdx) + chSuffix
			winName = "ColCmp_Tau_C" + num2str(compIdx) + chSuffix
			yLabel = "\\F'Arial'\\Z14τ" + num2str(compIdx) + " [s]"
			graphTitle = "Col Compare On-Time τ" + num2str(compIdx) + " " + chLabel
			
			// rowIndex = compIdx-1 (0-indexed)
			CreateComparisonSummaryPlotEx(basePath, matrixName, compIdx-1, outputPrefix, winName, yLabel, graphTitle, 0, 0, sampleList)
			
			Print "  Compare On-Time τ" + num2str(compIdx) + " " + chLabel + " completed"
		endfor
		
		// Fraction
		matrixName = "Fraction_Duration" + chSuffix + "_m"
		for(compIdx = 1; compIdx <= expMax; compIdx += 1)
			outputPrefix = "ColFrac_C" + num2str(compIdx) + chSuffix
			winName = "ColCmp_Frac_C" + num2str(compIdx) + chSuffix
			yLabel = "\\F'Arial'\\Z14Fraction A" + num2str(compIdx)
			graphTitle = "Col Compare Fraction A" + num2str(compIdx) + " " + chLabel
			
			CreateComparisonSummaryPlotEx(basePath, matrixName, compIdx-1, outputPrefix, winName, yLabel, graphTitle, 0, 0, sampleList)
			
			Print "  Compare Fraction A" + num2str(compIdx) + " " + chLabel + " completed"
		endfor
	endfor
	
	SetDataFolder $savedDF
	return 0
End

// -----------------------------------------------------------------------------
// ColCompareOnrate - On-rate 
// -----------------------------------------------------------------------------
Function ColCompareOnrate()
	String savedDF = GetDataFolder(1)
	String basePath = GetECBasePath() + ":"

	NVAR gDstate = root:Dstate
	NVAR ColWeightingMode = root:ColWeightingMode
	Variable Dstate = gDstate
	Variable weighting = ColWeightingMode  // 0=Particle, 1=Molecule

	String weightStr = SelectString(weighting, "Particle", "Molecule")
	Print "=== Compare Colocalization On-event Rate (" + weightStr + ") ==="
	
	String channelList = GetOutputChannelList(1)
	Variable chIdx, stt
	String chSuffix, chLabel, stateName, sampleList
	String matrixName, outputPrefix, winName, yLabel, graphTitle
	
	for(chIdx = 0; chIdx < ItemsInList(channelList); chIdx += 1)
		chSuffix = StringFromList(chIdx, channelList)
		chLabel = GetChannelLabel(chSuffix)
		sampleList = GetSampleListForChannel(GetChannelIndex(chSuffix))
		
		for(stt = 0; stt <= Dstate; stt += 1)
			stateName = GetDstateName(stt, Dstate)
			
			// WeightingMatrix
			if(weighting == 0)
				// Particle
				matrixName = "ParaOnrate_S" + num2str(stt) + chSuffix + "_m"
				yLabel = "\\F'Arial'\\Z14On-event Rate\\B" + stateName + "\\M [/µm\\S2\\M/s]"
			else
				// Molecule
				matrixName = "ParaOnrateMol_S" + num2str(stt) + chSuffix + "_m"
				yLabel = "\\F'Arial'\\Z14Molecular On-event Rate\\B" + stateName + "\\M [mol/µm\\S2\\M/s]"
			endif
			
			outputPrefix = "ColOnRate_S" + num2str(stt) + chSuffix
			winName = "ColCmp_OnRate_S" + num2str(stt) + chSuffix
			graphTitle = "Col Compare On-event Rate (" + weightStr + ") " + chLabel + " (S" + num2str(stt) + ": " + stateName + ")"
			
			// rowIndex=1: OnRate
			CreateComparisonSummaryPlotEx(basePath, matrixName, 1, outputPrefix, winName, yLabel, graphTitle, 1, stt, sampleList)
			
			Print "  Compare On-event Rate " + chLabel + " S" + num2str(stt) + " completed"
		endfor
		
		// State
		String allYLabel, allTitlePrefix
		if(weighting == 0)
			allYLabel = "\\F'Arial'\\Z14On-event Rate [/µm\\S2\\M/s]"
			allTitlePrefix = "Col On-event Rate (Particle)"
			CreateColAllStatesGraph(basePath, "ParaOnrate", chSuffix, allYLabel, allTitlePrefix, 1, rowIndex=1)
		else
			allYLabel = "\\F'Arial'\\Z14Molecular On-event Rate [mol/µm\\S2\\M/s]"
			allTitlePrefix = "Col On-event Rate (Molecule)"
			CreateColAllStatesGraph(basePath, "ParaOnrateMol", chSuffix, allYLabel, allTitlePrefix, 1, rowIndex=1)
		endif
	endfor
	
	SetDataFolder $savedDF
	return 0
End

// -----------------------------------------------------------------------------
// ColCompareOntimeSimple - On-time
// -----------------------------------------------------------------------------
// S0: 
// S1-Sn: 
Function ColCompareOntimeSimple()
	String savedDF = GetDataFolder(1)
	String basePath = GetECBasePath() + ":"

	NVAR gDstate = root:Dstate
	NVAR ColWeightingMode = root:ColWeightingMode
	Variable Dstate = gDstate
	Variable weighting = ColWeightingMode  // 0=Particle, 1=Molecule

	String weightStr = SelectString(weighting, "Particle", "Molecule")
	Print "=== Compare Colocalization On-time (Simple, " + weightStr + ") ==="
	
	String channelList = GetOutputChannelList(1)
	Variable chIdx, stt
	String chSuffix, chLabel, stateName, sampleList
	String matrixName, outputPrefix, winName, yLabel, graphTitle
	
	for(chIdx = 0; chIdx < ItemsInList(channelList); chIdx += 1)
		chSuffix = StringFromList(chIdx, channelList)
		chLabel = GetChannelLabel(chSuffix)
		sampleList = GetSampleListForChannel(GetChannelIndex(chSuffix))
		
		for(stt = 0; stt <= Dstate; stt += 1)
			stateName = GetDstateName(stt, Dstate)
			
			// WeightingMatrix
			if(weighting == 0)
				matrixName = "Ontime_mean_S" + num2str(stt) + chSuffix + "_m"
			else
				matrixName = "OntimeMol_mean_S" + num2str(stt) + chSuffix + "_m"
			endif
			
			outputPrefix = "ColOntime_mean_S" + num2str(stt) + chSuffix
			winName = "ColCmp_OntMean_S" + num2str(stt) + chSuffix
			
			// S0Colocalization DurationS1-SnState Duration
			if(stt == 0)
				yLabel = "\\F'Arial'\\Z14Colocalization Duration [s]"
				graphTitle = "Col Compare Colocalization Duration (" + weightStr + ") " + chLabel
			else
				yLabel = "\\F'Arial'\\Z14State Duration\\B" + stateName + "\\M [s]"
				graphTitle = "Col Compare State Duration (" + weightStr + ") " + chLabel + " (S" + num2str(stt) + ": " + stateName + ")"
			endif
			
			CreateComparisonSummaryPlotEx(basePath, matrixName, -1, outputPrefix, winName, yLabel, graphTitle, 1, stt, sampleList)
			
			if(stt == 0)
				Print "  Compare Colocalization Duration " + chLabel + " completed"
			else
				Print "  Compare State Duration " + chLabel + " S" + num2str(stt) + " completed"
			endif
		endfor
		
		// StateS0S1
		String allYLabel = "\\F'Arial'\\Z14Duration [s]"
		String allTitlePrefix = "Col On-time (" + weightStr + ")"
		if(weighting == 0)
			CreateColAllStatesGraph(basePath, "Ontime_mean", chSuffix, allYLabel, allTitlePrefix, 1)
		else
			CreateColAllStatesGraph(basePath, "OntimeMol_mean", chSuffix, allYLabel, allTitlePrefix, 1)
		endif
	endfor
	
	SetDataFolder $savedDF
	return 0
End

// -----------------------------------------------------------------------------
// ColCompareReactionRate - Reaction rate ([Event rate] / [A][B])
// -----------------------------------------------------------------------------
Function ColCompareReactionRate()
	String savedDF = GetDataFolder(1)
	String basePath = GetECBasePath() + ":"

	NVAR gDstate = root:Dstate
	NVAR ColWeightingMode = root:ColWeightingMode
	Variable Dstate = gDstate
	Variable weighting = ColWeightingMode  // 0=Particle, 1=Molecule

	String weightStr = SelectString(weighting, "Particle", "Molecule")
	Print "=== Compare Colocalization k_on (" + weightStr + ") ==="
	
	String channelList = GetOutputChannelList(1)
	Variable chIdx, stt
	String chSuffix, chLabel, stateName, sampleList
	String matrixName, outputPrefix, winName, yLabel, graphTitle
	
	for(chIdx = 0; chIdx < ItemsInList(channelList); chIdx += 1)
		chSuffix = StringFromList(chIdx, channelList)
		chLabel = GetChannelLabel(chSuffix)
		sampleList = GetSampleListForChannel(GetChannelIndex(chSuffix))
		
		for(stt = 0; stt <= Dstate; stt += 1)
			stateName = GetDstateName(stt, Dstate)
			
			// WeightingMatrix
			if(weighting == 0)
				matrixName = "ReactionRate_S" + num2str(stt) + chSuffix + "_m"
			else
				matrixName = "ReactionRateMol_S" + num2str(stt) + chSuffix + "_m"
			endif
			
			outputPrefix = "ColKon_S" + num2str(stt) + chSuffix
			winName = "ColCmp_Kon_S" + num2str(stt) + chSuffix
			yLabel = "\\F'Arial'\\Z14k\\Bon\\M\\B" + stateName + "\\M [µm\\S2\\M/s]"
			graphTitle = "Col Compare k_on (" + weightStr + ") " + chLabel + " (S" + num2str(stt) + ": " + stateName + ")"
			
			CreateComparisonSummaryPlotEx(basePath, matrixName, -1, outputPrefix, winName, yLabel, graphTitle, 1, stt, sampleList)
			
			Print "  Compare k_on " + chLabel + " S" + num2str(stt) + " completed"
		endfor
		
		// State
		String allYLabel = "\\F'Arial'\\Z14k\\Bon\\M [µm\\S2\\M/s]"
		String allTitlePrefix = "Col k_on (" + weightStr + ")"
		if(weighting == 0)
			CreateColAllStatesGraph(basePath, "ReactionRate", chSuffix, allYLabel, allTitlePrefix, 1)
		else
			CreateColAllStatesGraph(basePath, "ReactionRateMol", chSuffix, allYLabel, allTitlePrefix, 1)
		endif
	endfor
	
	SetDataFolder $savedDF
	return 0
End

// -----------------------------------------------------------------------------
// ColCompareAffinity - 
// -----------------------------------------------------------------------------
Function ColCompareAffinity()
	String savedDF = GetDataFolder(1)
	String basePath = GetECBasePath() + ":"
	
	Print "=== Compare Colocalization Affinity (Distance) ==="
	
	// PercentCKbAbsolute HMMP, KbByState
	String paramNames = "Distance_mean;Distance_SD"
	String paramLabels = "Mean Distance [nm];Distance SD [nm]"
	Variable numParams = 2
	
	String channelList = GetOutputChannelList(0)
	Variable chIdx, pIdx
	String chSuffix, chLabel, paramName, paramLabel, sampleList
	String matrixName, outputPrefix, winName, yLabel, graphTitle
	
	for(chIdx = 0; chIdx < ItemsInList(channelList); chIdx += 1)
		chSuffix = StringFromList(chIdx, channelList)
		chLabel = GetChannelLabel(chSuffix)
		matrixName = "ParaCol" + chSuffix + "_m"
		sampleList = GetSampleListForChannel(GetChannelIndex(chSuffix))
		
		for(pIdx = 0; pIdx < numParams; pIdx += 1)
			paramName = StringFromList(pIdx, paramNames)
			paramLabel = StringFromList(pIdx, paramLabels)
			
			outputPrefix = "ColAff_" + paramName + chSuffix
			winName = "ColCmp_" + paramName + chSuffix
			yLabel = "\\F'Arial'\\Z14" + paramLabel
			graphTitle = "Col Compare " + paramName + " " + chLabel
			
			// rowIndex = pIdx + 1 (ParaCol: 0=PercentC, 1=Distance_mean, 2=Distance_SD, 3=Kb)
			CreateComparisonSummaryPlotEx(basePath, matrixName, pIdx + 1, outputPrefix, winName, yLabel, graphTitle, 0, 0, sampleList)
			
			Print "  Compare " + paramName + " " + chLabel + " completed"
		endfor
	endfor
	
	SetDataFolder $savedDF
	return 0
End

// -----------------------------------------------------------------------------
// ColCompareOsizeCol - Oligomer Size
// -----------------------------------------------------------------------------
Function ColCompareOsizeCol()
	String savedDF = GetDataFolder(1)
	String basePath = GetECBasePath() + ":"

	NVAR gDstate = root:Dstate
	NVAR ColWeightingMode = root:ColWeightingMode
	Variable Dstate = gDstate
	Variable weighting = ColWeightingMode  // 0=Particle, 1=Molecule

	String weightStr = SelectString(weighting, "Particle", "Molecule")
	Print "=== Compare Colocalization Oligomer Size (Simple, " + weightStr + ") ==="
	
	String channelList = GetOutputChannelList(1)
	Variable chIdx, stt
	String chSuffix, chLabel, stateName, sampleList
	String matrixName, outputPrefix, winName, yLabel, graphTitle
	
	for(chIdx = 0; chIdx < ItemsInList(channelList); chIdx += 1)
		chSuffix = StringFromList(chIdx, channelList)
		chLabel = GetChannelLabel(chSuffix)
		sampleList = GetSampleListForChannel(GetChannelIndex(chSuffix))
		
		for(stt = 0; stt <= Dstate; stt += 1)
			stateName = GetDstateName(stt, Dstate)
			
			// WeightingMatrix
			if(weighting == 0)
				// Particle
				matrixName = "OsizeCol_mean_S" + num2str(stt) + chSuffix + "_m"
			else
				// Molecule
				matrixName = "OsizeColMol_mean_S" + num2str(stt) + chSuffix + "_m"
			endif
			
			outputPrefix = "ColOsizeCol_S" + num2str(stt) + chSuffix
			winName = "ColCmp_OsizeCol_S" + num2str(stt) + chSuffix
			yLabel = "\\F'Arial'\\Z14Mean Oligomer Size\\B" + stateName + "\\M"
			graphTitle = "Col Compare Oligomer Size (" + weightStr + ") " + chLabel + " (S" + num2str(stt) + ": " + stateName + ")"
			
			// rowIndex=-1: 1D wave
			CreateComparisonSummaryPlotEx(basePath, matrixName, -1, outputPrefix, winName, yLabel, graphTitle, 1, stt, sampleList)
			
			Print "  Compare OsizeCol " + chLabel + " S" + num2str(stt) + " completed"
		endfor
		
		// State
		String allYLabel = "\\F'Arial'\\Z14Mean Oligomer Size"
		String allTitlePrefix = "Col Oligomer Size (" + weightStr + ")"
		if(weighting == 0)
			CreateColAllStatesGraph(basePath, "OsizeCol_mean", chSuffix, allYLabel, allTitlePrefix, 1)
		else
			CreateColAllStatesGraph(basePath, "OsizeColMol_mean", chSuffix, allYLabel, allTitlePrefix, 1)
		endif
	endfor
	
	SetDataFolder $savedDF
	return 0
End

// -----------------------------------------------------------------------------
// ColCompareAbsoluteHMMP - 
// -----------------------------------------------------------------------------
Function ColCompareAbsoluteHMMP()
	String savedDF = GetDataFolder(1)
	String basePath = GetECBasePath() + ":"

	NVAR gDstate = root:Dstate
	NVAR ColWeightingMode = root:ColWeightingMode
	Variable Dstate = gDstate
	Variable weighting = ColWeightingMode  // 0=Particle, 1=Molecule

	String weightStr = SelectString(weighting, "Particle", "Molecule")
	Print "=== Compare Absolute Colocalization HMMP (% of Total, " + weightStr + ") ==="
	
	String channelList = GetOutputChannelList(1)
	Variable chIdx, stt
	String chSuffix, chLabel, stateName, sampleList
	String matrixName, outputPrefix, winName, yLabel, graphTitle
	
	for(chIdx = 0; chIdx < ItemsInList(channelList); chIdx += 1)
		chSuffix = StringFromList(chIdx, channelList)
		chLabel = GetChannelLabel(chSuffix)
		sampleList = GetSampleListForChannel(GetChannelIndex(chSuffix))
		
		for(stt = 0; stt <= Dstate; stt += 1)
			stateName = GetDstateName(stt, Dstate)
			
			// WeightingMatrix
			if(weighting == 0)
				matrixName = "ColHMMP_abs_S" + num2str(stt) + chSuffix + "_m"
			else
				matrixName = "ColHMMPMol_abs_S" + num2str(stt) + chSuffix + "_m"
			endif
			
			outputPrefix = "ColHMMP_abs_S" + num2str(stt) + chSuffix
			winName = "ColCmp_AbsHMMP_S" + num2str(stt) + chSuffix
			yLabel = "\\F'Arial'\\Z14Colocalization\\B" + stateName + "\\M [%]"
			graphTitle = "Col Compare Absolute HMMP (" + weightStr + ") " + chLabel + " (S" + num2str(stt) + ": " + stateName + ")"
			
			// rowIndex=-1: 1D wave
			CreateComparisonSummaryPlotEx(basePath, matrixName, -1, outputPrefix, winName, yLabel, graphTitle, 1, stt, sampleList)
			
			Print "  Compare Absolute HMMP " + chLabel + " S" + num2str(stt) + " completed"
		endfor
		
		// State
		String allYLabel = "\\F'Arial'\\Z14Colocalization [%]"
		String allTitlePrefix = "Col Absolute HMMP (" + weightStr + ")"
		if(weighting == 0)
			CreateColAllStatesGraph(basePath, "ColHMMP_abs", chSuffix, allYLabel, allTitlePrefix, 1)
		else
			CreateColAllStatesGraph(basePath, "ColHMMPMol_abs", chSuffix, allYLabel, allTitlePrefix, 1)
		endif
	endfor
	
	SetDataFolder $savedDF
	return 0
End

// -----------------------------------------------------------------------------
// ColCompareSteps - 
// -----------------------------------------------------------------------------
Function ColCompareSteps()
	String savedDF = GetDataFolder(1)
	String basePath = GetECBasePath() + ":"

	NVAR gDstate = root:Dstate
	NVAR ColWeightingMode = root:ColWeightingMode
	Variable Dstate = gDstate
	Variable weighting = ColWeightingMode  // 0=Particle, 1=Molecule

	String weightStr = SelectString(weighting, "Particle", "Molecule")
	Print "=== Compare Colocalization Steps (" + weightStr + ") ==="
	
	String channelList = GetOutputChannelList(1)
	Variable chIdx, stt
	String chSuffix, chLabel, stateName, sampleList
	String matrixName, outputPrefix, winName, yLabel, graphTitle
	
	for(chIdx = 0; chIdx < ItemsInList(channelList); chIdx += 1)
		chSuffix = StringFromList(chIdx, channelList)
		chLabel = GetChannelLabel(chSuffix)
		sampleList = GetSampleListForChannel(GetChannelIndex(chSuffix))
		
		for(stt = 0; stt <= Dstate; stt += 1)
			stateName = GetDstateName(stt, Dstate)
			
			// WeightingMatrix
			if(weighting == 0)
				// Particle: 
				matrixName = "ColSteps_S" + num2str(stt) + chSuffix + "_m"
				yLabel = "\\F'Arial'\\Z14Steps\\B" + stateName + "\\M [counts]"
			else
				// Molecule: 
				matrixName = "ColStepsMol_S" + num2str(stt) + chSuffix + "_m"
				yLabel = "\\F'Arial'\\Z14Molecular Steps\\B" + stateName + "\\M [molecules]"
			endif
			
			outputPrefix = "ColSteps_S" + num2str(stt) + chSuffix
			winName = "ColCmp_Steps_S" + num2str(stt) + chSuffix
			graphTitle = "Col Compare Steps (" + weightStr + ") " + chLabel + " (S" + num2str(stt) + ": " + stateName + ")"
			
			// rowIndex=-1: 1D wave
			CreateComparisonSummaryPlotEx(basePath, matrixName, -1, outputPrefix, winName, yLabel, graphTitle, 1, stt, sampleList)
			
			Print "  Compare Steps " + chLabel + " S" + num2str(stt) + " completed"
		endfor
		
		// State
		String allYLabel, allTitlePrefix
		if(weighting == 0)
			allYLabel = "\\F'Arial'\\Z14Steps [counts]"
			allTitlePrefix = "Col Steps (Particle)"
			CreateColAllStatesGraph(basePath, "ColSteps", chSuffix, allYLabel, allTitlePrefix, 1)
		else
			allYLabel = "\\F'Arial'\\Z14Molecular Steps [molecules]"
			allTitlePrefix = "Col Steps (Molecule)"
			CreateColAllStatesGraph(basePath, "ColStepsMol", chSuffix, allYLabel, allTitlePrefix, 1)
		endif
	endfor
	
	SetDataFolder $savedDF
	return 0
End

// -----------------------------------------------------------------------------
// ColCompareStepsDensity - ColSteps / Area [/um^2]
// -----------------------------------------------------------------------------
Function ColCompareStepsDensity()
	String savedDF = GetDataFolder(1)
	String basePath = GetECBasePath() + ":"

	NVAR gDstate = root:Dstate
	NVAR ColWeightingMode = root:ColWeightingMode
	Variable Dstate = gDstate
	Variable weighting = ColWeightingMode  // 0=Particle, 1=Molecule

	String weightStr = SelectString(weighting, "Particle", "Molecule")
	Print "=== Compare Colocalization Steps Density (" + weightStr + ") ==="

	String channelList = GetOutputChannelList(1)
	Variable chIdx, stt
	String chSuffix, chLabel, stateName, sampleList
	String matrixName, outputPrefix, winName, yLabel, graphTitle

	for(chIdx = 0; chIdx < ItemsInList(channelList); chIdx += 1)
		chSuffix = StringFromList(chIdx, channelList)
		chLabel = GetChannelLabel(chSuffix)
		sampleList = GetSampleListForChannel(GetChannelIndex(chSuffix))

		for(stt = 0; stt <= Dstate; stt += 1)
			stateName = GetDstateName(stt, Dstate)

			if(weighting == 0)
				matrixName = "ColStepsDensity_S" + num2str(stt) + chSuffix + "_m"
				yLabel = "\\F'Arial'\\Z14Steps/Area\\B" + stateName + "\\M [/µm²]"
			else
				matrixName = "ColStepsMolDensity_S" + num2str(stt) + chSuffix + "_m"
				yLabel = "\\F'Arial'\\Z14Mol Steps/Area\\B" + stateName + "\\M [/µm²]"
			endif

			outputPrefix = "ColStepsDensity_S" + num2str(stt) + chSuffix
			winName = "ColCmp_StepsDens_S" + num2str(stt) + chSuffix
			graphTitle = "Col Steps Density (" + weightStr + ") " + chLabel + " (S" + num2str(stt) + ": " + stateName + ")"

			CreateComparisonSummaryPlotEx(basePath, matrixName, -1, outputPrefix, winName, yLabel, graphTitle, 1, stt, sampleList)

			Print "  Compare Steps Density " + chLabel + " S" + num2str(stt) + " completed"
		endfor

		String allYLabel, allTitlePrefix
		if(weighting == 0)
			allYLabel = "\\F'Arial'\\Z14Steps/Area [/µm²]"
			allTitlePrefix = "Col Steps Density (Particle)"
			CreateColAllStatesGraph(basePath, "ColStepsDensity", chSuffix, allYLabel, allTitlePrefix, 1)
		else
			allYLabel = "\\F'Arial'\\Z14Mol Steps/Area [/µm²]"
			allTitlePrefix = "Col Steps Density (Molecule)"
			CreateColAllStatesGraph(basePath, "ColStepsMolDensity", chSuffix, allYLabel, allTitlePrefix, 1)
		endif
	endfor

	SetDataFolder $savedDF
	return 0
End

// -----------------------------------------------------------------------------
// ColCompareParticleDensity - Particle Density
// -----------------------------------------------------------------------------
Function ColCompareParticleDensity()
	String savedDF = GetDataFolder(1)
	String basePath = GetECBasePath() + ":"
	
	NVAR gDstate = root:Dstate
	Variable Dstate = gDstate

	Print "=== Compare Colocalization Particle Density ==="
	
	String channelList = GetOutputChannelList(1)
	Variable chIdx, stt
	String chSuffix, chLabel, stateName, sampleList
	String matrixName, outputPrefix, winName, yLabel, graphTitle
	
	for(chIdx = 0; chIdx < ItemsInList(channelList); chIdx += 1)
		chSuffix = StringFromList(chIdx, channelList)
		chLabel = GetChannelLabel(chSuffix)
		sampleList = GetSampleListForChannel(GetChannelIndex(chSuffix))
		
		for(stt = 0; stt <= Dstate; stt += 1)
			stateName = GetDstateName(stt, Dstate)
			matrixName = "ColParticleDensity_S" + num2str(stt) + chSuffix + "_m"
			outputPrefix = "ColPDens_S" + num2str(stt) + chSuffix
			winName = "ColCmp_PDens_S" + num2str(stt) + chSuffix
			yLabel = "\\F'Arial'\\Z14Particle Density\\B" + stateName + "\\M [/µm\\S2\\M]"
			graphTitle = "Col Compare Particle Density " + chLabel + " (S" + num2str(stt) + ": " + stateName + ")"
			
			// rowIndex=-1: 1D wave
			CreateComparisonSummaryPlotEx(basePath, matrixName, -1, outputPrefix, winName, yLabel, graphTitle, 1, stt, sampleList)
			
			Print "  Compare Particle Density " + chLabel + " S" + num2str(stt) + " completed"
		endfor
		
		// State
		String allYLabel = "\\F'Arial'\\Z14Particle Density [/µm\\S2\\M]"
		String allTitlePrefix = "Col Particle Density"
		CreateColAllStatesGraph(basePath, "ColParticleDensity", chSuffix, allYLabel, allTitlePrefix, 1)
	endfor
	
	SetDataFolder $savedDF
	return 0
End

// -----------------------------------------------------------------------------
// ColCompareKbByState - Kb
// -----------------------------------------------------------------------------
Function ColCompareKbByState()
	String savedDF = GetDataFolder(1)
	String basePath = GetECBasePath() + ":"
	
	NVAR gDstate = root:Dstate
	Variable Dstate = gDstate

	Print "=== Compare Colocalization Kb by State (Particle) ==="
	
	String channelList = GetOutputChannelList(1)
	Variable chIdx, stt
	String chSuffix, chLabel, stateName, sampleList
	String matrixName, outputPrefix, winName, yLabel, graphTitle
	
	for(chIdx = 0; chIdx < ItemsInList(channelList); chIdx += 1)
		chSuffix = StringFromList(chIdx, channelList)
		chLabel = GetChannelLabel(chSuffix)
		sampleList = GetSampleListForChannel(GetChannelIndex(chSuffix))
		
		for(stt = 0; stt <= Dstate; stt += 1)
			stateName = GetDstateName(stt, Dstate)
			matrixName = "ColKb_S" + num2str(stt) + chSuffix + "_m"
			outputPrefix = "ColKb_S" + num2str(stt) + chSuffix
			winName = "ColCmp_Kb_S" + num2str(stt) + chSuffix
			yLabel = "\\F'Arial'\\Z14Kb\\B" + stateName + "\\M [/µm\\S2\\M]"
			graphTitle = "Col Compare Kb (Particle) " + chLabel + " (S" + num2str(stt) + ": " + stateName + ")"
			
			// rowIndex=-1: 1D wave
			CreateComparisonSummaryPlotEx(basePath, matrixName, -1, outputPrefix, winName, yLabel, graphTitle, 1, stt, sampleList)
			
			Print "  Compare Kb " + chLabel + " S" + num2str(stt) + " completed"
		endfor
		
		// State
		String allYLabel = "\\F'Arial'\\Z14Kb [/µm\\S2\\M]"
		String allTitlePrefix = "Col Kb (Particle)"
		CreateColAllStatesGraph(basePath, "ColKb", chSuffix, allYLabel, allTitlePrefix, 1)
	endfor
	
	SetDataFolder $savedDF
	return 0
End

// -----------------------------------------------------------------------------
// ColCompareMolecularDensity - Molecular Density
// -----------------------------------------------------------------------------
Function ColCompareMolecularDensity()
	String savedDF = GetDataFolder(1)
	String basePath = GetECBasePath() + ":"
	
	NVAR gDstate = root:Dstate
	Variable Dstate = gDstate

	Print "=== Compare Colocalization Molecular Density ==="
	
	String channelList = GetOutputChannelList(1)
	Variable chIdx, stt
	String chSuffix, chLabel, stateName, sampleList
	String matrixName, outputPrefix, winName, yLabel, graphTitle
	
	for(chIdx = 0; chIdx < ItemsInList(channelList); chIdx += 1)
		chSuffix = StringFromList(chIdx, channelList)
		chLabel = GetChannelLabel(chSuffix)
		sampleList = GetSampleListForChannel(GetChannelIndex(chSuffix))
		
		for(stt = 0; stt <= Dstate; stt += 1)
			stateName = GetDstateName(stt, Dstate)
			matrixName = "ColMolecularDensity_S" + num2str(stt) + chSuffix + "_m"
			outputPrefix = "ColMDens_S" + num2str(stt) + chSuffix
			winName = "ColCmp_MDens_S" + num2str(stt) + chSuffix
			yLabel = "\\F'Arial'\\Z14Molecular Density\\B" + stateName + "\\M [/µm\\S2\\M]"
			graphTitle = "Col Compare Molecular Density " + chLabel + " (S" + num2str(stt) + ": " + stateName + ")"
			
			// rowIndex=-1: 1D wave
			CreateComparisonSummaryPlotEx(basePath, matrixName, -1, outputPrefix, winName, yLabel, graphTitle, 1, stt, sampleList)
			
			Print "  Compare Molecular Density " + chLabel + " S" + num2str(stt) + " completed"
		endfor
		
		// State
		String allYLabel = "\\F'Arial'\\Z14Molecular Density [/µm\\S2\\M]"
		String allTitlePrefix = "Col Molecular Density"
		CreateColAllStatesGraph(basePath, "ColMolecularDensity", chSuffix, allYLabel, allTitlePrefix, 1)
	endfor
	
	SetDataFolder $savedDF
	return 0
End

// -----------------------------------------------------------------------------
// ColCompareKbByStateMol - Kb(Molecule)
// -----------------------------------------------------------------------------
Function ColCompareKbByStateMol()
	String savedDF = GetDataFolder(1)
	String basePath = GetECBasePath() + ":"
	
	NVAR gDstate = root:Dstate
	Variable Dstate = gDstate

	Print "=== Compare Colocalization Kb by State (Molecule) ==="
	
	String channelList = GetOutputChannelList(1)
	Variable chIdx, stt
	String chSuffix, chLabel, stateName, sampleList
	String matrixName, outputPrefix, winName, yLabel, graphTitle
	
	for(chIdx = 0; chIdx < ItemsInList(channelList); chIdx += 1)
		chSuffix = StringFromList(chIdx, channelList)
		chLabel = GetChannelLabel(chSuffix)
		sampleList = GetSampleListForChannel(GetChannelIndex(chSuffix))
		
		for(stt = 0; stt <= Dstate; stt += 1)
			stateName = GetDstateName(stt, Dstate)
			matrixName = "ColKbMol_S" + num2str(stt) + chSuffix + "_m"
			outputPrefix = "ColKbMol_S" + num2str(stt) + chSuffix
			winName = "ColCmp_KbMol_S" + num2str(stt) + chSuffix
			yLabel = "\\F'Arial'\\Z14Kb(mol)\\B" + stateName + "\\M [/µm\\S2\\M]"
			graphTitle = "Col Compare Kb (Molecule) " + chLabel + " (S" + num2str(stt) + ": " + stateName + ")"
			
			// rowIndex=-1: 1D wave
			CreateComparisonSummaryPlotEx(basePath, matrixName, -1, outputPrefix, winName, yLabel, graphTitle, 1, stt, sampleList)
			
			Print "  Compare Kb(mol) " + chLabel + " S" + num2str(stt) + " completed"
		endfor
		
		// State
		String allYLabel = "\\F'Arial'\\Z14Kb(mol) [/µm\\S2\\M]"
		String allTitlePrefix = "Col Kb (Molecule)"
		CreateColAllStatesGraph(basePath, "ColKbMol", chSuffix, allYLabel, allTitlePrefix, 1)
	endfor
	
	SetDataFolder $savedDF
	return 0
End

// -----------------------------------------------------------------------------
// ColCompareAll - Compare
// -----------------------------------------------------------------------------
Function ColCompareAll()
	Print "=========================================="
	Print "Colocalization Compare All Analysis"
	Print "=========================================="
	
	//
	NVAR ColWeightingMode = root:ColWeightingMode
	NVAR ColAffinityParam = root:ColAffinityParam
	NVAR ColIntensityMode = root:ColIntensityMode
	NVAR ColDiffusionMode = root:ColDiffusionMode
	NVAR ColOntimeMode = root:ColOntimeMode
	NVAR ColOnrateMode = root:ColOnrateMode

	Variable weighting = ColWeightingMode  // 0=Particle, 1=Molecule
	Variable affParam = ColAffinityParam  // 0=Kb, 1=Density, 2=Distance
	Variable intMode = ColIntensityMode
	Variable diffMode = ColDiffusionMode
	Variable ontMode = ColOntimeMode
	Variable onrMode = ColOnrateMode
	
	String weightStr = SelectString(weighting, "Particle", "Molecule")
	
	// Affinity - 
	if(affParam == 0)
		Print "--- Affinity: Kb (" + weightStr + ") ---"
		if(weighting == 0)
			ColCompareKbByState()
		else
			ColCompareKbByStateMol()
		endif
	elseif(affParam == 1)
		Print "--- Affinity: Density (" + weightStr + ") ---"
		if(weighting == 0)
			ColCompareParticleDensity()
		else
			ColCompareMolecularDensity()
		endif
	else
		Print "--- Affinity: Distance ---"
		ColCompareAffinity()
	endif
	
	// Intensity
	if(intMode == 0)
		Print "--- Intensity (Simple, " + weightStr + ") ---"
		ColCompareOsizeCol()
	else
		Print "--- Intensity (Fitting) ---"
		ColCompareIntensity()
	endif
	
	// D-state Population
	if(diffMode == 0)
		Print "--- D-state Population (per Total, " + weightStr + ") ---"
		ColCompareAbsoluteHMMP()
	elseif(diffMode == 1)
		Print "--- D-state Population (per Col) ---"
		ColCompareDiffusion()
	else
		Print "--- D-state Steps (" + weightStr + ") ---"
		ColCompareSteps()
	endif

	// Steps Density (ColSteps / Area)
	Print "--- Steps Density (" + weightStr + ") ---"
	ColCompareStepsDensity()

	// On-time
	if(ontMode == 0)
		Print "--- On-time (Simple, " + weightStr + ") ---"
		ColCompareOntimeSimple()
	else
		Print "--- On-time (Fitting) ---"
		ColCompareOntime()
	endif
	
	// On-rate
	if(onrMode == 0)
		Print "--- On-rate (On-event Rate, " + weightStr + ") ---"
		ColCompareOnrate()
	else
		Print "--- On-rate (k_on, " + weightStr + ") ---"
		ColCompareReactionRate()
	endif
	
	Print "=========================================="
	Print "Colocalization Compare All completed"
	Print "=========================================="
	return 0
End

// -----------------------------------------------------------------------------
// CreateColAllStatesGraph - Col CompareState
// -----------------------------------------------------------------------------
// basePath: EC
// matrixPrefix: Matrix"ColHMMP_abs", "ColSteps"_Sn_suffix
// chSuffix: "_C1E", "_C2E"
// yLabel: Y
// titlePrefix: 
// includeS0: S01=0=S1
// [rowIndex]: avg/sem wave02D matrix
Function CreateColAllStatesGraph(basePath, matrixPrefix, chSuffix, yLabel, titlePrefix, includeS0, [rowIndex])
	String basePath
	String matrixPrefix
	String chSuffix
	String yLabel
	String titlePrefix
	Variable includeS0
	Variable rowIndex
	
	// rowIndex
	if(ParamIsDefault(rowIndex))
		rowIndex = 0
	endif
	
	String savedDF = GetDataFolder(1)
	
	NVAR gDstate = root:Dstate
	Variable Dstate = gDstate

	//
	Variable chIdx = GetChannelIndex(chSuffix)
	String sampleList = GetSampleListForChannel(chIdx)
	Variable numSamples = ItemsInList(sampleList)
	
	if(numSamples == 0)
		return -1
	endif
	
	// 
	Variable startState = includeS0 ? 0 : 1
	Variable numStates = Dstate - startState + 1
	
	// Comparison
	String compPath = GetComparisonPathFromBase(basePath)
	if(!DataFolderExists(compPath))
		EnsureComparisonFolderForBase(basePath)
	endif
	SetDataFolder $compPath
	
	// wave
	String allLabelName = matrixPrefix + "_AllLabels" + chSuffix
	String allMeanName = matrixPrefix + "_AllMeans" + chSuffix
	String allSEMName = matrixPrefix + "_AllSEMs" + chSuffix
	String allColorName = matrixPrefix + "_AllColors" + chSuffix
	
	Variable totalBars = numStates * numSamples
	Make/O/T/N=(totalBars) $allLabelName
	Make/O/N=(totalBars) $allMeanName = NaN
	Make/O/N=(totalBars) $allSEMName = NaN
	Make/O/N=(totalBars, 3) $allColorName = 0
	
	Wave/T AllLabels = $allLabelName
	Wave AllMeans = $allMeanName
	Wave AllSEMs = $allSEMName
	Wave AllColors = $allColorName
	
	Variable barIdx = 0, stt, smplIdx
	Variable r, g, b
	String smplName, stateName
	String avgPath, semPath
	
	for(stt = startState; stt <= Dstate; stt += 1)
		stateName = GetDstateName(stt, Dstate)
		
		for(smplIdx = 0; smplIdx < numSamples; smplIdx += 1)
			smplName = StringFromList(smplIdx, sampleList)
			
			AllLabels[barIdx] = smplName + "-" + stateName
			
			// Results  avg/sem 
			String matrixName = matrixPrefix + "_S" + num2str(stt) + chSuffix + "_m"
			avgPath = basePath + smplName + ":Results:" + matrixName + "_avg"
			semPath = basePath + smplName + ":Results:" + matrixName + "_sem"
			Wave/Z avgWave = $avgPath
			Wave/Z semWave = $semPath
			
			if(WaveExists(avgWave) && WaveExists(semWave))
				if(rowIndex < numpnts(avgWave))
					AllMeans[barIdx] = avgWave[rowIndex]
					AllSEMs[barIdx] = semWave[rowIndex]
				endif
			endif
			
			GetStateColorWithShade(stt, smplIdx, numSamples, r, g, b)
			AllColors[barIdx][0] = r
			AllColors[barIdx][1] = g
			AllColors[barIdx][2] = b
			
			barIdx += 1
		endfor
	endfor
	
	// 
	String chLabel = GetChannelLabel(chSuffix)
	String winName = "ColCmp_" + matrixPrefix + "_All" + chSuffix
	DoWindow/K $winName
	
	Display/K=1/N=$winName AllMeans vs AllLabels
	
	ModifyGraph mode=5, hbFill=2
	ModifyGraph zColor($allMeanName)={AllColors,*,*,directRGB,0}
	ModifyGraph useBarStrokeRGB($allMeanName)=1, barStrokeRGB($allMeanName)=(0,0,0)
	
	ErrorBars $allMeanName Y,wave=(AllSEMs, AllSEMs)
	
	ModifyGraph tick=2, mirror=0, fStyle=1, fSize=14, font="Arial"
	ModifyGraph tick(bottom)=3, fSize(bottom)=10
	ModifyGraph tkLblRot(bottom)=90
	ModifyGraph catGap(bottom)=0.3
	
	// 
	SetBarGraphSizeByItems(totalBars)
	
	Label left yLabel
	SetAxis left 0, *
	DoWindow/T $winName, titlePrefix + " " + chLabel + " (All States)"
	
	SetDataFolder $savedDF
	Print "  All States graph created: " + winName
	return 0
End
