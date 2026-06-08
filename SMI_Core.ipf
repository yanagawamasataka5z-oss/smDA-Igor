#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3
#pragma version=2.6
// ModuleName - 

// =============================================================================
// SMI_Core.ipf - Single Molecule Imaging Analysis Core Utilities
// =============================================================================
// 
// Version 2.6 - Added EnsureGlobalParameters for NVAR_Exists removal
// =============================================================================

// -----------------------------------------------------------------------------
// 
// 
// -----------------------------------------------------------------------------
Function EnsureGlobalParameters()
	NVAR/Z initialized = root:gGlobalParamsInitialized
	if(NVAR_Exists(initialized) && initialized == 1)
		return 0  // 
	endif
	
	InitializeGlobalParameters()
	return 1  // 
End

// -----------------------------------------------------------------------------
// 
// -----------------------------------------------------------------------------
Function InitializeGlobalParameters()
	// 
	Variable/G root:gGlobalParamsInitialized = 1
	
	// =====  =====
	String/G root:CurrentSampleName = ""		// 
	
	// =====  =====
	Variable/G root:framerate = 0.03		//  [sec/frame]
	Variable/G root:FrameNum = 100			//
	Variable/G root:scale = 0.065			//  [um/pix]
	Variable/G root:ROIsize = 12			// ROI [pix]
	Variable/G root:MinFrame = 12			//
	Variable/G root:PixNum = 512			//

	//
	Variable/G root:ExCoef = 0.23			//  [e-/count]
	Variable/G root:QE = 0.80				//
	Variable/G root:IntensityMode = 1		// Intensity: 0=Raw Intensity, 1=Photon number
	
	// =====  =====
	Variable/G root:cAAS = 0				// AAS
	Variable/G root:cAAS2 = 0				// AAS v2
	Variable/G root:cAAS4 = 1				// AAS v4
	Variable/G root:cHMM = 1				// HMMHMM*ON
	Variable/G root:Dstate = 3				// HMM1-5*3
	Variable/G root:MaxSegment = 0			// Segmentation0=
	Variable/G root:ctif = 0				// TIF
	Variable/G root:cDXT = 0				// DXT
	Variable/G root:cTrackMate = 0			// TrackMate format
	Variable/G root:cVBSPT = 0				// VBSPT format
	Variable/G root:cImage = 0				// Image mode
	Variable/G root:cUseUserDefinedName = 0	// SampleName0=
	String/G root:gSampleNameInput = "Sample1"	// SampleNameCommonLoad
	Variable/G root:ROIavg = 0				// ROI average
	Variable/G root:Kfunc = 1				// K-function
	Variable/G root:PVHistBin = 50			// Pixel Value histogram bin
	Variable/G root:PVHistDim = 200			// Pixel Value histogram dim
	
	// ===== - ON =====
	// Diffusion
	Variable/G root:cRunMSD = 1				// MSD
	Variable/G root:cRunStepSize = 1		// Step Size
	// Intensity
	Variable/G root:cRunIntensity = 1		// Intensity
	Variable/G root:cRunLP = 1				// Localization Precision
	Variable/G root:cRunDensity = 1			// Density
	Variable/G root:cRunMolDensity = 1		// Molecular Density
	// Kinetics
	Variable/G root:cRunOffrate = 1			// Off-rate
	Variable/G root:cRunOnrate = 1			// On-rate
	Variable/G root:cRunStateTransition = 1	// State Transition
	Variable/G root:LThreshold = 1.0			// L-threshold [µm] for diagram display
	Variable/G root:cKinOutputTau = 1		// Kinetics: 1=τ(), 0=k()
	Variable/G root:cRunAutoStatTest = 1	// Compare
	Variable/G root:cStatOutputCmdLine = 1	// 
	Variable/G root:cStatOutputGraph = 1	// 
	Variable/G root:cStatOutputTable = 1	// 
	
	// Significance bracket display parameters
	Variable/G root:StatBracket_XOffset = 0.5	// X offset (shift brackets right)
	Variable/G root:StatBracket_TextGap = 0.11	// gap between line and * (fraction of globalMax)
	Variable/G root:StatBracket_StartY = 1.15	// first bracket Y (fraction of globalMax)
	Variable/G root:StatBracket_StepY = 0.12	// vertical step between brackets (fraction of globalMax)
	Variable/G root:StatBracket_TickH = 0.05	// tick height (fraction of globalMax)
	Variable/G root:cSuppressOutput = 1	// 1=, 0=*ON
	// Data Loading - Trajectory
	Variable/G root:cRunTrajectory = 1		// TrajectoryON
	Variable/G root:cUseAlignedTraj = 1		// State TransitionAligned TrajectoryON
	
	// =====  =====
	// Panel.ipf CreateColocalizationTab()
	Variable/G root:ColIndex = 1			// Col1/EC1, Col2/EC2, ...
	Variable/G root:ColAreaMode = 1			// Density area: 0=Min, 1=Max

	// =====  =====
	Variable/G root:cSumGauss = 0			// Sum Gauss
	Variable/G root:cSumLogNorm = 0		// Sum Log-normal
	Variable/G root:cFixIntParameters = 0	// 
	Variable/G root:cFixMean = 0			// Mean
	Variable/G root:cFixSD = 0				// SD
	Variable/G root:IntNormByS0 = 1		// S01=, 0=*ON
	Variable/G root:MeanIntGauss = 250		// Gauss [au]
	Variable/G root:SDIntGauss = 100		// Gauss SD [au]
	Variable/G root:SDIntLognorm = 0.2		// LogNorm SD*0.2
	Variable/G root:IhistBin = 25			//  *25
	Variable/G root:IhistDim = 200			//  *200
	Variable/G root:MinOligomerSize = 8	// AIC *8
	Variable/G root:MaxOligomerSize = 8	// AIC *8
	Variable/G root:cSetIntensityRange = 0	// 
	Variable/G root:cSetIntPN = 0			// 
	Variable/G root:StartIntRange = 0		// 
	Variable/G root:EndIntRange = 0		// 
	
	// =====  =====
	Variable/G root:cTimeAverage = 0		// 
	Variable/G root:cMoveAve = 1			//  (1=, 0=) *
	Variable/G root:AreaRangeMSD = 20		// MSD [frames] (RangeMSD)
	Variable/G root:ThresholdMSD = 1		// MSD [%] *1%
	Variable/G root:AreaThresholdMSD = 5	// MSD [%] (ThresholdMSD) - 
	Variable/G root:DavgFrame = 10			// 
	Variable/G root:InitialD0 = 0.1			// D0 [um^2/s]
	Variable/G root:InitialAlpha = 1		// Alpha
	Variable/G root:AlphaFix = 0			// Alpha (1=alpha)
	Variable/G root:InitialL = 0.2			// L [um]
	Variable/G root:InitialEpsilon = 0.005	// Epsilon [um^2]
	Variable/G root:Efix = 1				// EpsilonON
	Variable/G root:DhistBin = 0.065		//  [um] (= scale)
	Variable/G root:DhistDim = 1000		// 
	Variable/G root:StepHistBin = 0.01		// Step size [um] (10 nm)
	Variable/G root:StepHistDim = 100		// Step size01um
	Variable/G root:StepDeltaTMin = 1		// Step size histogram Δt min [frames] - 
	Variable/G root:StepDeltaTMax = 1		// Step size histogram Δt max [frames]
	Variable/G root:StepFitD1 = 0.002		// Step fitting D1 [um^2/s]
	Variable/G root:StepFitScale = 5		// Step fitting scale (Dn+1 = Dn * scale)
	// Step fitting - 
	NVAR/Z existingMin = root:StepFitMinStates
	NVAR/Z existingMax = root:StepFitMaxStates
	if(!NVAR_Exists(existingMin))
		Variable/G root:StepFitMinStates = 1	// Step fitting 
	endif
	if(!NVAR_Exists(existingMax))
		Variable/G root:StepFitMaxStates = 5	// Step fitting 
	endif
	
	// =====  =====
	Variable/G root:LPhistBin = 1			//  [nm]
	Variable/G root:LPhistDim = 40			//
	Variable/G root:RHistBin = 0.1			// R (Particle Density) [um]
	Variable/G root:RHistDim = 200			// R (Particle Density)

	// =====  =====
	String/G root:Color0 = "grays"			// S0
	String/G root:Color1 = "cyan"			// S1
	String/G root:Color2 = "yellow"			// S2
	String/G root:Color3 = "green"			// S3
	String/G root:Color4 = "magenta"		// S4
	String/G root:Color5 = "red"			// S5
	Variable/G root:HeatmapMin = 0			// 
	Variable/G root:HeatmapMax = 5			// 0=
	
	Variable/G root:DstateMin = 1			// D
	Variable/G root:DstateMax = 5			// D
	// DA:, D:- 
	Variable/G root:InitialD_A1 = 1
	Variable/G root:InitialD_A2 = 1
	Variable/G root:InitialD_A3 = 1
	Variable/G root:InitialD_A4 = 1
	Variable/G root:InitialD_A5 = 1
	Variable/G root:InitialD_D1 = 1
	Variable/G root:InitialD_D2 = 1
	Variable/G root:InitialD_D3 = 1
	Variable/G root:InitialD_D4 = 1
	Variable/G root:InitialD_D5 = 1
	
	// =====  =====
	// Density parameters: initialized by Panel (do not use Variable/G here)
	
	// ===== Ripley K =====
	// R histogram parameters: initialized by Panel (do not use Variable/G here)
	Variable/G root:DSmoothing = 20		// 
	Variable/G root:DensityStartFrame = 20	// Density
	Variable/G root:DensityEndFrame = 25	// Density
	
	// ===== Timelapse =====
	Variable/G root:LigandNumTL = 2			// 
	Variable/G root:TimeInterval = 10		//  [min]
	Variable/G root:TimePoints = 3			// 
	Variable/G root:TimeStimulation = 8		//  [min]
	Variable/G root:DIhistImageMin = 0.001	// Mol Density Image
	Variable/G root:DIhistImageMax = 0.1	// Mol Density Image
	Variable/G root:DIhistTxt = 1			// DxI Image
	
	// ===== Layout =====
	Variable/G root:LayoutPageW = 8.27		//  [inch] (A4)
	Variable/G root:LayoutPageH = 11.69		//  [inch]
	Variable/G root:LayoutOffset = 12.7		//  [mm]
	Variable/G root:LayoutGap = 3.0			//  [mm]
	Variable/G root:LayoutDivW = 4			// 
	Variable/G root:LayoutDivH = 4			// 
	Variable/G root:LayoutPaperMode = 2		//  (1=Letter, 2=A4, 3=Custom)
	Variable/G root:LayoutOutputMode = 3	//  (1=Graph, 2=PNG, 3=SVG)
	Variable/G root:LayoutNoLabel = 0		// XY (0=, 1=)
	Variable/G root:LayoutNoTitle = 0		// Image title (0=, 1=)
	Variable/G root:LayoutScaleFontSize = 8	// ColorScale
	
	// ===== On-rate =====
	Variable/G root:cUseDensityForOnrate = 1	// Density (0=, 1=Density)
	Variable/G root:OnArea = (512 * 0.065) * (512 * 0.065)	// On-rate [um^2] = (PixNum * scale)^2
	Variable/G root:InitialVon = 1			// Von
	Variable/G root:InitialTauon = 5		// Tauon [s]5
	Variable/G root:InitialStarton = 1		// Starton [frame]
	
	// ===== Off-rate =====
	Variable/G root:cORC = 1				// Off-rate correction ()
	Variable/G root:cEcorrection = 0		// 
	Variable/G root:cRestrictArea = 0		// 
	Variable/G root:AreaX0_off = 0			// Off-rateX0 [um]
	Variable/G root:AreaY0_off = 0			// Off-rateY0 [um]
	Variable/G root:AreaWidth_off = 0		// Off-rate [um]
	Variable/G root:AreaLong_off = 0		// Off-rate [um]
	Variable/G root:ExpMin_off = 1			//
	Variable/G root:ExpMax_off = 1			//
	Variable/G root:MaxExpComponents = 5	// AIC
	Variable/G root:TrajHistBin = 0.1		//  [s]
	Variable/G root:TrajHistMax = 10		//  [s]
	Variable/G root:FitType = 2				// MSD (0:free, 1:confined, 2:confined+err, 3:anomalous, 4:anomalous+err)
	// Off-rateTau1:, TauScale:
	Variable/G root:InitialTau1_off = 0.5	//  [s]
	Variable/G root:TauScale_off = 5		// Tau (Tau_n = Tau1 * Scale^(n-1))
	Variable/G root:InitialA1_off = 80		// A1 [%]
	Variable/G root:AScale_off = 0.5		// A (A_n = A1 * Scale^(n-1))
	
	// ===== PALM/STORM =====
	// 
	Variable/G root:PALM_X0 = 0			// X0 [um]
	Variable/G root:PALM_Y0 = 0			// Y0 [um]
	Variable/G root:PALM_Width = 10		//  [um]
	Variable/G root:PALM_Height = 10		//  [um]
	Variable/G root:PALM_Guard = 1			//  [um]
	Variable/G root:PALM_DensityBin = 0.5	//  [um]
	Variable/G root:PALM_FrameAvg = 10		// 
	// 
	// Area parameters: initialized by SMI_Panel.ipf InitGlobalIfMissing
	// (Do not use Variable/G here — it overwrites user-changed values)
	Variable/G root:cPALM_Scan = 0			// PALM
	Variable/G root:cROIavg = 0			// ROI
	Variable/G root:cKfunc = 0				// K
	Variable/G root:cClustering = 0		// 
	Variable/G root:PALM_KfuncRmax = 1.0	// K [um]
	Variable/G root:PALM_KfuncRstep = 0.02	// K [um]
	Variable/G root:PALM_ClusterEps = 0.1	// DBSCAN [um]
	Variable/G root:PALM_ClusterMinPts = 5	// DBSCAN
	Variable/G root:PALM_PixelSize = 20	//  [nm]
	
	// ===== Dose-response =====
	Variable/G root:LigandNumDose = 1		// 
	Variable/G root:LigandMax = 1000		// 
	Variable/G root:LigandDilution = 10	// 
	Variable/G root:LigandPoints = 8		// 
	
	// =====  =====
	Variable/G root:GraphWidth = 150		// Summary Plot [points]
	
	Print "SMI Analysis: "
