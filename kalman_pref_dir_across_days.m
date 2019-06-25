%% check if kalman weights are converging within and across days
clear, clc, close all

%% experiment info
expts = [];

expts(end+1).yymmdd = '20190514';
expts(end).hhmmss = {'112836','133050'};

expts(end+1).yymmdd = '20190515';
expts(end).hhmmss = {'110735'};

expts(end+1).yymmdd = '20190521';
expts(end).hhmmss = {'135008','141438'};

expts(end+1).yymmdd = '20190524';
expts(end).hhmmss = {'110219','133313'};

expts(end+1).yymmdd = '20190529';
expts(end).hhmmss = {'105609','113247','132457','135030'};

expts(end+1).yymmdd = '20190531';
expts(end).hhmmss = {'102944','111946','132244','135046'};

expts(end+1).yymmdd = '20190604';
expts(end).hhmmss = {'112454','140706'};

expts(end+1).yymmdd = '20190607';
expts(end).hhmmss = {'104622','133540'};

expts(end+1).yymmdd = '20190610';
% expts(end).hhmmss = {'104104','131054'};
expts(end).hhmmss = {'104104'};

expts(end+1).yymmdd = '20190618';
expts(end).hhmmss = {'135020','141917'};

expts(end+1).yymmdd = '20190621';
expts(end).hhmmss = {'110109','112545','133227','135917'};

%% load data

% go through expts
Ccell = {};
alpha = {};
lambda = {};
TargetID = {};
TargetIDstr = {};
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
            'GangulyServer','Center-Out',yymmdd,hhmmss,'BCI_CLDA');
        datafiles = dir(fullfile(datadir,'Data*.mat'));
        T = length(datafiles);

        for iii=T,
            % load data, grab neural features
            disp(datafiles(iii).name)
            load(fullfile(datadir,datafiles(iii).name))
            
            Ccell{trial} = TrialData.KalmanFilter{1}.C;
            alpha{trial} = TrialData.CursorAssist(1);
            lambda{trial} = round(TrialData.KalmanFilter{1}.Lambda,2);
            TargetID{trial} = TrialData.TargetID;
            TargetIDstr{trial} = int2str(TrialData.TargetID);
            
            trials(trial) = trial;
            trial = trial + 1;
        end
        
    end
end
day_break(end+1) = trial;
session_break(end+1) = trial; 

%% figure info 
% plot across array
ch_layout = [
    96	84	76	95	70	82	77	87	74	93	66	89	86	94	91	79
    92	65	85	83	68	75	78	81	72	69	88	71	80	73	90	67
    62	37	56	48	43	44	60	33	49	64	58	59	63	61	51	34
    45	53	55	52	35	57	38	50	54	39	47	42	36	40	46	41
    19	2	10	21	30	23	17	28	18	1	8	15	32	27	9	3
    24	13	6	4	7	16	22	5	20	14	11	12	29	26	31	25
    124	126	128	119	110	113	111	122	117	125	112	98	104	116	103	106
    102	109	99	101	121	127	105	120	107	123	118	114	108	115	100	97];
[R,Col] = size(ch_layout);
Nch = 128;
limch = ch_layout(R,1);

% go through each feature and plot erps
feature_strs = {'delta-phase','delta-pwr','theta-pwr','alpha-pwr',...
    'beta-pwr','low-gamma-pwr','high-gamma-pwr'};
cc = brewermap(trials(end),'Blues');

%% plot kalman preferred dirs
C = cat(3,Ccell{:});
Cx = squeeze(C(:,3,:))';
Cy = -1*squeeze(C(:,4,:))';

% features
for feature=1:7,
    Cx_feature = Cx(:,128*(feature-1)+1:128*feature);
    Cy_feature = Cy(:,128*(feature-1)+1:128*feature);

    fig = figure('units','normalized','position',[.1,.1,.8,.8],'name',feature_strs{feature});
    ax = tight_subplot(R,Col,[.01,.01],[.05,.01],[.03,.01]);
    set(ax,'NextPlot','add');
    for sess=1:trials(end),
        Cvec = [Cx(sess,128*(feature-1)+1:128*feature);
            Cy(sess,128*(feature-1)+1:128*feature)]';

        for ch=1:Nch,
            [r,c] = find(ch_layout == ch);
            idx = Col*(r-1) + c;

            % clean plot
            plot(ax(idx),[0,Cvec(ch,1)],[0,Cvec(ch,2)],...
                'linewidth',1,'color',cc(sess,:))
            set(ax(idx),'XTick',[],'YTick',[],'box','on');
        end
    end

    % make all subplots have the same scale
    xx = cell2mat(get(ax,'XLim'));
    yy = cell2mat(get(ax,'YLim'));
    xy(1) = abs(min(cat(1,xx(:),yy(:))));
    xy(2) = abs(max(cat(1,xx(:),yy(:))));

    max_xy = .8*max(xy);
    xy = [-max_xy,max_xy];
    set(ax,'XLim',xy,'YLim',xy)

    % add limits to limch
    [r,c] = find(ch_layout == limch);
    idx = Col*(r-1) + c;
    set(ax(idx),'XTick',xy,'XTickLabel',xy,'YTick',xy,'YTickLabel',xy)

    % add channel nums & vline at t=0
    for ch=1:Nch,
        [r,c] = find(ch_layout == ch);
        idx = Col*(r-1) + c;
        text(ax(idx),xy(1),xy(1),sprintf('ch%03i',ch),...
            'VerticalAlignment','Bottom')
    end

    tightfig;
    
    % save figure
    saveas(fig,sprintf('Figures/kalman_%s_pref_dir_across_days.png',...
        feature_strs{feature}))

end



