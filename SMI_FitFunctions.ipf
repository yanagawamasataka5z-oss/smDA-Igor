#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3
#pragma version=2.0
// ModuleName - FitFunc

// =============================================================================
// SMI_FitFunctions.ipf - Fitting Functions for Single Molecule Analysis
// =============================================================================
// 
// Version 2.0 - Refactored
// =============================================================================

// -----------------------------------------------------------------------------
// Sum of Gaussians ()
// 
// -----------------------------------------------------------------------------

Function SumGauss1(w, x) : FitFunc
	Wave w
	Variable x
	// w[0] = A1 ()
	// w[1] = m ()
	// w[2] = s ()
	return w[0] * exp(-((x - w[1])^2 / (2 * w[2]^2)))
End

Function SumGauss2(w, x) : FitFunc
	Wave w
	Variable x
	// w[0] = A1, w[1] = A2 ()
	// w[2] = m ()
	// w[3] = s ()
	Variable func = 0
	func += w[0] * exp(-((x - w[2])^2 / (2 * w[3]^2)))
	func += w[1] * exp(-((x - 2*w[2])^2 / (2 * 2*w[3]^2)))
	return func
End

Function SumGauss3(w, x) : FitFunc
	Wave w
	Variable x
	Variable func = 0
	func += w[0] * exp(-((x - w[3])^2 / (2 * w[4]^2)))
	func += w[1] * exp(-((x - 2*w[3])^2 / (2 * 2*w[4]^2)))
	func += w[2] * exp(-((x - 3*w[3])^2 / (2 * 3*w[4]^2)))
	return func
End

Function SumGauss4(w, x) : FitFunc
	Wave w
	Variable x
	Variable func = 0
	Variable m = w[4], s = w[5]
	func += w[0] * exp(-((x - m)^2 / (2 * s^2)))
	func += w[1] * exp(-((x - 2*m)^2 / (2 * 2*s^2)))
	func += w[2] * exp(-((x - 3*m)^2 / (2 * 3*s^2)))
	func += w[3] * exp(-((x - 4*m)^2 / (2 * 4*s^2)))
	return func
End

Function SumGauss5(w, x) : FitFunc
	Wave w
	Variable x
	Variable func = 0
	Variable m = w[5], s = w[6]
	Variable i
	for(i = 0; i < 5; i += 1)
		func += w[i] * exp(-((x - (i+1)*m)^2 / (2 * (i+1)*s^2)))
	endfor
	return func
End

Function SumGauss6(w, x) : FitFunc
	Wave w
	Variable x
	Variable func = 0
	Variable m = w[6], s = w[7]
	Variable i
	for(i = 0; i < 6; i += 1)
		func += w[i] * exp(-((x - (i+1)*m)^2 / (2 * (i+1)*s^2)))
	endfor
	return func
End

Function SumGauss7(w, x) : FitFunc
	Wave w
	Variable x
	Variable func = 0
	Variable m = w[7], s = w[8]
	Variable i
	for(i = 0; i < 7; i += 1)
		func += w[i] * exp(-((x - (i+1)*m)^2 / (2 * (i+1)*s^2)))
	endfor
	return func
End

Function SumGauss8(w, x) : FitFunc
	Wave w
	Variable x
	Variable func = 0
	Variable m = w[8], s = w[9]
	Variable i
	for(i = 0; i < 8; i += 1)
		func += w[i] * exp(-((x - (i+1)*m)^2 / (2 * (i+1)*s^2)))
	endfor
	return func
End

Function SumGauss9(w, x) : FitFunc
	Wave w
	Variable x
	Variable func = 0
	Variable m = w[9], s = w[10]
	Variable i
	for(i = 0; i < 9; i += 1)
		func += w[i] * exp(-((x - (i+1)*m)^2 / (2 * (i+1)*s^2)))
	endfor
	return func
End

Function SumGauss10(w, x) : FitFunc
	Wave w
	Variable x
	Variable func = 0
	Variable m = w[10], s = w[11]
	Variable i
	for(i = 0; i < 10; i += 1)
		func += w[i] * exp(-((x - (i+1)*m)^2 / (2 * (i+1)*s^2)))
	endfor
	return func
End

Function SumGauss11(w, x) : FitFunc
	Wave w
	Variable x
	Variable func = 0
	Variable m = w[11], s = w[12]
	Variable i
	for(i = 0; i < 11; i += 1)
		func += w[i] * exp(-((x - (i+1)*m)^2 / (2 * (i+1)*s^2)))
	endfor
	return func
