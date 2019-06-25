%% plot erps to compare across days
clear, clc, close all
cc = hsv(8);

%% experiment info
expts = [];

expts(end+1).yymmdd = '20190604';
expts(end).hhmmss = {'142504'};

expts(end+1).yymmdd = '20190607';
expts(end).hhmmss = {'110703'};

expts(end+1).yymmdd = '20190610';
expts(end).hhmmss = {'112117','135719'};

mvmt_str = 'Squeeze your right hand';
savedir = '~/Desktop/Bravo1_ClickClassifier';
%% load data

% go through expts
Fcell = {};
trial = 1;
trials = [];
day_break = [];
session_break = [];
for i=1:length(expts),
    expt = expts(i);
    yymmdd = expt.yymmdd;
    day_break(end+1) = trial; 
    
    for ii=1:length(expt.hhmmss),
        hhmmss = expt.hhmmss{ii};
        session_break(end+1) = trial; 
        
        datadir = fullfile('/media/dsilver/data/Bravo1',yymmdd,...
            'GangulyServer','ImaginedMovements',yymmdd,hhmmss,mvmt_str);
        datafiles = dir(fullfile(datadir,'Data*.mat'));
        T = length(datafiles);

        for iii=1:T,
            % load data, grab neural features
            disp(datafiles(iii).name)
            load(fullfile(datadir,datafiles(iii).name))
            Fcell{trial} = cat(2,TrialData.NeuralFeatures{:})';
%             Fcell{trial} = (Fcell{trial} .* repmat(sqrt(TrialData.FeatureStats.Var),40,1)) ...
%                 + repmat(TrialData.FeatureStats.Mean,40,1); % unzscore
            trials(trial) = trial;
            trial = trial + 1;
        end % trials
    end % sessions
end % days
day_break(end+1) = trial;
session_break(end+1) = trial; 

%% plot across array
fprintf('Making ERP plots.\n')
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

% go through each feature and plot erps
feature_strs = {'delta-phase','delta-pwr','theta-pwr','alpha-pwr',...
    'beta-pwr','low-gamma-pwr','high-gamma-pwr'};
feature_list = 1:length(feature_strs); % all features
for feature=feature_list,
    % create figure
    fig = figure('units','normalized','position',[.1,.1,.8,.8],'name',feature_strs{feature});
    ax = tight_subplot(R,C,[.01,.01],[.05,.01],[.03,.01]);
    set(ax,'NextPlot','add');
    
    for s=1:length(session_break)-1,
        F = cat(3,Fcell{session_break(s):session_break(s+1)-1});
        for ch=1:Nch,
            [r,c] = find(ch_layout == ch);
            idx = C*(r-1) + c;

            erps = squeeze(F(:,(feature-1)*128+ch,:));
            t_erp = (((1:size(erps,1))-25)/TrialData.Params.UpdateRate)';
            
            % split erps into baseline to get cleaner erps
            tidx = t_erp<-1;
            base_erps = erps(tidx,:);
            
            % zscore erps
            mu_erps = mean(base_erps);
            sigma_erps = std(erps);
            z_erps = (erps - repmat(mu_erps,size(erps,1),1)) ...
                ./ repmat(sigma_erps,size(erps,1),1); 
            
            % avg erp
            erp = mean(z_erps,2);

            % clean
            plot(ax(idx),t_erp,erp,'linewidth',1)
            set(ax(idx),'XTick',[],'YTick',[]);
        end
    end
    
    % clean up
    XX = [minmax(t_erp')];
    YY = cell2mat(get(ax,'YLim'));
    YY = [min(YY(:)),max(YY(:))];
    set(ax,'XLim',XX)
    %set(ax,'YLim',YY);
    
    % add channel nums
    for ch=1:Nch,
        [r,c] = find(ch_layout == ch);
        idx = C*(r-1) + c;
        YY = get(ax(idx),'YLim');
        text(ax(idx),XX(1),YY(1),sprintf('ch%03i',ch),...
            'VerticalAlignment','Bottom')
        vline(ax(idx),-3,'k');
        vline(ax(idx),0,'r');
    end
    
    % add lims
    [r,c] = find(ch_layout == limch);
    idx = C*(r-1) + c;
    set(ax(idx),...
        'XTick',XX,'XTickLabels',XX,...
        'YTick',YY,'YTickLabels',YY);
        
    % save plot
    drawnow
    saveas(fig,fullfile(savedir,sprintf('ERPs_%s_V2',feature_strs{feature})),'png')
    close(fig);
end

fprintf('Done.\n\n')

