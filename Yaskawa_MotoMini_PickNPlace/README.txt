0. ���s�O�ɂ��ׂẴE�B���X�΍�\�t�g�A�t�@�C�A�[�E�H�[�����I�t�ɂ���

1. Ubuntu Linux 16.04��(VMware�Ȃǂł���)��ROS Kinetic Kame + Gazebo v7���C���X�g�[��
  http://wiki.ros.org/kinetic/Installation/Ubuntu
  http://projectsfromtech.blogspot.com/2017/09/installing-ros-on-virtual-machine-for.html

2. catkin workspace���z�[���f�B���N�g���Ȃǂɍ쐬����
$ mkdir ~/catkin_ws_motomini
$ mkdir ~/catkin_ws_motomini/src
$ cd ~/catkin_ws_motomini/src
$ catkin_init_workspace
$ git clone https://github.com/ntl-ros-pkg/motoman_apps.git
$ cd motoman_apps
$ sh install.sh
$ source ~/catkin_ws_motomini/devel/setup.bash

3. XACRO�����s���AURDF�𐶐����� (COLLADA(.dae)��STL�ɕϊ�)
$ cd ~/catkin_ws_motomini/src/motoman_pkgs/motoman_robot/motoman_description
$ rosrun xacro xacro --inorder motomini_with_gripper.urdf.xacro > ~/motomini_with_gripper.urdf
$ sudo apt install openctm-tools
$ find . -name '*.dae' | sed 's/.dae$//' | xargs -i ctmconv {}.dae {}.stl    
(�������A�ꕔ��COLLADA�t�@�C�����������ϊ�����Ȃ��̂ŗe��0�̂��̂�Blender�Ȃǂ��g����STL�Ɏ蓮�ϊ�)  
$ sed -i 's/.dae/.stl/g' ~/motomini_with_gripper.urdf 

4. ROSFiles�t�H���_�ȉ���1�̃t�@�C����1�̃t�H���_���R�s�[
(Ubuntu����Windows�Ƀt�@�C���������Ă���ꍇ��WinSCP�Ȃǂ��g��)
~/motomini_with_gripper.urdf
~/catkin_ws_motomini/src/motoman_pkgs/motoman_robot/motoman_description

5. Motomini�̃V�~�����[�V���������N��
$ source ~/catkin_ws_motomini/devel/setup.bash
$ roslaunch motoman_mathworks_apps motomini_picking_demo_gazebo_autorun.launch

6. MATLAB R2019a�ȍ~���N������

7. ������Indigo�̃��b�Z�[�W����Kinetic�ɒu������
7-0. �uRobotics System Toolbox Interface for ROS Custom Messages�v���A�h�I���G�N�X�v���[������C���X�g�[���B
�A�h�I���G�N�X�v���[���͉��L�̃R�}���h�ŋN���B
>>roboticsAddons

7-1. gazebo_msgs�p�b�P�[�W�����L����_�E�����[�h
https://github.com/ros-simulation/gazebo_ros_pkgs
"kinetic-devel"�u�����`���g�����ƁB

7-2.ROSFiles�t�H���_�ȉ���custommsg�ɉ�
ROSFiles/custommsg/gazebo_msgs
ROSFiles/custommsg/gazebo_msgs/msg
ROSFiles/custommsg/gazebo_msgs/srv
ROSFiles/custommsg/gazebo_msgs/package.xml

7-3. rosgenmsg��MATLAB�Ŏ��s
>> rosgenmsg(fullfile(pwd,'ROSFiles','custommsg'))

7-4. �R�}���h���C���ɕ\������郁�b�Z�[�W�ɂ��������� javaclasspath.txt�t�@�C����ҏW�B
������JAR�t�@�C���̑���ɐV�������̂��g�p���邽��"before"�g�[�N�����s���ɓ����B
��F
<before>
c:\Yaskawa_MotoMini\ROSFiles\custommsg\matlab_gen\jar\gazebo_msgs-2.5.8.jar

���L�̂Ƃ���MATLAB�p�X�ɂ��ǉ�
addpath(fullfile(pwd,'ROSFiles','custommsg','matlab_gen','msggen'))
savepath

7-5. MATLAB�ċN��

7-6. �O�񐶐����ꂽ�t�@�C�����폜���A�Đ���
rmdir(fullfile(pwd,'ROSFiles','custommsg','matlab_gen','msggen','+robotics','+ros','+custom','+msggen','+gazebo_msgs'), 's')
rosgenmsg(fullfile(pwd,'ROSFiles','custommsg'))

8. �f���t�H���_(PickAndPlaceDemo)�̒���startupDemo.m�����s

9. �u���E�U�́uMATLAB/Simulink: �s�b�N&�v���C�X�A�v���P�[�V�����v���N���b�N

10. showCompleteDemo.m���J������14�s�ڂ�IP�A�h���X��

  Ubuntu 16.04���C���X�g�[������Ă���}�V����IP�A�h���X�ɕύX���Ă���

11. �R�}���h�E�B���h�E�ŉ��L��mainController��Simulink���f�����J���Ă���
  >> open_system('mainController');

12. showCompleteDemo.m�����s

13. mainController��Simulink�̎��s�{�^���Ŏ��s
   �s�b�N���v���C�X���͂��܂�

�K�v��Toolbox
MATLAB R2019a
Robotics System Toolbox
Image Acquisition Toolbox
Image Processing Toolbox
Computer Vision Toolbox
Statistics and Machine Learning Toolbox
Deep Learning Toolbox
Reinforcement Learning Toolbox
Simulink
Stateflow
Simscape
Simscape Multibody
Optimization Toolbox
Global Optimization Toolbox
Parallel Computing Toolbox
MATLAB Coder
GPU Coder
Simulink Coder
Embedded Coder
