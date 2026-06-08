#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3
#pragma version=2.0
// ModuleName - 

// =============================================================================
// SMI_Kinetics.ipf - Kinetic Analysis Module (Off-rate / On-rate)
// =============================================================================
// 
// Version 2.0 - Refactored ()
// =============================================================================

// -----------------------------------------------------------------------------
// Duration_Gcount - On-time
// AIC
// -----------------------------------------------------------------------------
Function Duration_Gcount(SampleName, [basePath, useMinFrame, waveSuffix, overrideTau1, overrideTauScale, overrideA1, overrideAScale])
	String SampleName
	String basePath      // :  "root"
	Variable useMinFrame // : MinFrame root:MinFrame
	String waveSuffix    // : wave"_C1E", "_C2E"
	Variable overrideTau1, overrideTauScale, overrideA1, overrideAScale
	
	// 
	EnsureGlobalParameters()
	
	NVAR framerate = root:framerate
	NVAR FrameNum = root:FrameNum
	NVAR MinFrame = root:MinFrame
	NVAR cORC = root:cORC
	NVAR ExpMin_off = root:ExpMin_off
	NVAR ExpMax_off = root:ExpMax_off
	NVAR InitialTau1_off = root:InitialTau1_off
	NVAR TauScale_off = root:TauScale_off
	NVAR InitialA1_off = root:InitialA1_off
	NVAR AScale_off = root:AScale_off
	NVAR/Z cSuppressOutput = root:cSuppressOutput
	Variable suppressOutput = NVAR_Exists(cSuppressOutput) ? cSuppressOutput : 0
	
	// Apply overrides if provided (for Colocalization — avoids global modification)
	Variable useTau1 = ParamIsDefault(overrideTau1) ? InitialTau1_off : overrideTau1
	Variable useTauScale = ParamIsDefault(overrideTauScale) ? TauScale_off : overrideTauScale
	Variable useA1 = ParamIsDefault(overrideA1) ? InitialA1_off : overrideA1
	Variable useAScale = ParamIsDefault(overrideAScale) ? AScale_off : overrideAScale
	
	
	// 
	if(ParamIsDefault(basePath))
		basePath = "root"
	endif
	if(ParamIsDefault(useMinFrame))
		useMinFrame = MinFrame
	endif
	if(ParamIsDefault(waveSuffix))
		waveSuffix = ""
	endif
	
	// 
	Variable numFolders = CountDataFoldersInPath(basePath, SampleName)
	Variable m, i, r
	String FolderName, folderPath
	
	if(!suppressOutput)
		Print "=== Duration (On-time) Analysis ==="
		Printf "BasePath: %s, FrameNum: %d, framerate: %.4f s, MinFrame: %d, suffix=%s\r", basePath, FrameNum, framerate, useMinFrame, waveSuffix
		Printf "Exp range: %d-%d, Tau1: %.4f s, Scale: %.1f\r", ExpMin_off, ExpMax_off, useTau1, useTauScale
	endif
	
	// 
	for(m = 0; m < numFolders; m += 1)
		FolderName = SampleName + num2str(m + 1)
		folderPath = basePath + ":" + SampleName + ":" + FolderName + ":"
		
		if(!DataFolderExists(basePath + ":" + SampleName + ":" + FolderName))
			break
		endif
		
		SetDataFolder $(basePath + ":" + SampleName + ":" + FolderName)
		
		if(!suppressOutput)
			Printf "\n  Processing %s...\r", FolderName
		endif
		
		// time_Duration:  [s]
		Make/O/N=(FrameNum) $(folderPath + "time_Duration" + waveSuffix) = (p + 1) * framerate
		Wave time_Duration = $(folderPath + "time_Duration" + waveSuffix)
		
		// P_Duration:  [%]
		Make/O/N=(FrameNum) $(folderPath + "P_Duration" + waveSuffix) = NaN
		Wave P_Duration = $(folderPath + "P_Duration" + waveSuffix)
		
		// 
		Wave/Z ROI_S0 = $(folderPath + "ROI_S0" + waveSuffix)
		Wave/Z Rframe_S0 = $(folderPath + "Rframe_S0" + waveSuffix)
		Wave/Z Rtime_S0 = $(folderPath + "Rtime_S0" + waveSuffix)
		
		if(!WaveExists(ROI_S0) || !WaveExists(Rframe_S0) || !WaveExists(Rtime_S0))
			Printf "    WARNING: Required waves not found\r"
			continue
		endif
		
		// Rframe_S0_Ontime: ORC
		Duplicate/O Rframe_S0, $(folderPath + "Rframe_S0_Ontime" + waveSuffix)
		Wave Rframe_S0_Ontime = $(folderPath + "Rframe_S0_Ontime" + waveSuffix)
		
		Variable totalpoints = numpnts(Rframe_S0)
		Variable TimeStart = 0
		Variable TimeEnd = FrameNum - 1
		
		// Off-rate correction: /
		if(cORC == 1)
			// Step 1: 1ROI
			Make/O/FREE/N=0 ROIsAtStart
			for(i = 0; i < totalpoints; i += 1)
				if(Rtime_S0[i] == TimeStart)
					// ROI
					Variable roiNum = ROI_S0[i]
					Variable found = 0
					Variable k
					for(k = 0; k < numpnts(ROIsAtStart); k += 1)
						if(ROIsAtStart[k] == roiNum)
							found = 1
							break
						endif
					endfor
					if(found == 0)
						InsertPoints numpnts(ROIsAtStart), 1, ROIsAtStart
						ROIsAtStart[numpnts(ROIsAtStart)-1] = roiNum
					endif
				endif
			endfor
			
			// Step 2: ROI
			Make/O/FREE/N=0 ROIsAtEnd
			for(i = 0; i < totalpoints; i += 1)
				if(Rtime_S0[i] == TimeEnd)
					roiNum = ROI_S0[i]
					found = 0
					for(k = 0; k < numpnts(ROIsAtEnd); k += 1)
						if(ROIsAtEnd[k] == roiNum)
							found = 1
							break
						endif
					endfor
					if(found == 0)
						InsertPoints numpnts(ROIsAtEnd), 1, ROIsAtEnd
						ROIsAtEnd[numpnts(ROIsAtEnd)-1] = roiNum
					endif
				endif
			endfor
			
			// Step 3: ROINaN
			Variable numStartROIs = numpnts(ROIsAtStart)
			Variable numEndROIs = numpnts(ROIsAtEnd)
			
			for(i = 0; i < totalpoints; i += 1)
				roiNum = ROI_S0[i]
				// 1ROI
				for(k = 0; k < numStartROIs; k += 1)
					if(roiNum == ROIsAtStart[k])
						Rframe_S0_Ontime[i] = NaN
						break
					endif
				endfor
				// ROI
				for(k = 0; k < numEndROIs; k += 1)
					if(roiNum == ROIsAtEnd[k])
						Rframe_S0_Ontime[i] = NaN
						break
					endif
				endfor
			endfor
			
			Printf "    ORC applied: excluded %d ROIs at start, %d ROIs at end\r", numStartROIs, numEndROIs
		endif
		
		// 
		// MinFrame100%
		// : time_Duration[i] = (i+1)*framerate 
		// MinFrame = index (MinFrame-1)
		Make/O/FREE/N=(FrameNum) countAtFrame = 0
		for(i = 0; i < FrameNum; i += 1)
			Extract/FREE/O Rframe_S0_Ontime, extracted, Rframe_S0_Ontime == i
			countAtFrame[i] = numpnts(extracted)
		endfor
		
		// MinFrame0-indexed: MinFrame-1
		Variable baselineIdx = useMinFrame - 1
		if(baselineIdx < 0)
			baselineIdx = 0
		endif
		Variable baselineCount = countAtFrame[baselineIdx]
		
		// MinFrameNaNindex < MinFrame-1MinFrame
		for(i = 0; i < FrameNum; i += 1)
			if(i < baselineIdx)
				P_Duration[i] = NaN
			elseif(baselineCount > 0)
				P_Duration[i] = countAtFrame[i] / baselineCount * 100
				// 0%NaN
				if(P_Duration[i] == 0)
					P_Duration[i] = NaN
				endif
			else
				P_Duration[i] = NaN
			endif
		endfor
		
		Printf "    Baseline at %d frames (idx=%d): %d trajectories\r", useMinFrame, baselineIdx, baselineCount
		
		// ===  ===
		String winName = "Duration_" + FolderName + waveSuffix
		DoWindow/K $winName
		
		Display/K=1/N=$winName P_Duration vs time_Duration
		ModifyGraph width={Aspect, 1.618}
		ModifyGraph tick=0, mirror=0
		ModifyGraph lowTrip(left)=0.0001
		ModifyGraph axisEnab(left)={0.05, 1}, axisEnab(bottom)={0.05, 1}
		ModifyGraph fStyle=1, fSize=16, font="Arial"
		ModifyGraph catGap(bottom)=0.3, barGap(bottom)=0
		Label left "\\F'Arial'\\Z14Percent remaining"
		Label bottom "\\F'Arial'\\Z14On-time [s]"
		SetAxis left 1, 100
		SetAxis bottom 0, *
		ModifyGraph log(left)=1
		ModifyGraph useBarStrokeRGB=1, rgb($("P_Duration" + waveSuffix))=(0, 0, 0)
		ModifyGraph mode($("P_Duration" + waveSuffix))=3, marker($("P_Duration" + waveSuffix))=19, msize($("P_Duration" + waveSuffix))=2
		
		String graphTitle = GetGraphTitleWithSeg(FolderName + " Duration (On-time)", waveSuffix)
		DoWindow/T $winName, graphTitle
		
		// === AIC ===
		Variable numstate, FitX_interval
		FitX_interval = numpnts(time_Duration) * 10
		
		// AIC
		Make/O/N=(ExpMax_off + 1) $(folderPath + "AIC_offrate" + waveSuffix) = NaN
		Wave AIC_offrate = $(folderPath + "AIC_offrate" + waveSuffix)
		
		// 
		for(numstate = ExpMin_off; numstate <= ExpMax_off; numstate += 1)
			// : A = A1 * Scale_A^(n-1), Tau = Tau1 * Scale_tau^(n-1)
			Make/O/D/N=(numstate * 2) $(folderPath + "W_coef_temp")
			Wave W_coef_temp = $(folderPath + "W_coef_temp")
			
			Variable n
			for(n = 0; n < numstate; n += 1)
				W_coef_temp[n * 2] = useA1 * (useAScale ^ n)  // A [%]
				W_coef_temp[n * 2 + 1] = useTau1 * (useTauScale ^ n)  // Tau [s]
			endfor
			
			// 
			Make/O/T/N=(numstate * 2) $(folderPath + "T_Constraints")
			Wave/T T_Constraints = $(folderPath + "T_Constraints")
			for(n = 0; n < numstate * 2; n += 1)
				T_Constraints[n] = "K" + num2str(n) + " > 0"
			endfor
			
			// /R - 
			Variable V_FitError = 0
			try
				if(numstate == 1)
					FuncFit/Q/L=(FitX_interval)/NTHR=0 SumExp1 W_coef_temp P_Duration /X=time_Duration /D /C=T_Constraints
				elseif(numstate == 2)
					FuncFit/Q/L=(FitX_interval)/NTHR=0 SumExp2 W_coef_temp P_Duration /X=time_Duration /D /C=T_Constraints
				elseif(numstate == 3)
					FuncFit/Q/L=(FitX_interval)/NTHR=0 SumExp3 W_coef_temp P_Duration /X=time_Duration /D /C=T_Constraints
				elseif(numstate == 4)
					FuncFit/Q/L=(FitX_interval)/NTHR=0 SumExp4 W_coef_temp P_Duration /X=time_Duration /D /C=T_Constraints
				elseif(numstate == 5)
					FuncFit/Q/L=(FitX_interval)/NTHR=0 SumExp5 W_coef_temp P_Duration /X=time_Duration /D /C=T_Constraints
				endif
			catch
				V_FitError = 1
			endtry
			
			if(V_FitError == 0)
				// AIC
				Make/O/FREE/N=(FrameNum) Res_temp
				if(numstate == 1)
					Res_temp = P_Duration[p] - SumExp1(W_coef_temp, time_Duration[p])
				elseif(numstate == 2)
					Res_temp = P_Duration[p] - SumExp2(W_coef_temp, time_Duration[p])
				elseif(numstate == 3)
					Res_temp = P_Duration[p] - SumExp3(W_coef_temp, time_Duration[p])
				elseif(numstate == 4)
					Res_temp = P_Duration[p] - SumExp4(W_coef_temp, time_Duration[p])
				elseif(numstate == 5)
					Res_temp = P_Duration[p] - SumExp5(W_coef_temp, time_Duration[p])
				endif
				
				// SS = Σ(residual^2)
				Make/O/FREE/N=(FrameNum) SS_temp
				SS_temp = Res_temp^2
				WaveStats/Q SS_temp
				
				// AIC = n * (ln(2π * MSE) + 1) + 2 * (k + 2)
				Variable AIC = V_npnts * (ln(2 * pi * V_avg) + 1) + 2 * (numstate * 2 + 2)
				AIC_offrate[numstate] = AIC
				
				Printf "    %d-exp: AIC=%.1f\r", numstate, AIC
			else
				Printf "    %d-exp: Fit failed\r", numstate
			endif
		endfor
		
		// ===  ===
		Variable MinAIC = WaveMin(AIC_offrate)
		Variable bestState = 0
		for(numstate = ExpMin_off; numstate <= ExpMax_off; numstate += 1)
			if(AIC_offrate[numstate] == MinAIC)
				bestState = numstate
				break
			endif
		endfor
		
		Printf "    Best model: %d-exp (AIC=%.1f)\r", bestState, MinAIC
		
		// 
		if(bestState > 0)
			Make/O/D/N=(bestState * 2) $(folderPath + "W_coef")
			Wave W_coef = $(folderPath + "W_coef")
			
			for(n = 0; n < bestState; n += 1)
				W_coef[n * 2] = useA1 * (useAScale ^ n)
				W_coef[n * 2 + 1] = useTau1 * (useTauScale ^ n)
			endfor
			
			Make/O/T/N=(bestState * 2) $(folderPath + "T_Constraints")
			Wave/T T_Constraints = $(folderPath + "T_Constraints")
			for(n = 0; n < bestState * 2; n += 1)
				T_Constraints[n] = "K" + num2str(n) + " > 0"
			endfor
			
			V_FitError = 0
			try
				if(bestState == 1)
					FuncFit/Q/L=(FitX_interval)/NTHR=0 SumExp1 W_coef P_Duration /X=time_Duration /D /C=T_Constraints
				elseif(bestState == 2)
					FuncFit/Q/L=(FitX_interval)/NTHR=0 SumExp2 W_coef P_Duration /X=time_Duration /D /C=T_Constraints
				elseif(bestState == 3)
					FuncFit/Q/L=(FitX_interval)/NTHR=0 SumExp3 W_coef P_Duration /X=time_Duration /D /C=T_Constraints
				elseif(bestState == 4)
					FuncFit/Q/L=(FitX_interval)/NTHR=0 SumExp4 W_coef P_Duration /X=time_Duration /D /C=T_Constraints
				elseif(bestState == 5)
					FuncFit/Q/L=(FitX_interval)/NTHR=0 SumExp5 W_coef P_Duration /X=time_Duration /D /C=T_Constraints
				endif
			catch
				V_FitError = 1
			endtry
			
			if(V_FitError == 0)
				// 
				Wave/Z fit_P_Duration = $(folderPath + "fit_P_Duration" + waveSuffix)
				if(WaveExists(fit_P_Duration))
					ModifyGraph rgb($("fit_P_Duration" + waveSuffix))=(65280, 0, 0), lsize($("fit_P_Duration" + waveSuffix))=1.5
				endif
				
				// ===  ===
				//  (Fraction_Duration)  (Tau_Duration)
				Make/O/N=(bestState) $(folderPath + "Fraction_Duration" + waveSuffix) = 0
				Make/O/N=(bestState) $(folderPath + "Tau_Duration" + waveSuffix) = 0
				Make/O/N=(bestState) $(folderPath + "koff_Duration" + waveSuffix) = 0
				Make/O/T/N=(bestState) $(folderPath + "ComponentLabel" + waveSuffix) = ""
				
				Wave Fraction_Duration = $(folderPath + "Fraction_Duration" + waveSuffix)
				Wave Tau_Duration = $(folderPath + "Tau_Duration" + waveSuffix)
				Wave koff_Duration = $(folderPath + "koff_Duration" + waveSuffix)
				Wave/T ComponentLabel = $(folderPath + "ComponentLabel" + waveSuffix)
				
				// A
				Variable SumA = 0
				for(n = 0; n < bestState; n += 1)
					SumA += W_coef[n * 2]
				endfor
				
				// 
				for(n = 0; n < bestState; n += 1)
					Fraction_Duration[n] = W_coef[n * 2] / SumA * 100  // [%]
					Tau_Duration[n] = W_coef[n * 2 + 1]  // [s]
					koff_Duration[n] = 1 / Tau_Duration[n]  // [/s]
					ComponentLabel[n] = "Comp " + num2str(n + 1)
				endfor
				
				// 
				Printf "    === Fit Results ===\r"
				for(n = 0; n < bestState; n += 1)
					Printf "      Comp%d: Fraction=%.1f%%, Tau=%.3f s, k_off=%.3f /s\r", n+1, Fraction_Duration[n], Tau_Duration[n], koff_Duration[n]
				endfor
				
				// === AICMin != Max===
				if(ExpMin_off != ExpMax_off)
					String aicWinName = "AIC_Duration_" + FolderName
					DoWindow/K $aicWinName
					
					// Xwave
					Make/O/N=(ExpMax_off - ExpMin_off + 1) $(folderPath + "AIC_StateNum") = ExpMin_off + p
					Wave AIC_StateNum = $(folderPath + "AIC_StateNum")
					
					// AIC
					Make/O/N=(ExpMax_off - ExpMin_off + 1) $(folderPath + "AIC_Values") = AIC_offrate[ExpMin_off + p]
					Wave AIC_Values = $(folderPath + "AIC_Values")
					
					Display/K=1/N=$aicWinName AIC_Values vs AIC_StateNum
					ModifyGraph mode=4, marker=19, msize=4
					ModifyGraph lsize=1.5
					ModifyGraph rgb=(0, 0, 0)
					ModifyGraph tick=2, fStyle=1, fSize=14, font="Arial"
				Label left "AIC"
				Label bottom "Number of Exponential Components"
				ModifyGraph width={Aspect, 1.618}
				
					// 
					Make/O/N=1 $(folderPath + "AIC_Best") = AIC_offrate[bestState]
					Make/O/N=1 $(folderPath + "AIC_BestX") = bestState
					Wave AIC_Best = $(folderPath + "AIC_Best")
					Wave AIC_BestX = $(folderPath + "AIC_BestX")
					
					AppendToGraph AIC_Best vs AIC_BestX
					ModifyGraph mode(AIC_Best)=3, marker(AIC_Best)=19, msize(AIC_Best)=6
					ModifyGraph rgb(AIC_Best)=(65280, 0, 0)
					
					DoWindow/T $aicWinName, FolderName + " Duration AIC"
				endif
				
				// ===  ===
				String tableName = "Table_Duration_" + FolderName
				DoWindow/K $tableName
				Edit/K=1/N=$tableName ComponentLabel, Fraction_Duration, Tau_Duration, koff_Duration
				DoWindow/T $tableName, FolderName + " Duration Parameters"
				
				// ===  ===
				String fracWinName = "Fraction_Duration_" + FolderName
				DoWindow/K $fracWinName
				
				Display/K=1/N=$fracWinName Fraction_Duration vs ComponentLabel
				ModifyGraph mode=5, hbFill=2
				ModifyGraph rgb=(0, 0, 50000)
				ModifyGraph useBarStrokeRGB=1, barStrokeRGB=(0, 0, 0)
				ModifyGraph tick=2, fStyle=1, fSize=14, font="Arial"
				ModifyGraph tick(bottom)=3, barGap(bottom)=0
				ModifyGraph catGap(bottom)=0.3
				Label left "Fraction (%)"
				Label bottom "Component"
				SetAxis left 0, *
				ModifyGraph width={Aspect, 1.618}
				DoWindow/T $fracWinName, FolderName + " Duration Fraction"
				
				// ===  ===
				String tauWinName = "Tau_Duration_" + FolderName
				DoWindow/K $tauWinName
				
				Display/K=1/N=$tauWinName Tau_Duration vs ComponentLabel
				ModifyGraph mode=5, hbFill=2
				ModifyGraph rgb=(0, 39168, 0)
				ModifyGraph useBarStrokeRGB=1, barStrokeRGB=(0, 0, 0)
				ModifyGraph tick=2, fStyle=1, fSize=14, font="Arial"
				ModifyGraph tick(bottom)=3, barGap(bottom)=0
				ModifyGraph catGap(bottom)=0.3
				Label left "Tau (s)"
				Label bottom "Component"
				SetAxis left 0, *
				ModifyGraph width={Aspect, 1.618}
				DoWindow/T $tauWinName, FolderName + " Duration Time Constants"
			else
				// : wave0
				Printf "    wave\r"
				Make/O/N=1 $(folderPath + "Fraction_Duration" + waveSuffix) = 0
				Make/O/N=1 $(folderPath + "Tau_Duration" + waveSuffix) = 0
				Make/O/N=1 $(folderPath + "koff_Duration" + waveSuffix) = 0
				Make/O/T/N=1 $(folderPath + "ComponentLabel" + waveSuffix) = "N/A"
				Make/O/D/N=2 $(folderPath + "W_coef") = 0
			endif
		else
			// bestState == 0: AIC
			Printf "    AICwave\r"
			Make/O/N=1 $(folderPath + "Fraction_Duration" + waveSuffix) = 0
			Make/O/N=1 $(folderPath + "Tau_Duration" + waveSuffix) = 0
			Make/O/N=1 $(folderPath + "koff_Duration" + waveSuffix) = 0
			Make/O/T/N=1 $(folderPath + "ComponentLabel" + waveSuffix) = "N/A"
			Make/O/D/N=2 $(folderPath + "W_coef") = 0
		endif
	endfor
	
	SetDataFolder root:
	Print "\nDuration analysis complete"
