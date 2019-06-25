%% classify targets
clear, clc

%% organize data
datadir = '/media/dsilver/data/Bravo1/DownsizedTrials';
day = '20190529';
files = dir(fullfile(datadir,sprintf('%s_*BCI_*.mat',day))); % fixed blocks

% split into training data and testing data
N = length(files);
randidx = randperm(N);
trainidx = randidx(1:round(.9*N));
testidx = randidx((round(.9*N)+1):end);
classes     = {'0','45','90','135','180','225','270','315','360'};
classes_mat = [...
    1 0 0 0 0 0 0 0;
    0 1 0 0 0 0 0 0;
    0 0 1 0 0 0 0 0;
    0 0 0 1 0 0 0 0;
    0 0 0 0 1 0 0 0;
    0 0 0 0 0 1 0 0;
    0 0 0 0 0 0 1 0;
    0 0 0 0 0 0 0 1];

%% try different hyper params
NumBinsVec = 1:25;
out = cell(1,length(NumBinsVec));

for ii=1:length(NumBinsVec),
    NumBins = NumBinsVec(ii);
    fprintf('  NumBins: %i\n',NumBins)
    
    % keep track
    out{1,ii}.num_bins = NumBins;
    
    % go through each file in load data, comp features, grab target
    target_angles = 0:45:360-45;
    features = cell(1,N);
    target = cell(1,N);
    msg = '';
    for iii=1:N,
        % update screen
        fprintf(repmat('\b',1,length(msg)))
        msg = sprintf('  %i of %i',iii,N);
        fprintf(msg)
        
        Data = load(fullfile(datadir,files(iii).name),'CursorState','Time','TargetAngle');
        
        % skip if not enough bins in trial
        if size(Data.CursorState,2)<15,
            continue;
        end
        
        % grab cursor state across bins
        X = Data.CursorState;
        try,
            features{iii} = reshape(X(1:2,1:NumBins),[],1);
        catch,
            tmp = X(1:2,1:end);
            tmp = cat(2,tmp,repmat(tmp(:,end),1,NumBins));
            features{iii} = reshape(tmp(:,1:NumBins),[],1);
        end
        
        % target angle
        target{iii} = find(Data.TargetAngle == target_angles);
    end
    fprintf(repmat('\b',1,length(msg)))
    fprintf('\n')
    
    % train classifiers
    X = cat(2,features{trainidx})';
    Y = cat(1,target{trainidx});
    
    % linear discriminant analysis
    lin_mdl = compact(fitcdiscr(X,Y,...
        'DiscrimType','linear',...
        'Prior','uniform',...
        'OptimizeHyperparameters','auto',...
        'HyperparameterOptimizationOptions',...
        struct('AcquisitionFunctionName','expected-improvement-plus',...
        'KFold',10,'ShowPlots',false,'Verbose',0,'Repartition',true)));
    out{1,ii}.lin_mdl = lin_mdl;
    
    % evaluate classifier on training data
    Yhat = predict(lin_mdl,X);
    accuracy = mean(Y==Yhat);
    
    % print update to screen
    fprintf('    LDA Training Accuracy: %.2f\n',accuracy)
    out{1,ii}.lin_mdl_train_accuracy = accuracy;
    out{1,ii}.lin_mdl_train_confusion = confusionmat(Y,Yhat);
    
    % save plots
    figure;
    plotconfusion(classes_mat(:,Y),classes_mat(:,Yhat))
    set(gcf,'Position', [706 193 647 594])
    set(gca,'XTickLabel',[classes,{''}])
    set(gca,'YTickLabel',[classes,{''}],'YTickLabelRotation',90)
    xlabel('True Target','fontsize',14)
    ylabel('Predicted Target','fontsize',14)
    title('Confusion Matrix: Training Data')
    savefile = sprintf(...
        '~/Desktop/Bravo1_LowW/%s_%iBins_PosTargetClassifier_TrainConfusionMat.png',...
        day,NumBins);
    saveas(gcf,savefile,'png');
    close(gcf)
    
    % evaluate classifier on testing data
    X = cat(2,features{testidx})';
    Y = cat(1,target{testidx});
    
    % linear discriminant analysis
    Yhat = predict(lin_mdl,X);
    accuracy = mean(Y==Yhat);
    
    % print update to screen
    fprintf('    LDA Testing Accuracy: %.2f\n',accuracy)
    out{1,ii}.lin_mdl_test_accuracy = accuracy;
    out{1,ii}.lin_mdl_test_confusion = confusionmat(Y,Yhat);
    
    % print to screen
    fprintf('\n\n')
    
    % continue plotting
    figure;
    plotconfusion(classes_mat(:,Y),classes_mat(:,Yhat))
    set(gcf,'Position', [706 193 647 594])
    set(gca,'XTickLabel',[classes,{''}])
    set(gca,'YTickLabel',[classes,{''}],'YTickLabelRotation',90)
    xlabel('True Target','fontsize',14)
    ylabel('Predicted Target','fontsize',14)
    title('Confusion Matrix: Testing Data')
    savefile = sprintf(...
        '~/Desktop/Bravo1_LowW/%s_%iBins_PosTargetClassifier_TestConfusionMat.png',...
        day,NumBins);
    saveas(gcf,savefile,'png');
    close(gcf)
    
