# �T�v
- "forward","left","right","stop","go" �݂̂�F������l�b�g���[�N���쐬�B
- �ȉ��̃R�}���h��z��B
  - �c���Ώۃp�[�c�̎w�� (MotoMINI ���猩��)
    - "forward": t_brace_part
    - "left": disk_part
    - "right": arm_part
  - �c���J�n�E��~�̎w��
    - "stop": ��~
    - "go": �J�n
- ���n��̃R�}���h������z��Ɋi�[�B
  - "right", "go" �������Ă���΁Aarm_part ���s�b�N�A�b�v�ΏۂƂ���A�Ƃ������R�}���h��z��B

# �����f�[�^�w�K
- �f���p�̊w�K�ς݃f�[�^�� trainedNet.mat �Ɋi�[�B

1. �f�[�^�Z�b�g��
`https://storage.cloud.google.com/download.tensorflow.org/data/speech_commands_v0.02.tar.gz`
����_�E�����[�h
2. ��L�f�[�^�Z�b�g�� SpeechRecognizer �t�H���_�����ɉ�
3. TrainSpeechRecognitionNet.m �����s

# �����R�}���h���o�T���v���A�v��
- �w�K�ς݃��f���Ƃ��� trainedNet.mat ��Ǎ��B
1. getCmdMain.m �����s
2. "forward","left","right","stop","go" ��F���\�B����ȊO��"unknown"�B
3. "unknown" �ȊO�̌��o���ʂ͔g�`�O���t�ɏo�́B
4. Figure �̃N���[�Y or "stop" �̔F���ɂ��break�B

