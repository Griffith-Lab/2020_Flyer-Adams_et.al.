# 2020_Flyer-Adams_et.al.
Johanna G. Flyer-Adams, Emmanuel J. Rivera-Rodriguez, Junwei Yu, Jacob D. Mardovin, Martha L. Reed, Leslie C. Griffith. Regulation of olfactory associative memory by the circadian clock output signal Pigment-dispersing factor (PDF). BioRxiv doi: https://doi.org/10.1101/2020.04.17.046953

For FRET imaging analysis:

  1) FRET_via_beamsplitter_simplephasealign.m
    
    Reads raw timecourse imaging data with vertically split CFP/YFP wavelength output (yielded by a DV splitter). Aligns frames, splits into CFP and YFP signal, and converts user-designated ROI and background ROI (multiple or single) into YFP/CFP values and graphical output.
    
  2) remove_linear_trend.m
    
    Examines Percent_ratio_over_baseline (PROB) variable output from FRET_via_beamsplitter_simplephasealign for a linear trend present in user-designated baseline frames; this linear trend is then extrapolated and subtracted from the PROB dataset, creating a 'detrended' output.
  

For evening activity analysis: Both scripts below utilize the 'amean' output variable from scamp.m , a function written by C. Vecsey (Skidmore, 2019).
  1) eveningpeak.m
    
    Calculates the peak of evening activity. 
  
  2) eveningact.m
    
    Calculates key features of evening activity including evening activity onset, utilizing either a method described in Lear, Zhang and Allad (2009) or by user-designated activity threshold value.
  
  
For comments, concerns or inquiries please contact Dr. Leslie Griffith (griffith@brandeis.edu).
Note: We cannot provide advice/assistance with configuring your
system.
