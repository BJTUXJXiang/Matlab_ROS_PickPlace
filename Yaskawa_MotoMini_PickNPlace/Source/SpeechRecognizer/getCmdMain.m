%% �����F�����C���t�@�C��
% "forward","left","right","stop","go" ��F���\�B

% FFigure �����݂������R�}���h�����o�B
h = figure('Units','normalized','Position',[0.2 0.1 0.6 0.8]);
cmd_hst = strings(0);

% Figure ����邩 "stop" �Ɠ��͂���� break�B
while ishandle(h)
  cmd_str = getCmdFromMic('trainedNet.mat','trainedNet',h);
  disp(cmd_str);
  
  if ~strcmp(cmd_str,'unknown')
    cmd_hst(end+1) = cmd_str;
  end
  
  if strcmp(cmd_str,'stop')
      break;
  end
end

% �����R�}���h����\��
disp('Command histories:');
disp(cmd_hst);