End

// -----------------------------------------------------------------------------
// SumExp1-5 
// y = A1*exp(-x/Tau1) + A2*exp(-x/Tau2) + ...
// -----------------------------------------------------------------------------
Function SumExp1(w, x) : FitFunc
	Wave w
	Variable x
	// w[0]=A1, w[1]=Tau1
	return w[0] * exp(-x / w[1])
End

Function SumExp2(w, x) : FitFunc
	Wave w
	Variable x
	// w[0]=A1, w[1]=Tau1, w[2]=A2, w[3]=Tau2
	return w[0] * exp(-x / w[1]) + w[2] * exp(-x / w[3])
End

Function SumExp3(w, x) : FitFunc
	Wave w
	Variable x
	return w[0] * exp(-x / w[1]) + w[2] * exp(-x / w[3]) + w[4] * exp(-x / w[5])
End

Function SumExp4(w, x) : FitFunc
	Wave w
	Variable x
	return w[0] * exp(-x / w[1]) + w[2] * exp(-x / w[3]) + w[4] * exp(-x / w[5]) + w[6] * exp(-x / w[7])
End

Function SumExp5(w, x) : FitFunc
	Wave w
	Variable x
	return w[0] * exp(-x / w[1]) + w[2] * exp(-x / w[3]) + w[4] * exp(-x / w[5]) + w[6] * exp(-x / w[7]) + w[8] * exp(-x / w[9])
End

// -----------------------------------------------------------------------------
// DisplayDurationGraph - Duration
// -----------------------------------------------------------------------------
Function DisplayDurationGraph(SampleName)
	String SampleName
	
	Variable numFolders = CountDataFolders(SampleName)
	Variable m, n
	String FolderName, folderPath
	
	for(m = 0; m < numFolders; m += 1)
		FolderName = SampleName + num2str(m + 1)
		folderPath = "root:" + SampleName + ":" + FolderName + ":"
		
		Wave/Z P_Duration = $(folderPath + "P_Duration")
		Wave/Z time_Duration = $(folderPath + "time_Duration")
		Wave/Z fit_P_Duration = $(folderPath + "fit_P_Duration")
		
		if(!WaveExists(P_Duration) || !WaveExists(time_Duration))
			continue
		endif
		
		// ===  ===
		String winName = "Duration_" + FolderName
		DoWindow/K $winName
		
		Display/K=1/N=$winName P_Duration vs time_Duration
		ModifyGraph width={Aspect, 1.618}
		ModifyGraph tick=0, mirror=0
		ModifyGraph lowTrip(left)=0.0001
		ModifyGraph axisEnab(left)={0.05, 1}, axisEnab(bottom)={0.05, 1}
		ModifyGraph fStyle=1, fSize=16, font="Arial"
		Label left "\\F'Arial'\\Z14Percent remaining"
		Label bottom "\\F'Arial'\\Z14On-time [s]"
		SetAxis left 1, 100
		SetAxis bottom 0, *
		ModifyGraph log(left)=1
		ModifyGraph rgb(P_Duration)=(0, 0, 0)
		ModifyGraph mode(P_Duration)=3, marker(P_Duration)=19, msize(P_Duration)=2
		
		if(WaveExists(fit_P_Duration))
			AppendToGraph fit_P_Duration vs time_Duration
			ModifyGraph rgb(fit_P_Duration)=(65280, 0, 0), lsize(fit_P_Duration)=1.5
		endif
		
		DoWindow/T $winName, FolderName + " Duration (On-time)"
		
		// === AICMin != Max===
		NVAR ExpMin_off = root:ExpMin_off
		NVAR ExpMax_off = root:ExpMax_off
		
		if(ExpMin_off != ExpMax_off)
			Wave/Z AIC_Values = $(folderPath + "AIC_Values")
			Wave/Z AIC_StateNum = $(folderPath + "AIC_StateNum")
			Wave/Z AIC_Best = $(folderPath + "AIC_Best")
			Wave/Z AIC_BestX = $(folderPath + "AIC_BestX")
			
			if(WaveExists(AIC_Values) && WaveExists(AIC_StateNum))
				String aicWinName = "AIC_Duration_" + FolderName
				DoWindow/K $aicWinName
				
				Display/K=1/N=$aicWinName AIC_Values vs AIC_StateNum
				ModifyGraph mode=4, marker=19, msize=4
				ModifyGraph lsize=1.5
				ModifyGraph rgb=(0, 0, 0)
				ModifyGraph tick=2, fStyle=1, fSize=14, font="Arial"
				Label left "AIC"
				Label bottom "Number of Exponential Components"
				ModifyGraph width={Aspect, 1.618}
				
				if(WaveExists(AIC_Best) && WaveExists(AIC_BestX))
					AppendToGraph AIC_Best vs AIC_BestX
					ModifyGraph mode(AIC_Best)=3, marker(AIC_Best)=19, msize(AIC_Best)=6
					ModifyGraph rgb(AIC_Best)=(65280, 0, 0)
				endif
				
				DoWindow/T $aicWinName, FolderName + " Duration AIC"
			endif
		endif
		
		// ===  ===
		Wave/Z Fraction_Duration = $(folderPath + "Fraction_Duration")
		Wave/Z Tau_Duration = $(folderPath + "Tau_Duration")
		Wave/T/Z ComponentLabel = $(folderPath + "ComponentLabel")
		
		if(WaveExists(Fraction_Duration) && WaveExists(ComponentLabel))
			// 
			String fracWinName = "Fraction_Duration_" + FolderName
			DoWindow/K $fracWinName
			
			Display/K=1/N=$fracWinName Fraction_Duration vs ComponentLabel
			ModifyGraph mode=5, hbFill=2
			ModifyGraph rgb=(0, 0, 50000)
			ModifyGraph useBarStrokeRGB=1, barStrokeRGB=(0, 0, 0)
			ModifyGraph tick=2, fStyle=1, fSize=14, font="Arial"
			ModifyGraph tick(bottom)=3, barGap(bottom)=0
			ModifyGraph catGap(bottom)=0.3
			Label left "Fraction (%)"
			Label bottom "Component"
			SetAxis left 0, *
			ModifyGraph width={Aspect, 1.618}
			DoWindow/T $fracWinName, FolderName + " Duration Fraction"
		endif
		
		if(WaveExists(Tau_Duration) && WaveExists(ComponentLabel))
			// 
			String tauWinName = "Tau_Duration_" + FolderName
			DoWindow/K $tauWinName
			
			Display/K=1/N=$tauWinName Tau_Duration vs ComponentLabel
			ModifyGraph mode=5, hbFill=2
			ModifyGraph rgb=(0, 39168, 0)
			ModifyGraph useBarStrokeRGB=1, barStrokeRGB=(0, 0, 0)
			ModifyGraph tick=2, fStyle=1, fSize=14, font="Arial"
			ModifyGraph tick(bottom)=3, barGap(bottom)=0
			ModifyGraph catGap(bottom)=0.3
			Label left "Tau (s)"
			Label bottom "Component"
			SetAxis left 0, *
			ModifyGraph width={Aspect, 1.618}
			DoWindow/T $tauWinName, FolderName + " Duration Time Constants"
		endif
	endfor
	
	SetDataFolder root:
End

