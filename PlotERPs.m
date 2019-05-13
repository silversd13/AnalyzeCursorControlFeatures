function PlotERPs(datadir)
% function PlotERPs(datadir)
% loads all trials in datadir and plots each feature as a heatmap in a
% separate figure. saves a .png
% 
% datadir - directory of data (also saves fig there)

fprintf('\n\nMaking ERP plots...\n')

if ~exist('datadir','var'),
    datadir = uigetdir();
end
fprintf('datadir = ''%s''\n', datadir)

% grab data trial data
datafiles = dir(fullfile(datadir,'Data*.mat'));
Y = [];
TargetID = [];
for i=1:length(datafiles),
    % load data, grab neural features
    load(fullfile(datadir,datafiles(i).name)) %#ok<LOAD>
    
    % only look from center to out
    Ytrial = cat(2,TrialData.NeuralFeatures{:});
    try
        Y = cat(3,Y,Ytrial);
        TargetID = cat(1,TargetID,TrialData.TargetAngle);
    end
end
time0 = find(TrialData.Time >= TrialData.Events(end).Time,1)-1;

% set up image saving
savedir = '~/Desktop/Bravo1_ERPs';
split_path = strsplit(datafiles(1).folder,'/');
yyyymmdd    = split_path{end-2};
hhmmss      = split_path{end-1};
trial_type  = split_path{end};

% SN: 8596-002131
ecog_grid = [
    91	84	67	90	70	79	88	69	92	83	65	89	87	86	94	82
    66	93	78	95	76	75	85	73	68	80	74	72	96	71	77	81
    60	37	42	50	56	54	49	40	43	35	45	63	47	46	58	55
    53	57	33	48	39	51	41	34	64	52	62	38	36	44	61	59
    8	26	29	28	9	5	13	20	11	23	16	22	27	4	3	31
    7	21	15	24	25	1	2	32	14	12	30	19	18	17	6	10
    110	125	111	115	103	117	100	123	113	119	118	98	101	105	116	99
    107	112	97	128	121	124	108	109	127	126	106	122	114	120	104	102];

[R,C] = size(ecog_grid);
Nch = 128; % channels
Nft = size(Y,1)/Nch; % neural features
Ntm = size(Y,2); % time pts per trial
limch = ecog_grid(R,1);
legch = ecog_grid(R,round(C/2));

% all targets
TargetIDList = unique(TargetID);
leg = cell(1,length(TargetIDList));

% go through each feature and plot erps
feature_list = 1:Nft;
feature_list_str = {'DeltaPhase','DeltaPower','ThetaPower','AlphaPower',...
    'BetaPower','LowGammaPower','HighGammaPower'};
% feature_list_str = {'DeltaPhase','LMP','HighGammaPower'};
for i=feature_list,
    feature = feature_list_str{i};
    fig = figure('units','normalized','position',[.1,.1,.8,.8],...
        'name',feature,'numbertitle','off');
    ax = tight_subplot(R,C,[.01,.01],[.05,.01],[.03,.01]);
    set(ax,'NextPlot','add')
    
    
    % each reach target
    for Tidx=1:length(TargetIDList),
        % avg over trials going to same target
        T = TargetIDList(Tidx);
        leg{Tidx} = sprintf('T: %i',T);
        trial_idx = (T==TargetID);
        Ytarg = squeeze(mean(Y(:,:,trial_idx),3));

        for ch=1:Nch,
            [r,c] = find(ecog_grid == ch);
            idx = C*(r-1) + c;

            % plot
            %erp = squeeze(Ytarg((ch-1)*Nft+i,:));
            erp = squeeze(Ytarg(Nch*(i-1)+ch,:));
            plot(ax(idx),erp,'linewidth',1)

        end

    end % reach target
    
    % clean up
    XX = [1,Ntm];
    YY = cell2mat(get(ax,'YLim'));
    YY = [min(YY(:,1)),max(YY(:,2))];
    set(ax,'XLim',XX,'YLim',YY,'XTick',[],'YTick',[]);
    
    % add channel nums & vline at t=0
    for ch=1:Nch,
        [r,c] = find(ecog_grid == ch);
        idx = C*(r-1) + c;
        text(ax(idx),XX(1),YY(1),sprintf('ch%03i',ch),...
            'VerticalAlignment','Bottom')
        vline(ax(idx),time0,'color',[.6,.6,.6]);
    end
    
    % add limits to limch
    [r,c] = find(ecog_grid == limch);
    idx = C*(r-1) + c;
    set(ax(idx),'XTick',XX,'XTickLabel',XX,'YTick',YY,'YTickLabel',YY)
    
    % add legend to legch
    [r,c] = find(ecog_grid == legch);
    idx = C*(r-1) + c;
    lgd = legend(ax(idx),leg,...
        'orientation','horizontal',...
        'position',[0.35,0.01,0.25,0.025]);
    
    % linkaxes (for manual adjustment of axes before saving)
    linkaxes(ax,'xy')
    
    % save plot
    savefile = fullfile(savedir,sprintf('%s_%s_%s_%s.png',...
        yyyymmdd,hhmmss,trial_type,feature));
    saveas(fig,savefile,'png')
    close(gcf)
end

fprintf('Done.\n\n')

end % PlotERPs
