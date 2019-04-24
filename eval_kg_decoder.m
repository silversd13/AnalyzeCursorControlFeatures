function [mse_kf,mse_kg] = eval_kg_decoder(buf_sz,X,Xint)

%% filter
for i=1:length(X), % trials
    
    X_kg_buf.vel = {};
    X_kg_buf.idx = 1;
    X_kg_buf.buf_sz = buf_sz;
    for ii=1:size(X{i},2), % time
        %% intended (refit)
        X_int{i}(:,ii) = Xint{i}(3:4,ii);
        
        %% kalman filter
        X_kf{i}(:,ii) = X{i}(3:4,ii);
        
        %% kg idea - put kf vel in circ buf, proj curr kf vel onto mean of buf
        % fill circ buffer
        X_kg_buf.vel{X_kg_buf.idx} = X_kf{i}(:,ii);
        X_kg_buf.idx = mod(X_kg_buf.idx,X_kg_buf.buf_sz) + 1;
        % compute int vel
        kg_int_vel = mean(cat(2,X_kg_buf.vel{:}),2);
        % project current kf vel onto intended vel
        kg_cur_vel = X_kf{i}(:,ii)*dot(X_kf{i}(:,ii),kg_int_vel)/norm(kg_int_vel)/norm(X_kf{i}(:,ii));
        X_kg{i}(:,ii) = kg_cur_vel;
        
    end
    
    % plot first 5 secs
    figure; hold on
    for ii=1:min([size(X{i},2),5*10]),
        plot([X{i}(1,ii),X{i}(1,ii)+X_kf{i}(1,ii)],...
            [X{i}(2,ii),X{i}(2,ii)+X_kf{i}(2,ii)],'-b')
    end
    waitforbuttonpress;
    close(gcf)
end

%% compute kf accuracy vs kg accuracy
v_int = cat(2,X_int{:});
v_kf = cat(2,X_kf{:});
v_kg = cat(2,X_kg{:});

mse_kf = mean((v_kf - v_int).^2,2);
mse_kg = mean((v_kg - v_int).^2,2);

end

