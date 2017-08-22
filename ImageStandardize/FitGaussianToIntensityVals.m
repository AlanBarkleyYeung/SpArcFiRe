(* ::Package:: *)

(************************************************************************)
(* This file was generated automatically by the Mathematica front end.  *)
(* It contains Initialization cells from a Notebook file, which         *)
(* typically will have the same name as this file except ending in      *)
(* ".nb" instead of ".m".                                               *)
(*                                                                      *)
(* This file is intended to be loaded into the Mathematica kernel using *)
(* the package loading commands Get or Needs.  Doing so is equivalent   *)
(* to using the Evaluate Initialization Cells menu command in the front *)
(* end.                                                                 *)
(*                                                                      *)
(* DO NOT EDIT THIS FILE.  This entire file is regenerated              *)
(* automatically each time the parent Notebook file is saved in the     *)
(* Mathematica front end.  Any changes you make to this file will be    *)
(* overwritten.                                                         *)
(************************************************************************)



Needs["MultivariateStatistics`"]; 


InitLikelihoods[dims_] := Module[{}, 
Table[0.5, {r, dims[[1]], 1, -1}, {c, 1, dims[[2]]}]];


(* Determine the mean and covariance for a Gaussian fitted to a target image.  The approach is similar to an EM algorithm for points in the X-Y plane, but here, all points (pixels) are present and we weight these points by their intensity values (as well as their likelihood values) *)
(* Note that the x-direction corresponds to columns and the y-direction corresponds to rows.  Also, we must compensate for the fact that image/matrix "coordinates" start from the top and Cartesian coordinates start from the bottom.  When needed, we use the Reverse function to reverse the order of the matrix rows, effectively switching from one system to the other. *) 
calculateMeanCovar[dims_, pixWts_] := Module[{rowVals, colVals, xMean, yMean, mean, meanPosX, meanPosY, valsCov11, valsCov12, valsCov22, cov11, cov12, cov22, covar},
rowVals = Table[r, {r, 1, dims[[1]]}, {c, 1, dims[[2]]}];
colVals = Table[c, {r, 1, dims[[1]]}, {c, 1, dims[[2]]}];
xMean  = Total[pixWts * colVals, 2] / (Total[pixWts, 2]) ;
yMean  = Total[pixWts * rowVals, 2] / (Total[pixWts, 2]) ;
mean = {xMean, yMean}; 

(* Calculate covariance *)
(* meanPosX = (\!\(
\*SubsuperscriptBox[\(\[Sum]\), \(pos = 1\), \(dims[\([\)\(2\)\(]\)]\)]pos\)) / dims[[2]]; *)
(* meanPosY = (\!\(
\*SubsuperscriptBox[\(\[Sum]\), \(pos = 1\), \(dims[\([\)\(1\)\(]\)]\)]pos\)) / dims[[1]]; *)
valsCov11 = Table[(c - xMean)^2, {r, 1, dims[[1]]}, {c, 1, dims[[2]]}];
valsCov12 = Table[(r - yMean) * (c - xMean), {r, 1, dims[[1]]}, {c, 1, dims[[2]]}];
(* cov12 = cov21 *)
valsCov22 = Table[(r - yMean)^2, {r, 1, dims[[1]]}, {c, 1, dims[[2]]}];
cov11 = Total[pixWts * valsCov11, 2] / (Total[pixWts, 2]) ;
cov12 = Total[pixWts * valsCov12, 2] / (Total[pixWts, 2]) ;
cov22 = Total[pixWts * valsCov22, 2] / (Total[pixWts, 2]) ;
(* covar = {{cov22, cov12}, {cov12, cov11}}; *)
covar = {{cov11, cov12}, {cov12, cov22}};

Print[mean];
Print[covar];
Return[{mean, covar}]
]


CalculateLikelihoods[mean_, covar_, dims_] := Module[{likelihoods},
(* Gaussian fitting is done in Cartesian coordinate space, so rows are produced in reverse order *)
likelihoods = Table[PDF[MultinormalDistribution[mean, covar], {c, r}], {r, 1, dims[[1]]},  {c, 1, dims[[2]]}];
Return[likelihoods];
]


