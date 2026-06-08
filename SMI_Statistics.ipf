#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3
#pragma version=2.0
// ModuleName - 

// =============================================================================
// SMI_Statistics.ipf - Statistical Analysis and Comparison Module
// =============================================================================
// 
// Version 2.0 - Refactored
// =============================================================================

// =============================================================================
// Matrix - 
// =============================================================================

// -----------------------------------------------------------------------------
// MakeResultMatrix_Gcount - Wave2Wave
// -----------------------------------------------------------------------------
// Wave
// MatrixMatrix 
// -----------------------------------------------------------------------------
Function MakeResultMatrix_Gcount(SampleName)
    String SampleName
    String FolderName, WName, MName
    Variable m = 0  // folder counter
    
    // CountDataFolders
    Variable n = CountDataFolders(SampleName)
    
    Printf "MakeResultMatrix: %s,  = %d\r", SampleName, n
    
    // 
    If(n <= 0)
        Printf ": %s \r", SampleName
        SetDataFolder root:
        return -1
    EndIf
    
    FolderName = SampleName + num2str(1)
    
    // 
    If(!DataFolderExists("root:" + SampleName + ":" + FolderName))
        Printf ": %s \r", FolderName
        SetDataFolder root:
        return -1
    EndIf
    
    SetDataFolder root:$(SampleName):$(FolderName)
    Variable NumWave = CountObjects("", 1)  // Wave 
    Variable i = 0    
    
    NewDataFolder/O root:$(SampleName):Matrix  // Wave
    
    Printf "  Wave = %d\r", NumWave
    
    // 
    Variable RowSize, ColumnSize, MatrixRowSize, MatrixColSize
    Variable copyRows, copyCols, r, c
    Variable loopCount = 0
    Variable maxLoops = NumWave + 10  // 
    
    Do  
        loopCount += 1
        If(loopCount > maxLoops)
            Printf ":  (i=%d)\r", i
            break
        EndIf
        
        m = 0
        FolderName = SampleName + num2str(m + 1)
        
        If(!DataFolderExists("root:" + SampleName + ":" + FolderName))
            i += 1
            continue
        EndIf
        
        SetDataFolder root:$(SampleName):$(FolderName)
        WName = GetIndexedObjName("", 1, i)
        
        // Wave
        If(strlen(WName) == 0)
            i += 1
            continue
        EndIf
        
        // Matrix
        Variable exc0 = StringMatch(WName, "*Trace*")
        Variable exc1 = StringMatch(WName, "*GFit*")
        Variable exc2 = StringMatch(WName, "*sig*")
        Variable exc3 = StringMatch(WName, "*name*")
        Variable exc4 = StringMatch(WName, "*_um*")  // "_um"CumOnEvent
        Variable exc5 = StringMatch(WName, "*ROI*")
        Variable exc6 = StringMatch(WName, "*Image*")
        Variable exc7 = StringMatch(WName, "*_x")
        Variable exc8 = StringMatch(WName, "*Hist*")
        
        If(exc0 == 0 && exc1 == 0 && exc2 == 0 && exc3 == 0 && exc4 == 0 && exc5 == 0 && exc6 == 0 && exc7 == 0 && exc8 == 0)
            
            // Matrix
            MatrixRowSize = 0
            MatrixColSize = 0
            
            Variable innerLoopCount = 0
            
            Do
                innerLoopCount += 1
                If(innerLoopCount > n + 5)
                    Printf ":  (m=%d, n=%d)\r", m, n
                    break
                EndIf
                
                FolderName = SampleName + num2str(m + 1)
                
                // 
                If(!DataFolderExists("root:" + SampleName + ":" + FolderName))
                    m += 1
                    continue
                EndIf
                
                SetDataFolder root:$(SampleName):$(FolderName)
                
                Wave/Z sourceWave = $WName
                If(!WaveExists(sourceWave))
                    m += 1
                    continue
                EndIf
                
                If(WaveType(sourceWave) != 0)
                    RowSize = DimSize(sourceWave, 0)
                    ColumnSize = DimSize(sourceWave, 1)
                    
                    SetDataFolder root:$(SampleName)
                    MName = WName + "_m"
                    
                    // m==0Matrix
                    If(m == 0 && ColumnSize == 0)
                        Make/O/N=(RowSize, n) Matrix = NaN
                        MatrixRowSize = RowSize
                        MatrixColSize = 0
                    ElseIf(m == 0 && n >= 3 && ColumnSize > 1)
                        Make/O/N=(RowSize, ColumnSize, n) Matrix = NaN
                        MatrixRowSize = RowSize
                        MatrixColSize = ColumnSize
                    ElseIf(m == 0 && n < 3 && ColumnSize > 1)
                        Make/O/N=(RowSize, ColumnSize, 3) Matrix = NaN
                        MatrixRowSize = RowSize
                        MatrixColSize = ColumnSize
                    EndIf
                    
                    Wave/Z Matrix
                    If(WaveExists(Matrix) && MatrixRowSize > 0)
                        // 
                        copyRows = min(RowSize, MatrixRowSize)
                        
                        If(ColumnSize == 0 && MatrixColSize == 0)
                            // 1D Wave → 2D Matrix
                            For(r = 0; r < copyRows; r += 1)
                                Matrix[r][m] = sourceWave[r]
                            EndFor
                        ElseIf(ColumnSize > 0 && MatrixColSize > 0)
                            // 2D Wave → 3D Matrix
                            copyCols = min(ColumnSize, MatrixColSize)
                            For(r = 0; r < copyRows; r += 1)
                                For(c = 0; c < copyCols; c += 1)
                                    Matrix[r][c][m] = sourceWave[r][c]
                                EndFor
                            EndFor
                        EndIf
                    EndIf
                EndIf
                
                m += 1
            While(m < n)
            
            SetDataFolder root:$(SampleName)
            Wave/Z Matrix
            If(WaveExists(Matrix) && WaveType(Matrix) != 0)
                Duplicate/O Matrix, root:$(SampleName):Matrix:$(MName)
            EndIf
            KillWaves/Z Matrix
        EndIf
        
        KillWaves/Z Matrix
        m = 0
        i += 1
    While(i < NumWave)
    
    SetDataFolder root:
    Printf "Matrix: %s (=%d)\r", SampleName, n
    return 0
End

// -----------------------------------------------------------------------------
// StatResultMatrix_Gcount - MatrixWave
// -----------------------------------------------------------------------------
// MatrixWaveSEMN
// Results
// -----------------------------------------------------------------------------
Function StatResultMatrix_Gcount(SampleName)
    String SampleName
    String MName, WName_avg, WName_sd, WName_sem, WName_n
    
    // Matrix
    If(!DataFolderExists("root:" + SampleName + ":Matrix"))
        Printf ": %s:Matrix \r", SampleName
        return -1
    EndIf
    
    NewDataFolder/O root:$(SampleName):Results
    SetDataFolder root:$(SampleName):Matrix
    Variable NumWave = CountObjects("", 1)
    
    If(NumWave == 0)
        Printf ": %s:Matrix Wave\r", SampleName
        SetDataFolder root:
        return -1
    EndIf
    
    Variable w = 0  // wave counter
    
    Do
        MName = GetIndexedObjName("", 1, w)
        
        Wave/Z MWave = $MName
        If(!WaveExists(MWave))
            w += 1
            continue
        EndIf
        
        // WaveImageStatsWave
        If(WaveType(MWave) == 0)
            w += 1
            continue
        EndIf
        
        WName_avg = MName + "_avg"
        WName_sd = MName + "_sd"
        WName_sem = MName + "_sem"
        WName_n = MName + "_n"
        
        Variable RowSize = DimSize(MWave, 0)
        Variable ColumnSize = DimSize(MWave, 1)
        Variable LayerSize = DimSize(MWave, 2)
        Variable i
        
        If(LayerSize == 0)
            // 2Wave: 
            Make/O/D/N=(RowSize) Average = NaN
            Make/O/D/N=(RowSize) SD = NaN
            Make/O/D/N=(RowSize) SEM = NaN
            Make/O/D/N=(RowSize) Npnts = NaN
            
            For(i = 0; i < RowSize; i += 1)
                ImageStats/G={i, i, 0, ColumnSize-1} MWave
                Average[i] = V_avg
                SD[i] = V_sdev
                If(V_npnts > 0)
                    SEM[i] = V_sdev / sqrt(V_npnts)
                EndIf
                Npnts[i] = V_npnts
            EndFor
        ElseIf(LayerSize > 1)
            // 3Wave: 
            Make/O/D/N=(RowSize, ColumnSize) Average = NaN
            Make/O/D/N=(RowSize, ColumnSize) SD = NaN
            Make/O/D/N=(RowSize, ColumnSize) SEM = NaN
            Make/O/D/N=(RowSize, ColumnSize) Npnts = NaN
            
            if(WaveDims(MWave) >= 3)
                ImageTransform/METH=1 averageImage MWave
            else
                Printf "  WARNING: ImageTransform skipped in CollectAndAverage — %s is %dD (LayerSize=%d)\r", MName, WaveDims(MWave), LayerSize
            endif
            Wave/Z M_AveImage, M_StdvImage
            
            If(WaveExists(M_AveImage) && WaveExists(M_StdvImage))
                Average[][] = M_AveImage[p][q]
                SD[][] = M_StdvImage[p][q]
                SEM[][] = M_StdvImage[p][q] / sqrt(LayerSize)
                Npnts[][] = LayerSize
            EndIf
            
            KillWaves/Z M_AveImage, M_StdvImage
        EndIf
        
        // Results
        Duplicate/O Average, root:$(SampleName):Results:$(WName_avg)
        Duplicate/O SD, root:$(SampleName):Results:$(WName_sd)
        Duplicate/O SEM, root:$(SampleName):Results:$(WName_sem)
        Duplicate/O Npnts, root:$(SampleName):Results:$(WName_n)
        
        KillWaves/Z Average, SD, SEM, Npnts
        w += 1
    While(w < NumWave)
    
    SetDataFolder root:
    Printf ": %s:Results\r", SampleName
    return 0
End