end % NumBins
save('classify_targets_pos.mat','out')

%% try different hyper params
NumBinsVec = 1:25;
out = cell(1,length(NumBinsVec));

for ii=1:length(NumBinsVec),
    NumBins = NumBinsVec(ii);
    fprintf('  NumBins: %i\n',NumBins)
    
    % keep track
    out{1,ii}.num_bins = NumBins;
    
    % go through each file in load data, comp features, grab target
    target_angles = 0:45:360-45;
    features = cell(1,N);
    target = cell(1,N);
    msg = '';
    for iii=1:N,
        % update screen
        fprintf(repmat('\b',1,length(msg)))
        msg = sprintf('  %i of %i',iii,N);
        fprintf(msg)
        
        Data = load(fullfile(datadir,files(iii).name),'CursorState','Time','TargetAngle');
        
        % skip if not enough bins in trial
        if size(Data.CursorState,2)<15,
            continue;
        end
        
        % grab cursor state across bins
        X = Data.CursorState;
        try,
            features{iii} = reshape(X(3:4,1:NumBins),[],1);
        catch,
            tmp = X(3:4,1:end);
            tmp = cat(2,tmp,repmat(tmp(:,end),1,NumBins));
            features{iii} = reshape(tmp(:,1:NumBins),[],1);
        end
        
        % target angle
        target{iii} = find(Data.TargetAngle == target_angles);
    end
    fprintf(repmat('\b',1,length(msg)))
    fprintf('\n')
    
    % train classifiers
    X = cat(2,features{trainidx})';
    Y = cat(1,target{trainidx});
    
    % linear discriminant analysis
    lin_mdl = compact(fitcdiscr(X,Y,...
        'DiscrimType','linear',...
        'Prior','uniform',...
        'OptimizeHyperparameters','auto',...
        'HyperparameterOptimizationOptions',...
        struct('AcquisitionFunctionName','expected-improvement-plus',...
        'KFold',10,'ShowPlots',false,'Verbose',0,'Repartition',true)));
    out{1,ii}.lin_mdl = lin_mdl;
    
    % evaluate classifier on training data
    Yhat = predict(lin_mdl,X);
    accuracy = mean(Y==Yhat);
    
    % print update to screen
    fprintf('    LDA Training Accuracy: %.2f\n',accuracy)
    out{1,ii}.lin_mdl_train_accuracy = accuracy;
    out{1,ii}.lin_mdl_train_confusion = confusionmat(Y,Yhat);
    
    % save plots
    figure;
    plotconfusion(classes_mat(:,Y),classes_mat(:,Yhat))
    set(gcf,'Position', [706 193 647 594])
    set(gca,'XTickLabel',[classes,{''}])
    set(gca,'YTickLabel',[classes,{''}],'YTickLabelRotation',90)
    xlabel('True Target','fontsize',14)
    ylabel('Predicted Target','fontsize',14)
    title('Confusion Matrix: Training Data')
    savefile = sprintf(...
        '~/Desktop/Bravo1_LowW/%s_%iBins_VelTargetClassifier_TrainConfusionMat.png',...
        day,NumBins);
    saveas(gcf,savefile,'png');
    close(gcf)
    
    % evaluate classifier on testing data
    X = cat(2,features{testidx})';
    Y = cat(1,target{testidx});
    
    % linear discriminant analysis
    Yhat = predict(lin_mdl,X);
    accuracy = mean(Y==Yhat);
    
    % print update to screen
    fprintf('    LDA Testing Accuracy: %.2f\n',accuracy)
    out{1,ii}.lin_mdl_test_accuracy = accuracy;
    out{1,ii}.lin_mdl_test_confusion = confusionmat(Y,Yhat);
    
    % print to screen
    fprintf('\n\n')
    
    % continue plotting
    figure;
    plotconfusion(classes_mat(:,Y),classes_mat(:,Yhat))
    set(gcf,'Position', [706 193 647 594])
    set(gca,'XTickLabel',[classes,{''}])
    set(gca,'YTickLabel',[classes,{''}],'YTickLabelRotation',90)
    xlabel('True Target','fontsize',14)
    ylabel('Predicted Target','fontsize',14)
    title('Confusion Matrix: Testing Data')
    savefile = sprintf(...
        '~/Desktop/Bravo1_LowW/%s_%iBins_VelTargetClassifier_TestConfusionMat.png',...
        day,NumBins);
    saveas(gcf,savefile,'png');
    close(gcf)
    
