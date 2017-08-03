function ctw_lags = estimate_lags_ctw(annotations, feature_sequences, label_sequences)
    addpath(genpath([cd '/ctw']))
    addpath(genpath([cd '/ctw/src']));
    addpath(genpath([cd '/ctw/lib']));

    prSet(1);

    % Parameters
    parDtw = [];
    parImw = st('lA', 1, 'lB', 1); % IMW: regularization weight
    parCca = st('d', .95); % CCA: reduce dimension to keep at least 0.95 energy
    parCtw = [];
    parGN = st('nItMa', 2, 'inp', 'linear'); % Gauss-Newton: 2 iterations to update the weight in GTW, 
    parGtw = [];

    Xs = label_sequences;

    % monotonic basis
    ns = cellDim(Xs, 2);
    len = length(Xs{1}); % Latent sequence length
    bas = baTems(len, ns, 'pol', [3 0.4], 'tan', [3 0.6 1]); % 2 polynomial and 3 tangent functions
    if ~exist('aliT', 'var')
        aliT = [];
    end

    % utw (initialization)
    if ~exist('aliUtw', 'var')
        aliUtw = utw(Xs, bas, aliT);
    end

    %% dtw
    if ~exist('aliDtw', 'var')
        aliDtw = dtw(Xs, aliT, parDtw);
    end

    %% ddtw
    if ~exist('aliDdtw', 'var')
        aliDdtw = ddtw(Xs, aliT, parDtw);
    end

    %% imw
    if ~exist('aliImw', 'var')
        aliImw = pimw(Xs, aliUtw, aliT, parImw, parDtw);
    end

    %% ctw
    if ~exist('aliCtw', 'var')
        aliCtw = ctw(Xs, aliUtw, aliT, parCtw, parCca, parDtw);
    end

    %% gtw
    if ~exist('aliGtw', 'var')
        aliGtw = gtw(Xs, bas, aliUtw, aliT, parGtw, parCca, parGN);
    end

    %% show alignment result
    %shAliCmp(Xs, Xs, {aliDtw, aliDdtw, aliImw, aliCtw, aliGtw}, aliT, parCca, parDtw, parGN, 1);

    %% show basis
    %shAliP(bas{1}.P, 'fig', 2);

    ctw_lags.annotator_lags = aliT;