// -----------------------------------------------------------------------------
// 
// -----------------------------------------------------------------------------
Function CalculateTrajectoryLengthDistribution(SampleName)
	String SampleName
	
	NVAR framerate = root:framerate
	NVAR MinFrame = root:MinFrame
	
	Variable numFolders = CountDataFolders(SampleName)
	Variable m
	String FolderName, folderPath
	
	// 
	Variable count, i, maxROI, n, r
	
	String resultsPath = "root:" + SampleName + ":Results"
	if(!DataFolderExists(resultsPath))
		NewDataFolder $resultsPath
	endif
	
	Make/O/N=0 $(resultsPath + ":TrajLength_all")
	Wave TrajLength_all = $(resultsPath + ":TrajLength_all")
	
	for(m = 0; m < numFolders; m += 1)
		FolderName = SampleName + num2str(m + 1)
		folderPath = "root:" + SampleName + ":" + FolderName + ":"
		SetDataFolder root:$(SampleName):$(FolderName)
		
		Wave/Z ROI_S0 = $(folderPath + "ROI_S0")
		Wave/Z Rframe_S0 = $(folderPath + "Rframe_S0")
		if(!WaveExists(ROI_S0))
			continue
		endif
		
		// ROI
		maxROI = WaveMax(ROI_S0)
		
		for(r = 1; r <= maxROI; r += 1)
			count = 0
			for(i = 0; i < numpnts(ROI_S0); i += 1)
				if(ROI_S0[i] == r)
					count += 1
				endif
			endfor
			
			if(count >= MinFrame)
				n = numpnts(TrajLength_all)
				InsertPoints n, 1, TrajLength_all
				TrajLength_all[n] = count * framerate
			endif
		endfor
	endfor
	
	SetDataFolder root:
End

// -----------------------------------------------------------------------------
// 
// -----------------------------------------------------------------------------
Function CreateTrajectoryLengthHistogram(SampleName, binSize, maxTime)
	String SampleName
	Variable binSize  // [sec]
	Variable maxTime  // [sec]
	
	String resultsPath = "root:" + SampleName + ":Results"
	SetDataFolder $resultsPath
	
	Wave/Z TrajLength_all
	if(!WaveExists(TrajLength_all))
		Print ""
		SetDataFolder root:
		return -1
	endif
	
	Variable nBins = ceil(maxTime / binSize)
	
	// 
	Make/O/N=(nBins) TrajHist, TrajHist_x
	TrajHist_x = binSize * (p + 0.5)
	
	Histogram/B={0, binSize, nBins} TrajLength_all, TrajHist
	
	// 
	Make/O/N=(nBins) SurvivalCurve, SurvivalTime
	SurvivalTime = TrajHist_x
	
	Variable total = sum(TrajHist)
	Variable cumSum = total
	
	Variable i
	for(i = 0; i < nBins; i += 1)
		SurvivalCurve[i] = cumSum / total * 100  // 
		cumSum -= TrajHist[i]
	endfor
	
	// 
	Display/K=1 SurvivalCurve vs SurvivalTime
	ModifyGraph mode=3, marker=19, msize=2
	ModifyGraph tick=2, mirror=1, fStyle=1, fSize=14, font="Arial"
	Label left "Percent remaining"
	Label bottom "Time (s)"
	ModifyGraph log(left)=1
	SetAxis left 1, 100
	ModifyGraph width={Aspect, 1.618}
	
	SetDataFolder root:
	return 0
End

// -----------------------------------------------------------------------------
// Off-rate 
// -----------------------------------------------------------------------------

// =============================================================================
// HMM State Transition Analysis
// =============================================================================

// -----------------------------------------------------------------------------
// TransA
// τ_ij = framerate / TransA[i][j] i≠j
// τ_i = framerate / (1 - TransA[i][i]) i
// -----------------------------------------------------------------------------
Function CalculateTransitionTau(SampleName)
	String SampleName
	
	NVAR framerate = root:framerate
	NVAR Dstate = root:Dstate
	
	// 
	Variable numCells, numFolders, i, j, k, cellIdx
	Variable pStay, pTrans, totalWeight
	String samplePath, resultsPath, folderName, cellPath
	String tableName
	
	if(Dstate < 2)
		Print "Error: Dstate must be >= 2 for transition analysis"
		return -1
	endif
	
	// TransA
	samplePath = "root:" + SampleName
	if(!DataFolderExists(samplePath))
		Print "Error: Sample folder not found: " + SampleName
		return -1
	endif
	
	// Results
	resultsPath = samplePath + ":Results"
	NewDataFolder/O $resultsPath
	SetDataFolder $resultsPath
	
	// TransA, Ctr
	Make/O/N=(Dstate, Dstate) TransA_avg = 0
	Make/O/N=(Dstate) Ctr_avg = 0
	numCells = 0
	
	// Tau
	SetDataFolder $samplePath
	numFolders = CountObjects("", 4)
	
	Print "=========================================="
	Printf "State Transition Analysis: %s\r", SampleName
	Print "=========================================="
	
	for(i = 0; i < numFolders; i += 1)
		folderName = GetIndexedObjName("", 4, i)
		if(StringMatch(folderName, "Results") || StringMatch(folderName, "Matrix"))
			continue
		endif
		
		cellPath = samplePath + ":" + folderName
		Wave/Z TransA_cell = $(cellPath + ":TransA")
		Wave/Z Ctr_cell = $(cellPath + ":Ctr")
		
		if(WaveExists(TransA_cell) && WaveExists(Ctr_cell))
			// 
			TransA_avg += TransA_cell
			Ctr_avg += Ctr_cell
			numCells += 1
			
			// TauTransition, TransitionRate
			SetDataFolder $cellPath
			
			Make/O/N=(Dstate, Dstate) TauTransition_cell = NaN
			Make/O/N=(Dstate, Dstate) TransitionRate_cell = NaN
			Make/O/N=(Dstate) TauDwell_cell = NaN
			Make/O/N=(Dstate) StatePopulation_cell = 0
			
			for(j = 0; j < Dstate; j += 1)
				pStay = TransA_cell[j][j]
				if(pStay < 1)
					TauDwell_cell[j] = framerate / (1 - pStay)
				endif
				
				for(k = 0; k < Dstate; k += 1)
					pTrans = TransA_cell[j][k]
					if(j != k && pTrans > 0)
						TauTransition_cell[j][k] = framerate / pTrans
						TransitionRate_cell[j][k] = pTrans / framerate
					endif
				endfor
			endfor
			
			// StatePopulation
			totalWeight = 0
			for(j = 0; j < Dstate; j += 1)
				StatePopulation_cell[j] = TransA_cell[j][j]
				totalWeight += StatePopulation_cell[j]
			endfor
			if(totalWeight > 0)
				StatePopulation_cell /= totalWeight
				StatePopulation_cell *= 100
			endif
			
			// 
			tableName = "TransitionTable_" + folderName
			DoWindow/K $tableName
			Edit/K=1/N=$tableName TransA_cell, TauTransition_cell, TransitionRate_cell, TauDwell_cell, Ctr_cell, StatePopulation_cell as "Transition: " + folderName
			
			Printf "\n--- Cell: %s ---\r", folderName
			for(j = 0; j < Dstate; j += 1)
				Printf "  State %d: D=%.4f, P=%.1f%%, τ_dwell=%.3fs\r", j+1, Ctr_cell[j], StatePopulation_cell[j], TauDwell_cell[j]
			endfor
			
			SetDataFolder $samplePath
		endif
	endfor
	
	if(numCells == 0)
		Print "Error: No TransA/Ctr data found in cells"
		SetDataFolder root:
		return -1
	endif
	
	// 
	TransA_avg /= numCells
	Ctr_avg /= numCells
	
	SetDataFolder $resultsPath
	
	// 
	Make/O/N=(Dstate, Dstate) TauTransition = NaN
	Make/O/N=(Dstate) TauDwell = NaN
	Make/O/N=(Dstate, Dstate) TransitionRate = NaN
	
	// Population
	Make/O/N=(Dstate) StatePopulation = 0
	
	for(i = 0; i < Dstate; i += 1)
		pStay = TransA_avg[i][i]
		if(pStay < 1)
			TauDwell[i] = framerate / (1 - pStay)
		endif
		
		for(j = 0; j < Dstate; j += 1)
			pTrans = TransA_avg[i][j]
			if(i != j && pTrans > 0)
				TauTransition[i][j] = framerate / pTrans
				TransitionRate[i][j] = pTrans / framerate
			endif
		endfor
	endfor
	
	// Population
	totalWeight = 0
	for(i = 0; i < Dstate; i += 1)
		StatePopulation[i] = TransA_avg[i][i]
		totalWeight += StatePopulation[i]
	endfor
	StatePopulation /= totalWeight
	StatePopulation *= 100  // 
	
	// 
	Printf "\n========== Average (n=%d cells) ==========\r", numCells
	Printf "Framerate: %.4f s/frame\r", framerate
	
	Print "\n--- Diffusion Coefficients & Population ---"
	for(i = 0; i < Dstate; i += 1)
		Printf "  State %d: D = %.4f µm²/s, Population = %.1f%%\r", i+1, Ctr_avg[i], StatePopulation[i]
	endfor
	
	Print "\n--- Dwell Times (τ_dwell) ---"
	for(i = 0; i < Dstate; i += 1)
		Printf "  State %d: τ = %.3f s\r", i+1, TauDwell[i]
	endfor
	
	Print "\n--- Transition Time Constants (τ_ij) and Rate (k_ij) ---"
	for(i = 0; i < Dstate; i += 1)
		for(j = 0; j < Dstate; j += 1)
			if(i != j && numtype(TauTransition[i][j]) == 0)
				Printf "  %d → %d: τ = %.3f s, k = %.4f /s\r", i+1, j+1, TauTransition[i][j], TransitionRate[i][j]
			endif
		endfor
	endfor
	
	// 
	tableName = "TransitionTable_Average"
	DoWindow/K $tableName
	Edit/K=1/N=$tableName TransA_avg, TauTransition, TransitionRate, TauDwell, Ctr_avg, StatePopulation as "Transition Parameters (Average)"
	
	SetDataFolder root:
	return numCells
End

// -----------------------------------------------------------------------------
// τij/kij
// cKinOutputTau=1: τ, cKinOutputTau=0: k
// -----------------------------------------------------------------------------
Function DisplayTauCategoryPlotForCell(SampleName, CellName)
	String SampleName, CellName
	
	NVAR Dstate = root:Dstate
	NVAR/Z cKinOutputTau = root:cKinOutputTau
	Variable outputTau = cKinOutputTau
	
	String cellPath = "root:" + SampleName + ":" + CellName
	if(!DataFolderExists(cellPath))
		Print "Error: Cell folder not found: " + CellName
		return -1
	endif
	
	SetDataFolder $cellPath
	
	Wave/Z TauTransition_cell, TauDwell_cell, TransitionRate_cell
	if(!WaveExists(TauTransition_cell))
		Print "Error: TauTransition_cell not found for: " + CellName
		SetDataFolder root:
		return -1
	endif
	
	// 
	Variable numTransitions = Dstate * (Dstate - 1)
	Variable numTotal = numTransitions + Dstate
	
	Make/O/N=(numTotal) TauValues_cell = NaN
	Make/O/T/N=(numTotal) TauLabels_cell = ""
	
	Variable idx = 0
	Variable i, j
	String prefix = SelectString(outputTau, "k_", "τ_")
	
	// /
	for(i = 0; i < Dstate; i += 1)
		TauLabels_cell[idx] = prefix + num2str(i+1) + num2str(i+1) + " (dwell)"
		if(outputTau)
			TauValues_cell[idx] = TauDwell_cell[i]
		else
			// k_dwell = 1/τ_dwell
			if(TauDwell_cell[i] > 0)
				TauValues_cell[idx] = 1 / TauDwell_cell[i]
			endif
		endif
		idx += 1
	endfor
	
	// /
	for(i = 0; i < Dstate; i += 1)
		for(j = 0; j < Dstate; j += 1)
			if(i != j)
				TauLabels_cell[idx] = prefix + num2str(i+1) + num2str(j+1)
				if(outputTau)
					TauValues_cell[idx] = TauTransition_cell[i][j]
				else
					// k = 1/τ  TransitionRate_cell 
					if(WaveExists(TransitionRate_cell))
						TauValues_cell[idx] = TransitionRate_cell[i][j]
					elseif(TauTransition_cell[i][j] > 0)
						TauValues_cell[idx] = 1 / TauTransition_cell[i][j]
					endif
				endif
				idx += 1
			endif
		endfor
	endfor
	
	// 
	String winName = SelectString(outputTau, "kCategoryPlot_", "TauCategoryPlot_") + CellName
	DoWindow/K $winName
	
	String graphTitle = SelectString(outputTau, "Transition Rate Constants: ", "Transition Time Constants: ") + CellName
	Display/K=1/N=$winName/W=(100,100,500,400) TauValues_cell vs TauLabels_cell as graphTitle
	
	// Summary Plot
	ModifyGraph mode=5, hbFill=2
	ModifyGraph rgb=(0,0,65535)
	ModifyGraph useBarStrokeRGB=1, barStrokeRGB=(0,0,0)
	
	// 
	ModifyGraph tick=2, mirror=0, fStyle=1, fSize=14, font="Arial"
	ModifyGraph tick(bottom)=3
	ModifyGraph tkLblRot(bottom)=90
	ModifyGraph catGap(bottom)=0.5
	
	if(outputTau)
		Label left "\\F'Arial'\\Z14τ [s]"
	else
		Label left "\\F'Arial'\\Z14k [/s]"
	endif
	ModifyGraph log(left)=1
	ModifyGraph width={Aspect, 1.618}
	SetAxis left 0.01, *
	
	SetDataFolder root:
	return 0
End

// -----------------------------------------------------------------------------
// τij/kijComparison
// cKinOutputTau=1: τ, cKinOutputTau=0: k
// -----------------------------------------------------------------------------
Function DisplayTauCategoryPlot(SampleName)
	String SampleName
	
	NVAR Dstate = root:Dstate
	NVAR/Z cKinOutputTau = root:cKinOutputTau
	Variable outputTau = cKinOutputTau
	
	String resultsPath = "root:" + SampleName + ":Results"
	if(!DataFolderExists(resultsPath))
		Variable result
		result = CalculateTransitionTau(SampleName)
		if(result < 0)
			return -1
		endif
	endif
	
	SetDataFolder $resultsPath
	
	Wave/Z TauTransition, TauDwell, TransitionRate
	if(!WaveExists(TauTransition))
		Print "Error: TauTransition not found. Run CalculateTransitionTau first."
		SetDataFolder root:
		return -1
	endif
	
	// 
	Variable numTransitions = Dstate * (Dstate - 1)
	Variable numTotal = numTransitions + Dstate
	
	Make/O/N=(numTotal) TauValues = NaN
	Make/O/T/N=(numTotal) TauLabels = ""
	
	Variable idx = 0
	Variable i, j
	String prefix = SelectString(outputTau, "k_", "τ_")
	
	// /
	for(i = 0; i < Dstate; i += 1)
		TauLabels[idx] = prefix + num2str(i+1) + num2str(i+1) + " (dwell)"
		if(outputTau)
			TauValues[idx] = TauDwell[i]
		else
			if(TauDwell[i] > 0)
				TauValues[idx] = 1 / TauDwell[i]
			endif
		endif
		idx += 1
	endfor
	
	// /
	for(i = 0; i < Dstate; i += 1)
		for(j = 0; j < Dstate; j += 1)
			if(i != j)
				TauLabels[idx] = prefix + num2str(i+1) + num2str(j+1)
				if(outputTau)
					TauValues[idx] = TauTransition[i][j]
				else
					if(WaveExists(TransitionRate))
						TauValues[idx] = TransitionRate[i][j]
					elseif(TauTransition[i][j] > 0)
						TauValues[idx] = 1 / TauTransition[i][j]
					endif
				endif
				idx += 1
			endif
		endfor
	endfor
	
	// 
	String winName = SelectString(outputTau, "kCategoryPlot_", "TauCategoryPlot_") + SampleName
	DoWindow/K $winName
	
	String graphTitle = SelectString(outputTau, "Transition Rate Constants: ", "Transition Time Constants: ") + SampleName
	Display/K=1/N=$winName/W=(100,100,500,400) TauValues vs TauLabels as graphTitle
	
	// Summary Plot
	ModifyGraph mode=5, hbFill=2
	ModifyGraph rgb=(0,0,65535)
	ModifyGraph useBarStrokeRGB=1, barStrokeRGB=(0,0,0)
	
	// 
	ModifyGraph tick=2, mirror=0, fStyle=1, fSize=14, font="Arial"
	ModifyGraph tick(bottom)=3
	ModifyGraph tkLblRot(bottom)=90
	ModifyGraph catGap(bottom)=0.5
	
	if(outputTau)
		Label left "\\F'Arial'\\Z14τ [s]"
	else
		Label left "\\F'Arial'\\Z14k [/s]"
	endif
	ModifyGraph log(left)=1
	ModifyGraph width={Aspect, 1.618}
	SetAxis left 0.01, *
	
	SetDataFolder root:
	return 0