End

// -----------------------------------------------------------------------------
// 
// ColIndexCol1/EC1, Col2/EC2, ...
// -----------------------------------------------------------------------------
Function/S GetColBasePath()
	NVAR/Z ColIndex = root:ColIndex
	if(!NVAR_Exists(ColIndex))
		return "root:Col1"
	endif
	return "root:Col" + num2str(ColIndex)
End

Function/S GetECBasePath()
	NVAR/Z ColIndex = root:ColIndex
	if(!NVAR_Exists(ColIndex))
		return "root:EC1"
	endif
	return "root:EC" + num2str(ColIndex)
End

// -----------------------------------------------------------------------------
// SetStandardGraphStyle - 
// fontSize: 14
// useLogScale: lowTrip0
// aspectRatio: 1.618=
// -----------------------------------------------------------------------------
Function SetStandardGraphStyle([fontSize, useLogScale, aspectRatio])
	Variable fontSize, useLogScale, aspectRatio
	
	// 
	if(ParamIsDefault(fontSize))
		fontSize = 14
	endif
	if(ParamIsDefault(useLogScale))
		useLogScale = 0
	endif
	if(ParamIsDefault(aspectRatio))
		aspectRatio = 1.618
	endif
	
	// 
	if(useLogScale)
		ModifyGraph tick=0, mirror=0, fStyle=1, fSize=(fontSize), font="Arial"
		ModifyGraph lowTrip(left)=0.001
	else
		ModifyGraph tick=0, mirror=0, fStyle=1, fSize=(fontSize), font="Arial"
		ModifyGraph lowTrip(left)=0.0001
	endif
	
	// 
	ModifyGraph width={Aspect, aspectRatio}
End

// -----------------------------------------------------------------------------
// SetBarGraphStyle - 
// fontSize: 14
// rotateLabels: X901
// catGap: 0.5
// aspectRatio: 1.618=
// -----------------------------------------------------------------------------
Function SetBarGraphStyle([fontSize, rotateLabels, catGap, aspectRatio])
	Variable fontSize, rotateLabels, catGap, aspectRatio
	
	// 
	if(ParamIsDefault(fontSize))
		fontSize = 14
	endif
	if(ParamIsDefault(rotateLabels))
		rotateLabels = 1
	endif
	if(ParamIsDefault(catGap))
		catGap = 0.5
	endif
	if(ParamIsDefault(aspectRatio))
		aspectRatio = 1.618
	endif
	
	// 
	ModifyGraph tick=2, mirror=0, fStyle=1, fSize=(fontSize), font="Arial"
	ModifyGraph tick(bottom)=3
	if(rotateLabels)
		ModifyGraph tkLblRot(bottom)=90
	endif
	ModifyGraph catGap(bottom)=(catGap)
	ModifyGraph width={Aspect, aspectRatio}
End

// -----------------------------------------------------------------------------
// SetBarGraphSizeByItems - Apply standard graph sizing to bar charts
// Uses Aspect ratio (1:1.618) for consistent, resizable display
// Note: params (numItems, baseWidth, widthPerItem, maxWidth) retained for
//       call-site compatibility but no longer used
// -----------------------------------------------------------------------------
Function SetBarGraphSizeByItems(numItems, [baseWidth, widthPerItem, maxWidth])
	Variable numItems, baseWidth, widthPerItem, maxWidth
	
	// Set initial window size large enough (matches standard graph window)
	// Then apply Aspect ratio so plot area is resizable by drag
	GetWindow kwTopWin, wsize
	MoveWindow V_left, V_top, V_left + 500, V_top + 350
	
	// Aspect ratio: same as all other graphs (resizable by drag)
	ModifyGraph width={Aspect, 1.618}
	
	// Y
	ModifyGraph lowTrip(left)=0.0001
	
	DoUpdate
End

// -----------------------------------------------------------------------------
// IsSystemFolder - 
// 
// -----------------------------------------------------------------------------
Function IsSystemFolder(folderName)
	String folderName
	
	// 
	if(strlen(folderName) == 0)
		return 1
	endif
	
	// Igor
	if(StringMatch(folderName, "Packages") || StringMatch(folderName, "WMAnalysisHelper"))
		return 1
	endif
	
	// SMI Suite
	if(StringMatch(folderName, "Comparison") || StringMatch(folderName, "Results"))
		return 1
	endif
	if(StringMatch(folderName, "Matrix") || StringMatch(folderName, "SMI"))
		return 1
	endif
	
	// ColocalizationCol, Col1-99, EC, EC1-99
	if(StringMatch(folderName, "Col") || StringMatch(folderName, "EC"))
		return 1
	endif
	// Colocalization
	if(GrepString(folderName, "^Col[0-9]+$") || GrepString(folderName, "^EC[0-9]+$"))
		return 1
	endif
	
	// SegmentationSeg, Seg0-99
	if(StringMatch(folderName, "Seg"))
		return 1
	endif
	if(GrepString(folderName, "^Seg[0-9]+$"))
		return 1
	endif
	
	// List_C1/List_C2
	if(StringMatch(folderName, "List_*"))
		return 1
	endif
	
	return 0  // 
End

// -----------------------------------------------------------------------------
// CleanupTempWaves - Wave
// Wave
// basePath: "root", "root:EC1", "root:Seg0" : "root"
// cleanAll: 1EC*/Col*/Seg*: 0
// -----------------------------------------------------------------------------
Function CleanupTempWaves([basePath, cleanAll, verbose])
	String basePath
	Variable cleanAll, verbose
	
	if(ParamIsDefault(basePath))
		basePath = "root"
	endif
	if(ParamIsDefault(cleanAll))
		cleanAll = 0
	endif
	if(ParamIsDefault(verbose))
		verbose = 1
	endif
	
	String savedDF = GetDataFolder(1)
	
	if(verbose)
		Print "=== Cleanup Temporary Waves ==="
	endif
	
	Variable totalDeleted = 0
	Variable i
	
	// basePath
	totalDeleted += CleanupBasePathTempWaves(basePath, verbose)
	
	// cleanAll=1 EC*/Col*/Seg*
	if(cleanAll)
		// EC1-EC99
		for(i = 1; i <= 99; i += 1)
			String ecPath = "root:EC" + num2str(i)
			if(DataFolderExists(ecPath))
				totalDeleted += CleanupBasePathTempWaves(ecPath, verbose)
			endif
		endfor
		// Col1-Col99
		for(i = 1; i <= 99; i += 1)
			String colPath = "root:Col" + num2str(i)
			if(DataFolderExists(colPath))
				totalDeleted += CleanupBasePathTempWaves(colPath, verbose)
			endif
		endfor
		// Seg0-Seg99
		for(i = 0; i <= 99; i += 1)
			String segPath = "root:Seg" + num2str(i)
			if(DataFolderExists(segPath))
				totalDeleted += CleanupBasePathTempWaves(segPath, verbose)
			endif
		endfor
	endif
	
	SetDataFolder $savedDF
	
	if(verbose)
		Printf "Cleanup complete: %d waves deleted\r", totalDeleted
	endif
	
	return totalDeleted
