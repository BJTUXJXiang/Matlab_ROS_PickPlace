%% ��������A�[�����{�b�g�ɂ�镨�̌��o�ƃs�b�N&�v���C�X

%% ������
clear all force; close all; clc; %#ok<CLALL>
delete(gcp('nocreate'))
parpool

%% roslaunch�ɂ��Gazebo�N��
% ROS Kinetic Kame + Gazebo v7���K�v
%
%  $ roslaunch motoman_mathworks_apps motomini_picking_demo_gazebo_autorun.launch world:=motomini_with_table_parts load_grasp_fix:=true
% 
% �Z�b�g�A�b�v�ɂ��Ă͉��L���Q��
% <https://github.com/ntl-ros-pkg/motoman_simulator>

%% ���O�ɒ�`�����p�����[�^�̃��[�h
load('motominiSplineData.mat');         % load spline data for motion generation
load('params.mat');                   % Load detector data
homeToIdleSpline.Q = zeros(6,6);
homeToIdleSpline.dQ = zeros(6,6);
homeToIdleSpline.t = linspace(0,5,6);
idleToHomeSpline.Q = zeros(6,6);
idleToHomeSpline.dQ = zeros(6,6);
idleToHomeSpline.t = linspace(0,5,6);

%% ���{�b�g�p�����[�^��IP�A�h���X��ݒ�
ros_master_ip = '192.168.93.128';
motomini = createMotomini();
MotominiParams = setMotominiParameters(ros_master_ip,motomini);
Q = homeToIdleSpline.Q;
numPoints = size(Q,2)-2; % -2 for start point and end point
numJoints = MotominiParams.numJoints;

%% ROS�}�X�^�[�ɐڑ�
rosshutdown;
setenv('ROS_MASTER_URI',"http://"+MotominiParams.ROS_IP+":11311")
setenv('ROS_IP','192.168.93.1') %�z�X�g����IP�A�h���X
rosinit

%% Simulink���f�����N��
open_system('mainController');

%% Simulink���f�������s
set_param('mainController','SimulationCommand','start');

%% �O���v��ROS�m�[�h���N��(���񃏁[�J�[�Ɋ��蓖��)
% managePlannerRequests(ros_master_ip,numPoints);
p = gcp(); % Get the current parallel pool
q = parallel.pool.DataQueue();
afterEach(q, @disp);
fp = parfeval(p,@managePlannerRequests,0,q,ros_master_ip,numPoints);
% 
% cancel(fp);

%% �����R�}���h���^���I��ROS�ő��M(�f�o�b�O�p)
% speechRecogNode = robotics.ros.Node('/matlab_speech_recognizer_dummy_node',ros_master_ip);
% speechResultsPub = robotics.ros.Publisher(speechRecogNode,'/speech_recognizer/speech_results',...
%     'std_msgs/String');
% speechResultsMsg = rosmessage(speechResultsPub);
% speechResultsMsg.Data = "right";
% %speechResultsMsg.Data = "left";
% %speechResultsMsg.Data = "forward";
% send(speechResultsPub,speechResultsMsg);
% pause(5);
% speechResultsMsg.Data = "go";
% send(speechResultsPub,speechResultsMsg);

%% �����F��ROS�m�[�h���N��(����v���Z�X�Ƃ���)
p = gcp(); % Get the current parallel pool
fs = parfeval(p,@speechRecognizerNode,0,q,ros_master_ip,'trainedNet.mat','trainedNet');
% 
% cancel(fs);

%% �I��(����v���Z�X���~����)
% set_param('mainController','SimulationCommand','stop');
% cancel(fp);
% cancel(fs);

%% Simulink���f������C�R�[�h�������g����ROS�m�[�h����
% d = rosdevice(ros_master_ip,'user','password');

% if you encounter the error "virtual memory exhausted: Cannot allocate
% memory", you need to increate your virtual memory as follows:
% https://digitizor.com/create-swap-file-ubuntu-linux/

% Manually launch motoMINI ros node in virtual machine
% $ cd /home/user/catkin_ws
% $ devel/lib/maincontroller/maincontroller_node

%% ROS���̐ݒ�
% ros_master_ip = MotominiParams.ROS_IP;
% username = 'user';
% password = 'password';
% d = rosdevice(ros_master_ip,username,password);
% d.CatkinWorkspace = '/home/user/catkin_ws_motomini';

% 
% [~,b] = fileparts(tempname);
% logFile = ['/tmp/roscore_' b '.log'];
% 
% % �ŏ���roslaunch�̃v���Z�X�����ׂĒ�~
% cmd = ['source ' d.ROSFolder '/setup.bash; pkill roslaunch'];
% d.system(cmd);
% 
% % roslaunch�����s
% cmd = ['source /home/user/.bashrc; ' ...
%     'export ROS_IP=' ros_master_ip ';' ...
%     ' export ROS_MASTER_URI=http://' ros_master_ip ':11311;' ...     % Export the ROS_MASTER_URI
%     ' export DISPLAY=:0;' ...
%     ' source ' d.CatkinWorkspace '/devel/setup.bash;' ...        % Source the setup.bash file we determined above
%     ' roslaunch motoman_mathworks_apps motomini_picking_demo_gazebo_autorun.launch&> ' logFile ...          % Run roscore and pipe output into log file
%     ' &'];
% d.system(cmd);
% pause(10);

% _Copyright 2019 The MathWorks, Inc._
