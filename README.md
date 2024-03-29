# LO14_Project

### 开发人员：张凯宣  林智帆

---

### 项目描述：通过shell脚本模拟管理员创建用户，管理用户，允许实现多个用户通过多个终端，登录不同的机器，并实现用户与用户，用户与机器之间的切换，退出，发送与接受消息，以及模拟使用中基本的Linux指令等

---

创建一个新的shell命合，命名为rvsh，它在以下两种模式下运行。

### 连接模式：

这个模式的调用方法是：

` rvsh -connect machine_name user_name `

这个命令允许你用用户的名字连接到虛拟机。

### 管理模式：

该模式的调用方法是：

` rvsh -admin `

该命令允许管理员管理连接到虛拟网络的机器列表和用户列表。

***

### 1.1连接模式的描述


连接模式允许用广连接到一个虛拟机（你事先已经创建的
）。如果用户名和虛拟机名称正确，连接被接受（即用广
有权连接到这个机器，而且他的密码正确），用户会到达
以下提示。

` user_name@machine_name> `

从这个提示中，用户应该能够协行某此虛拟命令。

> who命令

该命令允许对所有连接到机器的用户进行访问。它必须返
回每个用户的名字，以及他连接的时间和日期（见Linux
who命合）。注意，同一个用户可以从几个终端多次连接到
同一台机器。

> rusers命令

该命令提供了对网络上连接的用户列表的访问。它应该返
回每个用户的名字和他们所连接的机器的名字，以及他们
连接的时间和日期。

> rhost命合

此命令应返回连接到虚拟网络的计算机列表。

> rconnect命令

该命令允许用户连接到网络上的另一台机器（必须首先验
证用户有权利连接到这台机器）。

> su命令

这个命令允许你在不改变机器的情况下改变用户（参照Lin
wx的su命令）。

> passwd命令

该命令允许用户改变整个虚拟网络的密码（见Linux
passwd命分）。

> finger指令

该命令返回关于用户的额外信息（见Linux finger命令）。

> write命令

这个命令允许你向连接到网络上的机器的用户发送信息(
见Linux写命分）。命令的语法如下。

` write user_name@machine_name message `

> exit命令
该命令允许你退出一个虚拟机。
当用户在登录到一个新的机器之前登录到一个虚拟机时，exit命令会退出当前机器并返回到前一个机器。一个用户可以登录到机器A，然后是机器B，然后是机器C。exit命令退出机器C并返回机器B。一个新的退出命令返回到机器A。

### 1.2管理模式的描述

只有虚拟网络的管理员才能使用这种模式。因此对该命令
的的访问必须通过密码（管理员密码）来管理。一旦命令被
启动，密码被验证，管理员就会看到以下提示。

` root@hostroot> `

虛拟网络从一开始就被假定有一个名为
"hostroot
"的虚拟机，管理员在使用rvsh命兮的管理模式时连接到该
虛拟机。
从这个提示中，管理员应该能够运行连接模式的命令和以
下一些附加命分。

> host命令

该命令允许管理员从虚拟网络中添加或删除一台机器。
用广命令
该命令允许管理员添加或删除一个用户，给予他们对网络
上一台或多台机器的访问权，并设置密码。

> wall命令

该命令允许管理员向网络上的所有用广发送一条信息）。
命分的语法如下。

` wall message： ` 

向所有连接的用户发送消息"message"。

` wall -n message：` 

向所有已连接和末连接的用广发送消息
"message'。没有登录的用户在再次连接到网络时将收到该
信息。

> afinger命令

该命令允许管理员填写关于用广的额外信息（用户在连接
模式下通过finger命合可以获得这些信息）。