End

// CleanupBasePathTempWaves - basePath
Function CleanupBasePathTempWaves(basePath, verbose)
	String basePath
	Variable verbose
	
	if(!DataFolderExists(basePath))
		return 0
	endif
	
	String savedDF = GetDataFolder(1)
	Variable totalDeleted = 0
	Variable i
	
	// basePath
	String sampleList = GetSampleListFromBase(basePath + ":")
	Variable numSamples = ItemsInList(sampleList)
	
	for(i = 0; i < numSamples; i += 1)
		String sampleName = StringFromList(i, sampleList)
		Variable deleted = CleanupSampleTempWavesInPath(basePath, sampleName, verbose)
		totalDeleted += deleted
	endfor
	
	SetDataFolder $savedDF
	return totalDeleted
End

// CleanupSampleTempWavesInPath - basePath
Function CleanupSampleTempWavesInPath(basePath, sampleName, verbose)
	String basePath, sampleName
	Variable verbose
	
	String samplePath
	if(StringMatch(basePath, "root"))
		samplePath = "root:" + sampleName
	else
		samplePath = basePath + ":" + sampleName
	endif
	
	if(!DataFolderExists(samplePath))
		return 0
	endif
	
	Variable totalDeleted = 0
	Variable numFolders
	if(StringMatch(basePath, "root"))
		numFolders = CountDataFolders(sampleName)
	else
		numFolders = CountDataFoldersInPath(basePath, sampleName)
	endif
	Variable m
	
	for(m = 0; m < numFolders; m += 1)
		String folderName = sampleName + num2str(m + 1)
		String cellPath = samplePath + ":" + folderName
		
		if(!DataFolderExists(cellPath))
			continue
		endif
		
		Variable deleted = CleanupCellTempWaves(cellPath, verbose)
		totalDeleted += deleted
	endfor
	
	if(verbose && totalDeleted > 0)
		Printf "  %s: %d waves deleted\r", samplePath, totalDeleted
	endif
	
	return totalDeleted
End

// CleanupSampleTempWaves - root
Function CleanupSampleTempWaves(sampleName, verbose)
	String sampleName
	Variable verbose
	
	return CleanupSampleTempWavesInPath("root", sampleName, verbose)
End

// CleanupCellTempWaves - 
Function CleanupCellTempWaves(cellPath, verbose)
	String cellPath
	Variable verbose
	
	if(!DataFolderExists(cellPath))
		return 0
	endif
	
	String savedDF = GetDataFolder(1)
	SetDataFolder $cellPath
	
	Variable deleted = 0
	Variable i
	String waveName
	
	// 
	// 1. LoadWave (wave0-wave9)
	for(i = 0; i <= 9; i += 1)
		waveName = "wave" + num2str(i)
		Wave/Z w = $waveName
		if(WaveExists(w))
			KillWaves/Z w
			deleted += 1
		endif
	endfor
	
	// 2. DataLoaderWave
	String tempWaves = "TM;TM_backup;frame;displacement;"
	for(i = 0; i < ItemsInList(tempWaves); i += 1)
		waveName = StringFromList(i, tempWaves)
		Wave/Z w = $waveName
		if(WaveExists(w))
			KillWaves/Z w
			deleted += 1
		endif
	endfor
	
	// 3. LocPrecisionWave
	String lpTempWaves = "Iback;BackN;VarLP;"
	for(i = 0; i < ItemsInList(lpTempWaves); i += 1)
		waveName = StringFromList(i, lpTempWaves)
		Wave/Z w = $waveName
		if(WaveExists(w))
			KillWaves/Z w
			deleted += 1
		endif
	endfor
	
	// 4. ORC (Rframe_S0_Ontime, Rframe_S0_Ontime_Seg0 )
	Variable numWaves = CountObjects("", 1)  // 1 = waves
	for(i = 0; i < numWaves; i += 1)
		waveName = GetIndexedObjName("", 1, i)
		if(GrepString(waveName, "^Rframe_S[0-9]+_Ontime"))
			Wave/Z w = $waveName
			if(WaveExists(w))
				KillWaves/Z w
				deleted += 1
				i -= 1  // 
				numWaves -= 1
			endif
		endif
	endfor
	
	// 5. Wave
	String fitTempWaves = "W_coef;W_sigma;T_Constraints;W_ParamConfidenceInterval;"
	for(i = 0; i < ItemsInList(fitTempWaves); i += 1)
		waveName = StringFromList(i, fitTempWaves)
		Wave/Z w = $waveName
		if(WaveExists(w))
			KillWaves/Z w
			deleted += 1
		endif
	endfor
	
	// 6. StepAllWave (StepAll_dt*_S*)
	numWaves = CountObjects("", 1)
	for(i = 0; i < numWaves; i += 1)
		waveName = GetIndexedObjName("", 1, i)
		if(GrepString(waveName, "^StepAll_dt[0-9]+_S[0-9]+"))
			Wave/Z w = $waveName
			if(WaveExists(w))
				KillWaves/Z w
				deleted += 1
				i -= 1
				numWaves -= 1
			endif
		endif
	endfor
	
	SetDataFolder $savedDF
	return deleted
End

// 
Function InitColFolders()
	String colBase = GetColBasePath()
	String ecBase = GetECBasePath()
	
	// Graph/Table/Layout
	// wave
	SMI_CloseAllGraphs()
	SMI_CloseAllTables()
	SMI_CloseAllLayouts()
	
	// 
	if(DataFolderExists(colBase))
		KillDataFolder/Z $colBase
	endif
	if(DataFolderExists(ecBase))
		KillDataFolder/Z $ecBase
	endif
	
	// 
	NewDataFolder/O $colBase
	NewDataFolder/O $ecBase
	
	NVAR ColIndex = root:ColIndex
	Printf "Colocalization folders initialized: Col%d, EC%d\r", ColIndex, ColIndex
End

// -----------------------------------------------------------------------------
// 
// -----------------------------------------------------------------------------
Function SMI_CloseAllGraphs()
	String name
	do
		name = WinName(0, 1)
		if(strlen(name) == 0)
			break
		endif
		DoWindow/K $name
	while(1)
End

Function SMI_CloseAllTables()
	String name
	do
		name = WinName(0, 2)
		if(strlen(name) == 0)
			break
		endif
		DoWindow/K $name
	while(1)
End

Function SMI_CloseAllLayouts()
	String name
	do
		name = WinName(0, 4)
		if(strlen(name) == 0)
			break
		endif
		DoWindow/K $name
	while(1)
End

Function SMI_KillAllWaves()
	KillWaves/A/F/Z
End

// -----------------------------------------------------------------------------
// 
// -----------------------------------------------------------------------------
Function SMI_RenameFoldersFromList()
	DFREF dfSave = GetDataFolderDFR()
	SetDataFolder root:
	
	String folder_list = ReplaceString(",", StringByKey("FOLDERS", DataFolderDir(1, root:)), ";")
	folder_list = SortList(folder_list, ";")
	folder_list = ListMatch(folder_list, "!Packages*", ";")
	folder_list = ListMatch(folder_list, "!Comparison*", ";")
	
	String s, before, after, Nbefore, Nafter
	Prompt s, "Data Folder List", popup, folder_list
	Prompt before, "Before"
	Prompt after, "After"
	DoPrompt "", s, before, after
	
	if(V_Flag != 0)
		Print "User Canceled"
		SetDataFolder dfSave
		return -1
	endif
	
	Wave/T FolderBefore = ListToTextWave(ListMatch(folder_list, "*"+before+"*"), ";")
	Print "Before:", numpnts(FolderBefore), "folders found"
	
	folder_list = ReplaceString(before, folder_list, after)
	Wave/T FolderAfter = ListToTextWave(ListMatch(folder_list, "*"+after+"*"), ";")
	
	Variable L = DimSize(FolderBefore, 0)
	Variable i
	
	for(i = 0; i < L; i += 1)
		Nbefore = FolderBefore[i]
		Nafter = FolderAfter[i]
		RenameFolderContents(Nbefore, Nafter, before, after)
	endfor
	
	SetDataFolder dfSave
End

static Function RenameFolderContents(parentBefore, parentAfter, before, after)
	String parentBefore, parentAfter, before, after
	
	SetDataFolder root:$(parentBefore)
	
	String folder_list = ReplaceString(",", StringByKey("FOLDERS", DataFolderDir(1)), ";")
	folder_list = SortList(folder_list, ";")
	folder_list = ListMatch(folder_list, "!Matrix*", ";")
	folder_list = ListMatch(folder_list, "!Results*", ";")
	
	Wave/T FolderList = ListToTextWave(ListMatch(folder_list, "*"+before+"*"), ";")
	Variable L = DimSize(FolderList, 0)
	Variable i
	String Nbefore, Nafter
	
	for(i = 0; i < L; i += 1)
		Nbefore = FolderList[i]
		Nafter = ReplaceString(before, Nbefore, after)
		RenameDataFolder root:$(parentBefore):$(Nbefore), $(Nafter)
	endfor
	
	RenameDataFolder root:$(parentBefore), $(parentAfter)
	SetDataFolder root:
End

