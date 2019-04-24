%% analyze blackrock datafiles
clear, clc, close all
addpath(genpath('/home/dsilver/Projects/BR_Ecog_Visualization/NPMK'));

%% load data
% [filename,pathname] = uigetfile('*.*');
pathname = '/media/dsilver/data/Bravo1/20190321/Blackrock/20190321-141340/';
filename = '20190321-141340-001.ns2';
data = openNSx(fullfile(pathname,filename),'read','report','precision','double');

% get lfp and analog input
lfp = data.Data(1:128,:)';
anin = data.Data(129:end,:)';
Fs = data.MetaTags.SamplingFreq; % Hz
clear data

%% get trial structure from anin signal
time = (1:length(anin))/Fs - 1/Fs;

% get upward pulse times
th = 1e4;
anin = anin>th;
pulseidx = find(diff(anin)>.5)+1;
pulsetime = time(pulseidx);

%% look for groups of pulses
% consolidate (e.g., [5,5,5,5,5,4,4,4,4,4,4,4,4,1] --> [5,4,4,1])
i = 1;
ct = 1;
pulse_groups = [];
group_idx = [];
group_times = [];
while i<length(pulseidx),
    % within group of pulses
    num_pulses = 1;
    while 1,
        if pulsetime(i)==pulsetime(end),
            break;
        elseif (pulsetime(i+1)-pulsetime(i))<.2,
            num_pulses = num_pulses + 1;
            i = i + 1;
        else,
            i = i + 1;
            break;
        end
    end
    if num_pulses==5, % if 5, split into 2 and 3
        pulse_groups(ct) = 2; % time of first pulse
        group_idx(ct) = pulseidx(i-5);
        group_times(ct) = pulsetime(i-5);
        ct = ct + 1;
        
        pulse_groups(ct) = 3; % time of third pulse
        group_idx(ct) = pulseidx(i-3);
        group_times(ct) = pulsetime(i-3);
        ct = ct + 1;
    else, % otherwise, collect time of first pulse
        pulse_groups(ct) = num_pulses; 
        group_idx(ct) = pulseidx(i-num_pulses); 
        group_times(ct) = pulsetime(i-num_pulses); 
        ct = ct + 1;
    end
end

%% only look at first session data (imagined mvmts)
idx20 = find(pulse_groups>=20);
start_idx = idx20(1)+1;
end_idx = idx20(2)-2;

pulse_groups    = pulse_groups(start_idx:end_idx);
group_idx       = group_idx(start_idx:end_idx);
group_times     = group_times(start_idx:end_idx);

%% trial times
idx1 = find(pulse_groups==1);
idx2 = find(pulse_groups==2);
idx3 = find(pulse_groups==3);
trials = [];
for i=1:length(idx1),
    trials(i).iti_idx = group_idx(idx1(i));
    trials(i).hold_idx = group_idx(idx2(i));
    trials(i).mvmt_idx = group_idx(idx3(i));
    trials(i).iti_time = group_times(idx1(i));
    trials(i).hold_time = group_times(idx2(i));
    trials(i).mvmt_time = group_times(idx3(i));
end

%% load matlab data to get idx of trial types
pathname = '/media/dsilver/data/Bravo1/20190321/GangulyServer/Center-Out/20190321/141351/Imagined';
datafiles = dir(fullfile(pathname,'Data*.mat'));
for i=1:length(datafiles),
    f=load(fullfile(pathname,datafiles(i).name));
    trials(i).TargetID = f.TrialData.TargetID;
    trials(i).TargetAngle = f.TrialData.TargetAngle;
end

%% limit data to session being analyzed (imagined mvmts)
idx = (trials(1).iti_idx-round(5*Fs)):(trials(end).mvmt_idx+round(5*Fs));
time = time(idx);
anin = anin(idx);
lfp = lfp(idx,:);

%% reference and zscore lfp channels
mu = median(lfp,2);
lfp = zscore(lfp-mu);


%% filter each channel in 2hz bands & hilbert to get instantaneous phase
fpass_starts = 1:2:148;
pwr = zeros(size(lfp,1),size(lfp,2),length(fpass_starts));
for i=1:length(fpass_starts),
    fpass = [fpass_starts(i),fpass_starts(i)+2];
    fprintf('fpass: [%i,%i]\n',fpass(1),fpass(2))
    
    % filter
    [b,a] = butter(2,fpass/(Fs/2));
    flfp = filtfilt(b,a,lfp);
    
    % pwr
    hlfp = hilbert(flfp);
    
    % store & zscore
    pwr(:,:,i) = zscore(log10(abs(hlfp)));
end

%% channel layout for plotting
ch_layout = [
    96	84	76	95	70	82	77	87	74	93	66	89	86	94	91	79
    92	65	85	83	68	75	78	81	72	69	88	71	80	73	90	67
    62	37	56	48	43	44	60	33	49	64	58	59	63	61	51	34
    45	53	55	52	35	57	38	50	54	39	47	42	36	40	46	41
    19	2	10	21	30	23	17	28	18	1	8	15	32	27	9	3
    24	13	6	4	7	16	22	5	20	14	11	12	29	26	31	25
    124	126	128	119	110	113	111	122	117	125	112	98	104	116	103	106
    102	109	99	101	121	127	105	120	107	123	118	114	108	115	100	97];
[R,C] = size(ch_layout);
Nch = 128;
limch = ch_layout(R,1);
cbarch = ch_layout(R,C);

%%
for target=1:8,
    fig = figure('units','normalized','position',[.1,.1,.8,.8],...
        'name',sprintf('hilb-spectrogram-target-%i',target));
    ax = tight_subplot(R,C,[.01,.01],[.06,.01],[.03,.01]);
    set(ax,'NextPlot','add');
    for ch=1:Nch,
        [r,c] = find(ch_layout == ch);
        idx = C*(r-1) + c;
        
        E = [trials.iti_time]-time(1);
        E = E([trials.TargetID]==target);
        for i=1:length(fpass_starts),
            erps(:,:,i) = createdatamatc(squeeze(pwr(:,ch,i)),E,Fs,[0,4]);
        end
        
        imagesc(ax(idx),linspace(-3,1,4000),fpass_starts,squeeze(mean(erps,2)));
        drawnow;
    end
    % make all axes the same
    XX = [-3,1];
    YY = [1,149];
    CC = cell2mat(get(ax,'CLim'));
    CC = [min(CC(:)),max(CC(:))];
    set(ax,'XTick',[],'YTick',[],'XLim',XX,'YLim',YY,'CLim',CC)
    
    % add channel nums
    for ch=1:Nch,
        [r,c] = find(ch_layout == ch);
        idx = C*(r-1) + c;
        text(ax(idx),XX(1),YY(1),sprintf('ch%03i',ch),...
            'VerticalAlignment','Bottom')
        vline(ax(idx),0,'r');
    end
    
    % add lims and legend
    [r,c] = find(ch_layout == limch);
    idx = C*(r-1) + c;
    set(ax(idx),'XTick',XX,'XTickLabel',XX,'YTick',YY,'YTickLabel',YY)
    
    [r,c] = find(ch_layout == 120);
    idx = C*(r-1) + c;
    text(ax(idx),-1,-30,sprintf('Target %i',target),'FontSize',16)

    [r,c] = find(ch_layout == cbarch);
    idx = C*(r-1) + c;
    colorbar(ax(idx),'location','southoutside','position',[.85,.025,.1,.02]);
    
    % save figure
    saveas(fig,sprintf('Figures/20190321-imagined-abstract/hilb-spectrogram-target-%i.png',target))
    close(fig)
end