End

// -----------------------------------------------------------------------------
// PDF
// - 2: 
// - 3,4,5: 
// - Population
// - (1/τ)
// - : S1=, S2=, S3=, S4=, S5=
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// PDF
// - 2: 
// - 3,4,5: 
// - Population
// - (1/τ)
// - : S1=, S2=, S3=, S4=, S5=
// - TextBoxAnnotation
// -----------------------------------------------------------------------------
Function DrawStateTransitionDiagram(SampleName)
	String SampleName
	
	NVAR Dstate = root:Dstate
	NVAR framerate = root:framerate
	NVAR/Z cKinOutputTau = root:cKinOutputTau
	Variable outputTau = cKinOutputTau
	
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
	
	// 
	Variable calcResult, i, j
	Variable baseRadius, angle, centerX, centerY
	Variable maxPop, markerSize, circleRadius, circleRadius2
	Variable axisRange, labelX, labelY, labelOffset
	Variable x1, y1, x2, y2, dx, dy, dist
	Variable arrowStartX, arrowStartY, arrowEndX, arrowEndY
	Variable midX, midY, rate, maxRate, perpX, perpY, lineThick
	Variable markerSize1, markerSize2, axisPerPoint
	Variable arrowLength, kValue, labelPerpX, labelPerpY
	Variable centerMidX, centerMidY, maxArrowLen, gapFromMarker
	Variable avgMarkerSize, arrowOffset, labelTauOffset
	Variable arrowNum, arrowLenAxis
	String samplePath, resultsPath, winName
	String labelStr, stateName, traceName
	String stateXName, stateYName, boxName
	
	samplePath = "root:" + SampleName
	resultsPath = samplePath + ":Results"
	
	if(!DataFolderExists(resultsPath))
		calcResult = CalculateTransitionTau(SampleName)
		if(calcResult < 0)
			return -1
		endif
	endif
	
	SetDataFolder $resultsPath
	
	Wave/Z TransA_avg, TauTransition, TauDwell, Ctr_avg, StatePopulation
	if(!WaveExists(TransA_avg) || !WaveExists(TauDwell))
		Print "Error: Run CalculateTransitionTau first"
		SetDataFolder root:
		return -1
	endif
	
	// 
	winName = "StateTransition_" + SampleName
	DoWindow/K $winName
	Display/K=1/N=$winName/W=(100,100,700,700) as "State Transition Diagram: " + SampleName
	
	// 
	Make/O/N=(6, 3) StateColors
	StateColors[0][0] = 0;       StateColors[0][1] = 0;       StateColors[0][2] = 65280
	StateColors[1][0] = 65280;   StateColors[1][1] = 43520;   StateColors[1][2] = 0
	StateColors[2][0] = 0;       StateColors[2][1] = 39168;   StateColors[2][2] = 0
	StateColors[3][0] = 65280;   StateColors[3][1] = 0;       StateColors[3][2] = 0
	StateColors[4][0] = 39168;   StateColors[4][1] = 0;       StateColors[4][2] = 39168
	StateColors[5][0] = 0;       StateColors[5][1] = 0;       StateColors[5][2] = 0
	
	// 
	Make/O/T/N=(5, 5) StateNames
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
	
	// L threshold
	Variable lThresh = 1.0
	ControlInfo/W=SMI_MainPanel tab4_sv_lthresh
	if(V_flag != 0)
		lThresh = V_Value
	endif
	
	// 20%baseRadius 4.5 → 5.4
	Make/O/N=(Dstate) StateX_pos, StateY_pos
	centerX = 0
	centerY = 0
	baseRadius = 5.4
	
	if(Dstate == 2)
		StateX_pos[0] = -4.05  // 5.4 * 0.75
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
	maxPop = WaveMax(StatePopulation)
	if(maxPop <= 0)
		maxPop = 100
	endif
	
	// 
	maxRate = 0
	Variable minRate = inf
	for(i = 0; i < Dstate; i += 1)
		for(j = 0; j < Dstate; j += 1)
			if(i != j && numtype(TauTransition[i][j]) == 0 && TauTransition[i][j] > 0)
				rate = 1.0 / TauTransition[i][j]
				if(rate > maxRate)
					maxRate = rate
				endif
				if(rate < minRate)
					minRate = rate
				endif
			endif
		endfor
	endfor
	if(maxRate == 0)
		maxRate = 1
	endif
	if(minRate == inf || minRate <= 0)
		minRate = maxRate / 10
	endif
	
	// 
	Variable minMarkerSize = 15
	Variable maxMarkerSize = 50
	axisPerPoint = 0.018
	
	// 
	avgMarkerSize = 0
	for(i = 0; i < Dstate; i += 1)
		markerSize = minMarkerSize + (maxMarkerSize - minMarkerSize) * (StatePopulation[i] / maxPop)
		avgMarkerSize += markerSize
	endfor
	avgMarkerSize /= Dstate
	
	// ===== Use Aligned Trajectory  =====
	if(useAlignedTraj)
		// Average Aligned Trajectory
		Wave/Z checkWave = AvgAligned_X_S1
		if(!WaveExists(checkWave))
			Print "WARNING: Average Aligned Trajectory data not found."
			Print "         Please run 'Average Aligned Trajectory' first."
			Print "         Falling back to standard marker mode."
			useAlignedTraj = 0
		endif
	endif
	
	if(useAlignedTraj)
		// Trace_HMM
		Make/O/N=(6, 3) TrajColorsRGB
		TrajColorsRGB[0][0] = 32768;  TrajColorsRGB[0][1] = 40704;  TrajColorsRGB[0][2] = 65280
		TrajColorsRGB[1][0] = 65280;  TrajColorsRGB[1][1] = 65280;  TrajColorsRGB[1][2] = 0
		TrajColorsRGB[2][0] = 0;      TrajColorsRGB[2][1] = 65280;  TrajColorsRGB[2][2] = 0
		TrajColorsRGB[3][0] = 65280;  TrajColorsRGB[3][1] = 0;      TrajColorsRGB[3][2] = 0
		TrajColorsRGB[4][0] = 65280;  TrajColorsRGB[4][1] = 40704;  TrajColorsRGB[4][2] = 32768
		TrajColorsRGB[5][0] = 65535;  TrajColorsRGB[5][1] = 65535;  TrajColorsRGB[5][2] = 65535
		
		for(i = 0; i < Dstate; i += 1)
			// CreateAverageAlignedTrajectory
			String avgXName = "AvgAligned_X_S" + num2str(i+1)
			String avgYName = "AvgAligned_Y_S" + num2str(i+1)
			
			Wave/Z avgXWave = $avgXName
			Wave/Z avgYWave = $avgYName
			
			if(WaveExists(avgXWave) && WaveExists(avgYWave) && numpnts(avgXWave) > 0)
				// StateX_pos[i], StateY_pos[i]
				String diagAvgXName = "DiagAvgTraj_X_S" + num2str(i+1)
				String diagAvgYName = "DiagAvgTraj_Y_S" + num2str(i+1)
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
			
			// L
			String avgLCircleXName = "AvgLCircle_X_S" + num2str(i+1)
			String avgLCircleYName = "AvgLCircle_Y_S" + num2str(i+1)
			Wave/Z avgLCircleX = $avgLCircleXName
			Wave/Z avgLCircleY = $avgLCircleYName
			
			if(WaveExists(avgLCircleX) && WaveExists(avgLCircleY))
				// StateX_pos[i], StateY_pos[i]
				String diagLCircleXName = "DiagAvgLCircle_X_S" + num2str(i+1)
				String diagLCircleYName = "DiagAvgLCircle_Y_S" + num2str(i+1)
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
		
		KillWaves/Z TrajColorsRGB
	else
		// ===== =====
		// 
		for(i = 0; i < Dstate; i += 1)
			stateXName = "StateX_" + num2str(i+1)
			stateYName = "StateY_" + num2str(i+1)
			Make/O/N=1 $stateXName, $stateYName
			Wave stateX = $stateXName
			Wave stateY = $stateYName
			stateX[0] = StateX_pos[i]
			stateY[0] = StateY_pos[i]
			
			AppendToGraph stateY vs stateX
			traceName = stateYName
			
			markerSize = minMarkerSize + (maxMarkerSize - minMarkerSize) * (StatePopulation[i] / maxPop)
			
			ModifyGraph mode($traceName)=3
			ModifyGraph marker($traceName)=19
			ModifyGraph msize($traceName)=markerSize
			ModifyGraph rgb($traceName)=(StateColors[i][0], StateColors[i][1], StateColors[i][2])
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
	
	// TextBox
	for(i = 0; i < Dstate; i += 1)
		stateName = StateNames[nameIdx][i]
		markerSize = minMarkerSize + (maxMarkerSize - minMarkerSize) * (StatePopulation[i] / maxPop)
		labelOffset = markerSize * axisPerPoint + 1.0
		
		if(Dstate == 2)
			labelX = StateX_pos[i]
			labelY = StateY_pos[i] + labelOffset * (stateLabelPct / 100)
		else
			// : 90
			angle = Pi/2 - 2*Pi*i/Dstate
			Variable labelAngle = angle - Pi/2  // 90
			labelX = StateX_pos[i] + labelOffset * cos(labelAngle) * (stateLabelPct / 100)
			labelY = StateY_pos[i] + labelOffset * sin(labelAngle) * (stateLabelPct / 100)
		endif
		
		// TextBox
		boxName = "State" + num2str(i+1)
		sprintf labelStr, "\\Z14\\f01%s\r\\Z11D=%.3f µm²/s\rP=%.1f%%", stateName, Ctr_avg[i], StatePopulation[i]
		TextBox/C/N=$boxName/F=0/B=1/A=MC/X=(labelX/axisRange*50)/Y=(labelY/axisRange*50)
		AppendText/N=$boxName labelStr
	endfor
	
	// 
	SetDrawLayer UserFront
	
	arrowOffset = avgMarkerSize * axisPerPoint * (arrowOffsetPct / 100) * 2  // 
	labelTauOffset = avgMarkerSize * axisPerPoint * (tauLabelPct / 100) * 3  // 
	gapFromMarker = avgMarkerSize * axisPerPoint * 0.20
	
	arrowNum = 0
	arrowLenAxis = 8 * axisPerPoint  // axis
	for(i = 0; i < Dstate; i += 1)
		for(j = 0; j < Dstate; j += 1)
			if(i != j && numtype(TauTransition[i][j]) == 0 && TauTransition[i][j] > 0)
				x1 = StateX_pos[i]
				y1 = StateY_pos[i]
				x2 = StateX_pos[j]
				y2 = StateY_pos[j]
				
				dx = x2 - x1
				dy = y2 - y1
				dist = sqrt(dx^2 + dy^2)
				
				centerMidX = (x1 + x2) / 2
				centerMidY = (y1 + y2) / 2
				
				markerSize1 = minMarkerSize + (maxMarkerSize - minMarkerSize) * (StatePopulation[i] / maxPop)
				markerSize2 = minMarkerSize + (maxMarkerSize - minMarkerSize) * (StatePopulation[j] / maxPop)
				circleRadius = markerSize1 * axisPerPoint * 0.55
				circleRadius2 = markerSize2 * axisPerPoint * 0.55
				
				// 
				perpX = dy / dist
				perpY = -dx / dist
				
				kValue = 1.0 / TauTransition[i][j]
				maxArrowLen = dist - circleRadius - circleRadius2 - 2 * gapFromMarker
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
				
				// τ: 10%τ
				labelPerpX = labelTauOffset * perpX
				labelPerpY = labelTauOffset * perpY
				
				// τ1TextBox
				// i < j: τ / i > j: τ
				// TextBox
				Variable xPct = (midX + labelPerpX) / axisRange * 50
				Variable yPct = (midY + labelPerpY) / axisRange * 50
				if(i < j)
					// →: τ
					if(outputTau)
						sprintf labelStr, "\\JC\\Z%d\\K(65280,0,0)τ=%.2f s\r\\Z%d\\K(0,0,0)%s", fontSize+2, TauTransition[i][j], fontSize, arrowStr
					else
						sprintf labelStr, "\\JC\\Z%d\\K(65280,0,0)k=%.3f/s\r\\Z%d\\K(0,0,0)%s", fontSize+2, kValue, fontSize, arrowStr
					endif
				else
					// →: τ
					if(outputTau)
						sprintf labelStr, "\\JC\\Z%d\\K(0,0,0)%s\r\\Z%d\\K(65280,0,0)τ=%.2f s", fontSize, arrowStr, fontSize+2, TauTransition[i][j]
					else
						sprintf labelStr, "\\JC\\Z%d\\K(0,0,0)%s\r\\Z%d\\K(65280,0,0)k=%.3f/s", fontSize, arrowStr, fontSize+2, kValue
					endif
				endif
				TextBox/C/N=$boxName/F=0/B=1/A=MC/X=(xPct)/Y=(yPct)/O=(arrowAngle)/LS=(lineSpace) labelStr
			endif
		endfor
	endfor
	
	// 14Arial
	String titleStr
	sprintf titleStr, "\\F'Arial'\\Z14State Transition Diagram: %s (%d states)\r\\Z12framerate = %.3f s", SampleName, Dstate, framerate
	TextBox/C/N=title/F=0/B=1/A=LT/X=0/Y=0 titleStr
	
	// Use Aligned Trajectory
	if(useAlignedTraj)
		// : 1 µm trajScale
		Variable scaleBarLen = 1.0 * trajScale  // 1 µm
		Variable scaleBarX1 = -axisRange * 0.90
		Variable scaleBarX2 = scaleBarX1 + scaleBarLen
		Variable scaleBarYPos = axisRange * 0.65  // 
		
		Make/O/N=2 ScaleBar_X, ScaleBar_Y
		ScaleBar_X[0] = scaleBarX1
		ScaleBar_X[1] = scaleBarX2
		ScaleBar_Y[0] = scaleBarYPos
		ScaleBar_Y[1] = scaleBarYPos
		
		AppendToGraph ScaleBar_Y vs ScaleBar_X
		ModifyGraph rgb(ScaleBar_Y)=(0,0,0)
		ModifyGraph lsize(ScaleBar_Y)=2
		
		// 
		String scaleLabel
		sprintf scaleLabel, "\\Z10\\K(0,0,0)1 µm"
		Variable scaleLabelX = (scaleBarX1 + scaleBarX2) / 2
		Variable scaleLabelYPos = scaleBarYPos - axisRange * 0.10
		TextBox/C/N=scalebar/F=0/B=1/A=MC/X=(scaleLabelX/axisRange*50)/Y=(scaleLabelYPos/axisRange*50) scaleLabel
	endif
	
	KillWaves/Z StateX_pos, StateY_pos, StateColors, StateNames
	
	SetDataFolder root:
	return 0
