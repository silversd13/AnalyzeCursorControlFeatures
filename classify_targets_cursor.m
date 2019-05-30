%% classify targets
clear, clc

%% organize data
datadir = '/Volumes/FLASH/Bravo1/DownsizedTrials/Cursor';
files = dir(fullfile(datadir,'Data*.mat'));

% split into training data and testing data
N = length(files);
randidx = randperm(N);
trainidx = randidx(1:round(.9*N));
testidx = randidx((round(.9*N)+1):end);

%% try different hyper params
BinSize = 100;
NumBinsVec = 1:15;
out = cell(1,length(NumBinsVec));

MaxNumBins = floor(1500/BinSize);
for ii=1:length(NumBinsVec),
    NumBins = NumBinsVec(ii);
    fprintf('  NumBins: %i\n',NumBins)
    
    % keep track
    out{1,ii}.bin_size = BinSize;
    out{1,ii}.num_binss = NumBins;
    
    % skip
    if NumBins>MaxNumBins, % max is 1 sec
        % keep track
        out{1,ii}.lin_mdl = {};
        out{1,ii}.lin_mdl_accuracy = NaN;
        out{1,ii}.lin_mdl_avg_target_dist = NaN;
        
        out{1,ii}.quad_mdl = {};
        out{1,ii}.quad_mdl_accuracy = NaN;
        out{1,ii}.quad_mdl_avg_target_dist = NaN;
        
        % out{1,ii}.svm_mdl = {};
        % out{1,ii}.svm_mdl_accuracy = NaN;
        % out{1,ii}.svm_mdl_avg_target_dist = NaN;
        
        % out{1,ii}.knn_mdl = {};
        % out{1,ii}.knn_mdl_accuracy = NaN;
        % out{1,ii}.knn_mdl_avg_target_dist = NaN;
        
        % out{1,ii}.tree_mdl = {};
        % out{1,ii}.tree_mdl_accuracy = NaN;
        % out{1,ii}.tree_mdl_avg_target_dist = NaN;
        continue;
    end
    
    %% go through each file in load data, comp features, grab target
    target_angles = 0:45:360-45;
    features = cell(1,N);
    target = cell(1,N);
    msg = '';
    for iii=1:N,
        % update screen
        fprintf(repmat('\b',1,length(msg)))
        msg = sprintf('  %i of %i',iii,N);
        fprintf(msg)
        
        load(fullfile(datadir,files(iii).name));
        
        % skip if not enough bins in trial
        if size(Data.CursorState,2)<15,
            continue;
        end
        
        % bin cursor state
        T = Data.Time;
        X = Data.CursorState;
        Tq = T(1):BinSize/1000:T(end);
        Xq = zeros(4,length(Tq));
        for i=1:4,
            Xq(i,:) = interp1(T,X(i,:),Tq,'linear');
        end
        features{iii} = Xq(:,NumBins);
        % bin other useful params (
        target{iii} = find(Data.TargetAngle==target_angles);
    end
    fprintf(repmat('\b',1,length(msg)))
    fprintf('\n')
    
    %% train classifiers
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
    
    % quadratic discriminant analysis
    quad_mdl = compact(fitcdiscr(X,Y,...
        'DiscrimType','pseudoquadratic',...
        'Prior','uniform',...
        'Delta',0,...
        'OptimizeHyperparameters','none',...
        'HyperparameterOptimizationOptions',...
        struct('AcquisitionFunctionName','expected-improvement-plus',...
        'KFold',10,'ShowPlots',false,'Verbose',0,'Repartition',true)));
    
    % %%% svm
    % %svm_mdl = compact(fitcecoc(X,Y,...
    % %    'Prior','uniform',...
    % %    'Learners',t,...
    % %    'OptimizeHyperparameters','auto',...
    % %    'HyperparameterOptimizationOptions',...
    % %    struct('AcquisitionFunctionName','expected-improvement-plus',...
    % %    'KFold',10,'ShowPlots',false,'Verbose',0,'Repartition',true)));
    
    % % knn
    % knn_mdl = compact(fitcknn(X,Y,...
    %     'Prior','uniform',...
    %     'OptimizeHyperparameters','auto',...
    %     'HyperparameterOptimizationOptions',...
    %     struct('AcquisitionFunctionName','expected-improvement-plus',...
    %     'KFold',10,'ShowPlots',false,'Verbose',0,'Repartition',true)));
    
    % % binary tree
    % tree_mdl = compact(fitctree(X,Y,...
    %     'Prior','uniform',...
    %     'OptimizeHyperparameters','auto',...
    %     'HyperparameterOptimizationOptions',...
    %     struct('AcquisitionFunctionName','expected-improvement-plus',...
    %     'KFold',10,'ShowPlots',false,'Verbose',0,'Repartition',true)));
    
    %% evaluate classifiers
    X = cat(2,features{testidx})';
    Y = cat(1,target{testidx});
    
    % linear discriminant analysis
    Yhat = predict(lin_mdl,X);
    accuracy = mean(Y==Yhat);
    dist1 = mod(Y-Yhat,8);
    dist2 = mod(Yhat-Y,8);
    dist = min([dist1,dist2],[],2);
    avg_dist = mean(dist);
    
    % print update to screen
    fprintf('    LDA Accuracy: %.2f\n',accuracy)
    fprintf('    LDA Avg Dist: %.2f\n',avg_dist)
    
    % keep track
    out{1,ii}.lin_mdl = lin_mdl;
    out{1,ii}.lin_mdl_accuracy = accuracy;
    out{1,ii}.lin_mdl_avg_target_dist = avg_dist;
    
    % quadratic discriminant analysis
    Yhat = predict(quad_mdl,X);
    accuracy = mean(Y==Yhat);
    dist1 = mod(Y-Yhat,8);
    dist2 = mod(Yhat-Y,8);
    dist = min([dist1,dist2],[],2);
    avg_dist = mean(dist);
    
    % print update to screen
    fprintf('    QDA Accuracy: %.2f\n',accuracy)
    fprintf('    QDA Avg Dist: %.2f\n',avg_dist)
    
    % keep track
    out{1,ii}.quad_mdl = quad_mdl;
    out{1,ii}.quad_mdl_accuracy = accuracy;
    out{1,ii}.quad_mdl_avg_target_dist = avg_dist;
    
    % %% support vector machine
    % %Yhat = predict(svm_mdl,X);
    % %accuracy = mean(Y==Yhat);
    % %dist1 = mod(Y-Yhat,8);
    % %dist2 = mod(Yhat-Y,8);
    % %dist = min([dist1,dist2],[],2);
    % %avg_dist = mean(dist);
    % %
    % % % print update to screen
    % % fprintf('    SVM Accuracy: %.2f\n',accuracy)
    % % fprintf('    SVM Avg Dist: %.2f\n',avg_dist)
    % %
    % % % keep track
    % % out{1,ii}.svm_mdl = svm_mdl;
    % % out{1,ii}.svm_mdl_accuracy = accuracy;
    % % out{1,ii}.svm_mdl_avg_target_dist = avg_dist;
    
    % % k nearest neighbors
    % Yhat = predict(knn_mdl,X);
    % accuracy = mean(Y==Yhat);
    % dist1 = mod(Y-Yhat,8);
    % dist2 = mod(Yhat-Y,8);
    % dist = min([dist1,dist2],[],2);
    % avg_dist = mean(dist);
    
    % % print update to screen
    % fprintf('    KNN Accuracy: %.2f\n',accuracy)
    % fprintf('    KNN Avg Dist: %.2f\n',avg_dist)
    
    % % keep track
    % out{1,ii}.knn_mdl = knn_mdl;
    % out{1,ii}.knn_mdl_accuracy = accuracy;
    % out{1,ii}.knn_mdl_avg_target_dist = avg_dist;
    
    % % binary tree
    % Yhat = predict(tree_mdl,X);
    % accuracy = mean(Y==Yhat);
    % dist1 = mod(Y-Yhat,8);
    % dist2 = mod(Yhat-Y,8);
    % dist = min([dist1,dist2],[],2);
    % avg_dist = mean(dist);
    
    % % print update to screen
    % fprintf('    TREE Accuracy: %.2f\n',accuracy)
    % fprintf('    TREE Avg Dist: %.2f\n',avg_dist)
    
    % % keep track
    % out{1,ii}.tree_mdl = tree_mdl;
    % out{1,ii}.tree_mdl_accuracy = accuracy;
    % out{1,ii}.tree_mdl_avg_target_dist = avg_dist;
    
    % print to screen
    fprintf('\n\n')
    
end % NumBins
save('classify_targets.mat','out')
