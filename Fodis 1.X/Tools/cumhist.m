function [H,bins]=cumhist(A,L)

% Cumhist
% Compute the cumulative histogram of A
% using L bins
%    [bins,H] = cumhist(...) returns the Cumulative histogram h and the
%    bins 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Fisrt Compute and normalise histogram
[h,bins]=hist(A,L);
h=h/sum(h);
% Flip the array
h1=fliplr(h);
% Make the cumulative sum starting from the largest value
h2=cumsum(h1);
% Flip back the array to plot starting from zero
H=fliplr(h2);