End

// -----------------------------------------------------------------------------
// 
// - MSDD, L
// - StepSizePopulation
// - LL-threshold
// -----------------------------------------------------------------------------
Function DrawStateTransitionDiagramForCell(SampleName, CellName)
	String SampleName, CellName

	// [nofallback] P_values NaN handling: when P_values[i] is NaN,
	// keep NaN instead of substituting 100/Dstate. Downstream Igor
	// drawing commands gracefully skip NaN-sized markers.

	NVAR Dstate = root:Dstate
	NVAR framerate = root:framerate
	NVAR/Z LThreshold = root:LThreshold
	NVAR/Z cKinOutputTau = root:cKinOutputTau
	Variable outputTau = cKinOutputTau
	
	// L-threshold1.0
	Variable lThresh = 1.0
	ControlInfo/W=SMI_MainPanel tab4_sv_lthresh
	if(V_flag != 0)
		lThresh = V_Value
	endif
	
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
	
	// 
	Variable i, j
	Variable baseRadius, angle, centerX, centerY
	Variable maxPop, markerSize, circleRadius, circleRadius2
	Variable axisRange, labelX, labelY, labelOffset
	Variable x1, y1, x2, y2, dx, dy, dist
	Variable arrowStartX, arrowStartY, arrowEndX, arrowEndY
	Variable midX, midY, rate, maxRate, perpX, perpY, lineThick
	Variable markerSize1, markerSize2, axisPerPoint
	Variable arrowLength, kValue, labelPerpX, labelPerpY
	Variable centerMidX, centerMidY, maxArrowLen, gapFromMarker
	Variable avgMarkerSize, arrowOffset, labelTauOffset
	Variable arrowNum, arrowLenAxis
	Variable lCircleRadius
	String cellPath, winName
	String labelStr, stateName, traceName
	String stateXName, stateYName, boxName
	
	cellPath = "root:" + SampleName + ":" + CellName
	if(!DataFolderExists(cellPath))
		Print "Error: Cell folder not found: " + CellName
		return -1
	endif
	
	SetDataFolder $cellPath
	
	// WaveCtrWave_cell
	Wave/Z TransA = TransA
	Wave/Z Ctr = Ctr
	Wave/Z TauTransition_cell = TauTransition_cell
	Wave/Z TauDwell_cell = TauDwell_cell
	Wave/Z StatePopulation_cell = StatePopulation_cell
	
	if(!WaveExists(TauTransition_cell))
		Print "Error: TauTransition_cell not found for: " + CellName
		SetDataFolder root:
		return -1
	endif
	
	if(!WaveExists(Ctr))
		Print "Error: Ctr not found for: " + CellName
		SetDataFolder root:
		return -1
	endif
	
	// D, L, PopulationWave
	Make/O/N=(Dstate) D_values = NaN, L_values = NaN, P_values = NaN
	
	// MSDD, Lcoef_MSD_Sn0=D, 1=L
	for(i = 0; i < Dstate; i += 1)
		String suffix = "_S" + num2str(i + 1)
		String coefMSDName = "coef_MSD" + suffix
		Wave/Z coef_MSD = $(cellPath + ":" + coefMSDName)
		
		if(WaveExists(coef_MSD) && numpnts(coef_MSD) >= 1)
			// coef_MSD[0] = D
			D_values[i] = coef_MSD[0]
			// coef_MSD[1] = L
			if(numpnts(coef_MSD) >= 2)
				L_values[i] = coef_MSD[1]
			else
				L_values[i] = NaN
			endif
		else
			// coef_MSDCtr
			D_values[i] = Ctr[i]
			L_values[i] = NaN
		endif
	endfor
	
	// StepSizePopulationHMMP wave
	Wave/Z HMMP = $(cellPath + ":HMMP")
	if(WaveExists(HMMP) && numpnts(HMMP) > Dstate)
		// HMMP1S1-Sn
		for(i = 0; i < Dstate; i += 1)
			P_values[i] = HMMP[i + 1]  // HMMP[0]=S0, HMMP[1]=S1, ...
		endfor
	else
		// HMMPTransA
		for(i = 0; i < Dstate; i += 1)
			P_values[i] = StatePopulation_cell[i]
		endfor
	endif
	
	// PopulationNaN
	Variable totalP = 0
	for(i = 0; i < Dstate; i += 1)
		if(numtype(P_values[i]) != 0 || P_values[i] < 0)
			P_values[i] = NaN
			Printf "WARNING: Population data NaN/invalid for state %d. Diagram will show empty.\r", i
		endif
		totalP += P_values[i]
	endfor
	// 0
	if(totalP <= 0)
		for(i = 0; i < Dstate; i += 1)
			P_values[i] = NaN
			Printf "WARNING: Population data NaN/invalid for state %d. Diagram will show empty.\r", i
		endfor
	endif
	
	// 50%: 600x600 → 300x300
	winName = "StateTransition_" + CellName
	DoWindow/K $winName
	Display/K=1/N=$winName/W=(100,100,400,400) as "State Transition: " + CellName
	
	// 
	Make/O/N=(6, 3) StateColors
	StateColors[0][0] = 0;       StateColors[0][1] = 0;       StateColors[0][2] = 65280
	StateColors[1][0] = 65280;   StateColors[1][1] = 43520;   StateColors[1][2] = 0
	StateColors[2][0] = 0;       StateColors[2][1] = 39168;   StateColors[2][2] = 0
	StateColors[3][0] = 65280;   StateColors[3][1] = 0;       StateColors[3][2] = 0
	StateColors[4][0] = 39168;   StateColors[4][1] = 0;       StateColors[4][2] = 39168
	StateColors[5][0] = 0;       StateColors[5][1] = 0;       StateColors[5][2] = 0
	
	// 
	Make/O/T/N=(5, 5) StateNames
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
	
	// Aligned Trajectory
	Variable minSteps = 20
	ControlInfo/W=SMI_MainPanel tab1_sv_minsteps
	if(V_flag != 0)
		minSteps = V_Value
	endif
	
	// Traj Scale
	Variable trajScale = 2.5
	ControlInfo/W=SMI_MainPanel tab4_sv_trajscale
	if(V_flag != 0)
		trajScale = V_Value
	endif
	
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
	
	// PopulationP_values
	maxPop = WaveMax(P_values)
	if(maxPop <= 0 || numtype(maxPop) != 0)
		maxPop = 100
	endif
	
	// 
	maxRate = 0
	Variable minRate = inf
	for(i = 0; i < Dstate; i += 1)
		for(j = 0; j < Dstate; j += 1)
			if(i != j && numtype(TauTransition_cell[i][j]) == 0 && TauTransition_cell[i][j] > 0)
				rate = 1.0 / TauTransition_cell[i][j]
				if(rate > maxRate)
					maxRate = rate
				endif
				if(rate < minRate)
					minRate = rate
				endif
			endif
		endfor
	endfor
	if(maxRate == 0)
		maxRate = 1
	endif
	if(minRate == inf || minRate <= 0)
		minRate = maxRate / 10
	endif
	
	// P_values- 80%
	Variable minMarkerSize = 6
	Variable maxMarkerSize = 20
	axisPerPoint = 0.018
	
	// P_values
	avgMarkerSize = 0
	for(i = 0; i < Dstate; i += 1)
		Variable pVal = P_values[i]
		if(numtype(pVal) != 0)
			pVal = NaN
			Printf "WARNING: Population data NaN/invalid for state %d. Diagram will show empty.\r", i
		endif
		markerSize = minMarkerSize + (maxMarkerSize - minMarkerSize) * (pVal / maxPop)
		avgMarkerSize += markerSize
	endfor
	avgMarkerSize /= Dstate
	
	// ===== Use Aligned Trajectory  =====
	if(useAlignedTraj)
		// Trace_HMM
		Make/O/N=(6, 3) TrajColorsRGB
		TrajColorsRGB[0][0] = 32768;  TrajColorsRGB[0][1] = 40704;  TrajColorsRGB[0][2] = 65280  // S1: 
		TrajColorsRGB[1][0] = 65280;  TrajColorsRGB[1][1] = 65280;  TrajColorsRGB[1][2] = 0      // S2: 
		TrajColorsRGB[2][0] = 0;      TrajColorsRGB[2][1] = 65280;  TrajColorsRGB[2][2] = 0      // S3: 
		TrajColorsRGB[3][0] = 65280;  TrajColorsRGB[3][1] = 0;      TrajColorsRGB[3][2] = 0      // S4: 
		TrajColorsRGB[4][0] = 65280;  TrajColorsRGB[4][1] = 40704;  TrajColorsRGB[4][2] = 32768  // S5: 
		TrajColorsRGB[5][0] = 65535;  TrajColorsRGB[5][1] = 65535;  TrajColorsRGB[5][2] = 65535  // : 
		
		for(i = 0; i < Dstate; i += 1)
			String roiNameS = "ROI_S" + num2str(i+1)
			String xNameS = "Xum_S" + num2str(i+1)
			String yNameS = "Yum_S" + num2str(i+1)
			
			Wave/Z roiWaveS = $roiNameS
			Wave/Z xWaveS = $xNameS
			Wave/Z yWaveS = $yNameS
			
			if(!WaveExists(roiWaveS) || !WaveExists(xWaveS) || !WaveExists(yWaveS))
				continue
			endif
			
			// 10minSteps
			String tempXName = "TrajDiag_X_S" + num2str(i+1)
			String tempYName = "TrajDiag_Y_S" + num2str(i+1)
			Variable nExtracted = ExtractLimitedTrajectories(roiWaveS, xWaveS, yWaveS, tempXName, tempYName, minSteps, 10)
			
			if(nExtracted > 0)
				Wave tempX = $tempXName
				Wave tempY = $tempYName
				
				// StateX_pos[i], StateY_pos[i]
				String diagXName = "DiagTraj_X_S" + num2str(i+1)
				String diagYName = "DiagTraj_Y_S" + num2str(i+1)
				Duplicate/O tempX, $diagXName
				Duplicate/O tempY, $diagYName
				Wave diagX = $diagXName
				Wave diagY = $diagYName
				
				// 
				diagX = (numtype(tempX[p]) == 0) ? StateX_pos[i] + tempX[p] * trajScale : NaN
				diagY = (numtype(tempY[p]) == 0) ? StateY_pos[i] + tempY[p] * trajScale : NaN
				
				AppendToGraph diagY vs diagX
				traceName = diagYName
				
				Variable colorIdx = i
				if(colorIdx > 5)
					colorIdx = 5
				endif
				ModifyGraph rgb($traceName)=(TrajColorsRGB[colorIdx][0], TrajColorsRGB[colorIdx][1], TrajColorsRGB[colorIdx][2])
				ModifyGraph lsize($traceName)=0.25
				
				KillWaves/Z tempX, tempY
			endif
			
			// L
			Variable lValTraj = L_values[i]
			if(numtype(lValTraj) == 0 && lValTraj > 0 && lValTraj <= lThresh)
				String lCircleXName = "DiagLCircle_X_S" + num2str(i+1)
				String lCircleYName = "DiagLCircle_Y_S" + num2str(i+1)
				Variable nCirclePts = 101
				Make/O/N=(nCirclePts) $lCircleXName, $lCircleYName
				Wave lCircleX = $lCircleXName
				Wave lCircleY = $lCircleYName
				
				Variable radiusL = (lValTraj / 2) * trajScale  // 
				Variable anglePt, pt
				for(pt = 0; pt < nCirclePts; pt += 1)
					anglePt = pt * 2 * Pi / (nCirclePts - 1)
					lCircleX[pt] = StateX_pos[i] + radiusL * cos(anglePt)
					lCircleY[pt] = StateY_pos[i] + radiusL * sin(anglePt)
				endfor
				
				AppendToGraph lCircleY vs lCircleX
				String lCircleTraceName = lCircleYName
				// L0.5
				ModifyGraph rgb($lCircleTraceName)=(TrajColorsRGB[colorIdx][0]*0.75, TrajColorsRGB[colorIdx][1]*0.75, TrajColorsRGB[colorIdx][2]*0.75)
				ModifyGraph lsize($lCircleTraceName)=2
			endif
		endfor
		
		KillWaves/Z TrajColorsRGB
	else
		// ===== =====
		// 
		for(i = 0; i < Dstate; i += 1)
			stateXName = "StateX_" + num2str(i+1)
			stateYName = "StateY_" + num2str(i+1)
			Make/O/N=1 $stateXName, $stateYName
			Wave stateX = $stateXName
			Wave stateY = $stateYName
			stateX[0] = StateX_pos[i]
			stateY[0] = StateY_pos[i]
			
			AppendToGraph stateY vs stateX
			traceName = stateYName
			
			// P_values (NaN → NaN: no silent fallback)
			Variable pValForSize = P_values[i]
			if(numtype(pValForSize) != 0)
				pValForSize = NaN
			endif
			markerSize = minMarkerSize + (maxMarkerSize - minMarkerSize) * (pValForSize / maxPop)
			
			ModifyGraph mode($traceName)=3
			ModifyGraph marker($traceName)=19
			ModifyGraph msize($traceName)=markerSize
			ModifyGraph rgb($traceName)=(StateColors[i][0], StateColors[i][1], StateColors[i][2])
		endfor
		
		// LL-threshold
		for(i = 0; i < Dstate; i += 1)
			Variable lVal = L_values[i]
			Printf "  State S%d: L=%.4f, threshold=%.4f\r", i+1, lVal, lThresh
			
			if(numtype(lVal) == 0 && lVal > 0 && lVal <= lThresh)
				// LlVal * 0.75 
				lCircleRadius = lVal * 0.75
				// 
				Variable lMarkerSize = lCircleRadius / axisPerPoint
				
				// 
				Variable pValL = P_values[i]
				if(numtype(pValL) != 0)
					pValL = NaN
				endif
				Variable stateMarkerSize = minMarkerSize + (maxMarkerSize - minMarkerSize) * (pValL / maxPop)
				
				Printf "    -> L marker size=%.1f, state marker size=%.1f\r", lMarkerSize, stateMarkerSize
				
				// LWave
				String lXName = "LMarkerX_" + num2str(i+1)
				String lYName = "LMarkerY_" + num2str(i+1)
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
	
	// TextBox
	for(i = 0; i < Dstate; i += 1)
		stateName = StateNames[nameIdx][i]
		Variable pValForLabel = P_values[i]
		if(numtype(pValForLabel) != 0)
			pValForLabel = NaN
		endif
		markerSize = minMarkerSize + (maxMarkerSize - minMarkerSize) * (pValForLabel / maxPop)
		
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
		
		boxName = "State" + num2str(i+1)
		// D_values, L_values, P_values
		Variable dVal = D_values[i]
		Variable lValLabel = L_values[i]
		Variable pValLabel = P_values[i]
		
		// 
		Variable stateR = StateColors[i][0]
		Variable stateG = StateColors[i][1]
		Variable stateB = StateColors[i][2]
		
		if(numtype(lValLabel) == 0 && lValLabel > 0)
			sprintf labelStr, "\\Z14\\f01\\K(%d,%d,%d)%s\r\\Z11\\K(0,0,0)D=%.3f µm²/s\rL=%.3f µm\rP=%.1f%%", stateR, stateG, stateB, stateName, dVal, lValLabel, pValLabel
		else
			sprintf labelStr, "\\Z14\\f01\\K(%d,%d,%d)%s\r\\Z11\\K(0,0,0)D=%.3f µm²/s\rP=%.1f%%", stateR, stateG, stateB, stateName, dVal, pValLabel
		endif
		TextBox/C/N=$boxName/F=0/B=1/A=MC/X=(labelX/axisRange*50)/Y=(labelY/axisRange*50)
		AppendText/N=$boxName labelStr
	endfor
	
	// 
	// SetDrawLayer UserFront  // 
	
	// : 20%
	arrowNum = 0
	arrowLenAxis = 8 * axisPerPoint
	
	for(i = 0; i < Dstate; i += 1)
		for(j = 0; j < Dstate; j += 1)
			if(i != j && numtype(TauTransition_cell[i][j]) == 0 && TauTransition_cell[i][j] > 0)
				x1 = StateX_pos[i]
				y1 = StateY_pos[i]
				x2 = StateX_pos[j]
				y2 = StateY_pos[j]
				
				dx = x2 - x1
				dy = y2 - y1
				dist = sqrt(dx^2 + dy^2)
				
				centerMidX = (x1 + x2) / 2
				centerMidY = (y1 + y2) / 2
				
				markerSize1 = minMarkerSize + (maxMarkerSize - minMarkerSize) * (StatePopulation_cell[i] / maxPop)
				markerSize2 = minMarkerSize + (maxMarkerSize - minMarkerSize) * (StatePopulation_cell[j] / maxPop)
				circleRadius = markerSize1 * axisPerPoint * 0.55
				circleRadius2 = markerSize2 * axisPerPoint * 0.55
				
				// 
				perpX = dy / dist
				perpY = -dx / dist
				
				// : %
				arrowOffset = dist * arrowOffsetPct / 100
				
				kValue = 1.0 / TauTransition_cell[i][j]
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
				
				// τ: 
				labelTauOffset = dist * tauLabelPct / 100
				labelPerpX = labelTauOffset * perpX
				labelPerpY = labelTauOffset * perpY
				
				// τ1TextBox
				// i < j: τ / i > j: τ
				// TextBox
				Variable xPct = (midX + labelPerpX) / axisRange * 50
				Variable yPct = (midY + labelPerpY) / axisRange * 50
				if(i < j)
					// →: τ
					if(outputTau)
						sprintf labelStr, "\\JC\\Z%dτ=%.2f s\r\\Z%d%s", fontSize, TauTransition_cell[i][j], fontSize, arrowStr
					else
						sprintf labelStr, "\\JC\\Z%dk=%.3f/s\r\\Z%d%s", fontSize, kValue, fontSize, arrowStr
					endif
				else
					// →: τ
					if(outputTau)
						sprintf labelStr, "\\JC\\Z%d%s\r\\Z%dτ=%.2f s", fontSize, arrowStr, fontSize, TauTransition_cell[i][j]
					else
						sprintf labelStr, "\\JC\\Z%d%s\r\\Z%dk=%.3f/s", fontSize, arrowStr, fontSize, kValue
					endif
				endif
				TextBox/C/N=$boxName/F=0/B=1/A=MC/X=(xPct)/Y=(yPct)/O=(arrowAngle)/LS=(lineSpace) labelStr
			endif
		endfor
	endfor
	
	// 14Arial
	String titleStr
	sprintf titleStr, "\\F'Arial'\\Z14State Transition: %s (%d states)\r\\Z12framerate = %.3f s", CellName, Dstate, framerate
	TextBox/C/N=title/F=0/B=1/A=LT/X=0/Y=0 titleStr
	
	// Use Aligned Trajectory
	if(useAlignedTraj)
		// : 1 µm trajScale
		Variable scaleBarLen = 1.0 * trajScale  // 1 µm
		Variable scaleBarX1 = -axisRange * 0.90
		Variable scaleBarX2 = scaleBarX1 + scaleBarLen
		Variable scaleBarYPos = axisRange * 0.65  // 
		
		Make/O/N=2 ScaleBar_X, ScaleBar_Y
		ScaleBar_X[0] = scaleBarX1
		ScaleBar_X[1] = scaleBarX2
		ScaleBar_Y[0] = scaleBarYPos
		ScaleBar_Y[1] = scaleBarYPos
		
		AppendToGraph ScaleBar_Y vs ScaleBar_X
		ModifyGraph rgb(ScaleBar_Y)=(0,0,0)
		ModifyGraph lsize(ScaleBar_Y)=2
		
		// 
		String scaleLabel
		sprintf scaleLabel, "\\Z10\\K(0,0,0)1 µm"
		Variable scaleLabelX = (scaleBarX1 + scaleBarX2) / 2
		Variable scaleLabelYPos = scaleBarYPos - axisRange * 0.10
		TextBox/C/N=scalebar/F=0/B=1/A=MC/X=(scaleLabelX/axisRange*50)/Y=(scaleLabelYPos/axisRange*50) scaleLabel
	endif
	
	KillWaves/Z StateX_pos, StateY_pos, StateColors, StateNames, D_values, L_values, P_values
	
	SetDataFolder root:
	return 0