// -----------------------------------------------------------------------------
// 
// -----------------------------------------------------------------------------
Function/S GetFolderListExcludingSystem()
	// 
	SetDataFolder root:
	String folder_list = ReplaceString(",", StringByKey("FOLDERS", DataFolderDir(1, root:)), ";")
	folder_list = ListMatch(folder_list, "!Packages*", ";")
	folder_list = ListMatch(folder_list, "!Comparison*", ";")
	folder_list = ListMatch(folder_list, "!Col*", ";")
	folder_list = ListMatch(folder_list, "!EC*", ";")
	return SortList(folder_list, ";")
End

Function CountDataFolders(SampleName)
	String SampleName
	
	If(!DataFolderExists("root:" + SampleName))
		return 0
	EndIf
	
	String savedDF = GetDataFolder(1)
	SetDataFolder root:$(SampleName)
	Variable totalFolders = CountObjects("", 4)
	Variable validCount = 0
	Variable i
	String folderName
	
	// 
	for(i = 0; i < totalFolders; i += 1)
		folderName = GetIndexedObjName("", 4, i)
		
		// 
		If(StringMatch(folderName, "Results") == 1)
			continue
		EndIf
		If(StringMatch(folderName, "Matrix") == 1)
			continue
		EndIf
		If(StringMatch(folderName, "Comparison") == 1)
			continue
		EndIf
		If(StringMatch(folderName, "Statistics") == 1)
			continue
		EndIf
		
		// SampleName +  
		Variable len = strlen(SampleName)
		If(strlen(folderName) > len)
			String prefix = folderName[0, len-1]
			String suffix = folderName[len, strlen(folderName)-1]
			If(StringMatch(prefix, SampleName) == 1)
				// 
				Variable num = str2num(suffix)
				If(numtype(num) == 0 && num > 0)
					validCount += 1
				EndIf
			EndIf
		EndIf
	endfor
	
	SetDataFolder $savedDF
	return validCount
End

// -----------------------------------------------------------------------------
// 
// basePath: "root"  "root:EC" 
// SampleName: 
// -----------------------------------------------------------------------------
Function CountDataFoldersInPath(basePath, SampleName)
	String basePath, SampleName
	
	String fullPath = basePath + ":" + SampleName
	If(!DataFolderExists(fullPath))
		return 0
	EndIf
	
	String savedDF = GetDataFolder(1)
	SetDataFolder $fullPath
	Variable totalFolders = CountObjects("", 4)
	Variable validCount = 0
	Variable i
	String folderName
	
	// 
	for(i = 0; i < totalFolders; i += 1)
		folderName = GetIndexedObjName("", 4, i)
		
		// 
		If(StringMatch(folderName, "Results") == 1)
			continue
		EndIf
		If(StringMatch(folderName, "Matrix") == 1)
			continue
		EndIf
		If(StringMatch(folderName, "Comparison") == 1)
			continue
		EndIf
		If(StringMatch(folderName, "Statistics") == 1)
			continue
		EndIf
		
		// SampleName +  
		Variable len = strlen(SampleName)
		If(strlen(folderName) > len)
			String prefix = folderName[0, len-1]
			String suffix = folderName[len, strlen(folderName)-1]
			If(StringMatch(prefix, SampleName) == 1)
				// 
				Variable num = str2num(suffix)
				If(numtype(num) == 0 && num > 0)
					validCount += 1
				EndIf
			EndIf
		EndIf
	endfor
	
	SetDataFolder $savedDF
	return validCount
End

Function IsNaN_Value(val)
	Variable val
	return numtype(val) == 2
End

Function IsValidWave(w)
	Wave/Z w
	return WaveExists(w) && numpnts(w) > 0
End

// -----------------------------------------------------------------------------
// 
// -----------------------------------------------------------------------------
Function ExtractNonNaN(sourceWave, destWaveName)
	Wave sourceWave
	String destWaveName
	
	Extract/O sourceWave, $destWaveName, numtype(sourceWave) == 0
End

Function RemoveNaNFromWave(w)
	Wave w
	
	Variable i, count = 0
	Variable n = numpnts(w)
	
	// NaN
	for(i = 0; i < n; i += 1)
		if(numtype(w[i]) == 0)
			count += 1
		endif
	endfor
	
	if(count == n)
		return 0  // NaN
	endif
	
	Make/FREE/D/N=(count) temp
	Variable j = 0
	for(i = 0; i < n; i += 1)
		if(numtype(w[i]) == 0)
			temp[j] = w[i]
			j += 1
		endif
	endfor
	
	Redimension/N=(count) w
	w = temp
	return n - count  // NaN
End

// -----------------------------------------------------------------------------
// HasValidData - waveNaN
// : 0
// -----------------------------------------------------------------------------
Function HasValidData(w)
	Wave/Z w
	
	if(!WaveExists(w) || numpnts(w) == 0)
		return 0
	endif
	
	WaveStats/Q w
	return V_npnts  // NaN
End

// -----------------------------------------------------------------------------
// EnsureWaveWithDefault - wave
// 0NaNComparison
// -----------------------------------------------------------------------------
Function EnsureWaveWithDefault(wName, defSize, defVal)
	String wName
	Variable defSize   // wave sizewave
	Variable defVal    // 0
	
	Wave/Z w = $wName
	if(!WaveExists(w))
		Make/O/D/N=(defSize) $wName = defVal
		Printf "EnsureWaveWithDefault: Created %s with default value %.4f\r", wName, defVal
		return 1  // 
	endif
	
	if(numpnts(w) == 0)
		Redimension/N=(defSize) w
		w = defVal
		Printf "EnsureWaveWithDefault: Resized empty wave %s with default value %.4f\r", wName, defVal
		return 2  // 
	endif
	
	// NaN0
	WaveStats/Q w
	if(V_npnts == 0)
		w = defVal
		Printf "EnsureWaveWithDefault: Replaced all NaN in %s with default value %.4f\r", wName, defVal
		return 3  // NaN
	endif
	
	return 0  // 
End

// -----------------------------------------------------------------------------
// CreateDummyResultWaves - wave
// 
// -----------------------------------------------------------------------------
Function CreateDummyResultWaves(folderPath, waveSuffix, numParams)
	String folderPath
	String waveSuffix  // "_S0", "_C1E" 
	Variable numParams // 
	
	String savedDF = GetDataFolder(1)
	
	if(!DataFolderExists(folderPath))
		NewDataFolder/O $folderPath
	endif
	SetDataFolder $folderPath
	
	// wave0
	String coefName = "coef" + waveSuffix
	Make/O/D/N=(numParams) $coefName = 0
	
	SetDataFolder $savedDF
	Printf "CreateDummyResultWaves: Created dummy waves in %s with suffix %s\r", folderPath, waveSuffix
	return 0
End

// -----------------------------------------------------------------------------
// SafeWaveStats - WaveStats/NaN
// : 0
// -----------------------------------------------------------------------------
Function SafeWaveStats(w, avgVar, sdVar, semVar, nVar)
	Wave/Z w
	Variable &avgVar, &sdVar, &semVar, &nVar
	
	// 
	avgVar = 0
	sdVar = 0
	semVar = 0
	nVar = 0
	
	if(!WaveExists(w) || numpnts(w) == 0)
		return 0
	endif
	
	WaveStats/Q w
	
	if(V_npnts == 0)
		// NaN
		return 0
	endif
	
	avgVar = V_avg
	sdVar = V_sdev
	nVar = V_npnts
	semVar = (nVar > 1) ? V_sdev / sqrt(nVar) : 0
	
	return V_npnts
End

// -----------------------------------------------------------------------------
// 
// -----------------------------------------------------------------------------
Function CalculateStats(w, avgVar, sdVar, semVar, nVar)
	Wave w
	Variable &avgVar, &sdVar, &semVar, &nVar
	
	WaveStats/Q w
	avgVar = V_avg
	sdVar = V_sdev
	nVar = V_npnts
	semVar = (nVar > 0) ? V_sdev / sqrt(nVar) : 0
End

// -----------------------------------------------------------------------------
// 
// -----------------------------------------------------------------------------
Function SafeFitWithErrorHandling(fitFunc, dataWave, coefWave, [xWave, holdString, constraints])
	String fitFunc
	Wave dataWave, coefWave
	Wave/Z xWave
	String holdString, constraints
	
	Variable V_FitError = 0
	Variable V_FitQuitReason = 0
	Variable useConstraints, numConstraints, c, err
	
	// 
	if(ParamIsDefault(holdString))
		holdString = ""
	endif
	if(ParamIsDefault(constraints))
		constraints = ""
	endif
	
	// Wave
	useConstraints = strlen(constraints) > 0
	if(useConstraints)
		numConstraints = ItemsInList(constraints, ";")
		Make/T/O/N=(numConstraints) T_Constraints
		for(c = 0; c < numConstraints; c += 1)
			T_Constraints[c] = StringFromList(c, constraints, ";")
		endfor
	endif
	
	// 
	try
		if(ParamIsDefault(xWave))
			if(useConstraints)
				if(strlen(holdString) > 0)
					FuncFit/Q/N/W=2/H=holdString $fitFunc, coefWave, dataWave /C=T_Constraints; AbortOnRTE
				else
					FuncFit/Q/N/W=2 $fitFunc, coefWave, dataWave /C=T_Constraints; AbortOnRTE
				endif
			else
				if(strlen(holdString) > 0)
					FuncFit/Q/N/W=2/H=holdString $fitFunc, coefWave, dataWave; AbortOnRTE
				else
					FuncFit/Q/N/W=2 $fitFunc, coefWave, dataWave; AbortOnRTE
				endif
			endif
		else
			if(useConstraints)
				if(strlen(holdString) > 0)
					FuncFit/Q/N/W=2/H=holdString $fitFunc, coefWave, dataWave /X=xWave /C=T_Constraints; AbortOnRTE
				else
					FuncFit/Q/N/W=2 $fitFunc, coefWave, dataWave /X=xWave /C=T_Constraints; AbortOnRTE
				endif
			else
				if(strlen(holdString) > 0)
					FuncFit/Q/N/W=2/H=holdString $fitFunc, coefWave, dataWave /X=xWave; AbortOnRTE
				else
					FuncFit/Q/N/W=2 $fitFunc, coefWave, dataWave /X=xWave; AbortOnRTE
				endif
			endif
		endif
	catch
		err = GetRTError(1)
		Printf ": %s\r", GetErrMessage(err)
		KillWaves/Z T_Constraints
		return -1
	endtry
	
	// 
	KillWaves/Z T_Constraints
	
	// 
	if(V_FitError != 0)
		Printf " (V_FitError=%d, V_FitQuitReason=%d)\r", V_FitError, V_FitQuitReason
		return -1
	endif
	
	return 0  // 
