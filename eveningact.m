function [a,da,mmn_da,evening_onset,evening_peak] = eveningact(data,~,onset_determination_method)
%Function: EVENING_ACT
%
%Examines a Zx48 cell array (24hr mean activity, 30min bins) for 
%various features of evening activity. Compatible with 'amean' output variable 
%from C. Vecsey's SCAMP function (U. Skidmore, 2019). Graphs these evening 
%activity features for any individual or multiple sample IDs according to 
%prompted user input. 
%
%            % % % USED IN Flyer-Adams, et. al. 2020 % % % % 
%
%Input variables: 
%  1) DATA :  A Zx48 cell array (ie: standard output of SCAMP amean: 24hr 
%       average of 30m binned activity counts, with bin (ZT time) increasing 
%       along columns,and fly # increasing along rows ).
%
%  2) ONSET_DETERMINATION_METHOD : The method by which the evening activity
%       onset value is calculated.
%           1 == Method described by Lear, Zhang, Allada (2009) (as used in
%                    Flyer-Adams, et. al. 2020)
%           2 == Threshold (user determined value)
%
%Output variables:
%  1) A : Activity values, normalized.
%
%  2) DA : Derivative of A
%
%  3) MMN_DA : Moving mean of DA between bin 8:23 with a 4-bin roll.
%
%  4) EVENING_ONSET : Max of MMN_DA between bin 10:23
%
%  5) EVENING_PEAK : Max of A between bins 16:24.
%%
prompt1 = 'Enter number of first time series to graph: ';
input1 = input(prompt1);

prompt2 = 'Enter number of last time series to graph, or ENTER for singular graph: ';
input2 = input(prompt2);

prompt3 = 'Enter rolling mean evening onset threshold: ';
if onset_determination_method == 2
    input3 = input(prompt3);
else
end

data = data;

for i = 1:(size(data,1))
    a(i,:) = (data(i,:) - mean(data(i,:),2))/std(data(i,:));%Normalize data
    
    da(i,:) = diff(a(i,:));%Calculate rate of change
    
    mmn_da(i,:) = movmean(da(i,8:23),4);%Calculate rolling average with 4 bin (2hr) roll
            
end

for i = 1:size(data,1)
    temp = find(a(i,16:24) == max(a(i,16:24)));
            if size(temp,2) > 1
                temp = mean(temp);
            end
    evening_peak(i) = temp + 15;
end

%%%%%%%%%%
if onset_determination_method == 1
    
    z = [8:23];
    