End

// -----------------------------------------------------------------------------
// 
// -----------------------------------------------------------------------------
Function RunStateTransitionAnalysis(SampleName)
	String SampleName
	
	NVAR Dstate = root:Dstate
	
	Print "=========================================="
	Print "Running State Transition Analysis"
	Print "=========================================="
	
	// MSDStepSize
	String samplePath = "root:" + SampleName
	Variable numFolders = CountDataFolders(SampleName)
	Variable m
	String FolderName, folderPath
	Variable hasMSD = 0, hasStepSize = 0
	
	// 
	if(numFolders > 0)
		FolderName = SampleName + "1"
		folderPath = samplePath + ":" + FolderName
		Wave/Z MSD_avg_S1 = $(folderPath + ":MSD_avg_S1")
		Wave/Z StepHist_S1 = $(folderPath + ":StepHist_S1")
		Wave/Z coef_Step_2D_S1 = $(folderPath + ":coef_Step_2D_S1")
		
		if(WaveExists(MSD_avg_S1))
			hasMSD = 1
		endif
		if(WaveExists(StepHist_S1) || WaveExists(coef_Step_2D_S1))
			hasStepSize = 1
		endif
	endif
	
	if(!hasMSD)
		Print "WARNING: MSD analysis not found. Please run 'Run MSD Analysis' first."
		Print "         D and L values will use default from HMM (Ctr wave)."
	endif
	if(!hasStepSize)
		Print "WARNING: Step Size Histogram analysis (Δt=1) not found."
		Print "         Please run 'Run Stepsize Histogram Analysis' first."
		Print "         Population values will use default from TransA matrix."
	endif
	
	// 
	Variable numCells
	numCells = CalculateTransitionTau(SampleName)
	if(numCells < 0)
		Print "State transition analysis failed"
		return -1
	endif
	
	// 
	SetDataFolder $samplePath
	numFolders = CountObjects("", 4)
	Variable i, cellCount
	String cellPath
	
	cellCount = 0
	for(i = 0; i < numFolders; i += 1)
		FolderName = GetIndexedObjName("", 4, i)
		if(StringMatch(FolderName, "Results") || StringMatch(FolderName, "Matrix"))
			continue
		endif
		
		cellPath = samplePath + ":" + FolderName
		Wave/Z TauTransition_cell = $(cellPath + ":TauTransition_cell")
		if(WaveExists(TauTransition_cell))
			Printf "Drawing diagram for: %s\r", FolderName
			DrawStateTransitionDiagramForCell(SampleName, FolderName)
			// 
			DisplayTauCategoryPlotForCell(SampleName, FolderName)
			cellCount += 1
			// SetDataFolder root:
			SetDataFolder $samplePath
		endif
	endfor
	
	Printf "Drew %d cell diagrams and category plots\r", cellCount
	
	// Comparison
	// DisplayTauCategoryPlot(SampleName)
	// DrawStateTransitionDiagram(SampleName)
	
	SetDataFolder root:
	Print "State transition analysis complete"
	return 0
End

// =============================================================================
// On-rate Analysis (moved from SMI_Timelapse.ipf)
// =============================================================================

// -----------------------------------------------------------------------------
// On-rateOn eventOn rate
// -----------------------------------------------------------------------------
Function CumOnrateAnalysis(SampleName, [basePath])
	String SampleName
	String basePath      // :  "root"
	
	// 
	if(ParamIsDefault(basePath))
		basePath = "root"
	endif
	
	Variable numFolders = CountDataFoldersInPath(basePath, SampleName)
	Variable m
	String FolderName
	
	NVAR framerate = root:framerate
	NVAR gFrameNum = root:FrameNum
	NVAR gMinFrame = root:MinFrame
	NVAR/Z gFixArea = root:cFixArea
	NVAR gOnArea = root:OnArea
	NVAR/Z gInitialVon = root:InitialVon
	NVAR gInitialTauon = root:InitialTauon

	//
	Variable localFrameNum = gFrameNum
	Variable localMinFrame = gMinFrame
	Variable localOnArea = gOnArea
	Variable localInitVon = NVAR_Exists(gInitialVon) ? gInitialVon : 1
	Variable localInitTauon = gInitialTauon
	Variable localFixArea = 0

	if(NVAR_Exists(gFixArea))
		localFixArea = gFixArea
	endif
	
	Variable analysisFrame = localFrameNum - localMinFrame
	
	Print "=== On-rate Analysis ==="
	Printf "BasePath: %s, Sample: %s\r", basePath, SampleName
	
	for(m = 0; m < numFolders; m += 1)
		FolderName = SampleName + num2str(m + 1)
		String folderFullPath = basePath + ":" + SampleName + ":" + FolderName
		
		if(!DataFolderExists(folderFullPath))
			continue
		endif
		
		SetDataFolder $folderFullPath
		
		Wave/Z Rframe_S0, Rtime_S0
		if(!WaveExists(Rframe_S0) || !WaveExists(Rtime_S0))
			continue
		endif
		
		Variable rowSize = numpnts(Rframe_S0)
		
		// On eventWave
		Make/O/N=(analysisFrame) time_onrate = (p + 1) * framerate
		Make/O/N=(analysisFrame) OnEvent = 0
		Make/O/N=(analysisFrame) CumOnEvent = 0
		
		// On event
		// t=0
		Variable r, Ton
		for(r = 0; r < rowSize; r += 1)
			if(numtype(Rframe_S0[r]) == 0 && Rframe_S0[r] == 0)
				Ton = Rtime_S0[r]  // 
				if(Ton > 0 && Ton < analysisFrame)
					OnEvent[Ton] += 1
				endif
			endif
		endfor
		
		// On event
		CumOnEvent[0] = OnEvent[0]
		for(Ton = 1; Ton < analysisFrame; Ton += 1)
			CumOnEvent[Ton] = CumOnEvent[Ton-1] + OnEvent[Ton]
		endfor
		
		// 
		Display/K=1 CumOnEvent vs time_onrate
		ModifyGraph mode=3, marker=19, msize=1
		ModifyGraph tick=2, mirror=1, fStyle=1, fSize=14, font="Arial"
		Label left "Cum. On events"
		Label bottom "Time [s]"
		String graphTitle = FolderName + " On-rate"
		DoWindow/T kwTopWin, graphTitle
		
		// 
		Variable cellArea = localOnArea
		if(localFixArea == 0)
			Wave/Z ParaDensity
			if(WaveExists(ParaDensity))
				cellArea = ParaDensity[1]
			endif
		endif
		
		// On-rate
		Variable totalEvents = CumOnEvent[analysisFrame - 1]
		Variable totalTime = time_onrate[analysisFrame - 1]
		Variable onRate = totalEvents / totalTime / cellArea
		
		// 
		Make/O/N=3 ParaOnrate
		ParaOnrate[0] = localInitTauon  // tau
		ParaOnrate[1] = onRate  // On-rate [molecules/um^2/s]
		ParaOnrate[2] = totalEvents  // On event
		
		Print "  " + FolderName + ": On-rate = " + num2str(onRate) + " /um^2/s, Total events = " + num2str(totalEvents)
	endfor
	
	SetDataFolder root:
	Print "On-rate analysis complete"
End