End

// -----------------------------------------------------------------------------
// 
// -----------------------------------------------------------------------------
Function ShowProgress(current, total, message)
	Variable current, total
	String message
	
	Variable percent = (current / total) * 100
	Printf "\r%s: %d/%d (%.1f%%)", message, current, total, percent
End

Function EndProgress()
	Print ""  // 
End

// -----------------------------------------------------------------------------
// 
// -----------------------------------------------------------------------------
Function/S GetCurrentSampleName()
	// gCurrentSampleName
	SVAR/Z gCurrentSample = root:gCurrentSampleName
	if(SVAR_Exists(gCurrentSample) && strlen(gCurrentSample) > 0)
		if(DataFolderExists("root:" + gCurrentSample))
			return gCurrentSample
		endif
	endif
	
	// CurrentSampleName
	SVAR/Z sampleName = root:CurrentSampleName
	if(SVAR_Exists(sampleName) && strlen(sampleName) > 0)
		if(DataFolderExists("root:" + sampleName))
			return sampleName
		endif
	endif
	
	// gSampleNameInput
	SVAR/Z gSampleInput = root:gSampleNameInput
	if(SVAR_Exists(gSampleInput) && strlen(gSampleInput) > 0)
		if(DataFolderExists("root:" + gSampleInput))
			return gSampleInput
		endif
	endif
	
	return ""
End

Function SetCurrentSampleName(newName)
	String newName
	
	SVAR/Z sampleName = root:CurrentSampleName
	if(!SVAR_Exists(sampleName))
		String/G root:CurrentSampleName = ""
		SVAR sampleName = root:CurrentSampleName
	endif
	
	sampleName = newName
	Print ": " + newName
End

// -----------------------------------------------------------------------------
// 
// -----------------------------------------------------------------------------
Function/S ExtractFolderName(fullPath)
	String fullPath
	
	// 
	if(StringMatch(fullPath, "*:") || StringMatch(fullPath, "*/") || StringMatch(fullPath, "*\\"))
		fullPath = fullPath[0, strlen(fullPath)-2]
	endif
	
	// Mac/Win
	Variable lastColon = strsearch(fullPath, ":", Inf, 1)
	Variable lastSlash = strsearch(fullPath, "/", Inf, 1)
	Variable lastBackslash = strsearch(fullPath, "\\", Inf, 1)
	
	Variable lastSep = max(max(lastColon, lastSlash), lastBackslash)
	
	String folderName
	if(lastSep < 0)
		//  - 
		folderName = fullPath
	else
		folderName = fullPath[lastSep+1, strlen(fullPath)-1]
	endif
	
	// Igor Pro
	folderName = CleanSampleName(folderName)
	
	return folderName
End

// -----------------------------------------------------------------------------
// PopupMenu
// -----------------------------------------------------------------------------
Function/S GetAnalyzedSampleList()
	String sampleList = ""
	String currentDF = GetDataFolder(1)
	
	SetDataFolder root:
	
	// root
	Variable numFolders = CountObjects(":", 4)  // 4 = folders
	Variable i
	String folderName
	
	for(i = 0; i < numFolders; i += 1)
		folderName = GetIndexedObjName(":", 4, i)
		if(IsSystemFolder(folderName))
			continue
		endif
		// Exclude Index_* folders (drift correction index data)
		if(StringMatch(folderName, "Index_*") == 1)
			continue
		endif
		if(strlen(sampleList) > 0)
			sampleList += ";"
		endif
		sampleList += folderName
	endfor
	
	SetDataFolder $currentDF
	
	if(strlen(sampleList) == 0)
		sampleList = "(No samples loaded)"
	endif
	
	return sampleList
End

// Get list of Index_* folders (for drift correction index selection)
Function/S GetIndexFolderList()
	String indexList = ""
	String currentDF = GetDataFolder(1)
	
	SetDataFolder root:
	Variable numFolders = CountObjects(":", 4)
	Variable i
	String folderName
	
	for(i = 0; i < numFolders; i += 1)
		folderName = GetIndexedObjName(":", 4, i)
		if(StringMatch(folderName, "Index_*") == 1)
			if(strlen(indexList) > 0)
				indexList += ";"
			endif
			indexList += folderName
		endif
	endfor
	
	SetDataFolder $currentDF
	return indexList
End
// WaveMatrix/Results
// 
// 
// SDSEM
// 
//
// 
// basePath = "root"      → root:SampleName:FolderName → root:SampleName:Matrix/Results
// basePath = "root:EC"   → root:EC:SampleName:FolderName → root:EC:SampleName:Matrix/Results
// basePath = "root:Col"  → root:Col:SampleName:FolderName → root:Col:SampleName:Matrix/Results
// basePath = "root:seg0" → root:seg0:SampleName:FolderName → root:seg0:SampleName:Matrix/Results
// 
// 
// basePath: "root", "root:EC", "root:Col", "root:seg0"
// sampleName: 
// waveNameList: Wave
//               Wave
//
// 
// Matrix: *_m2D: bins×cells  3D: rows×cols×cells
// Results: *_m_avg, *_m_sd, *_m_sem, *_m_n
// -----------------------------------------------------------------------------
Function StatsResultsMatrix(basePath, sampleName, waveNameList)
	String basePath      // "root", "root:EC", "root:Col", "root:seg0", etc.
	String sampleName    // e.g., "Sample1"
	String waveNameList  // e.g., "Wave1;Wave2;..." or "" for all waves
	
	String savedDF = GetDataFolder(1)
	
	// 
	String samplePath
	if(StringMatch(basePath, "root"))
		samplePath = "root:" + sampleName
	else
		samplePath = basePath + ":" + sampleName
	endif
	
	if(!DataFolderExists(samplePath))
		Printf "StatsResultsMatrix: %s does not exist\r", samplePath
		SetDataFolder $savedDF
		return -1
	endif
	
	// Matrix/Results
	if(!DataFolderExists(samplePath + ":Matrix"))
		NewDataFolder $(samplePath + ":Matrix")
	endif
	if(!DataFolderExists(samplePath + ":Results"))
		NewDataFolder $(samplePath + ":Results")
	endif
	
	// 
	Variable numCells = 0
	Variable m = 0
	do
		String folderName = sampleName + num2str(m + 1)
		String cellPath = samplePath + ":" + folderName
		if(!DataFolderExists(cellPath))
			break
		endif
		numCells += 1
		m += 1
	while(1)
	
	if(numCells == 0)
		Printf "StatsResultsMatrix: No cell folders found for %s\r", sampleName
		SetDataFolder $savedDF
		return -1
	endif
	
	Printf "StatsResultsMatrix: %s (%s), cells=%d\r", sampleName, basePath, numCells
	
	// Wave
	String processWaveList = ""
	
	if(strlen(waveNameList) == 0)
		// Wave: Wave
		String firstCellPath = samplePath + ":" + sampleName + "1"
		SetDataFolder $firstCellPath
		Variable numWavesInFolder = CountObjects("", 1)
		Variable i
		
		for(i = 0; i < numWavesInFolder; i += 1)
			String wName = GetIndexedObjName("", 1, i)
			if(strlen(wName) == 0)
				continue
			endif
			
			// 
			Variable exc0 = StringMatch(wName, "*Trace*")
			Variable exc1 = StringMatch(wName, "*GFit*")
			Variable exc2 = StringMatch(wName, "*sig*")
			Variable exc3 = StringMatch(wName, "*name*")
			Variable exc4 = StringMatch(wName, "*_um*")  // "_um"CumOnEvent
			Variable exc5 = StringMatch(wName, "*ROI*")
			Variable exc6 = StringMatch(wName, "*Image*")
			Variable exc7 = StringMatch(wName, "*_x")
			Variable exc8 = StringMatch(wName, "*Distance*")
			Variable exc9 = StringMatch(wName, "*Colocalize*")
			
			if(exc0 == 0 && exc1 == 0 && exc2 == 0 && exc3 == 0 && exc4 == 0 && exc5 == 0 && exc6 == 0 && exc7 == 0 && exc8 == 0 && exc9 == 0)
				Wave/Z testWave = $wName
				if(WaveExists(testWave) && WaveType(testWave) != 0)  // Wave
					processWaveList += wName + ";"
				endif
			endif
		endfor
	else
		processWaveList = waveNameList
	endif
	
	// Wave
	Variable numWaves = ItemsInList(processWaveList, ";")
	Variable w, c, r, col
	
	for(w = 0; w < numWaves; w += 1)
		String waveName = StringFromList(w, processWaveList, ";")
		if(strlen(waveName) == 0)
			continue
		endif
		
		// Wave
		String firstPath = samplePath + ":" + sampleName + "1:" + waveName
		Wave/Z firstWave = $firstPath
		
		if(!WaveExists(firstWave))
			continue
		endif
		
		Variable RowSize = DimSize(firstWave, 0)
		Variable ColumnSize = DimSize(firstWave, 1)
		
		// Matrix
		String matrixName = waveName + "_m"
		SetDataFolder $(samplePath + ":Matrix")
		
		if(ColumnSize == 0)
			// 1D Wave → 2D Matrix (rows × cells)
			Make/O/D/N=(RowSize, numCells) $matrixName = NaN
		else
			// 2D Wave → 3D Matrix (rows × cols × cells)
			Make/O/D/N=(RowSize, ColumnSize, numCells) $matrixName = NaN
		endif
		Wave Matrix = $matrixName
		
		// 
		Variable validCells = 0
		for(c = 0; c < numCells; c += 1)
			folderName = sampleName + num2str(c + 1)
			String srcPath = samplePath + ":" + folderName + ":" + waveName
			Wave/Z srcWave = $srcPath
			
			if(!WaveExists(srcWave))
				continue
			endif
			
			if(ColumnSize == 0)
				// 1D Wave
				Variable copyRows = min(RowSize, DimSize(srcWave, 0))
				for(r = 0; r < copyRows; r += 1)
					Matrix[r][validCells] = srcWave[r]
				endfor
			else
				// 2D Wave
				copyRows = min(RowSize, DimSize(srcWave, 0))
				Variable copyCols = min(ColumnSize, DimSize(srcWave, 1))
				for(r = 0; r < copyRows; r += 1)
					for(col = 0; col < copyCols; col += 1)
						Matrix[r][col][validCells] = srcWave[r][col]
					endfor
				endfor
			endif
			validCells += 1
		endfor
		
		// Matrix
		if(validCells > 0 && validCells < numCells)
			if(ColumnSize == 0)
				Redimension/N=(RowSize, validCells) Matrix
			else
				Redimension/N=(RowSize, ColumnSize, validCells) Matrix
			endif
		endif
		
		// 
		if(validCells > 0)
			String avgName = waveName + "_m_avg"
			String sdName = waveName + "_m_sd"
			String semName = waveName + "_m_sem"
			String nName = waveName + "_m_n"
			
			SetDataFolder $(samplePath + ":Results")
			
			Variable LayerSize = DimSize(Matrix, 2)
			ColumnSize = DimSize(Matrix, 1)
			RowSize = DimSize(Matrix, 0)
			
			if(LayerSize == 0)
				// 2D Matrix: 
				Make/O/D/N=(RowSize) $avgName = NaN
				Make/O/D/N=(RowSize) $sdName = NaN
				Make/O/D/N=(RowSize) $semName = NaN
				Make/O/D/N=(RowSize) $nName = NaN
				
				Wave Avg = $avgName
				Wave SD = $sdName
				Wave SEM = $semName
				Wave Npnts = $nName
				
				for(i = 0; i < RowSize; i += 1)
					ImageStats/G={i, i, 0, ColumnSize-1} Matrix
					Avg[i] = V_avg
					SD[i] = V_sdev
					if(V_npnts > 0)
						SEM[i] = V_sdev / sqrt(V_npnts)
					endif
					Npnts[i] = V_npnts
				endfor
				
				// SetScaleWave
				CopyScales firstWave, Avg, SD, SEM, Npnts
			elseif(LayerSize > 1)
				// 3D Matrix: 
				Make/O/D/N=(RowSize, ColumnSize) $avgName = NaN
				Make/O/D/N=(RowSize, ColumnSize) $sdName = NaN
				Make/O/D/N=(RowSize, ColumnSize) $semName = NaN
				Make/O/D/N=(RowSize, ColumnSize) $nName = NaN
				
				Wave Avg = $avgName
				Wave SD = $sdName
				Wave SEM = $semName
				Wave Npnts = $nName
				
				if(WaveDims(Matrix) >= 3)
					ImageTransform/METH=1 averageImage Matrix
				else
					Printf "  WARNING: ImageTransform skipped in StatsResultsMatrix — %s is %dD (LayerSize=%d)\r", waveName, WaveDims(Matrix), LayerSize
				endif
				Wave/Z M_AveImage, M_StdvImage
				
				if(WaveExists(M_AveImage) && WaveExists(M_StdvImage))
					Avg[][] = M_AveImage[p][q]
					SD[][] = M_StdvImage[p][q]
					SEM[][] = M_StdvImage[p][q] / sqrt(LayerSize)
					Npnts[][] = LayerSize
				endif
				
				KillWaves/Z M_AveImage, M_StdvImage
				
				// SetScaleWave
				CopyScales firstWave, Avg, SD, SEM, Npnts
			endif
		endif
	endfor
	
	Printf "  Statistics completed: %s:Matrix, %s:Results\r", samplePath, samplePath
	
	SetDataFolder $savedDF
	return 0
