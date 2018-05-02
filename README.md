## foo

纯手工打造Erlang release。

Erlang release算是OTP中的多坑区了。平日中用rebar3或distillery来做发布，从没了解过这些自动化工具到底都做了什么。
这里用最简单的代码手写一个release。

- `foo.erl`一个最简单的gen_server, 每秒打印hello。
- `foo_sup.erl`一个最简单的supervisor。
- `foo_app.erl`一个最简单的application。
- `foo.app.src`一个最简单的application resource file。注意这个文件将来会被拷贝到ebin/foo.app。

`Makefile`中的compile部分
- 用`erlc`编译所有.erl文件，将.beam文件输出到`ebin`
- 将`src/foo.app.src`拷到`ebin/foo.app`

进erl里面测试一下
```
$ make compile
$ erl -pa ebin
Erlang/OTP 20 [erts-9.3] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

Eshell V9.3  (abort with ^G)
1> application:start(foo).
ok
2> hello
hello
hello
```

好，下面来写release。其实传说中的release无非就是一个.rel文件，里面包括了你的发布版本的
- 名称(`foo`)
- 版本号(`0.1.0`)
- Erlang 虚拟机版本(`9.3`)
- 所有用到的application以及其各自的版本(`kernel`,`stdlib`是必须包括的，`sasl`基本也要热更会用到，当然还有我们刚才自己写的`foo`)

另外一个文件`sys.config`包括系统参数，这个文件是必要的，但是我们目前可以不放任何内容。

有这两个文件后，看`Makefile`的release都做啥了
- 调用`systools:make_script("rel/0.1.0/foo")`生成`foo.boot`和`foo.script`
  - `foo.script`是一个程序员可读的脚本，描述了当启动Erlang节点时要做的事情(载入kernel,载入modules,启动各个application等)
  - `foo.boot`是对应的二进制版本，虚拟机只需要这个文件就能启动了。其实我们平日打`erl`进入shell的时候，虚拟器默认加载`start.boot`，只加载kernel和stdlib，这个文件可以在Erlang安装地找到，我的在`/usr/local/Cellar/erlang/20.3.2/lib/erlang/bin/start.boot`
- 调用`systools:make_tar("rel/0.1.0/foo",[{erts,"/usr/local/Cellar/erlang/20.3.2/lib/erlang"}])`生成tarball。后面选项中加上erts会在tarball中包括Erlang虚拟机

运行一下
```
$ make release
```
好，现在我们有了tarball在`rel/0.1.0/foo.tar.gz`，接下来的工作就是把这个家伙部署到目标机上（假设在`/tmp/prod`）。

所有要做的事都在`Makefile`的deploy中
- 将tarbar解压到`/tmp/prod`
- 将`erts-9.3/bin`中的几个文件拷到`bin`中
  - `start`用于启动虚拟机
  - `start_erl`, `run_erl`都是被间接调用的
  - `to_erl`可以让我们在节点启动后连上去进行各种操作
- 将`bin/start`中的几处替换一下
  - `%FINAL_ROOTDIR%`被替换成`/tmp/prod`作为运行节点的根目录
  - `/tmp/`被替换成`$ROOTDIR/log/pipes/`作为I/O文件的地址，以后我们就连到这里进行操作
- 生成一个文件`releases/start_erl.data`，内容为`9.3 0.1.0`，分别是虚拟机版本和release版本

好了，至此一切就绪。运行一下试试
```
$ make deploy
$ bin/start
$ bin/to_erl log/pipes/
Attaching to log/pipes/erlang.pipe.1 (^D to exit)

1> hello
hello
hello
```

所有代码总共72行，实现了一个很简单但是可用的Erlang release。至于rebar3或distillery把这个过程
自动化并且加上各自的options，需要去看他们各自的文档来了解如何使用。但是总体的步骤是一样的
- 生成`.rel`
- 生成`sys.config`
- 生成`.boot`
- 生成`.tar.gz`
- 发布`.tar.gz`到目标机
- 启动节点

### 参考资料
- Designing for Scalability with Erlang/OTP - Francesco & Steve 第11章，讲得非常详细