End

Function SumGauss12(w, x) : FitFunc
	Wave w
	Variable x
	Variable func = 0
	Variable m = w[12], s = w[13]
	Variable i
	for(i = 0; i < 12; i += 1)
		func += w[i] * exp(-((x - (i+1)*m)^2 / (2 * (i+1)*s^2)))
	endfor
	return func
End

Function SumGauss13(w, x) : FitFunc
	Wave w
	Variable x
	Variable func = 0
	Variable m = w[13], s = w[14]
	Variable i
	for(i = 0; i < 13; i += 1)
		func += w[i] * exp(-((x - (i+1)*m)^2 / (2 * (i+1)*s^2)))
	endfor
	return func
End

Function SumGauss14(w, x) : FitFunc
	Wave w
	Variable x
	Variable func = 0
	Variable m = w[14], s = w[15]
	Variable i
	for(i = 0; i < 14; i += 1)
		func += w[i] * exp(-((x - (i+1)*m)^2 / (2 * (i+1)*s^2)))
	endfor
	return func
End

Function SumGauss15(w, x) : FitFunc
	Wave w
	Variable x
	Variable func = 0
	Variable m = w[15], s = w[16]
	Variable i
	for(i = 0; i < 15; i += 1)
		func += w[i] * exp(-((x - (i+1)*m)^2 / (2 * (i+1)*s^2)))
	endfor
	return func
End

Function SumGauss16(w, x) : FitFunc
	Wave w
	Variable x
	Variable func = 0
	Variable m = w[16], s = w[17]
	Variable i
	for(i = 0; i < 16; i += 1)
		func += w[i] * exp(-((x - (i+1)*m)^2 / (2 * (i+1)*s^2)))
	endfor
	return func
End

// -----------------------------------------------------------------------------
// Sum of Log-Normal Distributions ()
// -----------------------------------------------------------------------------

// LogHistGauss: Gaussian in log10 space (v5.4.1)
// Applied to log10 histograms. k-mer: center = m + log(k), SD = s/sqrt(k)
// Parameters: [A1, ..., An, m, s]
// m = log10(1-mer peak), s = 1-mer SD in log10 space

Function LogHistGauss1(w, x) : FitFunc
	Wave w
	Variable x
	// w[0] = A1, w[1] = m, w[2] = s
	return w[0] * exp(-((x - w[1])^2 / (2 * w[2]^2)))
End

Function LogHistGauss2(w, x) : FitFunc
	Wave w
	Variable x
	// w[0]=A1, w[1]=A2, w[2]=m, w[3]=s
	Variable func = 0
	Variable m = w[2], s = w[3]
	func += w[0] * exp(-((x - m)^2 / (2 * s^2)))
	func += w[1] * exp(-((x - m - log(2))^2 / (2 * (s/sqrt(2))^2)))
	return func
End

Function LogHistGauss3(w, x) : FitFunc
	Wave w
	Variable x
	Variable func = 0, sd_k
	Variable m = w[3], s = w[4]
	Variable i
	for(i = 0; i < 3; i += 1)
		sd_k = s / sqrt(i+1)
		func += w[i] * exp(-((x - m - log(i+1))^2 / (2 * sd_k^2)))
	endfor
	return func
End

Function LogHistGauss4(w, x) : FitFunc
	Wave w
	Variable x
	Variable func = 0, sd_k
	Variable m = w[4], s = w[5]
	Variable i
	for(i = 0; i < 4; i += 1)
		sd_k = s / sqrt(i+1)
		func += w[i] * exp(-((x - m - log(i+1))^2 / (2 * sd_k^2)))
	endfor
	return func
End

Function LogHistGauss5(w, x) : FitFunc
	Wave w
	Variable x
	Variable func = 0, sd_k
	Variable m = w[5], s = w[6]
	Variable i
	for(i = 0; i < 5; i += 1)
		sd_k = s / sqrt(i+1)
		func += w[i] * exp(-((x - m - log(i+1))^2 / (2 * sd_k^2)))
	endfor
	return func
End

Function LogHistGauss6(w, x) : FitFunc
	Wave w
	Variable x
	Variable func = 0, sd_k
	Variable m = w[6], s = w[7]
	Variable i
	for(i = 0; i < 6; i += 1)
		sd_k = s / sqrt(i+1)
		func += w[i] * exp(-((x - m - log(i+1))^2 / (2 * sd_k^2)))
	endfor
	return func