End

// =============================================================================
// Comparison
// =============================================================================
// Matrix/ResultsComparison
// 
// basePath:
//   "root:"       → root:Comparison:
//   "root:EC:"    → root:EC:Comparison:
//   "root:EC1:"   → root:EC:Comparison:
//   "root:seg:"   → root:seg:Comparison:
//   "root:seg1:"  → root:seg:Comparison:
// =============================================================================

// -----------------------------------------------------------------------------
// GetComparisonPathFromBase - basePathComparison
// -----------------------------------------------------------------------------
Function/S GetComparisonPathFromBase(basePath)
	String basePath
	
	// 
	if(StringMatch(basePath[strlen(basePath)-1], ":") == 0)
		basePath += ":"
	endif
	
	// Comparison
	// root:, root:EC*, root:Seg*  root:Comparison: 
	// GrepString (?i)
	if(StringMatch(basePath, "root:") || GrepString(basePath, "(?i)^root:EC[0-9]*:$") || GrepString(basePath, "(?i)^root:Seg[0-9]*:$"))
		return "root:Comparison:"
	else
		// : basePathComparison
		return basePath + "Comparison:"
	endif
End

// -----------------------------------------------------------------------------
// GetSampleListFromBase - basePath
// -----------------------------------------------------------------------------
// List_C1/C2
Function/S GetSampleListFromBase(basePath)
	String basePath
	
	String savedDF = GetDataFolder(1)
	
	// 
	if(StringMatch(basePath[strlen(basePath)-1], ":") == 0)
		basePath += ":"
	endif
	
	String sampleList = ""
	Variable i
	
	// basePath"root:"List_C1/C2
	if(StringMatch(basePath, "root:"))
		// List_C1/C2Compare
		Wave/T/Z List_C1 = root:List_C1
		Wave/T/Z List_C2 = root:List_C2
		
		if(WaveExists(List_C1) && WaveExists(List_C2))
			// List_C1/C2
			Variable numPairs = min(numpnts(List_C1), numpnts(List_C2))
			for(i = 0; i < numPairs; i += 1)
				String smplA = List_C1[i]
				String smplB = List_C2[i]
				if(strlen(smplA) > 0 && FindListItem(smplA, sampleList) < 0)
					if(StringMatch(smplA, "Tif_*") == 0)
						sampleList += smplA + ";"
					endif
				endif
				if(strlen(smplB) > 0 && FindListItem(smplB, sampleList) < 0)
					if(StringMatch(smplB, "Tif_*") == 0)
						sampleList += smplB + ";"
					endif
				endif
			endfor
			return sampleList
		endif
		
		// List_C1/C2GetSampleFolderList
		return GetSampleFolderList()
	endif
	
	// basePath != "root:" : basePath
	if(!DataFolderExists(basePath))
		return ""
	endif
	
	SetDataFolder $basePath
	Variable numFolders = CountObjects("", 4)
	for(i = 0; i < numFolders; i += 1)
		String folderName = GetIndexedObjName("", 4, i)
		// Matrix/Results/Comparison
		if(StringMatch(folderName, "Matrix") || StringMatch(folderName, "Results") || StringMatch(folderName, "Comparison"))
			continue
		endif
		// Matrix subfolder exists
		if(DataFolderExists(basePath + folderName + ":Matrix"))
			sampleList += folderName + ";"
		endif
	endfor
	SetDataFolder $savedDF
	
	return sampleList
End

// -----------------------------------------------------------------------------
// GetSampleListForChannel - 
// -----------------------------------------------------------------------------
// channelIdx: 0=Ch1 (List_C1), 1=Ch2 (List_C2)
// Colocalization Compare: Ch1List_C1
Function/S GetSampleListForChannel(channelIdx)
	Variable channelIdx
	
	Wave/T/Z List_C1 = root:List_C1
	Wave/T/Z List_C2 = root:List_C2
	
	if(!WaveExists(List_C1) || !WaveExists(List_C2))
		return ""
	endif
	
	Wave/T srcList
	if(channelIdx == 0)
		Wave/T srcList = List_C1
	else
		Wave/T srcList = List_C2
	endif
	
	String sampleList = ""
	Variable i, numItems = numpnts(srcList)
	
	for(i = 0; i < numItems; i += 1)
		String smpl = srcList[i]
		if(strlen(smpl) > 0 && FindListItem(smpl, sampleList) < 0)
			sampleList += smpl + ";"
		endif
	endfor
	
	return sampleList
End

// -----------------------------------------------------------------------------
// EnsureComparisonFolderForBase - Comparison
// -----------------------------------------------------------------------------
Function EnsureComparisonFolderForBase(basePath)
	String basePath
	
	String compPath = GetComparisonPathFromBase(basePath)
	
	// 
	String parentPath = RemoveEnding(compPath, "Comparison:")
	if(strlen(parentPath) > 0 && !StringMatch(parentPath, "root:"))
		if(!DataFolderExists(parentPath))
			NewDataFolder/O $RemoveEnding(parentPath, ":")
		endif
	endif
	
	// Comparison
	if(!DataFolderExists(compPath))
		NewDataFolder/O $RemoveEnding(compPath, ":")
	endif
	
	return 0
End

// -----------------------------------------------------------------------------
// ExtractMatrixRowToComparison - Matrix waveComparison
// -----------------------------------------------------------------------------
// rowIndex:  (-1 = 1D wave2D wave)
// : wave
Function/S ExtractMatrixRowToComparison(basePath, matrixName, rowIndex)
	String basePath
	String matrixName
	Variable rowIndex
	
	String savedDF = GetDataFolder(1)
	
	// 
	if(StringMatch(basePath[strlen(basePath)-1], ":") == 0)
		basePath += ":"
	endif
	
	// Comparison
	EnsureComparisonFolderForBase(basePath)
	String compPath = GetComparisonPathFromBase(basePath)
	
	// 
	String sampleList = GetSampleListFromBase(basePath)
	Variable numSamples = ItemsInList(sampleList)
	
	if(numSamples == 0)
		Print "ExtractMatrixRowToComparison: No samples found in " + basePath
		return ""
	endif
	
	String createdWaves = ""
	Variable i, j, nCells
	
	for(i = 0; i < numSamples; i += 1)
		String smplName = StringFromList(i, sampleList)
		String srcPath = basePath + smplName + ":Matrix:" + matrixName
		Wave/Z srcWave = $srcPath
		
		if(!WaveExists(srcWave))
			continue
		endif
		
		String dstName = smplName + "_" + matrixName
		String dstPath = compPath + dstName
		
		Variable dims = WaveDims(srcWave)
		
		if(dims == 1)
			// 1D wave: NaN
			SetDataFolder $compPath
			Duplicate/O srcWave, $dstName
			WaveTransform zapNaNs $dstName
			createdWaves += dstName + ";"
		elseif(dims == 2)
			nCells = DimSize(srcWave, 1)
			
			if(rowIndex < 0)
				// 2D wave
				Duplicate/O srcWave, $dstPath
				createdWaves += dstName + ";"
			else
				// 1D wave
				SetDataFolder $compPath
				Make/O/D/N=(nCells) $dstName = NaN
				Wave dstWave = $dstName
				
				if(rowIndex < DimSize(srcWave, 0))
					for(j = 0; j < nCells; j += 1)
						dstWave[j] = srcWave[rowIndex][j]
					endfor
				endif
				
				// NaN
				WaveTransform zapNaNs dstWave
				
				createdWaves += dstName + ";"
				SetDataFolder $savedDF
			endif
		endif
	endfor
	
	SetDataFolder $savedDF
	return createdWaves