%   for j = 1:(size(data,1))
%   on_ind = find(mmn_da(j,10:24) == max(mmn_da(j,10:24)));%Find bin# of max rolling avg. change
%        if size(on_ind,2) > 1
%            evening_onset(j) = z(on_ind(1) + 9);
%        else evening_onset(j) = z(on_ind + 9);
%        end
%        
%   end
    
   for j = 1:(size(data,1))
   on_ind = find(mmn_da(j,3:end) == max(mmn_da(j,3:end)));%Find bin# of max rolling avg. change
        if size(on_ind,2) > 1
            evening_onset(j) = z(on_ind(1) + 2);
        else evening_onset(j) = z(on_ind + 2);
        end
        
   end
   
    if isempty(input2) == 1

        figure; 
        plot(a(input1,:),'k'); hold on;
        plot(da(input1,:),'c'); hold on;
        plot(z,mmn_da(input1,:),'m'); hold on;
        plot(evening_onset(input1),max(mmn_da(input1,3:end)),'om','MarkerFaceColor','m'); hold on;
        temp = floor(evening_peak(input1)) == ceil(evening_peak(input1));
            if temp == 1
                plot(evening_peak(input1),a(input1,evening_peak(input1)),'og','MarkerFaceColor','g'); hold on; 
            else plot(evening_peak(input1),...
                    (a(input1,floor(evening_peak(input1)))+a(input1,ceil(evening_peak(input1))))/2,...
                    'og','MarkerFaceColor','g'); hold on;
            end
        yl = ylim;
        plot([evening_onset(input1) evening_onset(input1)],[min(ylim) max(ylim)],'--m'); hold on;
        plot([evening_peak(input1) evening_peak(input1)],[min(ylim) max(ylim)],'--g'); hold on;

    else        
        m = input2 - input1 + 1;
        figure;
        
        if m<9
            for n = 1:m
                subplot(2,4,n);
                plot(a(input1+n-1,:),'k'); hold on;
                plot(da(input1+n-1,:),'c'); hold on;
                plot(z,mmn_da(input1+n-1,:),'m'); hold on;
                plot(evening_onset(input1+n-1),max(mmn_da(input1+n-1,3:end)),'om','MarkerFaceColor','m'); hold on;
                temp = floor(evening_peak(input1+n-1)) == ceil(evening_peak(input1+n-1));
                    if temp == 1
                        plot(evening_peak(input1+n-1),a(input1+n-1,evening_peak(input1+n-1)),'og','MarkerFaceColor','g'); hold on; 
                    else plot(evening_peak(input1+n-1),...
                            (a(input1+n-1,floor(evening_peak(input1+n-1)))+a(input1+n-1,ceil(evening_peak(input1+n-1))))/2,...
                            'og','MarkerFaceColor','g'); hold on;
                    end
                yl = ylim;
                plot([evening_onset(input1+n-1) evening_onset(input1+n-1)],[min(ylim) max(ylim)],'--m'); hold on;
                plot([evening_peak(input1+n-1) evening_peak(input1+n-1)],[min(ylim) max(ylim)],'--g'); hold on;
            end

         elseif (8<m)&&(m<17)
                for n = 1:m
           
            subplot(4,4,n);
            plot(a(input1+n-1,:),'k'); hold on;
                plot(da(input1+n-1,:),'c'); hold on;
                plot(z,mmn_da(input1+n-1,:),'m'); hold on;
                plot(evening_onset(input1+n-1),max(mmn_da(input1+n-1,3:end)),'om','MarkerFaceColor','m'); hold on;
                temp = floor(evening_peak(input1+n-1)) == ceil(evening_peak(input1+n-1));
                    if temp == 1
                        plot(evening_peak(input1+n-1),a(input1+n-1,evening_peak(input1+n-1)),'og','MarkerFaceColor','g'); hold on; 
                    else plot(evening_peak(input1+n-1),...
                            (a(input1+n-1,floor(evening_peak(input1+n-1)))+a(input1+n-1,ceil(evening_peak(input1+n-1))))/2,...
                            'og','MarkerFaceColor','g'); hold on;
                    end
                yl = ylim;
                plot([evening_onset(input1+n-1) evening_onset(input1+n-1)],[min(ylim) max(ylim)],'--m'); hold on;
                plot([evening_peak(input1+n-1) evening_peak(input1+n-1)],[min(ylim) max(ylim)],'--g'); hold on;            

                end

            elseif (16<m)&&(m<25)
                for n = 1:m
        
            subplot(5,5,n);
            plot(a(input1+n-1,:),'k'); hold on;
                plot(da(input1+n-1,:),'c'); hold on;
                plot(z,mmn_da(input1+n-1,:),'m'); hold on;
                plot(evening_onset(input1+n-1),max(mmn_da(input1+n-1,3:end)),'om','MarkerFaceColor','m'); hold on;
                temp = floor(evening_peak(input1+n-1)) == ceil(evening_peak(input1+n-1));
                    if temp == 1
                        plot(evening_peak(input1+n-1),a(input1+n-1,evening_peak(input1+n-1)),'og','MarkerFaceColor','g'); hold on; 
                    else plot(evening_peak(input1+n-1),...
                            (a(input1+n-1,floor(evening_peak(input1+n-1)))+a(input1+n-1,ceil(evening_peak(input1+n-1))))/2,...
                            'og','MarkerFaceColor','g'); hold on;
                    end
                yl = ylim;
                plot([evening_onset(input1+n-1) evening_onset(input1+n-1)],[min(ylim) max(ylim)],'--m'); hold on;
                plot([evening_peak(input1+n-1) evening_peak(input1+n-1)],[min(ylim) max(ylim)],'--g'); hold on;            

                end

         elseif (24<m)&&(m<33)
                for n = 1:m
         
                    subplot(5,7,n);
                    plot(a(input1+n-1,:),'k'); hold on;
                    plot(da(input1+n-1,:),'c'); hold on;
                    plot(z,mmn_da(input1+n-1,:),'m'); hold on;
                    plot(evening_onset(input1+n-1),max(mmn_da(input1+n-1,3:end)),'om','MarkerFaceColor','m'); hold on;
                    temp = floor(evening_peak(input1+n-1)) == ceil(evening_peak(input1+n-1));
                        if temp == 1
                            plot(evening_peak(input1+n-1),a(input1+n-1,evening_peak(input1+n-1)),'og','MarkerFaceColor','g'); hold on; 
                        else plot(evening_peak(input1+n-1),...
                                (a(input1+n-1,floor(evening_peak(input1+n-1)))+a(input1+n-1,ceil(evening_peak(input1+n-1))))/2,...
                                'og','MarkerFaceColor','g'); hold on;
                        end
                    yl = ylim;
                    plot([evening_onset(input1+n-1) evening_onset(input1+n-1)],[min(ylim) max(ylim)],'--m'); hold on;
                    plot([evening_peak(input1+n-1) evening_peak(input1+n-1)],[min(ylim) max(ylim)],'--g'); hold on;            
                end

        
         elseif (32<m)&&(m<49)
                for n = 1:m
        
                    subplot(7,7,n);
                    plot(a(input1+n-1,:),'k'); hold on;
                    plot(da(input1+n-1,:),'c'); hold on;
                    plot(z,mmn_da(input1+n-1,:),'m'); hold on;
                    plot(evening_onset(input1+n-1),max(mmn_da(input1+n-1,3:end)),'om','MarkerFaceColor','m'); hold on;
                    temp = floor(evening_peak(input1+n-1)) == ceil(evening_peak(input1+n-1));
                        if temp == 1
                            plot(evening_peak(input1+n-1),a(input1+n-1,evening_peak(input1+n-1)),'og','MarkerFaceColor','g'); hold on; 
                        else plot(evening_peak(input1+n-1),...
                                (a(input1+n-1,floor(evening_peak(input1+n-1)))+a(input1+n-1,ceil(evening_peak(input1+n-1))))/2,...
                                'og','MarkerFaceColor','g'); hold on;
                        end
                    yl = ylim;
                    plot([evening_onset(input1+n-1) evening_onset(input1+n-1)],[min(ylim) max(ylim)],'--m'); hold on;
                    plot([evening_peak(input1+n-1) evening_peak(input1+n-1)],[min(ylim) max(ylim)],'--g'); hold on;            

                end
        end
    end
    
    %% 
elseif onset_determination_method == 2
    z = 8:23;
    
    for i = 1:(size(data,1))
   
        m = 3;
        while m < 17
            if mmn_da(i,m) < input3
               m = m + 1;
            else evening_onset(i) = m + 7;
                    m = 17; 
            end
        end
    end
    
    figure;
    k = input2 - input1 + 1; 
    
    for i = 1:k
        subplot(7,7,i);
        plot(a(input1+i-1,:),'k'); hold on;
        plot(da(input1+i-1,:),'c'); hold on;
        plot(z,mmn_da(input1+i-1,:),'m'); hold on;           
        plot(evening_onset(input1+i-1),max(mmn_da(input1+i-1,3:end)),'om','MarkerFaceColor','m'); hold on;
            plot(evening_peak(input1),a(input1,evening_peak),'og','MarkerFaceColor','g'); hold on;

    end
end
    


%outputArg1 = inputArg1;
%outputArg2 = inputArg2;
end