CalculatePosnNormFactor[mean_, dims_] := Module[{normCovar, normFactor},
normCovar = {{dims[[2]], 0}, {0, dims[[1]]}};
normFactor = 2 * Table[PDF[MultinormalDistribution[mean, normCovar], {c, r}], {r, 1, dims[[1]]},  {c, 1, dims[[2]]}];
Return[normFactor];
]


fitGaussianToIntensityVals[imgMtx_, numRefits_, giveDetails_] := Module[{intensities, dims, initMc, initLikelihoods, likelihoods, lkAvg, prevLkAvg, wlRatios, blAvg, blMax, maxAvgRatio, prevRatio, relRatioChange, pixWts,mc, prevMc, mean, covar, covVecCur, covVecPrev, covVecDiff, imgList, startImgPlot, curWtPlot, curMeanPlot, curContourPlot, curFitPlot, refit, initConvCount, convCount, finalMc, finalPlot, durations, frame},
intensities = Reverse[imgMtx]; (* change to Cartesian coordinates for fitting *)
dims = Dimensions[intensities];
initConvCount = 2;
convCount = initConvCount;

imgList = {};

(* initMc = calculateMeanCovar[dims, intensities];
initLikelihoods = CalculatePosnNormFactor[initMc[[1]], dims];

pixWts = intensities * initLikelihoods;
curWtPlot = ArrayPlot[Reverse[pixWts], ColorFunction -> "GrayTones", Frame -> None];
imgList = Append[imgList, Rasterize[curWtPlot]]; *)

pixWts = intensities * InitLikelihoods[dims];
(* change coordinates back to image coordinates for plotting *)
curWtPlot = ArrayPlot[Reverse[pixWts], ColorFunction -> "GrayTones", Frame -> None];
imgList = Append[imgList, Rasterize[curWtPlot]];

mc = calculateMeanCovar[dims, pixWts]; mean = mc[[1]]; covar = mc[[2]];
covVecCur = {covar[[1, 1]], covar[[1, 2]], covar[[2, 2]]}; covVecCur = covVecCur / Norm[covVecCur];
curMeanPlot = ListPlot[{mean}, PlotStyle -> Directive[Orange, PointSize[0.02]], PlotRange -> {{1, dims[[2]]}, {1, dims[[1]]}}];
curContourPlot = ContourPlot[PDF[MultinormalDistribution[mean,covar], {x, y}], {x, 0, dims[[2]]}, {y,0, dims[[1]]}, ContourShading -> None, ContourStyle -> Red, ContourLabels -> Automatic];
curFitPlot = Show[curWtPlot, curMeanPlot, curContourPlot];
(* Print[curFitPlot]; *)
imgList = Append[imgList, Rasterize[curFitPlot]];

For[refit = 0, (refit <= numRefits) && (convCount != 0 || giveDetails), refit++,
Print[refit];
(* determine likelihoods from previous fit *)
likelihoods = CalculateLikelihoods[mean, covar, dims];
Print["likelihood average: "]; Print[lkAvg = Total[likelihoods, 2] / (dims[[1]] * dims[[2]])];
If[ValueQ[prevLkAvg], Print["likelihood change: "]; Print[lkAvg - prevLkAvg]; Print["likelihood relative change: "]; Print[(lkAvg - prevLkAvg)/prevLkAvg]];
prevLkAvg = lkAvg;
wlRatios = pixWts / likelihoods;
Print["wtd-brightness/likelihood ratio average: "]; Print[blAvg = Total[wlRatios, 2] / (dims[[1]] * dims[[2]])];
Print["wtd-brightness/likelihood ratio max: "]; Print[blMax = Max[wlRatios]];
maxAvgRatio = blMax / blAvg;
Print["max/average: "]; Print[maxAvgRatio];
If[ValueQ[prevRatio], Print["ratio change: "]; Print[maxAvgRatio - prevRatio]; Print["relative ratio change: "]; Print[relRatioChange =(maxAvgRatio - prevRatio)/prevRatio]];
prevRatio = maxAvgRatio;
(* Print[ArrayPlot[likelihoods, ColorFunction -> "GrayTones", Frame -> None]]; *)
pixWts = intensities * likelihoods;
(* Print[ArrayPlot[pixWts, ColorFunction -> "GrayTones", Frame -> None]]; *)
(* change coordinates back to image coordinates for plotting *)
curWtPlot = ArrayPlot[Reverse[pixWts], ColorFunction -> "GrayTones", Frame -> None];
imgList = Append[imgList, Rasterize[curWtPlot]];
If[convCount != 0 && Abs[relRatioChange] < 0.5,
convCount = convCount - 1;
If[convCount == 0,
finalMc = {mean, covar};
];
];
If[Abs[relRatioChange] >= 0.5,
convCount = initConvCount;
];

If[(refit < numRefits) && (convCount != 0 || giveDetails),
prevMc = mc;
mc = calculateMeanCovar[dims, pixWts]; mean = mc[[1]]; covar = mc[[2]];
covVecPrev = covVecCur;
covVecCur = {covar[[1, 1]], covar[[1, 2]], covar[[2, 2]]}; covVecCur = covVecCur / Norm[covVecCur];
covVecDiff = 1 - Dot[covVecPrev, covVecCur];
Print["covariance shape change: "]; Print[covVecDiff];
curMeanPlot = ListPlot[{mean}, PlotStyle -> Directive[Orange, PointSize[0.02]], PlotRange -> {{1, dims[[2]]}, {1, dims[[1]]}}];
curContourPlot = ContourPlot[PDF[MultinormalDistribution[mean,covar], {x, y}], {x, 0, dims[[2]]}, {y,0, dims[[1]]}, ContourShading -> None, ContourStyle -> Red, ContourLabels -> Automatic];
curFitPlot = Show[curWtPlot, curMeanPlot, curContourPlot];
(* Print[curFitPlot]; *)
imgList = Append[imgList, Rasterize[curFitPlot]];
];
];

If[convCount != 0, 
Print["Warning: did not reach convergence within allowed number of iterations"]; 
finalMc = mc;
];


imgList = Append[imgList, 
finalPlot = Show[ArrayPlot[Reverse[intensities], ColorFunction -> "GrayTones", Frame -> None],
ListPlot[{finalMc[[1]]}, PlotStyle -> Directive[Blue, PointSize[0.02]], PlotRange -> {{1, dims[[2]]}, {1, dims[[1]]}}],
ContourPlot[PDF[MultinormalDistribution[finalMc[[1]], finalMc[[2]]], {x, y}], {x, 0, dims[[2]]}, {y,0, dims[[1]]}, ContourShading -> None, ContourStyle -> Blue, ContourLabels -> Automatic]]];
Print[finalPlot];

(* visualization to help figure out how to do auto-cropping *)
Print[Show[ArrayPlot[Reverse[intensities], ColorFunction -> "GrayTones", Frame -> None],
ListPlot[{finalMc[[1]]}, PlotStyle -> Directive[Green, PointSize[0.02]], PlotRange -> {{1, dims[[2]]}, {1, dims[[1]]}}],
ContourPlot[PDF[MultinormalDistribution[finalMc[[1]], finalMc[[2]]], {x, y}], {x, 0, dims[[2]]}, {y,0, dims[[1]]}, Contours -> {10^-5, 10^-6, 10^-7, 10^-8, 10^-9}, ContourShading -> None, ContourStyle -> Green, ContourLabels -> Automatic]]];

Print[Dimensions[imgList]];

If[giveDetails, 
durations = {3};
For[frame = 1, frame < Length[imgList] - 1, frame++, durations = Append[durations, 1]];
durations = Append[durations, 5];
Print[durations];
Export[ToString[Round[Mod[AbsoluteTime[], 1000000]]] <>"_fitvis.gif", imgList, "DisplayDurations" -> durations];
];

Return[{finalMc[[1]], finalMc[[2]], imgList}]
]