End

// -----------------------------------------------------------------------------
// ExtractResultsToComparison - Results (avg/sem) Comparison
// -----------------------------------------------------------------------------
// rowIndex:  (-1 = )
// : wave
Function/S ExtractResultsToComparison(basePath, matrixName, rowIndex)
	String basePath
	String matrixName
	Variable rowIndex
	
	String savedDF = GetDataFolder(1)
	
	// 
	if(StringMatch(basePath[strlen(basePath)-1], ":") == 0)
		basePath += ":"
	endif
	
	// Comparison
	EnsureComparisonFolderForBase(basePath)
	String compPath = GetComparisonPathFromBase(basePath)
	
	// 
	String sampleList = GetSampleListFromBase(basePath)
	Variable numSamples = ItemsInList(sampleList)
	
	if(numSamples == 0)
		return ""
	endif
	
	String createdWaves = ""
	Variable i
	
	for(i = 0; i < numSamples; i += 1)
		String smplName = StringFromList(i, sampleList)
		
		// avg wave
		String avgSrcPath = basePath + smplName + ":Results:" + matrixName + "_avg"
		Wave/Z avgSrc = $avgSrcPath
		
		if(WaveExists(avgSrc))
			String avgDstName = smplName + "_" + matrixName + "_avg"
			String avgDstPath = compPath + avgDstName
			
			if(rowIndex < 0)
				// 
				Duplicate/O avgSrc, $avgDstPath
			else
				// 
				SetDataFolder $compPath
				Variable/G $avgDstName = NaN
				NVAR avgVal = $avgDstName
				if(rowIndex < numpnts(avgSrc))
					avgVal = avgSrc[rowIndex]
				endif
				SetDataFolder $savedDF
			endif
			createdWaves += avgDstName + ";"
		endif
		
		// sem wave
		String semSrcPath = basePath + smplName + ":Results:" + matrixName + "_sem"
		Wave/Z semSrc = $semSrcPath
		
		if(WaveExists(semSrc))
			String semDstName = smplName + "_" + matrixName + "_sem"
			String semDstPath = compPath + semDstName
			
			if(rowIndex < 0)
				Duplicate/O semSrc, $semDstPath
			else
				SetDataFolder $compPath
				Variable/G $semDstName = NaN
				NVAR semVal = $semDstName
				if(rowIndex < numpnts(semSrc))
					semVal = semSrc[rowIndex]
				endif
				SetDataFolder $savedDF
			endif
			createdWaves += semDstName + ";"
		endif
	endfor
	
	SetDataFolder $savedDF
	return createdWaves
End

// -----------------------------------------------------------------------------
// ExtractToComparison - MatrixResults(avg/sem)
// -----------------------------------------------------------------------------
// basePath: "root:", "root:EC:", "root:EC1:" 
// matrixName: Matrix wave (e.g., "HMMP_m", "mean_osize_S0_C1E_m")
// rowIndex:  (-1 = )
// : wave
Function/S ExtractToComparison(basePath, matrixName, rowIndex)
	String basePath
	String matrixName
	Variable rowIndex
	
	String createdWaves = ""
	
	// Matrix wave
	createdWaves += ExtractMatrixRowToComparison(basePath, matrixName, rowIndex)
	
	// Results (avg/sem) 
	createdWaves += ExtractResultsToComparison(basePath, matrixName, rowIndex)
	
	return createdWaves
End

// -----------------------------------------------------------------------------
// ExtractAllSamplesToComparison - wave
// -----------------------------------------------------------------------------
// Summary wave: {matrixName}_mean, {matrixName}_sem, {matrixName}_colors
// : {Sample}_{matrixName}
// -----------------------------------------------------------------------------
// ExtractAllSamplesToComparison - wave
// -----------------------------------------------------------------------------
// basePath:  ("root:", "root:EC:" )
// matrixName: Matrix wave (e.g., "mean_osize_m")
// rowIndex:  (-1=/1D wave)
// outputPrefix: wave (=matrixName)
// createSummary: 1 = mean/sem/colors wave
//
// :
//   : {Sample}_{outputPrefix}
//   : {outputPrefix}_SampleNames, {outputPrefix}_mean, {outputPrefix}_sem, {outputPrefix}_colors
Function/S ExtractAllSamplesToComparison(basePath, matrixName, rowIndex, outputPrefix, createSummary)
	String basePath
	String matrixName
	Variable rowIndex
	String outputPrefix
	Variable createSummary
	
	// sampleListGetSampleListFromBase()
	String sampleList = GetSampleListFromBase(basePath)
	return ExtractAllSamplesToComparisonEx(basePath, matrixName, rowIndex, outputPrefix, createSummary, sampleList)
End

// -----------------------------------------------------------------------------
// ExtractAllSamplesToComparisonEx - 
// -----------------------------------------------------------------------------
// sampleList: 
Function/S ExtractAllSamplesToComparisonEx(basePath, matrixName, rowIndex, outputPrefix, createSummary, sampleList)
	String basePath
	String matrixName
	Variable rowIndex
	String outputPrefix
	Variable createSummary
	String sampleList
	
	String savedDF = GetDataFolder(1)
	
	// 
	if(StringMatch(basePath[strlen(basePath)-1], ":") == 0)
		basePath += ":"
	endif
	
	// outputPrefixmatrixName
	if(strlen(outputPrefix) == 0)
		outputPrefix = matrixName
	endif
	
	// Comparison folder
	EnsureComparisonFolderForBase(basePath)
	String compPath = GetComparisonPathFromBase(basePath)
	
	Variable numSamples = ItemsInList(sampleList)
	
	if(numSamples == 0)
		Print "ExtractAllSamplesToComparisonEx: No samples in list"
		return ""
	endif
	
	// sampleList
	String cellWaves = ExtractMatrixRowWithSampleList(basePath, matrixName, rowIndex, outputPrefix, sampleList)
	
	if(!createSummary)
		return cellWaves
	endif
	
	// wave
	SetDataFolder $compPath
	
	// SampleNames wave
	String sampleNamesWave = outputPrefix + "_SampleNames"
	Make/O/T/N=(numSamples) $sampleNamesWave
	Wave/T SampleNames = $sampleNamesWave
	
	// mean/sem/colors wave
	String meanWaveName = outputPrefix + "_mean"
	String semWaveName = outputPrefix + "_sem"
	String colorsWaveName = outputPrefix + "_colors"
	
	Make/O/D/N=(numSamples) $meanWaveName = NaN
	Make/O/D/N=(numSamples) $semWaveName = NaN
	Make/O/N=(numSamples, 3) $colorsWaveName = 0
	
	Wave meanW = $meanWaveName
	Wave semW = $semWaveName
	Wave colorsW = $colorsWaveName
	
	Variable i
	for(i = 0; i < numSamples; i += 1)
		String smplName = StringFromList(i, sampleList)
		SampleNames[i] = smplName
		
		// avg/sem
		String avgSrcPath = basePath + smplName + ":Results:" + matrixName + "_avg"
		String semSrcPath = basePath + smplName + ":Results:" + matrixName + "_sem"
		Wave/Z avgSrc = $avgSrcPath
		Wave/Z semSrc = $semSrcPath
		
		if(WaveExists(avgSrc) && WaveExists(semSrc))
			if(rowIndex < 0)
				// 1D wave
				meanW[i] = avgSrc[0]
				semW[i] = semSrc[0]
			elseif(rowIndex < numpnts(avgSrc))
				meanW[i] = avgSrc[rowIndex]
				semW[i] = semSrc[rowIndex]
			endif
		else
			// Results
			String cellDataName = outputPrefix + "_" + smplName
			Wave/Z cellData = $cellDataName
			if(WaveExists(cellData) && numpnts(cellData) > 0)
				WaveStats/Q cellData
				meanW[i] = V_avg
				if(V_npnts > 1)
					semW[i] = V_sdev / sqrt(V_npnts)
				endif
			endif
		endif
	endfor
	
	SetDataFolder $savedDF
	
	return cellWaves + sampleNamesWave + ";" + meanWaveName + ";" + semWaveName + ";" + colorsWaveName + ";"
End

// -----------------------------------------------------------------------------
// ExtractMatrixRowWithSampleList - Matrix
// -----------------------------------------------------------------------------
Function/S ExtractMatrixRowWithSampleList(basePath, matrixName, rowIndex, outputPrefix, sampleList)
	String basePath
	String matrixName
	Variable rowIndex
	String outputPrefix
	String sampleList
	
	String savedDF = GetDataFolder(1)
	
	// 
	if(StringMatch(basePath[strlen(basePath)-1], ":") == 0)
		basePath += ":"
	endif
	
	// outputPrefixmatrixName
	if(strlen(outputPrefix) == 0)
		outputPrefix = matrixName
	endif
	
	// Comparison
	EnsureComparisonFolderForBase(basePath)
	String compPath = GetComparisonPathFromBase(basePath)
	
	Variable numSamples = ItemsInList(sampleList)
	
	if(numSamples == 0)
		return ""
	endif
	
	String createdWaves = ""
	Variable i, j, nCells
	
	for(i = 0; i < numSamples; i += 1)
		String smplName = StringFromList(i, sampleList)
		String srcPath = basePath + smplName + ":Matrix:" + matrixName
		Wave/Z srcWave = $srcPath
		
		if(!WaveExists(srcWave))
			continue
		endif
		
		// prefix_ CompareD/CompareL
		String dstName = outputPrefix + "_" + smplName
		String dstPath = compPath + dstName
		
		Variable dims = WaveDims(srcWave)
		
		if(dims == 1)
			// 1D wave: 
			SetDataFolder $compPath
			Duplicate/O srcWave, $dstName
			WaveTransform zapNaNs $dstName
			createdWaves += dstName + ";"
		elseif(dims == 2)
			nCells = DimSize(srcWave, 1)
			
			if(rowIndex < 0)
				// 2D wave
				Duplicate/O srcWave, $dstPath
				createdWaves += dstName + ";"
			else
				// 1D wave
				SetDataFolder $compPath
				Make/O/D/N=(nCells) $dstName = NaN
				Wave dstWave = $dstName
				
				if(rowIndex < DimSize(srcWave, 0))
					for(j = 0; j < nCells; j += 1)
						dstWave[j] = srcWave[rowIndex][j]
					endfor
				endif
				
				// NaN
				WaveTransform zapNaNs dstWave
				
				createdWaves += dstName + ";"
			endif
		endif
	endfor
	
	SetDataFolder $savedDF
	return createdWaves