End

Function LogHistGauss7(w, x) : FitFunc
	Wave w
	Variable x
	Variable func = 0, sd_k
	Variable m = w[7], s = w[8]
	Variable i
	for(i = 0; i < 7; i += 1)
		sd_k = s / sqrt(i+1)
		func += w[i] * exp(-((x - m - log(i+1))^2 / (2 * sd_k^2)))
	endfor
	return func
End

Function LogHistGauss8(w, x) : FitFunc
	Wave w
	Variable x
	Variable func = 0, sd_k
	Variable m = w[8], s = w[9]
	Variable i
	for(i = 0; i < 8; i += 1)
		sd_k = s / sqrt(i+1)
		func += w[i] * exp(-((x - m - log(i+1))^2 / (2 * sd_k^2)))
	endfor
	return func
End


// -----------------------------------------------------------------------------
// MSD Fitting Functions ()
// Procedure.ipf
// -----------------------------------------------------------------------------

//  MSD = 4Dt (: MSD_dt_liner)
Function FreeDiffusion(w, x) : FitFunc
	Wave w
	Variable x
	// w[0] = D ()
	return 4 * w[0] * x
End

// : 
Function MSD_dt_liner(w, t) : FitFunc
	Wave w
	Variable t
	// w[0] = D
	return 4 * w[0] * t
End

// : MSD_dt
// MSD = (L^2/3) * (1 - exp(-12*D*t/L^2))
Function MSD_dt(w, t) : FitFunc
	Wave w
	Variable t
	// w[0] = D, w[1] = L
	Variable L2 = w[1]^2
	return (L2/3) * (1 - exp(-12 * w[0] * t / L2))
End

// : ConfinedDiffusion
Function ConfinedDiffusion(w, x) : FitFunc
	Wave w
	Variable x
	// w[0] = D (), w[1] = L ()
	Variable L2 = w[1]^2
	return L2 * (1 - exp(-4 * w[0] * x / L2))
End

//  + 
Function ConfinedDiffusionWithError(w, x) : FitFunc
	Wave w
	Variable x
	// w[0] = D, w[1] = L, w[2] = epsilon ()
	Variable L2 = w[1]^2
	return L2 * (1 - exp(-4 * w[0] * x / L2)) + 4 * w[2]^2
End

//  + : MSD_dt_epsilon
Function MSD_dt_epsilon(w, t) : FitFunc
	Wave w
	Variable t
	// w[0] = D, w[1] = L, w[2] = epsilon
	Variable L2 = w[1]^2
	return (L2/3) * (1 - exp(-12 * w[0] * t / L2)) + 4 * w[2]^2
End

//  + : MSD_dt_Alpha_epsilon
Function MSD_dt_Alpha_epsilon(w, t) : FitFunc
	Wave w
	Variable t
	// w[0] = D, w[1] = alpha, w[2] = epsilon
	return 4 * w[0] * t^w[1] + 4 * w[2]^2
End

//  MSD = 4D*t^alpha
Function AnomalousDiffusion(w, x) : FitFunc
	Wave w
	Variable x
	// w[0] = D, w[1] = alpha
	return 4 * w[0] * x^w[1]
End

//  + 
Function AnomalousDiffusionWithError(w, x) : FitFunc
	Wave w
	Variable x
	// w[0] = D, w[1] = alpha, w[2] = epsilon
	return 4 * w[0] * x^w[1] + 4 * w[2]^2
End

// -----------------------------------------------------------------------------
// Displacement Distribution Functions ()
// -----------------------------------------------------------------------------

// 
Function DisplacementDist1(w, x) : FitFunc
	Wave w
	Variable x
	// w[0] = A, w[1] = sigma (= sqrt(4*D*dt))
	if(x < 0)
		return 0
	endif
	Variable sigma2 = w[1]^2
	return w[0] * (x / sigma2) * exp(-x^2 / (2 * sigma2))
End

// 2
Function DisplacementDist2(w, x) : FitFunc
	Wave w
	Variable x
	if(x < 0)
		return 0
	endif
	Variable func = 0
	func += w[0] * (x / w[2]^2) * exp(-x^2 / (2 * w[2]^2))
	func += w[1] * (x / w[3]^2) * exp(-x^2 / (2 * w[3]^2))
	return func
End

