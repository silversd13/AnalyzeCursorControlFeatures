%% clicker classifier
clear, clc, close all

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
F_squeeze = [];
F_nothing = [];
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
            Ftrial = cat(2,TrialData.NeuralFeatures{:});
            
            idx_squeeze = (TrialData.Time >= TrialData.Events(end).Time+1) ...
                & (TrialData.Time < TrialData.Events(end).Time+2);
            idx_nothing = (TrialData.Time >= TrialData.Events(end).Time-1) ...
                & (TrialData.Time < TrialData.Events(end).Time);
            
            F_squeeze = cat(1,F_squeeze,Ftrial(:,idx_squeeze)');
            F_nothing = cat(1,F_nothing,Ftrial(:,idx_nothing)');
            
            trials(trial) = trial;
            trial = trial + 1;
        end % trials
    end % sessions
end % days
day_break(end+1) = trial;
session_break(end+1) = trial; 

%% build classifer using all data

F = cat(1,F_nothing,F_squeeze);
Y(1:size(F_nothing,1),1) = 1;
Y(size(F_nothing,1)+1:size(F,1),1) = 2;
classes_mat = [...
    1 0
    0 1];
classes = {'relax','squeeze'};

idx = randperm(size(Y,1));

% cross val - 10-fold
K = 10;
for k=1:K,
    idx = circshift(idx,round(.1*size(Y,1)));
    train_idx = idx(1:round(.9*size(Y,1)));
    test_idx = idx(round(.9*size(Y,1))+1:end);

    % Classify w/ LDA: Training

    lin_mdl = compact(fitcdiscr(F(train_idx,:),Y(train_idx,:),...
        'DiscrimType','linear',...
        'Prior','uniform',...
        'OptimizeHyperparameters','auto',...
        'HyperparameterOptimizationOptions',...
        struct('AcquisitionFunctionName','expected-improvement-plus',...
        'KFold',10,'ShowPlots',false,'Verbose',0,'Repartition',true)));

    Yhat = predict(lin_mdl,F(train_idx,:));
    fprintf('training_accuracy, %.2f\n', mean(Y(train_idx,:)==Yhat))

    Yhat = predict(lin_mdl,F(test_idx,:));
    fprintf('training_accuracy, %.2f\n\n', mean(Y(test_idx,:)==Yhat))
end

% plots
figure;
plotconfusion(classes_mat(:,Y(test_idx,:)),classes_mat(:,Yhat))
set(gcf,'Position', [706 193 647 594])
set(gca,'XTickLabel',[classes,{''}])
set(gca,'YTickLabel',[classes,{''}],'YTickLabelRotation',90)
xlabel('True Target','fontsize',14)
ylabel('Predicted Target','fontsize',14)
title('Confusion Matrix')