// -----------------------------------------------------------------------------
// OnrateAnalysisWithOption - Density/On-rate
// CumOnrate_Gcount
// -----------------------------------------------------------------------------
Function OnrateAnalysisWithOption(SampleName, [basePath, waveSuffix])
	String SampleName
	String basePath      // :  "root"
	String waveSuffix    // : wave"_C1E", "_C2E"
	
	// 
	if(ParamIsDefault(basePath))
		basePath = "root"
	endif
	if(ParamIsDefault(waveSuffix))
		waveSuffix = ""
	endif
	
	Variable numFolders = CountDataFoldersInPath(basePath, SampleName)
	Variable m, stateIdx
	String FolderName, folderPath
	
	NVAR framerate = root:framerate
	NVAR gFrameNum = root:FrameNum
	NVAR gMinFrame = root:MinFrame
	NVAR gOnArea = root:OnArea
	NVAR gInitialTauon = root:InitialTauon
	NVAR/Z gInitialVon = root:InitialVon
	NVAR/Z cUseDensity = root:cUseDensityForOnrate
	NVAR/Z cHMM = root:cHMM
	NVAR gDstate = root:Dstate

	//
	Variable localFrameNum = gFrameNum
	Variable localMinFrame = gMinFrame
	Variable localOnArea = gOnArea
	Variable localInitTauon = gInitialTauon
	Variable localInitVon = NVAR_Exists(gInitialVon) ? gInitialVon : 1
	Variable useDensity = NVAR_Exists(cUseDensity) ? cUseDensity : 1
	Variable maxState = 0

	if(NVAR_Exists(cHMM) && cHMM == 1)
		maxState = gDstate
	endif
	
	Variable analysisFrame = localFrameNum - localMinFrame
	
	Print "=== On-rate Analysis (with Option) ==="
	Printf "BasePath: %s, Sample: %s, suffix=%s\r", basePath, SampleName, waveSuffix
	Printf "FrameNum: %d, MinFrame: %d, AnalysisFrame: %d\r", localFrameNum, localMinFrame, analysisFrame
	Printf "UseDensity: %d, OnArea: %.1f µm², MaxState: %d\r", useDensity, localOnArea, maxState
	
	// S0=, S1=, S2=, S3=, S4=, S5=
	Make/FREE/N=(6, 3) DstateColors
	DstateColors[0][0] = 0;       DstateColors[0][1] = 0;       DstateColors[0][2] = 0        // S0: 
	DstateColors[1][0] = 0;       DstateColors[1][1] = 0;       DstateColors[1][2] = 65280    // S1: 
	DstateColors[2][0] = 65280;   DstateColors[2][1] = 43520;   DstateColors[2][2] = 0        // S2: 
	DstateColors[3][0] = 0;       DstateColors[3][1] = 39168;   DstateColors[3][2] = 0        // S3: 
	DstateColors[4][0] = 65280;   DstateColors[4][1] = 0;       DstateColors[4][2] = 0        // S4: 
	DstateColors[5][0] = 65280;   DstateColors[5][1] = 0;       DstateColors[5][2] = 65280    // S5: 
	
	for(m = 0; m < numFolders; m += 1)
		FolderName = SampleName + num2str(m + 1)
		folderPath = basePath + ":" + SampleName + ":" + FolderName + ":"
		
		if(!DataFolderExists(basePath + ":" + SampleName + ":" + FolderName))
			break
		endif
		
		SetDataFolder $(basePath + ":" + SampleName + ":" + FolderName)
		Printf "\n  Processing %s...\r", FolderName
		
		// 
		Variable cellArea = localOnArea
		if(useDensity == 1)
			Wave/Z ParaDensity = $(folderPath + "ParaDensity" + waveSuffix)
			if(WaveExists(ParaDensity) && numtype(ParaDensity[1]) == 0 && ParaDensity[1] > 0)
				cellArea = ParaDensity[1]
				Printf "    Using Density-based area: %.2f µm²\r", cellArea
			else
				Printf "    ParaDensity not found or invalid, using fixed area: %.2f µm²\r", cellArea
			endif
		else
			Printf "    Using fixed area: %.2f µm²\r", cellArea
		endif
		
		// 
		String winName = "Onrate_" + FolderName + waveSuffix
		DoWindow/K $winName
		Variable firstPlot = 1
		
		// Dstate
		// : S1SnS0Rframe==0
		
		// S0SegwaveSuffix
		Wave/Z Rframe_S0 = $(folderPath + "Rframe_S0" + waveSuffix)
		Wave/Z Rtime_S0 = $(folderPath + "Rtime_S0" + waveSuffix)
		Wave/Z Dstate_S0 = $(folderPath + "Dstate_S0" + waveSuffix)
		
		if(!WaveExists(Rframe_S0) || !WaveExists(Rtime_S0))
			Printf "    WARNING: Input waves not found in %s\r", folderPath
			Printf "      Rframe_S0%s: %s\r", waveSuffix, SelectString(WaveExists(Rframe_S0), "NOT FOUND", "exists")
			Printf "      Rtime_S0%s: %s\r", waveSuffix, SelectString(WaveExists(Rtime_S0), "NOT FOUND", "exists")
			continue
		endif
		
		Variable hasDstateWave = WaveExists(Dstate_S0)
		
		for(stateIdx = 0; stateIdx <= maxState; stateIdx += 1)
			String stateSuffix = "_S" + num2str(stateIdx) + waveSuffix
			String stateName = "S" + num2str(stateIdx)
			
			// On eventWave
			Make/O/N=(analysisFrame) $(folderPath + "time_onrate" + stateSuffix) = (p + 1) * framerate
			Make/O/N=(analysisFrame) $(folderPath + "OnEvent" + stateSuffix) = 0
			Make/O/N=(analysisFrame) $(folderPath + "CumOnEvent" + stateSuffix) = 0
			
			Wave time_onrate_s = $(folderPath + "time_onrate" + stateSuffix)
			Wave OnEvent_s = $(folderPath + "OnEvent" + stateSuffix)
			Wave CumOnEvent_s = $(folderPath + "CumOnEvent" + stateSuffix)
			
			// On event
			Variable rowSize = numpnts(Rframe_S0)
			Variable r, Ton
			
			if(stateIdx == 0)
				// S0: 
				for(r = 0; r < rowSize; r += 1)
					if(numtype(Rframe_S0[r]) == 0 && Rframe_S0[r] == 0)
						Ton = Rtime_S0[r]
						if(Ton > 0 && Ton < analysisFrame)
							OnEvent_s[Ton] += 1
						endif
					endif
				endfor
			else
				// S1Sn: stateIdx
				if(hasDstateWave)
					for(r = 0; r < rowSize; r += 1)
						if(numtype(Rframe_S0[r]) == 0 && Rframe_S0[r] == 0)
							// 
							Variable startState = Dstate_S0[r]
							if(numtype(startState) == 0 && startState == stateIdx)
								Ton = Rtime_S0[r]
								if(Ton > 0 && Ton < analysisFrame)
									OnEvent_s[Ton] += 1
								endif
							endif
						endif
					endfor
				endif
			endif
			
			// On event
			CumOnEvent_s[0] = OnEvent_s[0]
			for(Ton = 1; Ton < analysisFrame; Ton += 1)
				CumOnEvent_s[Ton] = CumOnEvent_s[Ton-1] + OnEvent_s[Ton]
			endfor
			
			Variable finalCum = CumOnEvent_s[analysisFrame - 1]
			Variable finalTime
			
			// : CumOnEvent = V0 * (1 - exp(-t/tau))
			Make/D/O/N=2 $(folderPath + "W_coef" + stateSuffix)
			Wave W_coef_s = $(folderPath + "W_coef" + stateSuffix)
			W_coef_s[0] = localInitTauon  // tau
			W_coef_s[1] = localInitVon * cellArea  // V0
			
			// 
			Variable V_FitError = 0
			try
				FuncFit/Q/N/W=2 OnrateFitFunc, W_coef_s, CumOnEvent_s /X=time_onrate_s; AbortOnRTE
			catch
				Variable err = GetRTError(1)
				Printf "    %s: Fit error - %s\r", stateName, GetErrMessage(err)
				V_FitError = 1
			endtry
			
			// 
			Make/O/N=(analysisFrame) $(folderPath + "fit_CumOnEvent" + stateSuffix)
			Wave fit_wave = $(folderPath + "fit_CumOnEvent" + stateSuffix)
			fit_wave = W_coef_s[1] * (1 - exp(-time_onrate_s / W_coef_s[0]))
			
			// 
			Variable plotR = DstateColors[min(stateIdx, 5)][0]
			Variable plotG = DstateColors[min(stateIdx, 5)][1]
			Variable plotB = DstateColors[min(stateIdx, 5)][2]
			
			if(firstPlot)
				Display/K=1/N=$winName CumOnEvent_s vs time_onrate_s
				firstPlot = 0
			else
				AppendToGraph/W=$winName CumOnEvent_s vs time_onrate_s
			endif
			
			String traceName = NameOfWave(CumOnEvent_s)
			ModifyGraph/W=$winName mode($traceName)=3, marker($traceName)=19, msize($traceName)=1
			ModifyGraph/W=$winName rgb($traceName)=(plotR, plotG, plotB)
			
			// 
			if(V_FitError == 0)
				AppendToGraph/W=$winName fit_wave vs time_onrate_s
				String fitTraceName = NameOfWave(fit_wave)
				ModifyGraph/W=$winName rgb($fitTraceName)=(plotR, plotG, plotB)
				ModifyGraph/W=$winName lsize($fitTraceName)=1.5
			endif
			
			// 
			Make/O/N=3 $(folderPath + "ParaOnrate" + stateSuffix)
			Wave ParaOnrate_s = $(folderPath + "ParaOnrate" + stateSuffix)
			
			finalTime = time_onrate_s[analysisFrame - 1]
			
			// Vm/Area
			Variable vmArea = 0
			if(finalTime > 0 && cellArea > 0)
				vmArea = finalCum / finalTime / cellArea  // Vm/CellArea [/um²/s]
			endif
			ParaOnrate_s[2] = vmArea
			
			// 
			Variable fitValid = 0
			Variable v0Area = 0
			Variable tau = 0
			
			if(V_FitError == 0)
				tau = W_coef_s[0]
				v0Area = W_coef_s[1] / cellArea
				
				// :
				// 1. tau
				// 2. V0/AreaVm/Area5 vmArea  0 
				// 3. tau > 0
				Variable tauOK = (tau > 0 && tau <= finalTime)
				Variable v0OK = (vmArea == 0) || (v0Area <= vmArea * 5)
				
				if(tauOK && v0OK)
					fitValid = 1
				else
					Printf "    WARNING %s: Fit unreliable (tau=%.1f s, V0/Area=%.4f, Vm/Area=%.4f) -> using Vm/Area\r", stateName, tau, v0Area, vmArea
				endif
			endif
			
			if(fitValid)
				ParaOnrate_s[0] = tau  // tau [s]
				ParaOnrate_s[1] = v0Area  // V0/CellArea [/um²/s]
			else
				// Vm/Area
				ParaOnrate_s[0] = 0  // tau
				ParaOnrate_s[1] = vmArea  // Vm/Areaon-rate
			endif
			
			if(stateIdx == 0 || (stateIdx > 0 && finalCum > 0))
				Printf "    %s: tau=%.2f s, V0/Area=%.4f /µm²/s, events=%d\r", stateName, ParaOnrate_s[0], ParaOnrate_s[1], finalCum
			endif
		endfor
		
		// 
		if(!firstPlot)
			ModifyGraph/W=$winName width={Aspect, 1.618}
			ModifyGraph/W=$winName tick=0, mirror=0
			ModifyGraph/W=$winName lowTrip(left)=0.0001
			ModifyGraph/W=$winName axisEnab(left)={0.05, 1}, axisEnab(bottom)={0.05, 1}
			ModifyGraph/W=$winName fStyle=1, fSize=16, font="Arial"
			Label/W=$winName left "Cum. On events"
			Label/W=$winName bottom "\\F'Arial'\\Z12time [s]"
			SetAxis/W=$winName left 0, *
			SetAxis/W=$winName bottom 0, *
			DoWindow/T $winName, FolderName + " On-rate"
			
			// 
			String legendStr = ""
			Variable legendIdx
			for(legendIdx = 0; legendIdx <= maxState; legendIdx += 1)
				if(legendIdx > 0)
					legendStr += "\r"
				endif
				String cumEventName = "CumOnEvent_S" + num2str(legendIdx) + waveSuffix
				legendStr += "\\s(" + cumEventName + ") " + GetDstateName(legendIdx, maxState)
			endfor
			Legend/W=$winName/C/N=legend1/J/F=0/B=1/A=RT legendStr
		endif
		
		// : ParaOnrate = ParaOnrate_S0
		Wave/Z ParaOnrate_S0 = $(folderPath + "ParaOnrate_S0" + waveSuffix)
		if(WaveExists(ParaOnrate_S0))
			Make/O/N=3 $(folderPath + "ParaOnrate" + waveSuffix)
			Wave ParaOnrate = $(folderPath + "ParaOnrate" + waveSuffix)
			ParaOnrate = ParaOnrate_S0
		endif
	endfor
	
	// ===  ===
	CreateOnrateSummaryGraphHMM(SampleName, maxState)
	
	SetDataFolder root:
	Print "On-rate analysis complete"
End

// -----------------------------------------------------------------------------
// On-rate : CumOnEvent = V0 * (1 - exp(-t/tau))
// -----------------------------------------------------------------------------
Function OnrateFitFunc(w, t) : FitFunc
	Wave w
	Variable t
	// w[0] = tau ()
	// w[1] = V0 ()
	return w[1] * (1 - exp(-t / w[0]))
End

// -----------------------------------------------------------------------------
// On-rate HMM
// Dstate1
// -----------------------------------------------------------------------------
Function CreateOnrateSummaryGraphHMM(SampleName, maxState)
	String SampleName
	Variable maxState
	
	Variable numFolders = CountDataFolders(SampleName)
	Variable m, stateIdx
	String FolderName, folderPath
	
	// 
	Variable numStates = maxState + 1  // S0, S1, ..., Sn
	if(numStates < 1)
		numStates = 1
	endif
	
	// S0=, S1=, S2=, S3=, S4=, S5=
	Make/FREE/N=(6, 3) DstateColors
	DstateColors[0][0] = 0;       DstateColors[0][1] = 0;       DstateColors[0][2] = 0        // S0: 
	DstateColors[1][0] = 0;       DstateColors[1][1] = 0;       DstateColors[1][2] = 65280    // S1: 
	DstateColors[2][0] = 65280;   DstateColors[2][1] = 43520;   DstateColors[2][2] = 0        // S2: 
	DstateColors[3][0] = 0;       DstateColors[3][1] = 39168;   DstateColors[3][2] = 0        // S3: 
	DstateColors[4][0] = 65280;   DstateColors[4][1] = 0;       DstateColors[4][2] = 0        // S4: 
	DstateColors[5][0] = 65280;   DstateColors[5][1] = 0;       DstateColors[5][2] = 65280    // S5: 
	
	// Matrix
	String matrixPath = "root:" + SampleName + ":Matrix"
	if(!DataFolderExists(matrixPath))
		NewDataFolder/O $matrixPath
	endif
	
	// WaveMatrix
	for(stateIdx = 0; stateIdx < numStates; stateIdx += 1)
		String suffix = "_S" + num2str(stateIdx)
		Make/O/N=(numFolders) $(matrixPath + ":Onrate_V0Area" + suffix) = NaN
	endfor
	Make/O/T/N=(numFolders) $(matrixPath + ":Onrate_Labels")
	Wave/T Labels = $(matrixPath + ":Onrate_Labels")
	
	// 
	for(m = 0; m < numFolders; m += 1)
		FolderName = SampleName + num2str(m + 1)
		folderPath = "root:" + SampleName + ":" + FolderName + ":"
		Labels[m] = FolderName
		
		for(stateIdx = 0; stateIdx < numStates; stateIdx += 1)
			suffix = "_S" + num2str(stateIdx)
			Wave/Z ParaOnrate_s = $(folderPath + "ParaOnrate" + suffix)
			Wave V0Area_s = $(matrixPath + ":Onrate_V0Area" + suffix)
			if(WaveExists(ParaOnrate_s))
				V0Area_s[m] = ParaOnrate_s[1]
			endif
		endfor
	endfor
	
	// === Dstate ===
	String winName = "Onrate_Summary_" + SampleName
	DoWindow/K $winName
	
	Variable firstPlot = 1
	// S0
	for(stateIdx = 0; stateIdx < numStates; stateIdx += 1)
		suffix = "_S" + num2str(stateIdx)
		Wave/Z V0Area_s = $(matrixPath + ":Onrate_V0Area" + suffix)
		
		if(!WaveExists(V0Area_s))
			continue
		endif
		
		// NaN
		WaveStats/Q V0Area_s
		if(V_npnts == 0)
			continue
		endif
		
		String traceName = "Onrate_V0Area" + suffix
		
		if(firstPlot)
			Display/K=1/N=$winName V0Area_s vs Labels
			firstPlot = 0
		else
			AppendToGraph V0Area_s vs Labels
		endif
		
		Variable r = DstateColors[min(stateIdx, 5)][0]
		Variable g = DstateColors[min(stateIdx, 5)][1]
		Variable b = DstateColors[min(stateIdx, 5)][2]
		
		ModifyGraph mode($traceName)=5, hbFill($traceName)=3
		ModifyGraph rgb($traceName)=(r, g, b)
	endfor
	
	if(!firstPlot)
		ModifyGraph width={Aspect, 1.618}
		ModifyGraph tick=0, mirror=0, fStyle=1, fSize=14, font="Arial"
		ModifyGraph catGap(bottom)=0.3, barGap(bottom)=0.1
		ModifyGraph tkLblRot(bottom)=45
		Label left "\\F'Arial'\\Z12on-rate [/µm²/s]"
		SetAxis left 0, *
		DoWindow/T $winName, SampleName + " On-rate by Dstate"
		
		// 
		String legendStr = ""
		String stateName
		for(stateIdx = 0; stateIdx < numStates; stateIdx += 1)
			if(stateIdx > 0)
				legendStr += "\r"
			endif
			stateName = GetDstateName(stateIdx, numStates - 1)
			legendStr += "\\s(Onrate_V0Area_S" + num2str(stateIdx) + ") " + stateName
		endfor
		Legend/C/N=legend1/J/F=0/B=1 legendStr
	endif
	
	Print "On-rate summary graph created"