// -----------------------------------------------------------------------------
// RunAllWithStatistics -  + 
// -----------------------------------------------------------------------------
Function RunAllWithStatistics(SampleName)
    String SampleName
    
    Print "=========================================="
    Printf ": %s\r", SampleName
    Print "=========================================="
    
    // 
    NVAR/Z cAAS4 = root:cAAS4
    NVAR/Z cHMM = root:cHMM
    NVAR Dstate = root:Dstate
    NVAR maxOlig = root:MaxOligomerSize
    NVAR fitType = root:FitType
    NVAR maxExp = root:ExpMax_off

    Variable isAAS4 = NVAR_Exists(cAAS4) ? cAAS4 : 1
    Variable isHMM = NVAR_Exists(cHMM) ? cHMM : 1
    Variable dstateVal = Dstate
    Variable maxOligVal = maxOlig
    Variable fitTypeVal = fitType
    Variable maxExpVal = maxExp
    
    String formatStr = ""
    If(isAAS4)
        formatStr = "AAS4"
    Else
        formatStr = "AAS2"
    EndIf
    If(isHMM)
        formatStr += " + HMM (n=" + num2str(dstateVal) + ")"
    EndIf
    
    // ========================================
    // Step 0: Load Data
    // ========================================
    Print "\r--- Step 0: Load Data ---"
    Printf "Format: %s\r", formatStr
    
    Variable numLoaded
	numLoaded = SMI_LoadData(SampleName)
    
    If(numLoaded == 0)
        Print ": "
        Print "==========================================\r"
        return -1
    EndIf
    
    Printf ": %d cells\r", numLoaded
    
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
    
    // Results
    CreateResultsFolder(SampleName)
    
    // ========================================
    // Step 1: Diffusion
    // ========================================
    Print "\r--- Step 1: Diffusion Analysis ---"
    SMI_AnalyzeMSD(SampleName, fitTypeVal)
    
    // ========================================
    // Step 2: Intensity
    // ========================================
    Print "\r--- Step 2: Intensity Analysis ---"
    SMI_AnalyzeIntensity(SampleName, maxOligVal)
    
    // ========================================
    // Step 3: Density
    // ========================================
    Print "\r--- Step 3: Density Analysis ---"
    TotalDensityAnalysis(SampleName)
    
    // ========================================
    // Step 4: Off-rate
    // ========================================
    Print "\r--- Step 4: Off-rate (Duration) Analysis ---"
    Duration_Gcount(SampleName)
    
    // ========================================
    // Step 5: On-rate
    // ========================================
    Print "\r--- Step 5: On-rate Analysis ---"
    OnrateAnalysisWithOption(SampleName)
    
    // ========================================
    // Step 6: Matrix & 
    // ========================================
    Print "\r--- Step 6: Matrix Creation & Statistics ---"
    StatsResultsMatrix("root", SampleName, "")
    
    Print "\r=========================================="
    Print ""
    Print "=========================================="
    Print ":"
    Printf "  Matrix: root:%s:Matrix\r", SampleName
    Printf "  : root:%s:Results\r", SampleName
    Print "==========================================\r"
    
    return 0
End


// =============================================================================
// Matrix/Results
// =============================================================================

// -----------------------------------------------------------------------------
// CollectWaveToMatrix - WavecellMatrix
// waveName: Wave: "StepHist_dt1_S0"
// matrixName: Matrix folder: "StepHist_dt1_S0_m"
// -----------------------------------------------------------------------------
Function CollectWaveToMatrix(SampleName, waveName, matrixName)
	String SampleName, waveName, matrixName
	
	Variable n = CountDataFolders(SampleName)
	if(n <= 0)
		return -1
	endif
	
	NewDataFolder/O root:$(SampleName):Matrix
	
	Variable m, RowSize, ColumnSize
	String FolderName, fullPath
	
	// 
	Variable firstFound = 0
	for(m = 0; m < n; m += 1)
		FolderName = SampleName + num2str(m + 1)
		fullPath = "root:" + SampleName + ":" + FolderName + ":" + waveName
		Wave/Z srcWave = $fullPath
		if(WaveExists(srcWave))
			RowSize = DimSize(srcWave, 0)
			ColumnSize = DimSize(srcWave, 1)
			firstFound = 1
			break
		endif
	endfor
	
	if(!firstFound)
		return -1
	endif
	
	// Matrix
	SetDataFolder root:$(SampleName):Matrix
	if(ColumnSize == 0)
		Make/O/D/N=(RowSize, n) $matrixName = NaN
	else
		Make/O/D/N=(RowSize, ColumnSize, n) $matrixName = NaN
	endif
	Wave Matrix = $matrixName
	
	// 
	Variable r, c
	for(m = 0; m < n; m += 1)
		FolderName = SampleName + num2str(m + 1)
		fullPath = "root:" + SampleName + ":" + FolderName + ":" + waveName
		Wave/Z srcWave = $fullPath
		if(!WaveExists(srcWave))
			continue
		endif
		
		if(ColumnSize == 0)
			for(r = 0; r < min(RowSize, DimSize(srcWave, 0)); r += 1)
				Matrix[r][m] = srcWave[r]
			endfor
		else
			for(r = 0; r < min(RowSize, DimSize(srcWave, 0)); r += 1)
				for(c = 0; c < min(ColumnSize, DimSize(srcWave, 1)); c += 1)
					Matrix[r][c][m] = srcWave[r][c]
				endfor
			endfor
		endif
	endfor
	
	SetDataFolder root:
	return 0
End

// -----------------------------------------------------------------------------
// StatMatrixWave - Matrix WaveResults
// matrixName: Matrix folderWave"_m"
// -----------------------------------------------------------------------------
Function StatMatrixWave(SampleName, matrixName)
	String SampleName, matrixName
	
	String matrixPath = "root:" + SampleName + ":Matrix:" + matrixName
	Wave/Z MWave = $matrixPath
	if(!WaveExists(MWave))
		return -1
	endif
	
	NewDataFolder/O root:$(SampleName):Results
	
	String WName_avg = matrixName + "_avg"
	String WName_sd = matrixName + "_sd"
	String WName_sem = matrixName + "_sem"
	String WName_n = matrixName + "_n"
	
	Variable RowSize = DimSize(MWave, 0)
	Variable ColumnSize = DimSize(MWave, 1)
	Variable LayerSize = DimSize(MWave, 2)
	Variable i
	
	SetDataFolder root:$(SampleName):Results
	
	if(LayerSize == 0)
		// 2D Wave
		Make/O/D/N=(RowSize) Average = NaN, SD = NaN, SEM = NaN, Npnts = NaN
		for(i = 0; i < RowSize; i += 1)
			ImageStats/G={i, i, 0, ColumnSize-1} MWave
			Average[i] = V_avg
			SD[i] = V_sdev
			if(V_npnts > 0)
				SEM[i] = V_sdev / sqrt(V_npnts)
			endif
			Npnts[i] = V_npnts
		endfor
	elseif(LayerSize == 1)
		// 3D Wave with single cell: mean = the value itself, SD/SEM = NaN (undefined for n=1)
		Make/O/D/N=(RowSize, ColumnSize) Average = NaN, SD = NaN, SEM = NaN, Npnts = NaN
		Average[][] = MWave[p][q][0]
		SD[][] = NaN
		SEM[][] = NaN
		Npnts[][] = 1
	elseif(LayerSize > 1)
		// 3D Wave: average across layers
		Make/O/D/N=(RowSize, ColumnSize) Average = NaN, SD = NaN, SEM = NaN, Npnts = NaN
		if(WaveDims(MWave) >= 3)
			ImageTransform/METH=1 averageImage MWave
		else
			Printf "  WARNING: ImageTransform skipped in StatMatrixWave — %s is %dD (LayerSize=%d)\r", matrixName, WaveDims(MWave), LayerSize
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
	
	Duplicate/O Average, $WName_avg
	Duplicate/O SD, $WName_sd
	Duplicate/O SEM, $WName_sem
	Duplicate/O Npnts, $WName_n
	KillWaves/Z Average, SD, SEM, Npnts
	
	SetDataFolder root:
	return 0
End

// -----------------------------------------------------------------------------
// EnsureWaveInResults - ResultsWavecell
// waveName: cellWave
// suffix: Matrix/Results Wavesuffix"_m"
// -----------------------------------------------------------------------------
Function EnsureWaveInResults(SampleName, waveName)
	String SampleName, waveName
	
	String matrixName = waveName + "_m"
	String resultsPath = "root:" + SampleName + ":Results:" + matrixName + "_avg"
	
	// Results
	Wave/Z existingWave = $resultsPath
	if(WaveExists(existingWave))
		return 0
	endif
	
	// MatrixWave
	Variable result = CollectWaveToMatrix(SampleName, waveName, matrixName)
	if(result != 0)
		return -1
	endif
	
	// Results
	result = StatMatrixWave(SampleName, matrixName)
	return result
End

// -----------------------------------------------------------------------------
// EnsureAllResultsForAverage - AverageWave
// analysisType: "StepHist", "IntHist", "LP", "Onrate", "StateTrans", "MSD", "Heatmap"
// -----------------------------------------------------------------------------
Function EnsureAllResultsForAverage(SampleName, analysisType)
	String SampleName, analysisType
	
	NVAR/Z Dstate = root:Dstate
	NVAR/Z cHMM = root:cHMM
	NVAR/Z StepDeltaTMin = root:StepDeltaTMin
	NVAR/Z StepDeltaTMax = root:StepDeltaTMax
	
	Variable maxState = 0
	if(NVAR_Exists(cHMM) && cHMM == 1 && NVAR_Exists(Dstate))
		maxState = Dstate
	endif
	
	Variable s, dt
	String waveName
	
	strswitch(analysisType)
		case "StepHist":
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
			for(dt = dtMin; dt <= dtMax; dt += 1)
				for(s = 0; s <= maxState; s += 1)
					waveName = "StepHist_dt" + num2str(dt) + "_S" + num2str(s)
					EnsureWaveInResults(SampleName, waveName)
					waveName = "StepHist_x_dt" + num2str(dt) + "_S" + num2str(s)
					EnsureWaveInResults(SampleName, waveName)
				endfor
			endfor
			break
			
		case "IntHist":
			for(s = 0; s <= maxState; s += 1)
				waveName = "Int_S" + num2str(s) + "_Phist"
				EnsureWaveInResults(SampleName, waveName)
			endfor
			// IntHist_x
			EnsureWaveInResults(SampleName, "IntHist_x")
			break
			
		case "LP":
			for(s = 0; s <= maxState; s += 1)
				waveName = "LP_S" + num2str(s) + "_Phist"
				EnsureWaveInResults(SampleName, waveName)
				waveName = "LP_S" + num2str(s) + "_X"
				EnsureWaveInResults(SampleName, waveName)
			endfor
			break
			
		case "Onrate":
			for(s = 0; s <= maxState; s += 1)
				waveName = "CumOnEvent_S" + num2str(s)
				EnsureWaveInResults(SampleName, waveName)
				waveName = "time_onrate_S" + num2str(s)
				EnsureWaveInResults(SampleName, waveName)
			endfor
			break
			
		case "StateTrans":
			EnsureWaveInResults(SampleName, "TauTransition_cell")
			EnsureWaveInResults(SampleName, "TauDwell_cell")
			EnsureWaveInResults(SampleName, "D_values")
			EnsureWaveInResults(SampleName, "L_values")
			EnsureWaveInResults(SampleName, "P_values")
			for(s = 1; s <= maxState; s += 1)
				waveName = "coef_MSD_S" + num2str(s)
				EnsureWaveInResults(SampleName, waveName)
			endfor
			// HMMP
			EnsureWaveInResults(SampleName, "HMMP")
			break
			
		case "Heatmap":
			// Step Size Heatmap
			for(s = 0; s <= maxState; s += 1)
				waveName = "StepHeatmap_S" + num2str(s)
				EnsureWaveInResults(SampleName, waveName)
			endfor
			break
			
		case "MSD":
			for(s = 0; s <= maxState; s += 1)
				waveName = "MSD_avg_S" + num2str(s)
				EnsureWaveInResults(SampleName, waveName)
				waveName = "MSD_time_S" + num2str(s)
				EnsureWaveInResults(SampleName, waveName)
			endfor
			// MSDD, L
			EnsureMSDParamsInResults(SampleName)
			break
			
		case "Duration":
			EnsureWaveInResults(SampleName, "P_Duration")
			EnsureWaveInResults(SampleName, "time_Duration")
			EnsureWaveInResults(SampleName, "Fraction_Duration")
			EnsureWaveInResults(SampleName, "Tau_Duration")
			break
			
		case "MolDens":
			// Wave: MolDensity_Dstate, StateFraction, ParticleDensity_Dstate, ParaDensityAvg, MolDensitySummary
			EnsureWaveInResults(SampleName, "MolDensity_Dstate")
			EnsureWaveInResults(SampleName, "StateFraction")
			EnsureWaveInResults(SampleName, "ParticleDensity_Dstate")
			EnsureWaveInResults(SampleName, "ParaDensityAvg")
			EnsureWaveInResults(SampleName, "MolDensitySummary")
			// Wavestate
			for(s = 0; s <= maxState; s += 1)
				waveName = "MolDensDist_S" + num2str(s)
				EnsureWaveInResults(SampleName, waveName)
			endfor
			break
	endswitch
	
	return 0
