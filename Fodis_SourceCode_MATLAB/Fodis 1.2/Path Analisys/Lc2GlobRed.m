function GMreduced=Lc2GlobRed(LcMaxPts,nTraces,intervals)
%da Global matrix, cio� quello che si estrae da global peaks, do una GM
%risretta per poi produrre la lista con nikcorr()

GMreduced=zeros(nTraces,size(intervals,1));
if ~isempty(intervals)
    for ii=1:nTraces
        for jj=1:size(intervals,1)
            xi=intervals(jj,:);
            logic=any((LcMaxPts{ii}*1E9>xi(1) & LcMaxPts{ii}*1E9<xi(2)));
            if logic;GMreduced(ii,jj)=1;end
        end
    end
end