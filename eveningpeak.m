function [evening_peak_analysis] = eveningpeak(amean)
% [ INDEX_INDIV_MAX, indiv_max ] = eveningpeak( AMEAN )
%
%For a 48-bin array A (ie: standard output of SCAMP amean: 24hr average of 30m binned activity counts, with 
%bin (ZT time) increasing along columns,and fly # increasing along rows ):
%
%Returns struct EVENING_PEAK_ANALYSIS with the following elements:
%  a) INDEX_INDIV_MAX: index locale of INDIV_MAX
%  b) INDIV_MAX: max activity count for each fly within +/-3hrs of population max activity inside ZT6-18 
%  c) MEAN_PEAKZT: Index locale of the population average peak activity
%          (determined from INDEX_INDIV_MAX)
%  d) STD : Standard deviation of population INDEX_INDIV_MAX


%   Trims dataset to ZT6-18 to exclude morning peak activity.
A618 = amean(:,12:36);

%Locate the evening peak of the population: Sum activity within each bin 
%across all flies, and find the bin containing
%the max summed value
sumA618 = sum(A618,1);
[~,index_sum_max] = max(sumA618, [], 2);

%Find the max activity of each fly within +/- 3hrs of the population peak
%bin #. 

trimmed = A618(:,(index_sum_max - 6):(index_sum_max + 6));
evening_peak_analysis.indiv_max = max(trimmed, [], 2);


%FIND INDEX OF INDIVIDUAL MAXIMA (indiv_max) WITHIN THE A618 ARRAY:

%Preallocate index array:
x = size(amean,1);
evening_peak_analysis.index_indiv_max = zeros(x,1);

%Return indices of individual maxima within the ZT6-18 dataset that are
    %+/- 3hr from population evening maximum.
y = 1;
while y < x + 1,
    %disp(y)
    temp = find(A618(y,(index_sum_max - 6):(index_sum_max + 6))== ...
        evening_peak_analysis.indiv_max(y,1)) + index_sum_max - 7;
       
    %Determine number of equal maxima within the ZT6-18 datasetthat are
    %+/- 3hr from population evening maximum. 
    %        
    %       If only one, then proceed to identify the max activity value 
    %       of the next fly.
        if size(temp,2)==1
            %sum(A618(y,(index_sum_max - 6):(index_sum_max + 6))==indiv_max(y,:))==1
            evening_peak_analysis.index_indiv_max(y,1) = temp;
            clear temp;
            y = y + 1;
            
    %       If more than one, identify which is closest, temporally, to the
    %       population max bin (index_sum_max), and identify it as the max 
    %       value for that fly, disregarding the other(s).                
        else
            temp2 = index_sum_max - temp;
            evening_peak_analysis.index_indiv_max(y,1) = temp(find(temp2==min(temp2)));
            clear temp;
            clear temp2;
            y = y + 1;
        end    
end

%Convert individual maxima indices from trimmed dataset indices to full
%24hr indices

evening_peak_analysis.index_indiv_max = evening_peak_analysis.index_indiv_max + 11;

evening_peak_analysis.indiv_max_ZT = evening_peak_analysis.index_indiv_max/2;

evening_peak_analysis.mean_peakZT = mean(evening_peak_analysis.index_indiv_max)/2;

evening_peak_analysis.std = std(evening_peak_analysis.index_indiv_max); 

x = size(evening_peak_analysis.index_indiv_max,1);
evening_peak_analysis.sem = evening_peak_analysis.std/sqrt(x);
end

