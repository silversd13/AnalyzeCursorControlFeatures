%% baseline stability
clear, clc, close all

%% experiment info
expts = [];

expts(end+1).yymmdd = '20190515';
expts(end).hhmmss = {'105504'};
expts(end).blackrock = {{
    {'105442','001'}
    {'105442','002'}
    {'105442','003'}
    {'105442','004'}
    {'105442','005'} }};

% expts(end+1).yymmdd = '20190521';
% expts(end).hhmmss = {'133731'};
% expts(end).blackrock = {{
%     {'133609','001'} }};

if ismac,
    basedir = '/Volumes/FLASH/Bravo1';
else,
    basedir = '/media/dsilver/data/Bravo1';
end

%% load data
ch_mean = {};
ch_var = {};
br_ch_mean = {};
br_ch_var = {};
for i=1:length(expts),
    expt = expts(i);
    yymmdd = expt.yymmdd;
    for ii=1:length(expt.hhmmss),
        hhmmss = expt.hhmmss{ii};
        br_files = expt.blackrock{ii};
        
        % go through datafiles (looks for imagined and clda for baseline)
        datadir = fullfile(basedir,yymmdd,...
            'GangulyServer','Center-Out',yymmdd,hhmmss,'Imagined');
        disp(datadir)
        files = dir(fullfile(datadir,'Data*.mat'));

        % load data from first file
        load(fullfile(files(1).folder,files(1).name));
        ch_mean{end+1} = TrialData.ChStats.Mean;
        ch_var{end+1} = TrialData.ChStats.Var;
        
        % load blackrock data
        lfp_ref = [];
        for iii=1:length(br_files),
            br_hhmmss = br_files{iii}{1};
            br_block = br_files{iii}{2};
            datadir = fullfile(basedir,yymmdd,'Blackrock',...
                sprintf('%s-%s',yymmdd,br_hhmmss));
            file = fullfile(datadir,sprintf('%s-%s-%s.ns2',...
                yymmdd,br_hhmmss,br_block));
            tmp = openNSx(file,'precision','double');
            lfp = tmp.Data(1:128,:);
            mu = median(lfp);
            lfp_ref = cat(2,lfp_ref, lfp - mu);
            Fs = tmp.MetaTags.SamplingFreq;
            clear tmp
        end
        
        % recompute ch_stats every 2 min
        N = size(lfp_ref,2);
        NumWin = floor(N/120/Fs);
        br_ch_mean{end+1} = {};
        br_ch_var{end+1} = {};
        for iii=1:NumWin,
            idx = (iii-1)*120*Fs + (1:120*Fs);
            br_ch_mean{end}{iii} = mean(lfp_ref(:,idx),2);
            br_ch_var{end}{iii}  = var(lfp_ref(:,idx),[],2);
        end
    end
end


%% look at stats for each channel, evolving over experiment
figure('Position',[207 287 1048 505]);

% channel means
plt_mean = cat(2,br_ch_mean{1}{:});
subplot(1,2,1); hold on
for i=1:128,
    plot3(i,-1,ch_mean{1}(i),'k.');
    plot3(i*ones(1,size(plt_mean,2)),1:size(plt_mean,2),plt_mean(i,:));
end

xlabel('channel')
ylabel('120sec bins')
zlabel('channel means')
set(gca,'CameraViewAngle',10,'CameraPosition',[600 -150  350]);

% channel variances
plt_var = cat(2,br_ch_var{1}{:});
subplot(1,2,2); hold on
for i=1:128,
    plot3(i,-1,ch_var{1}(i),'k.');
    plot3(i*ones(1,size(plt_var,2)),1:size(plt_var,2),plt_var(i,:));
end

xlabel('channel')
ylabel('120sec bins')
zlabel('channel variance')
set(gca,'CameraViewAngle',10,'CameraPosition',[600 -150  350]);


%% identify bad channels
figure('position',[440 546 800 252]);
th = 1e5;

subplot(1,2,1)
stem(ch_var{1})
hline(th)
xlabel('channel')
ylabel('variance during baseline')
title('all channels')

% remove bad channels
bad_idx = ch_var{1} > th;
plt_var = ch_var{1};
plt_var(bad_idx) = nan;

subplot(1,2,2)
stem(plt_var)
xlabel('channel')
ylabel('variance during baseline')
title('only "good" channels')


%% same analysis but remove bad channels
figure('Position',[207 287 1048 505]);

% channel means
plt_mean = cat(2,br_ch_mean{1}{:});
plt_mean(bad_idx,:) = nan;
subplot(1,2,1); hold on
for i=1:128,
    if any(find(bad_idx)==i),
        continue;
    end
    plot3(i,-1,ch_mean{1}(i),'k.');
    plot3(i*ones(1,size(plt_mean,2)),1:size(plt_mean,2),plt_mean(i,:));
end

xlabel('channel')
ylabel('120sec bins')
zlabel('channel means')
set(gca,'CameraViewAngle',10,'CameraPosition',[600 -150  350]);

% channel variances
plt_var = cat(2,br_ch_var{1}{:});
plt_var(bad_idx,:) = nan;
subplot(1,2,2); hold on
for i=1:128,
    if any(find(bad_idx)==i),
        continue;
    end
    plot3(i,-1,ch_var{1}(i),'k.');
    plot3(i*ones(1,size(plt_var,2)),1:size(plt_var,2),plt_var(i,:));
end

xlabel('channel')
ylabel('120sec bins')
zlabel('channel variance')
set(gca,'CameraViewAngle',10,'CameraPosition',[600 -150  350]);


% bad1 = 16    21    26    29
% bad2 = 5    13    17    20    23