End

// -----------------------------------------------------------------------------
// EnsureMSDParamsInResults - MSD(D, L)Matrix/Results
// cellcoef_MSD_SnD(0), L(1)
// : coef_MSD_Sn_m[param][cell], coef_MSD_Sn_m_avg[param], coef_MSD_Sn_m_sem[param]
// -----------------------------------------------------------------------------
Function EnsureMSDParamsInResults(SampleName)
	String SampleName
	
	NVAR/Z Dstate = root:Dstate
	NVAR/Z cHMM = root:cHMM
	
	Variable maxState = 0
	if(NVAR_Exists(cHMM) && cHMM == 1 && NVAR_Exists(Dstate))
		maxState = Dstate
	endif
	
	String basePath = "root:" + SampleName + ":"
	NVAR/Z n_folders = $(basePath + "n_folders")
	if(!NVAR_Exists(n_folders))
		Print "EnsureMSDParamsInResults: n_folders not found for " + SampleName
		return -1
	endif
	Variable n = n_folders
	
	// Matrix/Results folder
	NewDataFolder/O $(basePath + "Matrix")
	NewDataFolder/O $(basePath + "Results")
	
	// 
	Variable stateIdx, m, numParams, foundCoef, paramIdx, i
	Variable RowSize, ColumnSize
	String FolderName, coefPath, matrixName, suffix
	String WName_avg, WName_sd, WName_sem, WName_n
	
	for(stateIdx = 0; stateIdx <= maxState; stateIdx += 1)
		suffix = "_S" + num2str(stateIdx)
		matrixName = "coef_MSD" + suffix + "_m"
		
		// Results
		Wave/Z existingAvg = $(basePath + "Results:" + matrixName + "_avg")
		if(WaveExists(existingAvg))
			continue
		endif
		
		// cell
		numParams = 2  // : D, L
		foundCoef = 0
		for(m = 0; m < n; m += 1)
			FolderName = SampleName + num2str(m + 1)
			coefPath = basePath + FolderName + ":coef_MSD" + suffix
			Wave/Z coef_MSD = $coefPath
			if(WaveExists(coef_MSD))
				numParams = numpnts(coef_MSD)
				foundCoef = 1
				break
			endif
		endfor
		
		if(foundCoef == 0)
			continue
		endif
		
		// Matrix folderMatrix
		SetDataFolder $(basePath + "Matrix")
		Make/O/D/N=(numParams, n) $matrixName = NaN
		Wave MatrixWave = $matrixName
		
		// cellcoef_MSD_Sn
		for(m = 0; m < n; m += 1)
			FolderName = SampleName + num2str(m + 1)
			coefPath = basePath + FolderName + ":coef_MSD" + suffix
			Wave/Z coef_MSD = $coefPath
			
			if(WaveExists(coef_MSD))
				for(paramIdx = 0; paramIdx < min(numParams, numpnts(coef_MSD)); paramIdx += 1)
					MatrixWave[paramIdx][m] = coef_MSD[paramIdx]
				endfor
			endif
		endfor
		
		// StatResultMatrix_Gcount
		WName_avg = matrixName + "_avg"
		WName_sd = matrixName + "_sd"
		WName_sem = matrixName + "_sem"
		WName_n = matrixName + "_n"
		
		RowSize = DimSize(MatrixWave, 0)
		ColumnSize = DimSize(MatrixWave, 1)
		
		Make/O/D/N=(RowSize) Average = NaN
		Make/O/D/N=(RowSize) SD = NaN
		Make/O/D/N=(RowSize) SEM = NaN
		Make/O/D/N=(RowSize) Npnts = NaN
		
		for(i = 0; i < RowSize; i += 1)
			ImageStats/G={i, i, 0, ColumnSize-1} MatrixWave
			Average[i] = V_avg
			SD[i] = V_sdev
			SEM[i] = V_sdev / sqrt(V_npnts)
			Npnts[i] = V_npnts
		endfor
		
		// ResultsDuplicate
		Duplicate/O Average, $(basePath + "Results:" + WName_avg)
		Duplicate/O SD, $(basePath + "Results:" + WName_sd)
		Duplicate/O SEM, $(basePath + "Results:" + WName_sem)
		Duplicate/O Npnts, $(basePath + "Results:" + WName_n)
		
		KillWaves/Z Average, SD, SEM, Npnts
	endfor
	
	SetDataFolder root:
	return 0
End

// =============================================================================
// Multiple Comparison Tests
// =============================================================================
// Summary Plot
// Igor
// - 2: StatsTTestWelch's t-test
// - 3ANOVA: Welch's ANOVA
// - 3Dunnett T3: StatsTTest + Sidak vs 
// - 3Games-Howell: StatsTTest + Sidak
// =============================================================================

// -----------------------------------------------------------------------------
// Summary Plot
// Stateroot:Comparison
// : 
// -----------------------------------------------------------------------------
Function GetCellDataWaveNames(targetGraph, waveNames, groupNames)
	String targetGraph
	Wave/T waveNames, groupNames
	
	//  cell data wave  prefix 
	// : Compare_{prefix}_{suffix} → cell data: {prefix}_{suffix}_{smplName}
	// : Compare_D_S0 → D_S0_{smplName}
	// : Compare_HMMP_S1 → HMMP_S1_{smplName}
	// : Compare_Tau_S1_dwell → Tau_S1_dwell_{smplName}
	// : Compare_Area → Area_{smplName}
	// : Compare_LowerBound_{smplName} → nLB_S1, nLB_S2, ... (LB_StateNames)
	// Timelapse: TL_{modePrefix}{prefix} → {modePrefix}{prefix}_{smplName}
	// : TL_D_S1, TL_nD_S1, TL_dD_S1, TL_NumPts, TL_nNumPts
	// ColCmp: ColCmp_{prefix} → {smplName}_{prefix} in root:EC1:Comparison
	// : ColCmp_OnRate_S0_C1E → Sample1_ColOnRate_S0_C1E
	
	// 
	String savedDF = GetDataFolder(1)
	
	// 
	String cellDataPrefix = ""
	Variable isTimelapse = 0
	Variable isColCmp = 0
	Variable groupIdx = 0
	Variable i, j
	Variable numConditions, numTimePoints, totalPoints, condIdx, tpIdx
	Variable numStates, numSamples, interval
	String smplName, cellDataName, fullPath, stateName
	String comparisonPath = "root:Comparison"
	
	// === Timelapse  ===
	if(StringMatch(targetGraph, "TL_*"))
		isTimelapse = 1
		// TL_
		cellDataPrefix = targetGraph[3, strlen(targetGraph)-1]
		
		// 
		if(strlen(cellDataPrefix) == 0)
			Print "GetCellDataWaveNames: Error - Empty prefix from: " + targetGraph
			return 0
		endif
		
		// root:Comparison
		if(!DataFolderExists("root:Comparison"))
			Print "GetCellDataWaveNames: Error - root:Comparison folder not found"
			return 0
		endif
		
		SetDataFolder root:Comparison
		
		// Timelapse
		Wave/T/Z TL_SampleList
		if(!WaveExists(TL_SampleList))
			Print "GetCellDataWaveNames: Timelapse - TL_SampleList not found"
			SetDataFolder $savedDF
			return 0
		endif
		
		numConditions = DimSize(TL_SampleList, 0)
		numTimePoints = DimSize(TL_SampleList, 1)
		totalPoints = numConditions * numTimePoints
		groupIdx = 0
		
		for(condIdx = 0; condIdx < numConditions; condIdx += 1)
			for(tpIdx = 0; tpIdx < numTimePoints; tpIdx += 1)
				smplName = TL_SampleList[condIdx][tpIdx]
				cellDataName = cellDataPrefix + "_" + smplName
				fullPath = "root:Comparison:" + cellDataName
				
				Wave/Z cellData = $fullPath
				if(WaveExists(cellData) && numpnts(cellData) > 0)
					if(groupIdx < numpnts(waveNames))
						waveNames[groupIdx] = fullPath
						// : t0_C1, t10_C1, t20_C1, ...
						NVAR/Z TimeInterval = root:TimeInterval
						interval = 10
						if(NVAR_Exists(TimeInterval) && TimeInterval > 0)
							interval = TimeInterval
						endif
						groupNames[groupIdx] = "t" + num2str(tpIdx * interval) + "_C" + num2str(condIdx + 1)
						groupIdx += 1
					endif
				endif
			endfor
		endfor
		
		SetDataFolder $savedDF
		return groupIdx
	endif
	
	// === ColCmp Colocalization Compare Parameters===
	if(StringMatch(targetGraph, "ColCmp_*"))
		isColCmp = 1
		// ColCmp_"Col"
		String suffix = targetGraph[7, strlen(targetGraph)-1]
		cellDataPrefix = "Col" + suffix
		
		// ComparisonGetComparisonPathFromBaseroot:Comparison
		// EC1, Seg1root:Comparison
		comparisonPath = "root:Comparison"
		
		// 
		if(strlen(cellDataPrefix) == 0)
			Print "GetCellDataWaveNames: Error - Empty prefix from: " + targetGraph
			return 0
		endif
		
		// Comparison
		if(!DataFolderExists(comparisonPath))
			Print "GetCellDataWaveNames: Error - " + comparisonPath + " folder not found"
			return 0
		endif
		
		SetDataFolder $comparisonPath
		
		// SampleNamesoutputPrefix_SampleNames
		String sampleNamesWaveName = cellDataPrefix + "_SampleNames"
		Wave/T/Z SampleNamesCol = $sampleNamesWaveName
		
		if(!WaveExists(SampleNamesCol))
			// : *_SampleNameswave
			String allWaves = WaveList("*_SampleNames", ";", "")
			if(strlen(allWaves) > 0)
				// cellDataPrefix
				Variable wIdx
				for(wIdx = 0; wIdx < ItemsInList(allWaves); wIdx += 1)
					String testName = StringFromList(wIdx, allWaves)
					if(StringMatch(testName, cellDataPrefix + "_SampleNames"))
						sampleNamesWaveName = testName
						Wave/T/Z SampleNamesCol = $sampleNamesWaveName
						break
					endif
				endfor
				// 
				if(!WaveExists(SampleNamesCol) && ItemsInList(allWaves) > 0)
					sampleNamesWaveName = StringFromList(0, allWaves)
					Wave/T/Z SampleNamesCol = $sampleNamesWaveName
				endif
			endif
		endif
		
		if(!WaveExists(SampleNamesCol))
			Print "GetCellDataWaveNames: Error - SampleNames wave not found for " + cellDataPrefix
			SetDataFolder $savedDF
			return 0
		endif
		
		numSamples = numpnts(SampleNamesCol)
		groupIdx = 0
		
		for(j = 0; j < numSamples; j += 1)
			smplName = SampleNamesCol[j]
			cellDataName = smplName + "_" + cellDataPrefix
			fullPath = comparisonPath + ":" + cellDataName
			
			Wave/Z cellDataCol = $fullPath
			if(WaveExists(cellDataCol) && numpnts(cellDataCol) > 0)
				if(groupIdx < numpnts(waveNames))
					waveNames[groupIdx] = fullPath
					groupNames[groupIdx] = smplName
					groupIdx += 1
				endif
			endif
		endfor
		
		SetDataFolder $savedDF
		return groupIdx
	endif
	
	// === Compare ===
	// "Compare_"
	if(!StringMatch(targetGraph, "Compare_*"))
		Print "GetCellDataWaveNames: Error - Cannot parse graph name: " + targetGraph
		return 0
	endif
	
	// Compare_
	cellDataPrefix = targetGraph[8, strlen(targetGraph)-1]
	
	// === winName → cellDataPrefix ===
	// winNameoutputPrefix
	if(StringMatch(cellDataPrefix, "NumPoints*"))
		// Compare_NumPoints → NumPts
		cellDataPrefix = ReplaceString("NumPoints", cellDataPrefix, "NumPts")
	elseif(StringMatch(cellDataPrefix, "MolDens_*"))
		// Compare_MolDens_S0 → MolDens_S0
	elseif(StringMatch(cellDataPrefix, "Fraction_*"))
		// Compare_Fraction_All → AllStates
		Print "GetCellDataWaveNames: Skipping All States graph: " + targetGraph
		return 0
	elseif(StringMatch(cellDataPrefix, "*_All"))
		// Compare_*_All → AllStates
		Print "GetCellDataWaveNames: Skipping All States graph: " + targetGraph
		return 0
	endif
	
	// 
	if(strlen(cellDataPrefix) == 0)
		Print "GetCellDataWaveNames: Error - Empty prefix from: " + targetGraph
		return 0
	endif
	
	// root:Comparison
	if(!DataFolderExists("root:Comparison"))
		Print "GetCellDataWaveNames: Error - root:Comparison folder not found"
		return 0
	endif
	
	SetDataFolder root:Comparison
	
	// === LowerBound ===
	if(StringMatch(cellDataPrefix, "LowerBound_*"))
		// LB_StateNames
		Wave/T/Z LB_StateNames
		if(!WaveExists(LB_StateNames))
			Print "GetCellDataWaveNames: Error - LB_StateNames wave not found"
			SetDataFolder $savedDF
			return 0
		endif
		
		numStates = numpnts(LB_StateNames)
		groupIdx = 0
		
		for(i = 0; i < numStates; i += 1)
			stateName = LB_StateNames[i]
			cellDataName = "nLB_" + stateName
			fullPath = "root:Comparison:" + cellDataName
			
			Wave/Z cellData2 = $fullPath
			if(WaveExists(cellData2) && numpnts(cellData2) > 0)
				if(groupIdx < numpnts(waveNames))
					waveNames[groupIdx] = fullPath
					groupNames[groupIdx] = stateName
					groupIdx += 1
				endif
			endif
		endfor
		
		SetDataFolder $savedDF
		return groupIdx
	endif
	
	// ===  ===
	// SampleNamesprefix_SampleNames
	String specificSampleNames = cellDataPrefix + "_SampleNames"
	Wave/T/Z SampleNamesSpec = $specificSampleNames
	
	// SampleNames
	Wave/T/Z SampleNames
	Wave/T/Z SampleNamesRef
	if(WaveExists(SampleNamesSpec))
		Wave/T SampleNamesRef = SampleNamesSpec
	elseif(WaveExists(SampleNames))
		Wave/T SampleNamesRef = SampleNames
	else
		Print "GetCellDataWaveNames: Error - No SampleNames wave found"
		Print "GetCellDataWaveNames: Tried: " + specificSampleNames + " and SampleNames"
		SetDataFolder $savedDF
		return 0
	endif
	
	numSamples = numpnts(SampleNamesRef)
	groupIdx = 0
	
	for(j = 0; j < numSamples; j += 1)
		smplName = SampleNamesRef[j]
		// : Compare
		// cellDataPrefix + "_" + smplName D_S0_Sample1
		cellDataName = cellDataPrefix + "_" + smplName
		fullPath = "root:Comparison:" + cellDataName
		
		Wave/Z cellData3 = $fullPath
		if(WaveExists(cellData3) && numpnts(cellData3) > 0)
			if(groupIdx < numpnts(waveNames))
				waveNames[groupIdx] = fullPath
				groupNames[groupIdx] = smplName
				groupIdx += 1
			endif
		else
			// : 
			// Print "GetCellDataWaveNames: Wave not found or empty: " + fullPath
		endif
	endfor
	
	// 
	SetDataFolder $savedDF
	return groupIdx