end % NumBins
save('classify_targets_vel.mat','out')

%% try different hyper params
NumBinsVec = 1:25;
out = cell(1,length(NumBinsVec));

for ii=1:length(NumBinsVec),
    NumBins = NumBinsVec(ii);
    fprintf('  NumBins: %i\n',NumBins)
    
    % keep track
    out{1,ii}.num_bins = NumBins;
    
    % go through each file in load data, comp features, grab target
    target_angles = 0:45:360-45;
    features = cell(1,N);
    target = cell(1,N);
    msg = '';
    for iii=1:N,
        % update screen
        fprintf(repmat('\b',1,length(msg)))
        msg = sprintf('  %i of %i',iii,N);
        fprintf(msg)
        
        Data = load(fullfile(datadir,files(iii).name),'CursorState','Time','TargetAngle');
        
        % skip if not enough bins in trial
        if size(Data.CursorState,2)<15,
            continue;
        end
        
        % grab cursor state across bins
        X = Data.CursorState;
        try,
            features{iii} = reshape(X(1:4,1:NumBins),[],1);
        catch,
            tmp = X(1:4,1:end);
            tmp = cat(2,tmp,repmat(tmp(:,end),1,NumBins));
            features{iii} = reshape(tmp(:,1:NumBins),[],1);
        end
        
        % target angle
        target{iii} = find(Data.TargetAngle == target_angles);
    end
    fprintf(repmat('\b',1,length(msg)))
    fprintf('\n')
    
    % train classifiers
    X = cat(2,features{trainidx})';
    Y = cat(1,target{trainidx});
    
    % linear discriminant analysis
    lin_mdl = compact(fitcdiscr(X,Y,...
        'DiscrimType','linear',...
        'Prior','uniform',...
        'OptimizeHyperparameters','auto',...
        'HyperparameterOptimizationOptions',...
        struct('AcquisitionFunctionName','expected-improvement-plus',...
        'KFold',10,'ShowPlots',false,'Verbose',0,'Repartition',true)));
    out{1,ii}.lin_mdl = lin_mdl;
    
    % evaluate classifier on training data
    Yhat = predict(lin_mdl,X);
    accuracy = mean(Y==Yhat);
    
    % print update to screen
    fprintf('    LDA Training Accuracy: %.2f\n',accuracy)
    out{1,ii}.lin_mdl_train_accuracy = accuracy;
    out{1,ii}.lin_mdl_train_confusion = confusionmat(Y,Yhat);
    
    % save plots
    figure;
    plotconfusion(classes_mat(:,Y),classes_mat(:,Yhat))
    set(gcf,'Position', [706 193 647 594])
    set(gca,'XTickLabel',[classes,{''}])
    set(gca,'YTickLabel',[classes,{''}],'YTickLabelRotation',90)
    xlabel('True Target','fontsize',14)
    ylabel('Predicted Target','fontsize',14)
    title('Confusion Matrix: Training Data')
    savefile = sprintf(...
        '~/Desktop/Bravo1_LowW/%s_%iBins_FullTargetClassifier_TrainConfusionMat.png',...
        day,NumBins);
    saveas(gcf,savefile,'png');
    close(gcf)
    
    % evaluate classifier on testing data
    X = cat(2,features{testidx})';
    Y = cat(1,target{testidx});
    
    % linear discriminant analysis
    Yhat = predict(lin_mdl,X);
    accuracy = mean(Y==Yhat);
    
    % print update to screen
    fprintf('    LDA Testing Accuracy: %.2f\n',accuracy)
    out{1,ii}.lin_mdl_test_accuracy = accuracy;
    out{1,ii}.lin_mdl_test_confusion = confusionmat(Y,Yhat);
    
    % print to screen
    fprintf('\n\n')
    
    % continue plotting
    figure;
    plotconfusion(classes_mat(:,Y),classes_mat(:,Yhat))
    set(gcf,'Position', [706 193 647 594])
    set(gca,'XTickLabel',[classes,{''}])
    set(gca,'YTickLabel',[classes,{''}],'YTickLabelRotation',90)
    xlabel('True Target','fontsize',14)
    ylabel('Predicted Target','fontsize',14)
    title('Confusion Matrix: Testing Data')
    savefile = sprintf(...
        '~/Desktop/Bravo1_LowW/%s_%iBins_FullTargetClassifier_TestConfusionMat.png',...
        day,NumBins);
    saveas(gcf,savefile,'png');
    close(gcf)
    
end % NumBins
save('classify_targets_full.mat','out')

