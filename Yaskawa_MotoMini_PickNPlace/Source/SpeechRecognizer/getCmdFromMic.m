function [word] = getCmdFromMic(networkFile,natworkName,h)
    %% �l�b�g���[�N�̓ǂݍ���
    load(networkFile, natworkName);

    %% �}�C�N����̃X�g���[�~���O �I�[�f�B�I���g�p�����R�}���h�̌��o
    % �R�}���h���o�l�b�g���[�N���}�C�N����̃X�g���[�~���O�I�[�f�B�I�Ńe�X�g�B

    % �I�[�f�B�I �f�o�C�X ���[�_�[�̍쐬�B
    fs = 16e3;
    classificationRate = 20;
    audioIn = audioDeviceReader('SampleRate',fs, ...
        'SamplesPerFrame',floor(fs/classificationRate));

    % �X�g���[�~���O �X�y�N�g���O�����̌v�Z�p�̃p�����[�^�[���w��B
    epsil = 1e-6;
    frameDuration = 0.025;
    hopDuration = 0.010;
    numBands = 40;
    
    frameLength = frameDuration*fs;
    hopLength = hopDuration*fs;
    waveBuffer = zeros([fs,1]);

    labels = trainedNet.Layers(end).Classes;
    YBuffer(1:classificationRate/2) = categorical("background");
    probBuffer = zeros([numel(labels),classificationRate/2]);

    specMin = -6;
    specMax = 3;

    breakFlg = false;
    word = 'unknown';
    
    % figure �����݂������p��
    while ishandle(h)

        % �I�[�f�B�I�f�o�C�X����T���v���擾�B
        x = audioIn();
        waveBuffer(1:end-numel(x)) = waveBuffer(numel(x)+1:end);
        waveBuffer(end-numel(x)+1:end) = x;

        % �ŐV�̃T���v������X�y�N�g�������Z�o�B
        spec = melSpectrogram(waveBuffer,fs, ...
            'WindowLength',frameLength, ...
            'OverlapLength',frameLength - hopLength, ...
            'FFTLength',512, ...
            'NumBands',numBands, ...
            'FrequencyRange',[50,7000]);

        spec = log10(spec + epsil);

        % �w�K�ς݃l�b�g���[�N�ŕ��ށB
        [YPredicted,probs] = classify(trainedNet,spec,'ExecutionEnvironment','cpu');
        YBuffer(1:end-1)= YBuffer(2:end);
        YBuffer(end) = YPredicted; % �ߋ�10�񕪂̔F�����ʂ�ۑ�
        probBuffer(:,1:end-1) = probBuffer(:,2:end);
        probBuffer(:,end) = probs'; % �ߋ�10�񕪂̊m����ۑ�

        % ���݂̉����g�`�ƃX�y�N�g������`��B
        subplot(2,1,1);
        plot(waveBuffer)
        axis tight
        ylim([-0.8,0.8])

        subplot(2,1,2)
        pcolor(spec)
        caxis([specMin+2 specMax])
        shading flat

        % �����R�}���h���o�B
        % �m�C�Y�ł��Ȃ��A�ߋ�10��5��ȏ�A���ő�m����0.7�ȏ�̏ꍇ�Ɋm��B
        [YMode,count] = mode(YBuffer);
        countThreshold = ceil(classificationRate*0.2);
        maxProb = max(probBuffer(labels == YMode,:));
        probThreshold = 0.7;
        subplot(2,1,1);
        if YMode == "background" || count<countThreshold || maxProb < probThreshold
            title(" ")
        else
            % �m�肵����߂�l�ɔF�����ʂ��i�[�B
            word = string(YMode);
            title(word,'FontSize',20)
            breakFlg = true;
        end

        drawnow
        
        if breakFlg == true
            break;
        end
    end
end