End

// -----------------------------------------------------------------------------
// mean + SEM
// groupIdx: 0-based
// waveNames: GetCellDataWaveNames
// : mean + SEM
// -----------------------------------------------------------------------------
Function GetGroupBarTop(waveNames, groupIdx)
	Wave/T waveNames
	Variable groupIdx
	
	Wave/Z data = $(waveNames[groupIdx])
	if(!WaveExists(data) || numpnts(data) == 0)
		return NaN
	endif
	
	WaveStats/Q data
	Variable meanVal = V_avg
	Variable sem = V_sdev / sqrt(V_npnts)
	
	return meanVal + sem
End

// -----------------------------------------------------------------------------
// mean + SEM
// waveNames: GetCellDataWaveNames
// numGroups: 
// : mean + SEM
// -----------------------------------------------------------------------------
Function GetMaxBarTop(waveNames, numGroups)
	Wave/T waveNames
	Variable numGroups
	
	Variable maxTop = -inf
	Variable i
	
	for(i = 0; i < numGroups; i += 1)
		Variable barTop = GetGroupBarTop(waveNames, i)
		if(numtype(barTop) == 0 && barTop > maxTop)
			maxTop = barTop
		endif
	endfor
	
	return maxTop
End

// -----------------------------------------------------------------------------
// mean + SEM
// TraceNameList
// barTops: mean + SEM
// : 
// -----------------------------------------------------------------------------
Function GetBarTopsFromGraph(targetGraph, barTops)
	String targetGraph
	Wave barTops
	
	// 
	String traceList = TraceNameList(targetGraph, ";", 1)
	Variable numTraces = ItemsInList(traceList)
	
	if(numTraces == 0)
		Print "GetBarTopsFromGraph: No traces found in " + targetGraph
		return 0
	endif
	
	// mode=5
	Variable i, j, groupCount = 0
	
	for(i = 0; i < numTraces; i += 1)
		String traceName = StringFromList(i, traceList)
		
		// 
		String tInfoStr = TraceInfo(targetGraph, traceName, 0)
		
		// mode=5mode=3
		String modeStr = StringByKey("mode(x)", tInfoStr, "=", ";")
		Variable traceMode = str2num(modeStr)
		
		// 53,4
		if(traceMode == 5 || traceMode == 3 || traceMode == 4)
			// Ymean
			Wave/Z yWave = TraceNameToWaveRef(targetGraph, traceName)
			if(!WaveExists(yWave))
				continue
			endif
			
			// ErrorBarsSEM
			String errInfoStr = StringByKey("ERRORBARS", tInfoStr)
			Wave/Z semErrWave = $""
			
			if(strlen(errInfoStr) > 0)
				// ErrorBars traceName Y,wave=(semWave, semWave) 
				Variable waveStart = strsearch(errInfoStr, "wave=(", 0)
				if(waveStart >= 0)
					Variable waveEnd = strsearch(errInfoStr, ")", waveStart)
					if(waveEnd > waveStart)
						String errWaveInfoStr = errInfoStr[waveStart+6, waveEnd-1]
						String errWaveName = StringFromList(0, errWaveInfoStr, ",")
						Wave/Z semErrWave = $errWaveName
					endif
				endif
			endif
			
			// 1
			Variable numPts = numpnts(yWave)
			for(j = 0; j < numPts && groupCount < numpnts(barTops); j += 1)
				Variable meanVal = yWave[j]
				Variable semVal = 0
				if(WaveExists(semErrWave) && j < numpnts(semErrWave))
					semVal = semErrWave[j]
				endif
				
				if(numtype(meanVal) == 0)
					barTops[groupCount] = meanVal + semVal
					groupCount += 1
				endif
			endfor
			
			// 
			if(groupCount > 0)
				break
			endif
		endif
	endfor
	
	// 
	if(groupCount == 0)
		// mean/sem
		String baseName = targetGraph
		if(StringMatch(targetGraph, "Compare_*"))
			baseName = targetGraph[8, strlen(targetGraph)-1]
		elseif(StringMatch(targetGraph, "TL_*"))
			baseName = targetGraph[3, strlen(targetGraph)-1]
		endif
		
		// root:Comparison
		String savedDF = GetDataFolder(1)
		if(DataFolderExists("root:Comparison"))
			SetDataFolder root:Comparison
			
			// mean
			// Compare_D_S0 → baseName = "D_S0"
			// 1: D_S0_mean ()
			// 2: D_mean_S0 (CompareD)  
			// 3: D_S0 (mean)
			String pattern1 = baseName + "_mean"
			String pattern2 = ReplaceString("_", baseName, "_mean_")  // D_S0 → D_mean_S0
			String pattern3 = baseName
			String meanPatterns = pattern1 + ";" + pattern2 + ";" + pattern3
			
			Variable pi
			for(pi = 0; pi < ItemsInList(meanPatterns); pi += 1)
				String meanPattern = StringFromList(pi, meanPatterns)
				Wave/Z meanW = $meanPattern
				if(WaveExists(meanW))
					// SEM
					String semPattern = ReplaceString("mean", meanPattern, "sem")
					Wave/Z semW = $semPattern
					
					Variable numPts2 = numpnts(meanW)
					for(j = 0; j < min(numPts2, numpnts(barTops)); j += 1)
						Variable mv = meanW[j]
						Variable sv = 0
						if(WaveExists(semW) && j < numpnts(semW))
							sv = semW[j]
						endif
						if(numtype(mv) == 0)
							barTops[j] = mv + sv
							groupCount += 1
						endif
					endfor
					break
				endif
			endfor
			
			SetDataFolder $savedDF
		endif
	endif
	
	return groupCount
