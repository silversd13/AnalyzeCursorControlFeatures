function kf = fit_cv_kf(a,w,dt,X,Y)

A = [...
    1       0       dt      0       0;
    0       1       0       dt      0;
    0       0       a       0       0;
    0       0       0       a       0;
    0       0       0       0       1];
W = [...
    0       0       0       0       0;
    0       0       0       0       0;
    0       0       w       0       0;
    0       0       0       w       0;
    0       0       0       0       0];

% 8-fold cross validation
idx = 1:size(X,2);
K = 8;
for i=1:K,
    % get (K-1)/K data for training
    train_idx = idx(1:(K-1)/K*size(X,2));
    idx = circshift(idx,1/K*size(X,2));
    
    D = length(train_idx);
    C{i} = (Y(:,train_idx)*X(3:end,train_idx)') ...
        / (X(3:end,train_idx)*X(3:end,train_idx)');
    C{i} = [zeros(size(C{i},1),2), C{i}];
    Q{i} = (1/D) * ((Y(:,train_idx)-C{i}*X(:,train_idx)) ...
        * (Y(:,train_idx)-C{i}*X(:,train_idx))');
end

kf.A = A;
kf.W = W;
kf.C = mean(cat(3,C{:}),3);
kf.Q = mean(cat(3,Q{:}),3);

end
