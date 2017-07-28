function [tracesExtend,tracesRetract] = readJPK(files,ii)

tracesExtend = cell(1, 2);
tracesRetract = cell(1, 2);
f=filesep;

% open a file
tmpName = tempname;

disp(['File Written to' tmpName])

% filenames=unzip(files{ii},['.' f 'temp' f files{ii}]);
filenames=unzip(files{ii},[tmpName f files{ii}]);

%Extract number of segment
segmentloci=find(~cellfun('isempty',strfind(filenames, 'segments')));
notvalid=ones(1,length(segmentloci));
for jj=1:length(segmentloci)
    if isdir(filenames{segmentloci(jj)})
        notvalid(jj)=0;
    end
end

segmentloc=segmentloci(logical(notvalid));
filenamessegm=filenames(segmentloc);
segm=zeros(1,length(segmentloc));
for jj=1:length(segmentloc)
    pieces=strsplit(filenames{segmentloc(jj)},f);
    segm(jj)=str2double(pieces(~isnan(str2double(pieces))));
end

headerloc=~cellfun('isempty',strfind(filenames, [files{ii} f 'header.properties']));
IDheadb = fopen(char(filenames(headerloc)), 'r');
dataheadb = textscan(IDheadb, '%s', 'delimiter', '\n');

idxExtLen = ~cellfun('isempty', strfind(dataheadb{1},'extend-k-length'));
ExtLenLine=strsplit(dataheadb{1}{idxExtLen},'=');
ExtLen=str2double(ExtLenLine{end});
%Num Points retr
idxRetLen = ~cellfun('isempty', strfind(dataheadb{1},'retract-k-length'));
RetLenLine=strsplit(dataheadb{1}{idxRetLen},'=');
RetLen=str2double(RetLenLine{end});

nrofsegm=max(segm);
check=0;

for kk=0:nrofsegm
    
    actsegmname=filenamessegm(segm==kk);
    
    %read header
    header=~cellfun('isempty',strfind(actsegmname, 'header'));
    IDhead = fopen(char(actsegmname(header)), 'r');
    datahead = textscan(IDhead, '%s', 'delimiter', '\n');
    
    idxSegmType = ~cellfun('isempty', strfind(datahead{1}, 'force-segment-header.settings.style'));
    SegmTypeLine=strsplit(datahead{1}{idxSegmType},'=');
    SegmType=SegmTypeLine{end};
    
    %read tipsampleseparation
    tssdataidx=~cellfun('isempty',strfind(actsegmname, 'tipSampleSeparation'));
    fidtss=fopen(char(actsegmname(tssdataidx)),'r','b','UTF-8');
    tss=fread(fidtss,'float32');
    
    
    Fdataidx=~cellfun('isempty',strfind(actsegmname, 'vDeflection'));
    fidF=fopen(char(actsegmname(Fdataidx)),'r','b','UTF-8');
    Fdata=fread(fidF,'float32');
    
    % save data
    switch SegmType
        case 'pause'
            
        case 'extend'
            
            if ExtLen~=length(tss)
                disp(['Length of header and of Extend Segment does not correspond' files{ii}]);
                error('Length Wrong')
            else
                extendVDeflaction = Fdata.*1E-9;
                extendTipSampleSeparation = tss-min(tss(:));
                check = check + 1;
            end
        case 'retract'
            if RetLen~=length(tss)
                disp(['Length of header and of Retract Segment does not correspond' files{ii}]);
                error('Length Wrong')
            else
                retractVDeflaction = Fdata.*1E-9;
                retractTipSampleSeparation = tss-min(tss(:));
                check = check + 1;
            end
        otherwise
            
            disp(['Bad file skiped (invalid format, wrong trace name): ' files{ii}]);
            % close file
            fclose(fidF);
            fclose(fidtss);
            error('Segment Unknown')
            
    end
end

% check if pause, extend and retract are defined
if(check ~= 2)
    disp(['Bad file skiped (invalid format, cannot find extend and/or retract trace/s): ' files{ii}]);
    % close file
    fclose(fidF);
    fclose(fidtss);
    fclose(IDheadb);

    error('Not enough segment')
    
end

tracesExtend{1,1} = extendTipSampleSeparation';
tracesExtend{1,2}= extendVDeflaction';
tracesRetract{1,1} = retractTipSampleSeparation';
tracesRetract {1,2}= retractVDeflaction';

fclose(fidF);
fclose(fidtss);
fclose(IDheadb);

fclose('all');
rmdir(tmpName,'s')  