End
// : bit0=cmdline, bit1=graph, bit2=table
// -----------------------------------------------------------------------------
Function GetOutputOptions()
	Variable options = 0
	
	// 
	NVAR/Z cStatOutputCmdLine = root:cStatOutputCmdLine
	NVAR/Z cStatOutputGraph = root:cStatOutputGraph
	NVAR/Z cStatOutputTable = root:cStatOutputTable
	
	// 
	if(NVAR_Exists(cStatOutputCmdLine))
		if(cStatOutputCmdLine)
			options = options | 1  // bit 0
		endif
	else
		// 
		ControlInfo/W=SMI_MainPanel tab6_chk_cmdline
		if(V_flag != 0 && V_Value)
			options = options | 1
		else
			// : 
			options = options | 1
		endif
	endif
	
	if(NVAR_Exists(cStatOutputGraph))
		if(cStatOutputGraph)
			options = options | 2  // bit 1
		endif
	else
		ControlInfo/W=SMI_MainPanel tab6_chk_graph
		if(V_flag != 0 && V_Value)
			options = options | 2
		else
			// : 
			options = options | 2
		endif
	endif
	
	if(NVAR_Exists(cStatOutputTable))
		if(cStatOutputTable)
			options = options | 4  // bit 2
		endif
	else
		ControlInfo/W=SMI_MainPanel tab6_chk_table
		if(V_flag != 0 && V_Value)
			options = options | 4
		else
			// : 
			options = options | 4
		endif
	endif
	
	// 0
	if(options == 0)
		options = 7  // cmdline + graph + table
	endif
	
	return options
End

// -----------------------------------------------------------------------------
// Auto Analysis
// -----------------------------------------------------------------------------
Function IsAutoAnalysisEnabled()
	NVAR/Z cRunAutoStatTest = root:cRunAutoStatTest
	if(NVAR_Exists(cRunAutoStatTest))
		return cRunAutoStatTest
	endif
	
	// 
	ControlInfo/W=SMI_MainPanel tab6_chk_autotest
	if(V_Flag == 0)  // 
		return 1  // : 
	endif
	return V_Value
End

// -----------------------------------------------------------------------------
// vs Control  All pairs 
// : 1=vs Control, 0=All pairs
// -----------------------------------------------------------------------------
Function IsVsControlMode()
	ControlInfo/W=SMI_MainPanel tab6_chk_vscontrol
	if(V_Flag == 0)  // 
		return 0  // : All pairs
	endif
	return V_Value
End

// -----------------------------------------------------------------------------
// 
// targetGraph: 
// 
// -----------------------------------------------------------------------------
Function RunAutoStatisticalTest(targetGraph)
	String targetGraph
	
	// Auto Analysis
	if(!IsAutoAnalysisEnabled())
		return 0
	endif
	
	// 
	if(strlen(targetGraph) == 0 || WinType(targetGraph) != 1)
		return -1
	endif
	
	// Y
	// CompareSetAxis left 0, * 
	// 
	DoUpdate/W=$targetGraph
	
	// 
	Make/FREE/T/N=20 waveNames, groupNames
	Variable numGroups = GetCellDataWaveNames(targetGraph, waveNames, groupNames)
	
	if(numGroups < 2)
		Print "Auto Analysis: Skipped (need at least 2 groups)"
		return -1
	endif
	
	Print "--- Auto Statistical Analysis ---"
	
	if(numGroups == 2)
		// 2: Welch's t-test
		TwoSampleWelchTest(targetGraph)
	else
		// 3: Sidak
		if(IsVsControlMode())
			SidakVsControl(targetGraph)
		else
			SidakAllPairs(targetGraph)
		endif
	endif
	
	return 0
End

// -----------------------------------------------------------------------------
// Compare
// -----------------------------------------------------------------------------
Function ResetStatisticsSummaryTable()
	String savedDF = GetDataFolder(1)
	
	if(DataFolderExists("root:Comparison"))
		SetDataFolder root:Comparison
		
		// Wave
		KillWaves/Z StatLabel
		String statWaves = WaveList("Stat_*", ";", "TEXT:1")
		Variable i
		for(i = 0; i < ItemsInList(statWaves); i += 1)
			String statWaveName = StringFromList(i, statWaves)
			KillWaves/Z $statWaveName
		endfor
		
		// 
		DoWindow/K Compare_Statistics
		
		// Wave
		KillWaves/Z StatSummary_Labels
		DoWindow/K Compare_Statistics_Summary
		
		String labelWaves = WaveList("Label_*", ";", "TEXT:1")
		for(i = 0; i < ItemsInList(labelWaves); i += 1)
			String labelWaveName = StringFromList(i, labelWaves)
			KillWaves/Z $labelWaveName
		endfor
		String resultWaves = WaveList("Result_*", ";", "TEXT:1")
		for(i = 0; i < ItemsInList(resultWaves); i += 1)
			String resultWaveName = StringFromList(i, resultWaves)
			KillWaves/Z $resultWaveName
		endfor
		
		// Table_*
		String tableWindows = WinList("Table_*", ";", "WIN:2")
		for(i = 0; i < ItemsInList(tableWindows); i += 1)
			String tableWinName = StringFromList(i, tableWindows)
			DoWindow/K $tableWinName
		endfor
	endif
	
	SetDataFolder $savedDF
End

// -----------------------------------------------------------------------------
// 2Welch's t-testIgorStatsTTest
// targetGraph: Summary Plot
// : p
// -----------------------------------------------------------------------------
Function TwoSampleWelchTest(targetGraph)
	String targetGraph
	
	if(strlen(targetGraph) == 0 || WinType(targetGraph) != 1)
		Print "Error: Invalid graph name"
		return NaN
	endif
	
	// 
	Variable outputOpt = GetOutputOptions()
	Variable showCmdLine = (outputOpt & 1) != 0
	Variable showGraph = (outputOpt & 2) != 0
	Variable showTable = (outputOpt & 4) != 0
	
	// 
	Make/FREE/T/N=20 waveNames, groupNames
	Variable numGroups = GetCellDataWaveNames(targetGraph, waveNames, groupNames)
	
	if(numGroups != 2)
		Print "Error: t-test requires exactly 2 groups. Found: " + num2str(numGroups)
		return NaN
	endif
	
	// 
	Wave/Z wave1 = $waveNames[0]
	Wave/Z wave2 = $waveNames[1]
	
	if(!WaveExists(wave1) || !WaveExists(wave2))
		Print "Error: Cannot access data waves"
		return NaN
	endif
	
	// 
	WaveStats/Q wave1
	Variable n1 = V_npnts, mean1 = V_avg, sd1 = V_sdev
	WaveStats/Q wave2
	Variable n2 = V_npnts, mean2 = V_avg, sd2 = V_sdev
	
	// IgorStatsTTestWelch's t-test
	StatsTTest/Q/TAIL=4 wave1, wave2
	
	// W_StatsTTest
	Wave/Z W_StatsTTest
	if(!WaveExists(W_StatsTTest))
		Print "Error: StatsTTest failed"
		return NaN
	endif
	
	Variable tStat = W_StatsTTest[8]
	Variable pVal = W_StatsTTest[9]
	Variable df = W_StatsTTest[10]
	String sigMark = GetSignificanceMark(pVal)
	
	// 
	if(showCmdLine)
		Print "=== Welch's t-test (Two-sample) ==="
		Printf "Group 1: %s (n=%d, mean=%.4f, SD=%.4f)\r", groupNames[0], n1, mean1, sd1
		Printf "Group 2: %s (n=%d, mean=%.4f, SD=%.4f)\r", groupNames[1], n2, mean2, sd2
		Printf "t-statistic: %.4f, df: %.2f\r", tStat, df
		Printf "p-value: %.4f %s\r", pVal, sigMark
	endif
	
	// 
	if(showGraph)
		AddTTestSignificanceToGraph(targetGraph, pVal)
	endif
	
	// 
	if(showTable)
		CreateTTestResultTable(targetGraph, groupNames[0], groupNames[1], n1, n2, mean1, mean2, sd1, sd2, tStat, df, pVal)
	endif
	
	return pVal
End

// -----------------------------------------------------------------------------
// t-test
// Sidak9p (adj)-
// -----------------------------------------------------------------------------
Function CreateTTestResultTable(targetGraph, grp1, grp2, n1, n2, mean1, mean2, sd1, sd2, tStat, df, pVal)
	String targetGraph, grp1, grp2
	Variable n1, n2, mean1, mean2, sd1, sd2, tStat, df, pVal
	
	// 
	String summaryTableName = "Compare_Statistics"
	String labelWaveName = "StatLabel"
	
	// Compare_TL_
	String colName = targetGraph
	if(StringMatch(targetGraph, "Compare_*"))
		colName = targetGraph[8, strlen(targetGraph)-1]
	elseif(StringMatch(targetGraph, "TL_*"))
		colName = targetGraph[3, strlen(targetGraph)-1]
	endif
	String resultWaveName = "Stat_" + colName
	
	// root:Comparison
	String savedDF = GetDataFolder(1)
	if(DataFolderExists("root:Comparison"))
		SetDataFolder root:Comparison
	endif
	
	//  = 9Sidak
	Variable numRows = 9
	
	// Wave
	Wave/T/Z labelWave = $labelWaveName
	if(!WaveExists(labelWave))
		Make/O/T/N=(numRows) $labelWaveName
		Wave/T labelWave = $labelWaveName
		labelWave[0] = "Comparison"
		labelWave[1] = "n (Group1)"
		labelWave[2] = "n (Group2)"
		labelWave[3] = "Mean (G1)"
		labelWave[4] = "Mean (G2)"
		labelWave[5] = "t-stat"
		labelWave[6] = "df"
		labelWave[7] = "p (raw)"
		labelWave[8] = "p (adj)"
	endif
	
	// Wave
	Make/O/T/N=(numRows) $resultWaveName
	Wave/T resultWave = $resultWaveName
	
	String tempStr
	resultWave[0] = grp1 + " vs " + grp2
	sprintf tempStr, "%d", n1
	resultWave[1] = tempStr
	sprintf tempStr, "%d", n2
	resultWave[2] = tempStr
	sprintf tempStr, "%.4f", mean1
	resultWave[3] = tempStr
	sprintf tempStr, "%.4f", mean2
	resultWave[4] = tempStr
	sprintf tempStr, "%.4f", tStat
	resultWave[5] = tempStr
	sprintf tempStr, "%.2f", df
	resultWave[6] = tempStr
	sprintf tempStr, "%.4f", pVal
	resultWave[7] = tempStr
	resultWave[8] = "-"  // Welch
	
	// 
	DoWindow $summaryTableName
	if(V_flag == 1)
		// Wave
		String traceList = TableInfo(summaryTableName, -2)
		if(WhichListItem(resultWaveName, traceList) < 0)
			// 
			AppendToTable/W=$summaryTableName resultWave
			ModifyTable/W=$summaryTableName width($resultWaveName)=100
		endif
		// Wave
	else
		// 
		Edit/N=$summaryTableName/W=(100,100,800,350) labelWave as "Statistical Test Summary"
		ModifyTable/W=$summaryTableName width($labelWaveName)=100
		AppendToTable/W=$summaryTableName resultWave
		ModifyTable/W=$summaryTableName width($resultWaveName)=100
	endif
	
	SetDataFolder $savedDF
End

// -----------------------------------------------------------------------------
// t-test 2
// 2*
// Y2(mean + SEM) + yRange*5%
// -----------------------------------------------------------------------------
// =============================================================================
// Significance Bracket Drawing System (Prism-style)
// Uses DrawLine/DrawText in axis coordinates for resize-robust display
// =============================================================================

