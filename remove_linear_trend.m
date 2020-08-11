function [ data_detrended ] = remove_linear_trend( data,x )
%for all data listed as row (value at time) by column (trial or n)
% to remove linear trend of X bins across the entire dataset

data_detrended = zeros(size(data,1),size(data,2));
i = 1;
while i < 1 + size(data,2),
    poly = polyfit(1:x,data(1:x,i)',1);
    fit = polyval(poly,1:size(data,1));
    
    data_detrended(1:size(data,1),i) = 1 + (data(1:size(data,1),i) - fit');
    
    clear poly;
    clear fit;
    
    i = i + 1;
end

end

