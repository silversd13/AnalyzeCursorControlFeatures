function [anin,lfp,Fs] = load_blackrock(basedir,yyyymmdd,brock)

tmp = strsplit(brock,'-');
pathname = fullfile(basedir,yyyymmdd,'Blackrock',...
    sprintf('%s-%s',yyyymmdd,tmp{1}));
filename = sprintf('%s-%s.ns2',yyyymmdd,brock);
data = openNSx(fullfile(pathname,filename),'uv','precision','double');
anin = data.Data(129,:);
lfp = data.Data(1:128,:);
Fs = data.MetaTags.SamplingFreq;

end % load_blackrock