// Clear all significance annotations (old TextBoxes + DrawLayer)
Function ClearSignificanceAnnotations(targetGraph)
	String targetGraph
	
	DoWindow $targetGraph
	if(V_flag == 0)
		return -1
	endif
	
	// Remove old TextBox annotations
	Variable i
	for(i = 0; i < 50; i += 1)
		TextBox/W=$targetGraph/K/N=$("sigText" + num2str(i))
	endfor
	
	// Clear UserFront draw layer
	SetDrawLayer/W=$targetGraph UserFront
	DrawAction/W=$targetGraph delete
End

// Core: Draw Prism-style significance brackets on a bar chart
// pVals[]: adjusted p-values for each comparison
// g1[]/g2[]: category indices (0-based) for each comparison pair
// numGroups: total number of categories
Function DrawSignificanceBrackets(targetGraph, pVals, g1, g2, numGroups)
	String targetGraph
	Wave pVals, g1, g2
	Variable numGroups
	
	Variable numComp = numpnts(pVals)
	if(numComp == 0)
		return 0
	endif
	
	// Clear previous annotations
	ClearSignificanceAnnotations(targetGraph)
	DoUpdate/W=$targetGraph
	
	// Get bar tops (mean + SEM) for each group
	Make/FREE/N=(numGroups) barTops = 0
	Variable numBarTops = GetBarTopsFromGraph(targetGraph, barTops)
	Variable nGrp, ii
	if(numBarTops == 0)
		Make/FREE/T/N=20 wvN, grN
		nGrp = GetCellDataWaveNames(targetGraph, wvN, grN)
		for(ii = 0; ii < min(nGrp, numGroups); ii += 1)
			barTops[ii] = GetGroupBarTop(wvN, ii)
		endfor
	endif
	
	// Global max bar top
	Variable globalMax = 0
	for(ii = 0; ii < numGroups; ii += 1)
		if(numtype(barTops[ii]) == 0 && barTops[ii] > globalMax)
			globalMax = barTops[ii]
		endif
	endfor
	if(globalMax <= 0)
		GetAxis/Q/W=$targetGraph left
		globalMax = V_max * 0.6
	endif
	
	// Read bracket parameters from globals (user-adjustable in Statistics tab)
	NVAR/Z gXOffset = root:StatBracket_XOffset
	NVAR/Z gTextGap = root:StatBracket_TextGap
	NVAR/Z gStartY = root:StatBracket_StartY
	NVAR/Z gStepY = root:StatBracket_StepY
	NVAR/Z gTickH = root:StatBracket_TickH
	
	Variable xOffset = NVAR_Exists(gXOffset) ? gXOffset : 0.5
	Variable tickH = globalMax * (NVAR_Exists(gTickH) ? gTickH : 0.05)
	Variable stepY = globalMax * (NVAR_Exists(gStepY) ? gStepY : 0.12)
	Variable textGap = globalMax * (NVAR_Exists(gTextGap) ? gTextGap : 0.11)
	Variable startY = globalMax * (NVAR_Exists(gStartY) ? gStartY : 1.15)
	
	// Collect significant pairs
	Make/FREE/N=(numComp) sigPVal = NaN, sigG1 = NaN, sigG2 = NaN, sigSpan = NaN
	Variable nSig = 0
	for(ii = 0; ii < numComp; ii += 1)
		if(numtype(pVals[ii]) == 0 && pVals[ii] < 0.05)
			sigPVal[nSig] = pVals[ii]
			sigG1[nSig] = g1[ii]
			sigG2[nSig] = g2[ii]
			sigSpan[nSig] = abs(g2[ii] - g1[ii])
			nSig += 1
		endif
	endfor
	
	if(nSig == 0)
		return 0
	endif
	Redimension/N=(nSig) sigPVal, sigG1, sigG2, sigSpan
	
	// Sort by span (narrow pairs first — they go lowest)
	Sort sigSpan, sigSpan, sigPVal, sigG1, sigG2
	
	// Assign Y levels: avoid overlap
	Make/FREE/N=(nSig) bracketY = NaN
	Make/FREE/N=(nSig) occX1 = NaN, occX2 = NaN, occY = NaN
	Variable nPlaced = 0
	
	Variable kk, pp, x1k, x2k, candidateY, overlap
	Variable spanMax, ss, settled, maxIter, iter
	for(kk = 0; kk < nSig; kk += 1)
		x1k = min(sigG1[kk], sigG2[kk])
		x2k = max(sigG1[kk], sigG2[kk])
		
		// Minimum Y: above the tallest bar in the span
		spanMax = 0
		for(ss = x1k; ss <= x2k; ss += 1)
			if(ss < numGroups && numtype(barTops[ss]) == 0 && barTops[ss] > spanMax)
				spanMax = barTops[ss]
			endif
		endfor
		candidateY = max(spanMax + stepY, startY)
		
		// Check against already placed brackets for overlap
		settled = 0
		maxIter = 50
		iter = 0
		do
			overlap = 0
			for(pp = 0; pp < nPlaced; pp += 1)
				// Check: do X ranges overlap AND Y is too close?
				if(x1k <= occX2[pp] && x2k >= occX1[pp])
					// X overlap exists — check Y proximity
					if(abs(candidateY - occY[pp]) < stepY * 0.9)
						candidateY = occY[pp] + stepY
						overlap = 1
						break
					endif
				endif
			endfor
			iter += 1
			if(overlap == 0 || iter >= maxIter)
				settled = 1
			endif
		while(!settled)
		
		bracketY[kk] = candidateY
		occX1[nPlaced] = x1k
		occX2[nPlaced] = x2k
		occY[nPlaced] = candidateY
		nPlaced += 1
	endfor
	
	// Find maximum bracket Y for axis extension
	Variable maxBracketY = 0
	for(kk = 0; kk < nSig; kk += 1)
		if(bracketY[kk] > maxBracketY)
			maxBracketY = bracketY[kk]
		endif
	endfor
	
	// Draw brackets
	SetDrawLayer/W=$targetGraph UserFront
	
	Variable yH, yTick, xMid
	Variable x1draw, x2draw  // draw coordinates with offset
	String sigStr
	for(kk = 0; kk < nSig; kk += 1)
		x1k = min(sigG1[kk], sigG2[kk])
		x2k = max(sigG1[kk], sigG2[kk])
		x1draw = x1k + xOffset
		x2draw = x2k + xOffset
		yH = bracketY[kk]       // horizontal line Y
		yTick = yH - tickH      // bottom of ticks
		xMid = (x1draw + x2draw) / 2.0
		
		// Significance text
		sigStr = ""
		if(sigPVal[kk] < 0.001)
			sigStr = "***"
		elseif(sigPVal[kk] < 0.01)
			sigStr = "**"
		else
			sigStr = "*"
		endif
		
		// Left tick (vertical)
		SetDrawEnv/W=$targetGraph xcoord=bottom, ycoord=left, linethick=1
		DrawLine/W=$targetGraph x1draw, yTick, x1draw, yH
		
		// Horizontal line
		SetDrawEnv/W=$targetGraph xcoord=bottom, ycoord=left, linethick=1
		DrawLine/W=$targetGraph x1draw, yH, x2draw, yH
		
		// Right tick (vertical)
		SetDrawEnv/W=$targetGraph xcoord=bottom, ycoord=left, linethick=1
		DrawLine/W=$targetGraph x2draw, yH, x2draw, yTick
		
		// Text: centered above horizontal line
		SetDrawEnv/W=$targetGraph xcoord=bottom, ycoord=left
		SetDrawEnv/W=$targetGraph fname="Arial", fsize=14, fstyle=1
		SetDrawEnv/W=$targetGraph textxjust=1, textyjust=2  // center horiz, bottom justify
		DrawText/W=$targetGraph xMid, yH + textGap, sigStr
	endfor
	
	// Extend Y axis to accommodate brackets + text
	SetAxis/W=$targetGraph left 0, maxBracketY + stepY
	
	return nSig
End

// =============================================================================
// Wrapper functions (called from test routines)
// =============================================================================

// 2-group: t-test bracket
Function AddTTestSignificanceToGraph(targetGraph, pVal)
	String targetGraph
	Variable pVal
	
	if(pVal >= 0.05)
		return 0
	endif
	
	Make/FREE/N=1 pVals = {pVal}, g1Idx = {0}, g2Idx = {1}
	return DrawSignificanceBrackets(targetGraph, pVals, g1Idx, g2Idx, 2)
End

// -----------------------------------------------------------------------------
// Welch's ANOVAIgorStatsANOVA1Test /W
// 
// : p
// -----------------------------------------------------------------------------
Function RunWelchANOVA(targetGraph)
	String targetGraph
	
	if(strlen(targetGraph) == 0 || WinType(targetGraph) != 1)
		Print "Error: Invalid graph name"
		return NaN
	endif
	
	// 
	Variable outputOpt = GetOutputOptions()
	Variable showCmdLine = (outputOpt & 1) != 0
	Variable showTable = (outputOpt & 4) != 0
	
	// 
	Make/FREE/T/N=20 waveNames, groupNames
	Variable numGroups = GetCellDataWaveNames(targetGraph, waveNames, groupNames)
	
	if(numGroups < 2)
		Print "Error: ANOVA requires at least 2 groups. Found: " + num2str(numGroups)
		return NaN
	endif
	
	// 
	Make/FREE/N=(numGroups) groupNs, groupMeans, groupSDs
	Variable i
	for(i = 0; i < numGroups; i += 1)
		Wave/Z w = $waveNames[i]
		if(WaveExists(w))
			WaveStats/Q w
			groupNs[i] = V_npnts
			groupMeans[i] = V_avg
			groupSDs[i] = V_sdev
		endif
	endfor
	
	// StatsANOVA1Test /W Welch's ANOVA
	String waveListStr = ""
	for(i = 0; i < numGroups; i += 1)
		waveListStr += waveNames[i] + ";"
	endfor
	
	StatsANOVA1Test/Q/W/WSTR=waveListStr
	
	// W_ANOVA1Welch 
	Wave/Z W_ANOVA1Welch
	if(!WaveExists(W_ANOVA1Welch))
		Print "Error: StatsANOVA1Test /W failed"
		return NaN
	endif
	
	Variable df1 = W_ANOVA1Welch[0]
	Variable df2 = W_ANOVA1Welch[1]
	Variable F = W_ANOVA1Welch[2]
	Variable pVal = W_ANOVA1Welch[4]
	String sigMark = GetSignificanceMark(pVal)
	
	// 
	if(showCmdLine)
		Print "=== Welch's ANOVA (One-way, unequal variances) ==="
		Print "Number of groups: " + num2str(numGroups)
		for(i = 0; i < numGroups; i += 1)
			Printf "Group %d: %s (n=%d, mean=%.4f, SD=%.4f)\r", i+1, groupNames[i], groupNs[i], groupMeans[i], groupSDs[i]
		endfor
		Printf "F'-statistic: %.4f, df1: %.0f, df2: %.2f\r", F, df1, df2
		Printf "p-value: %.4f %s\r", pVal, sigMark
		if(pVal < 0.05)
			Print "Significant difference detected. Consider post-hoc test (Sidak Correction)."
		endif
	endif
	
	// 
	if(showTable)
		CreateANOVAResultTable(targetGraph, groupNames, groupNs, groupMeans, groupSDs, numGroups, F, df1, df2, pVal)
	endif
	
	return pVal
