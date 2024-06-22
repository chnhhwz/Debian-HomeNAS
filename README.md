基于Debian搭建HomeNAS
使用完整版DVD安装，跳过配置root用户密码和镜像源
---

# 使用方法
### 1、首先使用SSH连接系统，然后用安装系统时创建的第一个普通用户账号进行登录。登陆后，使用以下命令切换到root账户。请注意，Debian系统默认禁用root账户直接通过SSH连接。
  ```shell
su -
  ```
### 2、执行脚本下载命令并自动运行（二选一）
国内环境
  ```shell
wget -O debian-homenas.sh -q --show-progress https://gitee.com/kekylin/Debian-HomeNAS/raw/main/debian-homenas_cn.sh && bash debian-homenas.sh
  ```
Github直连
  ```shell
wget -O debian-homenas.sh -q --show-progress https://raw.githubusercontent.com/chnhhwz/debian-homenas/main/debian-homenas.sh && bash debian-homenas.sh
  ```
### 3、登陆使用
> **脚本执行完毕后，查看SSH工具显示的Cockpit面板管理地址和Docker管理工具地址，打开对应服务进行使用。**

Cockpit，一个基于 Web 的服务器图形界面，在 Web 浏览器中查看您的服务器并使用鼠标执行系统任务。启动容器、管理存储、配置网络和检查日志都很容易。基本上，您可以将 Cockpit 视为图形“桌面界面”。
Cockpit是直接使用系统账户进行登陆使用，出于安全考虑，Cockpit默认禁用root账户登陆，建议使用您安装系统时创建的第一个用户登陆。
  ```shell
https://localhost:9090
  ```
Portainer，通用容器管理平台，脚本部署的是英文原版，与Dockge配合使用，涉及到网络管理、容器镜像管理，使用Portainer。日常部署容器及维护容器，推荐使用Dockge，支持中文，对容器的管理和维护很方便。
  ```shell
https://localhost:9443
  ```
Dockge,一个精美的、易于使用的、反应式的自托管 docker compose.yaml 面向堆栈的管理器。自带中文，日常维护时，不管是部署、更新还是维护，都比Portainer方便，但目前缺少容器网络管理及容器镜像功能，推荐搭配Portainer使用。
  ```shell
http://localhost:5001
  ```

# 转载请保留出处
- DIY NAS_3群 339169752