End

// -----------------------------------------------------------------------------
// ExtractMatrixRowToComparisonWithPrefix - outputPrefixMatrix wave
// -----------------------------------------------------------------------------
Function/S ExtractMatrixRowToComparisonWithPrefix(basePath, matrixName, rowIndex, outputPrefix)
	String basePath
	String matrixName
	Variable rowIndex
	String outputPrefix
	
	String savedDF = GetDataFolder(1)
	
	// 
	if(StringMatch(basePath[strlen(basePath)-1], ":") == 0)
		basePath += ":"
	endif
	
	// outputPrefixmatrixName
	if(strlen(outputPrefix) == 0)
		outputPrefix = matrixName
	endif
	
	// Comparison
	EnsureComparisonFolderForBase(basePath)
	String compPath = GetComparisonPathFromBase(basePath)
	
	// 
	String sampleList = GetSampleListFromBase(basePath)
	Variable numSamples = ItemsInList(sampleList)
	
	if(numSamples == 0)
		Print "ExtractMatrixRowToComparisonWithPrefix: No samples found in " + basePath
		return ""
	endif
	
	String createdWaves = ""
	Variable i, j, nCells
	
	for(i = 0; i < numSamples; i += 1)
		String smplName = StringFromList(i, sampleList)
		String srcPath = basePath + smplName + ":Matrix:" + matrixName
		Wave/Z srcWave = $srcPath
		
		if(!WaveExists(srcWave))
			continue
		endif
		
		// wave: {Sample}_{outputPrefix}
		String dstName = smplName + "_" + outputPrefix
		String dstPath = compPath + dstName
		
		Variable dims = WaveDims(srcWave)
		
		if(dims == 1)
			// 1D wave: NaN
			SetDataFolder $compPath
			Duplicate/O srcWave, $dstName
			WaveTransform zapNaNs $dstName
			createdWaves += dstName + ";"
		elseif(dims == 2)
			nCells = DimSize(srcWave, 1)
			
			if(rowIndex < 0)
				// 2D wave
				Duplicate/O srcWave, $dstPath
				createdWaves += dstName + ";"
			else
				// 1D wave
				SetDataFolder $compPath
				Make/O/D/N=(nCells) $dstName = NaN
				Wave dstWave = $dstName
				
				if(rowIndex < DimSize(srcWave, 0))
					for(j = 0; j < nCells; j += 1)
						dstWave[j] = srcWave[rowIndex][j]
					endfor
				endif
				
				// NaN
				WaveTransform zapNaNs dstWave
				
				createdWaves += dstName + ";"
				SetDataFolder $savedDF
			endif
		endif
	endfor
	
	SetDataFolder $savedDF
	return createdWaves
End

// =============================================================================
// Summary Plot 
// =============================================================================

// -----------------------------------------------------------------------------
// CreateSummaryPlot - Bar+Violin Plot
// -----------------------------------------------------------------------------
// compPath: Comparison (e.g., "root:Comparison:", "root:EC:Comparison:")
// matrixName: Matrix wave (wave prefix)
// winName: 
// yLabel: Y
// graphTitle: 
// colorMode: 0=, 1=State(stateNum)
// stateNum: State (colorMode=1)
Function CreateSummaryPlot(compPath, matrixName, winName, yLabel, graphTitle, colorMode, stateNum)
	String compPath
	String matrixName
	String winName
	String yLabel
	String graphTitle
	Variable colorMode  // 0=sample color, 1=state color with shade
	Variable stateNum   // used when colorMode=1
	
	String savedDF = GetDataFolder(1)
	
	// 
	if(StringMatch(compPath[strlen(compPath)-1], ":") == 0)
		compPath += ":"
	endif
	
	SetDataFolder $compPath
	
	// wave
	String sampleNamesWave = matrixName + "_SampleNames"
	String meanWaveName = matrixName + "_mean"
	String semWaveName = matrixName + "_sem"
	String colorsWaveName = matrixName + "_colors"
	
	Wave/T/Z SampleNames = $sampleNamesWave
	Wave/Z meanW = $meanWaveName
	Wave/Z semW = $semWaveName
	Wave/Z colorsW = $colorsWaveName
	
	if(!WaveExists(SampleNames) || !WaveExists(meanW))
		Print "CreateSummaryPlot: Required waves not found for " + matrixName
		SetDataFolder $savedDF
		return -1
	endif
	
	Variable numSamples = numpnts(SampleNames)
	
	// 
	Variable i
	Variable r, g, b, baseR, baseG, baseB
	Variable maxVal = 65535
	
	if(colorMode == 1)
		// State + GetStateColorWithShade50%20%
		GetDstateColor(stateNum, baseR, baseG, baseB)
		for(i = 0; i < numSamples; i += 1)
			GetStateColorWithShade(stateNum, i, numSamples, r, g, b)
			colorsW[i][0] = r
			colorsW[i][1] = g
			colorsW[i][2] = b
		endfor
	else
		// 50%
		for(i = 0; i < numSamples; i += 1)
			GetSampleColor(i, r, g, b)
			// 50%
			r = min(r + (maxVal - r) * 0.5, maxVal)
			g = min(g + (maxVal - g) * 0.5, maxVal)
			b = min(b + (maxVal - b) * 0.5, maxVal)
			colorsW[i][0] = r
			colorsW[i][1] = g
			colorsW[i][2] = b
		endfor
	endif
	
	// 
	DoWindow/K $winName
	
	// 
	Display/K=1/N=$winName meanW vs SampleNames
	ModifyGraph mode($meanWaveName)=5, hbFill($meanWaveName)=2
	ModifyGraph zColor($meanWaveName)={colorsW,*,*,directRGB,0}
	ModifyGraph useBarStrokeRGB($meanWaveName)=1, barStrokeRGB($meanWaveName)=(0,0,0)
	
	// 
	if(WaveExists(semW))
		ErrorBars $meanWaveName Y,wave=(semW, semW)
	endif
	
	// Violin Plot
	String firstViolinTrace = ""
	Variable firstViolin = 1
	
	for(i = 0; i < numSamples; i += 1)
		String smplName = SampleNames[i]
		String cellDataName = matrixName + "_" + smplName
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
	// topViolinPlot
	String topAxisInfo = AxisInfo(winName, "top")
	if(strlen(topAxisInfo) > 0)
		ModifyGraph noLabel(top)=2, axThick(top)=0, tick(top)=3
	endif
	ModifyGraph tick=2, mirror=0, fStyle=1, fSize=14, font="Arial"
	ModifyGraph tick(bottom)=3, tkLblRot(bottom)=90, catGap(bottom)=0.5
	
	// 
	SetBarGraphSizeByItems(numSamples, baseWidth=150, widthPerItem=30)
	
	Label left yLabel
	SetAxis left 0, *
	DoWindow/T $winName, graphTitle
	
	SetDataFolder $savedDF
	return 0
End

// -----------------------------------------------------------------------------
// CreateComparisonSummaryPlot - 
// -----------------------------------------------------------------------------
// basePath:  ("root:", "root:EC:" )
// matrixName: Matrix wave
// rowIndex:  (-1=)
// outputPrefix: wave (=matrixName)
// winName: 
// yLabel: Y
// graphTitle: 
// colorMode: 0=, 1=State
// stateNum: State
Function CreateComparisonSummaryPlot(basePath, matrixName, rowIndex, outputPrefix, winName, yLabel, graphTitle, colorMode, stateNum)
	String basePath
	String matrixName
	Variable rowIndex
	String outputPrefix
	String winName
	String yLabel
	String graphTitle
	Variable colorMode
	Variable stateNum
	
	// outputPrefixmatrixName
	if(strlen(outputPrefix) == 0)
		outputPrefix = matrixName
	endif
	
	//  + wave
	ExtractAllSamplesToComparison(basePath, matrixName, rowIndex, outputPrefix, 1)
	
	// Comparison
	String compPath = GetComparisonPathFromBase(basePath)
	
	//  (outputPrefix)
	CreateSummaryPlot(compPath, outputPrefix, winName, yLabel, graphTitle, colorMode, stateNum)
	
	return 0
End

// -----------------------------------------------------------------------------
// CreateComparisonSummaryPlotEx - 
// -----------------------------------------------------------------------------
// sampleList: 
Function CreateComparisonSummaryPlotEx(basePath, matrixName, rowIndex, outputPrefix, winName, yLabel, graphTitle, colorMode, stateNum, sampleList)
	String basePath
	String matrixName
	Variable rowIndex
	String outputPrefix
	String winName
	String yLabel
	String graphTitle
	Variable colorMode
	Variable stateNum
	String sampleList
	
	// outputPrefixmatrixName
	if(strlen(outputPrefix) == 0)
		outputPrefix = matrixName
	endif
	
	//  + wavesampleList
	ExtractAllSamplesToComparisonEx(basePath, matrixName, rowIndex, outputPrefix, 1, sampleList)
	
	// Comparison
	String compPath = GetComparisonPathFromBase(basePath)
	
	//  (outputPrefix)
	CreateSummaryPlot(compPath, outputPrefix, winName, yLabel, graphTitle, colorMode, stateNum)
	
	// 
	NVAR/Z cRunAutoStatTest = root:cRunAutoStatTest
	if(NVAR_Exists(cRunAutoStatTest) && cRunAutoStatTest == 1)
		// 
		DoUpdate
		RunStatTestOnGraph(winName)
	endif
	
	return 0
End