End

// -----------------------------------------------------------------------------
// ANOVA
// -----------------------------------------------------------------------------
Function CreateANOVAResultTable(targetGraph, groupNames, groupNs, groupMeans, groupSDs, numGroups, F, df1, df2, pVal)
	String targetGraph
	Wave/T groupNames
	Wave groupNs, groupMeans, groupSDs
	Variable numGroups, F, df1, df2, pVal
	
	String tableName = "ANOVA_" + targetGraph
	
	// 
	DoWindow/K $tableName
	
	// 
	String grpWaveName = "W_ANOVAGroups_" + targetGraph
	String nWaveName = "W_ANOVAn_" + targetGraph
	String meanWaveName = "W_ANOVAMean_" + targetGraph
	String sdWaveName = "W_ANOVASD_" + targetGraph
	
	Make/O/T/N=(numGroups) $grpWaveName
	Make/O/N=(numGroups) $nWaveName, $meanWaveName, $sdWaveName
	Wave/T grpWave = $grpWaveName
	Wave nWave = $nWaveName
	Wave meanWave = $meanWaveName
	Wave sdWave = $sdWaveName
	
	grpWave = groupNames[p]
	nWave = groupNs[p]
	meanWave = groupMeans[p]
	sdWave = groupSDs[p]
	
	// 
	Edit/N=$tableName/W=(100,100,600,300) grpWave, nWave, meanWave, sdWave as "Welch's ANOVA: " + targetGraph
	ModifyTable/W=$tableName width($grpWaveName)=100, width($nWaveName)=50, width($meanWaveName)=80, width($sdWaveName)=80
	
	// 
	Printf "\\r[Table: %s] F'=%.4f, df1=%.0f, df2=%.2f, p=%.4f %s\\r", tableName, F, df1, df2, pVal, GetSignificanceMark(pVal)
End

// -----------------------------------------------------------------------------
// Sidak vs 
// Welch's t-test + Sidak
// targetGraph: Summary Plot
// -----------------------------------------------------------------------------
Function SidakVsControl(targetGraph)
	String targetGraph
	
	if(strlen(targetGraph) == 0 || WinType(targetGraph) != 1)
		Print "Error: Invalid graph name"
		return -1
	endif
	
	// 
	Variable outputOpt = GetOutputOptions()
	Variable showCmdLine = (outputOpt & 1) != 0
	Variable showGraph = (outputOpt & 2) != 0
	Variable showTable = (outputOpt & 4) != 0
	
	// 
	Make/FREE/T/N=20 waveNames, groupNames
	Variable numGroups = GetCellDataWaveNames(targetGraph, waveNames, groupNames)
	
	if(numGroups < 2)
		Print "Error: Need at least 2 groups. Found: " + num2str(numGroups)
		return -1
	endif
	
	// 
	Wave/Z controlWave = $waveNames[0]
	WaveStats/Q controlWave
	Variable ctrlN = V_npnts, ctrlMean = V_avg, ctrlSD = V_sdev
	
	// 
	Variable numComparisons = numGroups - 1
	Make/FREE/N=(numComparisons) pValues, pAdjusted, testNs, testMeans, testSDs, tStats, dfValues
	Make/FREE/T/N=(numComparisons) testNames
	
	Variable i
	for(i = 1; i < numGroups; i += 1)
		Wave/Z testWave = $waveNames[i]
		WaveStats/Q testWave
		testNs[i-1] = V_npnts
		testMeans[i-1] = V_avg
		testSDs[i-1] = V_sdev
		testNames[i-1] = groupNames[i]
		
		// StatsTTest
		StatsTTest/Q/TAIL=4 controlWave, testWave
		Wave/Z W_StatsTTest
		
		if(WaveExists(W_StatsTTest))
			tStats[i-1] = W_StatsTTest[8]    // t
			pValues[i-1] = W_StatsTTest[9]   // p-value
			dfValues[i-1] = W_StatsTTest[10] // 
		else
			tStats[i-1] = NaN
			pValues[i-1] = NaN
			dfValues[i-1] = NaN
		endif
	endfor
	
	// Sidak
	for(i = 0; i < numComparisons; i += 1)
		if(numtype(pValues[i]) == 0)
			pAdjusted[i] = 1 - (1 - pValues[i])^numComparisons
			if(pAdjusted[i] > 1)
				pAdjusted[i] = 1
			endif
		else
			pAdjusted[i] = NaN
		endif
	endfor
	
	// 
	if(showCmdLine)
		Print "=== Sidak Correction (vs Control) ==="
		Print "Number of groups: " + num2str(numGroups)
		Printf "Control: %s (n=%d, mean=%.4f, SD=%.4f)\r", groupNames[0], ctrlN, ctrlMean, ctrlSD
		Print "--- Results ---"
		for(i = 0; i < numComparisons; i += 1)
			String sigMark = GetSignificanceMark(pAdjusted[i])
			Printf "%s vs %s: n=%d, mean=%.4f, t=%.4f, df=%.2f, p=%.4f (raw), p=%.4f (adj), %s\r", groupNames[0], testNames[i], testNs[i], testMeans[i], tStats[i], dfValues[i], pValues[i], pAdjusted[i], sigMark
		endfor
	endif
	
	// 
	if(showGraph)
		AddSidakVsControlToGraph(targetGraph, pAdjusted, groupNames, numGroups)
	endif
	
	// 
	if(showTable)
		CreateSidakVsControlTable(targetGraph, groupNames[0], testNames, ctrlN, ctrlMean, testNs, testMeans, tStats, dfValues, pValues, pAdjusted, numComparisons)
	endif
	
	return 0
End

// -----------------------------------------------------------------------------
// Sidak vs Control 
// 
// -----------------------------------------------------------------------------
Function CreateSidakVsControlTable(targetGraph, ctrlName, testNames, ctrlN, ctrlMean, testNs, testMeans, tStats, dfValues, pValues, pAdjusted, numComparisons)
	String targetGraph, ctrlName
	Wave/T testNames
	Variable ctrlN, ctrlMean
	Wave testNs, testMeans, tStats, dfValues, pValues, pAdjusted
	Variable numComparisons
	
	// 
	String summaryTableName = "Compare_Statistics"
	String labelWaveName = "StatLabel"
	
	// Compare_TL_
	String baseName = targetGraph
	if(StringMatch(targetGraph, "Compare_*"))
		baseName = targetGraph[8, strlen(targetGraph)-1]
	elseif(StringMatch(targetGraph, "TL_*"))
		baseName = targetGraph[3, strlen(targetGraph)-1]
	endif
	
	// root:Comparison
	String savedDF = GetDataFolder(1)
	if(DataFolderExists("root:Comparison"))
		SetDataFolder root:Comparison
	endif
	
	//  = 9Welch
	Variable numRows = 9
	
	// Wave
	Wave/T/Z labelWave = $labelWaveName
	if(!WaveExists(labelWave))
		Make/O/T/N=(numRows) $labelWaveName
		Wave/T labelWave = $labelWaveName
		labelWave[0] = "Comparison"
		labelWave[1] = "n (Ctrl)"
		labelWave[2] = "n (Test)"
		labelWave[3] = "Mean (Ctrl)"
		labelWave[4] = "Mean (Test)"
		labelWave[5] = "t-stat"
		labelWave[6] = "df"
		labelWave[7] = "p (raw)"
		labelWave[8] = "p (adj)"
	endif
	
	// Wave
	Variable i
	String tempStr
	
	for(i = 0; i < numComparisons; i += 1)
		String resultWaveName = "Stat_" + baseName + "_" + num2str(i+1)
		
		Make/O/T/N=(numRows) $resultWaveName
		Wave/T resultWave = $resultWaveName
		
		resultWave[0] = ctrlName + " vs " + testNames[i]
		sprintf tempStr, "%d", ctrlN
		resultWave[1] = tempStr
		sprintf tempStr, "%d", testNs[i]
		resultWave[2] = tempStr
		sprintf tempStr, "%.4f", ctrlMean
		resultWave[3] = tempStr
		sprintf tempStr, "%.4f", testMeans[i]
		resultWave[4] = tempStr
		sprintf tempStr, "%.4f", tStats[i]
		resultWave[5] = tempStr
		sprintf tempStr, "%.2f", dfValues[i]
		resultWave[6] = tempStr
		sprintf tempStr, "%.4f", pValues[i]
		resultWave[7] = tempStr
		sprintf tempStr, "%.4f", pAdjusted[i]
		resultWave[8] = tempStr
	endfor
	
	// 
	DoWindow $summaryTableName
	if(V_flag == 1)
		// Wave
		String traceList = TableInfo(summaryTableName, -2)
		for(i = 0; i < numComparisons; i += 1)
			String resultWaveName2 = "Stat_" + baseName + "_" + num2str(i+1)
			if(WhichListItem(resultWaveName2, traceList) < 0)
				Wave/T resultWave2 = $resultWaveName2
				AppendToTable/W=$summaryTableName resultWave2
				ModifyTable/W=$summaryTableName width($resultWaveName2)=100
			endif
		endfor
	else
		// 
		Edit/N=$summaryTableName/W=(100,100,800,350) labelWave as "Statistical Test Summary"
		ModifyTable/W=$summaryTableName width($labelWaveName)=100
		for(i = 0; i < numComparisons; i += 1)
			String resultWaveName3 = "Stat_" + baseName + "_" + num2str(i+1)
			Wave/T resultWave3 = $resultWaveName3
			AppendToTable/W=$summaryTableName resultWave3
			ModifyTable/W=$summaryTableName width($resultWaveName3)=100
		endfor
	endif
	
	SetDataFolder $savedDF
End

