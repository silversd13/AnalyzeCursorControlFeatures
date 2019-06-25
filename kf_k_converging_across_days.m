%% check if kalman gain is changing within and across days
clear, clc, close all
cc = hsv(8);
feature_strs = {'delta-phase','delta-pwr','theta-pwr','alpha-pwr',...
    'beta-pwr','low-gamma-pwr','high-gamma-pwr'};

%% experiment info
expts = [];

% expts(end+1).yymmdd = '20190514';
% expts(end).hhmmss = {'112836','133050'};
% 
% expts(end+1).yymmdd = '20190515';
% expts(end).hhmmss = {'110735'};
% 
% expts(end+1).yymmdd = '20190521';
% expts(end).hhmmss = {'135008','141438'};
% 
% expts(end+1).yymmdd = '20190524';
% expts(end).hhmmss = {'110219','133313'};
% 
% expts(end+1).yymmdd = '20190529';
% expts(end).hhmmss = {'105609','113247','132457','135030'};
% 
% expts(end+1).yymmdd = '20190531';
% expts(end).hhmmss = {'102944','111946','132244','135046'};

expts(end+1).yymmdd = '20190604';
expts(end).hhmmss = {'112454','140706'};

% expts(end+1).yymmdd = '20190607';
% expts(end).hhmmss = {'104622','133540','133540'};

% expts(end+1).yymmdd = '20190610';
% expts(end).hhmmss = {'104104','131054'};

%% load data

% go through expts
Kcell = {};
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

        for iii=T, % last trial (K should converge by trial 2)
            % load data, grab neural features
            disp(datafiles(iii).name)
            load(fullfile(datadir,datafiles(iii).name))
            
            P = TrialData.KalmanFilter{1}.P;
            C = TrialData.KalmanFilter{1}.C;
            Q = TrialData.KalmanFilter{1}.Q;
            K = P*C'/(C*P*C' + Q);
             
            Kcell{trial} = K;
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
K = cat(3,Kcell{:});

%% plot K from final session

% stem plots
figure;

subplot(2,1,1)
stem(K(3,:,end))
ylabel('Vx')
title('Steady State Kalman Gain')

subplot(2,1,2)
stem(K(4,:,end))
ylabel('Vy')
xlabel('ch/feature')

%% plot K from final session on the brain
% load imaging data
load('imaging/BRAVO1_rh_pial.mat');
rh = cortex;
load('imaging/BRAVO1_lh_pial.mat');
lh = cortex;
load('imaging/elecs_all.mat');
ch_layout = [
    96	84	76	95	70	82	77	87	74	93	66	89	86	94	91	79
    92	65	85	83	68	75	78	81	72	69	88	71	80	73	90	67
    62	37	56	48	43	44	60	33	49	64	58	59	63	61	51	34
    45	53	55	52	35	57	38	50	54	39	47	42	36	40	46	41
    19	2	10	21	30	23	17	28	18	1	8	15	32	27	9	3
    24	13	6	4	7	16	22	5	20	14	11	12	29	26	31	25
    124	126	128	119	110	113	111	122	117	125	112	98	104	116	103	106
    102	109	99	101	121	127	105	120	107	123	118	114	108	115	100	97];
% elecmatrix = elecmatrix((reshape(flipud(ch_layout)',128,1)),:);
idx = reshape(flipud(ch_layout)',128,1);

% brain plots
for f=1:7,
    figure('name',sprintf(feature_strs{f}),'position',[681 559 1125 391]);

    ax(1)=subplot(1,2,1);
    ctmr_gauss_plot(lh,elecmatrix,K(3,(f-1)*128+(idx),end),'lh'); hold on
    el_add(elecmatrix, 'msize',1.7);
    title('Vx')
    colorbar('location','southoutside');
    
    ax(2)=subplot(1,2,2);
    ctmr_gauss_plot(lh,elecmatrix,K(4,(f-1)*128+(idx),end),'lh'); hold on
    el_add(elecmatrix, 'msize',1.7);
    title('Vy')
    colorbar('location','southoutside');
    
    % make colorbars same
    ccs = cell2mat(get(ax,'CLim'));
    cc = [];
    cc(1) = min(ccs(:));
    cc(2) = max(ccs(:));
    cc = [-.2,.2]
    set(ax,'CLim',cc)
end