End

// -----------------------------------------------------------------------------
// On-rate 
// -----------------------------------------------------------------------------
Function DisplayOnrateGraph(SampleName)
	String SampleName
	
	Variable numFolders = CountDataFolders(SampleName)
	Variable m
	String FolderName, folderPath, winName
	
	for(m = 0; m < numFolders; m += 1)
		FolderName = SampleName + num2str(m + 1)
		folderPath = "root:" + SampleName + ":" + FolderName + ":"
		
		Wave/Z CumOnEvent = $(folderPath + "CumOnEvent")
		Wave/Z time_onrate = $(folderPath + "time_onrate")
		Wave/Z fit_CumOnEvent = $(folderPath + "fit_CumOnEvent")
		Wave/Z ParaOnrate = $(folderPath + "ParaOnrate")
		
		if(!WaveExists(CumOnEvent) || !WaveExists(time_onrate))
			continue
		endif
		
		// 
		winName = "Onrate_" + FolderName
		DoWindow/K $winName
		
		Display/K=1/N=$winName CumOnEvent vs time_onrate
		ModifyGraph width={Aspect, 1.618}
		ModifyGraph tick=0, mirror=0
		ModifyGraph lowTrip(left)=0.0001
		ModifyGraph axisEnab(left)={0.05, 1}, axisEnab(bottom)={0.05, 1}
		ModifyGraph fStyle=1, fSize=16, font="Arial"
		ModifyGraph catGap(bottom)=0.3, barGap(bottom)=0
		Label left "Cum. On events"
		Label bottom "\\F'Arial'\\Z12time [s]"
		SetAxis left 0, *
		SetAxis bottom 0, *
		ModifyGraph useBarStrokeRGB=1, rgb(CumOnEvent)=(0, 0, 0)
		ModifyGraph mode(CumOnEvent)=3, marker(CumOnEvent)=19, msize(CumOnEvent)=1
		
		// 
		if(WaveExists(fit_CumOnEvent))
			AppendToGraph fit_CumOnEvent vs time_onrate
			ModifyGraph rgb(fit_CumOnEvent)=(0, 0, 0), lsize(fit_CumOnEvent)=1.5
		endif
		
		DoWindow/T $winName, FolderName + " On-rate"
		
		// 
		if(WaveExists(ParaOnrate))
			Printf "  %s: tau=%.2f s, V0/Area=%.4f /µm²/s, Vm/Area=%.4f /µm²/s\r", FolderName, ParaOnrate[0], ParaOnrate[1], ParaOnrate[2]
		endif
	endfor
	
	SetDataFolder root:
End


// =============================================================================
// 
// =============================================================================

// -----------------------------------------------------------------------------
// FitSumExpAIC - AIC
// P_DurationP_Duration_m_avg
// : 0
// -----------------------------------------------------------------------------
Function FitSumExpAIC(dataWave, timeWave, outputPath, outputName)
	Wave dataWave, timeWave
	String outputPath, outputName
	
	// 
	EnsureGlobalParameters()
	
	NVAR ExpMax_off = root:ExpMax_off
	NVAR ExpMin_off = root:ExpMin_off
	NVAR InitialTau1_off = root:InitialTau1_off
	NVAR TauScale_off = root:TauScale_off
	NVAR InitialA1_off = root:InitialA1_off
	NVAR AScale_off = root:AScale_off
	
	Variable maxExp = ExpMax_off
	Variable minExp = ExpMin_off
	Variable initTau = InitialTau1_off
	Variable tauScale = TauScale_off
	Variable initA1 = InitialA1_off
	Variable aScale = AScale_off
	
	String savedDF = GetDataFolder(1)
	
	// 
	if(StringMatch(outputPath[strlen(outputPath)-1], ":") == 0)
		outputPath += ":"
	endif
	
	SetDataFolder $outputPath
	
	// NaN
	Variable numPts = numpnts(dataWave)
	Variable validCount = 0
	Variable i
	
	// 
	for(i = 0; i < numPts; i += 1)
		if(numtype(dataWave[i]) == 0 && numtype(timeWave[i]) == 0)
			validCount += 1
		endif
	endfor
	
	if(validCount < 3)
		Printf "  WARNING: Not enough valid data points for fitting (%d)\r", validCount
		SetDataFolder $savedDF
		return 0
	endif
	
	// 
	Make/O/N=(validCount) fitData_temp, fitTime_temp
	Variable idx = 0
	for(i = 0; i < numPts; i += 1)
		if(numtype(dataWave[i]) == 0 && numtype(timeWave[i]) == 0)
			fitData_temp[idx] = dataWave[i]
			fitTime_temp[idx] = timeWave[i]
			idx += 1
		endif
	endfor
	
	Variable FitX_interval = validCount * 10
	
	// AIC
	Make/O/N=(maxExp + 1) AIC_fit_temp = NaN
	
	Variable numstate, n, bestState = minExp
	Variable bestAIC = Inf
	Variable anyFitSuccess = 0  // AIC1
	
	// Wave
	Make/O/D/N=(maxExp * 2) W_coef_best_saved = NaN
	
	// 
	for(numstate = minExp; numstate <= maxExp; numstate += 1)
		// : A = A1 * Scale_A^(n-1), Tau = Tau1 * Scale_tau^(n-1)
		Make/O/D/N=(numstate * 2) W_coef_fit_temp
		Wave W_coef_temp = W_coef_fit_temp
		
		for(n = 0; n < numstate; n += 1)
			W_coef_temp[n * 2] = initA1 * (aScale ^ n)  // A [%]
			W_coef_temp[n * 2 + 1] = initTau * (tauScale ^ n)  // Tau [s]
		endfor
		
		// 
		Make/O/T/N=(numstate * 2) T_Constraints_fit
		Wave/T T_Constraints = T_Constraints_fit
		for(n = 0; n < numstate * 2; n += 1)
			T_Constraints[n] = "K" + num2str(n) + " > 0"
		endfor
		
		// 
		Variable V_FitError = 0
		try
			AbortOnRTE
			if(numstate == 1)
				FuncFit/Q/L=(FitX_interval)/NTHR=0 SumExp1 W_coef_temp fitData_temp /X=fitTime_temp /D /C=T_Constraints; AbortOnRTE
			elseif(numstate == 2)
				FuncFit/Q/L=(FitX_interval)/NTHR=0 SumExp2 W_coef_temp fitData_temp /X=fitTime_temp /D /C=T_Constraints; AbortOnRTE
			elseif(numstate == 3)
				FuncFit/Q/L=(FitX_interval)/NTHR=0 SumExp3 W_coef_temp fitData_temp /X=fitTime_temp /D /C=T_Constraints; AbortOnRTE
			elseif(numstate == 4)
				FuncFit/Q/L=(FitX_interval)/NTHR=0 SumExp4 W_coef_temp fitData_temp /X=fitTime_temp /D /C=T_Constraints; AbortOnRTE
			elseif(numstate == 5)
				FuncFit/Q/L=(FitX_interval)/NTHR=0 SumExp5 W_coef_temp fitData_temp /X=fitTime_temp /D /C=T_Constraints; AbortOnRTE
			endif
		catch
			V_FitError = 1
		endtry
		
		if(V_FitError == 0)
			anyFitSuccess = 1
			
			// AIC
			Make/O/FREE/N=(validCount) Res_fit_temp
			if(numstate == 1)
				Res_fit_temp = fitData_temp[p] - SumExp1(W_coef_temp, fitTime_temp[p])
			elseif(numstate == 2)
				Res_fit_temp = fitData_temp[p] - SumExp2(W_coef_temp, fitTime_temp[p])
			elseif(numstate == 3)
				Res_fit_temp = fitData_temp[p] - SumExp3(W_coef_temp, fitTime_temp[p])
			elseif(numstate == 4)
				Res_fit_temp = fitData_temp[p] - SumExp4(W_coef_temp, fitTime_temp[p])
			elseif(numstate == 5)
				Res_fit_temp = fitData_temp[p] - SumExp5(W_coef_temp, fitTime_temp[p])
			endif
			
			// AIC
			Make/O/FREE/N=(validCount) SS_fit_temp
			SS_fit_temp = Res_fit_temp^2
			WaveStats/Q SS_fit_temp
			
			Variable AIC = V_npnts * (ln(2 * pi * V_avg) + 1) + 2 * (numstate * 2 + 2)
			AIC_fit_temp[numstate] = AIC
			
			if(AIC < bestAIC)
				bestAIC = AIC
				bestState = numstate
				// 
				W_coef_best_saved = NaN
				for(n = 0; n < numstate * 2; n += 1)
					W_coef_best_saved[n] = W_coef_temp[n]
				endfor
			endif
		endif
	endfor
	
	// 
	if(anyFitSuccess == 0)
		Printf "  WARNING: All fits failed, skipping\r"
		KillWaves/Z fitData_temp, fitTime_temp
		KillWaves/Z W_coef_fit_temp, T_Constraints_fit, AIC_fit_temp
		KillWaves/Z W_coef_best_saved
		SetDataFolder $savedDF
		return 0
	endif
	
	// 
	Make/O/D/N=(bestState * 2) W_coef_best_fit
	Wave W_coef_best = W_coef_best_fit
	for(n = 0; n < bestState; n += 1)
		W_coef_best[n * 2] = initA1 * (aScale ^ n)
		W_coef_best[n * 2 + 1] = initTau * (tauScale ^ n)
	endfor
	
	Make/O/T/N=(bestState * 2) T_Constraints_best_fit
	Wave/T T_Constraints_best = T_Constraints_best_fit
	for(n = 0; n < bestState * 2; n += 1)
		T_Constraints_best[n] = "K" + num2str(n) + " > 0"
	endfor
	
	Variable finalError = 0
	try
		AbortOnRTE
		if(bestState == 1)
			FuncFit/Q/L=(FitX_interval)/NTHR=0 SumExp1 W_coef_best fitData_temp /X=fitTime_temp /D /C=T_Constraints_best; AbortOnRTE
		elseif(bestState == 2)
			FuncFit/Q/L=(FitX_interval)/NTHR=0 SumExp2 W_coef_best fitData_temp /X=fitTime_temp /D /C=T_Constraints_best; AbortOnRTE
		elseif(bestState == 3)
			FuncFit/Q/L=(FitX_interval)/NTHR=0 SumExp3 W_coef_best fitData_temp /X=fitTime_temp /D /C=T_Constraints_best; AbortOnRTE
		elseif(bestState == 4)
			FuncFit/Q/L=(FitX_interval)/NTHR=0 SumExp4 W_coef_best fitData_temp /X=fitTime_temp /D /C=T_Constraints_best; AbortOnRTE
		elseif(bestState == 5)
			FuncFit/Q/L=(FitX_interval)/NTHR=0 SumExp5 W_coef_best fitData_temp /X=fitTime_temp /D /C=T_Constraints_best; AbortOnRTE
		endif
	catch
		finalError = 1
		Printf "  WARNING: Final fit failed, using AIC loop result\r"
		// AIC
		for(n = 0; n < bestState * 2; n += 1)
			W_coef_best[n] = W_coef_best_saved[n]
		endfor
	endtry
	
	// FuncFit
	if(finalError == 0)
		Wave/Z fitWave = fit_fitData_temp
		if(WaveExists(fitWave))
			Duplicate/O fitWave, $outputName
			Printf "  Avg fit: %d-exp (AIC=%.1f)\r", bestState, bestAIC
		endif
	else
		// : 
		Make/O/N=(FitX_interval) $outputName
		Wave outWave = $outputName
		Variable tMin = fitTime_temp[0]
		Variable tMax = fitTime_temp[validCount - 1]
		Variable dt = (tMax - tMin) / (FitX_interval - 1)
		SetScale/P x, tMin, dt, outWave
		
		Variable pt
		for(pt = 0; pt < FitX_interval; pt += 1)
			Variable tVal = tMin + pt * dt
			if(bestState == 1)
				outWave[pt] = SumExp1(W_coef_best, tVal)
			elseif(bestState == 2)
				outWave[pt] = SumExp2(W_coef_best, tVal)
			elseif(bestState == 3)
				outWave[pt] = SumExp3(W_coef_best, tVal)
			elseif(bestState == 4)
				outWave[pt] = SumExp4(W_coef_best, tVal)
			elseif(bestState == 5)
				outWave[pt] = SumExp5(W_coef_best, tVal)
			endif
		endfor
		Printf "  Avg fit (from AIC loop): %d-exp (AIC=%.1f)\r", bestState, bestAIC
	endif
	
	// 
	KillWaves/Z fitData_temp, fitTime_temp
	KillWaves/Z W_coef_fit_temp, T_Constraints_fit, AIC_fit_temp
	KillWaves/Z W_coef_best_fit, T_Constraints_best_fit
	KillWaves/Z W_coef_best_saved
	KillWaves/Z fit_fitData_temp
	
	SetDataFolder $savedDF
	return bestState
End