// -----------------------------------------------------------------------------
// Sidak
// Welch's t-test + Sidak
// -----------------------------------------------------------------------------
Function SidakAllPairs(targetGraph)
	String targetGraph
	
	if(strlen(targetGraph) == 0 || WinType(targetGraph) != 1)
		Print "Error: Invalid graph name"
		return -1
	endif
	
	// 
	Variable outputOpt = GetOutputOptions()
	Variable showCmdLine = (outputOpt & 1) != 0
	Variable showGraph = (outputOpt & 2) != 0
	Variable showTable = (outputOpt & 4) != 0
	
	// 
	Make/FREE/T/N=20 waveNames, groupNames
	Variable numGroups = GetCellDataWaveNames(targetGraph, waveNames, groupNames)
	
	if(numGroups < 2)
		Print "Error: Need at least 2 groups. Found: " + num2str(numGroups)
		return -1
	endif
	
	// 
	Make/FREE/N=(numGroups) grpNs, grpMeans, grpSDs
	Variable i, j
	for(i = 0; i < numGroups; i += 1)
		Wave/Z w = $waveNames[i]
		WaveStats/Q w
		grpNs[i] = V_npnts
		grpMeans[i] = V_avg
		grpSDs[i] = V_sdev
	endfor
	
	// 
	Variable numComparisons = numGroups * (numGroups - 1) / 2
	Make/FREE/N=(numComparisons) pValues, pAdjusted, group1Idx, group2Idx, tStats, dfValues
	Make/FREE/N=(numComparisons) n1Values, n2Values, mean1Values, mean2Values
	Make/FREE/T/N=(numComparisons) compLabels
	
	Variable compIdx = 0
	for(i = 0; i < numGroups - 1; i += 1)
		for(j = i + 1; j < numGroups; j += 1)
			Wave/Z wave1 = $waveNames[i]
			Wave/Z wave2 = $waveNames[j]
			
			// 
			n1Values[compIdx] = grpNs[i]
			n2Values[compIdx] = grpNs[j]
			mean1Values[compIdx] = grpMeans[i]
			mean2Values[compIdx] = grpMeans[j]
			
			// StatsTTest
			StatsTTest/Q/TAIL=4 wave1, wave2
			Wave/Z W_StatsTTest
			
			if(WaveExists(W_StatsTTest))
				tStats[compIdx] = W_StatsTTest[8]    // t
				pValues[compIdx] = W_StatsTTest[9]   // p-value
				dfValues[compIdx] = W_StatsTTest[10] // 
			else
				tStats[compIdx] = NaN
				pValues[compIdx] = NaN
				dfValues[compIdx] = NaN
			endif
			
			compLabels[compIdx] = groupNames[i] + " vs " + groupNames[j]
			group1Idx[compIdx] = i
			group2Idx[compIdx] = j
			compIdx += 1
		endfor
	endfor
	
	// Sidak
	for(i = 0; i < numComparisons; i += 1)
		if(numtype(pValues[i]) == 0)
			pAdjusted[i] = 1 - (1 - pValues[i])^numComparisons
			if(pAdjusted[i] > 1)
				pAdjusted[i] = 1
			endif
		else
			pAdjusted[i] = NaN
		endif
	endfor
	
	// 
	if(showCmdLine)
		Print "=== Sidak Correction (All Pairwise Comparisons) ==="
		Print "Number of groups: " + num2str(numGroups)
		for(i = 0; i < numGroups; i += 1)
			Printf "Group %d: %s (n=%d, mean=%.4f, SD=%.4f)\r", i+1, groupNames[i], grpNs[i], grpMeans[i], grpSDs[i]
		endfor
		Print "--- Pairwise Comparisons ---"
		for(i = 0; i < numComparisons; i += 1)
			String sigMark = GetSignificanceMark(pAdjusted[i])
			Printf "%s: t=%.4f, df=%.2f, p=%.4f (raw), p=%.4f (adj), %s\r", compLabels[i], tStats[i], dfValues[i], pValues[i], pAdjusted[i], sigMark
		endfor
	endif
	
	// 
	if(showGraph)
		AddSidakAllPairsToGraph(targetGraph, pAdjusted, group1Idx, group2Idx, groupNames, numGroups)
	endif
	
	// 
	if(showTable)
		CreateSidakAllPairsTable(targetGraph, compLabels, n1Values, n2Values, mean1Values, mean2Values, tStats, dfValues, pValues, pAdjusted, numComparisons)
	endif
	
	return 0
End

// -----------------------------------------------------------------------------
// Sidak All Pairs 
// 
// -----------------------------------------------------------------------------
Function CreateSidakAllPairsTable(targetGraph, compLabels, n1Values, n2Values, mean1Values, mean2Values, tStats, dfValues, pValues, pAdjusted, numComparisons)
	String targetGraph
	Wave/T compLabels
	Wave n1Values, n2Values, mean1Values, mean2Values, tStats, dfValues, pValues, pAdjusted
	Variable numComparisons
	
	// 
	String summaryTableName = "Compare_Statistics"
	String labelWaveName = "StatLabel"
	
	// Compare_TL_
	String baseName = targetGraph
	if(StringMatch(targetGraph, "Compare_*"))
		baseName = targetGraph[8, strlen(targetGraph)-1]
	elseif(StringMatch(targetGraph, "TL_*"))
		baseName = targetGraph[3, strlen(targetGraph)-1]
	endif
	
	// root:Comparison
	String savedDF = GetDataFolder(1)
	if(DataFolderExists("root:Comparison"))
		SetDataFolder root:Comparison
	endif
	
	//  = 9Welch
	Variable numRows = 9
	
	// Wave
	Wave/T/Z labelWave = $labelWaveName
	if(!WaveExists(labelWave))
		Make/O/T/N=(numRows) $labelWaveName
		Wave/T labelWave = $labelWaveName
		labelWave[0] = "Comparison"
		labelWave[1] = "n (Group1)"
		labelWave[2] = "n (Group2)"
		labelWave[3] = "Mean (G1)"
		labelWave[4] = "Mean (G2)"
		labelWave[5] = "t-stat"
		labelWave[6] = "df"
		labelWave[7] = "p (raw)"
		labelWave[8] = "p (adj)"
	endif
	
	// Wave
	Variable i
	String tempStr
	
	for(i = 0; i < numComparisons; i += 1)
		String resultWaveName = "Stat_" + baseName + "_" + num2str(i+1)
		
		Make/O/T/N=(numRows) $resultWaveName
		Wave/T resultWave = $resultWaveName
		
		resultWave[0] = compLabels[i]
		sprintf tempStr, "%d", n1Values[i]
		resultWave[1] = tempStr
		sprintf tempStr, "%d", n2Values[i]
		resultWave[2] = tempStr
		sprintf tempStr, "%.4f", mean1Values[i]
		resultWave[3] = tempStr
		sprintf tempStr, "%.4f", mean2Values[i]
		resultWave[4] = tempStr
		sprintf tempStr, "%.4f", tStats[i]
		resultWave[5] = tempStr
		sprintf tempStr, "%.2f", dfValues[i]
		resultWave[6] = tempStr
		sprintf tempStr, "%.4f", pValues[i]
		resultWave[7] = tempStr
		sprintf tempStr, "%.4f", pAdjusted[i]
		resultWave[8] = tempStr
	endfor
	
	// 
	DoWindow $summaryTableName
	if(V_flag == 1)
		// Wave
		String traceList = TableInfo(summaryTableName, -2)
		for(i = 0; i < numComparisons; i += 1)
			String resultWaveName2 = "Stat_" + baseName + "_" + num2str(i+1)
			if(WhichListItem(resultWaveName2, traceList) < 0)
				Wave/T resultWave2 = $resultWaveName2
				AppendToTable/W=$summaryTableName resultWave2
				ModifyTable/W=$summaryTableName width($resultWaveName2)=100
			endif
		endfor
	else
		// 
		Edit/N=$summaryTableName/W=(100,100,800,350) labelWave as "Statistical Test Summary"
		ModifyTable/W=$summaryTableName width($labelWaveName)=100
		for(i = 0; i < numComparisons; i += 1)
			String resultWaveName3 = "Stat_" + baseName + "_" + num2str(i+1)
			Wave/T resultWave3 = $resultWaveName3
			AppendToTable/W=$summaryTableName resultWave3
			ModifyTable/W=$summaryTableName width($resultWaveName3)=100
		endfor
	endif
	
	SetDataFolder $savedDF
End

// -----------------------------------------------------------------------------
// 
// -----------------------------------------------------------------------------
Function/S GetSignificanceMark(pVal)
	Variable pVal
	
	if(numtype(pVal) != 0)
		return "N/A"
	elseif(pVal < 0.001)
		return "***"
	elseif(pVal < 0.01)
		return "**"
	elseif(pVal < 0.05)
		return "*"
	else
		return "n.s."
	endif
End

// -----------------------------------------------------------------------------
// Sidak vs Control 
// vs Control: 2*
// Y(mean + SEM) + yRange*5%
// -----------------------------------------------------------------------------
// Sidak vs Control: bracket from group 0 to each significant group
Function AddSidakVsControlToGraph(targetGraph, pAdjusted, groupNames, numGroups)
	String targetGraph
	Wave pAdjusted
	Wave/T groupNames
	Variable numGroups
	
	Variable numComparisons = numpnts(pAdjusted)
	
	// Build pair arrays: control (0) vs group (i+1)
	Make/FREE/N=(numComparisons) g1Idx = 0, g2Idx
	Variable i
	for(i = 0; i < numComparisons; i += 1)
		g2Idx[i] = i + 1
	endfor
	
	return DrawSignificanceBrackets(targetGraph, pAdjusted, g1Idx, g2Idx, numGroups)
End

// -----------------------------------------------------------------------------
// Sidak All Pairs 
// All Pairs: 2*
// YyMax + 5%X-5% offset
// -----------------------------------------------------------------------------
// Sidak All Pairs: bracket for each significant pair
Function AddSidakAllPairsToGraph(targetGraph, pAdjusted, group1Idx, group2Idx, groupNames, numGroups)
	String targetGraph
	Wave pAdjusted, group1Idx, group2Idx
	Wave/T groupNames
	Variable numGroups
	
	return DrawSignificanceBrackets(targetGraph, pAdjusted, group1Idx, group2Idx, numGroups)
End

// -----------------------------------------------------------------------------
// 
// testType: 0=t-test, 1=Welch's ANOVA, 2=Sidak vs Control, 3=Sidak All Pairs
// -----------------------------------------------------------------------------
Function RunMultipleComparisonTest(testType)
	Variable testType
	
	// 
	String targetGraph = WinName(0, 1)
	
	if(strlen(targetGraph) == 0)
		Print "Error: No graph window is active"
		return -1
	endif
	
	// Summary Plot
	if(StringMatch(targetGraph, "Compare_*") || StringMatch(targetGraph, "TL_*") || StringMatch(targetGraph, "ColCmp_*"))
		Print "Target graph: " + targetGraph
	else
		Print "Warning: Graph may not be a Summary Plot. Proceeding anyway..."
		Print "Target graph: " + targetGraph
	endif
	
	switch(testType)
		case 0:
			TwoSampleWelchTest(targetGraph)
			break
		case 1:
			RunWelchANOVA(targetGraph)
			break
		case 2:
			SidakVsControl(targetGraph)
			break
		case 3:
			SidakAllPairs(targetGraph)
			break
		default:
			Print "Error: Unknown test type"
			return -1
	endswitch
	
	return 0
End

// -----------------------------------------------------------------------------
// RunStatTestOnGraph - 
// -----------------------------------------------------------------------------
// 2: Welch's t-test
// 3: Sidakvs Control  All Pairs
Function RunStatTestOnGraph(targetGraph)
	String targetGraph
	
	// Auto Analysis
	if(!IsAutoAnalysisEnabled())
		return 0
	endif
	
	// 
	DoWindow $targetGraph
	if(V_flag == 0)
		return -1
	endif
	
	// Y
	DoUpdate/W=$targetGraph
	
	// 
	Make/FREE/T/N=20 waveNamesTemp, groupNamesTemp
	Variable numGroups = GetCellDataWaveNames(targetGraph, waveNamesTemp, groupNamesTemp)
	
	if(numGroups < 2)
		// 2
		return -1
	endif
	
	Print "--- Auto Statistical Analysis ---"
	
	if(numGroups == 2)
		// 2: Welch's t-test
		TwoSampleWelchTest(targetGraph)
	else
		// 3: Sidak
		if(IsVsControlMode())
			SidakVsControl(targetGraph)
		else
			SidakAllPairs(targetGraph)
		endif
	endif
	
	return 0
End