// 3
Function DisplacementDist3(w, x) : FitFunc
	Wave w
	Variable x
	if(x < 0)
		return 0
	endif
	Variable func = 0
	func += w[0] * (x / w[3]^2) * exp(-x^2 / (2 * w[3]^2))
	func += w[1] * (x / w[4]^2) * exp(-x^2 / (2 * w[4]^2))
	func += w[2] * (x / w[5]^2) * exp(-x^2 / (2 * w[5]^2))
	return func
End

// 4
Function DisplacementDist4(w, x) : FitFunc
	Wave w
	Variable x
	Variable A, sigma2
	if(x < 0)
		return 0
	endif
	Variable func = 0
	Variable i
	for(i = 0; i < 4; i += 1)
		A = w[i]
		sigma2 = w[4+i]^2
		func += A * (x / sigma2) * exp(-x^2 / (2 * sigma2))
	endfor
	return func
End

// 5
Function DisplacementDist5(w, x) : FitFunc
	Wave w
	Variable x
	Variable A, sigma2
	if(x < 0)
		return 0
	endif
	Variable func = 0
	Variable i
	for(i = 0; i < 5; i += 1)
		A = w[i]
		sigma2 = w[5+i]^2
		func += A * (x / sigma2) * exp(-x^2 / (2 * sigma2))
	endfor
	return func
End

// -----------------------------------------------------------------------------
// On-rate Functions ()
// -----------------------------------------------------------------------------

Function OnRateFunc(w, x) : FitFunc
	Wave w
	Variable x
	// w[0] = A (), w[1] = von (), w[2] = tau ()
	return w[0] * (1 - exp(-w[1] * x / w[2]))
End


// -----------------------------------------------------------------------------
// AIC
// -----------------------------------------------------------------------------

Function CalculateAIC(nPoints, nParams, chiSq)
	Variable nPoints, nParams, chiSq
	
	// AIC = n * ln(RSS/n) + 2k
	// RSS = chi^2 * n ()
	Variable RSS = chiSq
	Variable AIC = nPoints * ln(RSS / nPoints) + 2 * nParams
	
	return AIC
End

Function CalculateAICc(nPoints, nParams, chiSq)
	Variable nPoints, nParams, chiSq
	
	// AIC
	Variable AIC
	AIC = CalculateAIC(nPoints, nParams, chiSq)
	Variable correction = 2 * nParams * (nParams + 1) / (nPoints - nParams - 1)
	
	return AIC + correction
End

Function CalculateBIC(nPoints, nParams, chiSq)
	Variable nPoints, nParams, chiSq
	
	// BIC = n * ln(RSS/n) + k * ln(n)
	Variable RSS = chiSq
	Variable BIC = nPoints * ln(RSS / nPoints) + nParams * ln(nPoints)
	
	return BIC
End

// -----------------------------------------------------------------------------
// 
// -----------------------------------------------------------------------------

Function EvaluateBestModel(AIC_wave)
	Wave AIC_wave
	
	// AIC
	WaveStats/Q AIC_wave
	return V_minloc
End

Function CalculateDeltaAIC(AIC_wave, deltaAIC_wave)
	Wave AIC_wave, deltaAIC_wave
	
	WaveStats/Q AIC_wave
	Variable minAIC = V_min
	
	deltaAIC_wave = AIC_wave - minAIC
End

Function CalculateAkaikeWeights(deltaAIC_wave, weights_wave)
	Wave deltaAIC_wave, weights_wave
	
	Variable n = numpnts(deltaAIC_wave)
	Variable sumExp = 0
	Variable i
	
	// exp(-deltaAIC/2)
	for(i = 0; i < n; i += 1)
		sumExp += exp(-deltaAIC_wave[i] / 2)
	endfor
	
	// Akaike weights
	for(i = 0; i < n; i += 1)
		weights_wave[i] = exp(-deltaAIC_wave[i] / 2) / sumExp
	endfor
End

// -----------------------------------------------------------------------------
// exp_onrate - On-rate
// On event: y = V0 * tau * (1 - exp(-x/tau))
// w[0] = tau ( [s])
// w[1] = V0 ( [events/s])
// -----------------------------------------------------------------------------
Function exp_onrate(w, x) : FitFunc
	Wave w
	Variable x
	
	Variable tau = w[0]
	Variable V0 = w[1]
	
	// On event = V0 * tau * (1 - exp(-x/tau))
	//  = V0,  = V0 * tau
	return V0 * tau * (1 - exp(-x / tau))
End
